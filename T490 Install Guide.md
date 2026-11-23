# Overview
Machine details: T490, 15-826U, Intel UHD 620, 16GB Ram, 256GB NVMe

Desktop:

| Role | Option |
| --- | --- |
| Compositor | Hyprland |
| Bar | Waybar |
| Notifications | swaync + swayosd |
| Launcher | Rofi |
| Lock / idle | hyprlock + hypridle |
| Terminal | kitty + zsh + starship |
| File Manager | Dolphin + Yazi |
| Look | Inter + JetBrains Mono, WhiteSur icons, Adwaita cursor, adw-gtk3-dark, Kvantum |
| Login Screen | SDDM + SilentSDDM theme |
| Browser | Vivaldi |
| Music | Spotify + Spicetify |
| MD + LaTeX Viewer | Leaf |
| Other Apps | Claude desktop |

# Part 0 - Setup
## BIOS Settings

This are BIOS settings specific for the ThinkPad T490
- Security:
	- Secure Boot: Disabled
	- Virtualization: Intel VT-x and VT-d Enabled
- Startup
	- UEFI/Legacy Boot: UEFI Only

**Bios version:** 1.54 or newer. BIOS 1.52 throttles CPU to 400 MHz too early. If BIOS is out of date, you can update it with `fwupd`

## Live USB

Download the ISO from archlinux.org, then write to USB
```
sudo dd if=archlinux.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

# Part 1 - Boot from Live USB
## 1. Setup Environment

1. Check that system booted in UEFI mode. Must print `64`:
```bash 
cat /sys/firmware/efi/fw_platform_size
```

2. Connect to Wi-Fi:
```bash
iwctl
# inside iwctl:
device list
station wlan0 scan
station wlan0 get-networks
station wlan0 connect "SSID"
exit

# test connection
ping -c3 google.com
```

3. Sync the clock:
```bash
timedatectl set-ntp true
```

4. Change to nearby mirror with reflector:
```bash
reflector --country Singapore/Malaysia --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
````

5. Edit `/etc/pacman.conf` and uncomment `Color` and ``ParallelDownloads = 5``

## 2. Disk Partitioning and Formatting
This setup uses two GPT partitions: a 1GB EFI partition and ext4 for the rest.
| # | Partition | Type | Size |
| 1 | `/dev/nvme0n1p1` | EFI System | 1GB |
| 2 | `/dev/nvme0n1p2` | Linux filesystem | rest of disk |

1. Partition:
```bash
fdisk -l # show disks
fdisk /dev/nvme0n1

# inside fdisk
g # create new partition table
n # create EFI partition. partition number: 1(default), first sector: default, last sector: +1G
t # partition type: 1(EFI)
n # create root partition. partition number: 2(default), first sector: default, last sector: default
p # print partition table to verify
w # write changes
```

2. Format:
```bash
mkfs.fat -F32 /dev/nvme0n1p1
mkfx.ext4 /dev/nvme0n1p2
```

3. Mount root partition and EFI:
```bash
mount /dev/nvme0n1p2 /mnt
mkdir -p /mnt/efi
mount /dev/nvme0n1p1 /mnt/efi
```

## 3. Install Base System
```bash
pacstrap -K /mnt \
  base linux linux-lts linux-firmware intel-ucode e2fsprogs \
  grub efibootmgr \
  base-devel git \
  networkmanager \
  sudo vim neovim man-db man-pages \
  pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber \
  sof-firmware alsa-ucm-conf \
  zsh zsh-completions zsh-autosuggestions zsh-syntax-highlighting \
  openssh reflector

genfstab -U /mnt >> /mnt/etc/fstab
cat /mnt/etc/fstab          # check: / (ext4) and /efi are both listed
```

## 4. Configure the system (inside chroot)
1. chroot onto /mnt on the system SSD
```bash
arch-chroot /mnt
```

2. Time zone:
```bash
ln -sf /usr/share/zoneinfo/Asia/Kuala_Lumpur /etc/localtime
hwclock --systohc
```

3. Locale. First uncomment `en_US.UTF-8 UTF-8` in `/etc/locale.gen`
```bash
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "KEYMAP=us" > /etc/vconsole.conf
```

4. Hostname and hosts:
```bash
echo "t490" > /etc/hostname
```
Edit `/etc/hosts` to match
```bash
127.0.0.1 localhost
::1 localhost
127.0.1.1 t490
```

5. Set root password, user and sudo:
```bash
passwd
useradd -mG wheel -s /bin/zsh zhen
passwd zhen
EDITOR=vim visudo # uncomment: %wheel ALL=(ALL:ALL) ALL
```

6. Enable NetworkManager
```bash
systemctl enable NetworkManager
```

7. Turn on multilib (32-bit graphics libraries). In `/etc/pacman.conf` uncomment `[multilib]` lines and `Color` and `ParallelDownloads = 5`. Then:
```bash
pacman -Sy
```

## 5. GRUB
1. Install GRUB:
```bash
grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB
grub-install --target=x86_64-efi --efi-directory=/efi --removable
grub-mkconfig -o /boot/grub/grub.cfg
```

## 6. Minimal Hyprland + SDDM
Install just enough to reach a working Hyprland login.
```bash
pacman -S hyprland sddm kitty \
xdg-desktop-portal-hyprland xdg-desktop-portal-gtk \
qt5-wayland qt6-wayland \
polkit hyprpolkitagent \
noto-fonts ttf-jetbrains-mono-nerd

systemctl enable sddm
```

Exit and reboot:
```bash
exit
umount -R /mnt
reboot
```

# Part 2 - Boot into System
## 1. First Boot
At SDDM, switch to a TTY with **Ctrl+Alt+F3**, login as `zhen`. Zsh asks a first run question, press `q` (`.zshrc` config later)
1. Connect and update
```bash
nmtui
ping -c3 google.com
sudo pacman -Syu
```

2. Install yay
```bash
git clone https://aur.archlinux.org/yay.git /tmp/yay
cd /tmp/yay && makepkg -si
```

3. setup zram swap (8GB):
```bash
sudo pacman -S zram-generator
sudo tee /etc/systemd/zram-generator.conf <<'EOF'
[zram0]
zram-size = min(ram / 2, 8192)
compression-algorithm = zstd
EOF
echo "vm.swappiness = 150" | sudo tee /etc/sysctl.d/99-zram.conf
sudo systemctl daemon-reload
sudo systemctl start systemd-zram-setup@zram0.service
zramctl # check it's live
```

4. setup swapfile
```bash
sudo mkswap -U clear --size 16G --file /swapfile
sudo swapon /swapfile
echo '/swapfile none swap defaults,pri=10 0 0' | sudo tee -a /etc/fstab
```

## 2. Install GRUB theme

3. edit grub file, change `#GRUB_THEME=` to `GRUB_THEME="/boot/grub/themes/tokyo-night/theme.txt"`
```bash
sudo vim /etc/default/grub
```

5. change config then reboot

```bash
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

## 3. Install dotfiles
1. Clone the repo:
```bash
git clone https://github.com/finn1282/dotfiles ~/dotfiles
cd ~/dotfiles
```
It must live at `~/dotfiles`, because the palette config writes there

2. Run it:
```bash
./install.sh
```

3. It runs these steps in order. Rerun any one with `./install.sh <step>`:

| Step       | What it does                                                                                                                                                                                                                                                                  |
| ---------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `packages` | Your real package list plus swaync, swayosd, Inter, adw-gtk3, stow, fwupd, udisks2, bolt (Thunderbolt), wireless-regdb; bootstraps yay. Anything not in the official repos goes to yay instead of stopping the run                                                            |
| `aur`      | Zen, Brave, Spotify, WhiteSur icons, SilentSDDM theme, Leaf markdown viewer, Claude desktop, Claude Code, and the Ghidra and Playwright MCP servers                                                                                                                           |
| `system`   | Audio-pop fix, TLP 75–80% charge limit, lid suspend, zram, Malaysian Wi-Fi region, Bluetooth off at boot, SDDM set to SilentSDDM, fprintd stop timeout (5 s), weekly SSD TRIM, fwupd pointed at /efi, services (incl. NetworkManager-dispatcher for tlp-rdw), wireshark group |
| `sddm`     | Copies your wallpaper and login-screen config into the SilentSDDM theme. Preview it before rebooting: cd /usr/share/sddm/themes/silent && ./test.sh                                                                                                                           |
| `stow`     | Links every config into `~/.config`; any file in the way is moved to `~/.dotfiles-backup/`                                                                                                                                                                                    |
| `theme`    | GTK/icon/font settings and the Adwaita cursor; installs Spicetify with its official script (the AUR spicetify-cli build fails) and applies the palette theme                                                                                                                  |
| `ctf`      | Asks for the BlackArch SHA1, adds the repo, installs your CTF tools and wordlists                                                                                                                                                                                             |
| `pipx`     | pwntools, git-dumper, ida-pro-mcp                                                                                                                                                                                                                                             |
4. Reboot, then log in to Hyprland from SDDM

# Part 3 - After First Login
1. Update firmware (stay on AC power):
```bash
fwupdmgr refresh && fwupdmgr update
```

2. Enroll fingerprint, not as sudo: `fprintd-enroll`. Then test with `fprintd-verify`.
3. Spotify: open it once, login, close it, then run `spicetiy backup apply`
4. Chinese input: `fcitx5-configtool` should already list Pinyin (your config is in the repo). Switch with **Ctrl+Space**.
5. Check the mute keys. `aplay -l` should show your sound card as `PCH` (it did on your current install). If F1/F4 light up out of step with the sound, run `~/.config/hypr/scripts/audio-mute.sh output` once to resync.

# Part 4 - Final Checklist
**T490 hardware checks** (do these once on the new install):

| Part                                                    | Driver / package                                   | How to check                                                   | If it fails                                         |
| ------------------------------------------------------- | -------------------------------------------------- | -------------------------------------------------------------- | --------------------------------------------------- |
| Graphics (UHD 620)                                      | i915, `mesa`, `vulkan-intel`, `intel-media-driver` | `vainfo` lists H.264/HEVC                                      | Reinstall `intel-media-driver`                      |
| Wi-Fi (Intel 9560)                                      | iwlwifi, `linux-firmware`                          | `iw reg get` shows `country MY`                                | Reboot after install.sh (region applies at boot)    |
| Bluetooth                                               | btusb, `bluez`                                     | Off after boot; right-click the bar icon to turn on, then pair | `rfkill list`; unblock                              |
| Speakers                                                | snd_hda_intel, `sof-firmware`, `alsa-ucm-conf`     | `speaker-test -c2 -twav`                                       | A faint hiss during playback is a known T490 issue  |
| Internal mic                                            | DMIC                                               | `arecord -d 5 /tmp/t.wav && aplay /tmp/t.wav`                  | Send me the check script output                     |
| Mute LEDs                                               | `alsa-utils` (amixer, card `PCH`)                  | F1/F4 lights follow mute                                       | `audio-mute.sh output` resyncs                      |
| Fingerprint (06cb:00bd)                                 | `fprintd` + firmware via `fwupd`                   | `fprintd-verify`                                               | `fwupdmgr enable-remote lvfs-testing`, then update  |
| Thunderbolt 3 (USB-C)                                   | thunderbolt, `bolt`                                | `boltctl list` shows docks                                     | `boltctl enroll <uuid>`                             |
| Battery limits                                          | thinkpad_acpi, `tlp`                               | `sudo tlp-stat -b` shows 75/80                                 | `sudo systemctl restart tlp`                        |
| Fan / thermals                                          | thinkpad_acpi, `thermald`                          | `sensors`, idle 40–55 °C                                       | Firmware controls the fan; no tool needed           |
| Firmware                                                | `fwupd`, `udisks2`                                 | `fwupdmgr get-devices` lists System Firmware                   | Check `EspLocation=/efi` in `/etc/fwupd/fwupd.conf` |
| Webcam, SD reader, TrackPoint, touchpad, keyboard light | in the kernel                                      | They just work                                                 | —                                                   |


**Keys to know:** `Super+/` keybind cheatsheet · `Super+C` terminal · `Super+R` launcher · `Super+B` browser · `Super+A` Claude · `Super+E` Dolphin · `Super+W` Yazi · `Super+N` notifications · `Super+.` clipboard history · `Super+arrows` resize (hold to repeat) · `Print` screenshot · `Super+Print` region to annotate · `Super+P` lock · `Super+M` power menu.

**Editing later:** files in `~/.config` are links into `~/dotfiles`, so edit either and `git commit` in the repo. Don't press Save in nwg-look or qt6ct: they replace the links with plain files. After changing a palette template, run `make-palette`.

# Reused Commands
1. Connecting to WPA2 Enterprise networks
```bash
nmcli connection add type wifi ifname <NetworkInterface> \
con-name <ProfileName> ssid <SSID> wifi-sec.key-mgmt wpa-eap \
802-1x.eap peap \
802.1x.phase2-auth mschapv2 \
802.1x.identity "<username>" \
802.1x.password "<password>" \
nmcli connection up "<ProfileName>"
```
