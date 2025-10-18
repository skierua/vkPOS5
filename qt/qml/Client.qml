import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Controls

import "../lib.js" as Lib

Window {
    id: root
    width: 240
    height: 480
//    title: qsTr('Clients')
    property var db                 // DataBase driver
    onDbChanged: vw.model.load(db)

    // signal vkEvent(string id, var param)

    Action{
        id: actionNew
        text: "Новий клієнт"  // qsTr("New")
        onTriggered: {
            if (rectNewClient.visible ){
                rectNewClient.visible = false
                edName.text = ''
                edPhone.text = ''
                edNote.text = ''
            } else {
                rectNewClient.visible = true
            }
        }
            // rectNewClient.visible = !rectNewClient.visible
    }

    Component {
        id: dlg
        FocusScope{
            id: root
            width: childrenRect.width;
            height: childrenRect.height
            Rectangle {
                id: dlgRect
                width: root.ListView.view.width
                height: 45
                color: (index == vw.currentIndex) ?  'lightsteelblue' :'white'
                                                        // (index%2 == 0 ?  Qt.darker('white',1.01) : 'white')
                ColumnLayout{
                    width: parent.width
                    anchors.verticalCenter:  parent.verticalCenter
                    spacing: 2
                    Label{
                        id:fldChar
                        text:name
                        Layout.fillWidth: true
                        MouseArea{
                            anchors.fill:parent
                            onClicked:{ fldEdit.code = "name"; fldEdit.text = name; fldEdit.forceActiveFocus(); }
                        }
                    }
                    RowLayout{
                        Layout.fillWidth: true
                        Label{text:'['+id+']'; color: 'dimgray'}
                        Label{
                            id: fldPhone
                            color:phone === '' ? 'lightgray':'black'
                            text: phone === '' ? 'телефон' : phone
                            MouseArea{
                                anchors.fill:parent
                                onClicked:{ fldEdit.code = "phone"; fldEdit.text = phone; fldEdit.forceActiveFocus(); }
                            }
                        }
                        Label{
                            id: fldNote
                            color:clnote === '' ? 'lightgray':'black'
                            text: clnote === '' ? 'примітка' : clnote
                            MouseArea{
                                anchors.fill:parent
                                onClicked:{ fldEdit.code = "note"; fldEdit.text = clnote; fldEdit.forceActiveFocus(); }
                            }
                        }
                    }
                }
                TextField{
                    id: fldEdit
                    property string code
                    anchors.fill: parent
                    visible: false
                    selectByMouse: true
                    onActiveFocusChanged: if (activeFocus) {visible = true; selectAll()} else {visible = false}
                    onAccepted: {
                        let ok = true
                        if (code === "name") { name = text; }
                        else if (code === "phone") { phone = text; }
                        else if (code === "note") { clnote = text; }
                        else { ok = false; }
                        if (ok){
                            root.ListView.view.model.update(db, index)
                        }
                        visible= false
                    }
                    Keys.onEscapePressed: visible= false    //root.ListView.view.forceActiveFocus()
                }
                MouseArea{
                   // anchors.fill: parent;
                    width: (index === root.ListView.view.currentIndex)?0:parent.width
                    height: (index === root.ListView.view.currentIndex)?0:parent.height
                    onClicked: {
                        root.ListView.view.currentIndex = index;
                    }
                }
            }
        }
    }

    ListModel{
        id: dataModel
        property var data

        function load(dbDriver){
            clear()
            data = Lib.getClientList(dbDriver).sort((a,b) => { return  a.name < b.name ? -1 : 1; })
            // console.log('[client] data ='+ JSON.stringify(data))
            populate()
        }

        function isAllowed(row, flt){
            return (~(data[row].id.indexOf(flt))
                    || ~(data[row].name.toLowerCase()).indexOf(flt.toLowerCase())
                    || ~(data[row].clnote.toLowerCase()).indexOf(flt.toLowerCase())
                    || ~(data[row].phone.toLowerCase()).indexOf(flt.toLowerCase()));
        }

        function populate( flt =""){
            // console.log('[client] flt =' + flt)
            clear()
            if ((flt === undefined) || flt === "") {
                for (let i =0; i < data.length; ++i) append(data[i])
            } else {
                for (let r =0; r < data.length; ++r){
                    if (isAllowed(r, flt)) {
                        append(data[r])
                    }
                }

            }

        }

        function addNew(dbDriver, name, phone ="", note =""){        // submit
            // console.log("#8943j subm() currentIndex="+currentIndex+" name="+model.get(currentIndex).phone)
            const res = Lib.updClient(dbDriver, "", name, phone, note)
            load(dbDriver)
        }

        function update(dbDriver, row){        // submit
            // console.log("#8943j subm() currentIndex="+currentIndex+" name="+model.get(currentIndex).phone)
            const res = Lib.updClient(dbDriver, get(row).id, get(row).name, get(row).phone, get(row).clnote)
            load(dbDriver)
        }
    }

    Page{
        anchors.fill: parent
        header: ToolBar {
            RowLayout {
                anchors.fill: parent
                Button{
                    id: find
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    visible: findEdit.visible || vw.model.count
                    flat: true
                    icon{name:"find"; source: "qrc:/icon/find.svg"}
//                    contentItem:
//                        Image {
//                                anchors{fill: parent; margins: parent.height/5}
//                        }
                    onClicked: {findEdit.visible = !findEdit.visible}
                }
                TextField{
                    id: findEdit
                    Layout.preferredWidth: 100
                    Layout.preferredHeight: 30
                    selectByMouse: true
                    visible: false
                    onVisibleChanged: {
                        if (visible) { forceActiveFocus() }
                        else {
                            text = ''
                        }
                    }
                    onAccepted: vw.model.populate(text)
                }
                Item{
                    Layout.fillWidth: true
                }

                ToolButton {
                    text: "⋮"
                    onClicked: toolMenu.open()
                    Menu {
                        id: toolMenu
                        y: parent.height
                        MenuItem { action: actionNew; }
                    }
                }
            }

        }

        Pane{
            anchors.fill: parent;
            ColumnLayout{
                anchors.fill: parent;
                Rectangle{
                    id: rectNewClient
                    Layout.fillWidth: true
                    Layout.preferredHeight: childrenRect.height
                    visible: false
                    color: "transparent"
                    ColumnLayout{
                        width: parent.width
                        RowLayout{
                            Label {text:'Name: '}
                            TextField{
                                id: edName
                                placeholderText: "name"
                            }
                        }
                        RowLayout{
                            Label {text:'Phone: '}
                            TextField{
                                id: edPhone
                                placeholderText: "phone"
                            }
                        }
                        RowLayout{
                            Label {text:'Note: '}
                            TextField{
                                id: edNote
                                placeholderText: "note"
                            }
                        }
                        RowLayout{
                            Layout.alignment: Qt.AlignCenter
                            Button{
                                text: "Save"
                                onClicked: vw.model.addNew(db, edName.text, dPhone.text, edNote.text)
                            }
                            Button{
                                action: actionNew
                                text: 'Cancel'
                            }

                        }

                    }
                }

                ListView{
                    id: vw
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 1
                    clip: true
                    focus: true
                    model: dataModel
                    delegate: dlg

    /*                highlight: Rectangle {
                        width: vw.width; height: vw.currentItem.height
                        color: "lightsteelblue"; radius: 5
                        y: vw.currentItem != null ? vw.currentItem.y : vw.y
                        Behavior on y {
                            SpringAnimation {
                                spring: 3
                                damping: 0.2
                            }
                        }
                    }*/
        //            highlightFollowsCurrentItem: false
                        /*            add: Transition {
                        NumberAnimation { properties: "y"; from: 100; duration: 500 }
                    }*/
                }

            }


        }

    }

}

/*
  client request structure
  [{
    "id":"1012",
    "name":"Some Name",
    "fullname":"",
    "phone":"+380xxxxxxxxx",
    "clnote":"/3209",
    "mask":"0",
    "sect":"Клієнти"},
}]
  */



