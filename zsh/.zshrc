# History
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt hist_ignore_dups share_history

# Completions
autoload -Uz compinit && compinit
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# Environment
export EDITOR=nvim
export VISUAL=nvim
export PATH="$HOME/.local/bin:$HOME/go/bin:$HOME/.spicetify:$PATH:/usr/bin/vendor_perl:/usr/bin/core_perl"   # pipx tools, go binaries (ffuf), dotfiles scripts, spicetify, perl tools (exiftool)

# Aliases
alias ls='eza --icons --group-directories-first'
alias ll='eza -l --icons --git --group-directories-first'
alias la='eza -la --icons --git --group-directories-first'
alias tree='eza --tree --icons'
alias cat='bat --paging=never --style=plain'

# Yazi: cd into the folder you quit in
function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(<"$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}

# ctf-skills python setup
[[ -n $CLAUDECODE ]] && source ~/.ctf-tools/venv/bin/activate

# Prompt and plugins
eval "$(starship init zsh)"
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh   # keep last

export PATH=$PATH:/home/zhen/.spicetify
