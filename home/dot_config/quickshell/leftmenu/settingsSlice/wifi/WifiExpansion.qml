import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets

import "../../../config" as C
import "../../../commonwidgets" as CW
import "../../../state" as S

Rectangle {
  id: root

  property var lines: []
  property string ssid: ""
  property bool active: false

  property bool busy: S.WifiState.connecting || S.WifiState.disconnecting
  property bool known: false
  property bool forgetting: false

  onKnownChanged: {
    if (!known) forgetting = false
  }

  color: active ? Qt.darker(C.Config.theme.primary, 1.8) : C.Config.applySecondaryOpacity(Qt.lighter(C.Config.theme.surface_container, 1.8))
  radius: 6

  implicitHeight: cl.implicitHeight

  ColumnLayout {
    id: cl

    anchors {
      top: parent.top
      left: parent.left
      right: parent.right
      margins: 6
    }

    Repeater {
      model: lines

      CW.StyledText {
        required property int index;
        text: lines[index]
      }
    }

    RowLayout {
      Layout.alignment: Qt.AlignRight
      Layout.bottomMargin: 12
      spacing: 6

      RowLayout {
        visible: !root.forgetting
        spacing: 6

        WrapperMouseArea {
          id: forgetMa

          visible: root.known
          enabled: !root.busy
          hoverEnabled: true

          Layout.preferredWidth: 70
          Layout.preferredHeight: 30

          onClicked: root.forgetting = true

          Rectangle {
            anchors.fill: parent
            radius: 6
            opacity: root.busy ? 0.5 : 1.0
            color: C.Config.applySecondaryOpacity(forgetMa.containsMouse ? Qt.lighter(C.Config.theme.background, 1.5) : C.Config.theme.background)

            Behavior on color {
              ColorAnimation {
                duration: 400
                easing.type: Easing.BezierSpline
                easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
              }
            }

            CW.StyledText {
              anchors.centerIn: parent
              text: "Forget"
            }
          }
        }

        WrapperMouseArea {
          id: ma

          enabled: !root.busy
          hoverEnabled: true

          Layout.preferredWidth: 110
          Layout.preferredHeight: 30

          onClicked: {
            if (active)
              S.WifiState.disconnect(root.ssid);
            else
              S.WifiState.connect(root.ssid);
          }

          Rectangle {
            anchors.fill: parent
            radius: 6
            opacity: root.busy ? 0.5 : 1.0
            color: C.Config.applySecondaryOpacity(ma.containsMouse ? Qt.lighter(C.Config.theme.background, 1.5) : C.Config.theme.background)

            Behavior on color {
              ColorAnimation {
                duration: 400
                easing.type: Easing.BezierSpline
                easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
              }
            }

            CW.StyledText {
              anchors.centerIn: parent
              text: {
                if (S.WifiState.connecting) return "Connecting..."
                if (S.WifiState.disconnecting) return "Disconnecting..."
                return root.active ? "Disconnect" : "Connect"
              }
            }
          }
        }
      }

      RowLayout {
        visible: root.forgetting
        spacing: 6

        CW.StyledText {
          text: "Forget?"
        }

        WrapperMouseArea {
          id: yesMa

          hoverEnabled: true
          Layout.preferredWidth: 50
          Layout.preferredHeight: 30

          onClicked: S.WifiState.forget(root.ssid)

          Rectangle {
            anchors.fill: parent
            radius: 6
            color: C.Config.applySecondaryOpacity(yesMa.containsMouse ? Qt.lighter(C.Config.theme.background, 1.5) : C.Config.theme.background)

            Behavior on color {
              ColorAnimation {
                duration: 400
                easing.type: Easing.BezierSpline
                easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
              }
            }

            CW.StyledText {
              anchors.centerIn: parent
              text: "Yes"
            }
          }
        }

        WrapperMouseArea {
          id: noMa

          hoverEnabled: true
          Layout.preferredWidth: 50
          Layout.preferredHeight: 30

          onClicked: root.forgetting = false

          Rectangle {
            anchors.fill: parent
            radius: 6
            color: C.Config.applySecondaryOpacity(noMa.containsMouse ? Qt.lighter(C.Config.theme.background, 1.5) : C.Config.theme.background)

            Behavior on color {
              ColorAnimation {
                duration: 400
                easing.type: Easing.BezierSpline
                easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
              }
            }

            CW.StyledText {
              anchors.centerIn: parent
              text: "No"
            }
          }
        }
      }
    }
  }
}
