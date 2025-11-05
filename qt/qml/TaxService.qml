import QtQuick
//import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Controls
import "../libTAX.js" as CashDesk

Window {
    id: root
    width: 360
    height: 480

    // onActiveChanged: tmr.running = active

    // signal vkEvent(string id, var param)

    Timer{
            id: removeRow_timer
            interval: 60000
            repeat: true
            running: true
            onTriggered: {
                let dd = new Date()
                // dd.setSeconds(dd.getSeconds() -59);
                for(let i = 0; i < vw.model.count; ++i){
                    console.log("TaxService i="+i + " tm=" + vw.model.get(i).tm + " dd=" + dd)
                    if (vw.model.get(i).tm < dd) {
                        vw.model.remove(i)
                    }
                }
            }
        }

    function newMessage(sender, text, code){
        taxModel.addMessage(sender, text, code)
    }

    ListModel{
        id: taxModel

        function getHost(){
            return CashDesk.gl_host.substring(CashDesk.gl_host.indexOf("//")+2)
        }

        function addMessage(sender, text, code = "info"){
            append({"code": code,
                      "sender": sender,
                      "resp": text,
                      "tm":new Date()})
        }

        function ping(){
            CashDesk.ping( (err, resp) =>
                        {
                            if (err){
                                addMessage("ping", err, "error")
                            } else {
                                addMessage("ping", "II: OK #" +resp.user_signature.user_id + " "+resp.user_signature.full_name)
                            }
                        }
                        )
        }

        function x_report(){
            CashDesk.x_report( (err, resp) =>
                        {
                            if (err){
                                addMessage("x_report", err, "error")
                            } else {
                                addMessage("x_report", "X_report OK #" +JSON.stringify(resp))
                            }
                        }
                        )
        }

        function z_report(){
            CashDesk.z_report( (err, resp) =>
                        {
                            if (err){
                                addMessage("z_report", err, "error")
                            } else {
                                addMessage("z_report", "Z_report OK #" +resp)
                            }
                        }
                        )
        }

    }

    Component {
        id: dlg
        FocusScope{
            id: root
            width: root.ListView.view.width;
            height: 70  //childrenRect.height;
            Rectangle {
                id: drect
                // width: parent.width
                // height: 70  // childrenRect.height
                anchors.fill: parent
                color: code === 'error'? '#f6d5d5' : '#d7f5d8'
                border{width:1; color:code === 'error'? 'red' : 'green'}
                    Text{
                        anchors{fill: parent; leftMargin: 4; rightMargin: 4}
                        clip: true
                        wrapMode:Text.Wrap;
                        text: sender+' '+Qt.formatDateTime(tm,"hh:mm")+"\n"+resp;   //JSON.stringify(resp)
                    }
                    MouseArea{
                        anchors.fill: parent
                        hoverEnabled: true
                        ToolTip.delay: 1000
                        ToolTip.timeout: 10000
                        ToolTip.visible: containsMouse
                        ToolTip.text: resp
                    }

            }
        }
    }

    Action {
        id: pingAction
        text: "Ping"
        onTriggered: taxModel.ping()
    }
    Action {
        id: xAction
        text: "Х-Звіт"
        onTriggered: taxModel.x_report()
    }
    Action {
        id: zAction
        text: "Z-Звіт"
        onTriggered: confirmZreport.open()
    }

    Dialog{
        id: confirmZreport
        anchors.centerIn: parent
        modal: true
        title: 'Зробити Z-звіт ?\n(Закрити фіскальну зміну ДПС)'
        footer: DialogButtonBox {
            standardButtons: Dialog.Ok|Dialog.Cancel
//            standardButtons: Dialog.Yes|Dialog.No
//            alignment: Qt.AlignHCenter
            Keys.onEnterPressed: confirmZreport.accept()
            Keys.onReturnPressed: confirmZreport.accept()
            onVisibleChanged: if (visible) forceActiveFocus()
        }
        onAccepted: taxModel.z_report()
    }

/*    Dialog {
        id: settingsDialog
        x: Math.round((root.width - width) / 2)
        y: Math.round(root.height / 6)
        width: Math.round(Math.min(root.width, root.height) *0.8)
        modal: true
        focus: true
        title: qsTr("Settings")

        standardButtons: Dialog.Ok | Dialog.Cancel  // Dialog.Close //Dialog.Ok | Dialog.Cancel
        onAccepted: {
            vkEvent("settings", { "cash":cash, "host":host, "prefix":prefix, "token":token })
            settingsDialog.close();
        }
        onRejected: { settingsDialog.close(); }
        contentItem: ColumnLayout {
                width: parent.width
                RowLayout {
                    spacing: 10
                    Label{ text: "Каса:" }
                    TextField{
                        id: editCash
                        Layout.fillWidth: true
                        placeholderText: "каса ДПС"
//                            onAccepted: { uplMngr.setSettingsValue("program/pwd", text); nextItemInFocusChain(true).forceActiveFocus(); }
                    }
                }
                RowLayout {
                    spacing: 10
                    Label{ text: "Провайдер:" }
                    TextField{
                        id: editHost
                        Layout.fillWidth: true
                        placeholderText: "сервер провайдера"
//                            onAccepted: { uplMngr.setSettingsValue("terminal/code", text); nextItemInFocusChain(true).forceActiveFocus(); }
                    }
                }
                RowLayout {
                    spacing: 10
                    Label{ text: "Префікс:" }
                    TextField{
                        id: editPrefix
                        Layout.fillWidth: true
                        placeholderText: "префікс API"
//                            onAccepted: { uplMngr.setSettingsValue("upload/http_host", text); nextItemInFocusChain(true).forceActiveFocus(); }
                    }
                }
                RowLayout {
                    spacing: 10
                    Label{
                        minimumPixelSize: 100
                        text: "Token:"
                    }
                    TextField{
                        id: editToken
                        Layout.fillWidth: true
                        echoMode: TextInput.Password
                        placeholderText: "token"
//                        text: root.token
//                            onAccepted: { uplMngr.setSettingsValue("upload/http_password", text); nextItemInFocusChain(true).forceActiveFocus(); }
                    }
                }
            }
    }
*/

    Page{
        anchors.fill: parent
        Pane{
            anchors.fill: parent
            ListView{
                id: vw
                anchors{fill:parent; }  //margins:2
                spacing: 5
                clip: true
                model: taxModel
                // model: ListModel{}
                // verticalLayoutDirection: ListView.BottomToTop
                delegate: dlg
            }

        }

        header: ToolBar {
            RowLayout {
                anchors.fill: parent
                ToolButton {    // ⋮
                    text: "☰"
                    onClicked: menu.open()
                    Menu{
                        id: menu
                        MenuItem { action: zAction; }
                        MenuSeparator { padding: 5; }
                        MenuItem { action: xAction; }
                        MenuItem { action: pingAction; }
                        // MenuSeparator { padding: 5; }
                        // MenuItem { action: settingsAction; }
                    }
                }
                Item{
                    Layout.fillWidth: true
                    Layout.preferredHeight: 30
                    id: info
                    clip: true
//                    color:'salmon'
                    Text{
                        anchors.centerIn: parent;
                        text: taxModel.getHost()
                        elide: Label.ElideRight;}
                }
                Button{ action: pingAction; }
                Button{ action: xAction; }

            }

        }
    }



}
