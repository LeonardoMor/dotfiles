pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  property bool wifiEnabled: false
  property bool wifiScanning: false

  readonly property list<AccessPoint> networks: []
  readonly property AccessPoint active: networks.find(n => n.active) ?? null

  property var knownNetworks: []

  property bool connecting: false
  property bool disconnecting: false
  property bool togglingWifi: false
  property int retryCount: 0
  property string connectError: ''
  property string connectingSsid: ''
  property bool connectAutoconnect: true

  Component.onCompleted: {
    executeCommand(['radio', 'wifi'], result => {
      if (result.success) {
        root.wifiEnabled = result.output.indexOf('enabled') !== -1
        if (root.wifiEnabled)
          root.refreshWifi()
      }
    })
  }

  function clearNetworks() {
    for (let i = networks.length - 1; i >= 0; --i) {
      const network = networks[i]
      networks.splice(i, 1)
      network.destroy()
    }
  }

  function disconnect(ssid) {
    if (connecting || disconnecting || togglingWifi) return
    disconnecting = true
    executeCommand(['connection', 'down', ssid], result => {
      disconnecting = false
      if (result.success) {
        refreshWifi()
      } else if (result.error) {
        console.log('wifi disconnect error: ' + result.error)
      }
    })
  }

  function connect(ssid, password, autoconnect) {
    if (connecting || disconnecting || togglingWifi) return
    connecting = true
    connectError = ''
    connectingSsid = ssid
    connectAutoconnect = autoconnect !== false
    executeCommand(['device', 'wifi', 'connect', ssid, ...(password ? ['password', password] : [])], result => {
      connecting = false
      if (result.success) {
        if (!connectAutoconnect) {
          executeCommand(['connection', 'modify', connectingSsid, 'connection.autoconnect', 'no'], inner => {
            if (!inner.success && inner.error)
              console.log('wifi disable autoconnect error: ' + inner.error)
          })
        }
        refreshWifi()
      } else {
        connectError = 'Connection failed'
        executeCommand(['connection', 'delete', connectingSsid], inner => {
          if (!inner.success && inner.error)
            console.log('wifi delete failed profile error: ' + inner.error)
        })
      }
    })
  }

  function forget(ssid) {
    executeCommand(['connection', 'delete', ssid], result => {
      if (result.success) {
        refreshWifi()
      } else if (result.error) {
        console.log('wifi forget error: ' + result.error)
      }
    })
  }

  function setWifiEnabled(on) {
    if (on == wifiEnabled || togglingWifi)
      return

    togglingWifi = true
    wifiEnabled = on
    wifiScanning = on
    clearNetworks()
    executeCommand(['radio', 'wifi', on ? 'on' : 'off'], result => {
      togglingWifi = false
      if (!on || !result.success) {
        wifiScanning = false
        if (!result.success && result.error)
          console.log('wifi toggle error: ' + result.error)
        return
      }
      scanWifi()
    })
  }

  function refreshWifi() {
    if (wifiScanning)
      return

    if (!wifiEnabled) {
      clearNetworks()
      return
    }

    scanWifi()
  }

  function scanWifi() {
    wifiScanning = true
    executeCommand(['--terse', '--fields', 'NAME,TYPE', 'connection', 'show'], result => {
      if (result.success) {
        const lines = result.output.split('\n')
        const savedNetworks = []
        for (const line of lines) {
          const parts = splitEscaped(line)
          if (parts.length >= 2 && parts[1] === '802-11-wireless')
            savedNetworks.push(parts[0])
        }
        knownNetworks = savedNetworks
      } else {
        knownNetworks = []
      }

      executeCommand(['--terse', '--fields', 'IN-USE,BSSID,SSID,MODE,CHAN,RATE,SIGNAL,BARS,SECURITY,FREQ', 'device', 'wifi', 'list'], scanResult => {
        if (scanResult.success) {
          const parsed = parseNetworkOutput(scanResult.output)
          const deduped = deduplicateNetworks(parsed)
          updateNetworks(deduped)
        } else {
          updateNetworks([])
        }

        if (wifiEnabled && root.networks.length === 0 && retryCount < 7) {
          retryCount++
          retryScanTimer.restart()
        } else {
          retryCount = 0
          wifiScanning = false
        }
      })
    })
  }

  function splitEscaped(str, sep = ':', esc = '\\') {
    const out = []
    let current = ''
    let escaped = false

    for (const ch of str) {
      if (escaped) {
        current += ch
        escaped = false
      } else if (ch == esc) {
        escaped = true
      } else if (ch == sep) {
        out.push(current)
        current = ''
      } else {
        current += ch
      }
    }
    out.push(current)
    return out
  }

  function parseNetworkOutput(data) {
    if (!data || data.length === 0)
      return []

    const lines = data.split('\n')
    const parsed = []
    for (const line of lines) {
      const lineParsed = splitEscaped(line)

      if (lineParsed.length < 10 || lineParsed[0].indexOf('IN-USE') != -1 || !lineParsed[2])
        continue

      const signal = parseInt(lineParsed[6], 10)
      const freqMhz = parseInt(lineParsed[9], 10)
      const freqGhz = Math.round(((isNaN(freqMhz) ? 0 : freqMhz) / 1000) * 10) / 10

      parsed.push({
        active: lineParsed[0] == '*',
        ssid: lineParsed[2],
        security: lineParsed[8],
        strength: isNaN(signal) ? 0 : signal,
        bssid: lineParsed[1],
        frequency: freqGhz,
        known: knownNetworks.includes(lineParsed[2])
      })
    }
    return parsed
  }

  function deduplicateNetworks(networks) {
    if (!networks || networks.length === 0)
      return []

    const networkMap = new Map()
    for (const network of networks) {
      const existing = networkMap.get(network.ssid)
      if (!existing) {
        networkMap.set(network.ssid, network)
      } else if (network.active && !existing.active) {
        networkMap.set(network.ssid, network)
      } else if (!network.active && !existing.active && network.strength > existing.strength) {
        networkMap.set(network.ssid, network)
      }
    }

    return Array.from(networkMap.values())
  }

  function updateNetworks(newData) {
    const networkMap = new Map()
    for (const network of newData) {
      networkMap.set(network.ssid, network)
    }

    for (let i = networks.length - 1; i >= 0; --i) {
      const existing = networks[i]
      if (!networkMap.has(existing.ssid)) {
        networks.splice(i, 1)
        existing.destroy()
      }
    }

    for (const [ssid, network] of networkMap) {
      const existing = networks.find(n => n.ssid === ssid)
      if (existing) {
        existing.lastIpcObject = network
      } else {
        networks.push(apComp.createObject(root, { lastIpcObject: network }))
      }
    }
  }

  function executeCommand(args, callback) {
    const proc = commandProc.createObject(root)
    proc.command = ['nmcli', ...args]
    proc.callback = callback ?? null
    proc.running = true
  }

  Timer {
    id: nmcliListTimer
    running: root.wifiEnabled
    onTriggered: root.refreshWifi()
  }

  Timer {
    id: retryScanTimer
    interval: 1000
    onTriggered: root.scanWifi()
  }

  component CommandProcess: Process {
    id: proc
    property var callback: null

    stdout: StdioCollector { id: stdoutCollector }
    stderr: StdioCollector { id: stderrCollector }

    onExited: (exitCode) => {
      const result = {
        success: exitCode === 0,
        output: stdoutCollector.text ?? '',
        error: stderrCollector.text ?? '',
        exitCode: exitCode
      }
      if (proc.callback)
        proc.callback(result)
      proc.destroy()
    }
  }

  Component {
    id: commandProc
    CommandProcess {}
  }

  component AccessPoint: QtObject {
    required property var lastIpcObject
    readonly property string ssid: lastIpcObject.ssid
    readonly property string bssid: lastIpcObject.bssid
    readonly property int strength: lastIpcObject.strength
    readonly property real frequency: lastIpcObject.frequency
    readonly property bool active: lastIpcObject.active
    readonly property string security: lastIpcObject.security
    readonly property bool known: lastIpcObject.known
  }

  Component {
    id: apComp
    AccessPoint {}
  }
}
