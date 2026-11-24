#!/usr/bin/env bash

set -u                  # unset/misspelled variables become an error
set -o pipefail         # If any command in a pipeline fails, the whole pipeline fails

# Block running as root because AUR helpers refuse to run as root.
# (EUID holds the Effective User ID and root is 0)
if [[ "$EUID" -eq 0 ]]; then
    echo "ERROR: Please do not run this script as root."
    exit 1
fi


#========================#
# Install batch function #
#========================#

install_batch() {
    local category_name="$1"
    
    local -n pkgs="$2"

    if [[ "${#pkgs[@]}" -eq 0 ]]; then
        echo "--- Skipping $category_name (No packages listed) ---"
        return 0
    fi

    echo ""
    echo "=== Installing category: $category_name ==="

    if ! sudo pacman -S --needed --noconfirm -- "${pkgs[@]}"; then
        echo ""
        echo "ERROR: Failed to install batch '$category_name'."
        exit 1
    fi
    
    echo ""
    echo "=== Packages in category $category_name installed ==="
}


#===============#
# Package lists #
#===============#

BASE_PKGS=(
    "base-devel"
    "git"
    "curl"
    "wget"
    "linux-headers"
)

CLI_UTILS=(
    "htop"
    "btop"
    "neovim"
    "tmux"
    "ripgrep"
    "fzf"
    "unzip"
    "unrar"
    "zsh"
)

DEV_PKGS=(
    "python"
    "python-pip"
    "nodejs"
    "npm"
    "docker"
    "docker-compose"
    "gcc"
    "cmake"
)

GUI_PKGS=(
    "firefox"
    "vlc"
    "gimp"
    "obs-studio"
    "thunderbird"
    "keepassxc"
    "flameshot"
)

FONT_PKGS=(
    "ttf-fira-code"
    "ttf-jetbrains-mono-nerd"
    "noto-fonts-emoji"
)

AUR_PKGS=(
    "visual-studio-code-bin"
    "spotify"
    "brave-bin"
)


#=================#
# Start execution #
#=================#

echo "#=========================#"
echo "# Updating mirrors system #"
echo "#=========================#"

if ! sudo pacman-mirrors --fasttrack; then
    echo "ERROR: Failed to update mirrors."
    exit 1
fi

# -Syu refreshes package databases (-y) and upgrades out-of-date system packages (-u).
if ! sudo pacman -Syu --noconfirm; then
    echo "ERROR: System upgrade failed."
    exit 1
fi

#===========================#
# Install official packages #
#===========================#

echo ""
echo "#=====================#"
echo "# Installing packages #"
echo "#=====================#"

install_batch "1/5 Base & Core System"          BASE_PKGS
install_batch "2/5 CLI Utilities"               CLI_UTILS
install_batch "3/5 Programming & Development"   DEV_PKGS
install_batch "4/5 Desktop & GUI Applications"  GUI_PKGS
install_batch "5/5 Fonts"                       FONT_PKGS

echo ""
echo "=== Official packages installed. ==="

#======================#
# Install AUR packages #
#======================#

if [[ "${#AUR_PKGS[@]}" -gt 0 ]]; then
    echo ""
    echo "=== Installing AUR Packages ==="

    # Check if yay is installed.
    if ! command -v yay &> /dev/null; then
        echo "--- 'yay' is not installed. Installing yay first ---"
        if ! sudo pacman -S --needed --noconfirm -- yay; then
            echo "ERROR: Could not install yay."
            exit 1
        fi
    fi

    if ! yay -S --needed --noconfirm -- "${AUR_PKGS[@]}"; then
        echo ""
        echo "ERROR: Failed to install AUR packages."
        exit 1
    fi

    echo ""
    echo "=== AUR packages installed. ==="
fi

echo ""
echo "#===================================#"
echo "# All packages have been installed. #"
echo "#===================================#"