import "."
import QtQuick

Item {
    id: rn

    property int value: 0
    property string suffix: ""
    property color color: Theme.fg
    property string fontFamily: Theme.fontFamily
    property int pixelSize: Theme.fontSize
    property int weight: Theme.fontWeight
    property bool italic: Theme.fontItalic
    property real letterSpacing: Theme.letterSpacing
    property int maxDigits: 3
    readonly property real lineH: Math.ceil(fm.height)
    readonly property real digitW: Math.ceil(zero.implicitWidth)
    readonly property int v: Math.max(0, Math.min(Math.pow(10, maxDigits) - 1, Math.round(value)))
    readonly property int digitCount: String(v).length

    implicitWidth: row.implicitWidth
    implicitHeight: lineH

    FontMetrics {
        id: fm

        font.family: rn.fontFamily
        font.pixelSize: rn.pixelSize
        font.weight: rn.weight
        font.italic: rn.italic
    }

    Text {
        id: zero

        visible: false
        text: "0"
        font.family: rn.fontFamily
        font.pixelSize: rn.pixelSize
        font.weight: rn.weight
        font.italic: rn.italic
        font.letterSpacing: rn.letterSpacing
    }

    Row {
        id: row

        spacing: 0

        Repeater {
            model: rn.maxDigits

            delegate: Item {
                id: slot

                required property int index
                readonly property int s: rn.maxDigits - 1 - index
                readonly property bool on: s < rn.digitCount
                readonly property int digit: Math.floor(rn.v / Math.pow(10, s)) % 10
                property int target: 0
                property real pos: target
                property int last: -1
                property bool ready: false

                width: on ? rn.digitW : 0
                height: rn.lineH
                opacity: on ? 1 : 0
                clip: true
                onDigitChanged: {
                    if (!ready)
                        return ;

                    var d = ((digit - last) % 10 + 10) % 10;
                    if (d > 5)
                        d -= 10;

                    last = digit;
                    target += d;
                }
                Component.onCompleted: {
                    last = digit;
                    target = digit;
                    ready = true;
                }

                Repeater {
                    model: 3

                    delegate: Text {
                        required property int index
                        readonly property int n: Math.floor(slot.pos) - 1 + index
                        readonly property real off: n - slot.pos

                        width: rn.digitW
                        height: rn.lineH
                        y: off * rn.lineH
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: String(((n % 10) + 10) % 10)
                        color: rn.color
                        font.family: rn.fontFamily
                        font.pixelSize: rn.pixelSize
                        font.weight: rn.weight
                        font.italic: rn.italic
                        font.letterSpacing: rn.letterSpacing
                        opacity: Math.max(0, 1 - Math.abs(off) * 1.1)
                        scale: 1 - 0.22 * Math.min(1, Math.abs(off))
                    }

                }

                Behavior on width {
                    enabled: slot.ready

                    NumberAnimation {
                        duration: 260
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Theme.emphasized
                    }

                }

                Behavior on opacity {
                    enabled: slot.ready

                    NumberAnimation {
                        duration: 180
                    }

                }

                Behavior on pos {
                    enabled: slot.ready

                    NumberAnimation {
                        duration: Theme.springy ? 380 : 280
                        easing.type: Theme.springy ? Easing.OutBack : Easing.BezierSpline
                        easing.overshoot: 1.3
                        easing.bezierCurve: Theme.emphasized
                    }

                }

            }

        }

        Text {
            visible: rn.suffix !== ""
            height: rn.lineH
            verticalAlignment: Text.AlignVCenter
            text: rn.suffix
            color: rn.color
            font.family: rn.fontFamily
            font.pixelSize: rn.pixelSize
            font.weight: rn.weight
            font.italic: rn.italic
            font.letterSpacing: rn.letterSpacing
        }

    }

}
