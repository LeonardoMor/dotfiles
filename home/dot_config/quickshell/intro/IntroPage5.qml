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
      text: "Updates"
      horizontalAlignment: Text.AlignHCenter
      font.pointSize: C.Config.fontSize.h2
      color: C.Config.theme.primary
    }

    CW.HorizontalLine {}

    Text {
      Layout.fillWidth: true
      text: "The Hyprland Desktop Experience is continuously maintained.\n\nWhen you want to update is always up to you,\nbut we can notify you when updates are available.\n\nThis notification will show up as a small bar in your right menu, if enabled,\nand it won't work when offline.\n\nNo telemetry is collected with the update check requests."
      horizontalAlignment: Text.AlignLeft
      font.pointSize: C.Config.fontSize.normal
      color: C.Config.theme.on_surface
      Layout.bottomMargin: 15
    }

    CW.ValueSwitch {
      Layout.fillWidth: true
      Layout.bottomMargin: 15
      label: "Enable automatic update checking"
      checked: C.Config.misc.autoUpdateCheck
      onToggled: C.Config.misc.autoUpdateCheck = checked
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
