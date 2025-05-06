import QtQuick
import QtQuick.Controls
// import QtQuick.Controls.Fusion
import QtQuick.Layouts

Item {
    id: root
    width: 640  //parent.width *0.5
    height: 250 //parent.height *0.3
    property string title: "Зміна"
    property string codeid: "shift"
    // property Menu vkContentMenu: Menu{
    // }
    property var vshift //: { "id":0,"cshr":"","cshrname":"","errid":1,"errname":"","shftbegin":"","shftdate":"","shftend":""}
        onVshiftChanged: shftStack.currentIndex = (vshift.shftend === "" ? 1 : 0)
    property bool toBulk: false

    // property var vincas: []
    property var vcashiers: []
        // onVcashiersChanged: {
        //     let r=0;
        //     // cmb.currentIndex = -1;
        //     cmb.model.clear()
        //     vw.model.clear()

        //     cmb.model.append({"code":"", "note":"без касира", "psw":""})
        //     for(r=0; r< vcashiers.length; ++r) {
        //         cmb.model.append(vcashiers[r])
        //         if (vcashiers[r].code === vshift.cshr) { cmb.currentIndex = r+1; }
        //         // console.log("#1wh code="+vcashiers[r].code+"i="+i+" r="+r)
        //     }
        // }

    signal vkEvent(string id, var param)

    function vpopulate( /*vcshr, */vtrades) {
        // console.log("#366 shift, trades="+vtrades)
        vw.model.clear()
        let vam = 0
        // var lmrow = ({})
        // var lm = []
        for (let r =0; vtrades !=='' && r < vtrades.length; ++r){
            // if (Number(vtrades[r].amnt) !== 0 || Number(vtrades[r].eqamnt) !== 0 ) {
            //     lmrow = vtrades[r]
            //     lmrow.incas = String(0 - Number(vtrades[r].amnt))
            //     // lm.push(lmrow);
                vw.model.append(vtrades[r])
            // }
            vam += Math.abs(Number(vtrades[r].amnt))
        }
        // vw.model = lm
        vw.amntTotal = vam;
        // console.log("#74y shift vtrades="+JSON.stringify(vw.model))
        root.state = (vshift.shftend === "" ? "closeState" : "")
    }

    StackLayout {
        id: shftStack
        anchors.centerIn: parent
        // spacing: 10
        GroupBox{
            id: openGroup
            title: "Нова зміна"
            ColumnLayout {
                RowLayout {
                    spacing: 10

                    Label {
                        text: qsTr("Login:")
                    }

                    ComboBox {
                        id: cmb
                        textRole: "note"
                        valueRole: "code"
                        model: root.vcashiers   // ListModel{}
                        Layout.fillWidth: true
                        onCurrentIndexChanged: {
                            psw.text = ""
                            actionStart.enabled = (cmb.currentIndex === 0)
                        }
                    }
                }
                RowLayout {
                    spacing: 10

                    Label { text: qsTr("Password:") }
                    TextField{
                        id: psw
                        echoMode: TextInput.Password      // PasswordEchoOnEdit
                        // onTextChanged: actionStart.enabled = (text === Qt.atob(cmb.model.get(cmb.currentIndex).psw) )
                        onAccepted: {
                            actionStart.enabled = (cmb.model.get(cmb.currentIndex).psw === "" || text === Qt.atob(cmb.model.get(cmb.currentIndex).psw) )
                            if (actionStart.enabled) {actionStart.trigger(); }
                        }
                    }
                }
                Label{
                    Layout.preferredHeight: 30
                    Layout.fillWidth: true
                    text: "Попередню зміну закрито"
                }
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    // anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 10
                    Button{
                        action: actionCancel
                        // text: "Cancel"
                        // focus: true
                        // onClicked: vkEvent('shift.cancel', "");
                    }
                    Button{
                        id: openBtn
                        action: actionStart
                        // text: "Нова зміна"
                        // onClicked: vkEvent('open', cmb.currentValue);
                    }
                }

            }
        }

        GroupBox{
            id: closeGroup
            // width: parent.width
            // height: childrenRect.height
            padding: 10
            // visible: false
            title: "Поточна зміна"
            ColumnLayout {

                RowLayout{
                    spacing: 5
                    ColumnLayout {
                        Layout.rightMargin: 10
                        RowLayout{
                            Label {text: "Id: " }
                            Label {id:shid; text:root.vshift.id }
                        }
                        Label { id:shcshr; text:"Касир: "+ root.vshift.cshrname }
                        RowLayout{
                            Label {text: "Дата: " }
                            Label {id:shdate; text: root.vshift.shftdate;}
                        }
                        Label {id:shopen; text:"Відкрито: "+ root.vshift.shftbegin}
                        Label {id:shclose; text: "Закрито: "+ root.vshift.shftend}
                        Label{
                            id: redyToCloseAlert
                            visible: (root.state === "closeState" && root.toBulk && vw.amntTotal > 0.5)
                            text: "\n  Не проведено інкасацію !!!  \n"
                            background:  Rectangle{
                                radius: 3
                                color: "pink"
                            }
                        }
                    }
                    Rectangle{
                        // visible: vw.count
                        Layout.fillHeight: true
                        // Layout.fillWidth: true
                        // Layout.preferredHeight: 100
                        Layout.preferredWidth: 400
                        clip: true
                        ListView{
                            id: vw
                            anchors{fill: parent; margins:5;}
                            property real amntTotal
                            property real curw: 0.15*width-5
                            property real amnw: 0.15*width-5
                            property real incw: 0.15*width-5
                            property real resw: 0.15*width-5
                            property real priw: 0.25*width-5
                            property real prow: 0.15*width
                            header:Row{
                                width:vw.width
                                spacing: 5
                                Label{ width:vw.curw; text:"вал"; }
                                Label{ width:vw.amnw; text:"знач"; horizontalAlignment: Qt.AlignHCenter; }
                                Label{ width:vw.incw; text:"інкас"; horizontalAlignment: Qt.AlignHCenter; }
                                Label{ width:vw.resw; text:"залиш"; horizontalAlignment: Qt.AlignHCenter; }
                                Label{ width:vw.priw; text:"курс"; horizontalAlignment: Qt.AlignHCenter; }
                                Label{ width:vw.prow; text:"дохід"; horizontalAlignment: Qt.AlignHCenter; }
                            }
                            model: ListModel{}
                            delegate:
                                FocusScope{
                                    property string test: 'for testing'
                                    width: childrenRect.width;
                        //            width: root.ListView.view.width;
                                    height: 20  //childrenRect.height;
                                Row{
                                    width:vw.width
                                    spacing: 5
                                    Label{ width:vw.curw; text:(qty==="1"?"":(qty)) + cur; }
                                    Label{ width:vw.amnw; text:Math.abs(amnt); horizontalAlignment: Qt.AlignRight; color:Number(amnt)<0?"red":"black";}
                                    Label{ width:vw.incw; text:Math.abs(incas); horizontalAlignment: Qt.AlignRight; color:Number(incas)<0?"red":"black";}
                                    Label{ width:vw.resw; text:Number(amnt)+Number(incas); horizontalAlignment: Qt.AlignRight; color:Number(Number(amnt)+Number(incas))<0?"red":"black";}
                                    Label{ width:vw.priw; text:Number(price).toFixed(2); horizontalAlignment: Qt.AlignRight;}
                                    Label{
                                        width:vw.prow;
                                        color:(Number(price)*Number(amnt)/Number(qty)-Number(eqamnt))<0?"red":"black";
                                        text:Math.abs(Number(price)*Number(amnt)/Number(qty)-Number(eqamnt)).toFixed(0);
                                        horizontalAlignment: Qt.AlignRight;
                                    }
                                }
                                MouseArea{
                                    anchors.fill: parent
                                    onDoubleClicked: {
                                        // console.log("#94yb index="+index)
                                        incasRateEdit.incasid = index
                                        incasRateEdit.visible = true
                                    }
                                }
                            }
                        }
                        Rectangle{
                            id: incasRateEdit
                            property int incasid
                            width: parent.width
                            height: parent.height*0.7
                            anchors.centerIn: parent
                            radius: 5
                            visible: false
                            color: "lightgrey"
                            RowLayout{
                                spacing: 10
                                ColumnLayout{
                                    // anchors.centerIn: parent
                                    // Label { text: "Змінити курс" }
                                    Label { text: "Сума:" }
                                    TextField{
                                        focus: true
                                        selectByMouse: true
                                        validator: DoubleValidator {
                                            /*decimals: 2; */notation: "StandardNotation"; locale: "en_US" }
                                        onActiveFocusChanged: if (activeFocus) {selectAll()}
                                        horizontalAlignment: Text.AlignHCenter
                                        font.pixelSize: 18
                                        text: visible ? Number(vw.model.get(incasRateEdit.incasid).incas) : ""
                                        onEditingFinished: { vw.model.setProperty(incasRateEdit.incasid,"incas",text); }
                                        onAccepted: { incasRateEdit.visible = false; }
                                    }
                                }
                                ColumnLayout{
                                    // anchors.centerIn: parent
                                    // Label { text: "Змінити курс" }
                                    RowLayout{
                                        spacing: 10
                                        Label { text: "Курс:" }
                                        Label { text: visible ? vw.model.get(incasRateEdit.incasid).cur : "" }
                                    }
                                    TextField{
                                        focus: true
                                        selectByMouse: true
                                        validator: DoubleValidator {
                                            bottom: incasRateEdit.visible ? Number(vw.model.get(incasRateEdit.incasid).price) * 0.98 : 0;
                                            top: incasRateEdit.visible ? Number(vw.model.get(incasRateEdit.incasid).price) * 1.02 : 0;
                                            decimals: 4; notation: "StandardNotation"; locale: "en_US" }
                                        onActiveFocusChanged: if (activeFocus) {selectAll()}
                                        horizontalAlignment: Text.AlignHCenter
                                        font.pixelSize: 18
                                        text: visible ? Math.abs(Number(vw.model.get(incasRateEdit.incasid).price)) : ""
                                        onEditingFinished: { vw.model.setProperty(incasRateEdit.incasid,"price",text); }
                                        onAccepted: { incasRateEdit.visible = false; }
                                    }
                                }
                            }
                        }
                    }
                }
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    // anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 10
                    Button{
                        action: actionCancel
                        // text: "Cancel"
                        // focus: true
                        // onClicked: vkEvent('shift.cancel', "");
                    }
                    Button{
                        id: closeBtn
                        text: "Закрити зміну"
                        // visible: false
                        enabled: vw.amntTotal < 1 || !root.toBulk
                        onClicked: vkEvent('shift.close', {"shid":shid.text,"shdate":shdate.text, "cshr":cmb.currentValue});
                    }
                    Button{
                        id: incasBtn
                        text: "Інкасувати"
                        visible: root.toBulk
                        enabled: vw.amntTotal > 0.5
                        onClicked: {
                            // var aa = []
                            // for (let j =0; j < vw.model.count; ++j) { aa.push(vw.model.get(j));}


                            let vj = {"id":"dcmbind","dcm":"check","dbt":"","cdt":"","amnt":"0","eq":"0","dsc":"0","bns":"0","note":"incas", "clnt":"","cshr":vshift.cshr, "dcms":[]}
                            let eq = 0, total = 0;
                            for (var r =0; r < vw.model.count; ++r) {
                                if (Math.abs(Number(vw.model.get(r).incas)) > 0.0000001) {
                                    eq = Number(vw.model.get(r).incas)*Number(vw.model.get(r).price)/Number(vw.model.get(r).qty);
                                    total += eq
                                    vj.dcms.push({"dcm":"trade:inner","dbt":acnts.cash,"cdt":acnts.trade,"crn":vw.model.get(r).curid,
                                        "amnt":String(Number(vw.model.get(r).incas)),"eq":eq.toFixed(2),"dsc":"0","bns":"0",
                                        "note":vw.model.get(r).cur,"retfor":""})
                                    vj.dcms.push({"dcm":"trade:inner","dbt":acnts.cash,"cdt":acnts.bulk,"crn":vw.model.get(r).curid,
                                        "amnt":(String(-1*Number(vw.model.get(r).incas))),"eq":(-1*eq).toFixed(2),"dsc":"0","bns":"0",
                                        "note":vw.model.get(r).cur,"retfor":""})
                                }

                            }
                            vj.eq = total.toFixed(2)
                            vkEvent('shift.incas', vj);



                        }
                    }
                }


            }

        }

    }

    Action{
        id: actionStart
        enabled: (cmb.currentIndex === 0 || psw.text === Qt.atob(cmb.model.get(cmb.currentIndex).psw) )
        text: qsTr("Нова зміна")
        onTriggered: {vkEvent('shift.open', {"id":cmb.currentValue, "name":cmb.currentText});}

    }

    Action{
        id: actionCancel
        text: qsTr("Cancel")
        onTriggered: { vkEvent('shift.cancel', ""); }

    }

}
