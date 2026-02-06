pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io



Singleton {
  id: root

  property bool wifiEnabled: false

  // ssid, security, active, bars
  property var wifiStations: []
  property string lastWifiScanResult: ""

  property var pendingNmcliCommands: []
  property bool pendingNmcliScan: false

  property bool wifiScanning: false

  property var knownNetworks: []

  property bool connecting: false
  property bool disconnecting: false
  property int retryCount: 0
  property string connectError: ""
  property string connectingSsid: ""

  function disconnect(ssid) {
    if (connecting || disconnecting) return
    disconnecting = true
    disconnectProc.command = ["nmcli", "connection", "down", ssid]
    disconnectProc.running = true
  }

  function connect(ssid, password) {
    if (connecting || disconnecting) return
    connecting = true
    connectError = ""
    connectingSsid = ssid
    connectProc.command = ["nmcli", "device", "wifi", "connect", ssid, ...(password ? ["password", password] : [])]
    connectProc.running = true
  }

  function forget(ssid) {
    forgetProc.command = ["nmcli", "connection", "delete", ssid]
    forgetProc.running = true
  }

  function setWifiEnabled(on) {
    if (on == wifiEnabled)
      return;

    wifiEnabled = on;
    pendingNmcliCommands = [["nmcli", "radio", "wifi", on ? "on" : "off"], ...pendingNmcliCommands];
    pendingNmcliScan = true;

    wifiStations = [];
  }

  function refreshWifi() {
    if (knownNetworksProc.running || nmcliListProc.running)
      return;

    if (!wifiEnabled) {
      wifiStations = [];
      return;
    }

    knownNetworksProc.running = true;
    wifiScanning = true;
  }

  function splitEscaped(str, sep = ':', esc = '\\') {
    const out = [];
    let current = '';
    let escaped = false;

    for (const ch of str) {
      if (escaped) {
        current += ch;
        escaped = false;
      } else if (ch == esc)
        escaped = true;
      else if (ch == sep) {
        out.push(current);
        current = '';
      } else
        current += ch;
    }
    out.push(current);
    return out;
  }

  function stationFromSSID(ssid) {
    for (let st of wifiStations) {
      if (st.ssid == ssid)
        return st;
    }
    return null;
  }

  function sortStations(station, stations) {
    const sorted = [...stations].sort((a, b) => b.bars - a.bars);
    if (!station) return sorted;
    const filtered = sorted.filter(s => s.ssid !== station.ssid);
    return [station, ...filtered];
  }

  Process {
    id: updateNmcliProc
    running: false

    stdout: SplitParser {
      splitMarker: ""
      onRead: data => {
        ; // doesn't get called most of the time due to no stdout
      }
    }
  }

  Process {
    id: nmcliListProc
    running: false

    command: ["nmcli", "--terse", "--fields", "IN-USE,BSSID,SSID,MODE,CHAN,RATE,SIGNAL,BARS,SECURITY,FREQ", "device", "wifi", "list"]

    onExited: {
      if (root.wifiEnabled && root.wifiStations.length === 0 && root.retryCount < 7) {
        root.retryCount++
        retryScanTimer.restart()
      } else {
        root.retryCount = 0
        root.wifiScanning = false
      }
    }

    stdout: SplitParser {
      splitMarker: ""
      onRead: data => {
        root.wifiScanning = false;

        // FIXME: this will still change quite often due to signal. Maybe only compare the things we get.
        if (root.lastWifiScanResult == data)
          return;

        root.lastWifiScanResult = data;

        const lines = data.split("\n");
        root.wifiStations = [];
        for (let line of lines) {
          const lineParsed = root.splitEscaped(line);

          if (lineParsed.length < 8 || lineParsed[0].indexOf("IN-USE") != -1 || !lineParsed[2])
            continue;

          let s = {};

          // console.log(lineParsed)

          s.active = lineParsed[0] == "*";
          s.ssid = lineParsed[2];
          s.security = lineParsed[8];
          s.bars = 4 - (lineParsed[7].match(/\_/g) || []).length;
          s.bssid = lineParsed[1];
          s.points = 1;
          s.freq = Math.round(parseInt(lineParsed[9].substr(0, lineParsed[9].length - 3)) / 100.0) / 10.0
          s.known = root.knownNetworks.includes(s.ssid)

          if (root.stationFromSSID(s.ssid) != null) {
            for (let i = 0; i < root.wifiStations.length; ++i) {
              if (root.wifiStations[i].ssid == s.ssid) {
                root.wifiStations[i].points++;
                root.wifiStations[i].active = root.wifiStations[i].active || s.active;
                root.wifiStations[i].bars = Math.max(root.wifiStations[i].bars, s.bars);
                root.wifiStations[i].freq = Math.max(root.wifiStations[i].freq, s.freq);
                break;
              }
            }
            continue;
          }

          root.wifiStations = [s, ...root.wifiStations];
        }

        const activeStation = root.wifiStations.find(s => s.active) || null
        root.wifiStations = root.sortStations(activeStation, root.wifiStations)
      }
    }
  }

  Timer {
    id: nmcliListTimer
    running: root.wifiEnabled
    onTriggered: root.refreshWifi()
  }

  Timer {
    id: retryScanTimer
    interval: 1000
    onTriggered: root.refreshWifi()
  }

  Timer {
    id: updateNmcliTimer
    repeat: true
    running: root.pendingNmcliCommands.length > 0
    interval: 100

    onTriggered: {
      if (updateNmcliProc.running)
        return;

      updateNmcliProc.command = root.pendingNmcliCommands[0];
      updateNmcliProc.running = true;

      root.pendingNmcliCommands = root.pendingNmcliCommands.slice(1);

      if (root.pendingNmcliCommands.length == 0 && root.pendingNmcliScan) {
        root.pendingNmcliScan = false;
        root.refreshWifi();
      }
    }
  }

  Process {
    id: checkWifiEnabledState
    running: true
    command: ["nmcli", "radio", "wifi"]

    stdout: SplitParser {
      splitMarker: ""
      onRead: data => {
        root.wifiEnabled = data.indexOf("enabled") != -1;
      }
    }
  }

  Process {
    id: knownNetworksProc
    running: false
    command: ["nmcli", "--terse", "--fields", "NAME,TYPE", "connection", "show"]

    stdout: SplitParser {
      splitMarker: ""
      onRead: data => {
        const lines = data.split("\n")
        const networks = []
        for (const line of lines) {
          const parts = line.split(":")
          if (parts.length >= 2 && parts[1] === "802-11-wireless")
            networks.push(parts[0])
        }
        root.knownNetworks = networks
        nmcliListProc.running = true
      }
    }
  }

  Process {
    id: connectProc
    running: false

    stdout: SplitParser {
      splitMarker: ""
      onRead: data => {
        if (data.indexOf("successfully activated") !== -1) {
          root.connecting = false
          root.refreshWifi()
        }
      }
    }

    stderr: SplitParser {
      splitMarker: ""
      onRead: data => {
        console.log("wifi connect error: " + data)
        root.connectError = "Connection failed"
        deleteFailedProfileProc.command = ["nmcli", "connection", "delete", root.connectingSsid]
        deleteFailedProfileProc.running = true
        root.connecting = false
      }
    }
  }

  Process {
    id: deleteFailedProfileProc
    running: false

    stderr: SplitParser {
      splitMarker: ""
      onRead: data => {
        console.log("wifi delete failed profile error: " + data)
      }
    }
  }

  Process {
    id: disconnectProc
    running: false

    stdout: SplitParser {
      splitMarker: ""
      onRead: data => {
        if (data.indexOf("successfully deactivated") !== -1) {
          root.disconnecting = false
          root.refreshWifi()
        }
      }
    }

    stderr: SplitParser {
      splitMarker: ""
      onRead: data => {
        console.log("wifi disconnect error: " + data)
        root.disconnecting = false
      }
    }
  }

  Process {
    id: forgetProc
    running: false

    stdout: SplitParser {
      splitMarker: ""
      onRead: data => {
        root.refreshWifi()
      }
    }

    stderr: SplitParser {
      splitMarker: ""
      onRead: data => {
        console.log("wifi forget error: " + data)
      }
    }
  }
}
