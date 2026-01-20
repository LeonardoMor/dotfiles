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
      text: "Configuring Hyprland"
      horizontalAlignment: Text.AlignHCenter
      font.pointSize: C.Config.fontSize.h2
      color: C.Config.theme.primary
    }

    CW.HorizontalLine {}

    Text {
      Layout.fillWidth: true
      text: "Most of your Hyprland config is managed by the Hyprland Desktop Experience itself, and will be overwritten on any update.\n\nIf you want to customize Hyprland options, you will need to do it in ~/.config/hypr/custom.d/.\nThose options will be left in-tact on updates, but might cause errors if an update changes some syntax.\nFor more info on configuration options, see the wiki at https://wiki.hypr.land"
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
