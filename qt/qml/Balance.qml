import QtQuick
import QtQuick.Controls
// import QtQuick.Controls.Fusion
import QtQuick.Layouts

Window {
    id: root
    width: 720
    height: 720

    property var dbDriver                 // DataBase driver
    onDbDriverChanged: {
        loadAction.trigger()
    }
    property real zero: 0.0000001

    function dbg(str, code ="") {
        console.log( String("%1[Balance] %2").arg(code).arg(str));
    }

    function humanDate(vdate) {
        var vtmp = Date()
        var vdiff = Math.floor(((new Date().getTime())-(new Date(String(vdate).substring(0,10)).getTime()))/(1000*60*60*24))
        if (vdiff === 0) { return vdate.substring(11,16) // Qt.formatDate(new Date(vdate), 'hh:mm')
        } else if (vdiff === 1) { return 'вч '+vdate.substring(11,16)  //Qt.formatDate(new Date(vdate), 'вч hh:mm')
        // } else if (vdiff < 8) { return Math.floor(((new Date().getTime())-(new Date(String(vdate).substring(0,10)).getTime()))/(1000*60*60*24))+' дн.'
        } else if (vdiff < 360) { return Qt.formatDate(new Date(vdate), 'dd MMM')
        } else { return Qt.formatDate(new Date(vdate), 'MMM yy'); /*String(vdate).substring(0,10);*/ }

    }

    Action {
        id: previousAction
        enabled: Number(vcrntEdit.text) > vcrntEdit.validator.bottom
        text: "❮"
        onTriggered: {
            vcrntEdit.text = Number(vcrntEdit.text) -1
            vw.model.populate(vcrntEdit.text)
        }
    }

    Action {
        id: nextAction
        enabled: vw.model !== null && Number(vcrntEdit.text) < vw.model.pager.length +1
        text: "❯"
        onTriggered: {
            vcrntEdit.text = Number(vcrntEdit.text) +1
            vw.model.populate(vcrntEdit.text)
        }
    }

    Action {
        id: loadAction
        icon.source:"qrc:/icon/reload.svg"
        onTriggered: {
            vfilterEdit.text = ""
            // console.log(String("Balance/loadAction \n%1\n%2").arg(cmbBal.currentValue).arg(cmbSort.currentValue))
            vw.model.load(root.dbDriver,cmbBal.currentValue, cmbSort.currentValue)
        }
    }

    ModelBalance{
        id: dataModel
    }

    Component {
        id: dlg
        FocusScope {
            id: dlgroot
            width: dlgroot.ListView.view.width //childrenRect.width;
            height: 28;
            Rectangle{
                width: parent.width
                height: parent.height
                color: "red"
            }

        }
    }

    Page{
        anchors.fill: parent
        Pane{
            anchors.fill: parent;


            ListView{
                id: vw
                anchors.fill: parent
                // property var totalEq: []
                // Layout.fillHeight: true
                // Layout.fillWidth: true
                spacing: 1
                clip: true
                // model: ListModel{ }
                model: dataModel
                delegate:
                    Rectangle{
                        width: vw.width
                        height: childrenRect.height * 1.2
                        // height: 35       //visible ? childrenRect.height+2 : 0
                        clip: true
                        Row{
                            width: parent.width
                            spacing: 5
                           // anchors{fill: parent;}
                            Text{
                                width: 50 // parent.width *0.18 - parent.spacing
                                text: item.id
                            }
                           Text{
                               width: parent.width - 330 -  6 * parent.spacing
                               text: item.itemchar
                               clip: true
                           }
                           Text{
                               width: 50    //parent.width *0.17 - parent.spacing
                               horizontalAlignment: Text.AlignRight
                               // anchors.horizontalCenter: parent.horizontalCenter
                               // text: Math.abs(Number(total))
                               text: Math.abs(Number(total)).toLocaleString(Qt.locale(),'f', Number(item.unitprec))
                               // font.pixelSize: 12
                               color: Number(total) < 0 ? 'red' : 'black'
                           }
                           Text{
                               width: 60    //parent.width *0.15 - parent.spacing
                               horizontalAlignment: Text.AlignRight
                               text: price.toFixed(price < 10 ? 2 : 0)
                               clip: true
                           }
                           Text{
                               width: 50    //parent.width *0.15 - parent.spacing
                               horizontalAlignment: Text.AlignRight
                               text: Math.abs(eq).toLocaleString(Qt.locale(),'f', 0)
                               clip: true
                               color: eq < 0 ? 'red' : 'black'
                           }

                           Text{
                               width: 60    //parent.width *0.15 - parent.spacing
                               horizontalAlignment: Text.AlignRight
                               text: humanDate(intm)
                               clip: true
                           }
                           Text{
                               width: 60    //parent.width *0.15 - parent.spacing
                               horizontalAlignment: Text.AlignRight
                               text: humanDate(outm)
                               clip: true
                           }
                        }
                    }
                section.property: "bind"
                section.criteria: ViewSection.FullString
                section.delegate: Rectangle{
                    width: vw.width
                    height: 30  // childrenRect.height   //*1.2
                    color: "lightgrey" //"silver"
                    Item {
                        anchors{fill: parent;}
                        Row {
                            anchors{fill: parent;leftMargin: 10; rightMargin: 10}
                            spacing: 5
                            Text{
                                width: parent.width - 100 - parent.spacing
                                anchors{verticalCenter: parent.verticalCenter;leftMargin: 50}
                                text:section
                //                    font.bold: true
                                font.pixelSize: 14
                            }
                            Text{
                                width: 100
                                anchors{verticalCenter: parent.verticalCenter;leftMargin: 50}
                                horizontalAlignment: Text.AlignRight
                                text: vw.model.getTotal(section).toLocaleString(Qt.locale(),'f', 0)
                //                    font.bold: true
                                font.pixelSize: 14
                            }

                        }

                    }
                }
            }

        }
        header: ToolBar {
            RowLayout {
                anchors.fill: parent
                ToolButton {
                    action: loadAction
                    // text: "☰"
                    // onClicked: loadAction.trigger()
                    // onClicked: naviMenu.open()
                    // Menu {
                    //     id: naviMenu
                    //     y: parent.height
                    //     // MenuItem { action: actionNew; }
                    // }
                }
                ComboBox{
                    id: cmbBal
                    flat: true
                    Layout.preferredWidth: 150
                    model: ListModel {
                        ListElement { text: "ТОВАР"; code: "300"; }
                        ListElement { text: "БРАК"; code: "302"; }
                        ListElement { text: "TRADE"; code: "3500"; }
                        ListElement { text: "TRADE, гурт"; code: "3501"; }
                    }
                    textRole: 'text'
                    valueRole: 'code'
                    // onCurrentIndexChanged: loadAction.trigger()
                }
                ComboBox{
                    id: cmbSort
                    flat: true
                    model: ListModel {
                        ListElement { text: "код.     ↓"; code: "code_asc"; }
                        ListElement { text: "назва.   ↓"; code: "name_asc"; }
                        ListElement { text: "назва.   ↑"; code: "name_desc"; }
                        ListElement { text: "вартість ↓"; code: "remind_asc"; }
                        ListElement { text: "вартість ↑"; code: "remind_desc"; }
                        ListElement { text: "прихід   ↓"; code: "income_asc"; }
                        ListElement { text: "прихід   ↑"; code: "income_desc"; }
                        ListElement { text: "розхід   ↓"; code: "outcome_asc"; }
                        ListElement { text: "розхід   ↑"; code: "outcome_desc"; }
                    }
                    textRole: 'text'
                    valueRole: 'code'
                    // onCurrentIndexChanged: loadAction.trigger()
                }
                // ToolButton{
                //     id: sortDirection
                //     text:"↑"
                //     checkable: true
                //     // flat: true
                //     onClicked: {
                //         text = (checked ? "↓" : "↑")
                //     }
                // }

                Item{
                    Layout.fillWidth: true
                }

                ToolButton {
                    // id: contextMenu
                    text: "⋮"
                    onClicked: toolMenu.open()
                    Menu {
                        id: toolMenu
                        y: parent.height
                        // MenuItem { action: actionNew; }
                    }
                }
            }

        }


        footer: ToolBar {
            RowLayout {
                anchors{fill: parent;leftMargin:10; rightMargin:10;}
                TextField{
                    id: vfilterEdit
                    Layout.preferredWidth: 100
//                    focus: true
                    selectByMouse: true
                    onActiveFocusChanged: if (activeFocus) {selectAll()}
                    horizontalAlignment: Text.AlignHCenter
                    placeholderText: "filter"
                    // text: vw.vfilter
                    // onAccepted: {
                    onEditingFinished: {
                        vw.model.filterData(text)
                        vcrntEdit.text = 1
                    }
                }
                Item{
                    Layout.fillWidth: true
                }
                RowLayout {
                    ToolButton{ action: previousAction; }
                    TextField{
                        id: vcrntEdit
                        Layout.preferredWidth: 50
    //                    focus: true
                        selectByMouse: true
                        validator: IntValidator {bottom: 1; }
                        onActiveFocusChanged: if (activeFocus) { selectAll(); }
                        horizontalAlignment: Text.AlignHCenter
                        text: "1"
                        // onTextChanged: {
                        onEditingFinished: {
                            if (Number(text) > vw.model.pager.length +1 ) text = vw.model.pager.length +1
                            vw.model.populate(text)
                        }
                    }
                    ToolButton{ action: nextAction; }

                }


                Label{
                    id: footerCount
                    text: String(" з %1").arg(vw.model === null ? 0 : vw.model.pager.length +1)
                }
            }
        }
    }

}
