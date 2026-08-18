import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

FocusScope {
    id: rootItem
    property alias text: editor.text
    property string placeholderText
    property bool fillWidth: false
    property bool expanded: false

    signal accepted()
    signal editingFinished()  //: editor.editingFinished;
    implicitHeight: layout.implicitHeight
    implicitWidth: layout.implicitWidth

    RowLayout {
        id: layout
        anchors.fill: parent
        anchors.leftMargin: 6; anchors.rightMargin: 6
        spacing: 6
        ToolButton {
            id: btnFindToggle
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32
            icon.source: "qrc:/icon/find.svg"
            onClicked: rootItem.expanded = !rootItem.expanded
            // onClicked: editor.visible = !editor.visible
            // hovered: true
            ToolTip{ visible: parent.hovered; delay: 800; timeout: 4000; text: qsTr("Фільтр"); }
        }
        TextField {
            id: editor
            Layout.preferredWidth: 120
            Layout.preferredHeight: 32
            Layout.fillWidth: rootItem.fillWidth
            topPadding: 0
            bottomPadding: 0
            selectByMouse: true
            visible: rootItem.expanded
            placeholderText: rootItem.placeholderText
            // background: null
            background: Rectangle {
                radius: height/5    //6
                color: parent.activeFocus ? "#FFFFFF" : "#F9FAFB"
                border { width: 1; color: parent.activeFocus ? "#0288d1" : "#bdbdbd" }
                // border { width: 1; color: parent.activeFocus ? "#3B82F6" : "#D1D5DB" }
            }

            onVisibleChanged: {
                if (visible) forceActiveFocus();
                else text = '';
            }
            // onTextChanged: dataModel.populate(text)
            onAccepted: rootItem.accepted()
            onEditingFinished: rootItem.editingFinished()
        }

    }
}

