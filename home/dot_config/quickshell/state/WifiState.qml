pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

import "../config" as C

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

  function disconnect(ssid) {
    if (connecting || disconnecting) return
    disconnecting = true
    disconnectProc.command = ["nmcli", "connection", "down", ssid]
    disconnectProc.running = true
  }

  function connect(ssid) {
    if (connecting || disconnecting) return
    connecting = true
    connectProc.command = ["nmcli", "device", "wifi", "connect", ssid]
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
      if (wifiEnabled && wifiStations.length === 0 && retryCount < 7) {
        retryCount++
        retryScanTimer.restart()
      } else {
        retryCount = 0
        wifiScanning = false
      }
    }

    stdout: SplitParser {
      splitMarker: ""
      onRead: data => {
        wifiScanning = false;

        // FIXME: this will still change quite often due to signal. Maybe only compare the things we get.
        if (lastWifiScanResult == data)
          return;

        lastWifiScanResult = data;

        const lines = data.split("\n");
        wifiStations = [];
        for (let line of lines) {
          const lineParsed = splitEscaped(line);

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
          s.known = knownNetworks.includes(s.ssid)

          if (stationFromSSID(s.ssid) != null) {
            for (let i = 0; i < wifiStations.length; ++i) {
              if (wifiStations[i].ssid == s.ssid) {
                wifiStations[i].points++;
                wifiStations[i].active = wifiStations[i].active || s.active;
                wifiStations[i].bars = Math.max(wifiStations[i].bars, s.bars);
                wifiStations[i].freq = Math.max(wifiStations[i].freq, s.freq);
                break;
              }
            }
            continue;
          }

          wifiStations = [s, ...wifiStations];
        }

        const activeStation = wifiStations.find(s => s.active) || null
        wifiStations = sortStations(activeStation, wifiStations)
      }
    }
  }

  Timer {
    id: nmcliListTimer
    running: wifiEnabled
    onTriggered: refreshWifi()
  }

  Timer {
    id: retryScanTimer
    interval: 1000
    onTriggered: refreshWifi()
  }

  Timer {
    id: updateNmcliTimer
    repeat: true
    running: pendingNmcliCommands.length > 0
    interval: 100

    onTriggered: {
      if (updateNmcliProc.running)
        return;

      updateNmcliProc.command = pendingNmcliCommands[0];
      updateNmcliProc.running = true;

      pendingNmcliCommands = pendingNmcliCommands.slice(1);

      if (pendingNmcliCommands.length == 0 && pendingNmcliScan) {
        pendingNmcliScan = false;
        refreshWifi();
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
        wifiEnabled = data.indexOf("enabled") != -1;
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
        knownNetworks = networks
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
          connecting = false
          refreshWifi()
        }
      }
    }

    stderr: SplitParser {
      splitMarker: ""
      onRead: data => {
        console.log("wifi connect error: " + data)
        connecting = false
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
          disconnecting = false
          refreshWifi()
        }
      }
    }

    stderr: SplitParser {
      splitMarker: ""
      onRead: data => {
        console.log("wifi disconnect error: " + data)
        disconnecting = false
      }
    }
  }

  Process {
    id: forgetProc
    running: false

    stdout: SplitParser {
      splitMarker: ""
      onRead: data => {
        refreshWifi()
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
