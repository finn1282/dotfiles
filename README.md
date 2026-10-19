# T490 dotfiles

Arch + Hyprland 0.56 (Lua config) for a ThinkPad T490. Symphony's layout and swaync/swayosd styling,
Mac-style motion, and one palette generated from the star-chart wallpaper (matugen, neutral scheme).

## Install (fresh system, from a TTY, before the first Hyprland login)

    git clone <your-repo-url> ~/dotfiles     # must live at ~/dotfiles
    cd ~/dotfiles && ./install.sh

Steps can be rerun one at a time: `./install.sh packages | aur | system | stow | theme | ctf | pipx`.

## Layout

Each top-level folder is a GNU Stow package that mirrors your home folder.

| Package | What it holds |
| --- | --- |
| hypr | hyprland.lua, keybinds.lua, colors.lua, hypridle, hyprlock, hyprpaper, wallpaper, scripts |
| waybar | one full-width bar, colors.css |
| swaync, swayosd | notifications and volume/brightness popups |
| rofi | launcher, cheatsheet theme, colors.rasi |
| kitty, zsh, starship, bat, yazi, zathura, btop, nvim | terminal tools |
| gtk, qt, fontconfig | adw-gtk3-dark + palette, Kvantum KvGnomeDark, WhiteSur icons, Inter/JetBrainsMono |
| fcitx5 | Pinyin input |
| spicetify | Spotify theme |
| palette | matugen config + templates |
| bin | make-palette |
| system | /etc tweaks copied by install.sh (not stowed) |
| packages | package lists used by install.sh |

## Colors

All color files are generated from `hypr/.config/hypr/wallpaper.png`. To rebuild them after changing a template:

    make-palette

Exception: swaync's style has the palette written in directly, so edit `swaync/.config/swaync/style.css` by hand.

## Editing

Files in `~/.config` are links into this repo, so edit either place and commit here.
Don't use nwg-look or qt6ct's Save button: they replace the links with plain files.

Credits: swaync, swayosd, kitty and starship styling adapted from [vyrx-dev/symphony](https://github.com/vyrx-dev/symphony) (MIT, see LICENSE.symphony).
