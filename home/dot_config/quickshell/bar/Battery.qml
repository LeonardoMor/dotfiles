import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import "../config" as C
import "../commonwidgets" as CW
import "../state" as S

RowLayout {
  id: root
  property real percentage: UPower.displayDevice.percentage
  property real charging: UPower.displayDevice.state === UPowerDeviceState.Charging
  property color color: (!charging && percentage * 100 < C.Config.settings.bar.battery.low) ? C.Config.theme.error : C.Config.theme.on_background
  spacing: 6

  RowLayout {
    spacing: 0
    visible: UPower.displayDevice.isLaptopBattery && (!C.Config.settings.bar.battery.hideOnFull ? true : UPower.displayDevice.percentage < 0.99)
      
    CW.FontIcon {
      Layout.topMargin: 0.5
      Layout.alignment: Qt.AlignVCenter
      color: root.color
      iconSize: 15
      text: {
        const iconNumber = Math.round(root.percentage * 7);
        return root.charging ? "battery_android_bolt" : `battery_android_${iconNumber >= 7 ? "full" : iconNumber}`;
      }
    }

    CW.StyledText {
      Layout.alignment: Qt.AlignVCenter
      Layout.fillHeight: true
      Layout.leftMargin: 2
      text: `${Math.round(percentage * 100)}%`
      color: root.color
    }
  }

  RowLayout {
    spacing: 0
    visible: C.Config.settings.bar.battery.showSystemStats
      
    CW.FontIcon {
      Layout.alignment: Qt.AlignVCenter
      Layout.topMargin: 0.5
      color: C.Config.theme.on_background
      iconSize: 15
      text: "memory"
    }

    CW.StyledText {
      Layout.alignment: Qt.AlignVCenter
      Layout.fillHeight: true
      Layout.leftMargin: 2
      text: `${Math.round(S.SystemState.cpu)}%`
      color: C.Config.theme.on_background
    }
  }

  RowLayout {
    spacing: 0
    visible: C.Config.settings.bar.battery.showSystemStats
      
    CW.FontIcon {
      Layout.alignment: Qt.AlignVCenter
      Layout.topMargin: 0.5
      color: C.Config.theme.on_background
      iconSize: 15
      text: "menu"
    }

    CW.StyledText {
      Layout.alignment: Qt.AlignVCenter
      Layout.fillHeight: true
      Layout.leftMargin: 2
      text: `${Math.round(S.SystemState.ram)}%`
      color: C.Config.theme.on_background
    }
  }
}
