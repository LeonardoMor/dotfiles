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
      text: "Update channel"
      horizontalAlignment: Text.AlignHCenter
      font.pointSize: C.Config.fontSize.h2
      color: C.Config.theme.primary
    }

    CW.HorizontalLine {}

    Text {
      Layout.fillWidth: true
      text: "The Hyprland Desktop Experience has two update channels: Main and Beta."
      horizontalAlignment: Text.AlignLeft
      font.pointSize: C.Config.fontSize.normal
      color: C.Config.theme.on_surface
      Layout.bottomMargin: 15
    }

    Text {
      Layout.fillWidth: true
      text: "Main Channel"
      horizontalAlignment: Text.AlignLeft
      font.pointSize: C.Config.fontSize.h2
      color: C.Config.theme.on_surface
      Layout.bottomMargin: 0
    }

    Text {
      Layout.fillWidth: true
      text: "The main channel moves more slowly, and will receive updates less often, but is more tested."
      horizontalAlignment: Text.AlignLeft
      font.pointSize: C.Config.fontSize.normal
      color: C.Config.theme.on_surface
      Layout.bottomMargin: 15
    }

    Text {
      Layout.fillWidth: true
      text: "Beta Channel"
      horizontalAlignment: Text.AlignLeft
      font.pointSize: C.Config.fontSize.h2
      color: C.Config.theme.on_surface
      Layout.bottomMargin: 0
    }

    Text {
      Layout.fillWidth: true
      text: "The beta channel will receive updates often, with fresh and new features, but is less tested."
      horizontalAlignment: Text.AlignLeft
      font.pointSize: C.Config.fontSize.normal
      color: C.Config.theme.on_surface
      Layout.bottomMargin: 15
    }

    CW.ValueSwitch {
      Layout.fillWidth: true
      Layout.bottomMargin: 15
      label: "Enable the Beta Channel"
      checked: C.Config.misc.betaChannel
      onToggled: C.Config.misc.betaChannel = checked
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
