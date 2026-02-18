import "../../../commonwidgets" as CW
import "../../../config" as C
import "../../../state" as S
import "../shared"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Widgets

WrapperMouseArea {
  id: root

  property var station: {
    "ssid": "Vaxry was here",
    "security": "None",
    "strength": 75,
    "active": false,
    "bssid": "",
    "frequency": 0,
    "known": false
  }
  property bool open: false

  readonly property string signalLabel: {
    if (station.strength >= 75)
      return "Very Good"
    if (station.strength >= 50)
      return "Good"
    if (station.strength >= 25)
      return "Average"
    return "Poor"
  }

  hoverEnabled: true

  ColumnLayout {
    id: collayout1

    anchors.fill: parent

    spacing: -1

    DeviceElement {
      Layout.fillWidth: true
      label: root.station.ssid
      active: root.station.active
      additionalIcon: root.station.strength >= 75 ? "network_wifi" : (root.station.strength >= 50 ? "network_wifi_3_bar" : (root.station.strength >= 25 ? "network_wifi_2_bar" : "network_wifi_1_bar"))
      hovered: root.containsMouse
    }

    Item {
      Layout.preferredHeight: root.open ? 6 : -1

      Behavior on Layout.preferredHeight {
        NumberAnimation {
          duration: C.Globals.anim_NORMAL
          easing.type: Easing.BezierSpline
          easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
        }
      }
    }

    WifiExpansion {
      Layout.fillWidth: true
      lines: [root.station.ssid + ", " + root.station.bssid, "Freq: " + root.station.frequency + "GHz", "Security: " + root.station.security, "Signal: " + root.signalLabel]
      visible: opacity != 0
      opacity: root.open ? 1 : 0
      active: root.station.active
      ssid: root.station.ssid
      known: root.station.known
      security: root.station.security
      Layout.preferredHeight: root.open ? implicitHeight : 0

      Behavior on opacity {
        NumberAnimation {
          duration: C.Globals.anim_NORMAL
          easing.type: Easing.BezierSpline
          easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
        }
      }

      Behavior on Layout.preferredHeight {
        NumberAnimation {
          duration: C.Globals.anim_NORMAL
          easing.type: Easing.BezierSpline
          easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
        }
      }
    }
  }

  Behavior on implicitHeight {
    NumberAnimation {
      duration: 400
      easing.type: Easing.BezierSpline
      easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
    }
  }
}
