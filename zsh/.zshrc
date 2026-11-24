fastfetch

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

######################
### General config ###
######################

### Options section

setopt correct                      # Autocorrect mistakes
setopt extendedglob                 # Extended globbing. Allows using regular expressions with *.
setopt nocaseglob                   # Case insensitive globbing.
setopt rcexpandparam                # Array expension with parameters.
setopt nocheckjobs                  # Don't warn about running processes when exiting.
setopt numericglobsort              # Sort filenames numerically when it makes sense.
setopt nobeep                       # No beep.
setopt appendhistory                # Immediately append history instead of overwriting.
setopt share_history                # Share history between sessions
setopt histignorealldups            # If a new command is a duplicate, remove the older one.
setopt autocd                       # If only a directory path is entered, cd there.
setopt inc_append_history           # Save commands to history immediately.
setopt histignorespace              # Don't save commands that start with space.

autoload -U compinit
compinit -d
# Configuring completion behavior
zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}'   # Case insensitive tab completion.
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"                             # Colored completions.
zstyle ':completion:*' rehash true                                                  # Automatically find new executables in path .
zstyle ':completion:*' menu select                                                  # Highlight menu selection.

# Speed-up and caching for completions
zstyle ':completion:*' accept-exact '*(N)'              # Accept exact matches immediately.
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.config/zsh/cache

# Configure history file and size
HISTFILE=~/.config/zsh/zhistory
HISTSIZE=50000
SAVEHIST=50000

# Set preferred editor
export EDITOR=/usr/bin/vim
export VISUAL=/usr/bin/vim

# Modify WORDCHARS to exclude certain punctuation from being considered part of a word.
WORDCHARS=${WORDCHARS//\/[&.;]}                        # Don't consider certain characters part of the word

autoload -U zcalc

###################
### Keybindings ###
###################

bindkey -v                                              # Set vim-style keybindings

bindkey '^[[7~' beginning-of-line                       # Home key
bindkey '^[[H' beginning-of-line                        # Home key (alternate)
if [[ "${terminfo[khome]}" != "" ]]; then
  bindkey "${terminfo[khome]}" beginning-of-line        # Terminfo's Home key, if available
fi
bindkey '^[[8~' end-of-line                             # End key
bindkey '^[[F' end-of-line                              # End key (alternate)
if [[ "${terminfo[kend]}" != "" ]]; then
  bindkey "${terminfo[kend]}" end-of-line               # Terminfo's End key, if available
fi
bindkey '^[[2~' overwrite-mode                          # Insert key
bindkey '^[[3~' delete-char                             # Delete key
bindkey '^[[C'  forward-char                            # Right arrow key
bindkey '^[[D'  backward-char                           # Left arrow key
bindkey '^[[5~' history-beginning-search-backward       # Page up key
bindkey '^[[6~' history-beginning-search-forward        # Page down key

# Navigate words with Ctrl+arrow keys.
bindkey '^[Oc' forward-word                             # Ctrl+Right arrow key
bindkey '^[[1;5C' forward-word                          # Ctrl+Right arrow key (alternate)
bindkey '^[Od' backward-word                            # Ctrl+Left arrow key
bindkey '^[[1;5D' backward-word                         # Ctrl+Left arrow key (alternate)

bindkey '^H' backward-kill-word                         # Ctrl+Backspace: Delete the word before the cursor
bindkey '^[[Z' undo                                     # Shift+tab: Undo last action

###############
### Theming ###
###############

autoload -U colors
colors

# File and Dir color settings
export LS_OPTIONS='--color=auto'
eval "$(dircolors -b)"

# Colorize man pages.
export LESS_TERMCAP_mb=$'\E[01;32m'
export LESS_TERMCAP_md=$'\E[01;32m'
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_se=$'\E[0m'
export LESS_TERMCAP_so=$'\E[01;47;34m'
export LESS_TERMCAP_ue=$'\E[0m'
export LESS_TERMCAP_us=$'\E[01;36m'
export LESS=-R                          # Instruct less to output raw control characters

###############
### Aliases ###
###############

alias ls='ls $LS_OPTIONS'
alias cp="cp -i"                                                # Confirm before overwriting
alias df='df -h'                                                # Human-readable sizes
alias free='free -m'                                            # Show sizes in MB

###############
### Plugins ###
###############

# Use syntax highlighting, history substring search and autosuggestions
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=244'


# Load terminfo module to get terminal key codes.
zmodload zsh/terminfo
# Bind Up and Down arrow keys to history substring search functions.
bindkey "$terminfo[kcuu1]" history-substring-search-up
bindkey "$terminfo[kcud1]" history-substring-search-down
bindkey '^[[A' history-substring-search-up			
bindkey '^[[B' history-substring-search-down

########################
### Window/tab title ###
########################

# Function to set terminal window and tab/icon title.
#
# usage: title short_tab_title [long_window_title]
#
# See: http://www.faqs.org/docs/Linux-mini/Xterm-Title.html#ss3.1
# Fully supports screen and probably most modern xterm and rxvt
# (In screen, only short_tab_title is used)
function title {
  emulate -L zsh            # Localize changes to the current function
  setopt prompt_subst       # Allow prompt substitutions

  [[ "$EMACS" == *term* ]] && return    # Skip title changes when running in an Emacs terminal

  # If $2 is unset use $1. If it is set and empty, leave it as is
  : ${2=$1}

  # Use the proper escape sequences depending on the terminal type
  case "$TERM" in
    xterm*|putty*|rxvt*|konsole*|ansi|mlterm*|alacritty|kitty|wezterm|st*)
      print -Pn "\e]2;${2:q}\a"     # Set window title
      print -Pn "\e]1;${1:q}\a"     # Set tab title
      ;;
    screen*|tmux*)
      print -Pn "\ek${1:q}\e\\"     # Only tab/title supported
      ;;
    *)
    # Use terminfo capabilities if available
    if [[ -n "$terminfo[fsl]" ]] && [[ -n "$terminfo[tsl]" ]]; then
      echoti tsl
      print -Pn "$1"
      echoti fsl
    fi
      ;;
  esac
}

# Variables for default terminal title formatting.
ZSH_THEME_TERM_TAB_TITLE_IDLE="%15<..<%~%<<"    # Format for tab title, truncated to 15 characters.
ZSH_THEME_TERM_TITLE_IDLE="%n@%m:%~"            # Format for window title showing user, host (short), and path

# Function to run before showing the prompt.
function mzc_termsupport_precmd {
  [[ "${DISABLE_AUTO_TITLE:-}" == true ]] && return
  title $ZSH_THEME_TERM_TAB_TITLE_IDLE $ZSH_THEME_TERM_TITLE_IDLE
}

# Function to run before executing a command.
function mzc_termsupport_preexec {
  [[ "${DISABLE_AUTO_TITLE:-}" == true ]] && return

  emulate -L zsh
  # Split command into array of arguments
  local -a cmdargs
  cmdargs=("${(z)2}")
  # If the command is 'fg' (foreground a job), try to extract the actual command
  if [[ "${cmdargs[1]}" = fg ]]; then
    # Get the job id from the first argument passed to the fg command
    local job_id jobspec="${cmdargs[2]#%}"
    # logic based on jobs arguments:
    # http://zsh.sourceforge.net/Doc/Release/Jobs-_0026-Signals.html#Jobs
    # https://www.zsh.org/mla/users/2007/msg00704.html
    case "$jobspec" in
      <->) # %number argument:
        # Use the same <number> passed as an argument
        job_id=${jobspec} ;;
      ""|%|+) # empty, %% or %+ argument:
        # Use the current job, which appears with a + in $jobstates:
        # suspended:+:5071=suspended (tty output)
        job_id=${(k)jobstates[(r)*:+:*]} ;;
      -) # %- argument:
        # Use the previous job, which appears with a - in $jobstates:
        # suspended:-:6493=suspended (signal)
        job_id=${(k)jobstates[(r)*:-:*]} ;;
      [?]*) # %?string argument:
        # Use $jobtexts to match for a job whose command *contains* <string>
        job_id=${(k)jobtexts[(r)*${(Q)jobspec}*]} ;;
      *) # %string argument:
        # Use $jobtexts to match for a job whose command *starts with* <string>
        job_id=${(k)jobtexts[(r)${(Q)jobspec}*]} ;;
    esac

    # If a matching job text is found, override preexec arguments
    if [[ -n "${jobtexts[$job_id]}" ]]; then
      1="${jobtexts[$job_id]}"
      2="${jobtexts[$job_id]}"
    fi
  fi

  # Simplified command name for title display (options and sudo/ssh/etc. are stripped)
  local CMD=${1[(wr)^(*=*|sudo|ssh|mosh|rake|-*)]:gs/%/%%}
  local LINE="${2:gs/%/%%}"

  # Update terminal title with current command information
  title "$CMD" "%100>...>$LINE%<<"
}

# Register the functions to be executed before the prompt and before executing a command.
autoload -U add-zsh-hook
add-zsh-hook precmd mzc_termsupport_precmd
add-zsh-hook preexec mzc_termsupport_preexec

################################################
### Terminal Integration: CWD + URL Encoding ###
################################################

# Load module to access locale-related information
zmodload zsh/langinfo

# Function to URL-encode a string.
#
# Encodes a string using RFC 2396 URL-encoding (%-escaped).
# See: https://www.ietf.org/rfc/rfc2396.txt
#
# By default, reserved characters and unreserved "mark" characters are
# not escaped by this function. This allows the common usage of passing
# an entire URL in, and encoding just special characters in it, with
# the expectation that reserved and mark characters are used appropriately.
# The -r and -m options turn on escaping of the reserved and mark characters,
# respectively, which allows arbitrary strings to be fully escaped for
# embedding inside URLs, where reserved characters might be misinterpreted.
#
# Prints the encoded string on stdout.
# Returns nonzero if encoding failed.
#
# Usage:
#  zsh_urlencode [-r] [-m] [-P] <string> [<string> ...]
#
#    -r causes reserved characters (;/?:@&=+$,) to be escaped
#
#    -m causes "mark" characters (_.!~*''()-) to be escaped
#
#    -P causes spaces to be encoded as '%20' instead of '+'
function zsh_urlencode() {
  emulate -L zsh
  local -a opts
  # Parse options from the command-line arguments
  zparseopts -D -E -a opts r m P

  local in_str="$@"
  local url_str=""
  local spaces_as_plus
  # By default, spaces are replaced with '+' unless -P is specified.
  if [[ -z $opts[(r)-P] ]]; then spaces_as_plus=1; fi
  local str="$in_str"

  # URLs must use UTF-8 encoding; convert str to UTF-8 if required
  local encoding=$langinfo[CODESET]
  local safe_encodings
  safe_encodings=(UTF-8 utf8 US-ASCII)
  if [[ -z ${safe_encodings[(r)$encoding]} ]]; then
    str=$(echo -E "$str" | iconv -f $encoding -t UTF-8)
    if [[ $? != 0 ]]; then
      echo "Error converting string from $encoding to UTF-8" >&2
      return 1
    fi
  fi

  # Set LC_CTYPE=C to process the string byte-by-byte
  local i byte ord LC_ALL=C
  export LC_ALL
  local reserved=';/?:@&=+$,'
  local mark='_.!~*''()-'
  local dont_escape="[A-Za-z0-9"
  # By default, reserved characters are not escaped unless -r is given
  if [[ -z $opts[(r)-r] ]]; then
    dont_escape+=$reserved
  fi
  # By default, mark characters are not escaped unless -m is given
  # $mark must be last because of the "-"
  if [[ -z $opts[(r)-m] ]]; then
    dont_escape+=$mark
  fi
  dont_escape+="]"
  
  # Process each character: if it matches dont_escape, leave it;
  # otherwise, encode it (or replace spaces with '+' if applicable).
  # (Implemented to use a single printf call and avoid subshells in the loop for performance)
  local url_str=""
  for (( i = 1; i <= ${#str}; ++i )); do
    byte="$str[i]"
    if [[ "$byte" =~ "$dont_escape" ]]; then
      url_str+="$byte"
    else
      if [[ "$byte" == " " && -n $spaces_as_plus ]]; then
        url_str+="+"
      else
        ord=$(( [##16] #byte ))
        url_str+="%$ord"
      fi
    fi
  done
  echo -E "$url_str"
}

# Function to emit the OSC 7 control sequence to notify terminal emulators of the CWD
#
# Identifies the directory using a file: URI scheme, including
# the host name to disambiguate local vs. remote paths.
function mzc_termsupport_cwd {
  # Percent-encode the host and path names.
  local URL_HOST URL_PATH
  URL_HOST="$(zsh_urlencode -P $HOST)" || return 1
  URL_PATH="$(zsh_urlencode -P $PWD)" || return 1

  # Common control sequence (OSC 7) to set current host and path
  printf "\e]7;%s\a" "file://${URL_HOST}${URL_PATH}"
}

# Use a precmd hook instead of a chpwd hook to avoid contaminating output
# i.e. when a script or function changes directory without `cd -q`, chpwd
# will be called the output may be swallowed by the script or function.
add-zsh-hook precmd mzc_termsupport_cwd

##############
### Prompt ###
##############
source /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.config/zsh/p10k.zsh ]] || source ~/.config/zsh/p10k.zsh

export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - zsh)"
