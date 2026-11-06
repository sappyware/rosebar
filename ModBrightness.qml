import "."
import QtQuick
import Quickshell.Io

Item {
    id: briRoot

    property int percent: -1
    readonly property bool hasBacklight: percent >= 0
    property bool _cooling: false

    visible: hasBacklight
    implicitWidth: chip.implicitWidth
    implicitHeight: Theme.rowHeight

    Chip {
        id: chip

        text: Config.data.icons.brightness
        fgColor: Theme.brightness
        rollValue: briRoot.percent
    }

    Process {
        id: readProc

        command: ["sh", "-c", "brightnessctl -m -c backlight 2>/dev/null | head -n1 | cut -d, -f4 | tr -d '%'"]

        stdout: StdioCollector {
            onStreamFinished: {
                var v = parseInt(text.trim(), 10);
                briRoot.percent = isNaN(v) ? -1 : v;
            }
        }

    }

    Process {
        id: setProc

        property string arg: ""

        command: ["brightnessctl", "-c", "backlight", "set", arg]
        onExited: readProc.running = true
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!readProc.running)
                readProc.running = true;

        }
    }

    Timer {
        id: wheelCooldown

        interval: 60
        onTriggered: briRoot._cooling = false
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: (wheel) => {
            if (!briRoot.hasBacklight || briRoot._cooling || setProc.running)
                return ;

            var step = Config.data.brightnessStep;
            var up = wheel.angleDelta.y > 0;
            var next = Math.max(1, Math.min(100, briRoot.percent + (up ? step : -step)));
            setProc.arg = next + "%";
            setProc.running = true;
            briRoot.percent = next;
            briRoot._cooling = true;
            wheelCooldown.restart();
        }
    }

}
