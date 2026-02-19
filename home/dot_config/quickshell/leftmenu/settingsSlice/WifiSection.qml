import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets

import "../../config" as C
import "../../state" as S
import "../../commonwidgets" as CW
import "./wifi" as W

BaseListSection {
  id: root
  property string selectedStation: ''

  header: CW.ValueSwitch {
    Layout.fillWidth: true
    Layout.leftMargin: 5
    Layout.rightMargin: 5
    label: "Wifi"
    bold: true
    checked: S.WifiState.wifiEnabled
    onToggled: {
      if (S.WifiState.togglingWifi) {
        checked = Qt.binding(() => S.WifiState.wifiEnabled)
        return
      }
      S.WifiState.setWifiEnabled(!S.WifiState.wifiEnabled)
    }
  }

  model: ScriptModel {
    values: [...S.WifiState.networks].filter(n => n.ssid != '').sort((a, b) => {
      if (a.active !== b.active)
        return b.active - a.active
      return b.strength - a.strength
    })
  }
  delegate: W.WifiStation {
    width: ListView.view.width
    station: modelData
    onClicked: {
      if (S.WifiState.connecting || S.WifiState.disconnecting || S.WifiState.togglingWifi) return
      if (root.selectedStation == modelData.ssid)
        root.selectedStation = ''
      else
        root.selectedStation = modelData.ssid
    }
    open: root.selectedStation == modelData.ssid
  }

  footerIcon: "refresh"
  onFooterClicked: S.WifiState.refreshWifi()

  placeholder: !S.WifiState.wifiEnabled ? "Wifi is disabled" : (S.WifiState.wifiScanning ? "Scanning..." : "No stations available")
}
