#!/bin/bash
# ============================================================
#  SkywareOS X — Void Linux Edition
#  Based on bspwm | runit | xbps
# ============================================================
set -euo pipefail

echo "╔══════════════════════════════════════════════════════╗"
echo "║         SkywareOS X  —  Void Linux           ║"
echo "║           Full System Setup v0.1 Void                ║"
echo "╚══════════════════════════════════════════════════════╝"

# ── Colour helpers ───────────────────────────────────────────
RED="\e[31m"; GREEN="\e[32m"; YELLOW="\e[33m"
CYAN="\e[36m"; BOLD="\e[1m"; RESET="\e[0m"
GRAY="\e[38;5;245m"
ok()   { echo -e "${GREEN}✔${RESET} $*"; }
info() { echo -e "${CYAN}→${RESET} $*"; }
warn() { echo -e "${YELLOW}⚠${RESET} $*"; }
die()  { echo -e "${RED}✖${RESET} $*"; exit 1; }

# ── Must run as a normal user who has sudo ───────────────────
[[ $EUID -eq 0 ]] && die "Run as a normal user, not root."
command -v sudo &>/dev/null || die "sudo is not installed."

# ── Passwordless sudo for wheel ──────────────────────────────
info "Configuring passwordless sudo for wheel group..."
sudo bash -c "echo '%wheel ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/10-skyware"
sudo chmod 440 /etc/sudoers.d/10-skyware
ok "Passwordless sudo configured"

# ─────────────────────────────────────────────────────────────
#  LOGO — SkywareOS X
# ─────────────────────────────────────────────────────────────
LOGO='
                    .+@@@@@@@@@@@@@@*.
                 .%@@@@@@@@@@@@@@@@@@@@@@@@@.
              -@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@-
             %@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%
               @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
                 @@@@@@@@@@+::...:+@@@@@@@@@@@@@@@@@@@
                  .@@%.                .%@@@@@@@@@@@@@@:
     %%                                    %@@@@@@@@@@@@%
    @@@@.                                    %@@@@@@@@@@@@
   @@@@@@@.                                    @@@@@@@@@@@%
  @@@@@@@@@@.                                   :@@@@@@@@@@%
 -@@@@@@@@@@:                                    .@@@@@@@@@@.
 @@@@@@@@@@+                                      -@@@@@@@@@@
.@@@@@@@@@@           .@@@@+      .@@@@-           @@@@@@@@@@.
@@@@@@@@@@:          @@@@@@@@@    *@@@@@@          :@@@@@@@@@#
@@@@@@@@@@          @@:     @@@         @@          @@@@@@@@@@
@@@@@@@@@@          @@       @@@        =@          @@@@@@@@@@
@@@@@@@@@@          @@        @@@       =@          @@@@@@@@@@
@@@@@@@@@@          @@:        @@@:     @@          @@@@@@@@@@
@@@@@@@@@@:          @@@@@@@    .@@@@@@@@          :@@@@@@@@@@
:@@@@@@@@@@           .@@@@.      .@@@@.           @@@@@@@@@@.
 @@@@@@@@@@-                                      +@@@@@@@@@@
 -@@@@@@@@@@.                                    :@@@@@@@@@@:
  @@@@@@@@@@@:                                   .@@@@@@@@@@
   @@@@@@@@@@@@                                    .@@@@@@@
    @@@@@@@@@@@@+                                    =@@@@
     @@@@@@@@@@@@@%                                    %%
      +@@@@@@@@@@@@@@#.                .@@@.
       .@@@@@@@@@@@@@@@@@@@+:...::*@@@@@@@@@@
         .@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%
            @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%
              +@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@-
                 .@@@@@@@@@@@@@@@@@@@@@@@@@%.
                      .#@@@@@@@@@@@@@@#.
'
echo -e "${GRAY}${LOGO}${RESET}"
echo ""

# ─────────────────────────────────────────────────────────────
#  xbps helpers
# ─────────────────────────────────────────────────────────────
XI() { sudo xbps-install -Sy --yes "$@"; }   # install
XQ() { xbps-query -l | grep -q "^ii $1 "; }  # query installed

# ─────────────────────────────────────────────────────────────
#  1. System update + base packages
# ─────────────────────────────────────────────────────────────
echo ""
echo "══ [1/22] Base packages ══════════════════════════════"
sudo xbps-install -Su --yes   # full system upgrade first

XI \
    base-devel git curl wget \
    zsh zsh-autosuggestions zsh-syntax-highlighting \
    alacritty kitty \
    btop fastfetch cmatrix \
    fzf zoxide eza bat ripgrep fd \
    flatpak \
    libnotify \
    xorg xorg-server xorg-input-all xorg-video-all \
    xinit xrandr autorandr \
    dbus dbus-x11 \
    polkit polkit-gnome \
    networkmanager \
    python3 python3-pip \
    nodejs npm \
    imagemagick librsvg \
    figlet lolcat \
    tmux \
    openssh \
    ufw \
    fail2ban \
    apparmor \
    usbguard \
    bluez blueman \
    cups cups-filters \
    avahi nss-mdns \
    docker podman docker-compose podman-compose \
    openvpn networkmanager-openvpn wireguard-tools \
    tlp ethtool smartmontools \
    timeshift \
    udisks2 udiskie \
    fprintd libfprint \
    libinput xdotool wmctrl \
    gamemode mangohud \
    wine wine-mono wine-gecko winetricks lutris \
    sddm qt6-declarative

ok "Base packages installed"

# ─────────────────────────────────────────────────────────────
#  2. GPU driver
# ─────────────────────────────────────────────────────────────
echo ""
echo "══ [2/22] GPU driver ════════════════════════════════"
GPU_INFO=$(lspci 2>/dev/null | grep -E "VGA|3D" || echo "")

if echo "$GPU_INFO" | grep -qi "NVIDIA"; then
    info "NVIDIA GPU detected"
    if echo "$GPU_INFO" | grep -qi "RTX\|GTX 16\|GTX 17"; then
        XI nvidia nvidia-libs nvidia-settings
    else
        XI nvidia-dkms nvidia-libs nvidia-settings
    fi
elif echo "$GPU_INFO" | grep -qi "AMD"; then
    XI xf86-video-amdgpu mesa vulkan-radeon
elif echo "$GPU_INFO" | grep -qi "Intel"; then
    XI xf86-video-intel mesa vulkan-intel
elif echo "$GPU_INFO" | grep -qi "VMware\|VirtualBox\|QEMU"; then
    XI xf86-video-vmware mesa
else
    warn "Could not detect GPU — skipping driver install"
fi
ok "GPU driver configured"

# ─────────────────────────────────────────────────────────────
#  3. runit services (Void uses runit, not systemd)
# ─────────────────────────────────────────────────────────────
echo ""
echo "══ [3/22] runit services ════════════════════════════"

enable_sv() {
    local svc="$1"
    if [ -d "/etc/sv/$svc" ] && [ ! -L "/var/service/$svc" ]; then
        sudo ln -sf "/etc/sv/$svc" /var/service/
        ok "Service enabled: $svc"
    elif [ ! -d "/etc/sv/$svc" ]; then
        warn "Service not found: $svc (skipping)"
    fi
}

# Core services
for svc in dbus NetworkManager ufw apparmor bluetoothd cups sddm \
           docker usbguard fprintd avahi-daemon; do
    enable_sv "$svc"
done

ok "runit services enabled"

# ─────────────────────────────────────────────────────────────
#  4. Limine bootloader branding
# ─────────────────────────────────────────────────────────────
echo ""
echo "══ [4/22] Bootloader branding ═══════════════════════"

LIMINE_CONF=""
for candidate in /boot/limine.conf /efi/limine.conf /boot/efi/limine.conf; do
    [ -f "$candidate" ] && { LIMINE_CONF="$candidate"; break; }
done
if [ -z "$LIMINE_CONF" ]; then
    for esp in /boot /efi /boot/efi; do
        [ -d "$esp" ] && {
            found=$(find "$esp" -maxdepth 5 -iname "limine.conf" 2>/dev/null | head -1)
            [ -n "$found" ] && { LIMINE_CONF="$found"; break 2; }
        }
    done
fi

if [ -n "$LIMINE_CONF" ]; then
    info "Limine config: $LIMINE_CONF"
    sudo cp "$LIMINE_CONF" "$LIMINE_CONF.bak"
    sudo sed -i -E 's/^([[:space:]]*label[[:space:]]*=[[:space:]]*).*/\1SkywareOS X/' "$LIMINE_CONF"
    sudo sed -i -E 's|^/[^/].*|/SkywareOS X|' "$LIMINE_CONF"
    sudo sed -i -E '/^[[:space:]]*cmdline/{ /quiet/! s/$/ quiet splash/ }' "$LIMINE_CONF"

    LIMINE_DIR=$(dirname "$LIMINE_CONF")
    if [ -f assets/skywareos.svg ]; then
        sudo rsvg-convert -w 300 -h 300 assets/skywareos.svg -o /tmp/skyware-logo-300.png
        sudo convert -size 1920x1080 xc:#111113 \
            /tmp/skyware-logo-300.png -gravity Center -composite \
            "$LIMINE_DIR/skywareos-boot.png"
        grep -qi "^background_path" "$LIMINE_CONF" || \
            echo "background_path = skywareos-boot.png" | sudo tee -a "$LIMINE_CONF" >/dev/null
        ok "Limine boot background set"
    fi
    ok "Limine entries renamed to 'SkywareOS X'"
else
    warn "Limine config not found — skipping bootloader branding"
fi

# ─────────────────────────────────────────────────────────────
#  5. Plymouth bootsplash
# ─────────────────────────────────────────────────────────────
echo ""
echo "══ [5/22] Plymouth bootsplash ═══════════════════════"

# Void Linux: plymouth is in contrib repo
XI plymouth 2>/dev/null || warn "plymouth not in repos — trying xbps-install from contrib"

THEME_DIR="/usr/share/plymouth/themes/skywareos-x"
sudo mkdir -p "$THEME_DIR"

if [ -f assets/skywareos.svg ]; then
    sudo rsvg-convert -w 512 -h 512 assets/skywareos.svg -o "$THEME_DIR/logo.png"
    sudo rsvg-convert -w 128 -h 128 assets/skywareos.svg -o "$THEME_DIR/logo-small.png"
    ok "Plymouth logo images generated"
else
    warn "assets/skywareos.svg not found — Plymouth will show text-only splash"
fi

sudo tee "$THEME_DIR/skywareos-x.plymouth" >/dev/null << 'EOF'
[Plymouth Theme]
Name=SkywareOS X
Description=SkywareOS X Boot Splash
ModuleName=script

[script]
ImageDir=/usr/share/plymouth/themes/skywareos-x
ScriptFile=/usr/share/plymouth/themes/skywareos-x/skywareos-x.script
EOF

sudo tee "$THEME_DIR/skywareos-x.script" >/dev/null << 'EOF'
Window.SetBackgroundTopColor(0.07, 0.07, 0.07);
Window.SetBackgroundBottomColor(0.04, 0.04, 0.05);

logo.image  = Image("logo.png");
logo.sprite = Sprite(logo.image);
logo.x = Window.GetWidth()  / 2 - logo.image.GetWidth()  / 2;
logo.y = Window.GetHeight() / 2 - logo.image.GetHeight() / 2 - 40;
logo.sprite.SetPosition(logo.x, logo.y, 0);

bar_height = 3;
bar_y      = Window.GetHeight() - 60;
bar_width  = Window.GetWidth() * 0.4;
bar_x      = Window.GetWidth() / 2 - bar_width / 2;

bar_bg.image  = Image.Scale(Image.New(1,1), bar_width, bar_height);
bar_bg.image.SetOpacity(0.15);
bar_bg.sprite = Sprite(bar_bg.image);
bar_bg.sprite.SetPosition(bar_x, bar_y, 1);

bar.width  = 1;
bar.image  = Image.Scale(Image.New(1,1), bar.width, bar_height);
bar.sprite = Sprite(bar.image);
bar.sprite.SetPosition(bar_x, bar_y, 2);

fun refresh_callback() {
    bar.sprite.SetOpacity(1);
    bar_bg.sprite.SetOpacity(0.2);
}
Plymouth.SetRefreshFunction(refresh_callback);

fun boot_progress_callback(duration, progress) {
    new_width = Math.Int(bar_width * progress);
    if (new_width < 2) new_width = 2;
    if (new_width != bar.width) {
        bar.width = new_width;
        bar.image = Image.Scale(Image.New(1,1), bar.width, bar_height);
        bar.image.FillWithColor(0.63, 0.63, 0.73, 1.0);
        bar.sprite.SetImage(bar.image);
    }
}
Plymouth.SetBootProgressFunction(boot_progress_callback);

fun quit_callback() {
    logo.sprite.SetOpacity(0);
    bar.sprite.SetOpacity(0);
    bar_bg.sprite.SetOpacity(0);
}
Plymouth.SetQuitFunction(quit_callback);
EOF

# Void: dracut handles initramfs, not mkinitcpio
if command -v dracut &>/dev/null; then
    if ! grep -q "plymouth" /etc/dracut.conf 2>/dev/null; then
        echo 'add_dracutmodules+=" plymouth "' | sudo tee -a /etc/dracut.conf >/dev/null
    fi
    sudo dracut --force 2>&1 | tail -3
    ok "Initramfs rebuilt with Plymouth (dracut)"
elif command -v mkinitcpio &>/dev/null; then
    grep -q "^HOOKS=" /etc/mkinitcpio.conf && \
        ! grep -q "plymouth" /etc/mkinitcpio.conf && \
        sudo sed -i '/^HOOKS=/ s/udev/udev plymouth/' /etc/mkinitcpio.conf
    sudo mkinitcpio -P
    ok "Initramfs rebuilt with Plymouth (mkinitcpio)"
fi

command -v plymouth-set-default-theme &>/dev/null && \
    sudo plymouth-set-default-theme -R skywareos-x && \
    ok "Plymouth theme set: skywareos-x"

# ─────────────────────────────────────────────────────────────
#  6. bspwm + sxhkd + picom + rofi + polybar + dunst
# ─────────────────────────────────────────────────────────────
echo ""
echo "══ [6/22] bspwm desktop environment ═════════════════"

XI \
    bspwm sxhkd \
    picom \
    rofi \
    polybar \
    dunst \
    nitrogen \
    lxappearance \
    thunar thunar-volman gvfs \
    xclip xsel \
    flameshot \
    redshift \
    xss-lock \
    i3lock \
    xdg-user-dirs \
    xdg-utils \
    xdotool \
    wmctrl \
    maim \
    feh

ok "bspwm stack installed"

# ── xinitrc / display-manager session entry ──────────────────
sudo mkdir -p /usr/share/xsessions
sudo tee /usr/share/xsessions/bspwm.desktop > /dev/null << 'EOF'
[Desktop Entry]
Name=bspwm
Comment=Binary Space Partitioning Window Manager
Exec=bspwm
Type=Application
EOF

# ── bspwm config ─────────────────────────────────────────────
mkdir -p "$HOME/.config/bspwm"
cat > "$HOME/.config/bspwm/bspwmrc" << 'BSPWMEOF'
#!/bin/bash
# ── SkywareOS X · bspwm config ───────────────────────

sxhkd &

bspc monitor -d I II III IV V VI VII VIII IX X

# Layout
bspc config border_width         2
bspc config window_gap           10
bspc config top_padding          34    # polybar height
bspc config bottom_padding       0
bspc config left_padding         0
bspc config right_padding        0

# Behaviour
bspc config split_ratio          0.52
bspc config borderless_monocle   true
bspc config gapless_monocle      false
bspc config click_to_focus       button1
bspc config focus_follows_pointer true
bspc config pointer_follows_focus false
bspc config remove_disabled_monitors true
bspc config remove_unplugged_monitors true

# Colours — Skyware dark palette
bspc config normal_border_color   "#2a2a2f"
bspc config focused_border_color  "#a0a0b0"
bspc config presel_feedback_color "#60a5fa"
bspc config urgent_border_color   "#f87171"

# Floating rules
bspc rule -a Screenkey      manage=off
bspc rule -a Zeal            state=floating
bspc rule -a Pavucontrol     state=floating rectangle=900x600+0+0
bspc rule -a blueman-manager state=floating
bspc rule -a Thunar          state=floating rectangle=1200x700+0+0
bspc rule -a feh              state=floating

# Autostart
picom --daemon &
dunst &
nitrogen --restore &
udiskie --tray --notify &
nm-applet &
/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
xss-lock -- i3lock -c 111113 &
~/.config/autostart-scripts/skyware-kickoff-icon.sh &
~/.config/autostart-scripts/skyware-pin-taskbar.sh &
~/.config/autostart-scripts/skyware-welcome-check.sh &
polybar skyware &
BSPWMEOF
chmod +x "$HOME/.config/bspwm/bspwmrc"

# ── sxhkd keybinds ───────────────────────────────────────────
mkdir -p "$HOME/.config/sxhkd"
cat > "$HOME/.config/sxhkd/sxhkdrc" << 'SXHKDEOF'
# ── SkywareOS X · sxhkd keybinds ─────────────────────

# Terminal
super + Return
    kitty

super + shift + Return
    alacritty

# Launcher
super + d
    rofi -show drun

super + shift + d
    rofi -show run

# File manager
super + e
    thunar

# Screenshot
Print
    flameshot gui

super + Print
    maim ~/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png

# Lock screen
super + l
    i3lock -c 111113

# Reload sxhkd
super + Escape
    pkill -USR1 -x sxhkd

# Quit / restart bspwm
super + alt + r
    bspc wm -r

super + alt + q
    bspc quit

# Close / kill window
super + {_,shift + }w
    bspc node -{c,k}

# Toggle monocle
super + m
    bspc desktop -l next

# Toggle floating
super + shift + space
    bspc node -t ~floating

# Toggle fullscreen
super + f
    bspc node -t ~fullscreen

# Focus/swap — vim keys + arrows
super + {_,shift + }{h,j,k,l}
    bspc node -{f,s} {west,south,north,east}

super + {_,shift + }{Left,Down,Up,Right}
    bspc node -{f,s} {west,south,north,east}

# Cycle windows
super + {_,shift + }c
    bspc node -f {next,prev}.local.!hidden.window

# Switch workspace
super + {1-9,0}
    bspc desktop -f '^{1-9,10}'

super + shift + {1-9,0}
    bspc node -d '^{1-9,10}'

# Resize preselection
super + ctrl + {h,j,k,l}
    bspc node -p {west,south,north,east}

super + ctrl + space
    bspc node -p cancel

# Resize (continuous)
super + alt + {h,j,k,l}
    bspc node -z {left -20 0,bottom 0 20,top 0 -20,right 20 0}

# Volume
XF86AudioRaiseVolume
    pactl set-sink-volume @DEFAULT_SINK@ +5%

XF86AudioLowerVolume
    pactl set-sink-volume @DEFAULT_SINK@ -5%

XF86AudioMute
    pactl set-sink-mute @DEFAULT_SINK@ toggle

# Brightness
XF86MonBrightnessUp
    brightnessctl set +10%

XF86MonBrightnessDown
    brightnessctl set 10%-

# SkywareOS Settings
super + s
    skyware-settings

# SkywareOS ware help
super + shift + s
    kitty -- bash -c "ware help; read -p 'Press Enter to close...'"
SXHKDEOF

# ── picom config ─────────────────────────────────────────────
mkdir -p "$HOME/.config/picom"
cat > "$HOME/.config/picom/picom.conf" << 'PICOMEOF'
# ── SkywareOS X · picom config ───────────────────────

backend       = "glx";
vsync         = true;
use-damage    = true;

# Shadows
shadow            = true;
shadow-radius     = 12;
shadow-opacity    = 0.35;
shadow-offset-x   = -8;
shadow-offset-y   = -8;
shadow-color      = "#000000";
shadow-exclude    = [
    "name = 'Notification'",
    "class_g = 'Conky'",
    "class_g ?= 'Notify-osd'",
    "_GTK_FRAME_EXTENTS@:c"
];

# Fading
fading          = true;
fade-in-step    = 0.06;
fade-out-step   = 0.06;
fade-delta      = 5;
fade-exclude    = [];

# Transparency
inactive-opacity          = 0.92;
active-opacity            = 1.0;
frame-opacity             = 0.85;
inactive-opacity-override = false;

opacity-rule = [
    "100:class_g = 'kitty' && focused",
    "92:class_g  = 'kitty' && !focused",
    "100:class_g = 'Alacritty' && focused",
    "92:class_g  = 'Alacritty' && !focused",
    "100:class_g = 'firefox'",
    "100:class_g = 'Chromium'"
];

# Blur (frosted glass for popups and polybar)
blur-method             = "dual_kawase";
blur-strength           = 6;
blur-background         = true;
blur-background-exclude = [
    "window_type = 'dock'",
    "window_type = 'desktop'",
    "_GTK_FRAME_EXTENTS@:c"
];

# Rounded corners
corner-radius      = 10;
rounded-corners-exclude = [
    "window_type = 'dock'",
    "window_type = 'desktop'"
];

# Animations
transition-length    = 160;
transition-pow-x     = 0.1;
transition-pow-y     = 0.1;
transition-pow-w     = 0.1;
transition-pow-h     = 0.1;
size-transition      = true;
PICOMEOF

# ── polybar config ────────────────────────────────────────────
mkdir -p "$HOME/.config/polybar"
cat > "$HOME/.config/polybar/config.ini" << 'POLYBAREOF'
; ── SkywareOS X · Polybar ────────────────────────────

[colors]
bg       = #cc111113
bg-alt   = #1f1f23
fg       = #e2e2ec
fg-dim   = #7a7a8a
accent   = #a0a0b0
hi       = #c8c8dc
green    = #4ade80
yellow   = #facc15
red      = #f87171
blue     = #60a5fa
purple   = #a78bfa
orange   = #fb923c
border   = #2a2a2f

[bar/skyware]
width            = 100%
height           = 32
radius           = 0
fixed-center     = true
bottom           = false

background       = ${colors.bg}
foreground       = ${colors.fg}

line-size        = 2
line-color       = ${colors.accent}

border-size      = 0
padding-left     = 2
padding-right    = 2
module-margin    = 1

font-0           = "JetBrainsMono Nerd Font:size=10:weight=medium;3"
font-1           = "Symbols Nerd Font:size=12;3"
font-2           = "Noto Color Emoji:size=10;3"

modules-left     = bspwm xwindow
modules-center   = date
modules-right    = updates cpu memory temperature wlan battery volume

tray-position    = right
tray-padding     = 4

cursor-click     = pointer
cursor-scroll    = ns-resize

enable-ipc       = true

[module/bspwm]
type             = internal/bspwm
label-focused    = %icon%
label-focused-foreground = ${colors.hi}
label-focused-background = ${colors.bg-alt}
label-focused-padding    = 2

label-occupied   = %icon%
label-occupied-foreground = ${colors.accent}
label-occupied-padding    = 2

label-urgent     = %icon%
label-urgent-foreground = ${colors.red}
label-urgent-padding    = 2

label-empty      = %icon%
label-empty-foreground = ${colors.border}
label-empty-padding    = 2

ws-icon-0  = I;
ws-icon-1  = II;
ws-icon-2  = III;
ws-icon-3  = IV;
ws-icon-4  = V;
ws-icon-5  = VI;
ws-icon-6  = VII;
ws-icon-7  = VIII;
ws-icon-8  = IX;
ws-icon-9  = X;

[module/xwindow]
type  = internal/xwindow
label = %title:0:50:…%
label-foreground = ${colors.fg-dim}
format-padding   = 2

[module/date]
type         = internal/date
interval     = 5
date         = "%a %d %b"
time         = "%H:%M"
label        = "  %date%   %time%"
label-foreground = ${colors.hi}

[module/cpu]
type              = internal/cpu
interval          = 2
format-prefix     = "󰻠 "
format-prefix-foreground = ${colors.blue}
label             = %percentage:2%%
label-foreground  = ${colors.fg}

[module/memory]
type              = internal/memory
interval          = 2
format-prefix     = "󰍛 "
format-prefix-foreground = ${colors.purple}
label             = %percentage_used:2%%
label-foreground  = ${colors.fg}

[module/temperature]
type              = internal/temperature
thermal-zone      = 0
warn-temperature  = 80
format-prefix     = " "
format-prefix-foreground = ${colors.orange}
label             = %temperature-c%
label-warn        = %temperature-c%
label-warn-foreground = ${colors.red}

[module/wlan]
type             = internal/network
interface-type   = wireless
interval         = 3
format-connected    = <label-connected>
format-disconnected = <label-disconnected>
format-connected-prefix     = "  "
format-connected-prefix-foreground = ${colors.green}
label-connected    = %essid%
label-disconnected = "offline"
label-disconnected-foreground = ${colors.fg-dim}

[module/battery]
type              = internal/battery
full-at           = 98
battery           = BAT0
adapter           = AC
poll-interval     = 5

format-charging    = <animation-charging> <label-charging>
format-discharging = <ramp-capacity> <label-discharging>
format-full        = <label-full>

label-charging    = %percentage%%
label-discharging = %percentage%%
label-full        = " 100%"
label-full-foreground = ${colors.green}

ramp-capacity-0  = "󰁺"
ramp-capacity-1  = "󰁼"
ramp-capacity-2  = "󰁿"
ramp-capacity-3  = "󰂁"
ramp-capacity-4  = "󰁹"
ramp-capacity-0-foreground = ${colors.red}
ramp-capacity-1-foreground = ${colors.yellow}
ramp-capacity-4-foreground = ${colors.green}

animation-charging-0 = "󰢜"
animation-charging-1 = "󰂆"
animation-charging-2 = "󰂇"
animation-charging-3 = "󰂈"
animation-charging-4 = "󰂉"
animation-charging-framerate = 750
animation-charging-foreground = ${colors.green}

[module/volume]
type              = internal/pulseaudio
format-volume     = <ramp-volume> <label-volume>
label-volume      = %percentage%%
label-muted       = "󰖁 mute"
label-muted-foreground = ${colors.fg-dim}
ramp-volume-0     = "󰕿"
ramp-volume-1     = "󰖀"
ramp-volume-2     = "󰕾"
ramp-volume-foreground = ${colors.accent}

[module/updates]
type  = custom/script
exec  = count=$(xbps-install -Mnu 2>/dev/null | wc -l); [ "$count" -gt 0 ] && echo " $count" || echo ""
interval  = 600
label-foreground = ${colors.yellow}
POLYBAREOF

# ── rofi theme ────────────────────────────────────────────────
mkdir -p "$HOME/.config/rofi"
cat > "$HOME/.config/rofi/skyware.rasi" << 'ROFIEOF'
/* ── SkywareOS X · Rofi theme ───────────────────────*/
* {
    bg:         #111113ee;
    bg-alt:     #18181bdd;
    fg:         #e2e2ec;
    fg-dim:     #7a7a8a;
    accent:     #a0a0b0;
    hi:         #c8c8dc;
    sel:        #1f1f23;
    border-col: #2a2a2f;
    red:        #f87171;

    background-color: transparent;
    text-color:       @fg;
    font:             "JetBrainsMono Nerd Font 12";
}

window {
    background-color: @bg;
    border:           1px solid;
    border-color:     @border-col;
    border-radius:    10px;
    padding:          8px;
    width:            520px;
}

mainbox {
    background-color: transparent;
    children:         [ inputbar, listview ];
    spacing:          8px;
}

inputbar {
    background-color: @bg-alt;
    border-radius:    7px;
    padding:          10px 16px;
    children:         [ prompt, entry ];
    spacing:          8px;
}

prompt {
    color:       @accent;
    font:        "JetBrainsMono Nerd Font 12";
}

entry {
    color:       @fg;
    placeholder: "Search...";
    placeholder-color: @fg-dim;
}

listview {
    background-color: transparent;
    lines:            10;
    columns:          1;
    spacing:          4px;
    scrollbar:        false;
}

element {
    background-color: transparent;
    border-radius:    6px;
    padding:          9px 14px;
    spacing:          10px;
    orientation:      horizontal;
}

element selected {
    background-color: @sel;
    text-color:       @hi;
}

element-icon {
    size: 22px;
}

element-text {
    color:            inherit;
    vertical-align:   0.5;
}
ROFIEOF

cat > "$HOME/.config/rofi/config.rasi" << 'EOF'
@theme "~/.config/rofi/skyware.rasi"
configuration {
    modi:         "drun,run,window";
    show-icons:   true;
    drun-display-format: "{name}";
    display-drun: "  Apps";
    display-run:  "  Run";
    display-window: "  Windows";
}
EOF

# ── dunst config ─────────────────────────────────────────────
mkdir -p "$HOME/.config/dunst"
cat > "$HOME/.config/dunst/dunstrc" << 'DUNSTEOF'
[global]
monitor                 = 0
follow                  = mouse
width                   = 340
height                  = 200
origin                  = top-right
offset                  = 12x44
scale                   = 0
notification_limit      = 5
progress_bar            = true
progress_bar_height     = 6
progress_bar_frame_width = 1
progress_bar_min_width  = 150
progress_bar_max_width  = 300
indicate_hidden         = yes
transparency            = 10
separator_height        = 2
padding                 = 12
horizontal_padding      = 14
text_icon_padding       = 10
frame_width             = 1
frame_color             = "#2a2a2f"
separator_color         = frame
sort                    = yes
font                    = JetBrainsMono Nerd Font 11
line_height             = 0
markup                  = full
format                  = "<b>%s</b>\n%b"
alignment               = left
vertical_alignment      = center
show_age_threshold      = 60
word_wrap               = yes
ellipsize               = middle
ignore_newline          = no
stack_duplicates        = true
hide_duplicate_count    = false
show_indicators         = yes
icon_theme              = Papirus-Dark
enable_recursive_icon_lookup = true
icon_position           = left
min_icon_size           = 24
max_icon_size           = 32
sticky_history          = yes
history_length          = 20
browser                 = /usr/bin/xdg-open
always_run_script       = true
title                   = Dunst
class                   = Dunst
corner_radius           = 8
ignore_dbusclose        = false
force_xinerama          = false
mouse_left_click        = close_current
mouse_middle_click      = do_action, close_current
mouse_right_click       = close_all

[urgency_low]
background = "#111113"
foreground = "#e2e2ec"
frame_color = "#2a2a2f"
timeout = 4

[urgency_normal]
background = "#18181b"
foreground = "#e2e2ec"
frame_color = "#a0a0b0"
timeout = 6

[urgency_critical]
background = "#2a1515"
foreground = "#f87171"
frame_color = "#f87171"
timeout = 0
DUNSTEOF

ok "bspwm + sxhkd + picom + polybar + rofi + dunst configured"

# ─────────────────────────────────────────────────────────────
#  7. Fastfetch — SkywareOS X branding
# ─────────────────────────────────────────────────────────────
echo ""
echo "══ [7/22] Fastfetch branding ════════════════════════"

FASTFETCH_DIR="$HOME/.config/fastfetch"
mkdir -p "$FASTFETCH_DIR/logos"

# Logo: inner Skyware mark + outer Void-style ring
cat > "$FASTFETCH_DIR/logos/skyware-x.txt" << 'EOF'
              .+@@@@@@@@@@@@@@*.
           .%@@@@@@@@@@@@@@@@@@@@@@@@@.
        -@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@-
         @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
           @@@@@@@@@@+::...:+@@@@@@@@@@@@@@@@@
            .@@%.                .%@@@@@@@@@@@@
%%                                    %@@@@@@@@@@%
@@.                                    %@@@@@@@@@@
@@@@.                                   :@@@@@@@@@
@@@@@@.                                  .@@@@@@@@
@@@@@@+                                   -@@@@@@@
@@@@@@        .@@@@+      .@@@@-           @@@@@@@
@@@@@@:       @@@@@@@@@    *@@@@@@         @@@@@@@
@@@@@@        @@:     @@@         @@       @@@@@@@
@@@@@@        @@       @@@        =@       @@@@@@@
@@@@@@        @@:        @@@:     @@       @@@@@@@
@@@@@@:        @@@@@@@    .@@@@@@@@        @@@@@@@
@@@@@@          .@@@@.      .@@@@.         @@@@@@@
@@@@@@-                                   +@@@@@@@
@@@@@@.                                  :@@@@@@@@
@@@@@@@:                                 .@@@@@@@
@@@@@@@@@                                 .@@@@@@
 @@@@@@@@@@+                               =@@@
  +@@@@@@@@@@@@#.                .@@@.
   .@@@@@@@@@@@@@@@@@+:...::*@@@@@@@@
     .@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%
          +@@@@@@@@@@@@@@@@@@@@@@@@@@-
             .@@@@@@@@@@@@@@@@@@@%.
                  .#@@@@@@@@#.
EOF

cat > "$FASTFETCH_DIR/config.jsonc" << 'EOF'
{
  "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
  "logo": {
    "type": "file",
    "source": "~/.config/fastfetch/logos/skyware-x.txt",
    "padding": { "top": 0, "left": 2 }
  },
  "modules": [
    "title", "separator",
    { "type": "os",     "format": "SkywareOS X (Void)", "use_pretty_name": false },
    "kernel", "uptime", "packages", "shell",
    { "type": "wm",     "format": "bspwm" },
    "cpu", "gpu", "memory", "disk"
  ]
}
EOF

ok "Fastfetch configured"

# ─────────────────────────────────────────────────────────────
#  8. OS release branding
# ─────────────────────────────────────────────────────────────
echo ""
echo "══ [8/22] OS release branding ═══════════════════════"

sudo tee /etc/os-release > /dev/null << 'EOF'
NAME="SkywareOS X"
PRETTY_NAME="SkywareOS X"
ID=skywareos-x
ID_LIKE=void
VERSION="0.1 Void"
VERSION_ID=Release_1-0-dev
HOME_URL="https://github.com/SkywareSW"
LOGO=skywareos
EOF

sudo tee /usr/lib/os-release > /dev/null << 'EOF'
NAME="SkywareOS X"
PRETTY_NAME="SkywareOS X"
ID=skywareos-x
ID_LIKE=void
VERSION="0.1 Void"
VERSION_ID=Release_1-0-dev
LOGO=skywareos
EOF

ok "OS branding set to SkywareOS X"

# ─────────────────────────────────────────────────────────────
#  9. btop — Skyware red theme
# ─────────────────────────────────────────────────────────────
echo ""
echo "══ [9/22] btop theme ════════════════════════════════"

BTOP_DIR="$HOME/.config/btop"
mkdir -p "$BTOP_DIR/themes"

cat > "$BTOP_DIR/themes/skyware-red.theme" << 'EOF'
theme[main_bg]="#0a0000"
theme[main_fg]="#f2dada"
theme[title]="#ff4d4d"
theme[hi_fg]="#ff6666"
theme[selected_bg]="#2a0505"
theme[inactive_fg]="#8a5a5a"
theme[cpu_box]="#ff4d4d"
theme[cpu_core]="#ff6666"
theme[cpu_misc]="#ff9999"
theme[mem_box]="#ff6666"
theme[mem_used]="#ff4d4d"
theme[mem_free]="#ff9999"
theme[mem_cached]="#ffb3b3"
theme[net_box]="#ff6666"
theme[net_download]="#ff9999"
theme[net_upload]="#ff4d4d"
theme[temp_start]="#ff9999"
theme[temp_mid]="#ff6666"
theme[temp_end]="#ff3333"
EOF

cat > "$BTOP_DIR/btop.conf" << 'EOF'
color_theme = "skyware-red"
rounded_corners = True
vim_keys = True
graph_symbol = "block"
update_ms = 2000
EOF

ok "btop theme configured"

# ─────────────────────────────────────────────────────────────
#  10. zsh + Starship + plugins
# ─────────────────────────────────────────────────────────────
echo ""
echo "══ [10/22] zsh + Starship ════════════════════════════"

chsh -s /bin/zsh "$USER" || true

if ! command -v starship &>/dev/null; then
    curl -sS https://starship.rs/install.sh | sh -s -- --yes
fi

rm -f "$HOME/.config/starship.toml"
mkdir -p "$HOME/.config"

cat > "$HOME/.zshrc" << 'ZSHEOF'
# ── SkywareOS X zshrc ─────────────────────────────────

# Plugins — Void Linux paths
[ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ] && \
    source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
[ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && \
    source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# fzf
[ -f /usr/share/fzf/key-bindings.zsh ]  && source /usr/share/fzf/key-bindings.zsh
[ -f /usr/share/fzf/completion.zsh ]    && source /usr/share/fzf/completion.zsh
export FZF_DEFAULT_OPTS="--color=bg+:#1f1f23,bg:#111113,spinner:#a0a0b0,hl:#60a5fa \
  --color=fg:#e2e2ec,header:#7a7a8a,info:#a0a0b0,pointer:#c8c8dc \
  --color=marker:#4ade80,fg+:#e2e2ec,prompt:#a0a0b0,hl+:#60a5fa \
  --border=rounded --prompt='  ' --pointer='▶' --marker='✔'"

# zoxide
eval "$(zoxide init zsh)"
alias cd='z'

# eza
alias ls='eza --icons --group-directories-first'
alias ll='eza -lah --icons --group-directories-first --git'
alias tree='eza --tree --icons'

# Dotfiles
alias dotfiles='git --git-dir=$HOME/.dotfiles --work-tree=$HOME'

# xbps shortcuts (Void-native)
alias xi='sudo xbps-install -S'
alias xr='sudo xbps-remove -R'
alias xu='sudo xbps-install -Su'
alias xq='xbps-query -Rs'
alias xl='xbps-query -l'

# History
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE

# Auto-completion
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# Run fastfetch on new terminal
fastfetch

# Starship prompt
eval "$(starship init zsh)"
ZSHEOF

cat > "$HOME/.config/starship.toml" << 'EOF'
[character]
success_symbol = "➜"
error_symbol   = "✗"
vicmd_symbol   = "❮"
[directory]
truncation_length = 3
style = "gray"
[git_branch]
symbol = " "
style = "bright-gray"
[git_status]
style = "gray"
conflicted = "✖"
ahead = "↑"
behind = "↓"
staged = "●"
deleted = "✖"
renamed = "➜"
modified = "!"
untracked = "?"
EOF

ok "zsh + Starship configured"

# ─────────────────────────────────────────────────────────────
#  11. ware package manager (Void edition)
# ─────────────────────────────────────────────────────────────
echo ""
echo "══ [11/22] ware package manager (Void) ══════════════"

sudo tee /usr/local/bin/ware > /dev/null << 'WAREEOF'
#!/bin/bash
# ── ware · SkywareOS X package manager (Void Linux) ──
LOGFILE="/var/log/ware.log"
GREEN="\e[32m"; RED="\e[31m"; BLUE="\e[34m"; YELLOW="\e[33m"
CYAN="\e[36m"; RESET="\e[0m"

log()     { echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | sudo tee -a "$LOGFILE" >/dev/null; }
spinner() { local pid=$!; local spin='-\|/'; local i=0
            while kill -0 $pid 2>/dev/null; do
                i=$(( (i+1) %4 ))
                printf "\r${CYAN}[%c] Working...${RESET}" "${spin:$i:1}"
                sleep .1
            done; printf "\r"; }

install_pkg() {
    for pkg in "$@"; do
        log "Install: $pkg"
        if xbps-query -Rs "^${pkg}-[0-9]" 2>/dev/null | grep -q "^-"; then
            sudo xbps-install -Sy "$pkg" & spinner; wait; log "Installed (xbps): $pkg"
        elif flatpak search --columns=application "$pkg" 2>/dev/null | grep -Fxq "$pkg"; then
            flatpak install -y flathub "$pkg" & spinner; wait; log "Installed (flatpak): $pkg"
        else
            echo -e "${RED}✖ Package not found: $pkg${RESET}"; log "FAILED: $pkg"
        fi
    done
}

remove_pkg() {
    for pkg in "$@"; do
        if xbps-query -l | grep -q "^ii ${pkg} "; then
            sudo xbps-remove -Ry "$pkg"; log "Removed: $pkg"
        elif flatpak list | grep -qi "$pkg"; then
            flatpak uninstall -y "$pkg"; log "Removed flatpak: $pkg"
        else
            echo -e "${RED}✖ $pkg not installed${RESET}"
        fi
    done
}

doctor() {
    echo -e "${CYAN}→ Checking xbps package database...${RESET}"
    sudo xbps-pkgdb -a 2>&1 | head -20
    echo ""
    echo -e "${CYAN}→ Checking Flatpak...${RESET}"; flatpak repair --dry-run 2>/dev/null || true
    echo ""
    echo -e "${CYAN}→ Checking firewall...${RESET}"
    if sv status ufw 2>/dev/null | grep -q "run"; then
        echo -e "${GREEN}✔ Firewall (ufw) ACTIVE${RESET}"
    else
        echo -e "${YELLOW}⚠ Firewall (ufw) NOT running${RESET}"
    fi
    echo ""
    echo -e "${GREEN}Diagnostics complete.${RESET}"
}

power_profile() {
    case "$1" in
        balanced)    sudo tlp start; sudo cpupower frequency-set -g schedutil >/dev/null 2>&1; echo -e "${GREEN}✔ Balanced${RESET}" ;;
        performance) sudo cpupower frequency-set -g performance;  echo -e "${GREEN}✔ Performance${RESET}" ;;
        battery)     sudo tlp start; sudo cpupower frequency-set -g powersave >/dev/null 2>&1; echo -e "${GREEN}✔ Battery saver${RESET}" ;;
        status)      cpupower frequency-info | grep "current policy" ;;
        *)           echo -e "${YELLOW}Usage: ware power <balanced|performance|battery|status>${RESET}" ;;
    esac
}

ware_status() {
    echo -e "${CYAN}System Status — SkywareOS X${RESET}"
    echo "────────────────────────────────────"
    echo -e "Kernel:   $(uname -r)"
    echo -e "Uptime:   $(uptime -p)"
    echo -e "Packages: $(xbps-query -l | wc -l) (xbps)"
    echo -e "Flatpak:  $(flatpak list 2>/dev/null | wc -l)"
    echo -e "Memory:   $(free -h | awk '/Mem:/{print $3"/"$2}')"
    echo -e "Disk:     $(df -h / | awk 'NR==2{print $5}')"
    echo -e "WM:       bspwm"
    echo -e "Init:     runit (Void Linux)"
    echo -e "Channel:  0.1 Void"
}

clean_cache() { sudo xbps-remove -Oo; flatpak uninstall --unused -y 2>/dev/null; log "Cache cleaned"; }
autoremove()  { sudo xbps-remove -Oo; echo -e "${GREEN}✔ Orphans removed${RESET}"; }
sync_mirrors() { sudo xbps-install -Su; log "Synced"; }

case "$1" in
    install)    shift; install_pkg "$@" ;;
    remove)     shift; remove_pkg "$@" ;;
    update)     sudo xbps-install -Su; flatpak update -y; log "Updated" ;;
    search)     shift; xbps-query -Rs "$@"; flatpak search "$@" ;;
    info)       shift; xbps-query -RS "$1" 2>/dev/null || flatpak info "$1" ;;
    list)       xbps-query -l; flatpak list ;;
    doctor)     doctor ;;
    power)      shift; power_profile "$1" ;;
    status)     ware_status ;;
    clean)      clean_cache ;;
    autoremove) autoremove ;;
    sync)       sync_mirrors ;;
    upgrade)    rm -rf SkywareOS-X 2>/dev/null; git clone https://github.com/SkywareSW/SkywareOS-X; cd SkywareOS-X; chmod +x skyware-x-setup.sh; ./skyware-x-setup.sh ;;
    switch)     rm -rf SkywareOS-X-Testing 2>/dev/null; git clone https://github.com/SkywareSW/SkywareOS-X-Testing; cd SkywareOS-X-Testing; chmod +x setup.sh; ./setup.sh ;;
    git)        command -v xdg-open &>/dev/null && xdg-open "https://skywaresw.github.io/SkywareOS" || echo "https://skywaresw.github.io/SkywareOS" ;;
    settings)   exec skyware-settings ;;
    ai)         exec ware-ai-doctor ;;
    backup)
        shift
        case "$1" in
            create)  sudo timeshift --create --comments "ware backup $(date '+%Y-%m-%d %H:%M')" --tags D; log "Snapshot created" ;;
            list)    sudo timeshift --list ;;
            restore) sudo timeshift --restore ;;
            delete)  sudo timeshift --delete ;;
            *)       echo "Usage: ware backup <create|list|restore|delete>" ;;
        esac ;;
    repair)
        echo -e "${CYAN}== SkywareOS Repair ==${RESET}"
        echo -e "${CYAN}→ Checking package database...${RESET}"; sudo xbps-pkgdb -a
        echo -e "${CYAN}→ Removing orphans...${RESET}"; sudo xbps-remove -Oo
        echo -e "${CYAN}→ Fixing Flatpak...${RESET}"; flatpak repair 2>/dev/null; flatpak uninstall --unused -y 2>/dev/null
        echo -e "${CYAN}→ Checking runit services...${RESET}"
        for sv_dir in /var/service/*/; do
            svc=$(basename "$sv_dir")
            state=$(sv status "$svc" 2>/dev/null | head -1)
            echo -e "  $state — $svc"
        done
        echo -e "${GREEN}== Repair complete ==${RESET}"; log "ware repair run" ;;
    benchmark)
        echo -e "${CYAN}== Benchmark ==${RESET}"
        echo -e "${CYAN}── CPU ─────────────────────────────${RESET}"
        echo -e "Model:  $(grep 'model name' /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)"
        echo -e "Cores:  $(nproc)"
        CPU_SCORE=$(python3 -c "import time,math; start=time.time(); count=0
while time.time()-start<5: math.factorial(10000); count+=1
print(count)")
        echo -e "Score:  $CPU_SCORE ops/5s"
        echo ""
        echo -e "${CYAN}── Memory ──────────────────────────${RESET}"
        MEM_BW=$(python3 -c "import time,array; size=100_000_000; a=array.array('B',bytes(size))
start=time.time(); b=bytes(a); el=time.time()-start; print(f'{(size/1e9)/el:.1f} GB/s')")
        echo -e "Bandwidth: $MEM_BW"
        echo ""
        echo -e "${CYAN}── Disk ────────────────────────────${RESET}"
        WRITE_SPEED=$(dd if=/dev/zero of=/tmp/ware-bench bs=1M count=512 conv=fdatasync 2>&1 | grep -oP '[0-9.]+ [MG]B/s' | tail -1)
        rm -f /tmp/ware-bench
        echo -e "Write: ${WRITE_SPEED:-n/a}"; log "benchmark run" ;;
    setup)
        shift
        case "$1" in
            lazyvim)
                sudo xbps-install -Sy neovim git
                mv ~/.config/nvim ~/.config/nvim.bak 2>/dev/null || true
                git clone https://github.com/LazyVim/starter ~/.config/nvim; rm -rf ~/.config/nvim/.git; nvim ;;
            hyprland)
                sudo xbps-install -Sy hyprland xdg-desktop-portal-hyprland waybar wofi kitty grim slurp wl-clipboard polkit-kde-agent pipewire wireplumber network-manager-applet thunar ;;
            *)  echo -e "${RED}Unknown setup target${RESET}" ;;
        esac ;;
    snap)
        echo -e "${YELLOW}→ Snap is not officially supported on Void Linux.${RESET}"
        echo -e "  Use flatpak instead: ware install <app-id>" ;;
    help)
        echo -e "ware status              — System overview"
        echo -e "ware install <pkg>       — Install (xbps / flatpak)"
        echo -e "ware remove <pkg>        — Remove package"
        echo -e "ware update              — Update system"
        echo -e "ware upgrade             — Upgrade SkywareOS X"
        echo -e "ware search <pkg>        — Search packages"
        echo -e "ware info <pkg>          — Package info"
        echo -e "ware list                — List installed packages"
        echo -e "ware doctor              — Diagnostics"
        echo -e "ware repair              — Fix broken packages / services"
        echo -e "ware backup <action>     — Snapshots (create/list/restore/delete)"
        echo -e "ware benchmark           — CPU / RAM / disk speed test"
        echo -e "ware clean               — Clean xbps + flatpak cache"
        echo -e "ware autoremove          — Remove orphaned packages"
        echo -e "ware sync                — Sync xbps repos"
        echo -e "ware power <mode>        — Power profile"
        echo -e "ware settings            — Open Settings GUI"
        echo -e "ware ai                  — AI Doctor (Claude API)"
        echo -e "ware setup lazyvim/hyprland"
        echo -e "ware git                 — Open SkywareOS website" ;;
    *)
        echo "Usage: ware <command>"; echo "Run 'ware help' for a full list." ;;
esac
WAREEOF

sudo chmod +x /usr/local/bin/ware
ok "ware package manager installed"

# ─────────────────────────────────────────────────────────────
#  12. Polkit + sudoers
# ─────────────────────────────────────────────────────────────
echo ""
echo "══ [12/22] Polkit + sudoers ══════════════════════════"

sudo mkdir -p /etc/polkit-1/rules.d
sudo tee /etc/polkit-1/rules.d/10-skyware.rules > /dev/null << 'EOF'
polkit.addRule(function(action, subject) {
    if (subject.isInGroup("wheel")) {
        return polkit.Result.YES;
    }
});
EOF

sudo tee /etc/sudoers.d/10-skyware > /dev/null << 'EOF'
%wheel ALL=(ALL) NOPASSWD: ALL
EOF
sudo chmod 440 /etc/sudoers.d/10-skyware
sudo visudo -c -f /etc/sudoers.d/10-skyware && ok "Sudoers configured"

# ─────────────────────────────────────────────────────────────
#  13. SkywareOS Settings App (Electron + React)
# ─────────────────────────────────────────────────────────────
echo ""
echo "══ [13/22] SkywareOS Settings App ═══════════════════"

APP_DIR="/opt/skyware-settings"
sudo mkdir -p "$APP_DIR/src"

sudo tee "$APP_DIR/package.json" > /dev/null << 'EOF'
{
  "name": "skyware-settings",
  "version": "0.1.0",
  "description": "SkywareOS X Settings",
  "main": "main.js",
  "scripts": { "start": "electron .", "build": "vite build" },
  "dependencies": { "react": "^18.2.0", "react-dom": "^18.2.0" },
  "devDependencies": { "electron": "^30.0.0", "@vitejs/plugin-react": "^4.0.0", "vite": "^5.0.0" }
}
EOF

sudo tee "$APP_DIR/main.js" > /dev/null << 'EOF'
const { app, BrowserWindow, ipcMain } = require('electron');
const { exec, spawn } = require('child_process');
const path = require('path');
const fs   = require('fs');

function createWindow() {
  const win = new BrowserWindow({
    width: 1000, height: 680, minWidth: 800, minHeight: 560,
    frame: false, backgroundColor: '#111113',
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true, nodeIntegration: false,
    },
    title: 'SkywareOS X Settings',
  });
  const distIndex = path.join(__dirname, 'dist', 'index.html');
  fs.existsSync(distIndex) ? win.loadFile(distIndex)
    : win.loadURL('data:text/html;charset=utf-8,' + encodeURIComponent(
        '<body style="background:#111113;color:#e2e2ec;font-family:sans-serif;display:flex;align-items:center;justify-content:center;height:100vh;margin:0;flex-direction:column;gap:16px">'
        + '<div style="font-size:28px">⚠</div><div style="font-size:17px;font-weight:600">Build not found</div>'
        + '<code style="background:#18181b;padding:10px 18px;border-radius:8px;color:#f87171;font-size:13px;border:1px solid #2a2a2f">'
        + 'cd /opt/skyware-settings && npm install && npx vite build</code></body>'
      ));
}

ipcMain.handle('run-cmd', async (_, cmd) => {
  return new Promise((resolve) => {
    const env = { ...process.env, PATH: '/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:' + (process.env.PATH||'') };
    const TERMINAL_CMDS = ['ware upgrade','ware switch','ware setup','ware backup restore'];
    const needsTerminal = TERMINAL_CMDS.some(c => cmd.startsWith(c.replace(/^\/usr\/local\/bin\//,'')));
    if (needsTerminal) {
      const tmpScript = '/tmp/skyware-run-' + Date.now() + '.sh';
      fs.writeFileSync(tmpScript, '#!/bin/bash\n' + cmd + '\necho\nread -p "Press Enter to close..."\n');
      fs.chmodSync(tmpScript, 0o755);
      for (const [t, args] of [['kitty',[tmpScript]],['alacritty',['-e','bash',tmpScript]]]) {
        const w = require('child_process').spawnSync('which',[t],{env});
        if (w.status===0) { spawn(t,args,{env,detached:true,stdio:'ignore'}).unref(); resolve({stdout:`→ Opened in ${t}`,stderr:'',code:0}); return; }
      }
    }
    const child = exec(`bash -c "${cmd.replace(/"/g,'\\"')}"`, {env,maxBuffer:50*1024*1024,timeout:120000},
      (err,stdout,stderr)=>resolve({stdout:stdout||'',stderr:stderr||'',code:err?err.code:0}));
    if (child.stdin) child.stdin.end();
  });
});

ipcMain.on('window-minimize', e => BrowserWindow.fromWebContents(e.sender).minimize());
ipcMain.on('window-maximize', e => { const w=BrowserWindow.fromWebContents(e.sender); w.isMaximized()?w.unmaximize():w.maximize(); });
ipcMain.on('window-close',    e => BrowserWindow.fromWebContents(e.sender).close());
app.whenReady().then(createWindow);
app.on('window-all-closed', () => { if (process.platform!=='darwin') app.quit(); });
EOF

sudo tee "$APP_DIR/preload.js" > /dev/null << 'EOF'
const { contextBridge, ipcRenderer } = require('electron');
contextBridge.exposeInMainWorld('skyware', {
  runCmd:   cmd => ipcRenderer.invoke('run-cmd', cmd),
  minimize: ()  => ipcRenderer.send('window-minimize'),
  maximize: ()  => ipcRenderer.send('window-maximize'),
  close:    ()  => ipcRenderer.send('window-close'),
});
EOF

sudo tee "$APP_DIR/vite.config.js" > /dev/null << 'EOF'
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
export default defineConfig({ plugins:[react()], base:'./', build:{outDir:'dist'} });
EOF

sudo tee "$APP_DIR/index.html" > /dev/null << 'EOF'
<!DOCTYPE html><html lang="en">
<head><meta charset="UTF-8"/><title>SkywareOS X Settings</title>
<style>*{margin:0;padding:0;box-sizing:border-box;}body{overflow:hidden;background:#111113;}#root{height:100vh;}</style>
</head><body><div id="root"></div><script type="module" src="/src/main.jsx"></script></body></html>
EOF

sudo tee "$APP_DIR/src/main.jsx" > /dev/null << 'EOF'
import React from 'react';
import { createRoot } from 'react-dom/client';
import App from './App.jsx';
createRoot(document.getElementById('root')).render(<App />);
EOF

# Settings App — bspwm/Void-aware panels
sudo tee "$APP_DIR/src/App.jsx" > /dev/null << 'APPEOF'
import { useState, useEffect, useRef } from "react";

const C = {
  bg:"#111113",bgSide:"#0e0e10",bgHeader:"#0c0c0e",bgCard:"#18181b",bgHover:"#1f1f23",
  border:"#2a2a2f",borderFaint:"#1e1e22",accent:"#a0a0b0",accentHi:"#c8c8dc",
  muted:"#4a4a58",mutedLo:"#2e2e38",text:"#e2e2ec",textDim:"#7a7a8a",
  green:"#4ade80",yellow:"#facc15",red:"#f87171",blue:"#60a5fa",purple:"#a78bfa",orange:"#fb923c",
};

const SIDEBAR = [
  {id:"status",  label:"System Status", icon:"◈"},
  {id:"packages",label:"Packages",      icon:"⬡"},
  {id:"bspwm",   label:"bspwm",         icon:"◉"},
  {id:"power",   label:"Power",         icon:"⚡"},
  {id:"system",  label:"System Tools",  icon:"⚙"},
  {id:"services",label:"runit Services",icon:"⬕"},
  {id:"channel", label:"Channel",       icon:"◎"},
];

const api = cmd => {
  const r = cmd.replace(/^ware\b/,'/usr/local/bin/ware');
  return window.skyware?.runCmd(r) ?? Promise.resolve({stdout:`[sim] ${r}`,stderr:'',code:0});
};

function useTerminal() {
  const [lines,setLines]=useState([]);
  const add=(text,type="info")=>setLines(p=>[...p,{text,type,id:Date.now()+Math.random()}]);
  return {lines,add};
}

function TitleBar() {
  const btns=[{l:"–",a:()=>window.skyware?.minimize(),c:C.yellow},{l:"□",a:()=>window.skyware?.maximize(),c:C.green},{l:"×",a:()=>window.skyware?.close(),c:C.red}];
  return (
    <div style={{WebkitAppRegion:"drag",height:"50px",background:C.bgHeader,borderBottom:`1px solid ${C.borderFaint}`,display:"flex",alignItems:"center",justifyContent:"space-between",padding:"0 20px",flexShrink:0}}>
      <div style={{display:"flex",alignItems:"center",gap:"10px"}}>
        <div style={{width:"24px",height:"24px",borderRadius:"5px",background:`linear-gradient(135deg,${C.accent},#505060)`,display:"flex",alignItems:"center",justifyContent:"center",fontSize:"12px",fontWeight:900,color:"#fff"}}>S</div>
        <span style={{color:C.text,fontWeight:600,fontSize:"13px"}}>SkywareOS X Settings</span>
        <span style={{background:C.bgHover,color:C.textDim,fontSize:"10px",borderRadius:"4px",padding:"2px 7px",border:`1px solid ${C.border}`}}>Void · bspwm · runit</span>
      </div>
      <div style={{WebkitAppRegion:"no-drag",display:"flex",gap:"6px"}}>
        {btns.map(b=>(
          <button key={b.l} onClick={b.a}
            style={{width:"28px",height:"22px",borderRadius:"4px",border:`1px solid ${C.border}`,background:"transparent",color:C.textDim,cursor:"pointer",fontSize:"12px",fontFamily:"inherit",transition:"all 0.1s"}}
            onMouseEnter={e=>{e.target.style.background=b.c+"33";e.target.style.color=b.c;}}
            onMouseLeave={e=>{e.target.style.background="transparent";e.target.style.color=C.textDim;}}>
            {b.l}
          </button>
        ))}
      </div>
    </div>
  );
}

function Terminal({lines,onClose}) {
  const ref=useRef(null);
  useEffect(()=>{if(ref.current)ref.current.scrollTop=ref.current.scrollHeight;},[lines]);
  const col={info:C.textDim,success:C.green,error:C.red,cmd:C.accentHi,warn:C.yellow};
  return (
    <div style={{position:"absolute",bottom:0,left:0,right:0,height:"200px",background:"#0a0a0c",borderTop:`1px solid ${C.border}`,fontFamily:"'JetBrains Mono','Fira Code',monospace",fontSize:"12px",display:"flex",flexDirection:"column",zIndex:50}}>
      <div style={{padding:"6px 16px",borderBottom:`1px solid ${C.borderFaint}`,display:"flex",justifyContent:"space-between",alignItems:"center"}}>
        <span style={{color:C.accent,fontSize:"11px",letterSpacing:"0.12em",textTransform:"uppercase"}}>Terminal Output</span>
        <button onClick={onClose} style={{background:"none",border:"none",color:C.muted,cursor:"pointer",fontSize:"18px",lineHeight:1}}>×</button>
      </div>
      <div ref={ref} style={{flex:1,overflowY:"auto",padding:"8px 16px"}}>
        {lines.map(l=>(
          <div key={l.id} style={{color:col[l.type]||C.textDim,marginBottom:"2px",lineHeight:"1.6"}}>
            {l.type==="cmd"?<><span style={{color:C.accent}}>$ </span>{l.text}</>:l.text}
          </div>
        ))}
      </div>
    </div>
  );
}

function Card({label,value,ab}) {
  return (
    <div style={{background:C.bgCard,border:`1px solid ${ab||C.border}`,borderRadius:"8px",padding:"14px 18px",display:"flex",flexDirection:"column",gap:"5px"}}>
      <span style={{color:C.muted,fontSize:"11px",textTransform:"uppercase",letterSpacing:"0.1em"}}>{label}</span>
      <span style={{color:C.text,fontSize:"14px",fontWeight:500}}>{value}</span>
    </div>
  );
}

function Hdr({title,sub}) {
  return (
    <div style={{marginBottom:"28px"}}>
      <h2 style={{color:C.text,fontSize:"19px",fontWeight:600,margin:0,letterSpacing:"-0.02em"}}>{title}</h2>
      {sub&&<p style={{color:C.textDim,fontSize:"13px",margin:"6px 0 0",lineHeight:1.5}}>{sub}</p>}
      <div style={{width:"32px",height:"2px",background:C.accent,marginTop:"12px",borderRadius:"2px"}}/>
    </div>
  );
}

function Btn({label,cmd,onClick,variant="default",icon}) {
  const [h,setH]=useState(false);
  const v={default:{bg:h?C.bgHover:"transparent",border:C.border,color:C.text},danger:{bg:h?"#2a1515":"transparent",border:C.red+"66",color:C.red},success:{bg:h?"#0d1f14":"transparent",border:C.green+"44",color:C.green}}[variant];
  return (
    <button onMouseEnter={()=>setH(true)} onMouseLeave={()=>setH(false)} onClick={()=>onClick(cmd,label)}
      style={{background:v.bg,border:`1px solid ${v.border}`,color:v.color,borderRadius:"7px",padding:"10px 16px",cursor:"pointer",fontSize:"13px",fontFamily:"inherit",transition:"all 0.12s",display:"flex",alignItems:"center",gap:"8px"}}>
      {icon&&<span style={{fontSize:"14px"}}>{icon}</span>}<span>{label}</span>
    </button>
  );
}

function StatusSection({run}) {
  const [s,setS]=useState({kernel:"…",uptime:"…",firewall:"…",disk:"…",memory:"…",wm:"bspwm",packages:"…"});
  useEffect(()=>{
    api("uname -r").then(r=>setS(p=>({...p,kernel:r.stdout.trim()||"—"})));
    api("uptime -p").then(r=>setS(p=>({...p,uptime:r.stdout.trim()||"—"})));
    api("sv status ufw 2>/dev/null | head -1").then(r=>setS(p=>({...p,firewall:r.stdout.includes("run")?"Active":"Inactive"})));
    api("df -h / | awk 'NR==2{print $5}'").then(r=>setS(p=>({...p,disk:r.stdout.trim()||"—"})));
    api("free -h | awk '/Mem:/{print $3\"/\"$2}'").then(r=>setS(p=>({...p,memory:r.stdout.trim()||"—"})));
    api("xbps-query -l | wc -l").then(r=>setS(p=>({...p,packages:r.stdout.trim()||"0"})));
  },[]);
  return (
    <div>
      <Hdr title="System Status" sub="Live overview of your SkywareOS X installation."/>
      <div style={{display:"grid",gridTemplateColumns:"repeat(3,1fr)",gap:"10px",marginBottom:"24px"}}>
        <Card label="Edition"   value="SkywareOS X" ab={C.accent+"44"}/>
        <Card label="Kernel"    value={s.kernel}/>
        <Card label="Uptime"    value={s.uptime}/>
        <Card label="Firewall"  value={s.firewall} ab={s.firewall==="Active"?C.green+"44":C.red+"33"}/>
        <Card label="Memory"    value={s.memory}/>
        <Card label="Disk"      value={s.disk}/>
        <Card label="Packages"  value={`${s.packages} (xbps)`}/>
        <Card label="WM"        value="bspwm + polybar"/>
        <Card label="Init"      value="runit (Void Linux)"/>
      </div>
      <div style={{display:"flex",gap:"10px",flexWrap:"wrap"}}>
        <Btn label="Run Diagnostics" cmd="echo n | ware doctor" onClick={run} icon="🩺"/>
        <Btn label="Update System"   cmd="ware update"    onClick={run} icon="↑" variant="success"/>
        <Btn label="Sync Repos"      cmd="ware sync"      onClick={run} icon="⟳"/>
        <Btn label="Clean Cache"     cmd="ware clean"     onClick={run} icon="✦"/>
        <Btn label="Autoremove"      cmd="ware autoremove"onClick={run} icon="✖" variant="danger"/>
      </div>
    </div>
  );
}

function PackagesSection({run}) {
  return (
    <div>
      <Hdr title="Packages" sub="xbps (native Void) and flatpak package management."/>
      <div style={{display:"flex",flexDirection:"column",gap:"10px"}}>
        <div style={{display:"flex",gap:"8px"}}>
          <input id="psi" placeholder="Package name…" style={{background:C.bgCard,border:`1px solid ${C.border}`,color:C.text,borderRadius:"7px",padding:"9px 14px",fontSize:"13px",flex:1,outline:"none",fontFamily:"inherit"}}/>
          <button onClick={()=>{const v=document.getElementById("psi").value;if(v)run(`ware install ${v}`,`Install: ${v}`);}} style={{background:C.bgHover,border:`1px solid ${C.accent}`,color:C.accentHi,borderRadius:"7px",padding:"9px 20px",cursor:"pointer",fontSize:"13px",fontWeight:600,fontFamily:"inherit"}}>Install</button>
          <button onClick={()=>{const v=document.getElementById("psi").value;if(v)run(`ware search ${v}`,`Search: ${v}`);}} style={{background:"transparent",border:`1px solid ${C.border}`,color:C.text,borderRadius:"7px",padding:"9px 20px",cursor:"pointer",fontSize:"13px",fontFamily:"inherit"}}>Search</button>
        </div>
        <Btn label="Update All Packages" cmd="ware update" onClick={run} icon="↑" variant="success"/>
        <Btn label="Remove Orphans"      cmd="ware autoremove" onClick={run} icon="✖"/>
        <Btn label="List Installed"      cmd="ware list" onClick={run} icon="◈"/>
        <Btn label="Clean Cache"         cmd="ware clean" onClick={run} icon="✦"/>
        <Btn label="Flatpak Apps"        cmd="flatpak list" onClick={run} icon="⬡"/>
      </div>
    </div>
  );
}

function BspwmSection({run}) {
  return (
    <div>
      <Hdr title="bspwm Controls" sub="Manage your tiling window manager and compositor."/>
      <div style={{display:"grid",gridTemplateColumns:"repeat(2,1fr)",gap:"10px"}}>
        <Btn label="Reload bspwm"    cmd="bspc wm -r"       onClick={run} icon="⟳"/>
        <Btn label="Reload sxhkd"    cmd="pkill -USR1 -x sxhkd" onClick={run} icon="⌨"/>
        <Btn label="Restart Polybar" cmd="pkill polybar; polybar skyware &" onClick={run} icon="◈"/>
        <Btn label="Restart Picom"   cmd="pkill picom; picom --daemon &" onClick={run} icon="◉"/>
        <Btn label="Restart Dunst"   cmd="pkill dunst; dunst &" onClick={run} icon="🔔"/>
        <Btn label="List Workspaces" cmd="bspc query -D --names" onClick={run} icon="⬡"/>
        <Btn label="Floating Toggle" cmd="bspc node -t ~floating" onClick={run} icon="⬕"/>
        <Btn label="Monocle Toggle"  cmd="bspc desktop -l next" onClick={run} icon="◈"/>
        <Btn label="Show bspwm State" cmd="bspc query -T -m" onClick={run} icon="⚙"/>
        <Btn label="Lock Screen"     cmd="i3lock -c 111113" onClick={run} icon="🔒"/>
      </div>
    </div>
  );
}

function PowerSection({run}) {
  const [active,setActive]=useState("balanced");
  const profiles=[
    {id:"balanced",label:"Balanced",icon:"⚖",desc:"Optimal performance and efficiency."},
    {id:"performance",label:"Performance",icon:"⚡",desc:"Maximum CPU speed for heavy workloads."},
    {id:"battery",label:"Battery Saver",icon:"🔋",desc:"Extends battery life via TLP + powersave."},
  ];
  return (
    <div>
      <Hdr title="Power Management" sub="TLP + cpupower profiles for Void Linux."/>
      <div style={{display:"flex",flexDirection:"column",gap:"10px"}}>
        {profiles.map(p=>(
          <div key={p.id} onClick={()=>{setActive(p.id);run(`ware power ${p.id}`,`Power: ${p.label}`);}}
            style={{background:active===p.id?C.bgHover:C.bgCard,border:`1px solid ${active===p.id?C.accent:C.border}`,borderRadius:"9px",padding:"16px 20px",cursor:"pointer",display:"flex",alignItems:"center",gap:"16px",transition:"all 0.14s"}}>
            <span style={{fontSize:"22px"}}>{p.icon}</span>
            <div style={{flex:1}}>
              <div style={{color:active===p.id?C.accentHi:C.text,fontWeight:600,fontSize:"14px"}}>{p.label}</div>
              <div style={{color:C.textDim,fontSize:"12px",marginTop:"3px"}}>{p.desc}</div>
            </div>
            {active===p.id&&<div style={{color:C.accent,fontSize:"18px"}}>●</div>}
          </div>
        ))}
      </div>
      <div style={{marginTop:"18px"}}><Btn label="Check Current Profile" cmd="ware power status" onClick={run} icon="◈"/></div>
    </div>
  );
}

function ServicesSection({run}) {
  const services = [
    "NetworkManager","ufw","apparmor","bluetoothd","cups","docker","usbguard",
    "sddm","dbus","avahi-daemon","tlp","udiskie"
  ];
  return (
    <div>
      <Hdr title="runit Services" sub="Manage Void Linux services via sv / vsv."/>
      <div style={{display:"grid",gridTemplateColumns:"repeat(2,1fr)",gap:"8px",marginBottom:"16px"}}>
        {services.map(svc=>(
          <div key={svc} style={{background:C.bgCard,border:`1px solid ${C.border}`,borderRadius:"8px",padding:"10px 14px",display:"flex",justifyContent:"space-between",alignItems:"center"}}>
            <span style={{fontSize:"13px",color:C.text,fontFamily:"monospace"}}>{svc}</span>
            <div style={{display:"flex",gap:"6px"}}>
              <button onClick={()=>run(`sudo sv start ${svc}`,`Start ${svc}`)} style={{background:"transparent",border:`1px solid ${C.green}44`,color:C.green,borderRadius:"4px",padding:"3px 8px",cursor:"pointer",fontSize:"11px",fontFamily:"inherit"}}>start</button>
              <button onClick={()=>run(`sudo sv stop ${svc}`,`Stop ${svc}`)} style={{background:"transparent",border:`1px solid ${C.red}44`,color:C.red,borderRadius:"4px",padding:"3px 8px",cursor:"pointer",fontSize:"11px",fontFamily:"inherit"}}>stop</button>
              <button onClick={()=>run(`sv status ${svc}`,`Status ${svc}`)} style={{background:"transparent",border:`1px solid ${C.border}`,color:C.textDim,borderRadius:"4px",padding:"3px 8px",cursor:"pointer",fontSize:"11px",fontFamily:"inherit"}}>status</button>
            </div>
          </div>
        ))}
      </div>
      <Btn label="List All Services" cmd="ls -la /var/service/" onClick={run} icon="☰"/>
    </div>
  );
}

function SystemSection({run}) {
  return (
    <div>
      <Hdr title="System Tools" sub="Maintenance, diagnostics, and developer utilities."/>
      <div style={{display:"grid",gridTemplateColumns:"repeat(2,1fr)",gap:"10px"}}>
        <Btn label="Run Doctor"         cmd="echo n | ware doctor"  onClick={run} icon="🩺"/>
        <Btn label="AI Doctor"          cmd="ware-ai-doctor"        onClick={run} icon="🤖"/>
        <Btn label="Sync xbps"          cmd="ware sync"             onClick={run} icon="⟳"/>
        <Btn label="Clean Cache"        cmd="ware clean"            onClick={run} icon="✦"/>
        <Btn label="Autoremove Orphans" cmd="ware autoremove"       onClick={run} icon="✖"/>
        <Btn label="Benchmark"          cmd="ware benchmark"        onClick={run} icon="📊"/>
        <Btn label="Repair System"      cmd="ware repair"           onClick={run} icon="🔧" variant="danger"/>
        <Btn label="Open Website"       cmd="ware git"              onClick={run} icon="◎"/>
      </div>
    </div>
  );
}

function ChannelSection({run}) {
  const [ch,setCh]=useState("release");
  const opts=[
    {id:"release",label:"0.1 Void",desc:"Stable developer builds.",color:C.green},
    {id:"testing", label:"Testing",   desc:"Latest features, may have bugs.",color:C.yellow},
  ];
  return (
    <div>
      <Hdr title="Update Channel" sub="Switch between stable and testing builds."/>
      <div style={{display:"flex",gap:"12px",marginBottom:"24px"}}>
        {opts.map(o=>(
          <div key={o.id} onClick={()=>setCh(o.id)} style={{background:ch===o.id?C.bgHover:C.bgCard,border:`1px solid ${ch===o.id?o.color+"88":C.border}`,borderRadius:"9px",padding:"20px",cursor:"pointer",flex:1,transition:"all 0.14s"}}>
            <div style={{color:ch===o.id?o.color:C.text,fontWeight:700,fontSize:"14px",marginBottom:"6px"}}>{o.label} {ch===o.id&&"●"}</div>
            <div style={{color:C.textDim,fontSize:"12px",lineHeight:1.5}}>{o.desc}</div>
          </div>
        ))}
      </div>
      <div style={{display:"flex",gap:"10px"}}>
        {ch==="testing"&&<Btn label="Switch to Testing" cmd="ware switch" onClick={run} icon="◎" variant="danger"/>}
        <Btn label="Upgrade SkywareOS X" cmd="ware upgrade" onClick={run} icon="↑" variant="success"/>
      </div>
    </div>
  );
}

export default function App() {
  const [active,setActive]=useState("status");
  const [termOpen,setTermOpen]=useState(false);
  const {lines,add}=useTerminal();

  const run=async(cmd,label)=>{
    setTermOpen(true); add(cmd,"cmd"); add(`→ Running: ${label||cmd}…`,"info");
    const r=await api(cmd);
    if(r.stdout) r.stdout.trim().split("\n").filter(Boolean).forEach(l=>add(l,"info"));
    if(r.stderr) r.stderr.trim().split("\n").filter(Boolean).forEach(l=>add(l,"error"));
    add("✔ Done.","success");
  };

  const sections={status:StatusSection,packages:PackagesSection,bspwm:BspwmSection,power:PowerSection,system:SystemSection,services:ServicesSection,channel:ChannelSection};
  const ActiveSection=sections[active];

  return (
    <div style={{height:"100vh",background:C.bg,fontFamily:"'Segoe UI','SF Pro Display',system-ui,sans-serif",color:C.text,display:"flex",flexDirection:"column",overflow:"hidden",position:"relative"}}>
      <TitleBar/>
      <div style={{display:"flex",flex:1,overflow:"hidden"}}>
        <div style={{width:"192px",background:C.bgSide,borderRight:`1px solid ${C.borderFaint}`,flexShrink:0,padding:"14px 0",overflowY:"auto"}}>
          {SIDEBAR.map(s=>(
            <button key={s.id} onClick={()=>setActive(s.id)}
              style={{width:"100%",background:active===s.id?C.bgHover:"transparent",border:"none",borderLeft:`2px solid ${active===s.id?C.accent:"transparent"}`,color:active===s.id?C.accentHi:C.muted,padding:"10px 18px",cursor:"pointer",textAlign:"left",fontSize:"13px",fontFamily:"inherit",transition:"all 0.1s",display:"flex",alignItems:"center",gap:"10px"}}>
              <span style={{fontSize:"13px"}}>{s.icon}</span>{s.label}
            </button>
          ))}
          <div style={{padding:"20px 18px 0",borderTop:`1px solid ${C.border}`,marginTop:"24px"}}>
            <div style={{color:C.mutedLo,fontSize:"10px",lineHeight:1.8}}>
              <div>ware v0.1</div><div>Void · bspwm · runit</div><div>0.1 Void</div>
            </div>
          </div>
        </div>
        <div style={{flex:1,padding:"28px 32px",overflowY:"auto",paddingBottom:termOpen?"220px":"28px"}}>
          <ActiveSection run={run}/>
        </div>
      </div>
      {termOpen&&<Terminal lines={lines} onClose={()=>setTermOpen(false)}/>}
      {!termOpen&&(
        <button onClick={()=>{setTermOpen(true);if(lines.length===0)add("Terminal ready.","info");}}
          style={{position:"absolute",bottom:"12px",right:"16px",background:C.bgCard,border:`1px solid ${C.border}`,color:C.textDim,borderRadius:"6px",padding:"6px 14px",cursor:"pointer",fontSize:"11px",fontFamily:"inherit",letterSpacing:"0.07em",zIndex:40}}>
          TERMINAL ▲
        </button>
      )}
    </div>
  );
}
APPEOF

# Build
sudo chown -R "$USER:$USER" "$APP_DIR"
cd "$APP_DIR"
npm install 2>&1 | tail -5
npx vite build 2>&1 | tail -5

[ -f "$APP_DIR/dist/index.html" ] || { npx vite build; }
ok "Settings app built"

sudo chown -R root:root "$APP_DIR"
sudo chmod -R a+rX "$APP_DIR"
sudo npm install -g electron 2>&1 | tail -3

sudo tee /usr/local/bin/skyware-settings > /dev/null << 'EOF'
#!/bin/bash
exec electron /opt/skyware-settings "$@"
EOF
sudo chmod +x /usr/local/bin/skyware-settings

sudo tee /usr/share/applications/skyware-settings.desktop > /dev/null << 'EOF'
[Desktop Entry]
Name=SkywareOS X Settings
Comment=Manage your SkywareOS X installation
Exec=/usr/local/bin/skyware-settings
Icon=preferences-system
Terminal=false
Type=Application
Categories=System;Settings;
Keywords=skyware;settings;ware;bspwm;void;
EOF

mkdir -p "$HOME/Desktop"
cp /usr/share/applications/skyware-settings.desktop "$HOME/Desktop/"
chmod +x "$HOME/Desktop/skyware-settings.desktop"
ok "SkywareOS Settings installed → skyware-settings or ware settings"

# ─────────────────────────────────────────────────────────────
#  14. AI Doctor
# ─────────────────────────────────────────────────────────────
echo ""
echo "══ [14/22] AI Doctor ════════════════════════════════"

sudo tee /usr/local/bin/ware-ai-doctor > /dev/null << 'EOF'
#!/bin/bash
# SkywareOS X AI Doctor — Claude API + Void Linux diagnostics
RED="\e[31m"; CYAN="\e[36m"; GREEN="\e[32m"; YELLOW="\e[33m"; RESET="\e[0m"

KEY_FILE="$HOME/.config/skyware/api_key"
API_KEY="${ANTHROPIC_API_KEY:-}"
[ -z "$API_KEY" ] && [ -f "$KEY_FILE" ] && API_KEY=$(cat "$KEY_FILE")

if [ -z "$API_KEY" ]; then
    echo -e "${YELLOW}→ No Anthropic API key found.${RESET}"
    echo -e "  echo 'sk-ant-...' > ~/.config/skyware/api_key"
    exit 1
fi

echo -e "${CYAN}== SkywareOS X AI Doctor ==${RESET}"
ERRORS=$(sudo svlogd /var/log 2>/dev/null || journalctl -p err -b --no-pager -n 20 2>/dev/null || echo "no log access")
FAILED=$(ls /var/service/ 2>/dev/null | xargs -I{} sh -c 'sv status {} 2>/dev/null | grep -v "^run" && echo {}' 2>/dev/null || echo "")
XBPS_LOG=$(tail -n 20 /var/log/xbps.log 2>/dev/null || echo "no xbps log")
OS_INFO="SkywareOS X 0.1 Void (Void Linux), bspwm, runit, kernel $(uname -r)"

PROMPT="You are a Linux system repair assistant for SkywareOS X (Void Linux, bspwm, runit). Analyze these diagnostics and provide specific, actionable fix commands. Format: issue → fix command.

OS: $OS_INFO
Service issues: $FAILED
Recent errors: $ERRORS
xbps log: $XBPS_LOG"

echo -e "${CYAN}→ Querying Claude...${RESET}"
RESPONSE=$(curl -s https://api.anthropic.com/v1/messages \
    -H "x-api-key: $API_KEY" \
    -H "anthropic-version: 2023-06-01" \
    -H "content-type: application/json" \
    -d "{\"model\":\"claude-sonnet-4-20250514\",\"max_tokens\":1024,\"messages\":[{\"role\":\"user\",\"content\":$(echo "$PROMPT" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))')}]}" 2>/dev/null)

echo "$RESPONSE" | python3 -c "
import json,sys
try:
    data=json.load(sys.stdin); print(data['content'][0]['text'])
except:
    print('Could not parse API response.')
" 2>/dev/null
EOF
sudo chmod +x /usr/local/bin/ware-ai-doctor
ok "AI Doctor installed"

# ─────────────────────────────────────────────────────────────
#  15. SDDM login screen
# ─────────────────────────────────────────────────────────────
echo ""
echo "══ [15/22] SDDM login screen ════════════════════════"

BREEZE_DIR="/usr/share/sddm/themes/breeze"
sudo mkdir -p "$BREEZE_DIR/assets"
[ -f assets/skywareos.svg ] && sudo cp assets/skywareos.svg "$BREEZE_DIR/assets/logo.svg" || true

if command -v convert &>/dev/null && [ -f assets/skywareos.svg ]; then
    sudo rsvg-convert -w 300 -h 300 assets/skywareos.svg -o /tmp/skyware-logo-300.png 2>/dev/null || true
    sudo convert -size 1920x1080 xc:#111113 \
        /tmp/skyware-logo-300.png -gravity Center -composite \
        "$BREEZE_DIR/background.jpg" 2>/dev/null || true
elif command -v convert &>/dev/null; then
    sudo convert -size 1920x1080 xc:#111113 "$BREEZE_DIR/background.jpg" 2>/dev/null || true
fi

sudo tee "$BREEZE_DIR/theme.conf" > /dev/null << 'EOF'
[General]
background=/usr/share/sddm/themes/breeze/background.jpg
type=image
color=#111113
showClock=true
EOF

SDDM_DISPLAY_SERVER="x11"
echo "$GPU_INFO" | grep -qi "NVIDIA" || SDDM_DISPLAY_SERVER="x11"  # bspwm is X11

sudo mkdir -p /etc/sddm.conf.d
sudo tee /etc/sddm.conf.d/10-skywareos.conf > /dev/null << EOF
[Theme]
Current=breeze

[General]
DisplayServer=x11

[X11]
MinimumVT=1
EOF

ok "SDDM configured (breeze theme, x11 — bspwm is Xorg-native)"

# ─────────────────────────────────────────────────────────────
#  16. Flatpak apps
# ─────────────────────────────────────────────────────────────
echo ""
echo "══ [16/22] Flatpak apps ══════════════════════════════"

flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo 2>/dev/null || \
    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

flatpak install -y flathub \
    com.discordapp.Discord \
    com.spotify.Client \
    com.valvesoftware.Steam \
    com.usebottles.bottles

ok "Flatpak apps installed (Discord, Spotify, Steam, Bottles)"

# ─────────────────────────────────────────────────────────────
#  17. Security hardening
# ─────────────────────────────────────────────────────────────
echo ""
echo "══ [17/22] Security ════════════════════════════════"

# UFW firewall
sudo ufw enable 2>/dev/null || true
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
ok "UFW firewall enabled"

# SSH hardening
sudo mkdir -p /etc/ssh/sshd_config.d
sudo tee /etc/ssh/sshd_config.d/99-skywareos.conf > /dev/null << 'EOF'
PermitRootLogin no
PasswordAuthentication yes
PermitEmptyPasswords no
X11Forwarding no
MaxAuthTries 3
LoginGraceTime 20
AllowAgentForwarding no
Protocol 2
ClientAliveInterval 300
ClientAliveCountMax 2
EOF
ok "SSH hardened"

# USBGuard
sudo usbguard generate-policy 2>/dev/null | sudo tee /etc/usbguard/rules.conf >/dev/null 2>&1 || true
ok "USBGuard configured"

# AppArmor
[ -n "$LIMINE_CONF" ] && \
    grep -qi "^[[:space:]]*cmdline" "$LIMINE_CONF" && \
    sudo sed -i -E '/^[[:space:]]*cmdline/{ /apparmor=1/! s/$/ apparmor=1 security=apparmor/ }' "$LIMINE_CONF"
ok "AppArmor kernel params set"

# ─────────────────────────────────────────────────────────────
#  18. xbps auto-update hook (cron via Void's cronie)
# ─────────────────────────────────────────────────────────────
echo ""
echo "══ [18/22] Auto-update + notifications ══════════════"

XI cronie 2>/dev/null || true
enable_sv cronie 2>/dev/null || true

# Weekly xbps security sync via cron (Void has no systemd timers)
sudo tee /etc/cron.weekly/skyware-security-update > /dev/null << 'EOF'
#!/bin/bash
xbps-install -Su --yes 2>&1 | logger -t skyware-update
flatpak update -y 2>&1 | logger -t skyware-update
EOF
sudo chmod +x /etc/cron.weekly/skyware-security-update
ok "Weekly auto-update cron job installed"

# Update notifier
sudo tee /usr/local/bin/skyware-update-notifier > /dev/null << 'EOF'
#!/usr/bin/env python3
import subprocess, sys

def count_updates():
    try:
        r = subprocess.run(["xbps-install","-Mnu"], capture_output=True, text=True, timeout=30)
        xbps = len([l for l in r.stdout.splitlines() if l.strip()])
    except: xbps = 0
    try:
        r = subprocess.run(["flatpak","remote-ls","--updates"], capture_output=True, text=True, timeout=30)
        fp = len([l for l in r.stdout.splitlines() if l.strip()])
    except: fp = 0
    return xbps, fp

def notify(xbps, fp):
    total = xbps + fp
    if total == 0: return
    parts = []
    if xbps > 0: parts.append(f"{xbps} xbps")
    if fp   > 0: parts.append(f"{fp} flatpak")
    subprocess.run(["notify-send","--app-name=SkywareOS",
        "--icon=system-software-update","--urgency=normal","--expire-time=8000",
        f"SkywareOS X: {total} update{'s' if total>1 else ''} available",
        f"{', '.join(parts)} package{'s' if total>1 else ''} ready.\nRun: ware update"])

if __name__ == "__main__":
    x, f = count_updates()
    notify(x, f)
EOF
sudo chmod +x /usr/local/bin/skyware-update-notifier

# Run via autostart every 6 hours using a background daemon pattern
cat > "$HOME/.config/autostart-scripts/skyware-update-check.sh" << 'EOF'
#!/bin/bash
while true; do
    sleep 21600  # 6 hours
    skyware-update-notifier
done
EOF
chmod +x "$HOME/.config/autostart-scripts/skyware-update-check.sh"
ok "Update notifier installed"

# ─────────────────────────────────────────────────────────────
#  19. TLP + battery health
# ─────────────────────────────────────────────────────────────
echo ""
echo "══ [19/22] TLP battery health ════════════════════════"

sudo tee /etc/tlp.conf > /dev/null << 'EOF'
TLP_ENABLE=1
TLP_DEFAULT_MODE=AC
CPU_SCALING_GOVERNOR_ON_AC=schedutil
CPU_SCALING_GOVERNOR_ON_BAT=powersave
CPU_ENERGY_PERF_POLICY_ON_AC=balance_performance
CPU_ENERGY_PERF_POLICY_ON_BAT=power
START_CHARGE_THRESH_BAT0=20
STOP_CHARGE_THRESH_BAT0=80
PCIE_ASPM_ON_AC=default
PCIE_ASPM_ON_BAT=powersupersave
USB_AUTOSUSPEND=1
USB_EXCLUDE_AUDIO=1
USB_EXCLUDE_BTUSB=1
DISK_APM_LEVEL_ON_AC="254 254"
DISK_APM_LEVEL_ON_BAT="128 128"
WIFI_PWR_ON_AC=off
WIFI_PWR_ON_BAT=on
NMI_WATCHDOG=0
RUNTIME_PM_ON_AC=on
RUNTIME_PM_ON_BAT=auto
EOF
enable_sv tlp 2>/dev/null || true
ok "TLP configured (charge 20–80%)"

# ─────────────────────────────────────────────────────────────
#  20. Docker + Podman
# ─────────────────────────────────────────────────────────────
echo ""
echo "══ [20/22] Docker + Podman ═══════════════════════════"

sudo gpasswd -a "$USER" docker
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json > /dev/null << 'EOF'
{
  "exec-opts": ["native.cgroupdriver=cgroupfs"],
  "log-driver": "journald",
  "live-restore": true,
  "userland-proxy": false
}
EOF
# Void Linux uses cgroupfs, not systemd cgroups
ok "Docker configured (cgroupfs — Void/runit)"
ok "Podman installed"

# ─────────────────────────────────────────────────────────────
#  21. Dotfiles auto-backup
# ─────────────────────────────────────────────────────────────
echo ""
echo "══ [21/22] Dotfiles backup ═══════════════════════════"

DOTFILES_DIR="$HOME/.dotfiles"
[ -d "$DOTFILES_DIR/.git" ] || git init --bare "$DOTFILES_DIR" 2>/dev/null || git init "$DOTFILES_DIR"

DOTFILES_CMD="git --git-dir=$DOTFILES_DIR --work-tree=$HOME"
$DOTFILES_CMD config status.showUntrackedFiles no 2>/dev/null || true

for f in "$HOME/.zshrc" "$HOME/.config/starship.toml" \
          "$HOME/.config/btop/btop.conf" "$HOME/.config/fastfetch/config.jsonc" \
          "$HOME/.config/bspwm/bspwmrc" "$HOME/.config/sxhkd/sxhkdrc" \
          "$HOME/.config/polybar/config.ini" "$HOME/.config/picom/picom.conf"; do
    [ -f "$f" ] && $DOTFILES_CMD add "$f" 2>/dev/null || true
done
$DOTFILES_CMD commit -m "SkywareOS X initial dotfiles" 2>/dev/null || true

# Daily cron backup (Void uses cronie, not systemd user timers)
(crontab -l 2>/dev/null; echo "0 3 * * * git --git-dir=$HOME/.dotfiles --work-tree=$HOME add -u && git --git-dir=$HOME/.dotfiles --work-tree=$HOME commit -m 'auto: \$(date +%%Y-%%m-%%d)' 2>/dev/null || true") | sort -u | crontab -
ok "Dotfiles backup configured (daily cron at 03:00)"

# ─────────────────────────────────────────────────────────────
#  22. MOTD + tmux + Gaming
# ─────────────────────────────────────────────────────────────
echo ""
echo "══ [22/22] MOTD + tmux + Gaming ══════════════════════"

# MOTD
sudo tee /etc/profile.d/skyware-motd.sh > /dev/null << 'MOTDEOF'
#!/bin/bash
[[ $- != *i* ]] && return
[[ -n "$MOTD_SHOWN" ]] && return
export MOTD_SHOWN=1

GRAY="\e[38;5;245m"; WHITE="\e[97m"; GREEN="\e[92m"
YELLOW="\e[93m"; RESET="\e[0m"; BOLD="\e[1m"

echo ""
echo -e "${GRAY}   .+@@@@@@@@@@*.        ${RESET}  ${BOLD}${WHITE}SkywareOS X${RESET}"
echo -e "${GRAY} .%@@@@@@@@@@@@@@@@@.    ${RESET}  ${GRAY}0.1 Void  ·  Void Linux${RESET}"
echo -e "${GRAY}-@@@@@@@@@@@@@@@@@@@@-   ${RESET}  ${GRAY}──────────────────────${RESET}"
echo -e "${GRAY} @@@@@+::....:+@@@@@@    ${RESET}  ${GRAY}Kernel${RESET}  $(uname -r)"
echo -e "${GRAY}  .@%.          .%@@@    ${RESET}  ${GRAY}Uptime${RESET}  $(uptime -p | sed 's/up //')"
echo -e "${GRAY}%%                @@@    ${RESET}  ${GRAY}WM    ${RESET}  bspwm + polybar"
echo -e "${GRAY}@@.               @@@    ${RESET}  ${GRAY}Pkgs  ${RESET}  $(xbps-query -l 2>/dev/null | wc -l) (xbps)"
echo -e "${GRAY}@@   .@@+  .@@-   @@@    ${RESET}  ${GRAY}Mem   ${RESET}  $(free -h | awk '/Mem:/{print $3"/"$2}')"
echo -e "${GRAY}@@  @@@@@ *@@@@@  @@@    ${RESET}  ${GRAY}Init  ${RESET}  runit"
echo -e "${GRAY}@@  @: @@    @@   @@@    ${RESET}"
echo -e "${GRAY}@@  @@  @@  =@    @@@    ${RESET}"
echo -e "${GRAY}@@  @:  @@@:@@    @@@    ${RESET}"
echo -e "${GRAY}@@  @@@@ .@@@@@   @@@    ${RESET}"
echo -e "${GRAY}@@   .@@.  .@@.   @@@    ${RESET}"
echo -e "${GRAY}@@-               @@@    ${RESET}"
echo -e "${GRAY} @@@.           .@@@     ${RESET}"
echo -e "${GRAY}  @@@@@@@@@@@@@@@@@@     ${RESET}"
echo -e "${GRAY}   .@@@@@@@@@@@@@@.      ${RESET}"
echo -e "${GRAY}      .#@@@@@@#.         ${RESET}"
echo ""

UPDATES=$(xbps-install -Mnu 2>/dev/null | wc -l)
[ "$UPDATES" -gt 0 ] && echo -e "  ${YELLOW}⚠${RESET}  ${YELLOW}${UPDATES} xbps update(s)${RESET} — run ${GRAY}ware update${RESET}" && echo ""
MOTDEOF
sudo chmod +x /etc/profile.d/skyware-motd.sh
sudo rm -f /etc/motd
ok "MOTD installed"

# tmux
cat > "$HOME/.tmux.conf" << 'EOF'
unbind C-b
set -g prefix C-Space
bind C-Space send-prefix
set -g mouse on
set -g history-limit 50000
set -g base-index 1
setw -g pane-base-index 1
set -g renumber-windows on
set -sg escape-time 0
set -g focus-events on
set -g default-terminal "tmux-256color"
set -ag terminal-overrides ",xterm-256color:RGB"
set -g status on
set -g status-position bottom
set -g status-interval 5
set -g status-style "bg=#0e0e10,fg=#a0a0b0"
set -g status-left-length 40
set -g status-left "#[bg=#1f1f23,fg=#c8c8dc,bold]  SkywareOS X #[bg=#0e0e10,fg=#2a2a2f]#[default] "
set -g status-right-length 80
set -g status-right "#[fg=#4a4a58]  #[fg=#7a7a8a]%H:%M  #[fg=#4a4a58]  #[fg=#7a7a8a]%d %b  "
setw -g window-status-current-format "#[bg=#1f1f23,fg=#c8c8dc,bold] #I #W #[default]"
setw -g window-status-format         "#[fg=#4a4a58] #I #W "
setw -g window-status-separator ""
set -g pane-border-style        "fg=#2a2a2f"
set -g pane-active-border-style "fg=#a0a0b0"
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R
bind r source-file ~/.tmux.conf \; display "Config reloaded"
EOF
ok "tmux configured"

# MangoHud config
mkdir -p "$HOME/.config/MangoHud"
cat > "$HOME/.config/MangoHud/MangoHud.conf" << 'EOF'
legacy_layout=false
background_alpha=0.4
font_size=20
round_corners=8
offset_x=12
offset_y=12
position=top-left
background_color=111113
text_color=e2e2ec
fps=1
frame_timing=1
cpu_stats=1
cpu_temp=1
gpu_stats=1
gpu_temp=1
vram=1
ram=1
time=1
time_format=%H:%M
toggle_hud=Shift_F12
EOF
ok "MangoHud configured (toggle: Shift+F12)"

# Timeshift
FS_TYPE=$(df -T / | awk 'NR==2{print $2}')
SNAPSHOT_TYPE="RSYNC"
[ "$FS_TYPE" = "btrfs" ] && SNAPSHOT_TYPE="BTRFS"
sudo mkdir -p /etc/timeshift
sudo tee /etc/timeshift/timeshift.json > /dev/null << TSEOF
{
  "btrfs_mode": "$([ "$SNAPSHOT_TYPE" = "BTRFS" ] && echo true || echo false)",
  "do_first_run": "false",
  "schedule_monthly": "true",
  "schedule_weekly": "true",
  "schedule_daily": "false",
  "count_monthly": "2",
  "count_weekly": "3",
  "exclude": ["- /home/**/.thumbnails","- /home/**/.cache","- /home/**/.local/share/Trash"]
}
TSEOF
ok "Timeshift configured ($SNAPSHOT_TYPE mode)"

# Touch gestures
XI libinput 2>/dev/null || true
sudo gpasswd -a "$USER" input
mkdir -p "$HOME/.config"
cat > "$HOME/.config/libinput-gestures.conf" << 'EOF'
gesture swipe left  3  xdotool key super+Right
gesture swipe right 3  xdotool key super+Left
gesture swipe up    3  xdotool key super+s
gesture swipe down  3  xdotool key super+s
gesture pinch in    2  xdotool key super+minus
gesture pinch out   2  xdotool key super+equal
EOF
ok "Touchpad gestures configured"

# Timezone
DETECTED_TZ=$(curl -s --max-time 5 "https://ipapi.co/timezone" 2>/dev/null || echo "")
if [ -n "$DETECTED_TZ" ] && timedatectl list-timezones 2>/dev/null | grep -qx "$DETECTED_TZ"; then
    sudo ln -sf "/usr/share/zoneinfo/$DETECTED_TZ" /etc/localtime
    ok "Timezone set to $DETECTED_TZ"
else
    sudo ln -sf /usr/share/zoneinfo/UTC /etc/localtime
    warn "Timezone set to UTC (auto-detect failed)"
fi

# Locale
if ! grep -q "^en_US.UTF-8 UTF-8" /etc/default/libc-locales 2>/dev/null; then
    echo "en_US.UTF-8 UTF-8" | sudo tee -a /etc/default/libc-locales >/dev/null
fi
sudo xbps-reconfigure -f glibc-locales 2>/dev/null || true
[ ! -f /etc/locale.conf ] && echo "LANG=en_US.UTF-8" | sudo tee /etc/locale.conf >/dev/null
ok "Locale set to en_US.UTF-8"

# ─────────────────────────────────────────────────────────────
#  Autostart scripts directory bootstrap
# ─────────────────────────────────────────────────────────────
mkdir -p "$HOME/.config/autostart-scripts"
cat > "$HOME/.config/autostart-scripts/skyware-welcome-check.sh" << 'EOF'
#!/bin/bash
FLAG="$HOME/.config/skyware/welcome-done"
[ -f "$FLAG" ] && exit 0
sleep 4
skyware-welcome &
EOF
chmod +x "$HOME/.config/autostart-scripts/skyware-welcome-check.sh"

# ─────────────────────────────────────────────────────────────
#  Done
# ─────────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}║${RESET}    ${GREEN}✔ SkywareOS X setup complete!${RESET}              ${CYAN}║${RESET}"
echo -e "${CYAN}╠══════════════════════════════════════════════════════╣${RESET}"
echo -e "${CYAN}║${RESET}  WM:       bspwm + sxhkd + polybar + picom + rofi    ${CYAN}║${RESET}"
echo -e "${CYAN}║${RESET}  Init:     runit (Void Linux native)                 ${CYAN}║${RESET}"
echo -e "${CYAN}║${RESET}  Pkg mgr:  xbps + flatpak via ware                   ${CYAN}║${RESET}"
echo -e "${CYAN}║${RESET}  Display:  SDDM (X11 / bspwm session)                ${CYAN}║${RESET}"
echo -e "${CYAN}║${RESET}  Edition:  0.1 Void                           ${CYAN}║${RESET}"
echo -e "${CYAN}╠══════════════════════════════════════════════════════╣${RESET}"
echo -e "${CYAN}║${RESET}  ${YELLOW}→ Log out or reboot required to start the session${RESET}  ${CYAN}║${RESET}"
echo -e "${CYAN}║${RESET}  ${YELLOW}→ Run 'ware help' to see all commands${RESET}              ${CYAN}║${RESET}"
echo -e "${CYAN}║${RESET}  ${YELLOW}→ super+d = launcher   super+Return = terminal${RESET}     ${CYAN}║${RESET}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════╝${RESET}"
