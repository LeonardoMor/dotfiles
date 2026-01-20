pragma Singleton

import QtQuick
import QtCore
import Quickshell
import Quickshell.Io

Singleton {
  id: root
  property alias theme: themeJson
  property alias account: accountJson
  property alias settings: settingsJson
  property alias misc: miscJson

  enum BarEdge {
    Top,
    Bottom
  }

  function asMonitorString(mons) {
    return mons.join(",");
  }

  function epochSecondsToHuman(sec) {
    if (sec < 10)
      return "None";

    const date = new Date(sec * 1000);
    return formatDateTime(date);
  }

  function romanize(num) {
    if (isNaN(num))
        return NaN;
    var digits = String(+num).split(""),
        key = ["", "C", "CC", "CCC", "CD", "D", "DC", "DCC", "DCCC", "CM",
            "", "X", "XX", "XXX", "XL", "L", "LX", "LXX", "LXXX", "XC",
            "", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX"],
        roman = "",
        i = 3;
    while (i--)
        roman = (key[+digits.pop() + (i * 10)] || "") + roman;
    return Array(+digits.join("") + 1).join("M") + roman;
  }

  function formatDateTime(dateTime) {
    if (settings.misc.dateFormat == 5 /* vaxry */)
      return Qt.formatDateTime(dateTime, "d") + " " + romanize(parseInt(Qt.formatDateTime(dateTime, "M"))) + " " + Qt.formatDateTime(dateTime, "yyyy hh:mm");
    return Qt.formatDateTime(dateTime, getConfigDateFormat());
  }

  function formatDateTimeSplit(dateTime) {
    if (settings.misc.dateFormat == 5 /* vaxry */)
      return [Qt.formatDateTime(dateTime, "d") + " " + romanize(parseInt(Qt.formatDateTime(dateTime, "M"))) + " " + Qt.formatDateTime(dateTime, "yyyy"), Qt.formatDateTime(dateTime, "hh:mm:ss")];
    return [Qt.formatDateTime(dateTime, getSplitConfigDateFormat()[0]), Qt.formatDateTime(dateTime, getSplitConfigDateFormat()[1])];
  }

  function getSplitConfigDateFormat() {
    if (settings.misc.dateFormat == 0)
      return ["d MMM yyyy", "hh:mm:ss"];
    if (settings.misc.dateFormat == 1)
      return ["dd/MM/yyyy", "hh:mm:ss"];
    if (settings.misc.dateFormat == 2)
      return ["dd/MM/yyyy", "hh:mm:ss AP"];
    if (settings.misc.dateFormat == 3)
      return ["MM/dd/yyyy", "hh:mm:ss AP"];
    if (settings.misc.dateFormat == 4)
      return ["ddd, d MMM yyyy", "hh:mm:ss AP"];
  }

  function getConfigDateFormat() {
    if (settings.misc.dateFormat == 0)
      return "d MMM yyyy hh:mm";
    if (settings.misc.dateFormat == 1)
      return "dd/MM/yyyy hh:mm";
    if (settings.misc.dateFormat == 2)
      return "dd/MM/yyyy hh:mm AP";
    if (settings.misc.dateFormat == 3)
      return "MM/dd/yyyy hh:mm AP";
    if (settings.misc.dateFormat == 4)
      return "ddd, d MMM yyyy hh:mm AP";
  }

  function secondsToRelative(sec) {
    if (sec < 60)
      return "A minute ago";
    if (sec < 3600)
      return "" + parseInt(sec / 60) + " minute" + (parseInt(sec / 60) == 1 ? "" : "s") + " ago";
    if (sec < 3600 * 24)
      return "" + parseInt(sec / 3600) + " hour" + (parseInt(sec / 3600) == 1 ? "" : "s") + " ago";
    return "" + parseInt(sec / (3600 * 24)) + " day" + (parseInt(sec / (3600 * 24)) == 1 ? "" : "s") + " ago";
  }

  function applyBaseOpacity(col) {
    if (settings.panels.transparent)
      return Qt.rgba(col.r, col.g, col.b, settings.panels.baseOpacity);
    return col;
  }

  function applySecondaryOpacity(col) {
    if (settings.panels.transparent)
      return Qt.rgba(col.r, col.g, col.b, 0.35);
    return col;
  }

  property int edge: {
    switch (settings.bar.edge) {
    case "top":
      return Config.BarEdge.Top;
    case "bottom":
      return Config.BarEdge.Bottom;
    default:
      console.warn("Invalid bar edge in settings, defaulting to top.");
      return Config.BarEdge.Top;
    }
  }

  property JsonObject fontSize: JsonObject {
    property int base: root.settings.fonts.basePointSize
    property int h1: base * 1.5
    property int h2: base * 1.35
    property int h3: base * 1.2
    property int large: base * 1.1
    property int normal: base
    property int small: base * 0.9
  }

  property panelAnchors barAnchors: {
    switch (edge) {
    case Config.BarEdge.Top:
      return {
        top: true,
        left: true,
        right: true
      };
    case Config.BarEdge.Bottom:
      return {
        bottom: true,
        left: true,
        right: true
      };
    }
  }

  property panelAnchors introAnchors: {
    return {
      top: true,
      left: true,
      right: true,
      bottom: true
    };
  }

  property panelAnchors noAnchors: {
    return {
      top: false,
      left: false,
      right: false,
      bottom: false
    };
  }

  FileView {
    id: matugenFp
    path: StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.config/quickshell/matugen.json"

    watchChanges: true
    onFileChanged: reload()
    onLoadFailed: error => {
      if (error == FileViewError.FileNotFound) {
        matugenFp.path = "matugen.json"; // FIXME: fox fix this, this doesn't work.
        matugenFp.reload();
      }
    }

    JsonAdapter {
      id: themeJson
      property color background: "#191113"
      property color error: "#ffb4ab"
      property color error_container: "#93000a"
      property color inverse_on_surface: "#382e30"
      property color inverse_primary: "#8d4a5c"
      property color inverse_surface: "#efdee1"
      property color on_background: "#efdee1"
      property color on_error: "#690005"
      property color on_error_container: "#ffdad6"
      property color on_primary: "#551d2e"
      property color on_primary_container: "#ffd9e0"
      property color on_primary_fixed: "#3a071a"
      property color on_primary_fixed_variant: "#efdee1"
      property color on_secondary: "#efdee1"
      property color on_secondary_container: "#efdee1"
      property color on_secondary_fixed: "#efdee1"
      property color on_secondary_fixed_variant: "#713344"
      property color on_surface: "#efdee1"
      property color on_surface_variant: "#efdee1"
      property color on_tertiary: "#efdee1"
      property color on_tertiary_container: "#efdee1"
      property color on_tertiary_fixed: "#efdee1"
      property color on_tertiary_fixed_variant: "#efdee1"
      property color outline: "#efdee1"
      property color outline_variant: "#efdee1"
      property color primary: "#efdee1"
      property color primary_container: "#efdee1"
      property color primary_fixed: "#efdee1"
      property color primary_fixed_dim: "#efdee1"
      property color scrim: "#efdee1"
      property color secondary: "#efdee1"
      property color secondary_container: "#efdee1"
      property color secondary_fixed: "#efdee1"
      property color secondary_fixed_dim: "#efdee1"
      property color shadow: "#efdee1"
      property color surface: "#efdee1"
      property color surface_bright: "#efdee1"
      property color surface_container: "#ff0000"
      property color surface_container_high: "#efdee1"
      property color surface_container_highest: "#efdee1"
      property color surface_container_low: "#efdee1"
      property color surface_container_lowest: "#efdee1"
      property color surface_dim: "#efdee1"
      property color surface_tint: "#efdee1"
      property color surface_variant: "#efdee1"
      property color tertiary: "#efdee1"
      property color tertiary_container: "#efdee1"
      property color tertiary_fixed: "#efdee1"
      property color tertiary_fixed_dim: "#efdee1"
    }
  }

  FileView {
    path: Quickshell.dataPath("config.json")

    watchChanges: true
    onFileChanged: reload()
    onAdapterUpdated: writeAdapter()
    onLoadFailed: error => {
      if (error == FileViewError.FileNotFound) {
        writeAdapter();
      }
    }

    JsonAdapter {
      id: settingsJson
      property JsonObject bar: JsonObject {
        property string edge: "top"
        property int verticalGap: 5
        property int horizontalGap: 5
        property int height: 30
        property int radius: 10
        property bool topLayer: false
        property bool weather: false
        property string weatherLocation: "None"
        property bool weatherNoLocation: false
        property bool weatherTempInCelcius: true
        property int addHorizontalEdgePad: 6

        property string modulesLeft: "workspaces, mpris"
        property string modulesRight: "clock, battery, weather"
        property string moduleCenter: "title"

        property JsonObject workspaces: JsonObject {
          property int shown: 10
          property real activeIndicatorWidthMultiplier: 2
          property int style: 0
          property bool onlyOnCurrent: false
          property bool onlyOpen: false
        }

        property JsonObject battery: JsonObject {
          property int low: 20
          property bool hideOnFull: false
          property bool showSystemStats: false
        }
      }
      property JsonObject fonts: JsonObject {
        property int basePointSize: 10
        property bool useNativeRendering: false
      }
      property JsonObject osd: JsonObject {
        property int timeoutDuration: 700
      }
      property JsonObject panels: JsonObject {
        property int radius: 10
        property bool borders: true
        property int bordersSize: 1
        property bool transparent: true
        property real baseOpacity: 0.8
        property bool compactEnabled: true
        property int monitorChoiceMode: 0 // 0 - exclude, 1 - include
        property list<string> excludedMonitors: ["DP-7, HDMI-A-4"]
        property list<string> includedMonitors: ["0, DP-1, eDP-1, HDMI-A-1"]
      }
      property JsonObject tray: JsonObject {
        property bool monochromeIcons: false
      }
      property JsonObject misc: JsonObject {
        property int dateFormat: 0
      }
      property JsonObject mpris: JsonObject {
        property int selectionMode: 0 // 0 - exclude, 1 - include
        property list<string> excludedPlayers: []
        property list<string> includedPlayers: []
      }
      property JsonObject monitorRounding: JsonObject {
        property bool enabled: false
        property bool ignoreReserved: true
        property bool amoled: true
        property bool allMonitors: false
        property int radius: 20
      }
    }
  }

  FileView {
    path: Quickshell.dataPath("account.json")

    watchChanges: true
    onFileChanged: reload()
    onAdapterUpdated: writeAdapter()
    onLoadFailed: error => {
      if (error == FileViewError.FileNotFound) {
        writeAdapter();
      }
    }

    JsonAdapter {
      id: accountJson
      property string username: ""
    }
  }

  FileView {
    path: Quickshell.dataPath("misc.json")

    watchChanges: true
    onFileChanged: reload()
    onAdapterUpdated: writeAdapter()
    onLoadFailed: error => {
      if (error == FileViewError.FileNotFound) {
        writeAdapter();
      }
    }

    JsonAdapter {
      id: miscJson
      property bool nightLightEnabled: false
      property real nightLightIntense: 50
      property bool brightnessSplit: true
      property bool introductionDone: false
      property bool autoUpdateCheck: true
      property bool betaChannel: false
      property bool hasUpdates: false
      property int lastUpdateEpoch: 0
      property int lastUpdateCheck: 0
      property int lastHyprlandVersion: 0
    }
  }
}
