# rosebar
A bar for people who like islands.


## installation

clone the repository and run the installer:

```bash
git clone https://github.com/sappyware/rosebar.git
cd rosebar
chmod +x install.sh
./install.sh
```

the installer copies the QML files into `~/.config/quickshell/rosebar/`. if files already exist there, it backs them up before replacing them.

## running

start rosebar with:

```bash
qs -c rosebar
```

to stop it, use:

```bash
qs -c rosebar kill
```
