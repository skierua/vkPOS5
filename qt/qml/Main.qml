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
    title: String("vkPOS5#%1").arg("2.10")

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

            if (vkStack.depth){
                vkStack.currentItem.dfltClient = Lib.getClient(Db)
                vkStack.currentItem.cashAcnt = Lib.getAccount(Db,acnts.cash)
                vkStack.currentItem.dfltAcnt = Lib.getAccount(Db)
                vkStack.currentItem.startBind()
            }
            // Lib.log("#72g dfltAcnt="+JSON.stringify(vkStack.currentItem.dfltAcnt))

            if (root.crntShift.shftend !== '') {   // shift is closed
                // Lib.log("222 here")
                actionShift.trigger();
            } else {
                // Lib.log("111 here")
                if (root.crntShift.shftdate !== Qt.formatDateTime(new Date(), "yyyy-MM-dd")){
                    if (Lib.isIncas(Db, root.acnts)) {
                      actionShift.trigger()
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
    // onDbnameChanged:  Lib.openConnection(dbDriver, dbname)

    property real z0: 0.0000001
    property var crntShift: { "id":0,"errid":1,"errname":"","shftdate":"","shftbegin":"","shftend":"","cshr":"","cshrname":""}
    // property var cashier: {"id":"", "name":""}
    property var acnts: { "cash":"3000", "incas":"3003ELSV", "trade":"3500", "bulk":"3501", "profit":"3607-55" }


    property string resthost: "http://localhost"
    property string restapi: "/api/dev"
    property string resttoken: ""
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

    function isOnline() { return root.resttoken != "" }

    function isTaxMode() { return root.cdhost != "" && !root.cdhost.startsWith('*') }

    function upload_tran(jbind, uplAcnt = true){

        if (jbind === undefined) { return; }

        if (root.resttoken != ""){      // isOnline

            REST.postRequest2(resthost+restapi+"/dcms?api_token="+resttoken, {"term":root.term,"reqid":"upd","shop":root.term,"data":jbind},
                (err,resp) => {
                if (err === null){
                     // Lib.log("#278 main "+JSON.stringify(resp))
                } else {
                    Lib.log(err.text, 'REST.postRequest2', err.code)
                }
            });

            if (uplAcnt) {
                const jacnt = Lib.uploadAcnt(Db, true)
                if (jacnt && jacnt.rows.length) {
                    REST.postRequest2(resthost+restapi+"/accounts?api_token="+resttoken, {"term":root.term,"reqid":"upd","shop":root.term,"data":jacnt.rows},
                        (err,resp) => {
                        if (err === null){
                           // Lib.log("#278 main "+JSON.stringify(resp))
                        } else {
                          Lib.log(err.text, 'REST.postRequest2', err.code)
                        }
                    });
                }
            }

        }
    }

    function taxUploadBind(bindid){
        if (isTaxMode()) {



            Lib.log("#94hn TAX MODE IS BLOCKED !!! \n main.taxUploadBind id=" + bindid); return;



            Lib.bindFromDb(Db, bindid,
               (err,bind) => {
                    if (err){
                        Lib.log(err, "Main>bindFromDb", "EE")
                    } else {
                       Lib.cdtaxFromBind(Db, bind,
                        (err, taxbind)=>{
                            if (err){
                                Lib.log(err, "Main>cdtaxFromBind", "EE")
                            } else {
                                taxbind.api_token = cdtoken
                                taxbind.num_fiscal = cdcash
                            /*    CashDesk.postRequest(cdhost + cdprefix + String("/check/sale?api_token=%1").arg(cdtoken), taxbind,
                                                    (taxerr, taxresp) =>
                                                     {
                                                         if (err){
                                                        // TODO
                                                         } else {
                                                             taxServiceLoader.item.showResp({"code":"info", "sender":"XReport",
                                                                 // "resp": "XReport OK #" +jsresp.user_signature.user_id + " "+jsresp.user_signature.full_name,
                                                                 "resp": "XReport OK #" + taxresp,
                                                                 "tm":new Date()});
                                                         }
                                                     } ) */
                            /*    taxRequest(String("/check/sale?api_token=%1").arg(cdtoken), taxbind, (response) => {
                                // Lib.log(response.status);
                                // Lib.log(response.headers);
                                // Lib.log( response.content);
                                let jsresp = JSON.parse(response.content)
                                while (~response.content.indexOf(',"')){ response.content = response.content.replace(',"',',\n"'); }
                                if (response.status === 200) {
                                 let isPlainText = response.contentType.length === 0
                                 if (isPlainText && taxServiceLoader.active) {
                                     taxServiceLoader.item.showResp({"code":"info", "sender":"XReport",
                                         // "resp": "XReport OK #" +jsresp.user_signature.user_id + " "+jsresp.user_signature.full_name,
                                         "resp": "XReport OK #" +response.content,
                                         "tm":new Date()});
                                 }
                                } else if (response.status === 0){
                                 taxServiceLoader.active = true
                                 taxServiceLoader.item.showResp({"code":"error", "sender":"ping", "resp":'Site connection error', "tm":new Date()});
                                } else {
                                 taxServiceLoader.active = true
                                 taxServiceLoader.item.showResp({"code":"error", "sender":"ping", "resp":"Status="+response.status+": "+response.content, "tm":new Date()});
                                }
                                }); */
                            }
                        })
                    }
                })
        }
    }

    Action {
        id: actionLogin
        text: "Login"
        onTriggered: {
            resttoken = ''
            if ( resthost != "") {
                REST.loginRequest(resthost+restapi+"/auth", restuser, restpassword, (err, token) => {
                    // Lib.log("#984u token="+token);
                    if (err === null){
                        resttoken = token
                    } else {
                        Lib.log(err.text, 'lib.login', err.code)
                    }
                });
            }

        }
    }

    Action {
        id: testAction
        text: "TEST"
//        icon.name: "edit-copy"
//        shortcut: StandardKey.Copy
        onTriggered: {
            Lib.log(Lib.ttest(Db))
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

    /**
      param { acntno, code, amnt, price, dsc, bns, pratt, retfor}
     */
    function new3Dcm(vaid, param) {
//        console.log("#48h vaid="+vaid+ " amnt="+vamnt)
        var n2d = {"price":0, "dsc":0, "bns":0, "tag":"", "retfor":""}
        n2d.atcl = Lib.getArticle(Db,vaid)
         if (param === undefined){
//            param = ({})
            n2d.acnt = vkStack.currentItem.crntAcnt
            n2d.amnt = vkStack.currentItem.crntAmnt
            n2d.code = Number(n2d.amnt) < 0 ? "pay:out" : "pay:in"
        } else {
            n2d.acnt = (param.acntno !== undefined) ? Lib.getAccount(Db,param.acntno) : vkStack.currentItem.crntAcnt;
            n2d.amnt = param.amnt || vkStack.currentItem.crntAmnt
            n2d.code = param.code || (Number(n2d.amnt) < 0 ? "pay:out" : "pay:in")
            n2d.retfor = param.retfor || ""
        }

        if ( !(Number(n2d.atcl.mask) & Number(n2d.acnt.mask)) ){
            msgDialog.code = 'Warning'
            msgDialog.message = 'Main\n'+"#37h currency/article and account missmatch ["+n2d.atcl.mask+"] & ["+n2d.acnt.mask +"]"
            msgDialog.open()
            vkStack.currentItem.startNewRow();
            return false;
        }
//        if (param === undefined) { param = {"price":"0", "offer":"0", "dsc":"0" }; }
//        if (vamnt !== undefined && vamnt !==''){ vkStack.currentItem.crntAmnt = vamnt; }
        let jpr = {"price":"0", "offer":"0", "dsc":"0" };
        if (Number(n2d.acnt.trade) === 1) {
            if (param !== undefined){
                n2d.price = param.price || 0;
                n2d.dsc = param.dsc || 0;
                n2d.bns = param.bns || 0;
                n2d.pratt = param.price > z0 ? 0 : 7
                if (Number(n2d.atcl.mask) === 4 || vkStack.currentItem.state === "incas") {
                    n2d.code = param.code || vkStack.currentItem.crntCode
                } else {
                    n2d.code = param.code || (Number(n2d.amnt) < 0 ? "trade:sell" : "trade:buy");
                }
            } else {
                n2d.pratt = 7
                if (Number(n2d.atcl.mask) === 4 || vkStack.currentItem.state === "incas") {
                    n2d.code = vkStack.currentItem.crntCode
                } else {
                    n2d.code = (Number(n2d.amnt) < 0 ? "trade:sell" : "trade:buy")
                }
            }


            if (n2d.price < z0) {   // price undefined
                let vj = ({})
                let prid = ""
                if (vkStack.currentItem.state !== "facture"){
                    vj = JSON.parse(Db.dbSelectRows(
                                String("select item as pkey, price.price/price.qtty as price, coalesce(selloffer.price,0)/coalesce(selloffer.qtty,1) as offer, coalesce(selldsc.price,0) as dsc
                                        from price left join selloffer on(item=selloffer.article) left join selldsc on(item=selldsc.article)
                                        where item = '%1' and prbidask=%2;").arg(vaid).arg(n2d.code === 'trade:sell'? '-1':'1')))
                    if (vj.rows.length) {
                        prid = vj.rows[0].pkey
                    }
//                    console.log("#4h7 n2d data="+JSON.stringify(vj))
                }

                if (prid === ""){
                    vj = JSON.parse(Db.dbSelectRows(
                                String("select article as pkey, %1 as price, 0 as offer, 0 as dsc from acntrade where article = '%2' and acntno='%3';")
                                .arg(n2d.code === "trade:sell" ? 'lastpricesell':'lastpricebuy')
                                .arg(n2d.atcl.id)
                                .arg(n2d.acnt.acntno)))
                }
                if (vj.rows.length){
                    jpr = vj.rows[0];
                    if (vj.rows[0].offer !== undefined && Number(vj.rows[0].offer) > z0 ){
                        n2d.price = Number(vj.rows[0].offer);
                        n2d.tag = ' #АКЦІЯ!'
                        n2d.pratt = 0
                    }
                    if (n2d.price < z0){
                        n2d.pratt = 7
                        n2d.price = Number(vj.rows[0].price);
                        if(Number(vj.rows[0].dsc) > z0){
                            n2d.dsc = Number(vj.rows[0].dsc);
                            n2d.pratt = 0
                        }
                    }
                }
            }
        }
       // Lib.log("#927b main param="+JSON.stringify(n2d))
        return n2d;
    }

    Timer{
        id: quitTimer
        interval: 2500
        repeat: false
        running: false
        onTriggered: {
            closeChildWindow()
            Qt.quit()
        }
    }

    Action {
        id: actionBind
        text: "Чек | Фактура"        //qsTr("Check")
//        icon.name: "edit-copy"
//        shortcut: StandardKey.Copy
        onTriggered: {
            while (vkStack.depth >1) {
                vkStack.pop()
            }
            if (vkStack.depth === 1){
                if (vkStack.currentItem.codeid === 'bind'){
                    //
                    return;
                }
            } else {
                vkStack.push("Bind.qml",
                               {
                                fnCreateDcm: (vaid, param) => { return new3Dcm(vaid, param)},
                                printDcm: checkPrintDcm,
                                autoPrint: checkAutoPrint,
                                dfltAmnt: Number(checkAmnt),
                               },
                               StackView.PushTransition)
                vkStack.currentItem.vkEvent.connect( (id, param)=>{
                    if (id === 'drawer'){
                        drawer2Right.open();
                    } else if (id === 'findText') {
                        // findText(text);
                        Lib.findText(Db, param.text, param.mask,
                            (err, res)=>{
                                if (err){
                                    msgDialog.code = 'Info'
                                    msgDialog.message = 'Main/bind\nНічого не знайдено'
                                    msgDialog.open()
                                    // vkStack.currentItem.startNewRow()
                                } else {
                                    if (res.length === 1){
                                     // create docum
                                        if (Number(res[0].mask)===0){
                                            vkStack.currentItem.crntClient = Lib.getClient(Db,res[0].id);
                                        } else {
                                            vkStack.currentItem.insert(new3Dcm(res[0].id))
                                        }
                                    } else {
                                     // choice article from list
                                     selectPopup.code = res[0].mask === "0" ? "client" : "article"
                                     selectPopup.jsdata = res
                                     selectPopup.open()
                                    }
                                }
                            })
                    } else if (id === 'tranBind'){
                        const jbind = vkStack.currentItem.makeBind()
                        const bindId = Lib.tranBind(Db, jbind);
                        if (bindId !== 0 ){

                            upload_tran(jbind)

                            if (root.checkPrintDcm !== undefined && root.checkPrintDcm !== ""){
                                if (param === 1) {
                                    Prn.saveCheck(jbind)
                                    Prn.printCheck(jbind)
                                } else if (param === 2 && root.checkAutoPrint !== undefined && root.checkAutoPrint !== 0) {
                                    Prn.saveCheck(jbind)
                                    Prn.printCheck(jbind)
                                }
                            }
                            taxUploadBind(bindId)
                            vkStack.currentItem.startBind()
                        }

                    } else if (id === 'creditAcntClicked'){
                        // selectAcnt(param.cashno, param.clid, param.mode )
                        Lib.getAcntList(Db, param.cashno, param.clid, param.mode)
                        selectPopup.code = "acntno"
                        selectPopup.jsdata = Lib.getAcntList(Db, param.cashno, param.clid, param.mode);
                        // Lib.log("#34rs HERE")
                        selectPopup.open()
                    } else if (id === 'crntAcntToTrade'){
                        vkStack.currentItem.crntAcnt = Lib.getAccount(Db);
                    } else if (id === 'dialog'){
                        msgDialog.code = 'Error'
                        msgDialog.message = 'Check\n'+param
                        msgDialog.open()
                    } else if (id === 'log'){ Lib.log(param.text,"Bind");
                    } else {
                        // bad event
                    }
                  })
                vkStack.currentItem.startBind()
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
        id: winClientAction
        checkable: true
        checked: clientLoader.active
        text: "Клієнти"
        onTriggered: {
            clientLoader.active = checked;
        }
    }

    Action {
        id: actionShift
        text: qsTr("Зміна")
        enabled: vkStack.currentItem.codeid !== 'shift'
        onTriggered: {
            closeChildWindow()
            if (vkStack.depth >1) {
                vkStack.pop()
            }

            vkStack.push("Shift.qml",
                           {
                             vshift: Lib.crntShift(Db),
                             vcashiers: Lib.getSQLData(Db,"select '' code, ' без касира' note, '' psw union select code, note, psw from cashier order by note;"),
                             // Lib.log(JSON.stringify(shift.vshift))
                             toBulk: (root.acnts.bulk !== undefined && root.acnts.bulk !== ""),
                           },
                           StackView.PushTransition)

            vkStack.currentItem.vpopulate(Lib.getIncas(Db))

            vkStack.currentItem.vkEvent.connect( (id, param)=>{
                    if (id === "shift.open") {
                        const isNewMonth = (root.crntShift.shftdate.substring(0,7) !== Qt.formatDateTime(new Date(), "yyyy-MM") )

                        if( Lib.newShift(Db, root.acnts, param/*, {"url":root.resthost+root.restapi, "token": root.resttoken, "term": root.term}*/) ) {
                            root.crntShift = Lib.crntShift(Db)
                            if (isNewMonth && root.acnts.profit !== undefined &&  root.acnts.profit !== ""){
                                const jbind = Lib.makeBind_balancingTrade(Db, root.acnts/*, {"url":root.resthost+root.restapi, "token": root.resttoken, "term": root.term}*/);
                                const bindId = Lib.tranBind(Db, jbind);
                                if (bindId !== 0 ){
                                    upload_tran(jbind)
                                }
                            }

                            if (root.resttoken != ""){      // isOnline
                                REST.postRequest2(resthost+restapi+"/accounts?api_token="+resttoken, {"term":root.term,"reqid":"del","shop":root.term},
                                    (err,resp) => {
                                    if (err === null){
                                       // Lib.log("#278 main "+JSON.stringify(resp))
                                    } else {
                                      Lib.log(err.text, 'REST.postRequest2', err.code)
                                    }
                                });

                                const jacnt = Lib.uploadAcnt(Db, false)
                                if (jacnt && jacnt.rows.length) {
                                    REST.postRequest2(resthost+restapi+"/accounts?api_token="+resttoken, {"term":root.term,"reqid":"upd","shop":root.term,"data":jacnt.rows},
                                        (err,resp) => {
                                        if (err === null){
                                           // Lib.log("#278 main "+JSON.stringify(resp))
                                        } else {
                                          Lib.log(err.text, 'REST.postRequest2', err.code)
                                        }
                                    });
                                }

                            }

                            vkStack.pop()
                        }
                    } else if(id === "shift.cancel") {
                        if(Lib.crntShift(Db).shftend !== "") {
                           actionShift.trigger();
                        } else {
                           vkStack.pop()
                        }

                    } else if(id==="shift.close") {
                        // console.log("#6ev Main shiftid="+ JSON.stringify(param)); return;
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
                                upload_tran(jbinds[r], r === (jbinds.length -1))
                            }
                        }

                        if (Lib.closeShift(Db, param)){
                        /*  REPORT proceed by dayly cron on server !!!
                            const dnow = new Date(param.shdate)
                            const dprev = new Date(dnow.getFullYear(), dnow.getMonth()-1)
                            const dnext = new Date(dnow.getFullYear(), dnow.getMonth()+1)
                            let ifrom = param.shdate.substring(0,7)
                            let ito = Qt.formatDate( dnext, "yyyy-MM")
                            let jrep = Lib.uploadReport(Db, ifrom, ito);
                            if (jrep.length) {  // month report stream  -- profit
                                REST.postRequest2(resthost+restapi+"/reports?api_token="+resttoken, {"term":root.term,"reqid":"upd", "period":ifrom,"shop":root.term,"data":jrep},
                                      (err,resp) => {
                                      if (err === null){
                                         // Lib.log("#278 main "+JSON.stringify(resp))
                                      } else {
                                        Lib.log(err.text, 'REST.postRequest2', err.code)
                                      }
                                  });
                            }
                            if (dnow.getDate() < 4){
                                ifrom = Qt.formatDate( dprev, "yyyy-MM")
                                ito = param.shdate.substring(0,7)
                                jrep = Lib.uploadReport(Db, ifrom, ito);
                                REST.postRequest2(resthost+restapi+"/reports?api_token="+resttoken, {"term":root.term,"reqid":"upd", "period":ifrom,"shop":root.term,"data":jrep},
                                      (err,resp) => {
                                      if (err === null){
                                         // Lib.log("#278 main "+JSON.stringify(resp))
                                      } else {
                                        Lib.log(err.text, 'REST.postRequest2', err.code)
                                      }
                                  });
                            }
                                                            */
                        }

                        root.visible = false;
                        quitTimer.start()
                    } else if(id==="shift.incas") {
                        // Lib.log("#32yh Main "+ JSON.stringify(param)); return;
                        const bindId = Lib.tranBind(Db, param);
                        if (bindId !== 0 ){
                            upload_tran(param)
                        }
                        vkStack.currentItem.vpopulate(Lib.getIncas(Db))
                        // Lib.incasShift(Db, root.acnts, root.crntShift.cshr, param, {"url":root.resthost+root.restapi, "token": root.resttoken, "term": root.term})
                        // actionShift.trigger()
                    } else {
                    // error
                    }

            })
        }
    }

    Action {
        id: actionSetting
        text: qsTr("Settings")
        onTriggered: {
            closeChildWindow()
            if (vkStack.depth >1) {
                vkStack.pop()
            }

            vkStack.push("Settings.qml", {
                            dfltTerminal: {term:root.term, posPrinter: root.posPrinter, checkAmnt:root.checkAmnt, checkAutoPrint:root.checkAutoPrint, checkPrintDcm: root.checkPrintDcm },
                            dfltAcnt: { cash: root.acnts.cash, trade: root.acnts.trade, bulk: root.acnts.bulk, incas: root.acnts.incas, profit: root.acnts.profit  },
                            dfltREST: { resthost: root.resthost, restapi: root.restapi, restuser: root.restuser, restpassword: root.restpassword, resttoken: root.resttoken },
                            dfltCashDisc: { cdhost: root.cdhost, cdprefix: root.cdprefix, cdcash: root.cdcash, cdtoken: root.cdtoken }
                         }
                             , StackView.PushTransition)

            vkStack.currentItem.vkEvent.connect( (id, param)=>{
                if (id === "saveTerminal") {
                    root.term = vkStack.currentItem.dfltTerminal.term
                    root.posPrinter = vkStack.currentItem.dfltTerminal.posPrinter
                    root.checkAmnt = vkStack.currentItem.dfltTerminal.checkAmnt
                    root.checkAutoPrint = vkStack.currentItem.dfltTerminal.checkAutoPrint
                    root.checkPrintDcm = vkStack.currentItem.dfltTerminal.checkPrintDcm
                } else if (id === "saveAcnts") {
                    // Lib.log('#893 param=' + JSON.stringify(param))
                    root.acnts = vkStack.currentItem.dfltAcnt
                    Db.dbUpdate("update settings set acnts = '" + JSON.stringify(vkStack.currentItem.dfltAcnt) + "' where rowid=1;")
                } else if (id === "loginREST") {
                    root.resthost = vkStack.currentItem.dfltREST.resthost
                    root.restapi = vkStack.currentItem.dfltREST.restapi
                    root.restuser = vkStack.currentItem.dfltREST.restuser
                    root.restpassword = vkStack.currentItem.dfltREST.restpassword
                    root.resttoken = ''
                    REST.loginRequest(resthost+restapi+"/auth", restuser, restpassword, (err, token) => {
                        // Lib.log("#984u token="+token);
                        if (err === null){
                            root.resttoken = token
                        } else {
                            Lib.log(err.text, 'lib.login', err.code)
                        }
                        vkStack.currentItem.dfltREST = { resthost: root.resthost, restapi: root.restapi, restuser: root.restuser, restpassword: root.restpassword, resttoken: root.resttoken }
                    } )
                } else if (id === "saveCD") {
                    root.cdhost = vkStack.currentItem.dfltCashDisc.cdhost
                    root.cdprefix = vkStack.currentItem.dfltCashDisc.cdprefix
                    root.cdcash = vkStack.currentItem.dfltCashDisc.cdcash
                    root.cdtoken = vkStack.currentItem.dfltCashDisc.cdtoken
                } else {
                    // bad event
                }
            })
        }
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
            const bindId = Lib.tranBind(Db, jbind);
            if (bindId !== 0 ){
                upload_tran(jbind)
            }
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
                if (id === "documView.return"){
                    actionBind.trigger();
                    const cl = Lib.getSQLData(Db, "select coalesce(client,'') as cl from documall where id ="+param.pid);
                    if (!cl.length){
                        msgDialog.code = 'Error'
                        msgDialog.message = "Неможливо визначити клієнта."
                        msgDialog.open()
                        return;
                    }
                    // console.log("#94j cl="+cl+" bindclid="+stackBind.children[stackBind.currentIndex].crntClient.id)
                    if (vkStack.currentItem.crntClient.id === "" ){
                        vkStack.currentItem.crntClient = Lib.getClient(Db, cl[0].cl);
                    }
                    if (vkStack.currentItem.crntClient.id !== cl[0].cl){
                        msgDialog.code = 'Error'
                        msgDialog.message = "Клієнт Чеку вже визначений і відрізняється від чеку повернення"
                        msgDialog.open()
                        return;
                    }
                    vkStack.currentItem.insert( new3Dcm(param.atclid,
                                { "acntno":param.acntcdt,
                                "code":param.dcmtype,
                                "amnt": String(0-Number(param.amount)),
                                "price":Math.abs(Number(param.eq)/Number(param.amount)),
                                "dsc":Math.abs(Number(param.dsc)/Number(param.eq)),
                                "bns":Math.abs(Number(param.bns)/Number(param.eq)),
                                "pratt":0, "retfor":param.dcmid}))
                } else { Lib.log("Bad request","DcmView"); }

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
                             item.uri = resthost + restapi + "/rates?api_token=" + resttoken
                             item.queryData = {"term": root.term, "reqid": "sel", "shop": root.term}
                             item.db = Db
                         }
        Connections {
            target: rateLoader.item
            function onClosing() { rateLoader.active = false; }

            function onVkEvent(id,param) {
                if (id === "rate.newDocum"){
                    if (vkStack.currentItem.codeid === 'bind'){ vkStack.currentItem.insert( new3Dcm(param) ); }
                }
            }
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
                            vkStack.currentItem.crntClient = Lib.getClient(Db,id);
                            vkStack.currentItem.crntAcnt = Lib.getAccount(Db)
                        } else if (selectPopup.code==="database") {        // database
                            root.dbname = id
                            // openConnection(id)
                        } else if (selectPopup.code==="acntno") {        // acntno
                            vkStack.currentItem.crntAcnt = Lib.getAccount(Db, id)
                            // setAccount(id)
                        } else if (selectPopup.code==="article") {
                            vkStack.currentItem.insert(new3Dcm(id))
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
        id: msgDialog
        width:300
//        height:300
        property string code: 'Info'
        property string message: ''

        anchors.centerIn: parent
        modal: true
        title: 'Повідомлення'
        contentItem: Text{text: msgDialog.message; wrapMode: Text.Wrap;}

        footer: DialogButtonBox {
            standardButtons: Dialog.Ok      //|Dialog.Cancel
//            alignment: Qt.AlignHCenter
            Keys.onEnterPressed: msgDialog.accept()
            Keys.onReturnPressed: msgDialog.accept()
            Keys.onEscapePressed: msgDialog.close()
            onVisibleChanged: if (visible) forceActiveFocus()
        }
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
                    msgDialog.code = 'Error'
                    msgDialog.message = 'main'+'\n'+'Prind bind paraneter error'
                    msgDialog.open()
                }
            } else if (code === "askCloseShift"){       // { "text" : "Закрити попередню зміну ?","shid":crsh.id,"shdate":crsh.shftdate, "cshr":crsh.cshr }
                // Lib.log("#7rh askCloseShift"); return;
                if (Lib.isIncas(Db, root.acnts)) {
                    actionShift.trigger();
                } else {
                    Lib.closeShift(Db, {"shid":jdata.shid,"shdate":jdata.shdate, "cshr":jdata.cshr}, {"url":root.resthost+root.restapi, "token": root.resttoken, "term": root.term})
                    quitTimer.start()
                }
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
        id: vkStack
        anchors.fill: parent
        // onDepthChanged: Lib.log("#6qg current depth="+ depth)
        onCurrentItemChanged:  {
        // Lib.log("#2804 vkStack =" +depth )
        }
        onDepthChanged:  {
            // Lib.log("#2804 vkStack =" + depth )
        }
    }

    LogView{
        id: logView
        width: parent.width
        height: (count * 25 < parent.height / 4) ? count * 25 : parent.height / 4
        z: 10
        anchors.bottom: parent.bottom
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
                        MenuItem { action: actionBind; }
                        // MenuItem { action: pageTaxAction; }
                        MenuItem { action: actionShift; }
                        MenuSeparator { padding: 5; }
                        MenuItem { action: winDcmsAction; }
                        MenuItem { action: winClientAction; }
                        MenuItem { action: winCashWizardAction; }
                        MenuItem { action: winStatAction; }
                        MenuItem { action: winRateAction; }
                        MenuItem { action: winTaxServiceAction; }
                        MenuSeparator { padding: 5; }
                        MenuItem { action: actionBalancingTrade; }
                        MenuSeparator {  padding: 5; }
                        MenuItem { action: actionSetting; }
                        MenuItem { action: changeDBAction; }
                        MenuItem { action: testAction; }
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
                    text: vkStack.currentItem.title
                }
                Row {
                    id: btnClient
                    visible: vkStack.currentItem.crntClient !== undefined
                    ToolButton{
                        text: vkStack.currentItem.crntClient !== undefined ? vkStack.currentItem.crntClient.name : ''
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
                        visible: vkStack.currentItem.crntClient !== undefined && vkStack.currentItem.crntClient.id !== ''
                        font.pointSize: 16
                        text:"⌫"
//                        flat: true
//                        icon.source:"qrc:/icon/undo.svg"
                        onClicked: {
                            vkStack.currentItem.crntClient = Lib.getClient(Db);
                        }
                    }
                    Label{
                        visible: vkStack.currentItem.crntClient !== undefined && Math.abs(Number(vkStack.currentItem.crntClient.bonusTotal)) >= 0.01
    //                        Layout.preferredWidth: visible?35:0
                        Layout.preferredHeight: 35
                        color:'slategray'
    //                        background: Rectangle{color:'gold'}
    //                        flat: true
                        text: vkStack.currentItem.crntClient !== undefined ? Number(vkStack.currentItem.crntClient.bonusTotal).toFixed(0) : ''
                        MouseArea{
                            anchors.fill: parent
                            onDoubleClicked: {
                                let ano = vkStack.currentItem.crntAcnt.acntno
                                vkStack.currentItem.crntAcnt = Lib.getAccount(Db, vkStack.currentItem.crntClient.bonusAcnt);
                                vkStack.currentItem.insert( new3Dcm('', {"amnt":(0 - Number(vkStack.currentItem.crntClient.bonusTotal)).toFixed(2)}) )
                                vkStack.currentItem.crntAcnt = Lib.getAccount(Db, ano)
                            }

                        }

                    }
                }

                ToolButton {    // ⋮
                    id:contentMenu_toolbtn
                    text: qsTr("⋮")
                    onClicked: {
                        // bindContentMenu.open()
                        // contentMenu.open()
                        // vkStack.currentItem.vkMenu.y = parent.height
                        if (vkStack.currentItem.vkContentMenu !== undefined){
                            vkStack.currentItem.vkContentMenu.popup()
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
        actionBind.trigger()
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
            msgDialog.message = "No DB"
            msgDialog.open()
        }

    }

}
