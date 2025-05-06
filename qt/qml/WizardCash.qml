import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Controls
//import com.vkeeper.sqlmodel 1.0

Window {
    id: root
    width: 300
    height: 540
//    title: qsTr('Cash wizard')
    property string cashAmnt

    signal vkEvent(var event)

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
                        MouseArea{
                            anchors.fill: parent
                            onClicked: {
                                root.ListView.view.currentIndex = index
                                fldQtyEdit.visible = true;
                                fldQtyEdit.forceActiveFocus();
                            }
                        }
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
                                root.ListView.view.model.setProperty(index,'qty', Number(text))
                                root.ListView.view.recalculate()
                                parent.forceActiveFocus()
                                root.ListView.view.currentIndex = -1
                            }
                        }
                    }
                    Label{
                        Layout.preferredWidth: 90
                        horizontalAlignment: Text.AlignHCenter
                        text:(qty*coef).toLocaleString(Qt.locale(),'f',2)
                    }
                }
            }

        }
    }

    Action {
        id: reloadAction
        text: "🔄"
        onTriggered: {
            vkEvent({'id':'loadData', 'crn':cmbMode.model.get(cmbMode.currentIndex).id})
        }
    }
    Action {
        id: clearAction
        text: "⌫"       // ✕ &#x2715
        onTriggered: {
            cashView.model.refreshData();
        }
    }

    Pane{
        anchors.fill: parent
        ColumnLayout{
            anchors.fill: parent
            ComboBox{
                id: cmbMode
                textRole: 'name'
                Layout.fillWidth: true;
    //            currentIndex: -1
                model: ListModel{}
                onCurrentIndexChanged: {
    //                console.log('Cash wizard onCurrentIndexChanged index ='+currentIndex)
                    if (currentIndex != -1 && count!=0){
                        cashView.model.refreshData()
                        vkEvent({'id':'loadData', 'crn':model.get(currentIndex).id})
    //                    refresh()
                    }
                }
                Component.onCompleted: {
                    model.append({ 'id':'', 'code':'UAH', 'name':'українська гривня'})
                    model.append({ 'id':'840', 'code':'USD', 'name':'долар США'})
                    model.append({ 'id':'978', 'code':'EUR', 'name':'ЄВРО'})
                    model.append({ 'id':'985', 'code':'PLN', 'name':'польський злотий'})
                    currentIndex = -1
                    currentIndex = 0
                }
            }

            Rectangle{
                id: resultRect
                Layout.fillWidth: true;
                height: 35  //resultLayout.height*1.2
                color: (cashView.total-Number(cashAmnt)) <0 ? 'mistyrose' : 'honeydew'
                radius: 5
                border.width: 1; border.color: Qt.darker(color,1.5)
                RowLayout{
                    id: resultLayout
                    anchors{fill: parent; margins: 5}
                    Label{anchors.leftMargin: parent.radius; anchors.rightMargin: parent.radius;text: (cashView.total-Number(cashAmnt))<0? qsTr('Shortage:') : qsTr('Surplus:')}
                    Label{
                        id: lblResult; font.pixelSize: 20;
                        Layout.fillWidth: true;
                        text: (cashView.total-Number(cashAmnt)).toLocaleString(Qt.locale(),'f',2)
                        color: (cashView.total-Number(cashAmnt)) <0 ? 'red' : 'green'
                    }
                }
            }


            RowLayout{
                Label{text: qsTr('Should be:')}
                Label{id: lblCash; font.pixelSize: 20; Layout.fillWidth: true; text: Number(cashAmnt).toLocaleString(Qt.locale(),'f',2)}
                ToolButton {
//                    Layout.preferredWidth: 32
//                    Layout.preferredHeight: 32
                    font.pointSize: 14
                    action: reloadAction
                }
                ToolButton {
//                    Layout.preferredWidth: 32
//                    Layout.preferredHeight: 32
                    font.pointSize: 14
                    action: clearAction
                }
            }

            ListView{
                id: cashView
                property real total:0
                property real subTotal:0
                Layout.fillWidth: true
                Layout.fillHeight: true

                clip: true
                model: ListModel{
                    function refreshData(){
                        cashView.model.clear()
                        cashView.total = 0
                        cashView.subTotal = 0
                        if (cmbMode.model.get(cmbMode.currentIndex).code === 'UAH') {
                            cashView.model.append({'name':'1000 грн.','qty':0,'coef':1000, 'sect': 'sub'})
                            cashView.model.append({'name':'500 грн.','qty':0,'coef':500,'sect': 'sub'})
                            cashView.model.append({'name':'200 грн.','qty':0,'coef':200, 'sect': 'sub'})
                            cashView.model.append({'name':'100 грн.','qty':0,'coef':100, 'sect': 'sub'})
                            cashView.model.append({'name':'50 грн.','qty':0,'coef':50, 'sect': 'sub'})
                            cashView.model.append({'name':'20 грн.','qty':0,'coef':20, 'sect': 'sub'})
                            cashView.model.append({'name':'10 грн.','qty':0,'coef':10, 'sect': 'sub'})
                            cashView.model.append({'name':'5 грн.','qty':0,'coef':5, 'sect': 'sub'})
                            cashView.model.append({'name':'2 грн.','qty':0,'coef':2, 'sect': 'sub'})
                            cashView.model.append({'name':'1 грн.','qty':0,'coef':1, 'sect': 'sub'})
                        } else if (cmbMode.model.get(cmbMode.currentIndex).code === 'PLN') {
                            cashView.model.append({'name':'200 pln','qty':0,'coef':200, 'sect': 'sub'})
                            cashView.model.append({'name':'100 pln','qty':0,'coef':100, 'sect': 'sub'})
                            cashView.model.append({'name':'50 pln','qty':0,'coef':50, 'sect': 'sub'})
                            cashView.model.append({'name':'20 pln','qty':0,'coef':20, 'sect': 'sub'})
                            cashView.model.append({'name':'10 pln','qty':0,'coef':10, 'sect': 'sub'})

                        } else if (cmbMode.model.get(cmbMode.currentIndex).code === 'EUR') {
                            cashView.model.append({'name':'500 eur','qty':0,'coef':500, 'sect': 'sub'})
                            cashView.model.append({'name':'200 eur','qty':0,'coef':200, 'sect': 'sub'})
                            cashView.model.append({'name':'100 eur','qty':0,'coef':100, 'sect': 'sub'})
                            cashView.model.append({'name':'50 eur','qty':0,'coef':50, 'sect': 'sub'})
                            cashView.model.append({'name':'20 eur','qty':0,'coef':20, 'sect': 'sub'})
                            cashView.model.append({'name':'10 eur','qty':0,'coef':10, 'sect': 'sub'})
                            cashView.model.append({'name':'5 eur','qty':0,'coef':5, 'sect': 'sub'})
                        } else if (cmbMode.model.get(cmbMode.currentIndex).code === 'USD') {
                            cashView.model.append({'name':'100 usd','qty':0,'coef':100, 'sect': 'sub'})
                            cashView.model.append({'name':'50 usd','qty':0,'coef':50, 'sect': 'sub'})
                            cashView.model.append({'name':'20 usd','qty':0,'coef':20, 'sect': 'sub'})
                            cashView.model.append({'name':'10 usd','qty':0,'coef':10, 'sect': 'sub'})
                            cashView.model.append({'name':'5 usd','qty':0,'coef':5, 'sect': 'sub'})
                        }

                        cashView.model.append({'name':'Сейф 1','qty':0,'coef':1, 'sect': ''})
                        cashView.model.append({'name':'Сейф 2','qty':0,'coef':1, 'sect': ''})
                        cashView.model.append({'name':'Збірна','qty':0,'coef':1, 'sect': ''})
                        cashView.model.append({'name':'Пошкодж.','qty':0,'coef':1, 'sect': ''})
                    }
                }
                delegate: wcdlg
                function recalculate(){
                    total = 0; subTotal = 0;
                    for (var r =0; r < model.count; ++r) {
                        total += Number(model.get(r).qty*Number(model.get(r).coef))
                        if (model.get(r).sect === 'sub') { subTotal += Number(model.get(r).qty*Number(model.get(r).coef)) }
                    }
                }
            }
            RowLayout{
                Item{Layout.fillWidth: true; }
                Label{text: 'Хвіст:' /*qsTr('Subtotal:')*/}
                Label{font.pixelSize: 14; text: cashView.subTotal.toLocaleString(Qt.locale(),'f',2)}

            }

            RowLayout{
                Label{text: 'Всього:' /*qsTr('Total:')*/}
                Label{id: lblTotal; font.pixelSize: 20; Layout.fillWidth: true; text: cashView.total.toLocaleString(Qt.locale(),'f',2)}
            }
        }

    }




    Component.onCompleted: {/*cmbMode.currentIndex=0*/}


}
