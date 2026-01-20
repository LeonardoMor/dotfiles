pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

import "../config" as C

Singleton {
  id: root

  property bool shortcutsOpen: false
  property bool shortcutsOpenGrab: false

  property bool settingsOpen: false
  property bool settingsOpenGrab: false

  property string keyboardLayout: ""

  property bool trayInBar: C.Config.settings.bar.moduleCenter.indexOf("tray") != -1 || C.Config.settings.bar.modulesLeft.indexOf("tray") != -1 || C.Config.settings.bar.modulesRight.indexOf("tray") != -1

  Process {
    id: devicesProc
    running: true
    command: ["hyprctl", "-j", "devices"]

    stdout: SplitParser {
      splitMarker: ""
      onRead: data => {
        const J = JSON.parse(data);

        if (J.keyboards.length <= 0)
          return;

        keyboardLayout = J.keyboards[0].active_keymap;
      }
    }
  }

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      if (event.name === "activelayout") {
        const data = event.data.split(",");
        if (data.length <= 1)
          return;

        if (data[0].indexOf("hl-virtual-") == 0)
          return;

        keyboardLayout = data[1];
      } else if (event.name == "configreloaded")
        devicesProc.running = true;
    }
  }
}
