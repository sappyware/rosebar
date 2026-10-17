pragma Singleton
import QtQuick
import "."

QtObject {
    readonly property var keys: ["bg","fg","border","muted","accent","accentFg",
                                 "urgent","cpu","memory","network","volume","battery"]

    readonly property var palettes: ({
        "catppuccin-mocha": ["#1e1e2e","#cdd6f4","#313244","#9399b2","#f5c2e7","#1e1e2e","#f38ba8","#a6e3a1","#f9e2af","#89dceb","#cba6f7","#fab387"],
        "catppuccin-latte": ["#eff1f5","#4c4f69","#ccd0da","#8c8fa1","#ea76cb","#eff1f5","#d20f39","#40a02b","#df8e1d","#04a5e5","#8839ef","#fe640b"],
        "nord":             ["#2e3440","#d8dee9","#3b4252","#7b88a1","#88c0d0","#2e3440","#bf616a","#a3be8c","#ebcb8b","#8fbcbb","#b48ead","#d08770"],
        "gruvbox":          ["#282828","#ebdbb2","#3c3836","#928374","#d79921","#282828","#cc241d","#b8bb26","#fabd2f","#83a598","#d3869b","#fe8019"],
        "tokyonight":       ["#1a1b26","#c0caf5","#292e42","#565f89","#7aa2f7","#1a1b26","#f7768e","#9ece6a","#e0af68","#7dcfff","#bb9af7","#ff9e64"],
        "rose-pine":        ["#191724","#e0def4","#26233a","#6e6a86","#ebbcba","#191724","#eb6f92","#9ccfd8","#f6c177","#31748f","#c4a7e7","#f6c177"],
        "dracula":          ["#282a36","#f8f8f2","#44475a","#6272a4","#bd93f9","#282a36","#ff5555","#50fa7b","#f1fa8c","#8be9fd","#ff79c6","#ffb86c"]
    })

    readonly property var raw: {
        var arr = palettes[Config.data.theme] || palettes["catppuccin-mocha"];
        var o = {};
        for (var i = 0; i < keys.length; i++) o[keys[i]] = arr[i];
        var uc = Config.data.colors || {};
        for (var k in uc) if (keys.indexOf(k) >= 0) o[k] = uc[k];
        return o;
    }

    readonly property color bg:       raw.bg
    readonly property color fg:       raw.fg
    readonly property color border:   raw.border
    readonly property color muted:    raw.muted
    readonly property color accent:   raw.accent
    readonly property color accentFg: raw.accentFg
    readonly property color urgent:   raw.urgent
    readonly property color cpu:      raw.cpu
    readonly property color memory:   raw.memory
    readonly property color network:  raw.network
    readonly property color volume:   raw.volume
    readonly property color battery:  raw.battery

    readonly property string fontFamily: Config.data.font.family
    readonly property int  fontSize:      Config.data.font.size
    readonly property bool fontItalic:    Config.data.font.italic
    readonly property int  fontWeight: {
        var w = Config.data.font.weight;
        if (w === "bold")   return Font.Bold;
        if (w === "normal") return Font.Normal;
        return parseInt(w) || Font.Normal;
    }
    readonly property real letterSpacing: Config.data.font.letterSpacing

    // ---- canonical row height for every pill -----------------------------
    property FontMetrics _fm: FontMetrics {
        id: _fm
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        font.weight: Theme.fontWeight
        font.italic: Theme.fontItalic
    }
    readonly property int rowHeight:
        Math.round(_fm.height) + Config.data.island.paddingY * 2

    function modStyle(name) {
        var base = { fg: fg, bg: "", border: "", bold: false, fontSize: 0 };
        if (name === "clock")  { base.fg = accentFg; base.bg = accent; base.border = accent; base.bold = true; }
        if (name === "brand")  { base.fg = accent; base.bold = true; }
        if (name === "title")  { base.fg = fg; }
        if (name === "cpu")    base.fg = cpu;
        if (name === "memory") base.fg = memory;
        if (name === "network")base.fg = network;
        if (name === "volume") base.fg = volume;
        if (name === "battery")base.fg = battery;

        var m = (Config.data.module || {})[name];
        if (m && typeof m === "object") {
            if (m.fg)        base.fg = m.fg;
            if (m.bg)        base.bg = m.bg;
            if (m.border)    base.border = m.border;
            if (m.bold)      base.bold = true;
            if (m.font_size) base.fontSize = m.font_size;
        }
        return base;
    }
}
