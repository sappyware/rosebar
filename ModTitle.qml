import "."
import QtQuick

Rectangle {
    id: titleChip

    property string value: "desktop"
    readonly property var st: Theme.modStyle("title")
    readonly property bool strip: Config.data.style === "bar"
    readonly property int r: (Config.data.style === "joined" && !Theme.md3) ? 0 : Config.data.island.radius
    readonly property int fs: st.fontSize > 0 ? st.fontSize : Theme.fontSize
    readonly property int maxTitleWidth: Math.round(Config.data.titleMaxChars * titleChip.fs * 0.55)
    property string shown: value
    readonly property int titleWidth: Math.min(Math.ceil(meas.implicitWidth) + 2, maxTitleWidth)

    color: st.bg !== "" ? st.bg : (strip ? "transparent" : Theme.bg)
    border.width: strip ? 0 : Config.data.island.borderWidth
    border.color: st.border !== "" ? st.border : (strip ? "transparent" : Theme.border)
    radius: r
    implicitWidth: titleChip.titleWidth + Config.data.island.paddingX * 2
    implicitHeight: Theme.rowHeight
    width: implicitWidth
    height: implicitHeight
    onValueChanged: {
        if (Theme.md3)
            swap.restart();
        else
            shown = value;
    }

    Text {
        id: meas

        visible: false
        text: titleChip.value
        font: label.font
    }

    SequentialAnimation {
        id: swap

        ParallelAnimation {
            NumberAnimation {
                target: label
                property: "opacity"
                to: 0
                duration: 90
                easing.type: Easing.BezierSpline
                easing.bezierCurve: [0.3, 0, 0.8, 0.15, 1, 1]
            }

            NumberAnimation {
                target: label
                property: "dy"
                to: -8
                duration: 90
                easing.type: Easing.BezierSpline
                easing.bezierCurve: [0.3, 0, 0.8, 0.15, 1, 1]
            }

        }

        ScriptAction {
            script: {
                titleChip.shown = titleChip.value;
                label.dy = 8;
            }
        }

        ParallelAnimation {
            NumberAnimation {
                target: label
                property: "opacity"
                to: 1
                duration: 260
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.emphasized
            }

            NumberAnimation {
                target: label
                property: "dy"
                to: 0
                duration: 320
                easing.type: Easing.BezierSpline
                easing.bezierCurve: [0.05, 0.7, 0.1, 1, 1, 1]
            }

        }

    }

    Item {
        anchors.fill: parent
        clip: true

        Text {
            id: label

            property real dy: 0

            anchors.centerIn: parent
            anchors.verticalCenterOffset: dy
            text: titleChip.shown
            width: Math.min(implicitWidth, titleChip.maxTitleWidth)
            color: titleChip.st.fg
            font.family: Theme.fontFamily
            font.pixelSize: titleChip.fs
            font.weight: titleChip.st.bold ? Font.Bold : Theme.fontWeight
            font.italic: Theme.fontItalic
            font.letterSpacing: Theme.letterSpacing
            elide: Text.ElideRight
            maximumLineCount: 1
        }

    }

    Behavior on color {
        enabled: Theme.md3

        ColorAnimation {
            duration: 200
        }

    }

    Behavior on width {
        enabled: Theme.md3

        NumberAnimation {
            duration: Theme.springy ? 450 : 300
            easing.type: Theme.springy ? Easing.OutBack : Easing.BezierSpline
            easing.overshoot: 1.2
            easing.bezierCurve: Theme.emphasized
        }

    }

}
