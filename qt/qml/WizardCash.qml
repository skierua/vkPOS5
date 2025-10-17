import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Controls
//import com.vkeeper.sqlmodel 1.0

import "../lib.js" as Lib

Window {
    id: root
    width: 300
    height: 540

    property var db                 // DataBase driver
    onDbChanged: view.model.getCash()

    // signal vkEvent(string id, var param)

    onVisibleChanged: {cmbMode.forceActiveFocus()}


    Component {
        id: wcdlg
        FocusScope{
            id: root
            width: childrenRect.width;
            height: childrenRect.height
            Rectangle{
                width: root.ListView.view.width
                height: root.ListView.view.currentIndex === index ? 30 : 24
                color: index%2 ? "white" : "whitesmoke"
                RowLayout{
                    anchors.verticalCenter: parent.verticalCenter
                    Label{
                        Layout.preferredWidth: 80
                        text:name
                    }
                    Label{
                        Layout.preferredWidth: 70
                        horizontalAlignment: Text.AlignHCenter
//                        clip: true
                        text:qty.toLocaleString(Qt.locale(),'f',0)
                        TextField{
                            id: fldQtyEdit
                            anchors.centerIn: parent
//                            z: parent.z+2
                            width: parent.width
                            height: 30
                            visible: false
                            selectByMouse: true
                            validator: DoubleValidator {bottom: 0; decimals: 0; notation: "StandardNotation"; locale: "en_US" }
                            onActiveFocusChanged: if (activeFocus) {selectAll()} else {visible = false}
                            onAccepted: {
                                root.ListView.view.model.setQty(index, text)
                                parent.forceActiveFocus()
                            }
                        }
                    }
                    Label{
                        Layout.preferredWidth: 90
                        horizontalAlignment: Text.AlignHCenter
                        text:(qty * coef).toLocaleString(Qt.locale(),'f',0)
                    }
                }
                MouseArea{
                    anchors.fill: parent
                    onClicked: {
                        root.ListView.view.currentIndex = index
                        fldQtyEdit.visible = true;
                        fldQtyEdit.forceActiveFocus();
                    }
                }
            }

        }
    }

    Action {
        id: reloadCashAction
        text: "🔄"
        onTriggered:  view.model.getCash()
    }

    Action {
        id: clearAction
        text: "⌫"       // ✕ &#x2715
        onTriggered:  view.model.erase();
    }

    ListModel{
        id: cmbModel
        Component.onCompleted: {
            append({ 'id':'', 'code':'UAH', 'name':'українська гривня'})
            append({ 'id':'840', 'code':'USD', 'name':'долар США'})
            append({ 'id':'978', 'code':'EUR', 'name':'ЄВРО'})
            append({ 'id':'985', 'code':'PLN', 'name':'польський злотий'})
        }
    }

    ListModel{
        id: dataModel
        property real cash: 0
        property real total: 0
        property real subTotal: 0

        property string cur: ""
        onCurChanged: populate()

        function populate(){
            clear()
            total = 0
            subTotal = 0
            if (cur === '') {
                append({'name':'1000 грн.','qty':0,'coef':1000, 'sect': 'sub'})
                append({'name':'500 грн.','qty':0,'coef':500,'sect': 'sub'})
                append({'name':'200 грн.','qty':0,'coef':200, 'sect': 'sub'})
                append({'name':'100 грн.','qty':0,'coef':100, 'sect': 'sub'})
                append({'name':'50 грн.','qty':0,'coef':50, 'sect': 'sub'})
                append({'name':'20 грн.','qty':0,'coef':20, 'sect': 'sub'})
                append({'name':'10 грн.','qty':0,'coef':10, 'sect': 'sub'})
                append({'name':'5 грн.','qty':0,'coef':5, 'sect': 'sub'})
                append({'name':'2 грн.','qty':0,'coef':2, 'sect': 'sub'})
                append({'name':'1 грн.','qty':0,'coef':1, 'sect': 'sub'})
            } else if (cur === '985') {
                append({'name':'200 pln','qty':0,'coef':200, 'sect': 'sub'})
                append({'name':'100 pln','qty':0,'coef':100, 'sect': 'sub'})
                append({'name':'50 pln','qty':0,'coef':50, 'sect': 'sub'})
                append({'name':'20 pln','qty':0,'coef':20, 'sect': 'sub'})
                append({'name':'10 pln','qty':0,'coef':10, 'sect': 'sub'})

            } else if (cur === '978') {
                append({'name':'500 eur','qty':0,'coef':500, 'sect': 'sub'})
                append({'name':'200 eur','qty':0,'coef':200, 'sect': 'sub'})
                append({'name':'100 eur','qty':0,'coef':100, 'sect': 'sub'})
                append({'name':'50 eur','qty':0,'coef':50, 'sect': 'sub'})
                append({'name':'20 eur','qty':0,'coef':20, 'sect': 'sub'})
                append({'name':'10 eur','qty':0,'coef':10, 'sect': 'sub'})
                append({'name':'5 eur','qty':0,'coef':5, 'sect': 'sub'})
            } else if (cur === '840') {
                append({'name':'100 usd','qty':0,'coef':100, 'sect': 'sub'})
                append({'name':'50 usd','qty':0,'coef':50, 'sect': 'sub'})
                append({'name':'20 usd','qty':0,'coef':20, 'sect': 'sub'})
                append({'name':'10 usd','qty':0,'coef':10, 'sect': 'sub'})
                append({'name':'5 usd','qty':0,'coef':5, 'sect': 'sub'})
            }

            append({'name':'Сейф 1','qty':0,'coef':1, 'sect': ''})
            append({'name':'Сейф 2','qty':0,'coef':1, 'sect': ''})
            append({'name':'Збірна','qty':0,'coef':1, 'sect': ''})
            append({'name':'Пошкодж.','qty':0,'coef':1, 'sect': ''})
            if (db !== undefined) getCash()
        }

        function getCash(){
            cash = Number(Lib.getSQLData(db,
                                         String("select item, beginamnt+turndbt-turncdt as total from acnt where item %1")
                                                .arg(cur === '' ? 'is null' : String("= '%1'").arg(cur)))[0].total)
        }

        function result(){
            return total - cash;
        }

        function recalculate(){
            let total_ = 0;
            let subTotal_ = 0;
            for (let r =0; r < count; ++r) {
                total_ += Number(get(r).qty * Number(get(r).coef))
                if (get(r).sect === 'sub') { subTotal_ += Number(get(r).qty*Number(get(r).coef)) }
            }
            total = total_;
            subTotal = subTotal_;
        }

        function erase(){
            for (let r =0; r < count; ++r) setProperty(r,'qty', 0)
            recalculate()
        }

        function setQty(row, val){
            setProperty(row,'qty', Number(val))
            recalculate()
        }

        Component.onCompleted: populate()
    }

    Pane{
        anchors.fill: parent
        ColumnLayout{
            anchors.fill: parent
            ComboBox{
                id: cmbMode
                textRole: 'name'
                Layout.fillWidth: true;
                currentIndex: 0
                model: cmbModel
                onCurrentIndexChanged: {
                    // console.log('Cash wizard onCurrentIndexChanged index ='+currentIndex + " count="+ count)
                    if (currentIndex !== -1 && count !== 0) dataModel.cur = model.get(currentIndex).id
                }
            }

            Rectangle{
                id: resultRect
                Layout.fillWidth: true;
                height: 35  //resultLayout.height*1.2
                color: view.model.result() < 0 ? 'mistyrose' : 'honeydew'
                radius: 5
                border.width: 1; border.color: Qt.darker(color,1.5)
                RowLayout{
                    id: resultLayout
                    anchors{fill: parent; margins: 5}
                    Text{
                        anchors{leftMargin: parent.radius; rightMargin: parent.radius;}
                        text: view.model.result() < 0 ? 'Нестача:' : 'Лишки:'
                    }
                    // Label{anchors.leftMargin: parent.radius; anchors.rightMargin: parent.radius;text: view.model.result() < 0 ? qsTr('Shortage:') : qsTr('Surplus:')}
                    Text{
                        font.pixelSize: 20;
                        Layout.fillWidth: true;
                        text: view.model.result().toLocaleString(Qt.locale(),'f',2)
                        color: view.model.result() < 0 ? 'red' : 'green'
                    }
                }
            }


            RowLayout{
                Label{text: qsTr('Should be:')}
                Text{font.pixelSize: 20; Layout.fillWidth: true; text: view.model.cash.toLocaleString(Qt.locale(),'f',2)}
                ToolButton {
                    font.pointSize: 14
                    action: reloadCashAction
                }
                ToolButton {
                    font.pointSize: 14
                    action: clearAction
                }
            }

            ListView{
                id: view
                Layout.fillWidth: true
                Layout.fillHeight: true

                clip: true
                model: dataModel
                delegate: wcdlg
            }

            RowLayout{
                Item{Layout.fillWidth: true; }
                Label{text: 'Хвіст:' /*qsTr('Subtotal:')*/}
                Text{font.pixelSize: 14; text: view.model.subTotal.toLocaleString(Qt.locale(),'f',0)}

            }

            RowLayout{
                Label{text: 'Всього:' /*qsTr('Total:')*/}
                Text{font.pixelSize: 20; Layout.fillWidth: true; text: view.model.total.toLocaleString(Qt.locale(),'f',0)}
            }
        }

    }

    // Component.onCompleted: {/*cmbMode.currentIndex=0*/}

}
