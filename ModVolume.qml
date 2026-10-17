import Quickshell.Services.Pipewire
import QtQuick
import "."

Item {
    id: volRoot

    readonly property var  sink:    Pipewire.defaultAudioSink
    readonly property bool hasSink: sink && sink.audio

    // Bind the default sink so .audio.muted / .audio.volume are writable.
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    readonly property string labelText: {
        if (!hasSink) return Config.data.icons.volume + "  --";
        if (sink.audio.muted) return Config.data.icons.volumeMuted + "  muted";
        return Config.data.icons.volume + "  " + Math.round(sink.audio.volume * 100) + "%";
    }

    implicitWidth:  chip.implicitWidth
    implicitHeight: Theme.rowHeight

    Chip { id: chip; text: volRoot.labelText; fgColor: Theme.volume }

    // Throttle touchpad scroll events so a single swipe isn't 20 steps.
    property bool _cooling: false
    Timer {
        id: wheelCooldown
        interval: 60
        onTriggered: volRoot._cooling = false
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        onWheel: wheel => {
            if (!volRoot.hasSink || volRoot._cooling) return;
            var step = Config.data.volumeStep / 100;
            var v = volRoot.sink.audio.volume;
            var next = v + (wheel.angleDelta.y > 0 ? step : -step);
            volRoot.sink.audio.volume = Math.max(0, Math.min(1.0, next));
            volRoot._cooling = true;
            wheelCooldown.restart();
        }
        onClicked: {
            if (volRoot.hasSink) volRoot.sink.audio.muted = !volRoot.sink.audio.muted;
        }
    }
}
