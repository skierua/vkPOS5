import QtCore
import QtQuick
import QtQuick.Controls
// import QtQuick.Controls.Fusion   // best
// import QtQuick.Controls.Basic
// import QtQuick.Controls.Material
//import QtQuick.Controls.Universal
import QtQuick.Layouts

import "../lib.js" as Lib
import "../libREST.js" as REST
import "../libTAX.js" as CashDesk

// TEST
// import "js/sqlItem.js" as LibItem
// import "js/sqlAcnt.js" as LibAcnt

import com.print 1.0
import com.singleton.dbdriver4 1.0

ApplicationWindow {
    id: root
    visible: true
    title: String("vkPOS5#%1").arg("2.22")

    // property string pathToDb: "/data/"
    property string dbname: ''
        onDbnameChanged: {
            closeChildWindow()
            Db.setDbParameter(dbname);
            root.crntShift = Lib.crntShift(Db)
            root.acnts = Lib.getAcntSettings(Db)
            bindCheckAction.trigger()

            Prn.setTerm(root.term)
            Prn.setUser(crntShift.cshrname)
            Prn.setCheck(root.checkPrintDcm)

            if (stack.count > 0){
                // dbg("count=" + stack.count
                //     + " cidx=" + stack.currentIndex
                //     + " title=" + stack.currentItem.title
                //             ,"36g")
                stack.currentItem.dfltClient = Lib.getClient(Db)
                stack.currentItem.cashAcnt = Lib.getAccount(Db,acnts.cash)
                stack.currentItem.dfltAcnt = Lib.getAccount(Db)
                stack.currentItem.startBind()
            }

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
        console.log( String("[Main.qml]#%1 %2").arg(code).arg(str));
    }

    function isOnline() { return REST.gl_token != ""; }
    // function isOnline() { return root.resttoken != "" }

    function isTaxMode() { return root.cdtoken != "" && root.cdhost != "" && !root.cdhost.startsWith('*') }

    function setClientFromBind(){
        if (stack.currentItem.crntClient !== undefined){
            btnClient.visible = true
            btnClient.clName = stack.currentItem.crntClient.name
            btnClient.clBonus = Number(stack.currentItem.crntClient.bonusTotal) !== 0
                            ? Number(stack.currentItem.crntClient.bonusTotal).toFixed(0) : ""
        } else {
            btnClient.visible = false
            btnClient.clName = ""
            btnClient.clBonus = ""
        }

    }

    // for context menu
    Component{
        id: activateBind
        Action{
            id: croot
            property int cindex
            text: croot.ctext
            onTriggered:  stack.currentIndex = cindex
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

    Action {
        id: testAction
        text: "TEST"
        checkable: true
        checked: testLoader.active
//        icon.name: "edit-copy"
//        shortcut: StandardKey.Copy
        onTriggered: {
            testLoader.active = checked;
            // LibAcnt.dbBalance(Db, "substr(acntno,1,3)='300'")
            // const a = LibItem.getItemById(Db, "200023")
            // const a = LibItem.getItemById(Db, "")
            // Lib.log("#w93 a=" + JSON.stringify(a))
            // LibItem.fillFolderCache(Db)
        }
    }


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
        }
    }

    Action {
        id: bindFactureAction
        property string code: "facture"
        property int dfltAmnt: 1
        text: "Нова Фактура"
        onTriggered: {
            actionBind.trigger(bindFactureAction)
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
                        const component = Qt.createComponent("Bind.qml");
                        if (component.status === Component.Ready) {
                            const newObj = component.createObject(stack,
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
                                });
                            // newObj.acnts = root.acnts
                            // newObj.dfltAmnt = source.dfltAmnt
                            // newObj.dfltClient = Lib.getClient(Db)
                            // newObj.cashAcnt = Lib.getAccount(Db,acnts.cash)
                            // newObj.dfltAcnt = Lib.getAccount(Db)
                            newObj.vkEvent.connect( (id, param)=>{
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
                            // newObj.forceActiveFocus()
                            newObj.startBind()
                            stack.currentIndex = stack.count - 1;
                        } else {
                            Lib.log("Помилка завантаження:" + component.errorString(), "main", "EE" );
                        }

                         /*
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
                         */
        }
    }

    Action {
        id: removeBindAction
        enabled: stack.count > 1
        text: "Видалити поточний"
        onTriggered: {
            if (stack.count > 1) { // Залишаємо хоча б один екран
                    const itemToRemove = stack.currentItem;

                    stack.currentIndex--;

                    itemToRemove.destroy();
            }

        }
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
        id: winBalanceAction
        text: "Залишки"
        checkable: true
        checked: balanceLoader.active
        onTriggered:  balanceLoader.active = checked;
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

            for (let i =0; i < stack.count; ++i ) {
                // Lib.log(String("#w9j id=%1 codeid=%2").arg(i).arg(stack.children[i].codeid))
                if (stack.contentChildren[i].codeid === "settings") {
                    stack.currentIndex = i
                    return
                }
            }
            const component = Qt.createComponent("Settings.qml");
            if (component.status === Component.Ready) {
                const newObj = component.createObject(stack,
                    {
                        dfltTerminal: {term:root.term, posPrinter: root.posPrinter, checkAmnt:root.checkAmnt, checkAutoPrint:root.checkAutoPrint, checkPrintDcm: root.checkPrintDcm },
                        dfltAcnt: { cash: root.acnts.cash, trade: root.acnts.trade, bulk: root.acnts.bulk, incas: root.acnts.incas, profit: root.acnts.profit  },
                        dfltREST: { resthost: root.resthost, restapi: root.restapi, restuser: root.restuser, restpassword: root.restpassword, resttoken: root.resttoken },
                        dfltCashDisc: { cdhost: root.cdhost, cdprefix: root.cdprefix, cdcash: root.cdcash, cdtoken: root.cdtoken }
                    })
                newObj.vkEvent.connect( (id, param) => {
                     if (id === "saveTerminal"){
                                               root.term = newObj.dfltTerminal.term
                                               root.posPrinter = newObj.dfltTerminal.posPrinter
                                               root.checkAmnt = newObj.dfltTerminal.checkAmnt
                                               root.checkAutoPrint = newObj.dfltTerminal.checkAutoPrint
                                               root.checkPrintDcm = newObj.dfltTerminal.checkPrintDcm
                                           } else if (id === "saveAcnts"){
                                                                     root.acnts = newObj.dfltAcnt
                                                                     Db.dbUpdate("update settings set acnts = '" + JSON.stringify(newObj.dfltAcnt) + "' where rowid=1;")
                     } else if (id === "loginREST"){
                                               root.resthost = newObj.dfltREST.resthost
                                               root.restapi = newObj.dfltREST.restapi
                                               root.restuser = newObj.dfltREST.restuser
                                               root.restpassword = newObj.dfltREST.restpassword
                                               root.resttoken = ''
                                               REST.login(restuser, restpassword, (err) => {
                                                   // Lib.log("#984u token="+token);
                                                   if (err === null){
                                                       root.resttoken = REST.gl_token
                                                   } else {
                                                       logView.appenr(err, 0)
                                                   }
                                                   newObj.dfltREST = { resthost: root.resthost, restapi: root.restapi, restuser: root.restuser, restpassword: root.restpassword, resttoken: root.resttoken }
                                               } )
                     } else if (id === "saveCD"){
                                               root.cdhost = newObj.dfltCashDisc.cdhost
                                               root.cdprefix = newObj.dfltCashDisc.cdprefix
                                               root.cdcash = newObj.dfltCashDisc.cdcash
                                               root.cdtoken = newObj.dfltCashDisc.cdtoken
                     } else {
                         logView.append("[Bind] Bad event", 1)
                     }
                })
                stack.currentIndex = stack.count - 1;

            } else {
                Lib.log("Помилка завантаження Settings.qml:" + component.errorString(), "main", "EE" );
            }




/*            bindContainer.push("Settings.qml", {
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
            */
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
                                // dbg("Shift upload ...", "#w7g"); return;


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
                    stack.currentItem.newRefused(param)
                }
            }
        }
    }

    Loader{
        id: balanceLoader
        active: false
        source: 'Balance.qml'
        onActiveChanged: if (active) {
                            item.dbDriver = Db
                            item.visible = true
                            item.title = String("%1(%2)").arg(root.title).arg("Balance")
                         }
        Connections {
            target: balanceLoader.item
            function onClosing() { balanceLoader.active = false ; }
        }
    }

    Loader{
        id: testLoader
        active: false
        source: 'Balance.qml'
        onActiveChanged: if (active) {
                            item.dbDriver = Db
                            item.visible = true
                            item.title = String("%1(%2)").arg(root.title).arg("Balance")
                         }
        Connections {
            target: testLoader.item
            function onClosing() { testLoader.active = false ; }
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

                             item.funcCreateDcm = (atclid) => {stack.currentItem.newDcm(atclid);
                                 }
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
                            stack.currentItem.crntClient = Lib.getClient(Db,id);
                            stack.currentItem.crntAcnt = Lib.getAccount(Db)
                            setClientFromBind()
                        } else if (selectPopup.code==="database") {        // database
                            root.dbname = id
                            // openConnection(id)
                        } else if (selectPopup.code==="acntno") {        // acntno
                            stack.currentItem.crntAcnt = Lib.getAccount(Db, id)
                            // setAccount(id)
                        } else if (selectPopup.code==="article") {
                            stack.currentItem.newDcm(id)
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


    // StackLayout {
    //     id: stack
    //     anchors.fill: parent
    //     // width: 0; height: 0
    //     clip: true
    //     // onCountChanged: Lib.log(String("#18g count=%1").arg(count))
    //     onCurrentIndexChanged: stack.children[stack.currentIndex].forceActiveFocus()
    // }

    SwipeView {
        id: stack

        // currentIndex: 1
        anchors.fill: parent

        onCurrentIndexChanged: {
            headerTitle.text = currentItem.title
            setClientFromBind()

            stack.currentItem.forceActiveFocus()
            // dbg("currentIndex=" + currentIndex
            //             ,"63gb")
        }
    }

    PageIndicator {
        id: indicator

        count: stack.count
        currentIndex: stack.currentIndex

        anchors{bottom: stack.bottom;
            horizontalCenter: parent.horizontalCenter;
            bottomMargin: 65;}
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
            // border{color:"lightsteelblue"; width: 2}
            width: parent.width
            height: childrenRect.height // 30
            // color: stackBind.children[stackBind.currentIndex].state === "taxcheck" ? "khaki" : "transparent"
            RowLayout {
                width: parent.width
                // anchors.fill: parent
    //            width: parent.width
                ToolButton {    //  ☰
                    text: "☰"
                    onClicked: naviMenu.open()
                    flat: true
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
                        MenuItem { action: winBalanceAction; }
                        MenuItem { action: winClientAction; }
                        // MenuItem { action: winStatAction; }      // TODO
                        MenuItem { action: winRateAction; }
                        MenuItem { action: winShiftAction; }
                        MenuSeparator {  padding: 5; }
                        Menu{
                            id: serviceMenu
                            title: "Сервіс"
                            MenuItem { action: winCashWizardAction; }
                            MenuSeparator {  padding: 5; }
                            MenuItem { action: winTaxServiceAction; }
                            MenuItem { action: changeDBAction; }
                            MenuSeparator {  padding: 5; }
                            MenuItem { action: actionSetting; }
                        }
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
                    font.pointSize: 20
                    // text: stack.currentItem.title
                }
                Item{
                    id: btnClient
                    Layout.preferredWidth: childrenRect.width
                    Layout.preferredHeight: childrenRect.height
                    property string clName
                    property string clBonus
                    Row {
                        // visible: stack.currentItem.crntClient !== undefined
                        ToolButton{
                            text: btnClient.clName
                            // text: stack.currentItem.crntClient !== undefined ? stack.currentItem.crntClient.name : ''
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
                            // visible: stack.currentItem.crntClient !== undefined && stack.currentItem.crntClient.id !== ''
                            font.pointSize: 16
                            text:"⌫"
    //                        flat: true
    //                        icon.source:"qrc:/icon/undo.svg"
                            onClicked: {
                                stack.currentItem.crntClient = Lib.getClient(Db);
                                setClientFromBind()
                            }
                        }
                        Label{
                            // visible: stack.currentItem.crntClient !== undefined && Math.abs(Number(stack.currentItem.crntClient.bonusTotal)) >= 0.01
                            Layout.preferredHeight: 35
                            color:'slategray'
                            text: btnClient.clBonus
                            // text: stack.currentItem.crntClient !== undefined ? Number(stack.currentItem.crntClient.bonusTotal).toFixed(0) : ''
                            MouseArea{
                                anchors.fill: parent
                                onDoubleClicked: {
                                    stack.currentItem.newBonus()
                                }

                            }

                        }
                    }

                }


                ToolButton {    // ⋮
                    id:contextMenu_toolbtn
                    text: qsTr("⋮")

                    onClicked:  contextMenu.popup()

                    Menu{
                        id: batchMenu
                        title: "Додатково"
                    }

                    Menu{
                        id: contextMenu
                        y: parent.height

                        onVisibleChanged: {
                            // dbg("contextMenu_toolbtn vsbl="+ visible, "#72js")
                            let i =0
                            if (visible){
                                if (stack.currentItem.vkContextActions !== undefined){
                                      for (i =0; i < stack.currentItem.vkContextActions.length; ++i){
                                          contextMenu.addAction(stack.currentItem.vkContextActions[i])
                                      }
                                }
                                if (stack.currentItem.vkBatchActions !== undefined){
                                    for (i =0; i < stack.currentItem.vkBatchActions.length; ++i){
                                        batchMenu.addAction(stack.currentItem.vkBatchActions[i])
                                    }
                                    contextMenu.addMenu(batchMenu)
                                }

                                contextMenu.addItem( Qt.createQmlObject('import QtQuick.Controls; MenuSeparator {}',
                                                                                              contextMenu.contentItem,
                                                                                              "dynamicSeparator") )
                                for (i =0; i < stack.count; ++i) {
                                    contextMenu.addAction(activateBind.createObject(contextMenu,
                                                                                    { cindex: i,
                                                                                      text: String(i === stack.currentIndex ? "<b>%1. %2</b>" : "%1. %2").arg(i).arg(stack.contentChildren[i].textForMenu())
                                                                                    }))

                                }
                            } else {
                                for (i =batchMenu.count -1; i >=0; --i) batchMenu.removeItem(batchMenu.itemAt(i))
                                for (i =contextMenu.count -1; i >=0; --i) contextMenu.removeItem(contextMenu.itemAt(i))
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
        // bindCheckAction.trigger()
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
