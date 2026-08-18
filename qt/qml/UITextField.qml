import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

FocusScope {
    id: rootItem
    property string title
    property alias text: editor.text
    property alias placeholderText: editor.placeholderText
    // property int pixelSize: 13

    implicitHeight: mainLayout.implicitHeight
    implicitWidth: 200
    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        spacing: 4
        Label {
            id: lbl
            visible: !!rootItem.title
            text: rootItem.title
            font.pixelSize: 11;
            font.bold: true;
            color: "#6b7280"
        }
        Rectangle {
            Layout.fillWidth: true;
            Layout.preferredHeight: 38
            color: "#f9fafb";
            radius: 6;
            border.color: editor.activeFocus ? "#0288d1" : "#d1d5db";
            border.width: editor.activeFocus ? 2 : 1
            TextField {
                id: editor;
                anchors.fill: parent;
                leftPadding: 10;
                font.pixelSize: 13;
                selectByMouse: true;
                background: null;
            }
        }
    }

}
