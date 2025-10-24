import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item{
    id: root
    width: 300
    height: 480
    // anchors{fill: parent}
//    property string mode: "cash"
    property var dbDriver                 // DataBase driver

    signal vkEvent(string id, var param)

    onVisibleChanged: {
        if (visible) viewCashAction.trigger()
        else drawerModel.data = []
    }

    ModelDrawer{
        id: drawerModel
    }

    Action{
        id: viewCashAction
        text: "Каса"
        onTriggered: drawerModel.load(dbDriver, ["30"], 3)
    }

    Action{
        id: viewDebtAction
        text: "Дебітори"
        onTriggered: drawerModel.load(dbDriver, ["36", "38", "42"], 3, true)
    }

    Action{
        id: viewTradeAction
        text: "TRADE"
        onTriggered: drawerModel.load(dbDriver, [35], 3, true)
    }

    Action{
        id: viewArticleAction
        text: "Товар"
        onTriggered: drawerModel.load(dbDriver, ["3000"], 4, false)
    }

    Action{
        id: viewDeffectiveAction
        text: "Брак"
        onTriggered: drawerModel.load(dbDriver, ["3020"], 4, false)
    }

//    color: 'lightgray'
    ColumnLayout{
        anchors{fill: parent;}
        spacing: 1
        RowLayout{
            Button{
                Layout.fillWidth: true
                action: viewCashAction
            }
            Button{
                Layout.fillWidth: true
                action: viewDebtAction
            }
            Button{
                Layout.fillWidth: true
                action: viewTradeAction
            }

        }
        RowLayout{
            TextField{
                id: filterEdit
                Layout.fillWidth: true
                font.pixelSize: 12
                selectByMouse: true
                placeholderText: 'фільтр'
                // color: text===''?'lightgray':'black'
               onAccepted: drawerModel.filterData(text)
            }
            Button{
                Layout.fillWidth: true
                action: viewArticleAction
            }
            Button{
                Layout.fillWidth: true
                action: viewDeffectiveAction
            }

        }

        Rectangle{
            id: debtMsg
            Layout.fillWidth: true
            Layout.preferredHeight: 20
            visible: false
            color: 'ivory'
            Label{
                anchors.horizontalCenter: parent.horizontalCenter
                color: 'red'
                text: 'Червоним борг клієнта'

            }

        }

        ListView{
            id: vw
            property var totalEq: []
            Layout.fillHeight: true
            Layout.fillWidth: true
            spacing: 1
            clip: true
            // model: ListModel{ }
            model: drawerModel
            delegate:
                Rectangle{
                    width: vw.width
                    height: 35       //visible ? childrenRect.height+2 : 0
                    clip: true
                    Row{
                        anchors{fill: parent; leftMargin: 5; rightMargin: 5;}
                        Column{
                            width: parent.width *0.6 - parent.spacing
                            anchors.verticalCenter: parent.verticalCenter
//                                    spacing: 0
                            clip: true
                            Text{
                                text: name + (clchar !== "" ? String(" %1[%2]").arg(clchar).arg(clid) : "")
                                font.pixelSize: 12
                            }
                            Text{text: subname; font.pixelSize: 10; color: 'grey'; }
                        }
                        Column{
                            width: parent.width *0.4
                            anchors.verticalCenter: parent.verticalCenter
//                                    spacing: 0
                            Text{
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: Math.abs(Number(total)).toLocaleString(Qt.locale(),'f', Number(prec))
                                font.pixelSize: 12
                                color: Number(total) < 0 ? 'red' : 'black'
                            }
                            Row{
                                width: parent.width
                                spacing: 5
//                                        Item{
                                    Text{
                                        width: (parent.width - parent.spacing)/2
//                                                anchors.verticalCenter: parent.verticalCenter
                                        horizontalAlignment: Text.AlignHCenter
                                        text: Number(income)===0 ? "" : Number(income).toLocaleString(Qt.locale(),'f',Number(prec))
                                        font.pixelSize: 8
                                        color: 'grey'
                                    }
//                                        }
//                                        Item{
                                    Text{
                                        width: (parent.width - parent.spacing)/2
//                                                anchors.horizontalCenter: parent.horizontalCenter
                                        horizontalAlignment: Text.AlignHCenter
                                        text: Number(outcome)===0 ? "" : Number(outcome).toLocaleString(Qt.locale(),'f',Number(prec))
                                        font.pixelSize: 8
                                        color: 'grey'
                                    }
//                                        }


                            }

                        }
                    }
                    // MouseArea{
                    //     anchors.fill: parent
                    //     onDoubleClicked: { vkEvent("rowDClicked",{"atcl":key, "clid":clid, "acnt":ano, "mask":mask, "amnt":Number(total).toFixed(prec) }); }
                    // }
                }
            section.property: "bind"
            section.criteria: ViewSection.FullString
            section.delegate: Rectangle{
                width: vw.width
                height: 30  // childrenRect.height   //*1.2
                color: "silver"
                Text{
                    anchors.verticalCenter: parent.verticalCenter
                    text:'  '+section
//                    font.bold: true
                    font.pixelSize: 14
                }
            }
        }
    }
}
