import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import "."

Item {
    id: mediaRoot

    readonly property int artSize:    Config.data.media?.artSize    ?? 28
    readonly property int barCount:   Config.data.media?.bars       ?? 12
    readonly property int barWidth:   Config.data.media?.barWidth   ?? 2
    readonly property int barGap:     Config.data.media?.barGap     ?? 2
    readonly property int maxTitleLen:Config.data.media?.maxTitleLen?? 40
    readonly property bool showVis:   Config.data.media?.visualizer ?? true
    readonly property bool showArt:   Config.data.media?.coverArt   ?? true

    readonly property var activePlayer: {
        var players = Mpris.players ? Mpris.players.values : [];
        if (!players || players.length === 0) return null;
        for (var i = 0; i < players.length; i++)
            if (players[i].playbackState === MprisPlaybackState.Playing)
                return players[i];
        return players[0];
    }

    readonly property bool hasPlayer:  activePlayer !== null
    readonly property bool isPlaying:  hasPlayer &&
                                       activePlayer.playbackState === MprisPlaybackState.Playing

    readonly property string artistText: {
        if (!hasPlayer) return "";
        var p = activePlayer;
        if (p.trackArtists && p.trackArtists.length > 0)
            return p.trackArtists.join(", ");
        return p.trackArtist || "";
    }

    readonly property string titleText: {
        if (!hasPlayer) return "";
        return activePlayer.trackTitle || "Unknown Title";
    }

    readonly property string displayText: {
        if (!hasPlayer) return "";
        var a = artistText, t = titleText;
        var s = a ? (a + "  ·  " + t) : t;
        if (s.length > maxTitleLen) s = s.substring(0, maxTitleLen - 1) + "…";
        return s;
    }

    readonly property string artUrl: hasPlayer ? (activePlayer.trackArtUrl || "") : ""

    visible: hasPlayer && (displayText !== "" || artUrl !== "")
    implicitWidth:  row.implicitWidth  + Config.data.island.paddingX * 2
    implicitHeight: Theme.rowHeight

    Rectangle {
        id: bg
        anchors.fill: parent
        color:        Config.data.style === "bar" ? "transparent" : Theme.bg
        border.width: Config.data.style === "bar" ? 0 : Config.data.island.borderWidth
        border.color: Theme.border
        radius:       Config.data.style === "joined" ? 0 : Config.data.island.radius

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 8

            Item {
                width:  mediaRoot.showArt ? mediaRoot.artSize : 0
                height: mediaRoot.showArt ? mediaRoot.artSize : 0
                visible: mediaRoot.showArt && mediaRoot.artUrl !== ""
                clip: true

                Image {
                    anchors.fill: parent
                    source: mediaRoot.artUrl
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                    smooth: true
                    visible: status === Image.Ready
                }
            }

            Text {
                id: label
                anchors.verticalCenter: parent.verticalCenter
                text: mediaRoot.displayText
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.weight: Theme.fontWeight
                font.italic: Theme.fontItalic
                elide: Text.ElideRight
                maximumLineCount: 1
                width: Math.min(implicitWidth, mediaRoot.maxTitleLen * Theme.fontSize * 0.55)
            }

            Item {
                id: visContainer
                anchors.verticalCenter: parent.verticalCenter
                visible: mediaRoot.showVis && mediaRoot.isPlaying

                // Bars grow inside this box and never affect the outer Row's size.
                readonly property int maxBarH:
                    Math.max(4, Theme.rowHeight - Config.data.island.paddingY * 2)
                width: mediaRoot.barCount * mediaRoot.barWidth
                       + Math.max(0, mediaRoot.barCount - 1) * mediaRoot.barGap
                height: maxBarH

                Repeater {
                    model: mediaRoot.barCount
                    delegate: Rectangle {
                        required property int index
                        readonly property int raw: visRoot.bars[index] || 0
                        width:  mediaRoot.barWidth
                        height: Math.max(2, Math.round(raw / 100 * visContainer.maxBarH))
                        x: index * (mediaRoot.barWidth + mediaRoot.barGap)
                        y: visContainer.height - height
                        radius: width / 2
                        color:  Theme.accent
                        Behavior on height {
                            NumberAnimation { duration: 80; easing.type: Easing.OutQuad }
                        }
                    }
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        hoverEnabled: true
        onClicked: mouse => {
            if (!mediaRoot.hasPlayer) return;
            var p = mediaRoot.activePlayer;
            if (mouse.button === Qt.LeftButton)        p.togglePlaying();
            else if (mouse.button === Qt.MiddleButton) p.next();
            else if (mouse.button === Qt.RightButton)  p.previous();
        }
        onWheel: wheel => {
            if (!mediaRoot.hasPlayer) return;
            var p = mediaRoot.activePlayer;
            if (wheel.angleDelta.y > 0) p.previous();
            else                        p.next();
        }
    }

    QtObject {
        id: visRoot
        property var bars: Array(mediaRoot.barCount).fill(0)
    }

    property Process cavaWriter: Process {
        id: cavaWriter
        running: true
        command: ["bash", "-c",
            "mkdir -p /tmp/qs-cava && cat > /tmp/qs-cava/rosebar.ini <<'CFG'\n" +
            "[general]\n" +
            "framerate = 60\n" +
            "bars = " + mediaRoot.barCount + "\n" +
            "[input]\n" +
            "method = pipewire\n" +
            "source = auto\n" +
            "[smoothing]\n" +
            "noise_reduction = 77\n" +
            "monstercat = 1\n" +
            "[output]\n" +
            "method = raw\n" +
            "raw_target = /dev/stdout\n" +
            "data_format = ascii\n" +
            "ascii_max_range = 100\n" +
            "bar_delimiter = 59\n" +
            "CFG\n"
        ]
    }

    property Process cavaProc: Process {
        id: cavaProc
        running: false
        command: ["sh", "-c", "sleep 0.3; exec cava -p /tmp/qs-cava/rosebar.ini"]
        stdout: SplitParser {
            onRead: line => {
                var parts = line.trim().replace(/;$/, "").split(";");
                if (parts.length >= mediaRoot.barCount) {
                    visRoot.bars = parts
                        .slice(0, mediaRoot.barCount)
                        .map(v => parseInt(v, 10) || 0);
                }
            }
        }
        onExited: cavaProc.running = true
    }

    Component.onCompleted: {
        cavaWriter.onExited.connect(() => { cavaProc.running = true; });
    }
}
