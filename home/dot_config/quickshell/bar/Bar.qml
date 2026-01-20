import "../config" as C
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
  id: root

  property bool compact: false
  property bool show: true
  property real barRadius: C.Config.settings.bar.radius
  property real barHeight: C.Config.settings.bar.height
  property real gapsHorz: C.Config.settings.bar.horizontalGap
  property real gapsVert: C.Config.settings.bar.verticalGap
  property real innerPadHorz: 8
  property real compactHeight: barHeight
  property real standardHeight: barHeight + gapsVert
  readonly property real borderMargin: C.Config.settings.panels.borders ? C.Config.settings.panels.bordersSize : 0
  readonly property real topContentMargin: borderMargin + (C.Config.edge == C.Config.BarEdge.Top ? uncompactState : compactState) * gapsVert
  readonly property real bottomContentMargin: borderMargin + (C.Config.edge == C.Config.BarEdge.Bottom ? uncompactState : compactState) * gapsVert
 // readonly property bool showBattery: (UPower.displayDevice.isLaptopBattery ||  && (!C.Config.settings.bar.battery.hideOnFull ? true : UPower.displayDevice.percentage < 0.99)
  property real compactState: compact ? 1 : 0
  property real uncompactState: 1 - compactState

  anchors: C.Config.barAnchors
  color: "transparent"
  exclusiveZone: compact ? compactHeight : standardHeight
  WlrLayershell.namespace: "hyprland-shell:bar"
  WlrLayershell.layer: C.Config.settings.bar.topLayer ? WlrLayer.Top : WlrLayer.Bottom
  implicitHeight: standardHeight

  visible: root.show

  function stringToModule(str) {
    let t = str.trim();

    if (t == "workspaces")
      return workspaces;
    if (t == "mpris")
      return barMpris;
    if (t == "weather")
      return C.Config.settings.bar.weather ? weather : null;
    if (t == "battery" || t == "systemstats")
      return battery;
    if (t == "clock")
      return clock;
    if (t == "title")
      return barWindowTitle;
    if (t == "keyboard")
      return barKeyboard;
    if (t == "tray")
      return barTray;
    return null;
  }

  function getLeftChildren() {
    let modules = C.Config.settings.bar.modulesLeft.split(',');
    let sepI = 0;
    const seps = [separator, separator2, separator3, separator4, separator5, separator6, separator7];

    let moduleArr = [];

    for (let mstr of modules) {
      let mod = stringToModule(mstr);
      if (mod == null) {
        console.log("module " + mstr + " was null");
        continue;
      }

      moduleArr.push(seps[sepI++]);
      moduleArr.push(mod);
    }

    return moduleArr;
  }

  function getRightChildren() {
    let modules = C.Config.settings.bar.modulesRight.split(',');
    let sepI = 0;
    const seps = [separatora, separator2a, separator3a, separator4a, separator5a, separator6a, separator7a];

    let moduleArr = [];

    for (let mstr of modules) {
      let mod = stringToModule(mstr);
      if (mod == null) {
        console.log("module " + mstr + " was null");
        continue;
      }

      moduleArr.push(seps[sepI++]);
      moduleArr.push(mod);
    }

    return moduleArr.reverse();
  }

  function getMiddleChild() {
    let mod = stringToModule(C.Config.settings.bar.moduleCenter);

    return [mod]
  }

  // Background
  Rectangle {
    id: barBackground

    radius: root.uncompactState * root.barRadius
    color: C.Config.applyBaseOpacity(C.Config.theme.background)
    border.width: C.Config.settings.panels.borders ? root.uncompactState * root.borderMargin : 0
    border.color: C.Config.applyBaseOpacity(C.Config.theme.outline_variant)

    anchors {
      fill: parent
      leftMargin: root.uncompactState * root.gapsHorz
      rightMargin: root.uncompactState * root.gapsHorz
      topMargin: root.topContentMargin - root.borderMargin
      bottomMargin: root.bottomContentMargin - root.borderMargin
    }

    RowLayout {
      id: leftSide
      spacing: 10

      anchors {
        top: parent.top
        bottom: parent.bottom
        left: parent.left
        leftMargin: C.Config.settings.bar.addHorizontalEdgePad
      }

      children: [leftMenuButton, ...getLeftChildren()]
    }

    RowLayout {
      id: rightSide
      spacing: 15

      anchors {
        top: parent.top
        bottom: parent.bottom
        right: parent.right
        rightMargin: C.Config.settings.bar.addHorizontalEdgePad
      }

      children: [...getRightChildren(), rightMenuButton]
    }

    // Title in the middle
    RowLayout {
      id: centerSide

      anchors {
        top: parent.top
        bottom: parent.bottom
        horizontalCenter: parent.horizontalCenter
      }

      readonly property int available: barBackground.width - 2 * Math.max(leftSide.width, rightSide.width) - 60 /* padding */

      width: available

      Item {
        id: fillerA
        Layout.fillWidth: true
        Layout.fillHeight: true
      }

      Item {
        id: fillerB
        Layout.fillWidth: true
        Layout.fillHeight: true
      }

      children: [fillerA, ...getMiddleChild(), fillerB]
    }
  }

  Behavior on compactState {
    SmoothedAnimation {
      velocity: 8
    }
  }

  Item {
    visible: false

    LeftMenuButton {
      id: leftMenuButton
      topLeftRadius: barBackground.radius - root.borderMargin
      bottomLeftRadius: topLeftRadius
    }

    WindowTitle {
      id: barWindowTitle
      panelWindow: root
      Layout.minimumWidth: 0
      Layout.fillWidth: true
      horizontalAlignment: getMiddleChild().indexOf(barWindowTitle) != -1 ? Text.AlignHCenter : (getLeftChildren().indexOf(barWindowTitle) != -1 ? Text.AlignLeft : Text.AlignRight)
      Layout.maximumWidth: getMiddleChild().indexOf(barWindowTitle) != -1 ? -1 : 350
    }

    // FIXME: this SUCKS
    BarSeparator {
      id: separator
    }

    BarSeparator {
      id: separator2
    }

    BarSeparator {
      id: separator3
    }

    BarSeparator {
      id: separator4
    }

    BarSeparator {
      id: separator5
    }

    BarSeparator {
      id: separator6
    }

    BarSeparator {
      id: separator7
    }

    BarSeparator {
      id: separatora
    }

    BarSeparator {
      id: separator2a
    }

    BarSeparator {
      id: separator3a
    }

    BarSeparator {
      id: separator4a
    }

    BarSeparator {
      id: separator5a
    }

    BarSeparator {
      id: separator6a
    }

    BarSeparator {
      id: separator7a
    }

    Workspaces {
      id: workspaces
      topInset: root.borderMargin
      bottomInset: root.borderMargin
      Layout.leftMargin: 8
      Layout.rightMargin: 8
    }

    Mpris {
      id: barMpris

      Layout.maximumWidth: 350
    }

    Weather {
      id: weather
    }

    Battery {
      id: battery
      visible: root.showBattery
    }

    Clock {
      id: clock
    }

    KeyboardLayout {
      id: barKeyboard
    }

    SystemTray {
      id: barTray
    }

    RightMenuButton {
      id: rightMenuButton
      topRightRadius: barBackground.radius - root.borderMargin
      bottomRightRadius: topRightRadius
      Layout.leftMargin: -6
    }
  }

  mask: Region {
    width: root.width
    height: root.exclusiveZone
  }
}
