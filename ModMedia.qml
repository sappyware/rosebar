
import QtQuick
import QtQuick.Effects
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

    
    readonly property bool strip: Config.data.style === "bar"
    readonly property int  islandRadius:
        (Config.data.style === "joined" && !Theme.md3) ? 0 : Config.data.island.radius
    readonly property int  padX: Config.data.island.paddingX
    readonly property int  rowGap: 8

    
    readonly property bool want: hasPlayer && (displayText !== "" || artUrl !== "")

    
    property string curText: displayText
    property string curArt:  artUrl
    
    property int dir: 1

    readonly property string trackKey: titleText + "|" + artistText + "|" + artUrl

    
    Text {
        id: meas
        visible: false
        text: mediaRoot.curText
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        font.weight: Theme.fontWeight
        font.italic: Theme.fontItalic
    }

    readonly property int maxTextW: Math.round(maxTitleLen * Theme.fontSize * 0.55)
    readonly property int textW:    Math.min(Math.ceil(meas.implicitWidth) + 2, maxTextW)
    readonly property bool artOn:   showArt && artUrl !== ""
    readonly property bool visOn:   showVis && isPlaying
    readonly property int visFullW: barCount * barWidth + Math.max(0, barCount - 1) * barGap

    readonly property int contentW: {
        var w = 0, n = 0;
        if (artOn)       { w += artSize;  n++; }
        if (textW > 0)   { w += textW;    n++; }
        if (visOn)       { w += visFullW; n++; }
        return w + Math.max(0, n - 1) * rowGap;
    }

    
    visible: want || width > 0.5
    opacity: want ? 1 : 0
    implicitWidth:  contentW + padX * 2
    implicitHeight: Theme.rowHeight
    width:  want ? implicitWidth : 0
    height: implicitHeight

    Behavior on opacity { NumberAnimation { duration: 180 } }
    Behavior on width {
        enabled: Theme.md3
        NumberAnimation {
            duration: Theme.springy ? 450 : 300
            easing.type: Theme.springy ? Easing.OutBack : Easing.BezierSpline
            easing.overshoot: 1.2
            easing.bezierCurve: Theme.emphasized
        }
    }

    
    onDisplayTextChanged: {
        if (displayText === "") return;
        if (Theme.md3) textSwap.restart(); else curText = displayText;
    }

    SequentialAnimation {
        id: textSwap
        ParallelAnimation {
            NumberAnimation { target: label; property: "opacity"; to: 0; duration: 90
                              easing.type: Easing.BezierSpline; easing.bezierCurve: [0.3, 0, 0.8, 0.15, 1, 1] }
            NumberAnimation { target: label; property: "dy"; to: -8; duration: 90
                              easing.type: Easing.BezierSpline; easing.bezierCurve: [0.3, 0, 0.8, 0.15, 1, 1] }
        }
        ScriptAction { script: { mediaRoot.curText = mediaRoot.displayText; label.dy = 8; } }
        ParallelAnimation {
            NumberAnimation { target: label; property: "opacity"; to: 1; duration: 260
                              easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized }
            NumberAnimation { target: label; property: "dy"; to: 0; duration: 320
                              easing.type: Easing.BezierSpline; easing.bezierCurve: [0.05, 0.7, 0.1, 1, 1, 1] }
        }
    }

    
    onTrackKeyChanged: {
        if (!hasPlayer) return;
        if (Theme.md3) artSwap.restart(); else curArt = artUrl;
    }

    SequentialAnimation {
        id: artSwap
        ParallelAnimation {
            NumberAnimation { target: artBox; property: "scale"; to: 0.55; duration: 110
                              easing.type: Easing.BezierSpline; easing.bezierCurve: [0.3, 0, 0.8, 0.15, 1, 1] }
            NumberAnimation { target: artBox; property: "opacity"; to: 0; duration: 110
                              easing.type: Easing.BezierSpline; easing.bezierCurve: [0.3, 0, 0.8, 0.15, 1, 1] }
            NumberAnimation { target: artBox; property: "rotation"; to: -16 * mediaRoot.dir; duration: 110
                              easing.type: Easing.BezierSpline; easing.bezierCurve: [0.3, 0, 0.8, 0.15, 1, 1] }
        }
        ScriptAction { script: { mediaRoot.curArt = mediaRoot.artUrl; artBox.rotation = 16 * mediaRoot.dir; } }
        ParallelAnimation {
            NumberAnimation { target: artBox; property: "scale"; to: 1; duration: Theme.springy ? 480 : 300
                              easing.type: Theme.springy ? Easing.OutBack : Easing.BezierSpline
                              easing.overshoot: 2.0; easing.bezierCurve: Theme.emphasized }
            NumberAnimation { target: artBox; property: "opacity"; to: 1; duration: 220
                              easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized }
            NumberAnimation { target: artBox; property: "rotation"; to: 0; duration: Theme.springy ? 520 : 320
                              easing.type: Theme.springy ? Easing.OutBack : Easing.BezierSpline
                              easing.overshoot: 1.6; easing.bezierCurve: Theme.emphasized }
        }
    }

    
    Rectangle {
        id: bg
        anchors.fill: parent
        color:        strip ? "transparent" : Theme.bg
        border.width: strip ? 0 : Config.data.island.borderWidth
        border.color: Theme.border
        radius:       mediaRoot.islandRadius

        
        scale: ma.pressed ? 0.95 : 1.0
        Behavior on scale {
            enabled: Theme.md3
            NumberAnimation {
                duration: Theme.springy ? 380 : 200
                easing.type: Theme.springy ? Easing.OutBack : Easing.BezierSpline
                easing.overshoot: 2.2
                easing.bezierCurve: Theme.emphasized
            }
        }
        Behavior on color { enabled: Theme.md3; ColorAnimation { duration: 200 } }

        Row {
            id: row
            anchors.left: parent.left
            anchors.leftMargin: mediaRoot.padX
            anchors.verticalCenter: parent.verticalCenter
            spacing: mediaRoot.rowGap

            
            Item {
                id: artBox
                width:  mediaRoot.artSize
                height: mediaRoot.artSize
                visible: mediaRoot.artOn
                anchors.verticalCenter: parent.verticalCenter

                
                
                readonly property real fullR:   Math.min(mediaRoot.islandRadius, width / 2)
                readonly property real pausedR: Math.min(fullR, width * 0.3)
                property real artRadius: mediaRoot.isPlaying ? fullR : pausedR
                Behavior on artRadius {
                    enabled: Theme.md3
                    NumberAnimation { duration: 280; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized }
                }

                
                Item {
                    id: playFx
                    anchors.fill: parent
                    scale: mediaRoot.isPlaying ? 1.0 : 0.88
                    Behavior on scale {
                        enabled: Theme.md3
                        NumberAnimation {
                            duration: Theme.springy ? 450 : 300
                            easing.type: Theme.springy ? Easing.OutBack : Easing.BezierSpline
                            easing.overshoot: 2.0
                            easing.bezierCurve: Theme.emphasized
                        }
                    }

                    
                    Item {
                        id: maskItem
                        anchors.fill: parent
                        visible: false
                        layer.enabled: true
                        Rectangle {
                            anchors.fill: parent
                            radius: artBox.artRadius
                            color: "black"
                        }
                    }

                    Image {
                        id: cover
                        anchors.fill: parent
                        source: mediaRoot.curArt
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                        smooth: true
                        sourceSize.width:  mediaRoot.artSize * 2
                        sourceSize.height: mediaRoot.artSize * 2
                        opacity: status === Image.Ready ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 150 } }

                        layer.enabled: true
                        layer.effect: MultiEffect {
                            maskEnabled: true
                            maskSource: maskItem
                            maskThresholdMin: 0.5
                            maskSpreadAtMin: 1.0
                            saturation: mediaRoot.isPlaying ? 0.0 : -0.75
                            brightness: mediaRoot.isPlaying ? 0.0 : -0.25
                            Behavior on saturation { NumberAnimation { duration: 250 } }
                            Behavior on brightness { NumberAnimation { duration: 250 } }
                        }
                    }

                    
                    Text {
                        anchors.centerIn: parent
                        text: "\uF04B"
                        color: "white"
                        font.family: Theme.iconFont
                        font.pixelSize: Math.round(mediaRoot.artSize * 0.42)
                        opacity: mediaRoot.isPlaying ? 0 : 0.95
                        scale:   mediaRoot.isPlaying ? 0.3 : 1.0
                        visible: opacity > 0.01
                        Behavior on opacity { NumberAnimation { duration: 160 } }
                        Behavior on scale {
                            NumberAnimation {
                                duration: Theme.springy ? 420 : 260
                                easing.type: Theme.springy ? Easing.OutBack : Easing.BezierSpline
                                easing.overshoot: 2.5
                                easing.bezierCurve: Theme.emphasized
                            }
                        }
                    }
                }
            }

            
            Item {
                id: textClip
                anchors.verticalCenter: parent.verticalCenter
                width:  mediaRoot.textW
                height: Theme.rowHeight
                clip: true

                Text {
                    id: label
                    property real dy: 0
                    anchors.verticalCenter: parent.verticalCenter
                    transform: Translate { y: label.dy }
                    text: mediaRoot.curText
                    width: mediaRoot.textW
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    font.weight: Theme.fontWeight
                    font.italic: Theme.fontItalic
                    font.letterSpacing: Theme.letterSpacing
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    
                    opacity: 1
                }
                
                Rectangle {
                    anchors.fill: parent
                    color: bg.color === "transparent" ? Theme.barBg : bg.color
                    opacity: mediaRoot.isPlaying ? 0 : 0.4
                    Behavior on opacity { NumberAnimation { duration: 250 } }
                }
            }

            
            Item {
                id: visContainer
                anchors.verticalCenter: parent.verticalCenter
                visible: opacity > 0.01 || mediaRoot.visOn
                opacity: mediaRoot.visOn ? 1 : 0
                scale:   mediaRoot.visOn ? 1 : 0.6
                transformOrigin: Item.Left
                Behavior on opacity { NumberAnimation { duration: 200 } }
                Behavior on scale {
                    enabled: Theme.md3
                    NumberAnimation {
                        duration: Theme.springy ? 450 : 300
                        easing.type: Theme.springy ? Easing.OutBack : Easing.BezierSpline
                        easing.overshoot: 1.8
                        easing.bezierCurve: Theme.emphasized
                    }
                }

                
                readonly property int maxBarH:
                    Math.max(4, Theme.rowHeight - Config.data.island.paddingY * 2)
                width: mediaRoot.visOn ? mediaRoot.visFullW : 0
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

        
        Rectangle {
            anchors.fill: parent
            radius: bg.radius
            color: Theme.fg
            opacity: Theme.md3 && ma.containsMouse ? (ma.pressed ? 0.12 : 0.08) : 0
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        hoverEnabled: true
        onClicked: mouse => {
            if (!mediaRoot.hasPlayer) return;
            var p = mediaRoot.activePlayer;
            if (mouse.button === Qt.LeftButton)        p.togglePlaying();
            else if (mouse.button === Qt.MiddleButton) { mediaRoot.dir = 1;  p.next(); }
            else if (mouse.button === Qt.RightButton)  { mediaRoot.dir = -1; p.previous(); }
        }
        onWheel: wheel => {
            if (!mediaRoot.hasPlayer) return;
            var p = mediaRoot.activePlayer;
            if (wheel.angleDelta.y > 0) { mediaRoot.dir = -1; p.previous(); }
            else                        { mediaRoot.dir = 1;  p.next(); }
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
