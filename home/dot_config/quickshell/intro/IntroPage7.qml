import "../commonwidgets" as CW
import "../commonwidgets" as CW
import "../config" as C
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

Item {
  id: root

  signal next

  implicitWidth: layout.width
  implicitHeight: layout.height

  ColumnLayout {
    id: layout

    Text {
      Layout.fillWidth: true
      text: "Thank you!"
      horizontalAlignment: Text.AlignHCenter
      font.pointSize: C.Config.fontSize.h2
      color: C.Config.theme.primary
    }

    CW.HorizontalLine {}

    Text {
      Layout.fillWidth: true
      text: "Thank you for trying out the Hyprland Desktop Experience.\nWe hope you enjoy your stay. :)"
      horizontalAlignment: Text.AlignLeft
      font.pointSize: C.Config.fontSize.normal
      color: C.Config.theme.on_surface
      Layout.bottomMargin: 15
    }

    CW.StyledButton {
      Layout.alignment: Qt.AlignRight
      label: "Finish"
      onClicked: {
        next();
      }
    }
  }
}
