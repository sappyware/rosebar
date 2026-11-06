import "."
import QtQuick
import Quickshell.Services.Pipewire

Item {
    id: volRoot

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool hasSink: sink && sink.audio
    readonly property bool rolling: hasSink && !sink.audio.muted
    readonly property int percent: hasSink ? Math.round(sink.audio.volume * 100) : 0
    readonly property string labelText: {
        if (!hasSink)
            return Config.data.icons.volume + "  --";

        if (sink.audio.muted)
            return Config.data.icons.volumeMuted + "  muted";

        return Config.data.icons.volume;
    }
    property bool _cooling: false

    implicitWidth: chip.implicitWidth
    implicitHeight: Theme.rowHeight

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    Chip {
        id: chip

        text: volRoot.labelText
        fgColor: Theme.volume
        rollValue: volRoot.rolling ? volRoot.percent : -1
    }

    Timer {
        id: wheelCooldown

        interval: 60
        onTriggered: volRoot._cooling = false
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        onWheel: (wheel) => {
            if (!volRoot.hasSink || volRoot._cooling)
                return ;

            var step = Config.data.volumeStep / 100;
            var v = volRoot.sink.audio.volume;
            var next = v + (wheel.angleDelta.y > 0 ? step : -step);
            volRoot.sink.audio.volume = Math.max(0, Math.min(1, next));
            volRoot._cooling = true;
            wheelCooldown.restart();
        }
        onClicked: {
            if (volRoot.hasSink)
                volRoot.sink.audio.muted = !volRoot.sink.audio.muted;

        }
    }

}
