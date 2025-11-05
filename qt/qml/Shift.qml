import QtQuick
import QtQuick.Window
import QtQuick.Controls
// import QtQuick.Controls.Fusion
import QtQuick.Layouts

import "../lib.js" as Lib

Window {
    id: root
    width: 640  //parent.width *0.5
    height: 250 //parent.height *0.3
    // width: 0
    // height: 0
    modality : Qt.WindowModal
    property string title: "Зміна"
    property string codeid: "shift"
    property var dbDriver                 // DataBase driver
    onDbDriverChanged: {
        // vshift = Lib.crntShift(dbDriver)
        // dbg(JSON.stringify(vshift, "#25fj"))
        vcashiers = Lib.getSQLData(dbDriver,"select '' code, ' без касира' note, '' psw union select code, note, psw from cashier order by note;")
        vpopulate(Lib.getIncas(dbDriver))

    }
    property var funcUploadBind     // (jbind)
    property var funcUploadBalace   // ()
    property var funcShiftClose     // ()
    property var funcOnShiftChanged // (newShift)
    // property Menu vkContentMenu: Menu{
    // }
    property var acnts
    property var vshift //: { "id":0,"cshr":"","cshrname":"","errid":1,"errname":"","shftbegin":"","shftdate":"","shftend":""}
        onVshiftChanged: {
            if (vshift.shftend === ""){
                // openGroup.visible = false
                // closeGroup.visible = true
            } else {
                // openGroup.visible = true
                // closeGroup.visible = false
                // root.width = 640
                // root.height = 280
            }
            shftStack.currentIndex = (vshift.shftend === "" ? 1 : 0)

            shid.text = vshift.id
            shcshr.text = vshift.cshrname
            shdate.text = vshift.shftdate
            shopen.text = vshift.shftbegin
            shclose.text = vshift.shftend

        }
    property bool toBulk: false

    property var vcashiers: []

    signal vkEvent(string id, var param)

    function dbg(str, code ="") {
        console.log( String("%1[Shift] %2").arg(code).arg(str));
    }

    function vpopulate( vtrades) {
        vw.model.clear()
        let vam = 0
        for (let r =0; vtrades !=='' && r < vtrades.length; ++r){
            vw.model.append(vtrades[r])
            vam += Math.abs(Number(vtrades[r].amnt))
        }
        vw.amntTotal = vam;
    }

    function shOpen() {
        const isNewMonth = (root.vshift.shftdate.substring(0,7) !== Qt.formatDateTime(new Date(), "yyyy-MM") )

        if( Lib.newShift(dbDriver, root.acnts, {"id":cmb.currentValue, "name":cmb.currentText}) ) {
            root.vshift = Lib.crntShift(dbDriver)
            funcOnShiftChanged(root.vshift)
            if (isNewMonth && root.acnts.profit !== undefined &&  root.acnts.profit !== ""){
                const jbind = Lib.makeBind_balancingTrade(dbDriver, root.acnts);
                const bindId = Lib.tranBind(dbDriver, jbind);
                if (bindId !== 0 ){
                    root.funcUploadBind(jbind)
                } else {
                    // TODO error
                }
            }
            funcUploadBalace()
        }
        root.close();
    }

    function shIncas() {
        let jbind = {"id":"dcmbind","dcm":"check","dbt":"","cdt":"","amnt":"0","eq":"0","dsc":"0","bns":"0","note":"incas", "clnt":"","cshr":vshift.cshr, "dcms":[]}
        let eq = 0, total = 0;
        for (var r =0; r < vw.model.count; ++r) {
            if (Math.abs(Number(vw.model.get(r).incas)) > 0.0000001) {
                eq = Number(vw.model.get(r).incas)*Number(vw.model.get(r).price)/Number(vw.model.get(r).qty);
                total += eq
                jbind.dcms.push({"dcm":"trade:inner","dbt":acnts.cash,"cdt":acnts.trade,"crn":vw.model.get(r).curid,
                    "amnt":String(Number(vw.model.get(r).incas)),"eq":eq.toFixed(2),"dsc":"0","bns":"0",
                    "note":vw.model.get(r).cur,"retfor":""})
                jbind.dcms.push({"dcm":"trade:inner","dbt":acnts.cash,"cdt":acnts.bulk,"crn":vw.model.get(r).curid,
                    "amnt":(String(-1*Number(vw.model.get(r).incas))),"eq":(-1*eq).toFixed(2),"dsc":"0","bns":"0",
                    "note":vw.model.get(r).cur,"retfor":""})
            }

        }
        jbind.eq = total.toFixed(2)
        // dbg(JSON.stringify(jbind), "#ew5"); return
        // vkEvent('shift.incas', jbind);
        const bindId = Lib.tranBind(dbDriver, jbind);
        if (bindId !== 0 ){
            root.funcUploadBind(jbind)
        } else {
            // TODO error
        }
        vpopulate(Lib.getIncas(dbDriver))
    }

    Action{
        id: startAction
        enabled: false  // (cmb.currentIndex === 0 || psw.text === Qt.atob(cmb.model.get(cmb.currentIndex).psw) )
        text: qsTr("Нова зміна")
        onTriggered: { shOpen(); }
        // onTriggered: {vkEvent('shift.open', {"id":cmb.currentValue, "name":cmb.currentText});}

    }

    Action{
        id: cancelAction
        // enabled: vshift.shftend === ""
        text: qsTr("Cancel")
        onTriggered: { root.close(); }
    }

    Action{
        id: incasAction
        text: "Зарахувати на ГУРТ"
        enabled: vw.amntTotal > 0.5
        onTriggered: { shIncas(); }
    }

    Action{
        id: closeAction
        text: "Закрити зміну"
        enabled: vw.amntTotal < 1 || !root.toBulk
        // onTriggered: { funcShiftClose({"shid":shid.text,"shdate":shdate.text, "cshr":cmb.currentValue}); }
        onTriggered: { funcShiftClose({"shid": root.vshift.id,"shdate": root.vshift.shftdate, "cshr":cmb.currentValue}); }
    }

    StackLayout {
        id: shftStack
        anchors.centerIn: parent
        // spacing: 10
    // RowLayout{
    //     anchors.centerIn: parent
        GroupBox{
            id: openGroup
            // width: 360
            // height: 360
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
                            startAction.enabled = (cmb.currentIndex === 0)
                        }
                    }
                }
                RowLayout {
                    spacing: 10

                    Label { text: qsTr("Password:") }
                    TextField{
                        id: psw
                        echoMode: TextInput.Password      // PasswordEchoOnEdit
                        // onTextChanged: startAction.enabled = (text === Qt.atob(cmb.model.get(cmb.currentIndex).psw) )
                        onAccepted: {
                            startAction.enabled = (cmb.model.get(cmb.currentIndex).psw === "" || text === Qt.atob(cmb.model.get(cmb.currentIndex).psw) )
                            if (startAction.enabled) {startAction.trigger(); }
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
                        action: cancelAction
                    }
                    Button{
                        id: openBtn
                        action: startAction
                    }
                }

            }
        }

        GroupBox{
            id: closeGroup
            // width: 640
            // height: 280
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
                            Text {id:shid;/* text:root.vshift.id*/ }
                        }
                        RowLayout{
                            Label {text: "Касир: " }
                            Text { id:shcshr; /*text:root.vshift.cshrname*/ }
                        }
                        RowLayout{
                            Label {text: "Дата: " }
                            Text {id:shdate;/* text: root.vshift.shftdate;*/}
                        }
                        RowLayout{
                            Label {text: "Відкрито: " }
                            Text {id:shopen;/* text:root.vshift.shftbegin*/}
                        }
                        RowLayout{
                            Label {text: "Закрито: " }
                            Text {id:shclose;/* text:root.vshift.shftend*/}
                        }
                        Label{
                            id: redyToCloseAlert
                            visible: ( root.toBulk && vw.amntTotal > 0.5)
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
                                    Text{ width:vw.curw; text:(qty==="1"?"":(qty)) + cur; }
                                    Text{ width:vw.amnw; text:Math.abs(amnt); horizontalAlignment: Qt.AlignRight; color:Number(amnt)<0?"red":"black";}
                                    Text{ width:vw.incw; text:Math.abs(incas); horizontalAlignment: Qt.AlignRight; color:Number(incas)<0?"red":"black";}
                                    Text{ width:vw.resw; text:Number(amnt)+Number(incas); horizontalAlignment: Qt.AlignRight; color:Number(Number(amnt)+Number(incas))<0?"red":"black";}
                                    Text{ width:vw.priw; text:Number(price).toFixed(2); horizontalAlignment: Qt.AlignRight;}
                                    Text{
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
                        action: cancelAction
                    }
                    Button{
                        action: closeAction
                        // text: "Закрити зміну"
                        // // visible: false
                        // enabled: vw.amntTotal < 1 || !root.toBulk
                        // onClicked: vkEvent('shift.close', {"shid":shid.text,"shdate":shdate.text, "cshr":cmb.currentValue});
                    }
                    Button{
                        visible: root.toBulk
                        action: incasAction
                    }
                }


            }

        }
    // }

    }

}
