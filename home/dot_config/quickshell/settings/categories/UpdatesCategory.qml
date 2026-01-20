import "../../commonwidgets" as CW
import "../../config" as C
import "./settings" as ST
import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets

CategoryBlueprint {
    id: root

    RowLayout {
        spacing: 50
        anchors.margins: 20
        uniformCellSizes: false

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }

        ColumnLayout {
            id: col1

            Layout.fillWidth: true
            Layout.maximumHeight: implicitHeight
            Layout.alignment: Qt.AlignTop
            uniformCellSizes: false
            spacing: 0

            CW.StyledText {
                Layout.topMargin: 10
                text: "Updates"

                font {
                    pointSize: C.Config.fontSize.h2
                    weight: Font.DemiBold
                }

            }

            Spacerr {
            }

            CW.HorizontalLine {
                Layout.topMargin: -5
                Layout.bottomMargin: 5
                Layout.fillWidth: false
                Layout.leftMargin: 0
                implicitWidth: 90
            }

            Spacerr {
            }

            CW.ValueSwitch {
                label: "Automatic update checking"
                checked: C.Config.misc.autoUpdateCheck
                onToggled: C.Config.misc.autoUpdateCheck = checked
                Layout.fillWidth: true
            }

            Spacerr {
            }

            CW.ValueSwitch {
                label: "Beta channel"
                checked: C.Config.misc.betaChannel
                onToggled: C.Config.misc.betaChannel = checked
                Layout.fillWidth: true
            }

            Spacerr {
            }

        }

        ColumnLayout {
            // empty

            id: col2

            Layout.fillWidth: true
            Layout.maximumHeight: implicitHeight
            Layout.alignment: Qt.AlignTop
            uniformCellSizes: false
            spacing: 0

            Item {
                Layout.preferredHeight: 20
                Layout.fillWidth: true
            }

        }

    }

    // this is horrible but QML has forced my hand.
    component Spacerr: Item {
        Layout.preferredHeight: 11
    }

}
