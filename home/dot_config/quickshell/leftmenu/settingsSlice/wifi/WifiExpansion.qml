import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Widgets

import "../../../config" as C
import "../../../commonwidgets" as CW
import "../../../state" as S

Rectangle {
  id: root

  property var lines: []
  property string ssid: ""
  property bool active: false

  property bool busy: S.WifiState.connecting || S.WifiState.disconnecting || S.WifiState.togglingWifi
  property bool known: false
  property bool forgetting: false
  property string security: ""
  property bool enteringPassword: false

  property bool needsPassword: !known && security !== "" && !active

  onKnownChanged: {
    if (!known) forgetting = false
    if (known) {
      enteringPassword = false
    }
  }

  onVisibleChanged: {
    if (!visible) {
      enteringPassword = false
    }
  }

  onEnteringPasswordChanged: {
    if (enteringPassword) S.WifiState.connectError = ""
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
      model: root.lines

      CW.StyledText {
        required property int index;
        text: root.lines[index]
      }
    }

    RowLayout {
      Layout.alignment: Qt.AlignRight
      Layout.bottomMargin: 12
      spacing: 6

      RowLayout {
        visible: !root.forgetting && !root.enteringPassword
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
            if (root.active)
              S.WifiState.disconnect(root.ssid)
            else if (root.needsPassword)
              root.enteringPassword = true
            else
              S.WifiState.connect(root.ssid)
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

      ColumnLayout {
        visible: root.enteringPassword
        spacing: 8

        RowLayout {
          visible: S.WifiState.connectError !== ""
          Layout.fillWidth: true

          CW.StyledText {
            text: S.WifiState.connectError
            color: C.Config.theme.error
          }

          Item { Layout.fillWidth: true }

          CW.FontIcon {
            text: "error"
            color: C.Config.theme.error
          }
        }

        Rectangle {
          Layout.fillWidth: true
          Layout.preferredHeight: 32
          color: C.Config.applySecondaryOpacity(C.Config.theme.surface_container)
          radius: 6

          TextField {
            id: passwordField
            anchors.fill: parent
            anchors.margins: 4
            focus: visible
            echoMode: TextInput.Password
            font.pointSize: C.Config.fontSize.normal
            color: C.Config.theme.on_surface
            background: Item {}
            placeholderText: "Password"
            placeholderTextColor: Qt.darker(C.Config.theme.on_surface, 1.5)

            Keys.onReturnPressed: {
              if (text.length > 0)
                S.WifiState.connect(root.ssid, text, autoconnectSwitch.checked)
            }
          }
        }

        RowLayout {
          spacing: 6

          CW.StyledSwitch {
            id: autoconnectSwitch
            checked: true
            implicitHeight: 14
            implicitWidth: 26
            switchHandlePadding: 2
            switchHandlePaddingUnchecked: 3
          }

          CW.StyledText {
            text: "Connect automatically"
          }
        }

        RowLayout {
          Layout.alignment: Qt.AlignRight
          spacing: 6

          WrapperMouseArea {
            id: cancelMa
            enabled: !root.busy
            hoverEnabled: true
            Layout.preferredWidth: 70
            Layout.preferredHeight: 30

            onClicked: {
              root.enteringPassword = false
            }

            Rectangle {
              anchors.fill: parent
              radius: 6
              opacity: root.busy ? 0.5 : 1.0
              color: C.Config.applySecondaryOpacity(cancelMa.containsMouse ? Qt.lighter(C.Config.theme.background, 1.5) : C.Config.theme.background)

              Behavior on color {
                ColorAnimation {
                  duration: 400
                  easing.type: Easing.BezierSpline
                  easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
                }
              }

              CW.StyledText {
                anchors.centerIn: parent
                text: "Cancel"
              }
            }
          }

          WrapperMouseArea {
            id: connectMa
            enabled: !root.busy && passwordField.text.length > 0
            hoverEnabled: true
            Layout.preferredWidth: 110
            Layout.preferredHeight: 30

            onClicked: S.WifiState.connect(root.ssid, passwordField.text, autoconnectSwitch.checked)

            Rectangle {
              anchors.fill: parent
              radius: 6
              opacity: (root.busy || passwordField.text.length === 0) ? 0.5 : 1.0
              color: C.Config.applySecondaryOpacity(connectMa.containsMouse ? Qt.lighter(C.Config.theme.background, 1.5) : C.Config.theme.background)

              Behavior on color {
                ColorAnimation {
                  duration: 400
                  easing.type: Easing.BezierSpline
                  easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
                }
              }

              CW.StyledText {
                anchors.centerIn: parent
                text: S.WifiState.connecting ? "Connecting..." : "Connect"
              }
            }
          }
        }
      }
    }
  }
}
