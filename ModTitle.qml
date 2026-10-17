import QtQuick
import "."

Rectangle {
    id: titleChip
    property string value: "desktop"

    readonly property var  st:    Theme.modStyle("title")
    readonly property bool strip: Config.data.style === "bar"
    readonly property int  r:     Config.data.style === "joined" ? 0 : Config.data.island.radius

    readonly property int maxTitleWidth:
        Math.round(Config.data.titleMaxChars * Theme.fontSize * 0.55)

    TextMetrics {
        id: tm
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        font.weight: Theme.fontWeight
        font.italic: Theme.fontItalic
        text: titleChip.value
    }
    readonly property int titleWidth: Math.min(Math.round(tm.advanceWidth),
                                               titleChip.maxTitleWidth)

    color: st.bg !== "" ? st.bg : (strip ? "transparent" : Theme.bg)
    border.width: strip ? 0 : Config.data.island.borderWidth
    border.color: st.border !== "" ? st.border : (strip ? "transparent" : Theme.border)
    radius: r

    implicitWidth:  titleChip.titleWidth + Config.data.island.paddingX * 2
    implicitHeight: Theme.rowHeight
    width:  implicitWidth
    height: implicitHeight

    Text {
        id: label
        anchors.centerIn: parent
        text: titleChip.value
        width: titleChip.titleWidth
        color: titleChip.st.fg
        font.family: Theme.fontFamily
        font.pixelSize: titleChip.st.fontSize > 0
            ? titleChip.st.fontSize : Theme.fontSize
        font.weight: titleChip.st.bold ? Font.Bold : Theme.fontWeight
        font.italic: Theme.fontItalic
        elide: Text.ElideRight
        maximumLineCount: 1
    }
}
