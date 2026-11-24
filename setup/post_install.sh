#!/usr/bin/env bash

set -u                  # unset/misspelled variables become an error
set -o pipefail         # If any command in a pipeline fails, the whole pipeline fails

# Block running as root because gsettings, dconf, vim, and $HOME paths must belong
# to user account.
# (EUID holds the Effective User ID and root is 0)
if [[ "$EUID" -eq 0 ]]; then
    echo "ERROR: Do not run this script as root."
    exit 1
fi


#==========================#
# Dotfile Linking Function #
#==========================#

link_dotfile() {
    local source_path="$1"
    local target_path="$2"

    if [[ ! -e "$source_path" ]]; then
        echo "--- Skipping '$target_path' (Source '$source_path' does not exist) ---"
        return 0
    fi

    mkdir -p "$(dirname "$target_path")" # dirname gets the parent folder path

    # Back up any real files/directories that exists and are not symlinks.
    if [[ -e "$target_path" && ! -L "$target_path" ]]; then
        echo "--- Backing up original config: $target_path -> ${target_path}.bak ---"
        mv "$target_path" "${target_path}.bak"
    fi

    # Create symbolic link.
    if ! ln -sfn "$source_path" "$target_path"; then
        echo "ERROR: Failed to link '$target_path'."
        exit 1
    fi

    echo "=== Linked: $target_path -> $source_path ==="
}

#===================================#
# Configuration Variables and Lists #
#===================================#
DOTFILES_DIR="$HOME/dotfiles"

DOTFILES_REPO="https://github.com/stelios-spyrounakos/dotfiles.git"

# GNOME Shell Extensions to enable (run 'gnome-extensions list' UUIDs).
GNOME_EXTENSIONS=(
    "dash-to-dock@micxgx.gmail.com"
    "appindicatorsupport@rgcjonas.gmail.com"
    # "blur-my-shell@aunetx"
    # "arcmenu@arcmenu.com"
)

#=================#
# System Services #
#=================#

echo "#============================#"
echo "# Setting Up System Services #"
echo "#============================#"

# Weekly SSD TRIM
#echo "--- Enabling weekly SSD TRIM timer (fstrim.timer) ---"
#sudo systemctl enable --now fstrim.timer

# Automatic Pacman Cache Cleanup
if [[ -f /usr/lib/systemd/system/paccache.timer ]]; then
    echo "--- Enabling weekly pacman cache cleanup (paccache.timer) ---"
    sudo systemctl enable --now paccache.timer
else
    echo "--- 'pacman-contrib' not installed. Skipping paccache.timer. ---"
fi

# Cronie Daemon
if [[ -f /usr/lib/systemd/system/cronie.service ]]; then
    echo "--- Enabling cronie.service ---"
    sudo systemctl enable --now cronie.service
else
    echo "--- 'cronie' not installed. Skipping cronie.service. ---"
fi

# Uncomplicated Firewall (UFW)
#if command -v ufw &> /dev/null; then
#    echo "--- Configuring and enabling Firewall (ufw) ---"
#    sudo ufw default deny incoming
#    sudo ufw default allow outgoing
#    sudo ufw --force enable
#    sudo systemctl enable --now ufw.service
#else
#    echo "--- 'ufw' is not installed. Skipping firewall setup. ---"
#fi

echo "=== System services configured. ==="

#================#
# Dotfiles Setup #
#================#

echo ""
echo "#==================#"
echo "# Linking Dotfiles #"
echo "#==================#"

if [[ -n "$DOTFILES_REPO" && ! -d "$DOTFILES_DIR" ]]; then
    echo "--- Cloning dotfiles repository into $DOTFILES_DIR ---"
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
fi

if [[ -d "$DOTFILES_DIR" ]]; then
    # ~ home dotfiles
    link_dotfile "$DOTFILES_DIR/.dir_colors"   "$HOME/.dir_colors"
    link_dotfile "$DOTFILES_DIR/.gitconfig"    "$HOME/.gitconfig"
    link_dotfile "$DOTFILES_DIR/.zshenv"       "$HOME/.zshenv"

    # XDG config folders
    link_dotfile "$DOTFILES_DIR/ghostty"       "$HOME/.config/ghostty"
    link_dotfile "$DOTFILES_DIR/tmux"          "$HOME/.config/tmux"
    link_dotfile "$DOTFILES_DIR/vim"           "$HOME/.config/vim"
    link_dotfile "$DOTFILES_DIR/zathura"       "$HOME/.config/zathura"
    link_dotfile "$DOTFILES_DIR/zsh"           "$HOME/.config/zsh"

    # Extra directory
    link_dotfile "$DOTFILES_DIR/setup"           "$HOME/.config/setup"

    # Wallpapers
    link_dotfile "$DOTFILES_DIR/backgrounds"   "$HOME/.local/share/backgrounds"

    echo "=== Dotfiles linked. ==="
else
    echo "--- Dotfiles folder ($DOTFILES_DIR) not found. Skipping dotfile links. ---"
fi

#=============#
# GNOME Setup #
#=============#

echo ""
echo "#====================================#"
echo "# Applying GNOME Settings and Tweaks #"
echo "#====================================#"

if command -v gsettings &> /dev/null; then

    # Appearance and peripherals
    echo "--- Applying GNOME desktop preferences ---"
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    gsettings set org.gnome.desktop.interface show-battery-percentage true
    gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'

    # Workspaces
    echo "--- Configuring GNOME Workspaces ---"
    gsettings set org.gnome.mutter dynamic-workspaces false
    gsettings set org.gnome.desktop.wm.preferences num-workspaces 5
    gsettings set org.gnome.mutter workspaces-only-on-primary true
    gsettings set org.gnome.shell.app-switcher current-workspace-only true

    # Keybindings
    echo "--- Configuring Keybindings ---"
    gsettings set org.gnome.desktop.wm.keybindings close "['<Super>q']"
    gsettings set org.gnome.desktop.wm.keybindings toggle-fullscreen "['<Super>f']"

    # Clear GNOME's default dock launcher bindings
    gsettings set org.gnome.shell.keybindings switch-to-application-1 "[]"
    gsettings set org.gnome.shell.keybindings switch-to-application-2 "[]"
    gsettings set org.gnome.shell.keybindings switch-to-application-3 "[]"
    gsettings set org.gnome.shell.keybindings switch-to-application-4 "[]"
    gsettings set org.gnome.shell.keybindings switch-to-application-5 "[]"

    # Switch to Workspaces
    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-1 "['<Super>1']"
    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-2 "['<Super>2']"
    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-3 "['<Super>3']"
    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-4 "['<Super>4']"
    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-5 "['<Super>5']"

    # Move active window
    gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-1 "['<Super><Shift>1']"
    gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-2 "['<Super><Shift>2']"
    gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-3 "['<Super><Shift>3']"
    gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-4 "['<Super><Shift>4']"
    gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-5 "['<Super><Shift>5']"

    # Custom Keybindings
    echo "--- Configuring Custom Keybindings---"
    KEY_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings"

    gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['${KEY_PATH}/custom0/']"

    # Custom Slot 0: Launch Terminal
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${KEY_PATH}/custom0/ name "Launch Terminal"
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${KEY_PATH}/custom0/ command "ghostty"
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${KEY_PATH}/custom0/ binding "<Super>Return"

    # GNOME Shell Extensions
    echo "--- Enabling GNOME Shell Extensions ---"
    for ext in "${GNOME_EXTENSIONS[@]}"; do
        if gnome-extensions info "$ext" &> /dev/null; then
            gnome-extensions enable "$ext"
            echo " Enabled extension: $ext"
        else
            echo " WARNING: Extension '$ext' is not installed. Skipping."
        fi
    done

    DCONF_FILE="$DOTFILES_DIR/setup/gnome-extensions.dconf"
    if [[ -f "$DCONF_FILE" ]]; then
        echo "--- Backing up default Manjaro extension settings to ~/gnome-extensions.dconf.bak ---"
        dconf dump /org/gnome/shell/extensions/ > "$HOME/gnome-extensions.dconf.bak"

        echo "--- Loading custom extension settings from $DCONF_FILE ---"
        dconf load /org/gnome/shell/extensions/ < "$DCONF_FILE"
    else
        echo "--- No saved extension settings found at $DCONF_FILE. Skipping dconf load. ---"
    fi

    echo "=== GNOME settings and tweaks applied. ==="
fi

echo ""
echo "#===============================================#"
echo "# Post-install setup complete.                  #"
echo "# Log out or reboot for shell changes to apply. #"
echo "#===============================================#"