# rosebar
A bar for people who like islands.

![rosebar screenshot](rosebar.png)
## requirements

- **linux + wayland** — rosebar is intended for wayland desktops.
- **[quickshell](https://github.com/quickshell-mirror/quickshell)** — required to run the bar.
- **a compatible wayland compositor** — workspace and window-title features depend on compositor support. (MangoWM used for testing)
- **coreutils** — used by the installer for file operations.

some modules may require additional system utilities or services, depending on how they are implemented. make sure any tools used by your configuration are installed and available in your `PATH`.

## installation

clone the repository and run the installer:

```bash
git clone https://github.com/sappyware/rosebar.git
cd rosebar
chmod +x install.sh
./install.sh
```

the installer copies the QML files into `~/.config/quickshell/rosebar/`.

## running

start rosebar with:

```bash
qs -c rosebar
```

to stop it, use:

```bash
qs -c rosebar kill
```
example usage in MangoWM:
```bash
exec_once=qs -c rosebar
```

## configuration
config file is located at ```~/.config/rosebar/config.toml```
```bash
# rosebar config

theme           = "catppuccin-mocha"   # mocha, latte, nord, gruvbox, tokyonight, rose-pine, dracula
style           = "islands"            # islands | joined | bar
position        = "top"                # top | bottom
layer           = "top"                # background | bottom | top | overlay
tags            = 9
poll_ms         = 1000
volume_step     = 5
clock_format    = "ddd dd  HH:mm"
title_max_chars = 45

[font]
family         = "IosevkaTerm Nerd Font Mono"
size           = 20
weight         = "normal"              # normal | bold | 100-900
italic         = false
letter_spacing = 0

[bar]
margin_top    = 6
margin_bottom = 0
margin_left   = 12
margin_right  = 12
module_gap    = 6
workspace_gap = 6
# only used with style = "bar"
padding_x     = 0
padding_y     = 0
radius        = 10
border_width  = 1

[island]
radius       = 10
padding_x    = 10
padding_y    = 6
border_width = 1

[layout]
# brand workspaces title media tray cpu memory network volume battery clock
left   = ["brand", "workspaces", "media"]
center = ["title"]
right  = ["tray", "cpu", "memory", "network", "volume", "battery", "clock"]

[workspaces]
labels    = ["一", "二", "三", "四", "五", "六", "七", "八", "九"]
count     = 0                          # 0 = show all tags
radius    = 10
padding_x = 10

[media]
cover_art     = true
art_size      = 28
visualizer    = true
bars          = 12
bar_width     = 2
bar_gap       = 2
max_title_len = 40

[colors]
bg        = "#1e1e2e"
fg        = "#cdd6f4"
border    = "#313244"
muted     = "#9399b2"
accent    = "#f5c2e7"
accent_fg = "#1e1e2e"
urgent    = "#f38ba8"
cpu       = "#a6e3a1"
memory    = "#f9e2af"
network   = "#89dceb"
volume    = "#cba6f7"
battery   = "#fab387"

# per-module overrides (fg / bg / border / bold)
[module.clock]
fg     = "#1e1e2e"
bg     = "#f5c2e7"
border = "#f5c2e7"
bold   = true

[module.brand]
fg   = "#f5c2e7"
bold = true

[module.title]
fg     = "#cdd6f4"
bg     = "#1e1e2e"
border = "#313244"
bold   = false

[module.cpu]
fg = "#a6e3a1"

[module.memory]
fg = "#f9e2af"

[module.network]
fg = "#89dceb"

[module.battery]
fg = "#fab387"

[module.tray]
enabled   = true
icon_size = 18
padding_x = 8
gap       = 4

[icons]
brand        = "\ue732 Arch Btw"
cpu          = "\uF2DB"
memory       = "\uEFC5"
network      = "\U000F05A9"
volume       = "\uF028"
volume_muted = "\uF026"
battery      = "\U000F0079"
clock        = "\uF017"

```

## help me fix any bugs with PRs!
