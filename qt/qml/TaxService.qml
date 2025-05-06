import QtQuick
//import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Controls

Window {
    id: root
    width: 360
    height: 480

    onActiveChanged: tmr.running = active
    property alias host: editHost.text
    property alias cash: editCash.text
    property alias prefix: editPrefix.text
    property alias token: editToken.text

    signal vkEvent(string id, var param)

    function showResp(jdata){       // {"code":code, "sender":sender, "resp":resp, "tm":new Date()}
//        console.log("#571 TaxService id="+code+ " resp="+resp)
        vw.model.insert(0, jdata)
    }

    Timer{
        id: tmr
//        property bool legacyLvl1: false
        interval: 60000
        repeat: true
        running: false
        onTriggered: {
//            msg("TaxService tmr started =")
            var i=0
            var dd= new Date()
            dd.setSeconds(dd.getSeconds() -59);
            for(i= vw.model.count-1; i>=0; --i){
                if (vw.model.get(i).tm < dd) {
                    vw.model.remove(i)
                }
            }
        }
    }

    Component {
        id: dlg
            Rectangle {
                id: drect
                width: drect.ListView.view.width
                height: childrenRect.height
                color: code === 'error'? '#f6d5d5' : '#d7f5d8'
                border{width:1; color:code === 'error'? 'red' : 'green'}
                radius: 5
                Text{
                    width: parent.width-10; //parent.width
                    anchors.centerIn: parent
                    wrapMode:Text.Wrap;
                    text:sender+' '+Qt.formatDateTime(tm,"hh:mm")+"\n"+resp;   //JSON.stringify(resp)
                }
            }
    }

    Action {
        id: pingAction
        text: "Ping"
        onTriggered: { vkEvent("ping",""); }
    }
    Action {
        id: xAction
        text: "Х-Звіт"
        onTriggered: { vkEvent("xreport",""); }
    }
    Action {
        id: zAction
        text: "Z-Звіт"
        onTriggered: { vkEvent("zreport",""); }
    }
    Action {
        id: settingsAction
        text: "Settings"
        onTriggered: {
            settingsDialog.open();
        }
    }
/*    Action {
        id: saveSettingsAction
        text: "Settings"
        onTriggered: {
            settingsDialog.close()
        }
    }*/

    Dialog {
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

    Page{
        anchors.fill: parent
        Pane{
            anchors.fill: parent
            ListView{
                id: vw
                anchors{fill:parent; }  //margins:2
                spacing: 5
                clip: true
                model: ListModel{}
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
                        MenuSeparator { padding: 5; }
                        MenuItem { action: settingsAction; }
                    }
                }
                Item{
                    Layout.fillWidth: true
                    Layout.preferredHeight: 30
                    id: info
                    clip: true
//                    color:'salmon'
                    Text{ anchors.centerIn: parent; text: (host===undefined || host ==="" ? "undefined" : host.substring(host.indexOf("//")+2)); elide: Label.ElideRight;}
                }
                Button{ action: pingAction; }
                Button{ action: xAction; }

            }

        }
    }



}
