import "."
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var modelData
    readonly property bool top: Config.data.position === "top"
    readonly property var b: Config.data.bar
    readonly property int mGap: Config.data.bar.moduleGap
    property QtObject titleState
    property Process titleWatch
    property SystemClock clock

    function pick(name) {
        switch (name) {
        case "media":
            return mediaComp;
        case "tray":
            return trayComp;
        case "brand":
            return brandComp;
        case "workspaces":
            return workspacesComp;
        case "title":
            return titleComp;
        case "cpu":
            return cpuComp;
        case "memory":
            return memComp;
        case "network":
            return netComp;
        case "volume":
            return volumeComp;
        case "brightness":
            return brightnessComp;
        case "battery":
            return batComp;
        case "clock":
            return clockComp;
        }
        console.warn("[rosebar] unknown module:", name);
        return null;
    }

    screen: modelData
    WlrLayershell.layer: {
        switch (Config.data.layer) {
        case "background":
            return WlrLayer.Background;
        case "bottom":
            return WlrLayer.Bottom;
        case "overlay":
            return WlrLayer.Overlay;
        default:
            return WlrLayer.Top;
        }
    }
    WlrLayershell.namespace: "rosebar"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusiveZone: Math.round(root.implicitHeight)
    color: "transparent"
    implicitHeight: barBg.implicitHeight + (top ? b.marginBottom : b.marginTop)

    anchors {
        top: top
        bottom: !top
        left: true
        right: true
    }

    margins {
        top: top ? b.marginTop : 0
        bottom: top ? b.marginBottom : b.marginTop
        left: b.marginLeft
        right: b.marginRight
    }

    Rectangle {
        id: barBg

        implicitHeight: content.implicitHeight + (Config.data.style === "bar" ? b.paddingY * 2 : 0)
        color: Config.data.style === "bar" ? Theme.barBg : "transparent"
        radius: b.radius
        border.width: Config.data.style === "bar" ? b.borderWidth : 0
        border.color: Theme.border

        anchors {
            left: parent.left
            right: parent.right
            top: root.top ? parent.top : undefined
            bottom: root.top ? undefined : parent.bottom
            topMargin: root.top ? 0 : b.marginTop
            bottomMargin: root.top ? b.marginBottom : 0
        }

        Item {
            id: content

            implicitHeight: Theme.rowHeight

            anchors {
                left: parent.left
                right: parent.right
                leftMargin: Config.data.style === "bar" ? b.paddingX : 0
                rightMargin: Config.data.style === "bar" ? b.paddingX : 0
                verticalCenter: parent.verticalCenter
            }

            Row {
                id: leftRow

                spacing: root.mGap

                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }

                Repeater {
                    model: Config.data.layout.left

                    delegate: Loader {
                        sourceComponent: root.pick(modelData)
                    }

                }

            }

            Row {
                id: rightRow

                spacing: root.mGap

                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }

                Repeater {
                    model: Config.data.layout.right

                    delegate: Loader {
                        sourceComponent: root.pick(modelData)
                    }

                }

            }

            Row {
                id: centerRow

                spacing: root.mGap

                anchors {
                    horizontalCenter: parent.horizontalCenter
                    verticalCenter: parent.verticalCenter
                }

                Repeater {
                    model: Config.data.layout.center

                    delegate: Loader {
                        sourceComponent: root.pick(modelData)
                    }

                }

            }

        }

    }

    Component {
        id: mediaComp

        ModMedia {
        }

    }

    Component {
        id: trayComp

        ModTray {
        }

    }

    Component {
        id: brandComp

        Chip {
            text: Config.data.icons.brand
            fgColor: Theme.modStyle("brand").fg
            bold: Theme.modStyle("brand").bold
        }

    }

    Component {
        id: workspacesComp

        ModWorkspaces {
        }

    }

    Component {
        id: titleComp

        ModTitle {
            value: titleState.text
        }

    }

    Component {
        id: cpuComp

        Chip {
            text: Config.data.icons.cpu + "  " + Sys.cpu + "%"
            fgColor: Theme.modStyle("cpu").fg
        }

    }

    Component {
        id: memComp

        Chip {
            text: Config.data.icons.memory + "  " + Sys.mem + "%"
            fgColor: Theme.modStyle("memory").fg
        }

    }

    Component {
        id: netComp

        Chip {
            text: Config.data.icons.network + "  " + Sys.net
            fgColor: Theme.modStyle("network").fg
        }

    }

    Component {
        id: volumeComp

        ModVolume {
        }

    }

    Component {
        id: brightnessComp

        ModBrightness {
        }

    }

    Component {
        id: batComp

        Chip {
            visible: Sys.hasBattery
            text: Sys.hasBattery ? Config.data.icons.battery + "  " + (Sys.batCharging ? "+" : "") + Sys.batPct + "%" : ""
            fgColor: Theme.modStyle("battery").fg
        }

    }

    Component {
        id: clockComp

        Chip {
            text: Config.data.icons.clock + "  " + Qt.formatDateTime(clock.date, Config.data.clockFormat)
            fgColor: Theme.modStyle("clock").fg
            bgOverride: Theme.modStyle("clock").bg
            borderOverride: Theme.modStyle("clock").border
            bold: Theme.modStyle("clock").bold
        }

    }

    titleState: QtObject {
        id: titleState

        property string text: "desktop"
    }

    titleWatch: Process {
        id: titleWatch

        running: true
        command: ["mmsg", "watch", "focusing-client"]

        stdout: SplitParser {
            onRead: (line) => {
                try {
                    var d = JSON.parse(line);
                    titleState.text = (d.title || d.appid || "desktop").trim().substring(0, 120);
                } catch (e) {
                }
            }
        }

    }

    clock: SystemClock {
        id: clock

        precision: SystemClock.Seconds
    }

}
