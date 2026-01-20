import "../commonwidgets" as CW
import "../config" as C
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

Item {
  id: root

  signal next

  implicitWidth: layout.width
  implicitHeight: layout.height

  ColumnLayout {
    id: layout

    Text {
      Layout.fillWidth: true
      text: "First things first"
      horizontalAlignment: Text.AlignHCenter
      font.pointSize: C.Config.fontSize.h2
      color: C.Config.theme.primary
    }

    CW.HorizontalLine {}

    Text {
      Layout.fillWidth: true
      text: "On the top bar, you have two menus, the left (home) and right (side) one."
      horizontalAlignment: Text.AlignLeft
      font.pointSize: C.Config.fontSize.normal
      color: C.Config.theme.on_surface
      Layout.bottomMargin: 15
    }

    Text {
      Layout.fillWidth: true
      text: "Left Menu"
      horizontalAlignment: Text.AlignLeft
      font.pointSize: C.Config.fontSize.h2
      color: C.Config.theme.on_surface
      Layout.bottomMargin: 0
    }

    Text {
      Layout.fillWidth: true
      text: "The left menu contains the current media playback, Wifi, Bluetooth,\nBrightness and Volume controls, and the system tray."
      horizontalAlignment: Text.AlignLeft
      font.pointSize: C.Config.fontSize.normal
      color: C.Config.theme.on_surface
      Layout.bottomMargin: 15
    }

    Text {
      Layout.fillWidth: true
      text: "Right Menu"
      horizontalAlignment: Text.AlignLeft
      font.pointSize: C.Config.fontSize.h2
      color: C.Config.theme.on_surface
      Layout.bottomMargin: 0
    }

    Text {
      Layout.fillWidth: true
      text: "The right menu contains the notification center, system statistics and DE settings.\nIt also contains a button to show the default keybinds."
      horizontalAlignment: Text.AlignLeft
      font.pointSize: C.Config.fontSize.normal
      color: C.Config.theme.on_surface
      Layout.bottomMargin: 15
    }

    CW.StyledButton {
      Layout.alignment: Qt.AlignRight
      label: "Next"
      onClicked: {
        next();
      }
    }
  }
}
