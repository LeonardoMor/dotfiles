pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

import "../config" as C

Singleton {
  id: root

  property bool updatesAvailable: false
  property bool lastUpdateCheckFailed: false
  property string lastUpdateCheckFailedReason: ""
  property bool updateRunning: false
  property string version: "v0.49.0"
  property int versionInt: 0
  property bool versionMismatch: false
  property bool versionMismatchOpen: false

  function init() {
  }

  function checkForUpdates() {
    if (checkUpdateProc.running)
      return;

    checkUpdateProc.running = true;
  }

  function relog() {
    relogProc.running = true;
  }

  function update() {
    if (updateRunning)
      return;
    updateRunning = true;
    Quickshell.execDetached(["kitty", "bash", "-c", (C.Config.misc.betaChannel ? "HLDE_BETA=1 " : "") + "HLA_CHANNEL=\"" + (C.Config.misc.betaChannel ? "beta" : "release") + "\" HLA_VERSION=\"" + version + "\" " + "$HOME/.config/hyprland-de/scripts/update.sh ; echo \"Update finished. Press enter to close this window.\" ; read"]);
    Quickshell.execDetached(["hyprctl", "dispatch", "global", "hyprland-shell:rightMenuToggle"]); // FIXME: this sucks!!!!
  }

  function setUpdated(epoch) {
    C.Config.misc.lastUpdateEpoch = epoch;
    updateRunning = false;
    versionProc.running = true;
  }

  Timer {
    running: C.Config.misc.autoUpdateCheck
    repeat: true
    interval: 60000 * 60 // 1 hr
    onTriggered: {
      if (versionInt != 0)
        checkUpdateProc.running = true;
    }
  }

  Process {
    id: relogProc
    running: false
    command: ["bash", "-c", "kitty \"$HOME/.config/hyprland-de/scripts/relog.sh\""]
  }

  Process {
    id: versionProc
    running: true
    command: ["hyprctl", "version"]

    stdout: SplitParser {
      splitMarker: ""
      onRead: data => {
        const tagBegin = data.indexOf("Tag: ") + 5;
        const dash = data.indexOf("-", tagBegin);
        let tagEnd = dash;
        if (tagEnd == -1)
          tagEnd = data.indexOf(",", tagBegin);
        else
          tagEnd = Math.min(data.indexOf(",", tagBegin), tagEnd);
        version = data.substr(tagBegin, tagEnd - tagBegin);

        versionInt = parseInt(version.replace(/\./g, "").replace(/v/g, ""));

        if (C.Config.misc.lastHyprlandVersion == 0)
          C.Config.misc.lastHyprlandVersion = versionInt;

        versionMismatch = C.Config.misc.lastHyprlandVersion != versionInt;
        versionMismatchOpen = versionMismatch;

        C.Config.misc.lastHyprlandVersion = versionInt;

        if (C.Config.misc.autoUpdateCheck)
          checkUpdateProc.running = true;
      }
    }
  }

  Process {
    id: checkUpdateProc
    running: false
    command: ["bash", "-c", "HLA_CHANNEL=\"" + (C.Config.misc.betaChannel ? "beta" : "release") + "\" HLA_VERSION=\"" + version + "\" $HOME/.config/hyprland-de/scripts/checkUpdates.sh"]

    stdout: SplitParser {
      splitMarker: ""
      onRead: data => {
        const json = JSON.parse(data);

        C.Config.misc.lastUpdateCheck = new Date().getTime() / 1000;

        if (json.success == false) {
          lastUpdateCheckFailed = true;
          lastUpdateCheckFailedReason = json.message;
          return;
        }

        lastUpdateCheckFailed = false;
        lastUpdateCheckFailedReason = "Unknown";

        if (C.Config.misc.lastUpdateEpoch == 0)
          C.Config.misc.lastUpdateEpoch = json.epoch_seconds;

        if (C.Config.misc.lastUpdateEpoch < json.epoch_seconds - 10)
          updatesAvailable = true;
        else
          updatesAvailable = false;
      }
    }
  }
}
