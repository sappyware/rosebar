import "."
import QtQuick

Rectangle {
    id: chip

    property string text: ""
    property color fgColor: Theme.fg
    property bool bold: false
    property int fontSize: 0
    property string bgOverride: ""
    property string borderOverride: ""
    property int radiusOverride: -1
    property int rollValue: -1
    property string rollSuffix: "%"
    readonly property bool strip: Config.data.style === "bar"
    readonly property bool joined: Config.data.style === "joined" && !Theme.md3
    readonly property int bw: strip ? 0 : Config.data.island.borderWidth
    readonly property int r: radiusOverride >= 0 ? radiusOverride : (joined ? 0 : Config.data.island.radius)
    readonly property var parts: Theme.md3 ? Theme.splitIcon(text) : ({
        "icon": "",
        "rest": text
    })
    readonly property int fs: fontSize > 0 ? fontSize : Theme.fontSize
    readonly property bool filled: bgOverride !== ""
    readonly property color textColor: (Theme.md3 && !chip.filled && chip.parts.icon !== "") ? Theme.fg : chip.fgColor

    color: bgOverride !== "" ? bgOverride : (strip ? "transparent" : Theme.bg)
    border.width: bw
    border.color: borderOverride !== "" ? borderOverride : (strip ? "transparent" : Theme.border)
    radius: r
    implicitWidth: row.implicitWidth + Config.data.island.paddingX * 2
    implicitHeight: Theme.rowHeight
    height: Theme.rowHeight

    Row {
        id: row

        anchors.centerIn: parent
        spacing: Math.round(chip.fs * 0.5)

        Text {
            visible: chip.parts.icon !== ""
            anchors.verticalCenter: parent.verticalCenter
            text: chip.parts.icon
            color: chip.fgColor
            font.family: Theme.iconFont
            font.pixelSize: Math.round(chip.fs * 1.15)
        }

        Text {
            id: label

            visible: chip.parts.rest !== ""
            anchors.verticalCenter: parent.verticalCenter
            text: chip.parts.rest
            color: chip.textColor
            font.family: Theme.fontFamily
            font.pixelSize: chip.fs
            font.weight: chip.bold ? Font.Bold : Theme.fontWeight
            font.italic: Theme.fontItalic
            font.letterSpacing: Theme.letterSpacing
        }

        RollNumber {
            visible: chip.rollValue >= 0
            anchors.verticalCenter: parent.verticalCenter
            value: Math.max(0, chip.rollValue)
            suffix: chip.rollSuffix
            color: chip.textColor
            pixelSize: chip.fs
            weight: chip.bold ? Font.Bold : Theme.fontWeight
        }

    }

    Rectangle {
        anchors.fill: parent
        radius: chip.radius
        color: chip.filled ? chip.fgColor : Theme.fg
        opacity: Theme.md3 && hh.hovered ? 0.08 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: 150
            }

        }

    }

    HoverHandler {
        id: hh

        enabled: Theme.md3
    }

    Behavior on color {
        enabled: Theme.md3

        ColorAnimation {
            duration: 200
        }

    }

}
