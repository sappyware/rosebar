# rosebar
A bar for people who like islands.


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

## help me fix any bugs with PRs!
