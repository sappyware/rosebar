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
[font]
family = 'Iosevka NF'
fallback = ["Symbols Nerd Font Mono", "Noto Sans Symbols 2", "monospace"]
size = 20
weight = "bold"
italic = false
letter_spacing = 0

[bar]
margin_top    = 12
margin_bottom = 6


[workspaces]
count = 5

[media]
artSize     = 28
bars        = 12
barWidth    = 2
barGap      = 2
maxTitleLen = 40
visualizer  = true
coverArt    = true
enabled     = true

[layout]
left   = ["brand", "workspaces", "tray"]
center = ["media",  "title"]
right  = ["cpu", "memory", "network", "volume", "battery", "clock"]
```

## help me fix any bugs with PRs!
