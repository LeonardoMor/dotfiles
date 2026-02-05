import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import QtQuick.Controls

import "../../config" as C
import "../../state" as S
import "../../commonwidgets" as CW
import "./wifi" as W

BaseListSection {
  id: root
  property string selectedStation: "[[VAXRY_WAS_HERE]]"

  property var orderedStations: {
    const stations = S.WifiState.wifiStations.filter(x => x.ssid != "")
    const selected = stations.find(s => s.bssid === selectedStation)
    if (!selected) return stations
    return S.WifiState.sortStations(selected, stations)
  }

  header: CW.ValueSwitch {
    Layout.fillWidth: true
    Layout.leftMargin: 5
    Layout.rightMargin: 5
    label: "Wifi"
    bold: true
    checked: S.WifiState.wifiEnabled
    onToggled: S.WifiState.setWifiEnabled(!S.WifiState.wifiEnabled)
  }

  model: orderedStations
  delegate: W.WifiStation {
    required property int index
    width: ListView.view.width
    station: orderedStations[index]
    onClicked: {
      if (selectedStation == orderedStations[index].bssid)
        selectedStation = "[[VAXRY_WAS_HERE]]";
      else
        selectedStation = orderedStations[index].bssid;
    }
    open: selectedStation == orderedStations[index].bssid
  }

  footerIcon: "refresh"
  onFooterClicked: S.WifiState.refreshWifi()

  placeholder: !S.WifiState.wifiEnabled ? "Wifi is disabled" : (S.WifiState.wifiScanning ? "Scanning..." : "No stations available")
}
