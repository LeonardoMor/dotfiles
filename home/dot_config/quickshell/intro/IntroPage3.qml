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
      text: "Support, bug reports and feature requests"
      horizontalAlignment: Text.AlignHCenter
      font.pointSize: C.Config.fontSize.h2
      color: C.Config.theme.primary
    }

    CW.HorizontalLine {}

    Text {
      Layout.fillWidth: true
      text: "For support, bug reports and feature requests, please head on to our forum,\nlog in with your Hyprland Account, and find the Premium section.\n\nThere, you can make support requests in the support channel,\nor report bugs / suggestions in the DE section."
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
