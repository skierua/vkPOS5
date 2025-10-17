import QtQuick
import QtQuick.Controls
// import QtQuick.Controls.Fusion
import QtQuick.Layouts

Window {
    id: root
    width: 200
    height: 400

    property string uri
    property var queryData  // {"term":term,"reqid":"sel","shop":root.term}
    property var db                 // DataBase driver
    onDbChanged: {
        vw.model.populate(db)
        vw.model.loadWebRates(uri, queryData)
    }
    property real zero: 0.0000001

    signal vkEvent(string id, var param)

    ModelRates{
        id: data
        onVkEvent: (id, param) => {
            if (id === 'log'){
                logView.append("[ModelRates] " + param, 2)
            } else if (id === 'err') {
                logView.append("[ModelRates] " + param, 0)
            } else {
                logView.append("[ModelRates] BAD event !!!", 1)
            }

        }
    }

    Component {
        id: dlg
        FocusScope {
            id: root
            width: root.ListView.view.width //childrenRect.width;
            height: 28;
//            color: (index==root.ListView.view.currentIndex?"PaleGreen":(index%2 == 0 ?  "white" : 'HoneyDew'))
            // color: (index%2 == 0 ?  "whitesmoke" : 'white')
//            color: (index%2 == 0 ?  "PaleGreen" : 'Aquamarine')
//            color: (index%2 == 0 ?  Qt.darker('white',1.03) : 'white')
                MouseArea{
                    anchors.fill: parent
                    onClicked: { root.ListView.view.currentIndex=index; }
                }

            Row{
                anchors.fill: parent
                Label{          // bid
                    width: parent.width*0.35;
                    height: parent.height
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    text: Number(lbid)!==0 ? Number(lbid).toFixed(Number(lbid)<10?3:2) : "" //(bid==''||Number(bid)===0)?'':bid+"/"+lbid
                    font.bold: Math.abs(Number(bid)-Number(lbid))>zero
/*                    MouseArea{
                        anchors.fill: parent
                        hoverEnabled :true
                        onClicked: { bidedit.visible = true; bidedit.text=lbid; bidedit.forceActiveFocus() }
                    }
                    TextField{
                        id: bidedit
                        anchors.fill: parent
                        visible: false
                        selectByMouse: true
                        validator: DoubleValidator {bottom: 0; decimals: 4; notation: "StandardNotation"; locale: "en_US" }
                        onActiveFocusChanged: if (activeFocus) {selectAll()} else {visible = false}
                        onAccepted: {
                            if ((Number(text)===0) || (Math.abs((Number(text)-Number(lbid))/Number(lbid)) < 0.04)) { lbid = text
                            } else { text = lbid } // error
                            // root.forceActiveFocus()
                        }
                    }*/
                }
                Label{      // currency name
                    width: parent.width*0.3;height:parent.height;
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    text:(qty==='1'?'':(qty+' ')) + curchar
                    font.bold: (Math.abs(Number(bid)-Number(lbid))>zero) || (Math.abs(Number(ask)-Number(lask))>zero)
                    MouseArea{
                        anchors.fill: parent
                        hoverEnabled :true
                        ToolTip{
                            id: rateToolTip
                            width: 150
                            visible: false
                            delay: 1000
                            timeout: 5000
                            text: 'код: '+ curid+'\n' + curname+'\n'+'к-сть: '+ qty
                                + String("\nсайт: %1/%2").arg(bid===""?"--":bid).arg(ask===""?"--":ask)
                                + String("\nпопередні: %1/%2").arg(dfltbid===""?"--":dfltbid).arg(dfltask===""?"--":dfltask)
                        }
                        onEntered: {rateToolTip.visible = true}
                        onExited: rateToolTip.visible = false
                        onDoubleClicked: { root.ListView.view.newDoc(index); }
                    }
                }
                Label{      // ask
                    width: parent.width*0.35;
                    height: parent.height
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    text: Number(lask)!==0 ? Number(lask).toFixed(Number(lask)<10?3:2) : ""
                    font.bold: Math.abs(Number(ask)-Number(lask))>zero
                    font.underline: lask !== dfltask
/*                    MouseArea{
                        anchors.fill: parent
                        hoverEnabled :true
                        onClicked: { askedit.visible = true; askedit.text=lask; askedit.forceActiveFocus() }
                    }
                    TextField{
                        id: askedit
                        anchors.fill: parent
                        visible: false
                        selectByMouse: true
                        validator: DoubleValidator {bottom: 0; decimals: 4; notation: "StandardNotation"; locale: "en_US" }
                        onActiveFocusChanged: if (activeFocus) {selectAll()} else {visible = false}
                        onAccepted: {
                            if ((Number(text)===0) || (Math.abs((Number(text)-Number(lask))/Number(lask)) < 0.04)) { lask = text
                            } else { text = lask } // error
                            // root.forceActiveFocus()
                        }
                    } */
                }
            }
        }
    }

    Action{
        id: getWebAction
        text: "Курси з сайту"
        onTriggered: vw.model.loadWebRates(queryData)
    }

    Action{
        id: saveWebAction
        text: "Встановити з сайту"
        onTriggered: vw.model.updateLocalRates(db);
    }

    Pane{
        anchors{fill: parent;}
        ColumnLayout{
            anchors{fill: parent; }
            ListView{
                id: vw
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: data
                // model: ListModel{}
                header:
                    Row{
                        width: vw.width
                        height: 20
                        Label{
                            width: parent.width*0.35-parent.spacing
                            height: parent.height
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignHCenter
                            color: 'dimgrey'
                            text: 'СКУП'
                        }
                        Label{
                            width: parent.width*0.30;
                            height: parent.height
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignHCenter
                            color: 'dimgrey'
                            text: 'ВАЛ'
                        }
                        Label{
                            width: parent.width*0.35-parent.spacing
                            height: parent.height
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignHCenter
                            color: 'dimgrey'
                            text: 'ПРОД'
                        }

                    }

                delegate: dlg

                function newDoc(vi){ vkEvent("rate.newDocum", jscur[vi].curid); }
            }

            Button{
                id: loadBtn
                Layout.fillWidth: true
                action: getWebAction
            }

            Button{
                id: saveBtn
                Layout.fillWidth: true
                action: saveWebAction
            }

            LogView{
                id: logView
                Layout.fillWidth: true
                Layout.preferredHeight: count * 25
                Layout.maximumHeight: parent.height / 4
            }

        }

    }

}
