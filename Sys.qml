pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import QtQuick
import "."

QtObject {
    id: sys

    property int cpu: 0
    property int mem: 0
    property string net: "offline"

    readonly property var  batDev: UPower.displayDevice
    readonly property bool hasBattery: batDev && batDev.ready && batDev.isLaptopBattery !== false
    readonly property int  batPct: hasBattery ? Math.round(batDev.percentage * 100) : 0
    readonly property bool batCharging: hasBattery && batDev.state === UPowerDeviceState.Charging

    property var _lastStat: null

    function _parseStat(text) {
        var lines = text.split("\n");

        var cpuLine = lines[0].split(/\s+/);
        var f = [];
        for (var i = 1; i < cpuLine.length; i++) f.push(Number(cpuLine[i]) || 0);
        var idle = f[3] + (f[4] || 0);
        var total = 0; for (var j = 0; j < f.length; j++) total += f[j];
        if (sys._lastStat) {
            var dt = total - sys._lastStat.total;
            var di = idle  - sys._lastStat.idle;
            sys.cpu = dt > 0 ? Math.round(100 * (dt - di) / dt) : 0;
        }
        sys._lastStat = { total: total, idle: idle };

        var info = {};
        for (var k = 0; k < lines.length; k++) {
            var m = lines[k].match(/^(\w+):\s+(\d+)/);
            if (m) info[m[1]] = Number(m[2]);
        }
        var memTotal = info.MemTotal || 0;
        var avail    = info.MemAvailable !== undefined ? info.MemAvailable : (info.MemFree || 0);
        sys.mem = memTotal > 0 ? Math.round((memTotal - avail) * 100 / memTotal) : 0;
    }

    property Process statProc: Process {
        id: statProc
        command: ["sh", "-c", "cat /proc/stat; echo ---; cat /proc/meminfo"]
        stdout: StdioCollector { onStreamFinished: sys._parseStat(text) }
    }

    property Process netProc: Process {
        id: netProc
        command: ["sh", "-c", "ip -o -4 route show default 2>/dev/null | awk '{print $5; exit}'"]
        stdout: StdioCollector { onStreamFinished: sys.net = text.trim() || "offline" }
    }

    property Timer timer: Timer {
        id: timer
        interval: Config.data.pollMs
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            statProc.running = true;
            netProc.running  = true;
        }
    }
}
