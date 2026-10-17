pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import "."

QtObject {
    id: tags

    property int occupied: 0
    property int active:   0
    property int urgent:   0

    function isOccupied(i) { return (occupied & (1 << (i - 1))) !== 0; }
    function isActive(i)   { return (active   & (1 << (i - 1))) !== 0; }
    function isUrgent(i)   { return (urgent   & (1 << (i - 1))) !== 0; }

    function switchTo(n) {
        tags.active = 1 << (n - 1);
        dispatch.targetTag = n;
        dispatch.running = true;
    }

    property Process watchProc: Process {
        id: watchProc
        running: true
        command: ["mmsg", "watch", "all-tags"]
        stdout: SplitParser {
            onRead: line => {
                try {
                    var d = JSON.parse(line);
                    var occ = 0, act = 0, urg = 0;
                    var mons = d.all_tags || [];
                    for (var i = 0; i < mons.length; i++) {
                        var ts = mons[i].tags || [];
                        for (var j = 0; j < ts.length; j++) {
                            var t = ts[j];
                            var idx = t.index;
                            if (typeof idx !== "number") continue;
                            if (idx < 1 || idx > Config.data.tags) continue;
                            var bit = 1 << (idx - 1);
                            if ((t.client_count || 0) > 0) occ |= bit;
                            if (t.is_active)               act |= bit;
                            if (t.is_urgent)               urg |= bit;
                        }
                    }
                    tags.occupied = occ;
                    tags.active   = act;
                    tags.urgent   = urg;
                } catch (e) {}
            }
        }
    }

    property Process dispatch: Process {
        id: dispatch
        property int targetTag: 0
        command: ["mmsg", "dispatch", "view," + targetTag]
    }
}
