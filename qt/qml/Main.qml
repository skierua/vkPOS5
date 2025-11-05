import QtCore
import QtQuick
// import QtQuick.Controls
// import QtQuick.Controls.Basic
import QtQuick.Controls.Fusion
// import QtQuick.Controls.Material
//import QtQuick.Controls.Universal
import QtQuick.Layouts

import "../lib.js" as Lib
import "../libREST.js" as REST
import "../libTAX.js" as CashDesk

import com.print 1.0
import com.singleton.dbdriver4 1.0

ApplicationWindow {
    id: root
    visible: true
    title: String("vkPOS5#%1").arg("2.11")

    // property string pathToDb: "/data/"
    property string dbname: ''
        onDbnameChanged: {
            closeChildWindow()
            Db.setDbParameter(dbname);
            root.crntShift = Lib.crntShift(Db)
            root.acnts = Lib.getAcntSettings(Db)

            Prn.setTerm(root.term)
            Prn.setUser(crntShift.cshrname)
            Prn.setCheck(root.checkPrintDcm)

            if (bindContainer.depth){
                bindContainer.currentItem.dfltClient = Lib.getClient(Db)
                bindContainer.currentItem.cashAcnt = Lib.getAccount(Db,acnts.cash)
                bindContainer.currentItem.dfltAcnt = Lib.getAccount(Db)
                bindContainer.currentItem.startBind()
            }
            // Lib.log("#72g dfltAcnt="+JSON.stringify(bindContainer.currentItem.dfltAcnt))

            if (root.crntShift.shftend !== '') {   // shift is closed
                // Lib.log("222 here")
                winShiftAction.trigger();
            } else {
                // Lib.log("111 here")
                if (root.crntShift.shftdate !== Qt.formatDateTime(new Date(), "yyyy-MM-dd")){
                    if (Lib.isIncas(Db, root.acnts)) {
                      winShiftAction.trigger()
                    } else {
                      askDialog.code = 'askCloseShift'
                      askDialog.jdata =  { "text" : "Закрити попередню зміну ?","shid":root.crntShift.id,"shdate":root.crntShift.shftdate, "cshr":root.crntShift.cshr }
                      askDialog.open()
                    }
                } else {
                    // bind is default
                }
            }
        }

    property real z0: 0.0000001
    property var crntShift: { "id":0,"errid":1,"errname":"","shftdate":"","shftbegin":"","shftend":"","cshr":"","cshrname":""}
    // property var cashier: {"id":"", "name":""}
    property var acnts: { "cash":"3000", "incas":"3003ELSV", "trade":"3500", "bulk":"3501", "profit":"3607-55" }


    property string resthost: ""      //"http://localhost"
        onResthostChanged: REST.gl_host = resthost
    property string restapi: ""
        onRestapiChanged: REST.gl_api = restapi
    property string resttoken: ""
        onResttokenChanged: REST.gl_token = resttoken
    property string restuser: ""
    property string restpassword: ""
    property string term: ""
    property string posPrinter: ""
    property string bindList: ""
    property string checkAmnt: "1"
    property string checkAutoPrint: "0"
    property string checkPrintDcm: ""

    property string cdhost: ""
        onCdhostChanged: CashDesk.gl_host = cdhost
    property string cdprefix: ""
        onCdprefixChanged: CashDesk.gl_prefix = cdprefix
    property string cdcash: ""
        onCdcashChanged: CashDesk.gl_cash = cdcash
    property string cdtoken: ""
        onCdtokenChanged: CashDesk.gl_token = cdtoken

    Settings {
        category: "terminal"
        property alias code: root.term
        property alias pos_printer: root.posPrinter
    }

    Settings {
        category: "program"
        property alias binds: root.bindList
        property alias width: root.width
        property alias height: root.height
    }

    Settings {
        category: "check"
        property alias amnt: root.checkAmnt
        property alias auto_print: root.checkAutoPrint
        property alias print_dcm: root.checkPrintDcm
    }

    Settings {
        category: "upload"
        property alias http_host: root.resthost
        property alias http_api: root.restapi
        property alias http_user: root.restuser
        property alias http_password: root.restpassword
    }

    Settings {
        category: "cashdesk"
        property alias host: root.cdhost
        property alias prefix: root.cdprefix
        property alias cash: root.cdcash
        property alias token: root.cdtoken
    }

    function dbg(str, code ="") {
        console.log( String("%1[Main.qml] %2").arg(code).arg(str));
    }

    function isOnline() { return REST.gl_token != ""; }
    // function isOnline() { return root.resttoken != "" }

    function isTaxMode() { return root.cdtoken != "" && root.cdhost != "" && !root.cdhost.startsWith('*') }

    Component{
        id: activateBind
        Action{
            id: croot
            property string ctext
            property int cindex
            text: croot.ctext
            onTriggered: {
                if (cindex === bindContainer.depth -1) return;
                let list = []
                // dbg("STA cindex=" + cindex +" container count="+ bindContainer.depth + " list.count=" + list.length, "#333")
                while (bindContainer.depth > croot.cindex +1) list[list.length] = bindContainer.pop()
                list.reverse()
                list[list.length] = bindContainer.pop()
                // dbg("MID cindex=" + cindex +" container count="+ bindContainer.depth + " list.count=" + list.length, "#333")
                for (let i =0; i < list.length; ++i) {bindContainer.push(list[i]); }
                // dbg("END cindex=" + cindex +" container count="+ bindContainer.depth + " list.count=" + list.length, "#333")
            }
        }
    }

    Action {
        id: actionLogin
        text: "Login"
        onTriggered: {
            REST.login(restuser, restpassword, (err) =>{
                           if (err !== null) logView.append("[REST login]" + err, 1)
                       });
        }
    }

 /*   Action {
        id: testAction
        text: "TEST"
//        icon.name: "edit-copy"
//        shortcut: StandardKey.Copy
        onTriggered: {
            Lib.log(Lib.ttest(Db))
        }
    } */


    function closeChildWindow(){
        dcmViewLoader.active = false
        clientLoader.active = false
        cashWizardLoader.active = false
        taxServiceLoader.active = false
        statLoader.active = false
        rateLoader.active = false
    }

    Timer{
        id: quitTimer
        interval: 1000
        repeat: false
        running: false
        onTriggered: {
            closeChildWindow()
            Qt.quit()
        }
    }

    Action {
        id: bindCheckAction
        property string code: ""
        property int dfltAmnt: Number(root.checkAmnt)
        text: "Новий Чек"        //qsTr("Check")
        onTriggered: {
            actionBind.trigger(bindCheckAction)
            bindContainer.currentItem.forceActiveFocus()
            // bindContainer.currentItem.startBind()
        }
    }

    Action {
        id: bindFactureAction
        property string code: "facture"
        property int dfltAmnt: 1
        text: "Нова Фактура"
        onTriggered: {
            actionBind.trigger(bindFactureAction)
            // bindContainer.currentItem.startBind()
        }
    }

    Action {
        id: bindTaxAction
        property string code: "taxcheck"
        property int dfltAmnt: Number(root.checkAmnt)
        text: "Новий ФІСК.Чек"
        onTriggered: actionBind.trigger(bindTaxAction)
    }

    Action {
        id: actionBind
        onTriggered: (source) => {

                         bindContainer.push("Bind.qml",
                               {
                                dbDriver: Db,
                                funcRESTUpload: (jbind) => {
                                    if (isOnline()) REST.uploadBindTran(root.term, root.term, jbind, Lib.uploadAcnt(Db, true).rows,
                                                         (err) =>{ if (err !== null) logView.append("[uploadBindTran] " + err, 0); })
                                 },
                                 funcFiscalizate: (bindid) =>{
                                    if (!isTaxMode()) {
                                         logView("Fiscalization is unsupported", 1)
                                         return
                                    }
                                    let jbind = Lib.cdtaxFromBind(Db, bindid)
                                    if (!jbind) {
                                        logView("Fiscalization local error", 0)
                                        return
                                    }
                                    CashDesk.sale(jbind, (err, resp) =>{
                                                      if (err) {
                                                          logView("Fiscalization server error", 0)
                                                          if (taxServiceLoader.active) taxServiceLoader.item.newMessage(
                                                              "SALE", "Fiscalization server error", "error")
                                                      } else {
                                                          if (taxServiceLoader.active) taxServiceLoader.item.newMessage(
                                                              "SALE", JSON.stringify(resp), "info")
                                                      }
                                                  }
                                                      )
                                },
                                // funcBatchIncasToBalk: () => {
                                //  },
                                acnts: root.acnts,
                                funcLog: (text, logid =2) => { logView.append("[Bind] " + text, logid); },
                                allowTax: isTaxMode(),
                                printDcm: root.checkPrintDcm,
                                autoPrint: root.checkAutoPrint,
                                dfltAmnt: source.dfltAmnt,
                                dfltClient: Lib.getClient(Db),
                                cashAcnt: Lib.getAccount(Db,acnts.cash),
                                dfltAcnt: Lib.getAccount(Db),
                                state: source.code
                               },
                               StackView.PushTransition)

                bindContainer.currentItem.vkEvent.connect( (id, param)=>{
                    if (id === 'drawer'){
                        drawer2Right.open();
                    } else if (id === 'find'){
                        selectPopup.code = param[0].mask === "0" ? "client" : "article"
                        selectPopup.jsdata = param
                        selectPopup.open()
                    } else if (id === 'creditAcntClicked'){
                        selectPopup.code = "acntno"
                        selectPopup.jsdata = Lib.getAcntList(Db, param.cashno, param.clid, param.mode);
                        // Lib.log("#34rs HERE")
                        selectPopup.open()
                    } else if (id === 'printCheck'){
                        Prn.saveCheck(param)
                        Prn.printCheck(param)
                    } else {
                        logView.append("[Bind] Bad event", 1)
                    }
                  })
                         bindContainer.currentItem.forceActiveFocus()
                bindContainer.currentItem.startBind()
        }
    }

    Action {
        id: removeBindAction
        enabled: bindContainer.depth > 2
        text: "Видалити поточний"
        onTriggered: bindContainer.popCurrentItem()
    }


    Action {
        id: winDcmsAction
        checkable: true
        checked: dcmViewLoader.active
//        enabled: false
        text: "Архів докум."
        onTriggered: { dcmViewLoader.active = checked; }
    }

    Action {
        id: winClientAction
        checkable: true
        checked: clientLoader.active
        text: "Клієнти"
        onTriggered: {
            clientLoader.active = checked;
        }
    }

    Action {
        id: actionSetting
        text: qsTr("Settings")
        onTriggered: {
            closeChildWindow()
            if (bindContainer.depth >1) {
                bindContainer.pop()
            }

            bindContainer.push("Settings.qml", {
                            dfltTerminal: {term:root.term, posPrinter: root.posPrinter, checkAmnt:root.checkAmnt, checkAutoPrint:root.checkAutoPrint, checkPrintDcm: root.checkPrintDcm },
                            dfltAcnt: { cash: root.acnts.cash, trade: root.acnts.trade, bulk: root.acnts.bulk, incas: root.acnts.incas, profit: root.acnts.profit  },
                            dfltREST: { resthost: root.resthost, restapi: root.restapi, restuser: root.restuser, restpassword: root.restpassword, resttoken: root.resttoken },
                            dfltCashDisc: { cdhost: root.cdhost, cdprefix: root.cdprefix, cdcash: root.cdcash, cdtoken: root.cdtoken }
                         }
                             , StackView.PushTransition)

            bindContainer.currentItem.vkEvent.connect( (id, param)=>{
                if (id === "saveTerminal") {
                    root.term = bindContainer.currentItem.dfltTerminal.term
                    root.posPrinter = bindContainer.currentItem.dfltTerminal.posPrinter
                    root.checkAmnt = bindContainer.currentItem.dfltTerminal.checkAmnt
                    root.checkAutoPrint = bindContainer.currentItem.dfltTerminal.checkAutoPrint
                    root.checkPrintDcm = bindContainer.currentItem.dfltTerminal.checkPrintDcm
                } else if (id === "saveAcnts") {
                    // Lib.log('#893 param=' + JSON.stringify(param))
                    root.acnts = bindContainer.currentItem.dfltAcnt
                    Db.dbUpdate("update settings set acnts = '" + JSON.stringify(bindContainer.currentItem.dfltAcnt) + "' where rowid=1;")
                } else if (id === "loginREST") {
                    root.resthost = bindContainer.currentItem.dfltREST.resthost
                    root.restapi = bindContainer.currentItem.dfltREST.restapi
                    root.restuser = bindContainer.currentItem.dfltREST.restuser
                    root.restpassword = bindContainer.currentItem.dfltREST.restpassword
                    root.resttoken = ''
                    REST.login(restuser, restpassword, (err) => {
                        // Lib.log("#984u token="+token);
                        if (err === null){
                            root.resttoken = REST.gl_token
                        } else {
                            logView.appenr(err, 0)
                        }
                        bindContainer.currentItem.dfltREST = { resthost: root.resthost, restapi: root.restapi, restuser: root.restuser, restpassword: root.restpassword, resttoken: root.resttoken }
                    } )
                } else if (id === "saveCD") {
                    root.cdhost = bindContainer.currentItem.dfltCashDisc.cdhost
                    root.cdprefix = bindContainer.currentItem.dfltCashDisc.cdprefix
                    root.cdcash = bindContainer.currentItem.dfltCashDisc.cdcash
                    root.cdtoken = bindContainer.currentItem.dfltCashDisc.cdtoken
                } else {
                    // bad event
                }
            })
        }
    }

    Action {
        id: winShiftAction
        checkable: true
        checked: winShiftLoader.active
        text: "Зміна"
        onTriggered: { winShiftLoader.active = checked; }
    }

    Action {
        id: winCashWizardAction
        checkable: true
        checked: cashWizardLoader.active
        text: "Звірка каси"
        onTriggered: { cashWizardLoader.active = checked; }
    }

    Action {
        id: winStatAction
        enabled: false
        checkable: true
        checked: statLoader.active
        text: "Статистика"
        onTriggered: { statLoader.active = checked; }
    }

    Action {
        id: winRateAction
        checkable: true
        checked: rateLoader.active
        text: "Курси валют"
        onTriggered: { rateLoader.active = checked; }
    }

    Action {
        id: winTaxServiceAction
        checkable: true
        checked: taxServiceLoader.active
        text: "ПРРО/касовий"
        onTriggered: { taxServiceLoader.active = checked; }
    }

    Action {
        id: actionBalancingTrade
        text: "Збалансувати дохід"
        onTriggered: {
            const jbind = Lib.makeBind_balancingTrade(Db, root.acnts/*, {"url":root.resthost+root.restapi, "token": root.resttoken, "term": root.term}*/);
            // console.log("#72h Main actionBalancingTrade " + JSON.stringify(jbind)); return;
            const bindId = Lib.tranBind(Db, jbind);
            if (bindId !== 0 ){
                if (bindId !== 0 && isOnline()) REST.uploadBindTran(root.term, root.term, jbind, Lib.uploadAcnt(Db, true).rows,
                                     (err) =>{ if (err !== null) logView.append("[uploadBindTran] " + err, 0); })        }
            }
    }

    Action {
        id: changeDBAction
        enabled: false
        text: "Змінити БД ["+root.dbname.substring(dbname.lastIndexOf('/')+1)+"]"
        onTriggered: {
            selectPopup.code = "database"
            selectPopup.jsdata = Lib.getDbList(Db, applicationDirPath);
            selectPopup.open()
        }
    }

    Loader{
        id: winShiftLoader
        active: false
        source: 'Shift.qml'
        onActiveChanged: if (active) {
                             closeChildWindow()
                             item.visible = true
                             item.title = String("%1(%2)").arg(root.title).arg("Shift")
                             item.dbDriver = Db
                             item.acnts = root.acnts
                             item.vshift = root.crntShift
                             item.toBulk = (root.acnts.bulk !== undefined && root.acnts.bulk !== "")
                             item.funcOnShiftChanged = (newShift) => { root.crntShift = newShift; }
                             item.funcUploadBind = (jbind) => {
                                if (!isOnline()){ return; }// isOnline
                                dbg("Shift upload ...", "#w7g"); return;


                                REST.uploadBindTran(root.term, root.term, jbind, Lib.uploadAcnt(Db, true).rows,
                                            (err) =>{ if (err !== null) logView.append("[uploadBindTran] " + err, 0); })
                            }
                            item.funcUploadBalace = () => {
                                 if (!isOnline()){ return; }// isOnline
                                 REST.uploadBalance({"term":root.term,"reqid":"del","shop":root.term},
                                                    (err) => { if (err !== null) logView.append("[REST uploadBalance]" + err, 0) });
                                 const jacnt = Lib.uploadAcnt(Db, false)
                                 if (jacnt && jacnt.rows.length) {
                                     REST.uploadBalance( {"term":root.term,"reqid":"upd","shop":root.term,"data":jacnt.rows},
                                                        (err) => { if (err !== null) logView.append("[REST uploadBalance]" + err, 0) });
                                 }
                            }
                            item.funcShiftClose = (param) => {
                                 if( isTaxMode() ) {
                                    askDialog.code = 'zreport'
                                    askDialog.jdata =  { "text" : "Закрити фіскальну зміну ДПС ?" }
                                    askDialog.open()
                                 }
                                 // revaluate TRADE
                                 const jbinds = Lib.makeBind_reval(Db, root.crntShift.cshr);
                                 let cbindId = 0;
                                 for (let r =0; r < jbinds.length; ++r){
                                     cbindId = Lib.tranBind(Db, jbinds[r]);
                                     if (cbindId !== 0 ){
                                         REST.uploadBindTran(root.term, root.term, jbinds[r], Lib.uploadAcnt(Db, true).rows,
                                                     (err) =>{ if (err !== null) logView.append("[uploadBindTran] " + err, 0); })
                                     }
                                 }

                                 if (Lib.closeShift(Db, param)){
                                 // TODO error
                                 }

                                 root.visible = false;
                                 quitTimer.start()

                             }
                         } else {
                             // root.crntShift = Lib.crntShift(Db)
                             // if shift is closed
                             if (crntShift.shftend !== "") { quitTimer.start(); }
                         }

        Connections {
            target: winShiftLoader.item
            function onClosing() { winShiftLoader.active = false; }
        }
    }

    Loader{
        id: dcmViewLoader
        active: false
        source: 'DcmView.qml'
        onActiveChanged: if (active) {
                            item.visible = true
                            item.title = String("%1(%2)").arg(root.title).arg("Documents")
                            item.dbDriver = Db
                            item.prnDriver = Prn
                         }
        Connections {
            target: dcmViewLoader.item
            function onClosing() {
                dcmViewLoader.active = false
            }
            function onVkEvent(id, param) {
                if (id === "refuse"){
                    // console.log("[MAIN>DcnView] dcmid=" + param.dcmid + " pid=" + param.pid)
                    bindContainer.currentItem.newRefused(param)
                }
            }
        }
    }

    Loader{
        id: cashWizardLoader
        active: false
        source: 'WizardCash.qml'
        onActiveChanged: if (active) {
                            item.visible = true
                            item.title = String("%1(%2)").arg(root.title).arg("Cash wizard")
                            item.db = Db
                         }
        Connections {
            target: cashWizardLoader.item
            function onClosing() { cashWizardLoader.active = false ; }
        }
    }

    Loader{
        id: statLoader
        active: false
        source: 'Stat.qml'
        onActiveChanged: if (active) {
                             item.visible = true
                             item.title = String("%1(%2)").arg(root.title).arg("Stat")
                             item.cshr = root.crntShift.cshr
                             item.dbDriver = Db
                         }
        Connections {
            target: statLoader.item
            function onClosing() { statLoader.active = false; }
        }
    }

    Loader{
        id: rateLoader
        active: false
        source: 'Rate.qml'
        onActiveChanged: if (active) {
                             item.visible = true
                             item.title = String("%1(%2)").arg(root.title).arg("Rates")
                             item.online = isOnline()
                             item.uri = resthost + restapi + "/rates?api_token=" + resttoken
                             item.queryData = {"term": root.term, "reqid": "sel", "shop": root.term}
                             item.dbDriver = Db
                             item.funcCreateDcm = (atclid) => {bindContainer.currentItem.newDcm(atclid);}
                         }
        Connections {
            target: rateLoader.item
            function onClosing() { rateLoader.active = false; }
        }
    }

    Loader{
        id: clientLoader
        active: false
        source: 'Client.qml'
        onActiveChanged: if (active) {
                             item.visible = true
                             item.title = String("%1(%2)").arg(root.title).arg("clients")
                             item.db = Db
                         }
        Connections {
            target: clientLoader.item
            function onClosing() { clientLoader.active = false; }
        }
    }

    Loader{
        id: taxServiceLoader
        active: false
        source: 'TaxService.qml'
        onActiveChanged: if (active) {
                             item.visible = true
                             item.title = String("%1(%2)").arg(root.title).arg("Tax service")
                         }
        Connections {
            target: taxServiceLoader.item

            function onClosing() { taxServiceLoader.active = false; }

        }
    }

    Popup{
        id: selectPopup
        property string code :""   // client|database|acntno|(1|2|4 article)
        property var jsdata     // JSON value: id, name, fullname, scancode, mask, sect
        width:300
        height: root.height*0.8
        x: (root.width-width)/2
        modal: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        ListView{
            id: selectPopupView
            anchors.fill: parent
            currentIndex: -1
            clip: true
            spacing: 0
            ScrollBar.vertical: ScrollBar{
                parent: selectPopupView.parent
                anchors.top: selectPopupView.top
                anchors.left: selectPopupView.right
                anchors.bottom: selectPopupView.bottom
            }
            model: ListModel{}
            delegate: Rectangle{
                width:selectPopupView.width
                height:childrenRect.height
                color: index%2==0 ? 'white' : 'whitesmoke'  // Qt.darker('white',0.5)
                ColumnLayout{
                    spacing: 0
                    Label{text:name}
                    RowLayout{
                        Label{text:id; color:'gray'}
                        Label{text:fullname; color:'gray'}
                    }
                }

                MouseArea{
                    anchors.fill: parent
                    onClicked: {
                        if (selectPopup.code==="client"){                  // client
                            bindContainer.currentItem.crntClient = Lib.getClient(Db,id);
                            bindContainer.currentItem.crntAcnt = Lib.getAccount(Db)
                        } else if (selectPopup.code==="database") {        // database
                            root.dbname = id
                            // openConnection(id)
                        } else if (selectPopup.code==="acntno") {        // acntno
                            bindContainer.currentItem.crntAcnt = Lib.getAccount(Db, id)
                            // setAccount(id)
                        } else if (selectPopup.code==="article") {
                            bindContainer.currentItem.newDcm(id)
                        } else {
                            Lib.log("selectPopup bad code, nothing to do","Main", "EE")
                            // bad code, nothing to do
                        }
                        selectPopup.close()
                    }
                }
            }
            section.property: "sect"
            section.criteria: ViewSection.FullString
            section.delegate: Rectangle{
                width: selectPopupView.width
                height: 30  //*/childrenRect.height*1.2
                color: "silver"
                Label{
                    font.pixelSize: 12;
                    text:'  '+section;
                    anchors{verticalCenter: parent.verticalCenter}
                }
            }
            function vpopulate(vfilter) {
                model.clear()
                for (var r =0; r < selectPopup.jsdata.length; ++r){
                    if (vfilter === undefined || vfilter === ''
                            || ~(selectPopup.jsdata[r].id.indexOf(vfilter))
                            || ~(selectPopup.jsdata[r].name.toLowerCase()).indexOf(String(vfilter).toLowerCase())
                            || ~(selectPopup.jsdata[r].fullname.toLowerCase()).indexOf(String(vfilter).toLowerCase())
                            || (selectPopup.jsdata[r].scancode !== undefined && ~(selectPopup.jsdata[r].scancode).indexOf(String(vfilter)))
                            ){
                        model.append(selectPopup.jsdata[r])
                    }
                }
            }
        }
        TextField{
            id: selectPopupFilter
            height: 26
            width: 80
//            font.pixelSize: 8
            anchors{right:parent.right;bottom:parent.bottom}
            selectByMouse: true
            placeholderText: 'фільтр'
//            color: text==''?'lightgray':'black'
            onAccepted: selectPopupView.vpopulate(text)
        }
        onVisibleChanged: if(!visible){selectPopupFilter.text=''; selectPopup.code = ""} else {selectPopupView.vpopulate(selectPopupFilter.text); selectPopupFilter.forceActiveFocus();}

    }

    Dialog{
        id: askDialog
        width: 300
        property string code: ''
        property var jdata: ({})        // JSON

        anchors.centerIn: parent
        modal: true
        title: 'Підтвердження дії'
        contentItem: Text{ wrapMode: Text.Wrap; text: askDialog.jdata.text === undefined ? 'some text' : askDialog.jdata.text; }
        footer: DialogButtonBox {
            standardButtons: Dialog.Ok|Dialog.Cancel
//            standardButtons: Dialog.Yes|Dialog.No
//            alignment: Qt.AlignHCenter
            Keys.onEnterPressed: askDialog.accept()
            Keys.onReturnPressed: askDialog.accept()
            onVisibleChanged: if (visible) forceActiveFocus()
        }

        onAccepted: {
            if (code === 'printCheck'){
//                console.log("#48d accepted, check printing...\n prid="+askDialog.jdata.prid+" prname="+askDialog.jdata.prname)
                if (askDialog.jdata.prid !== undefined && askDialog.jdata.prname !== undefined) {
                    Prn.printCheck(jbind)
                } else {
                    logView.append("Не вдається роздрукувати чек", 0)
                }
            } else if (code === "askCloseShift"){       // { "text" : "Закрити попередню зміну ?","shid":crsh.id,"shdate":crsh.shftdate, "cshr":crsh.cshr }
                winShiftAction.trigger()
            } else  {
                logView.append("[askDialog] BAD event code", 0)
                // console.log("#0i code undefined")
            }
        }
//        onRejected:  { console.log("#348j rejected"); }
        onClosed: { askDialog.jdata = ({}); }
    }

    Drawer {
        id: drawer2Right

        width: parent.width < 500 ? parent.width*0.8 : 400
        height: parent.height
        edge: Qt.RightEdge

        DrawerItem{
            id: drawer2RightItem
            dbDriver: Db
            anchors.fill: parent

        }
    }


    StackView {
        id: bindContainer
        anchors.fill: parent
        initialItem: Bind{} // blank item
        // onCurrentItemChanged:  {
            // currentItem.findChild("fldMainInput").forceActiveFocus()
        // }
        // onDepthChanged:  {
        //     // Lib.log("#2804 bindContainer =" + depth )
        // }
    }

    LogView{
        id: logView
        width: parent.width
        height: (count * 25 < parent.height / 4) ? count * 25 : parent.height / 4
        z: 10
        anchors.bottom: parent.bottom
        debug: true
    }

    header: ToolBar {
        id: appToolBar
        height: 32
        Rectangle{
//            anchors.fill: parent
            width: parent.width
            height: 30
            // color: stackBind.children[stackBind.currentIndex].state === "taxcheck" ? "khaki" : "transparent"
            RowLayout {
                anchors.fill: parent
    //            width: parent.width
                ToolButton {    //  ☰
                    text: "☰"
                    onClicked: naviMenu.open()
                    Menu{
                        id: naviMenu
                        y: parent.height
                        MenuItem { action: bindCheckAction; }
                        MenuItem { action: bindFactureAction; }
                        MenuItem { action: bindTaxAction; }
                        MenuSeparator { padding: 5; }
                        MenuItem { action: removeBindAction; }
                        MenuSeparator { padding: 5; }
                        MenuItem { action: winDcmsAction; }
                        MenuItem { action: winClientAction; }
                        MenuItem { action: winCashWizardAction; }
                        // MenuItem { action: winStatAction; }      // TODO
                        MenuItem { action: winRateAction; }
                        MenuItem { action: winTaxServiceAction; }
                        MenuItem { action: winShiftAction; }
                        MenuSeparator { padding: 5; }
                        MenuItem { action: actionBalancingTrade; }
                        MenuSeparator {  padding: 5; }
                        MenuItem { action: actionSetting; }
                        MenuItem { action: changeDBAction; }
                        // MenuItem { action: testAction; }
                        MenuSeparator { padding: 5; }
                        MenuItem {
                            text: "Вийти"
                            onTriggered: quitTimer.start()
                        }
                    }
                }

                Label {
                    id: headerTitle
                    elide: Label.ElideRight
                    horizontalAlignment: Qt.AlignHCenter
                    verticalAlignment: Qt.AlignVCenter
                    Layout.fillWidth: true
                    text: bindContainer.currentItem.title
                }
                Row {
                    id: btnClient
                    visible: bindContainer.currentItem.crntClient !== undefined
                    ToolButton{
                        text: bindContainer.currentItem.crntClient !== undefined ? bindContainer.currentItem.crntClient.name : ''
                        icon.source: "qrc:/icon/account.svg"
//                        flat: true
                        onClicked: {
                            selectPopup.code = "client"
                            selectPopup.jsdata = Lib.getClientList(Db)
                            selectPopup.open()
                        }
                    }
                    ToolButton{
                        width: 32
    //                    Layout.preferredHeight: 35
                        visible: bindContainer.currentItem.crntClient !== undefined && bindContainer.currentItem.crntClient.id !== ''
                        font.pointSize: 16
                        text:"⌫"
//                        flat: true
//                        icon.source:"qrc:/icon/undo.svg"
                        onClicked: {
                            bindContainer.currentItem.crntClient = Lib.getClient(Db);
                        }
                    }
                    Label{
                        visible: bindContainer.currentItem.crntClient !== undefined && Math.abs(Number(bindContainer.currentItem.crntClient.bonusTotal)) >= 0.01
    //                        Layout.preferredWidth: visible?35:0
                        Layout.preferredHeight: 35
                        color:'slategray'
    //                        background: Rectangle{color:'gold'}
    //                        flat: true
                        text: bindContainer.currentItem.crntClient !== undefined ? Number(bindContainer.currentItem.crntClient.bonusTotal).toFixed(0) : ''
                        MouseArea{
                            anchors.fill: parent
                            onDoubleClicked: {
                                bindContainer.currentItem.newBonus()
                            }

                        }

                    }
                }

                ToolButton {    // ⋮
                    id:contextMenu_toolbtn
                    text: qsTr("⋮")

                    onClicked:  contextMenu.popup()

                    Menu{
                        id: contextMenu
                        y: parent.height

                        onVisibleChanged: {
                            // dbg("contextMenu_toolbtn vsbl="+ visible, "#72js")
                            if (visible){
                                if (bindContainer.currentItem.vkContextActions !== undefined){
                                      for (let i =0; i < bindContainer.currentItem.vkContextActions.length; ++i){
                                          contextMenu.addAction(bindContainer.currentItem.vkContextActions[i])
                                      }
                                      contextMenu.addItem( Qt.createQmlObject('import QtQuick.Controls; MenuSeparator {}',
                                                                                                    contextMenu,
                                                                                                    "dynamicSeparator") )
                                }
                                for (let i = bindContainer.depth -1, r =1; i > 0; --i, ++r){
                                    // dbg(bindContainer.get(i, StackView.DontLoad).title, "#34gs")
                                    contextMenu.addAction(activateBind.createObject(contextMenu
                                                                                  ,{ cindex: i
                                                                                    , ctext: String("%1. %2 (%3грн/%4)")
                                                                                        .arg(r)
                                                                                        .arg(bindContainer.get(i, StackView.DontLoad).title)
                                                                                        .arg(bindContainer.get(i, StackView.DontLoad).total)
                                                                                        .arg(bindContainer.get(i, StackView.DontLoad).count)
                                                                                    }))
                                }
                            } else {
                                for (let j =contextMenu.count -1; j >=0; --j){
                                    contextMenu.removeItem(contextMenu.itemAt(j))
                                }
                            }

                        }
                    }

                }
            }
        }

    }


    onClosing: close =>
    {
//        close.accepted = false
//        askDialog.jdata = {"code":"zReport", "text":"zReport"}
//        askDialog.open()
        closeChildWindow()
    }
    footer: Rectangle{
        width: parent.width
        height: childrenRect.height
        color: 'lightgray'
        RowLayout{
            width: parent.width
            Label {
                id: footerLeftLabel
                text: String(" %1@%2").arg(root.term).arg(root.resthost)
            }
        }

    }

    Component.onCompleted: {
        // let p = "f26r"    //"s5k9";
        // console.log("#387y psw = " + p + " b64: " + Qt.btoa( p));
        // console.log("env=")
        // console.log(applicationDirPath)
        // console.log("+++")
        bindCheckAction.trigger()
        if (resthost != undefined && resthost != "") {
            actionLogin.trigger();
        }
        // pathToDb = "./data/"
        // pathToDb = applicationDirPath + "/data/"
//         var dbList = Db.dirEntryList(pathToDb,'*.sqlite', 2,0)
// //            console.log('main db list='+dbList)
        const dbList = Lib.getDbList(Db, applicationDirPath)
        if (dbList.length === 1) {
            // root.dbname = pathToDb+dbList[0]
            root.dbname = dbList[0].id
            // openConnection(pathToDb+dbList[0])
        } else if (dbList.length > 1) {
            changeDBAction.enabled = true
            changeDBAction.trigger()

        } else {        // no database
            // error
            logView.append("Недоступна база даних", 0)
        }

    }

}
