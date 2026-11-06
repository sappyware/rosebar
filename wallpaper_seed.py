"""Rosebar helper. args: [wallpaper path] [wallpaper command] [last key]
stdout: line 1 = "path|mtime" key; line 2 = seed hex (only when the key changed)."""

import colorsys, os, re, shutil, subprocess, sys


def sh(cmd):
    try:
        return subprocess.run(
            cmd, shell=True, capture_output=True, text=True, timeout=3
        ).stdout.strip()
    except Exception:
        return ""


def detect():
    for q in ("awww", "swww"):
        if shutil.which(q):
            m = re.search(r"image:\s*(\S.*)", sh(q + " query"))
            if m:
                return m.group(1).strip()

    pid = sh("pgrep -n -x swaybg")
    if pid.isdigit():
        try:
            args = (
                open("/proc/%s/cmdline" % pid, "rb")
                .read()
                .decode(errors="ignore")
                .split("\0")
            )
            for i, a in enumerate(args[:-1]):
                if a in ("-i", "--image"):
                    return args[i + 1]
        except Exception:
            pass
    return ""


def pixels(path, n=64):
    try:
        from PIL import Image

        im = Image.open(path).convert("RGB")
        im.thumbnail((n, n))
        return list(
            im.get_flattened_data()
            if hasattr(im, "get_flattened_data")
            else im.getdata()
        )
    except ImportError:
        pass
    except Exception:
        return []
    try:
        import gi

        gi.require_version("GdkPixbuf", "2.0")
        from gi.repository import GdkPixbuf

        pb = GdkPixbuf.Pixbuf.new_from_file_at_scale(path, n, n, True)
        d, rs, ch = pb.get_pixels(), pb.get_rowstride(), pb.get_n_channels()
        return [
            tuple(d[y * rs + x * ch : y * rs + x * ch + 3])
            for y in range(pb.get_height())
            for x in range(pb.get_width())
        ]
    except Exception:
        return []


def seed_from(px):
    bins = [[0.0, 0.0, 0.0, 0.0] for _ in range(36)]
    for r, g, b in px:
        h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
        if v < 0.2 or s < 0.15:
            continue
        w = s * s * (0.4 + v)
        k = bins[int(h * 36) % 36]
        k[0] += w
        k[1] += r * w
        k[2] += g * w
        k[3] += b * w
    best = max(bins, key=lambda k: k[0])
    if best[0] <= 0:
        return "#4285F4"
    return "#%02x%02x%02x" % tuple(int(best[i] / best[0]) for i in (1, 2, 3))


def main():
    cfg_path, cmd, last = (sys.argv[1:4] + ["", "", ""])[:3]
    path = cfg_path or (sh(cmd) if cmd else "") or detect()
    path = os.path.expanduser(path.strip())
    if not path or not os.path.isfile(path):
        return
    key = "%s|%d" % (path, int(os.path.getmtime(path)))
    print(key)
    if key == last:
        return
    px = pixels(path)
    print(seed_from(px) if px else "")


main()
