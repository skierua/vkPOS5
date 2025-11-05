import QtQuick
import QtQuick.Controls
// import QtQuick.Controls.Fusion
import QtQuick.Layouts
import "../lib.js" as Lib


Item {
    id: root
//    width: 480
//    height: 480
    property string title: "Чек"
    property string codeid: "bind"
    property var dbDriver                 // DataBase driver
    property var acnts

    property list<Action> vkContextActions: [
        uahToAcntAction,
        curToAcntAction,
        incasToBulkAction
    ]
    // property list<MenuItem> vkContextItems: [
    //     MenuItem { action: uahToAcntAction; },
    //     MenuItem { action: curToAcntAction; },
    //     MenuItem { action: incasToBulkAction; }
    // ]
    // property Menu vkContextMenu: Menu{
    //     id: vkContextMenu_id
    //     MenuItem { action: uahToAcntAction; }
    //     MenuItem { action: curToAcntAction; }
    //     MenuItem { action: incasToBulkAction; }
    //     // MenuSeparator { padding: 5; }
    //     // MenuItem { action: drawerAction; text: "Залишки"; }
    //     // MenuSeparator { padding: 5; }
    //     // MenuItem { action: checkAction; }
    //     // MenuItem { action: factureAction; }
    //     // MenuItem { action: taxcheckAction; }
    // }

    property var funcRESTUpload // (jbind)
    property var funcFiscalizate  // (bindid)
    // property var funcBatchIncasToBalk   // ()
    property var funcLog  // (text, logid)

    property int dfltAmnt: 1
    property var dfltClient: {'id':'', 'name':'', "bonusTotal": 0, "bonusAcnt":''};
    property var dfltAcnt
    property bool allowTax: false
    property string printDcm: ""
    property bool autoPrint: false
    property bool autoTax: false

    property int count: bindView.model.count
    property real total: bindView.model.pmntTotal
    property real z0: 0.0000001


    property string parentCode: "check"
    property var cashAcnt : {"acntno":"3000", "clid":"", "note":"", "mask":"7", "trade":"0", "name":"Залишок"}
    // onCashAcntChanged: dataModel.cashAcnt = cashAcnt.acntno
    property var crntAcnt: { "acntno":"", "clid":"", "clname":"", "note":"", "mask":"", "clnote":"", "trade":"", "name":"" };
    onCrntAcntChanged: startNewRow()
    property int crntAmnt
    property var crntClient: {'id':'', 'name':'', "bonusTotal": 0, "bonusAcnt":''};
    onCrntClientChanged: {
        // cmbAcnt.model = Lib.getAcntList(dbDriver, cashAcnt.acntno, crntClient.id, "")
        startNewRow()
    }

    onVisibleChanged: startNewRow()


    signal vkEvent(string id, var param)

    states: [
            State {
                name: "facture"
                PropertyChanges { target: root; title: "Фактура" }
                PropertyChanges { target: root; parentCode: "facture" }
                PropertyChanges { target: dataModel; code: "facture" }
                PropertyChanges { target: root; autoTax: false }
                PropertyChanges { target: fldDsc; visible: true }
                PropertyChanges { target: fldBns; visible: true }
                PropertyChanges { target: fldRate; visible: true }
                // PropertyChanges { target: viewArea; color: "white" }
            },
        State {
            name: "incas"
            PropertyChanges { target: root; title: "Інкасація" }
            PropertyChanges { target: root; parentCode: "check" }
            PropertyChanges { target: dataModel; code: "check" }
            PropertyChanges { target: root; autoTax: false }
            PropertyChanges { target: fldDsc; visible: false }
            PropertyChanges { target: fldBns; visible: false }
            PropertyChanges { target: fldRate; visible: false }
            PropertyChanges { target: viewArea; color: "honeydew" }
        },
            State {
                name: "taxcheck"
                PropertyChanges { target: root; title: "Фіскальний чек" }
                PropertyChanges { target: root; parentCode: "check" }
                PropertyChanges { target: dataModel; code: "check" }
                PropertyChanges { target: root; autoTax: true }
                PropertyChanges { target: fldDsc; visible: false }
                PropertyChanges { target: fldBns; visible: false }
                PropertyChanges { target: fldRate; visible: false }
                PropertyChanges { target: viewArea; color: "beige" }
        },
            State {
                name: "kantor"
                // PropertyChanges { target: root; title: "Фіскальний чек" }
                // PropertyChanges { target: root; autoTax: true }
                // PropertyChanges { target: viewArea; color: "beige" }
            }
        ]

    function dbg(str, code ="") {
        console.log( String("%1[Bind.qml] %2").arg(code).arg(str));
    }


    ModelBind{
        id: dataModel
        code: "check"
    }

    Action {
        id: tranAction
        icon.name: "save"
        icon.source: "qrc:/icon/save.svg"
        onTriggered: tranBind(2)
    }

    Action {
        id: uahToAcntAction
        enabled: Number(crntAcnt.mask)&1 == 1
        text: "ГРН на рахунок"
        onTriggered: {
            dataModel.uahToAcnt(crntAcnt)
            fldMainInput.forceActiveFocus()
            // startNewRow()
        }
    }

    Action {
        id: curToAcntAction
        enabled: Number(crntAcnt.mask)&2 == 2
        text: "ВАЛЮТА на рахунок"
        onTriggered: {
            dataModel.curToAcnt(crntAcnt)
            fldMainInput.forceActiveFocus()
            // startNewRow()
        }
    }

    Action {
        id: incasToBulkAction
        enabled: root.state === ""
        text: "Зарахувати на ГУРТ"
        onTriggered: {
            newBatchIncasToBalk()
        }
    }

    Action {
        id: drawerAction
        icon.source: "qrc:/icon/drawer.svg"
        onTriggered: {vkEvent("drawer", "")}
    }


/*    Action {
        id: checkAction
        enabled: !bindView.model.count
        text: "Чек"
        onTriggered: { root.state = '' }
    }

    Action {
        id: factureAction
        enabled: !bindView.model.count
        text: "Фактура"
        onTriggered: { root.state = 'facture' }
    }

    Action {
        id: taxcheckAction
        enabled: root.allowTax && !bindView.model.count
        text: "Фіскальний чек"
        onTriggered: { root.state = 'taxcheck' }
    } */

    function startNewRow() {
        dataModel.recalculate()
        root.crntAmnt = root.dfltAmnt
        totalCurrencyView.model = dataModel.curBalanceList()
        // dbg(JSON.stringify(totalCurrencyView.model), "#5wet")
        fldMainInput.text = ''

        // if (totalCurrencyView.model.length) dbg(JSON.stringify(totalCurrencyView.model[0]), "#73h")

        fldMainInput.forceActiveFocus()
    }

    function startBind() {
        bindView.model.clear()
        root.crntClient = root.dfltClient
//        crntAmnt = dfltAmnt
        root.crntAcnt = root.dfltAcnt
        dataModel.setRate(1)
        dataModel.setDsc(0)
        dataModel.setBns(0)
        startNewRow()
    }

    function find(text){
        Lib.findText(dbDriver, text, crntAcnt.mask,
            (err, res)=>{
                if (err){
                    funcLog(err, 1)
                } else {
                    if (res.length === 1){
                     // create docum
                        if (Number(res[0].mask)===0){
                            // set currentClient
                            root.crntClient = Lib.getClient(dbDriver, res[0].id)
                        } else {
                            dataModel.addDcm(dbDriver, res[0].id, root.crntAcnt.acntno, crntAmnt)
                            bindView.currentIndex = 0
                            bindView.forceActiveFocus()
                        }
                    } else {
                        vkEvent("find", res)
                    }
                }
            })

    }

    function newDcm(atclid, acntno, amnt, price){
        if (atclid === undefined) atclid = "";
        if (acntno === undefined) acntno = root.crntAcnt.acntno;
        if (amnt === undefined) amnt = root.crntAmnt;
        dataModel.addDcm(root.dbDriver, atclid, acntno, amnt, price)
        bindView.currentIndex = 0
        bindView.forceActiveFocus()
    }

    function newBonus(){
        dataModel.addDcm(root.dbDriver, "", root.crntClient.bonusAcnt, 0 - root.crntClient.bonusTotal)
        bindView.currentIndex = 0
        bindView.forceActiveFocus()
    }

    function newRefused(param){
        // return
        const cl = Lib.getSQLData(dbDriver, "select coalesce(client,'') as cl from documall where id ="+param.pid);
        if (!cl.length){
            funcLog("Неможливо визначити клієнта.", 1)
            return;
        }
        // console.log("#94j cl="+cl+" bindclid="+stackBind.children[stackBind.currentIndex].crntClient.id)
        if (root.crntClient.id === "" ){
            root.crntClient = Lib.getClient(dbDriver, cl[0].cl);
        }
        if (root.crntClient.id !== cl[0].cl){
            funcLog("Клієнт Чеку вже визначений і відрізняється від чеку повернення.", 1)
            return;
        }
        dataModel.addRefused(dbDriver, param.dcmid)
        startNewRow();
    }

    function newBatchIncasToBalk(){
        const jdata = Lib.getIncas(root.dbDriver)
        if (!jdata.length) { // nothing to do
            funcLog("Немає документів для інкасації", 1)
            return
        }
        if (root.acnts.bulk === undefined || root.acnts.bulk === ""){ // nothing to do
            funcLog("Не визначено рахунку ГУРТ для інкасації", 1)
            return
        }
        for (let i =0; i < jdata.length; ++i) {
            dataModel.addDcm(root.dbDriver, jdata[i].curid, root.acnts.trade, Number(jdata[i].incas), Number(jdata[i].price)/Number(jdata[i].qty))
            dataModel.addDcm(root.dbDriver, jdata[i].curid, root.acnts.bulk, 0 - Number(jdata[i].incas), Number(jdata[i].price)/Number(jdata[i].qty))
        }
        startNewRow();
    }

    function tranBind(prnMode){
        if (!bindView.count){
            funcLog("Відсутні документи." , 2)
            startNewRow()
            return
        }
        dataModel.cashno = cashAcnt.acntno

        const jbind = dataModel.bindToJSON(root.crntClient.id, root.cashAcnt.acntno )
        if (!jbind) {
            funcLog("Помилка. Несумісні типи документів." , 0)
            return
        }
// return
        if (root.autotax && !dataModel.isTaxBindCorrect()) {
            funcLog("Дукумент не проведено. Помилка фіскалізовації." , 0)
            return
        }
        const bid = dataModel.tran(dbDriver, jbind)
        if (bid === 0) {
            // vkEvent("error", jbind)
            funcLog( dataModel.lastError, 0)
            return
        }
        if (root.autotax) {
            funcFiscalizate(bid)
        }

        funcRESTUpload(jbind)

        if (root.checkPrintDcm !== undefined && root.checkPrintDcm !== ""){
            if ((prnMode === 1) ||
                    (prnMode === 2 && root.checkAutoPrint !== undefined && root.checkAutoPrint !== 0)) {
                vkEvent("printCheck", jbind)
            }
        }


        startBind()
    }

    Component {
        id: dlg1
        FocusScope{
            id: root
            property string test: 'for testing'
            width: childrenRect.width;
//            width: root.ListView.view.width;
            height: 40  //childrenRect.height;
            RowLayout{
                id: layout
                width: root.ListView.view.width
                clip: true
                spacing: 2
                Text{
                    font{pointSize: 30; bold:true;}
                    visible: Number(dacnt.trade) && dprice === 0
                    color: "tomato"
                    text: " ! "

                }

                Text{
                    id: fldSgn
                    property int value : (dsign < 0 ? -1 : 1)
                    Layout.preferredWidth: 30   //parent.height
                    Layout.preferredHeight: 40  //parent.height
                    font.pointSize: 30
                    horizontalAlignment: Text.AlignHCenter
                    text: dsign < 0 ? '-' : '+'
                }


                Item{   // note
                    Layout.fillWidth: true
                    Layout.preferredHeight: parent.height
                    ColumnLayout{
                        anchors.fill: parent
    //                    Layout.preferredWidth: 120
                        spacing: 0
                        clip: true
                        Text{
                            text: dnote
                            font.pointSize: 12
                        }
                        Text{
                            text: dsubName
                            color: 'dimgray'
                            font.pointSize: 10
                        }
                    }
                    MouseArea{
//                        width: parent.width; height: parent.height
                        anchors.fill: parent
                        enabled: Number(dacnt.trade) === 0
                        onClicked: {fldNoteEdit.visible = true; fldNoteEdit.forceActiveFocus();}
                    }

                    TextField{
                        id: fldNoteEdit
                        anchors.fill: parent
                        visible: false
                        selectByMouse: true
                        onActiveFocusChanged: if (activeFocus) {selectAll()} else {visible = false}
                        text: dnote
                        onAccepted: {
                            text = text.replace(/\\/g,"/")
                            dnote = text
                            root.ListView.view.restart()
                        }
                    }
                }

                Item {  // amnt & rate
//                    Layout.preferredWidth: 100
                    Layout.minimumWidth: 200
                    Layout.fillHeight: true
//                    clip: true

                    ColumnLayout{
                        anchors.fill: parent
                        spacing: 0
                        RowLayout{
                            Text{
                                id: fldAmnt
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                text: damnt.toLocaleString(Qt.locale(),'f',Number(darticle.prec))
                                font.pointSize: 14
                                clip: true
                                elide: Text.ElideLeft
                                MouseArea{
                                    anchors.fill: parent
                                    onClicked: {fldAmntEdit.visible = true; fldAmntEdit.forceActiveFocus();}
                                }
                            }
                            Text{
                                id: fldPrice
                                Layout.fillWidth: true
                                visible: Number(dacnt.trade) === 1
                                font.pointSize: 12
                                horizontalAlignment: Text.AlignHCenter
                                // text: root.ListView.view.model.getPriceStr(index)
                                text: (Number(dprice) * Number(darticle.qty) / drate).toFixed((Number(darticle.mask) & 2) == 2 ? 3 : 2)
                                      + (Number(darticle.qty) === 1?'':('/' + darticle.qty))
//                                color: 'dimgray'
                                MouseArea{
                                    anchors.fill: parent
                                    enabled: (dpratt&1)===1
                                    onClicked: {fldPriceEdit.visible = true;
                                            fldPriceEdit.text=(Number(dprice)*Number(darticle.qty)/drate)//.toPrecision(4);
                                            fldPriceEdit.forceActiveFocus();}
                                }
                            }

                        }

                        RowLayout{
                            visible: Number(dacnt.trade)!==0
                            Text{
                                id: fldEq
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                                text: Math.abs(Number(damnt)*dprice/drate).toLocaleString(Qt.locale(),'f',2)
                                font.pointSize: 10
                                color: 'dimgray'
                                MouseArea{
                                    anchors.fill: parent
                                    onClicked: {
                                        fldEqEdit.text=(Number(damnt)*dprice/drate).toFixed(2)//.toPrecision(4);
                                        fldEqEdit.visible = true;
                                        fldEqEdit.forceActiveFocus();
                                    }
                                }
                            }
                            Text{
                                id: fldDsc
                                width: parent.width/2
                                text: ddsc === 0 ? 'знижка' : 100*Math.abs(ddsc) +'%' //.toLocaleString(Qt.locale(),'f',4)
//                                font.pointSize: 8
                                horizontalAlignment: Text.AlignHCenter
                                color: ddsc === 0 ? 'lightgray' : 'dimgray'
                                MouseArea{
                                    anchors.fill: parent
                                    enabled: (dpratt&2) == 2
//                                    onClicked: {fldPriceEdit.visible = true; fldPriceEdit.forceActiveFocus();}
                                }
                            }
                            Text{
                                id: fldBns
                                width: parent.width/2
                                text: dbns  === 0 ? 'бонус' : 100*Math.abs(dbns) +'%'
//                                font.pointSize: 8
                                horizontalAlignment: Text.AlignHCenter
                                color: dbns === 0 ? 'lightgray' : 'dimgray'
                                MouseArea{
                                    anchors.fill: parent
                                    enabled: (dpratt&4) == 4
//                                    onClicked: if () {fldPriceEdit.visible = true; fldPriceEdit.forceActiveFocus();}
                                }
                            }


                        }

                    }
                    TextField{
                        id: fldAmntEdit
//                        width: parent.width; height: parent.height
                        anchors.fill: parent
                        visible: activeFocus    //index === root.ListView.view.currentIndex
                        focus: true
                        selectByMouse: true
                        validator: DoubleValidator {bottom: 0; decimals: darticle.prec; notation: "StandardNotation"; locale: "en_US" }
                        onActiveFocusChanged: if (activeFocus) {selectAll()} else {visible = false}
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: 20
                        text: damnt
                        onEditingFinished: {
                            // if (Number(text) !== 0){ damnt = Number(text).toFixed(darticle.prec); }
                            if (Number(text) !== 0){ damnt = Number(text); }
                            root.ListView.view.restart()
                        }
                    }
                    TextField{
                        id: fldPriceEdit
//                        width: parent.width; height: parent.height
                        anchors.fill: parent
                        visible: false
                        selectByMouse: true
                        validator: DoubleValidator {bottom: 0; decimals: 6; notation: "StandardNotation"; locale: "en_US" }
                        onActiveFocusChanged: if (activeFocus) {selectAll()} else {visible = false}
                        onAccepted: {
                            if (Number(text) !== 0){ dprice = Number(text)*drate/Number(darticle.qty); }
                            root.ListView.view.restart()
                        }
                    }
                    TextField{
                        id: fldEqEdit
//                        width: parent.width; height: parent.height
                        anchors.fill: parent
                        visible: false
                        selectByMouse: true
                        validator: DoubleValidator {bottom: 0; decimals: 2; notation: "StandardNotation"; locale: "en_US" }
                        onActiveFocusChanged: if (activeFocus) {selectAll()} else {visible = false}
//                        text: 'eq'//Math.abs(Number(eq))
                        onAccepted: {
                            // Math.abs(Number(damnt)*dprice/drate).toLocaleString(Qt.locale(),'f',2)
                            if (Number(text) !== 0){ damnt = (Number(text)/Number(dprice)).toFixed(darticle.prec); }
                            root.ListView.view.restart()
                        }
                    }
                }

                Button{
                    id: btnDelete
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    icon {source: "qrc:/icon/close.svg"}
                    onClicked: {
                        root.ListView.view.model.remove(index)
                        root.ListView.view.restart()
                    }
                }
            }
        }
    }


    ColumnLayout{
        anchors{fill: parent; margins: 2}



        RowLayout {
            Layout.fillWidth: true
            Button{
                id: btnAmnt
                Layout.preferredWidth: 32   //parent.height
                Layout.preferredHeight: 32   //parent.height
                font.pointSize: 30
                text: Number(crntAmnt) < 0 ? '-' : '+'
//                    icon {name:"add"; source:"qrc:/icon/add.svg"}
                onClicked: {crntAmnt = -1 * Number(crntAmnt); fldMainInput.forceActiveFocus()}
            }
            TextField{
                id: fldMainInput
                Layout.fillWidth: true
                focus: true
                selectByMouse: true
                onAccepted: {
                    if (text === '*') {     // auto print
                        tranBind(2)
                        // vkEvent('tranBind', 2);
                        return;
                    } else if (text === '*8') { // DO print
                        tranBind(1)
                        return;
                    } else if (text === '*9') { // NOT print
                        tranBind(0)
                        return;
                    }
                    // TODO
//                    if (text == '0000') {
//                        setClient(); text =''; return;
//                    }

                    while ((text.substring(0,1) === '+') || (text.substring(0,1) === '-')) {
                        if (text.substring(0,1) === '+') {
                            text = text.substring(1)
                            crntAmnt = Math.abs(crntAmnt)
                        } else {
                            text = text.substring(1)
                            crntAmnt = 0 - Math.abs(crntAmnt)
                        }
                    }
                    if (text === '' && (Number(root.crntAcnt.mask) & 1) === 1){
                            dataModel.addDcm(root.dbDriver, "", root.crntAcnt.acntno, Number(root.crntAmnt))
                        bindView.currentIndex = 0
                        bindView.forceActiveFocus()
                    } else if (text !== ""){
                        find(text)
                    }
                    // fldMainInput.forceActiveFocus()
                    // bindView.currentIndex = 0
                    // bindView.forceActiveFocus()

                }

                Button{
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    visible: crntAcnt !== undefined && (Number(crntAcnt.mask)&1) == 1
                    text:'ГРН'
                    onClicked: newDcm();
                }
            }

            Row{
                spacing: 0
                Button{
                    id: btnCreditAcnt
                    text: (crntAcnt !== undefined && crntAcnt.note !== "") ? crntAcnt.note : crntAcnt.name   // 'ТОРГІВЛЯ'
    //                visible: crntAcnt.trade === '0'
                    onClicked: vkEvent('creditAcntClicked', {cashno:cashAcnt.acntno, clid:crntClient.id, mode:''})
                }
                Button{
                    id: btnReturnToTrade
                    width: 32
//                            Layout.preferredHeight: 32
                    visible: crntAcnt !== undefined && (crntAcnt.acntno).substring(0,2) !== '35' //crntAcnt.trade === '0'
                    icon {name:'undo'; source: "qrc:/icon/undo.svg"}
                    onClicked: root.crntAcnt = Lib.getAccount(dbDriver);  // vkEvent('crntAcntToTrade', "")
                }
            }


        }

        Rectangle{   // bindItem
            id: viewArea
            Layout.minimumWidth: 400
//                Layout.preferredWidth: 200
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip:true
//                color: 'beige'

            ListView{
                id: bindView
                anchors.fill: parent
                spacing: 2
                // model: ListModel{ }
                model: dataModel

                delegate: dlg1

                function restart(){
                    startNewRow();
                }

            }
        }

        Rectangle{      // totalCurrencyView
            Layout.fillWidth: true
            Layout.preferredHeight: 20
            color: 'WhiteSmoke'
            RowLayout{
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                Repeater {
                    id: totalCurrencyView
                    model: []
                    Label {
                        required property var modelData
                        color: modelData.amnt > 0 ? 'blue': (modelData.amnt < 0?'red':'grey')
                        text: String(' %1%2%3 ').arg(modelData.amnt > 0 ? "+" : "").arg(modelData.amnt === 0 ? "0" : modelData.amnt).arg(modelData.atcl.name)
                    }
                  }
            }


        }

        Rectangle{
            id:totalArea
            Layout.preferredHeight: childrenRect.height
            Layout.fillWidth: true
            color: 'whitesmoke'

            RowLayout{
                id:totalAreaLayout
                width: parent.width
//                anchors.fill: parent
//                anchors.verticalCenter: parent.verticalCenter
                spacing: 10

                Button{
                    id: btnTran
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    action: tranAction
                }

                Label{
//                    anchors.horizontalCenter: parent.horizontalCenter
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    color: (dataModel.pmntTotal) < 0 ? 'red' : 'blue'
                    text: ((dataModel.pmntTotal) <0 ? '- ':'+ ') + Math.abs(dataModel.pmntTotal).toLocaleString(Qt.locale(),'f',2)
                    font.pixelSize: 30
                    font.bold: true
                }

                Item{
                    id:dbrArea
                    Layout.preferredWidth: childrenRect.width
                    Layout.fillHeight: true

                    RowLayout{
                        spacing: 10
                        ColumnLayout{
                            Label{
                                id: fldDsc
                                text:String('Dsc: %1 %2').arg((100 * Math.abs(dataModel.crntDsc)).toFixed(1)+'%')
                                     .arg(dataModel.dscMoney == 0 ? '' : Math.abs(dataModel.dscMoney).toLocaleString(Qt.locale(),'f',2))
                                MouseArea{
                                    anchors.fill: parent
                                    onClicked: {
                                        fldDscEdit.text = 100 * Math.abs(dataModel.crntDsc);
                                        fldDscEdit.visible = true;
                                        fldDscEdit.forceActiveFocus();
                                    }
                                }
                            }
                            Label{
                                id: fldBns
                                text:String('Bns: %1 %2').arg((100 * Math.abs(dataModel.crntBns)).toFixed(1)+'%')
                                     .arg(dataModel.bnsMoney == 0 ? '' : Math.abs(dataModel.bnsMoney).toLocaleString(Qt.locale(),'f',2))
                                MouseArea{
                                    anchors.fill: parent
                                    enabled: crntClient !== undefined && crntClient.id !==''
                                    onClicked: {
                                        fldBnsEdit.text = 100 * Math.abs(dataModel.crntBns);
                                        fldBnsEdit.visible = true;
                                        fldBnsEdit.forceActiveFocus();
                                    }
                                }
                            }
                        }

                        ColumnLayout{
                            id: fldRate
                            visible: false
                            Label{
                                text:'Rate: '+ dataModel.crntRate
                                MouseArea{
                                    anchors.fill: parent
                                    onClicked: {    /*console.log("094 clicked")*/
                                        fldRateEdit.visible = true;
                                        fldRateEdit.text = String(dataModel.crntRate);
                                        fldRateEdit.forceActiveFocus();
                                    }
                                }
                            }
                            Label{ text: dataModel.crntRate === 1 ? '' : (dataModel.eqTotal/dataModel.crntRate).toFixed(2); }
                        }
                    }
                    TextField{
                        id: fldDscEdit
                        anchors.fill: parent
                        visible: false; //activeFocus    //index === root.ListView.view.currentIndex
                        selectByMouse: true
                        validator: DoubleValidator {bottom: 0; top:100; decimals: 4; notation: "StandardNotation"; locale: "en_US" }
                        onActiveFocusChanged: if (activeFocus) {selectAll()} else {visible = false}
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: 14
                        onAccepted:  {
                            dataModel.setDsc(text)
                            fldMainInput.forceActiveFocus()
                        }
                    }
                    TextField{
                        id: fldBnsEdit
                        anchors.fill: parent
                        visible: false; //activeFocus    //index === root.ListView.view.currentIndex
                        selectByMouse: true
                        validator: DoubleValidator {bottom: 0; top:100; decimals: 4; notation: "StandardNotation"; locale: "en_US" }
                        onActiveFocusChanged: if (activeFocus) {selectAll()} else {visible = false}
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: 14
                        onAccepted: {
                            dataModel.setBns(text)
                            fldMainInput.forceActiveFocus()
                        }
                    }
                    TextField{
                        id: fldRateEdit
                        anchors.fill: parent
                        visible: false; //activeFocus    //index === root.ListView.view.currentIndex
                        selectByMouse: true
                        validator: DoubleValidator {bottom: 0; notation: "StandardNotation"; locale: "en_US" }
                        onActiveFocusChanged: if (activeFocus) {selectAll()} else {visible = false}
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: 12
                        onAccepted: {
                            dataModel.setRate(text)
                            fldMainInput.forceActiveFocus()
                        }
                    }

                }

                Button{
                    id: btnDrawer
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    action: drawerAction
                }


            }

        }

    }
}
