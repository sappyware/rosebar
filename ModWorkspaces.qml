import "."
import QtQuick

Row {
    id: wsRow

    readonly property int visibleCount: {
        var c = Config.data.workspaces.count;
        if (typeof c !== "number" || c <= 0)
            return Config.data.tags;

        return Math.min(c, Config.data.tags);
    }

    spacing: (Config.data.style === "joined" && !Theme.md3) ? 0 : Config.data.bar.workspaceGap

    Repeater {
        model: wsRow.visibleCount

        delegate: Rectangle {
            id: btn

            required property int index
            readonly property int n: index + 1
            readonly property bool occ: Tags.isOccupied(n)
            readonly property bool act: Tags.isActive(n)
            readonly property bool urg: Tags.isUrgent(n)
            readonly property bool hov: hover.hovered
            readonly property bool md: Theme.md3
            readonly property bool strip: Config.data.style === "bar"
            readonly property bool joined: Config.data.style === "joined" && !md
            readonly property color base: strip ? "transparent" : Theme.bg
            readonly property string label: (Config.data.workspaces.labels[index] !== undefined) ? Config.data.workspaces.labels[index] : String(n)
            readonly property real grow: (md && act) ? (Config.data.md3.activeGrow || 0) : 0

            width: lbl.implicitWidth + Config.data.workspaces.paddingX * 2 + grow
            height: Theme.rowHeight
            color: urg ? (md ? Theme.r.errorContainer : Theme.urgent) : act ? (md ? Theme.r.secondaryContainer : Theme.accent) : md ? (hov ? Theme.layered(base, Theme.fg, tap.pressed ? 0.12 : 0.08) : base) : hov ? Theme.border : (strip ? "transparent" : Theme.bg)
            radius: md ? (tap.pressed ? 8 : (act ? Math.round(height * 0.32) : height / 2)) : (joined ? 0 : Config.data.workspaces.radius)
            border.width: strip ? 0 : Config.data.island.borderWidth
            border.color: urg ? Theme.urgent : act ? Theme.accent : (strip ? "transparent" : Theme.border)

            HoverHandler {
                id: hover
            }

            TapHandler {
                id: tap

                onTapped: Tags.switchTo(btn.n)
            }

            Text {
                id: lbl

                anchors.centerIn: parent
                text: btn.label
                color: btn.urg ? (btn.md ? Theme.r.onErrorContainer : Theme.accentFg) : btn.act ? (btn.md ? Theme.r.onSecondaryContainer : Theme.accentFg) : btn.occ ? Theme.fg : Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.weight: btn.act ? Font.Bold : Theme.fontWeight
                font.italic: Theme.fontItalic
            }

            Behavior on width {
                enabled: btn.md

                NumberAnimation {
                    duration: Theme.springy ? 450 : 300
                    easing.type: Theme.springy ? Easing.OutBack : Easing.BezierSpline
                    easing.overshoot: 1.5
                    easing.bezierCurve: Theme.emphasized
                }

            }

            Behavior on radius {
                enabled: btn.md

                NumberAnimation {
                    duration: 250
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.emphasized
                }

            }

            Behavior on color {
                enabled: btn.md

                ColorAnimation {
                    duration: 150
                }

            }

        }

    }

}
