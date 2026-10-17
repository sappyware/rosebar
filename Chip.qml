import QtQuick
import "."

Rectangle {
    id: chip

    property string text: ""
    property color  fgColor: Theme.fg
    property bool   bold: false
    property int    fontSize: 0
    property string bgOverride: ""
    property string borderOverride: ""
    property int    radiusOverride: -1

    readonly property bool strip:  Config.data.style === "bar"
    readonly property bool joined: Config.data.style === "joined"
    readonly property int  bw: strip ? 0 : Config.data.island.borderWidth
    readonly property int  r: radiusOverride >= 0
        ? radiusOverride
        : (joined ? 0 : Config.data.island.radius)

    color: bgOverride !== "" ? bgOverride
         : (strip ? "transparent" : Theme.bg)
    border.width: bw
    border.color: borderOverride !== "" ? borderOverride
                : (strip ? "transparent" : Theme.border)
    radius: r

    implicitWidth:  label.implicitWidth  + Config.data.island.paddingX * 2
    implicitHeight: Theme.rowHeight
    height:         Theme.rowHeight

    Text {
        id: label
        anchors.centerIn: parent
        text: chip.text
        color: chip.fgColor
        font.family: Theme.fontFamily
        font.pixelSize: chip.fontSize > 0 ? chip.fontSize : Theme.fontSize
        font.weight: chip.bold ? Font.Bold : Theme.fontWeight
        font.italic: Theme.fontItalic
        font.letterSpacing: Theme.letterSpacing
    }
}
