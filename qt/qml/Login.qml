import QtQuick
import QtQuick.Controls.Fusion
import QtQuick.Layouts
import QtQuick.Window

import com.vkeeper 3.0

Window {
    id: root
    title: qsTr("Login")
    width:300
    height: 200
    visible: true

//    signal vkEvent(var event)
    signal vkEvent(string id, var param)

    DbDriver{
        id: dbDriver
        Component.onCompleted: {
//            let sql =
            let data = JSON.parse(dbDriver.getJSONRowsFromSQL_2("select code, note from cashier order by note;")).rows;
            console.log(data)
//        cmb.model
        }
    }
//    onVisibleChanged: if(visible) { login.open(); }
//    Dialog{
//        id: login
//        width: parent.width
//        height: parent.height
        //    x: Math.round((root.width - width) / 2)
        //    y: Math.round(root.height / 6)
        //    modal: true
        //    focus: true
        //    standardButtons: Dialog.Ok | Dialog.Cancel
        //    onAccepted: { root.close(); showRoot(); }
        //    onRejected: { root.close(); }
//            contentItem:
                ColumnLayout {
//                RowLayout {
//                    spacing: 10

                    Label {
                        text: qsTr("Cashier:")
                    }

                    ComboBox {
                        id: cmb
                        property int styleIndex: -1
                        textRole: "note"
                        valueRole: "code"
                        model: [{"code":"tes1", "note":"Test Cashier 1"},{"code":"tes2", "note":"Test Cashier 2"}]
        //                    Component.onCompleted: {
        //                        styleIndex = find(settings.style, Qt.MatchFixedString)
        //                        if (styleIndex !== -1)
        //                            currentIndex = styleIndex
        //                    }
                        Layout.fillWidth: true
                    }
//                }
                    Button{
                        text: "Ok"
                        onClicked: vkEvent("cashierChanged", cmb.currentValue)

                    }


            }
        //    onOpened: {
        ////            root.opacity = 0.5
        ////            root.hide()
        //    }

//    }


}
