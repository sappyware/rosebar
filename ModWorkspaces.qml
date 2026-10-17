import QtQuick
import "."

Row {
    id: wsRow
    spacing: Config.data.style === "joined" ? 0 : Config.data.bar.workspaceGap

    // 0 (or missing) = show every configured tag; positive N caps the row.
    readonly property int visibleCount: {
        var c = Config.data.workspaces.count;
        if (typeof c !== "number" || c <= 0) return Config.data.tags;
        return Math.min(c, Config.data.tags);
    }

    Repeater {
        model: wsRow.visibleCount

        delegate: Rectangle {
            id: btn
            required property int index

            readonly property int  n:      index + 1
            readonly property bool occ:    Tags.isOccupied(n)
            readonly property bool act:    Tags.isActive(n)
            readonly property bool urg:    Tags.isUrgent(n)
            readonly property bool hov:    hover.hovered
            readonly property bool strip:  Config.data.style === "bar"
            readonly property bool joined: Config.data.style === "joined"

            readonly property string label:
                (Config.data.workspaces.labels[index] !== undefined)
                    ? Config.data.workspaces.labels[index]
                    : String(n)

            width:  lbl.implicitWidth  + Config.data.workspaces.paddingX * 2
            height: Theme.rowHeight

            color: urg ? Theme.urgent
                 : act ? Theme.accent
                 : hov ? Theme.border
                 :       (strip ? "transparent" : Theme.bg)
            radius: joined ? 0 : Config.data.workspaces.radius
            border.width: strip ? 0 : Config.data.island.borderWidth
            border.color: urg ? Theme.urgent
                        : act ? Theme.accent
                        :       (strip ? "transparent" : Theme.border)

            HoverHandler { id: hover }
            TapHandler   { onTapped: Tags.switchTo(btn.n) }

            Text {
                id: lbl
                anchors.centerIn: parent
                text: btn.label
                color: btn.urg ? Theme.accentFg
                     : btn.act ? Theme.accentFg
                     : btn.occ ? Theme.fg
                     :           Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.weight: btn.act ? Font.Bold : Theme.fontWeight
                font.italic: Theme.fontItalic
            }
        }
    }
}
