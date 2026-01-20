import "../config" as C
import "../commonwidgets" as CW
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import Quickshell.Wayland

PanelWindow {
  id: root

  property var activePanel: page1
  property var previousPanel: page1

  WlrLayershell.namespace: "hyprland-shell:bar"
  WlrLayershell.layer: WlrLayer.overlay
  anchors: C.Config.introAnchors
  color: "transparent"

  Rectangle {
    radius: 10
    color: C.Config.applyBaseOpacity(C.Config.theme.background)
    border.width: C.Config.settings.panels.borders ? C.Config.settings.panels.bordersSize : 0
    border.color: C.Config.applyBaseOpacity(C.Config.theme.outline_variant)
    implicitWidth: activePanel.width + 40
    implicitHeight: activePanel.height + 40

    clip: true

    anchors {
      horizontalCenter: parent.horizontalCenter
      verticalCenter: parent.verticalCenter
    }

    IntroPage1 {
      id: page1

      visible: opacity > 0
      opacity: activePanel == page1 ? 1 : 0
      z: activePanel == page1 ? 2 : 1
      onNext: {
        previousPanel = page1;
        activePanel = page2;
      }

      anchors {
        top: parent.top
        left: parent.left
        margins: 20
      }

      Behavior on opacity {
        NumberAnimation {
          duration: C.Globals.anim_MEDIUM
          easing.type: Easing.BezierSpline
          easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
        }
      }
    }

    IntroPage2 {
      id: page2

      visible: opacity > 0
      opacity: activePanel == page2 ? 1 : 0
      z: activePanel == page2 ? 2 : 1
      onNext: {
        previousPanel = page2;
        activePanel = page3;
      }

      anchors {
        top: parent.top
        left: parent.left
        margins: 20
      }

      Behavior on opacity {
        NumberAnimation {
          duration: C.Globals.anim_MEDIUM
          easing.type: Easing.BezierSpline
          easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
        }
      }
    }

    IntroPage3 {
      id: page3

      visible: opacity > 0
      opacity: activePanel == page3 ? 1 : 0
      z: activePanel == page3 ? 2 : 1
      onNext: {
        previousPanel = page3;
        activePanel = page4;
      }

      anchors {
        top: parent.top
        left: parent.left
        margins: 20
      }

      Behavior on opacity {
        NumberAnimation {
          duration: C.Globals.anim_MEDIUM
          easing.type: Easing.BezierSpline
          easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
        }
      }
    }

    IntroPage4 {
      id: page4

      visible: opacity > 0
      opacity: activePanel == page4 ? 1 : 0
      z: activePanel == page4 ? 2 : 1
      onNext: {
        previousPanel = page4;
        activePanel = page5;
      }

      anchors {
        top: parent.top
        left: parent.left
        margins: 20
      }

      Behavior on opacity {
        NumberAnimation {
          duration: C.Globals.anim_MEDIUM
          easing.type: Easing.BezierSpline
          easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
        }
      }
    }

    IntroPage5 {
      id: page5

      visible: opacity > 0
      opacity: activePanel == page5 ? 1 : 0
      z: activePanel == page5 ? 2 : 1
      onNext: {
        previousPanel = page5;
        activePanel = page6;
      }

      anchors {
        top: parent.top
        left: parent.left
        margins: 20
      }

      Behavior on opacity {
        NumberAnimation {
          duration: C.Globals.anim_MEDIUM
          easing.type: Easing.BezierSpline
          easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
        }
      }
    }

    IntroPage6 {
      id: page6

      visible: opacity > 0
      opacity: activePanel == page6 ? 1 : 0
      z: activePanel == page6 ? 2 : 1
      onNext: {
        previousPanel = page6;
        activePanel = page7;
      }

      anchors {
        top: parent.top
        left: parent.left
        margins: 20
      }

      Behavior on opacity {
        NumberAnimation {
          duration: C.Globals.anim_MEDIUM
          easing.type: Easing.BezierSpline
          easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
        }
      }
    }

    IntroPage7 {
      id: page7

      visible: opacity > 0
      opacity: activePanel == page7 ? 1 : 0
      z: activePanel == page7 ? 2 : 1
      onNext: {
        previousPanel = page7;
        C.Config.misc.introductionDone = true;
      }

      anchors {
        top: parent.top
        left: parent.left
        margins: 20
      }

      Behavior on opacity {
        NumberAnimation {
          duration: C.Globals.anim_MEDIUM
          easing.type: Easing.BezierSpline
          easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
        }
      }
    }

    Behavior on implicitWidth {
      NumberAnimation {
        duration: C.Globals.anim_MEDIUM
        easing.type: Easing.BezierSpline
        easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
      }
    }

    Behavior on implicitHeight {
      NumberAnimation {
        duration: C.Globals.anim_MEDIUM
        easing.type: Easing.BezierSpline
        easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
      }
    }
  }
}
