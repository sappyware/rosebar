import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import "."

PanelWindow {
    id: root

    readonly property bool top: Config.data.position === "top"
    readonly property var  b:   Config.data.bar
    readonly property int  mGap: Config.data.bar.moduleGap

    WlrLayershell.layer: {
        switch (Config.data.layer) {
            case "background": return WlrLayer.Background;
            case "bottom":     return WlrLayer.Bottom;
            case "overlay":    return WlrLayer.Overlay;
            default:           return WlrLayer.Top;
        }
    }
    WlrLayershell.namespace: "rosebar"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors { top: top; bottom: !top; left: true; right: true }
    margins {
        top:    top  ? b.marginTop    : 0
        bottom: top  ? b.marginBottom : b.marginTop
        left:   b.marginLeft
        right:  b.marginRight
    }

    // Explicit zone so MangoWM actually reserves space (auto doesn't work reliably).
    exclusiveZone: Math.round(root.implicitHeight)

    color: "transparent"
    implicitHeight: barBg.implicitHeight + (top ? b.marginBottom : b.marginTop)

    Rectangle {
        id: barBg
        anchors {
            left: parent.left; right: parent.right
            top: root.top ? parent.top : undefined
            bottom: root.top ? undefined : parent.bottom
            topMargin: root.top ? 0 : b.marginTop
            bottomMargin: root.top ? b.marginBottom : 0
        }
        implicitHeight: content.implicitHeight
                        + (Config.data.style === "bar" ? b.paddingY * 2 : 0)
        color: Config.data.style === "bar" ? Theme.bg : "transparent"
        radius: b.radius
        border.width: Config.data.style === "bar" ? b.borderWidth : 0
        border.color: Theme.border

        Item {
            id: content
            anchors {
                left: parent.left; right: parent.right
                leftMargin:  Config.data.style === "bar" ? b.paddingX : 0
                rightMargin: Config.data.style === "bar" ? b.paddingX : 0
                verticalCenter: parent.verticalCenter
            }
            implicitHeight: Theme.rowHeight

            Row {
                id: leftRow
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                spacing: root.mGap
                Repeater {
                    model: Config.data.layout.left
                    delegate: Loader { sourceComponent: root.pick(modelData) }
                }
            }
            Row {
                id: rightRow
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                spacing: root.mGap
                Repeater {
                    model: Config.data.layout.right
                    delegate: Loader { sourceComponent: root.pick(modelData) }
                }
            }
            Row {
                id: centerRow
                anchors { horizontalCenter: parent.horizontalCenter; verticalCenter: parent.verticalCenter }
                spacing: root.mGap
                Repeater {
                    model: Config.data.layout.center
                    delegate: Loader { sourceComponent: root.pick(modelData) }
                }
            }
        }
    }

    function pick(name) {
        switch (name) {
            case "media":      return mediaComp;
            case "tray":       return trayComp;
            case "brand":      return brandComp;
            case "workspaces": return workspacesComp;
            case "title":      return titleComp;
            case "cpu":        return cpuComp;
            case "memory":     return memComp;
            case "network":    return netComp;
            case "volume":     return volumeComp;
            case "battery":    return batComp;
            case "clock":      return clockComp;
        }
        console.warn("[rosebar] unknown module:", name);
        return null;
    }

    Component { id: mediaComp; ModMedia {} }
    Component { id: trayComp; ModTray {} }
    Component { id: brandComp; Chip {
        text: Config.data.icons.brand
        fgColor: Theme.modStyle("brand").fg
        bold: Theme.modStyle("brand").bold
    }}
    Component { id: workspacesComp; ModWorkspaces {} }
    Component { id: titleComp; ModTitle { value: titleState.text } }
    Component { id: cpuComp; Chip {
        text: Config.data.icons.cpu + "  " + Sys.cpu + "%"
        fgColor: Theme.modStyle("cpu").fg
    }}
    Component { id: memComp; Chip {
        text: Config.data.icons.memory + "  " + Sys.mem + "%"
        fgColor: Theme.modStyle("memory").fg
    }}
    Component { id: netComp; Chip {
        text: Config.data.icons.network + "  " + Sys.net
        fgColor: Theme.modStyle("network").fg
    }}
    Component { id: volumeComp; ModVolume {} }
    Component { id: batComp; Chip {
        visible: Sys.hasBattery
        text: Sys.hasBattery
              ? Config.data.icons.battery + "  " + (Sys.batCharging ? "+" : "") + Sys.batPct + "%"
              : ""
        fgColor: Theme.modStyle("battery").fg
    }}
    Component { id: clockComp; Chip {
        text: Config.data.icons.clock + "  " + Qt.formatDateTime(clock.date, Config.data.clockFormat)
        fgColor: Theme.modStyle("clock").fg
        bgOverride: Theme.modStyle("clock").bg
        borderOverride: Theme.modStyle("clock").border
        bold: Theme.modStyle("clock").bold
    }}

    property QtObject titleState: QtObject {
        id: titleState
        property string text: "desktop"
    }

    property Process titleWatch: Process {
        id: titleWatch
        running: true
        command: ["mmsg", "watch", "focusing-client"]
        stdout: SplitParser {
            onRead: line => {
                try {
                    var d = JSON.parse(line);
                    titleState.text =
                        (d.title || d.appid || "desktop").trim().substring(0, 120);
                } catch (e) {}
            }
        }
    }

    property SystemClock clock: SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }
}
