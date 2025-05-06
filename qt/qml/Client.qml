import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Controls

Window {
    id: root
    width: 240
    height: 480
//    title: qsTr('Clients')
    property var jdata
    onJdataChanged: {
       // console.log('onDcmListChanged')
        rectNewClient.visible = false
        edName.text = ''
        edPhone.text = ''
        edNote.text = ''
        vw.vpopulate()
    }

    signal vkEvent(string id, var param)

    Action{
        id: actionNew
        text: qsTr("Новий клієнт")
        onTriggered: rectNewClient.visible = !rectNewClient.visible
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
//                 MouseArea{
// //                    anchors.fill: parent;
//                     width: (index === root.ListView.view.currentIndex)?0:parent.width
//                     height: (index === root.ListView.view.currentIndex)?0:parent.height
//                     onClicked: {
//                         root.ListView.view.currentIndex = index;
//                     }
//                 }
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
                        if (ok){ root.ListView.view.subm()
                            // vkEvent('client.submit', {'id':id, 'name':name, 'note':clnote, 'phone':phone})
                        }
                        visible= false

                        // root.ListView.view.forceActiveFocus()
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
//                            vw.model.vpopulate()
                        }
                    }
                }
                Item{
                    Layout.fillWidth: true
                }

                ToolButton {
                    text: qsTr("⋮")
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
                                onClicked: {
                                    vkEvent('client.submit', {'id':'', 'name':edName.text, 'note':edNote.text, 'phone':edPhone.text})
                                }
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
                    property alias vfilter: findEdit.text
                    onVfilterChanged: vpopulate()
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 1
                    clip: true
                    focus: true
                    model: ListModel{}
                    delegate: dlg
                    function vpopulate(){
                        currentIndex = -1
                        model.clear()
                        var r = 0
                        var i = 0
                        for (r =0; r < jdata.length; ++r){
                            if ((vfilter == undefined) || vfilter === ''
                                    || ~(jdata[r].id.indexOf(vfilter))
                                    || ~(jdata[r].name.toLowerCase()).indexOf(vfilter.toLowerCase())
                                    || ~(jdata[r].clnote.toLowerCase()).indexOf(vfilter.toLowerCase())
                                    || ~(jdata[r].phone.toLowerCase()).indexOf(vfilter.toLowerCase())) {
                                model.append(jdata[r])
                            }
                        }
                        if (model.count){ currentIndex = 0; }
        //                forceActiveFocus()
                    }

                    function subm(){        // submit
                        // console.log("#8943j subm() currentIndex="+currentIndex+" name="+model.get(currentIndex).phone)

                        vkEvent('client.submit', {'id':model.get(currentIndex).id, 'name':model.get(currentIndex).name, 'note':model.get(currentIndex).clnote, 'phone':model.get(currentIndex).phone})
                    }
                    // onCurrentIndexChanged: console.log("#a7h currentIndex="+currentIndex+" name="+model.get(currentIndex).phone)

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
