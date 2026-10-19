#!/usr/bin/env bash
# Zhen's T490 dotfiles installer.
# Run as your normal user (not root) from ~/dotfiles, in a TTY, before the first Hyprland login.
#
#   ./install.sh            everything below, in order
#   ./install.sh <step>     one step: packages | aur | system | stow | theme | ctf | pipx

set -euo pipefail

DOTS="$HOME/dotfiles"
STOW_PKGS=(hypr waybar swaync swayosd rofi kitty zsh starship yazi zathura btop bat gtk qt fontconfig fcitx5 nvim spicetify palette bin)

say()  { printf '\n\033[1;35m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m  ! %s\033[0m\n' "$*"; }
list() { grep -v '^\s*#' "$DOTS/packages/$1" | grep -v '^\s*$'; }
pkgs() { mapfile -t PKGS < <(list "$1"); }

# Split a list into packages the enabled repos have (REPO) and the rest (OTHER, for yay),
# so one AUR-only or BlackArch-only name can't abort the whole pacman run.
split_pkgs() {
    pkgs "$1"
    declare -A have=()
    while read -r p; do have[$p]=1; done < <(pacman -Slq)
    REPO=(); OTHER=()
    for p in "${PKGS[@]}"; do
        if [[ -n "${have[$p]:-}" ]]; then REPO+=("$p"); else OTHER+=("$p"); fi
    done
}

preflight() {
    [[ $EUID -ne 0 ]] || { echo "Run as your user, not root."; exit 1; }
    [[ "$(realpath "$(dirname "$0")")" == "$(realpath "$DOTS")" ]] || {
        echo "Clone the repo to ~/dotfiles first (the palette config expects that path)."; exit 1; }
    ping -c1 -W3 archlinux.org >/dev/null 2>&1 || { echo "No internet. Connect with nmtui first."; exit 1; }
}

step_packages() {
    say "Installing desktop packages"
    sudo pacman -Syu --noconfirm
    split_pkgs desktop.txt
    sudo pacman -S --needed --noconfirm "${REPO[@]}"
    if ! command -v yay >/dev/null; then
        say "Bootstrapping yay"
        local tmp; tmp=$(mktemp -d)
        git clone https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
        (cd "$tmp/yay-bin" && makepkg -si --noconfirm)
        rm -rf "$tmp"
    fi
    if ((${#OTHER[@]})); then
        warn "Not in the official repos, trying the AUR: ${OTHER[*]}"
        yay -S --needed --noconfirm "${OTHER[@]}" || warn "Some of these failed; install them later"
    fi
}

step_aur() {
    say "Installing AUR packages (never with sudo)"
    pkgs aur.txt
    yay -S --needed --noconfirm "${PKGS[@]}"
}

step_system() {
    say "Copying system tweaks into /etc"
    sudo cp -rv "$DOTS/system/etc/." /etc/

    say "Fingerprint for sudo"
    if ! grep -q pam_fprintd /etc/pam.d/sudo; then
        sudo sed -i '0,/^auth/s//auth      sufficient pam_fprintd.so\nauth/' /etc/pam.d/sudo
    fi

    say "Firmware updates: point fwupd at the /efi partition"
    if [[ -f /etc/fwupd/fwupd.conf ]] && ! grep -q '^EspLocation' /etc/fwupd/fwupd.conf; then
        if grep -q '^\[fwupd\]' /etc/fwupd/fwupd.conf; then
            sudo sed -i '/^\[fwupd\]/a EspLocation=/efi' /etc/fwupd/fwupd.conf
        else
            printf '[fwupd]\nEspLocation=/efi\n' | sudo tee -a /etc/fwupd/fwupd.conf >/dev/null
        fi
    fi

    say "Enabling services"
    # NetworkManager-dispatcher is required by tlp-rdw (radio switching on dock/undock, wifi/LAN)
    sudo systemctl enable NetworkManager NetworkManager-dispatcher sddm bluetooth tlp thermald cronie grub-btrfsd
    sudo systemctl mask systemd-rfkill.service systemd-rfkill.socket
    systemctl --user enable gnome-keyring-daemon.socket || warn "gnome-keyring socket not found"

    say "Groups and folders"
    getent group wireshark >/dev/null && sudo usermod -aG wireshark "$USER" || true
    xdg-user-dirs-update
    mkdir -p "$HOME/Pictures/Screenshots"
    [[ "$SHELL" == */zsh ]] || chsh -s /bin/zsh
}

step_stow() {
    say "Linking dotfiles with stow"
    local backup
    backup="$HOME/.dotfiles-backup/$(date +%F_%H%M%S)"
    for pkg in "${STOW_PKGS[@]}"; do
        # move any real file that would block a link into the backup folder
        while IFS= read -r -d '' f; do
            local rel="${f#"$DOTS/$pkg/"}" target="$HOME/${f#"$DOTS/$pkg/"}"
            if [[ -e "$target" && ! -L "$target" ]]; then
                mkdir -p "$backup/$(dirname "$rel")"
                mv "$target" "$backup/$rel"
                warn "backed up ~/$rel"
            fi
        done < <(find "$DOTS/$pkg" -type f -print0)
        stow --no-folding -d "$DOTS" -t "$HOME" -R "$pkg"
    done
    fc-cache -f >/dev/null
}

step_theme() {
    say "Applying GTK, icon, cursor and font settings"
    gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    gsettings set org.gnome.desktop.interface icon-theme 'WhiteSur-dark'
    gsettings set org.gnome.desktop.interface cursor-theme 'Adwaita'
    gsettings set org.gnome.desktop.interface cursor-size 24
    gsettings set org.gnome.desktop.interface font-name 'Inter 10'
    gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrainsMono Nerd Font 10'

    say "Spicetify"
    if [[ -d /opt/spotify ]] && command -v spicetify >/dev/null; then
        sudo chmod a+wr /opt/spotify /opt/spotify/Apps -R
        spicetify config current_theme palette color_scheme base >/dev/null
        spicetify backup apply || warn "Open Spotify once, log in, close it, then run: spicetify backup apply"
    else
        warn "Spotify or spicetify not installed yet; rerun: ./install.sh theme"
    fi
}

step_ctf() {
    say "CTF tools"
    if ! grep -q '^\[blackarch\]' /etc/pacman.conf; then
        echo "BlackArch repo is not set up. Get the current SHA1 from https://blackarch.org/downloads.html"
        read -rp "Paste the strap.sh SHA1 (or Enter to skip BlackArch): " sha
        if [[ -n "$sha" ]]; then
            local tmp; tmp=$(mktemp -d)
            curl -fsSL -o "$tmp/strap.sh" https://blackarch.org/strap.sh
            echo "$sha  $tmp/strap.sh" | sha1sum -c -
            sudo bash "$tmp/strap.sh"
            rm -rf "$tmp"
        else
            warn "Skipping BlackArch; burpsuite, zsteg and stegsolve will fail to install"
        fi
    fi
    sudo pacman -Syu --noconfirm
    split_pkgs ctf.txt
    sudo pacman -S --needed "${REPO[@]}" || warn "Some CTF packages failed; check the names above"
    if ((${#OTHER[@]})); then
        yay -S --needed --noconfirm "${OTHER[@]}" || warn "Not found anywhere: ${OTHER[*]}"
    fi
    pkgs aur-ctf.txt
    yay -S --needed --noconfirm "${PKGS[@]}" || warn "Some AUR CTF packages failed"
    [[ -f /usr/share/wordlists/rockyou.txt.gz ]] && sudo gunzip -k /usr/share/wordlists/rockyou.txt.gz || true
    getent group wireshark >/dev/null && sudo usermod -aG wireshark "$USER" || true
}

step_pipx() {
    say "pipx tools"
    pipx ensurepath >/dev/null
    while read -r t; do pipx install "$t" || warn "pipx: $t failed"; done < <(list pipx.txt)
}

main() {
    preflight
    if [[ $# -gt 0 ]]; then "step_$1"; exit; fi
    step_packages
    step_aur
    step_system
    step_stow
    step_theme
    step_ctf
    step_pipx
    say "Done. Reboot, then log in to Hyprland from SDDM."
    echo "  Enroll your fingerprint after reboot (as yourself, no sudo): fprintd-enroll"
}

main "$@"
