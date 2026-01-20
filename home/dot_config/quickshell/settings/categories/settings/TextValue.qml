import "../../../bar" as B
import "../../../commonwidgets" as CW
import "../../../config" as C
import "../../../state" as S
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

RowLayout {
  id: root

  z: 10

  property string label: "Vaxry was here"
  property string value: "Test"
  property var onChanged: function (x) {
    console.log("BUG THIS: empty onChanged in TextValue.qml");
  }

  RowLayout {
    Text {
      Layout.fillHeight: true
      font.pointSize: C.Config.fontSize.normal
      text: label
      verticalAlignment: Text.AlignVCenter
      color: C.Config.theme.on_surface
    }

    Item {
      Layout.fillWidth: true
    }

    Rectangle {
      Layout.fillHeight: true
      Layout.preferredWidth: te.width + 20
      color: C.Config.applySecondaryOpacity(C.Config.theme.surface_container)
      radius: 6

      TextEdit {
        id: te

        font.pointSize: C.Config.fontSize.normal
        text: value.length < 1 ? "None" : value
        verticalAlignment: Text.AlignVCenter
        color: C.Config.theme.on_surface
        focus: true
        readOnly: false
        activeFocusOnPress: true
        onEditingFinished: {
          onChanged(te.text);
        }

        Keys.onPressed: (event) => {
          // FIXME: why does this not work by default? TextEdit should do it...
          if (event.key == Qt.Key_Left && te.cursorPosition > 0)
            te.cursorPosition--;
          if (event.key == Qt.Key_Right && te.cursorPosition < te.text.length)
            te.cursorPosition++;
          if (event.key == Qt.Key_Delete && te.text.length > 0 && te.cursorPosition < te.text.length) {
            const curpos = te.cursorPosition;
            te.text = te.text.substr(0, te.cursorPosition) + te.text.substr(te.cursorPosition + 1, te.text.length - te.cursorPosition - 1);
            te.cursorPosition = curpos;
          }

          if (event.key == Qt.Key_Return) {
            onChanged(te.text);
            te.deselect();
          }

          event.accepted = false;
        }

        anchors {
          top: parent.top
          bottom: parent.bottom
          right: parent.right
          rightMargin: 10
        }
      }
    }
  }
}
