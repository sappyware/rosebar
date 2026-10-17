import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Services.SystemTray
import "."

Item {
    id: trayRoot

    readonly property var mcfg: (Config.data.module || {})["tray"] || {}
    readonly property bool enabled:   mcfg.enabled   !== false
    readonly property int  iconSize:  typeof mcfg.iconSize === "number" ? mcfg.iconSize : 18
    readonly property int  padX:      typeof mcfg.paddingX === "number" ? mcfg.paddingX : 8
    readonly property int  padY:      typeof mcfg.paddingY === "number" ? mcfg.paddingY : 4
    readonly property int  gap:       typeof mcfg.gap      === "number" ? mcfg.gap      : 4

    visible: enabled && trayRepeater.count > 0
    implicitWidth:  row.implicitWidth
    implicitHeight: Theme.rowHeight

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: trayRoot.gap

        Repeater {
            id: trayRepeater
            model: SystemTray.items

            delegate: Rectangle {
                id: pill
                required property var modelData

                width:  trayRoot.iconSize + trayRoot.padX * 2
                height: Theme.rowHeight
                radius: Config.data.island.radius
                color:  hover.hovered ? Theme.border
                     : (Config.data.style === "bar" ? "transparent" : Theme.bg)
                border.width: Config.data.style === "bar" ? 0 : Config.data.island.borderWidth
                border.color: Theme.border

                HoverHandler { id: hover }

                Image {
                    anchors.centerIn: parent
                    width:  trayRoot.iconSize
                    height: trayRoot.iconSize
                    source: {
                        var raw = pill.modelData.icon || "";
                        if (raw.indexOf("?path=") !== -1) {
                            var parts = raw.split("?path=");
                            var name = parts[0];
                            var path = parts[1];
                            var file = name.slice(name.lastIndexOf("/") + 1);
                            return "file://" + path + "/" + file;
                        }
                        return raw;
                    }
                    sourceSize.width:  trayRoot.iconSize
                    sourceSize.height: trayRoot.iconSize
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    smooth: true
                }

                ToolTip {
                    visible: hover.hovered &&
                             (pill.modelData.tooltipTitle || pill.modelData.title || "") !== ""
                    text: {
                        var t = pill.modelData.tooltipTitle || pill.modelData.title || "";
                        var d = pill.modelData.tooltipDescription || "";
                        return d ? (t + "\n" + d) : t;
                    }
                    delay: 400
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                    hoverEnabled: true
                    z: 10   // make sure we're on top of the Image

                    function logClick(what, extra) {
                        console.log("[tray] " + what + " on",
                                    pill.modelData.id || pill.modelData.title || "?",
                                    extra || "");
                    }

                  onClicked: mouse => {
    var item = pill.modelData;
    logClick("click button=" + mouse.button,
             "hasMenu=" + item.hasMenu +
             " onlyMenu=" + item.onlyMenu);
    try {
        var win = pill.QsWindow.window;

        // Map MouseArea-local coords to window coords.
        // The menu opens at the bottom-left of the pill.
        var pos = pill.mapToItem(null, 0, pill.height);

        if (mouse.button === Qt.LeftButton) {
            if (item.hasMenu) {
                item.display(win, pos.x, pos.y);
            } else {
                item.activate();
            }
        } else if (mouse.button === Qt.MiddleButton) {
            if (item.hasMenu) {
                item.secondaryActivate();
            } else {
                item.activate();
            }
        } else if (mouse.button === Qt.RightButton) {
            if (item.hasMenu) {
                item.display(win, pos.x, pos.y);
            }
        }
    } catch (e) {
        console.warn("[tray] click handler error:", e);
    }
}

                    onWheel: wheel => {
                        try {
                            pill.modelData.scroll(wheel.angleDelta.y, false);
                        } catch (e) {
                            console.warn("[tray] scroll error:", e);
                        }
                    }
                }
            }
        }
    }
}