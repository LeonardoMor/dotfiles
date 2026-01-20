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
      text: "Welcome to the Hyprland Desktop Experience!"
      horizontalAlignment: Text.AlignHCenter
      font.pointSize: C.Config.fontSize.h2
      color: C.Config.theme.primary
    }

    CW.HorizontalLine {}

    Text {
      Layout.fillWidth: true
      text: "Thank you for installing the Hyprland Desktop Experience.\nLet us guide you through a very brief setup, then you'll be free to explore."
      horizontalAlignment: Text.AlignHCenter
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
