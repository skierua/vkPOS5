import QtCore
import QtQuick
//import QtQuick.Controls
import QtQuick.Controls.Fusion
//import QtQuick.Controls.Material
//import QtQuick.Controls.Universal
import QtQuick.Layouts

import "../../lib.js" as Lib
// import "../../libSettings.js" as Stng

import com.vkeeper 3.0

ApplicationWindow {
    id: root
    visible: true
    // width: 0    /*640*/; // onWidthChanged: geometryTimer.start()   //if (!geometryTimer.running) {geometryTimer.start()}
    // height: 0   /*480*/; // onHeightChanged: geometryTimer.start()  //if (!geometryTimer.running) {geometryTimer.start()}
    title: String("vkPOS5#%1").arg("2.6")

    // property string pathToDb: "/data/"
    property string dbname: ''
    // property string incasAcntno:""  // "3501"
    property real z0: 0.0000001
    property var cashier: {"id":"", "name":""}
    property var acnts: { "cash":"3000", "incas":"3003ELSV", "trade":"3500", "bulk":"3501", "profit":"3607-55" }
    property var crntClient: {'id':'', 'name':'', "bonusTotal": 0, "bonusAcnt":''};
    // property var program: { "cash":"3000", "incas":"3003ELSV", "trade":"3500", "bulk":"3501", "profit":"3607-55",


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
    property string cdprefix: ""
    property string cdcash: ""
    property string cdtoken: ""

    // property var rest: Stng.rest


    property int loadStatus:0
        onLoadStatusChanged: {
            /*
            if (loadStatus === 5){
// msg("#74yn rslt.3500/978 acnt="+String("rslt.3500/978").substring(5,9)+" cur="+String("rslt.3500/978").substring(String("rslt.3500/978").indexOf("/")+1))
                let bstate = "check"
                let cashAcnt = getAccount(acnts.cash);
                let dfltAcnt = getAccount();
                let dfltClnt = getClient();
                for (let i =0; i < stackBind.children.length; ++i ){
                    if (stackBind.children[i].state === "facture"){
                        stackBind.children[i].printDcm = ""
                        stackBind.children[i].autoPrint = "0"
                        stackBind.children[i].dfltAmnt = "1"
                        stackBind.children[i].dfltClient = dfltClnt;
                        stackBind.children[i].cashAcnt = cashAcnt;
                        stackBind.children[i].dfltAcnt = dfltAcnt;
                    } else {
                        stackBind.children[i].printDcm = checkPrintDcm
                        stackBind.children[i].autoPrint = checkAutoPrint
                        stackBind.children[i].dfltAmnt = checkAmnt
                        stackBind.children[i].dfltClient = dfltClnt;
                        stackBind.children[i].cashAcnt = cashAcnt;
                        stackBind.children[i].dfltAcnt = dfltAcnt;
                    }
//        msg("#e7h i="+i+" crntAcnt="+stackBind.children[i].cashAcnt)
                    stackBind.children[i].startBind()
                }
                let vbinds = String(dbDriver.settingsValue("program/binds","check"))
                pageTaxAction.enabled = ~vbinds.indexOf("tax")
                winTaxServiceAction.enabled = ~vbinds.indexOf("tax")
                pageFactureAction.enabled = ~vbinds.indexOf("facture")
                pageIncasAction.enabled = ~vbinds.indexOf("incas")
//                var jdata = JSON.parse(vdata);
//                bind.cashAcnt = getAccount("3000"); //jdata.rows[0];
//                bind.domesticCrn = getArticle();
//                bind.crntAcnt = getAccount()     //jdata.rows[0];
                // msg("#846 stack index="+stackBind.currentIndex)
                stackBind.children[stackBind.currentIndex].startBind()

                // set shift properties
                shift.cash = acnts.cash
                shift.trade = acnts.trade
                shift.bulk = (acnts.bulk !== undefined ? acnts.bulk : "")


                root.visible = true
                var crsh = crntShift()
                root.cashier = {"id":crsh.cshr, "name":crsh.cshrname }
                if(crsh.id === 0 || crsh.shftend !== "" || crsh.shftdate !== Qt.formatDateTime(new Date(), "yyyy-MM-dd")) { modeShiftAction.trigger(); } else { modeBindAction.trigger(); }
                // msg("#6eg stack base64 4444="+Qt.btoa("4444")+ " decode="+Qt.atob("MTExMQ==")+ " md5="+Qt.md5("asdf3456"))
                // dbDriver.dbUpdate("update cashier set psw='MTExMQ==' where code = 'vasn';")
                // dbDriver.dbUpdate("update cashier set psw='NDQ0NA==' where code = 'kuzb';")
                // msg("#48df ascii=dj39 v64="+Qt.btoa("dj39"))
                // msg("#48df ascii=lw05 v64="+Qt.btoa("lw05"))
                // msg("#48df ascii=s28f v64="+Qt.btoa("s28f"))
                // msg("#48df ascii=y6k9 v64="+Qt.btoa("y6k9"))

            } */
        }

    Settings {
        category: "terminal"
        property alias code: root.term
        property alias pos_printer: root.posPrinter
        // property alias http_user: root.bindList
        // property alias http_password: root.restpassword
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

    Component.onDestruction: {}

    function msg(vstring, vtype, vmodule) {
        if (vtype === undefined) { vtype = 'II'}
        if (vmodule === undefined) { vmodule = 'main.qml'}
        msgDialog.code = vtype
        msgDialog.message = vstring
        msgDialog.open()

        Lib.log(vstring, vmodule, vtype)
    }

    function isOnline() { return root.resttoken != "" }

    function isTaxMode() { return root.cdhost != "" }

    function isShiftOpen() {
        let sh = crntShift();
        if (Number(sh.id)!==0 && sh.shftend==='') { return true; }
        return false;
    }

    function isIncas() {
        if (acnts.bulk === undefined || acnts.bulk === "") { return false; }
        let vsql = "select sum(abs(beginamnt+turndbt-turncdt)) as total from acnt where acntno='3500';";
        let vj = JSON.parse(dbDriver.getJSONRowsFromSQL_2(vsql));
        if (vj.rows.length){
            // Lib.log("#e8u isIncas="+(vj.rows[0].total>0))
            return (Number(vj.rows[0].total) > 0);
        }
        return false;
    }

    function taxRequest(path, req, callback) {
        let request = new XMLHttpRequest();

        request.onreadystatechange = function() {
            if (request.readyState === XMLHttpRequest.DONE) {
                let response = {
                    status : request.status,
                    headers : request.getAllResponseHeaders(),
                    contentType : request.responseType,
                    content : request.response
                };

                callback(response);
            }
        }
        request.open("POST", cdhost + cdprefix + path);
        request.setRequestHeader("Content-Type","application/json");
        request.setRequestHeader("Accept","application/json");
        request.setRequestHeader("developer-id","linux,mppanna");
        // request.setRequestHeader("Bearer",token);
        request.send(JSON.stringify(req));
        // request.send("data=" + JSON.stringify(req));
    }

    QtObject {
        id: bindObj
        property variant jbind
        property string printDcm
        property bool autoPrint
        property bool autoTax
    }

    Action {
        id: actionLogin
        text: "Login"
        onTriggered:
            if ( resthost != "") {
                Lib.loginRequest(resthost+restapi+"/auth", restuser, restpassword, (response) => {
                resttoken = ""
                // Lib.log(response.status);
                // Lib.log(response.headers);
                // Lib.log( response.content);
                // Lib.log("contentType="+response.contentType)
                if (response.status === 200) {
                    let isPlainText = response.contentType.length === 0
                    if (isPlainText) {
                        resttoken = JSON.parse(response.content).token
                    }
                } else if (response.status === 0){
                    // errorStr.text = "Site connection error"
                    msg('Site connection error', 'EE')
                } else {
                    // TODO off online mode
                    // Lib.log( response.content )
                    // errorStr.text = JSON.parse(response.content).errstr
                    Lib.log(resthost+restapi+"/auth" + "\nU:"+restuser+" P:"+restpassword+"\n"+response.content,'Main', 'EE')
                }

                });
            }

    }

    Action {
        id: testAction
        text: "TEST"
//        icon.name: "edit-copy"
//        shortcut: StandardKey.Copy
        onTriggered: {
            isIncas()
        }
    }

    function crntShift(){
        let shft = dbDriver.getJSONRowFromSQL("select id, shftdate, coalesce(shftbegin,'') shftbegin, coalesce(shftend,'') shftend, cshr, coalesce(cashier.note,'') as cshrname from shift left join cashier on(cshr=code) order by id desc limit 1;")
        // Lib.log("#w34 shft id="+ JSON.stringify(shft) )
        if (shft.errid === 0) { return shft; }
        return { "id":0,"cshr":"","cshrname":"","errid":1,"errname":"","shftbegin":"","shftdate":"","shftend":""}
    }


    function openConnection(vname, vdriver){
        closeChildWindow()
        if (dbname === vname) { return } //same connection
        if (vdriver === undefined) { vdriver = 'QSQLITE'}
        dbDriver.clearSqlData()
        // Lib.log("#625a db="+vname)
        dbDriver.setDbParameter(vname,vdriver)
        dbname = vname
        // var i = 0
        // var ilen = 0
        loadStatus++

        var crsh = crntShift()
        root.cashier = {"id":crsh.cshr, "name":crsh.cshrname }
        // Lib.log("#848 date="+Qt.formatDateTime(new Date(), "yyyy-MM-dd")+" shift="+JSON.stringify(crsh))
        if (crsh.shftdate !== Qt.formatDateTime(new Date(), "yyyy-MM-dd")){
            if (isShiftOpen()){     // close shift
                // { "id":0,"cshr":"","cshrname":"","errid":0,"errname":"","shftbegin":"","shftdate":"","shftend":""}
                if (isIncas()) {
                    modeShiftAction.trigger()
                } else {
                    askDialog.code = 'askCloseShift'
                    askDialog.jdata =  { "text" : "Закрити попередню зміну ?","shid":crsh.id,"shdate":crsh.shftdate, "cshr":crsh.cshr }
                    askDialog.open()
                }

            } else {        // new shift
                modeShiftAction.trigger()
            }

        } else {
            modeBindAction.trigger();
        }
        // set root acnts
        var va = dbDriver.getJSONRowFromSQL("select acnts from settings limit 1;")
        // Lib.log('#92uj acnts='+JSON.stringify(va))
        if (!va.errid){
            // Lib.log('#671g acnts='+va.acnts)
            const aa = Lib.parse(va.acnts)
            // aa = ((raw) => {
            //     try {
            //         return JSON.parse(raw);
            //     } catch (err) {
            //         return false;
            //     }
            // })(va.acnts);
            if(aa) { root.acnts = aa;/* Lib.log('#671g acnts='+JSON.stringify(root.acnts));*/}
                else {Lib.log('#25tx acnts JSON.parse error');}
            // Lib.log('#671g acnts='+JSON.stringify(root.acnts))
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

    function findBind(vcode){
        let i =-1
        vcode = vcode || ""
        for (i =0; i < stackBind.children.length && stackBind.children[i].state !== vcode; ++i ){}
        return i
    }

    function balancingTrade(){
        let r =0;
        let total = 0;
        var vj;
        // var jsrow;
        // for testing only START !!!
        // jsrow = [{"acntno":"rslt.3500/840","amnt":"55.11"},{"acntno":"rslt.3500/978","amnt":"-66.2"}]
        // for testing only FINISH !!!

        // jsrow = JSON.parse(dbDriver.getJSONRowsFromSQL_2("select acntno, beginamnt+turndbt-turncdt as amnt from acnt where substr(acntno,1,4)='rslt' and amnt!=0;")).rows
        const jsrow = Lib.parse(dbDriver.getJSONRowsFromSQL_2("select acntno, beginamnt+turndbt-turncdt as amnt from acnt where substr(acntno,1,4)='rslt' and amnt!=0;")).rows
        if (!jsrow){ Lib.log('balancingTrade #32gt JSON.parse error'); return; }
        if (!jsrow.length) { Lib.log('balancingTrade #1e2 Nothing to do'); return; }

        vj = {"id":"dcmbind","dcm":"folder","dbt":"profit","cdt":"blnc","amnt":"0","eq":"0","dsc":"0","bns":"0","note":"rslt>profit", "clnt":"", "dcms":[]}
        total = 0
        for (r =0; r < jsrow.length; ++r) {
            total += Number(jsrow[r].amnt)
            vj.dcms.push({"dcm":"memo","dbt":acnts.cash,"cdt":jsrow[r].acntno,"crn":"","amnt":jsrow[r].amnt,"eq":"0","dsc":"0","bns":"0","note":"","retfor":""})
            vj.dcms.push({"dcm":"memo","dbt":acnts.cash,"cdt":acnts.profit,"crn":"",
                "amnt":(String(-1*Number(jsrow[r].amnt))),"eq":"0","dsc":"0","bns":"0","note":"","retfor":""})
        }
        vj.amnt = total.toFixed(2)
        vj.eq = (0-total).toFixed(2)
        bindObj.jbind = vj
        bindObj.printDcm = ""
        bindObj.autoPrint = false
        bindObj.autoTax = false
        tranAction.trigger(bindObj)

               // msg('#74g balancingTrade bind='+JSON.stringify(vj));
    }

    function reval( cshr ){
        let ok = true;
        let r=0, prf = 0;
        let vsql = ""
        vsql = String("select item as curid, case when qtty=1 then price else price/qtty end as rate from  price where price!=0 and prbidask=1 and (prtype='' or prtype is null);")
        var vdata = JSON.parse(dbDriver.getJSONRowsFromSQL_2(vsql));
        if (vdata.errid) { // error
            msg(vdata.errname,"EE #6g2");
            return;
        }
        let vrows = vdata.rows
        for (r =0; r < vrows.length; ++r) {
            vsql = String("update acntrade set lastpricebuy = %1 where article='%2';").arg(vrows[r].rate).arg(vrows[r].curid)
            ok &= dbDriver.dbUpdate(vsql)
        }
        vsql = String("update acntrade set lastpricebuy = 0 where lastpricebuy IS NULL;")
        ok &= dbDriver.dbUpdate(vsql)
        vsql = String("update acntrade set lastpricesell = 0 where lastpricesell IS NULL;")
        ok &= dbDriver.dbUpdate(vsql)
        vsql = String("update acntrade set bscprice = (case when lastpricebuy = 0 then lastpricesell else lastpricebuy end) "
                    + "where (lastpricebuy != 0 or lastpricesell != 0 ) "
                    + "and bscprice != (case when lastpricebuy = 0 then lastpricesell else lastpricebuy end);")
        ok &= dbDriver.dbUpdate(vsql)
        vsql = String("select acnt.id tid,acnt.acntno tno, acnt.item, eq.id eid, eq.acntno eno,'rslt.'||acntrade.acntno||'/'||acntrade.article as rno, bscprice, 0-(acnt.beginamnt+acnt.turndbt-acnt.turncdt) amnt, "
                      + "round(0-(acnt.beginamnt+acnt.turndbt-acnt.turncdt) * bscprice - (eq.beginamnt+eq.turndbt-eq.turncdt),2) as profit "
                      + " from  acntrade join acnt on (acntrade.pkey = acnt.id) join acnt as eq on (('eqvl.'||acntrade.acntno||'/'||acntrade.article) = eq.acntno) where substr(acnt.acntno,1,2)='35' and abs(profit)>1 "
                      + "order by acnt.acntno;")  // and profit!=0
        vdata = JSON.parse(dbDriver.getJSONRowsFromSQL_2(vsql));
        if (vdata.errid) { // error
            msg(vdata.errname,"EE #8ey");
            return;
        }
        // console.log("#9e7h main "+JSON.stringify(vdata))
        var tarr = []
        var vj = ({})
        var vjdcms = []
        let m = vdata.rows
        let vtno = ""
        for (r =0; r < m.length; ++r) {
            if (vtno !== m[r].tno) {
                vtno = m[r].tno
                prf = 0
                vj = {"id":"dcmbind","dcm":"folder","dbt":m[r].tno,"cdt":"rslt","amnt":"0","eq":"0","dsc":"0","bns":"0","note":"reval", "clnt":cshr, "dcms":[]}
            }
            prf += Number(m[r].profit)
            vj.dcms.push({"dcm":"memo","dbt":m[r].eno,"cdt":m[r].rno,"crn":"","amnt":m[r].profit,
                "eq":"0","dsc":"0","bns":"0","note":String("reval %1*%2/%3").arg(m[r].amnt).arg(m[r].bscprice).arg(m[r].item),"retfor":""})
            if ( r+1 === m.length || vtno !== m[r+1].tno) {
                vj.amnt = prf.toFixed(0)
                tarr.push(vj)
                vtno = ""
            }
        }
        for(r=0; r< tarr.length; ++r) {
            // console.log("#63t main "+JSON.stringify(tarr[r]))
            bindObj.jbind = tarr[r]
            bindObj.printDcm = ""
            bindObj.autoPrint = false
            bindObj.autoTax = false
            tranAction.trigger(bindObj)
        }

    }


    function getClient(vid){
        let ret = {'id':'', 'name':'', "bonusTotal": 0, "bonusAcnt":''};
        if (vid !== undefined && vid !== "" && vid !== 0){
            let vsql = "select pkey as id, clchar as name, coalesce('tel.'||phone,'') || coalesce(' '||clnote,'')  as fullname, coalesce(a.acntno,'') as bonusAcnt, coalesce(a.total,0) as bonusTotal ";
            vsql += "from client left join (select acntno, client as pkey, (0-(beginamnt+turndbt-turncdt)) as total from acntbal join acnt using(acntno) where item is null and substr(acntno,1,4)='3800') as a using (pkey) ";
            vsql += "where id = '" + vid + "'";
            const vj = Lib.parse(dbDriver.getJSONRowsFromSQL_2(vsql));
            if (!vj){Lib.log('getClient #25fa JSON.parse error'); return; }
            if (vj.rows.length){
                ret = vj.rows[0];
            }
        }
//        msg("#dj3 cl="+JSON.stringify(ret))
        return ret;
    }

    function getAccount(vno) {
        let vsql = "select acntno, coalesce(pkey,'') as clid, coalesce(clchar, '') as clname, coalesce(acntnote,balname,'') as note, mask, clnote, acntbal.trade as trade, balname as name
    from acntbal left join client on (pkey=client) left join balname on (substr(acntno,1,2)=bal) ";
        let ret = { "acntno":"", "clid":"", "clname":"", "note":"", "mask":"", "clnote":"", "trade":"", "name":"" };
        var jdata = ({})
        if (vno === undefined || vno === ''){
            jdata = Lib.parse(dbDriver.getJSONRowsFromSQL_2(vsql+" where acntbal.trade=1 and mask!=0 order by acntno"));
        } else {
            jdata = Lib.parse(dbDriver.getJSONRowsFromSQL_2(vsql+" where acntno='"+vno+"' order by acntno"));
        }
//        msg("#048j getAccount(vno)="+JSON.stringify(jdata.rows[0]))
        if (jdata){
            if (jdata.rows.length){ ret = jdata.rows[0]; }
        }
        return ret;
    }

    function getArticle(vaid) {
        var jdata = ({})
        let vsql = "select item.pkey as id, itemchar as name, coalesce(itemname, itemnote,'') as fullname, itemmask as mask, coalesce(qty,1) as qty, uktzed, taxchar, taxprc, "
        +" coalesce(defunit,'') as unitid ,coalesce(unitprec,2) as prec, coalesce(unitchar,'') as unitchar, coalesce(unitname,'') as unitname, coalesce(code,'') as unitcode, "
        +" coalesce(term,0) as term from item left join itemunit on(defunit=itemunit.pkey) left join articlepriceqty on (item.pkey=articlepriceqty.pkey) left join warranty on (item.pkey=article) ";
        let ret = {"id":"", "name":"", "fullname":"", "mask":"", "qty":"1", "uktzed":"", "taxchar":"","taxprc":"",
        "unitid":"", "prec":"0", "unitchar":"", "unitname":"", "unitcode":"", "term":"" };
        let filt = " where mask='1'"
        if (vaid !== undefined && vaid !== ''){
            filt = " where id='"+vaid+"'"
        }
        // console.log("#ueh9 sql="+vsql+filt)
        jdata = Lib.parse(dbDriver.getJSONRowsFromSQL_2(vsql+filt));
        if (jdata){
            if (jdata.rows.length){
                ret = jdata.rows[0];
                if (vaid === undefined || vaid === ''){
                    ret.id = ''
                }
            }
        }
        // console.log("#16q article="+JSON.stringify(ret))
        return ret;
    }

    function setClient(vid){
        crntClient = getClient(vid);
        stackBind.children[stackBind.currentIndex].crntClient = crntClient;
        stackBind.children[stackBind.currentIndex].crntAcnt = getAccount();
    }

    function setAccount(vno) {
        let vacnt = getAccount(vno);
        // Lib.log("#8jr vacnt="+JSON.stringify(vacnt))
        stackBind.children[stackBind.currentIndex].crntAcnt = vacnt;
        uahToAcntAction.enabled = (Number(vacnt.mask)&1)==1
        curToAcntAction.enabled = (Number(vacnt.mask)&3)==3
    }

/**
  param { acntno, code, amnt, price, dsc, bns, pratt, retfor}
 */
    function new2Dcm(vaid, param) {
//        console.log("#48h vaid="+vaid+ " amnt="+vamnt)
        var n2d = {"price":0, "dsc":0, "bns":0, "tag":"", "retfor":""}
        n2d.atcl = getArticle(vaid)
//        let vatcl = getArticle(vaid)
        let vacnt = stackBind.children[stackBind.currentIndex].crntAcnt
        if (param === undefined){
//            param = ({})
            n2d.acnt = stackBind.children[stackBind.currentIndex].crntAcnt
            n2d.amnt = stackBind.children[stackBind.currentIndex].crntAmnt
            n2d.code = Number(n2d.amnt) < 0 ? "pay:out" : "pay:in"
        } else {
            n2d.acnt = (param.acntno !== undefined) ? getAccount(param.acntno) : stackBind.children[stackBind.currentIndex].crntAcnt;
            n2d.amnt = param.amnt || stackBind.children[stackBind.currentIndex].crntAmnt
            n2d.code = param.code || (Number(n2d.amnt) < 0 ? "pay:out" : "pay:in")
            n2d.retfor = param.retfor || ""
//            if (param.acntno !== undefined){ vacnt = getAccount(param.acntno); }
        }

        if ( !(Number(n2d.atcl.mask) & Number(n2d.acnt.mask)) ){
            msgDialog.code = 'Warning'
            msgDialog.message = 'Main\n'+"#37h currency/article and account missmatch ["+n2d.atcl.mask+"] & ["+n2d.acnt.mask +"]"
            msgDialog.open()
            stackBind.children[stackBind.currentIndex].startNewRow();
            return;
        }
//        if (param === undefined) { param = {"price":"0", "offer":"0", "dsc":"0" }; }
//        if (vamnt !== undefined && vamnt !==''){ stackBind.children[stackBind.currentIndex].crntAmnt = vamnt; }
        let jpr = {"price":"0", "offer":"0", "dsc":"0" };
        if (Number(n2d.acnt.trade) === 1) {
            if (param !== undefined){
                n2d.price = param.price || 0;
                n2d.dsc = param.dsc || 0;
                n2d.bns = param.bns || 0;
                n2d.pratt = param.price > z0 ? 0 : 7
                if (Number(n2d.atcl.mask) === 4 || stackBind.children[stackBind.currentIndex].state === "incas") {
                    n2d.code = param.code || stackBind.children[stackBind.currentIndex].crntCode
                } else {
                    n2d.code = param.code || (Number(n2d.amnt) < 0 ? "trade:sell" : "trade:buy");
                }
            } else {
                n2d.pratt = 7
                if (Number(n2d.atcl.mask) === 4 || stackBind.children[stackBind.currentIndex].state === "incas") {
                    n2d.code = stackBind.children[stackBind.currentIndex].crntCode
                } else {
                    n2d.code = (Number(n2d.amnt) < 0 ? "trade:sell" : "trade:buy")
                }
            }


            if (n2d.price < z0) {   // price undefined
                let vj = ({})
                let prid = ""
                if (stackBind.children[stackBind.currentIndex].state !== "facture"){
                    vj = JSON.parse(dbDriver.getJSONRowsFromSQL_2(
                                String("select item as pkey, price.price/price.qtty as price, coalesce(selloffer.price,0)/coalesce(selloffer.qtty,1) as offer, coalesce(selldsc.price,0) as dsc
                                        from price left join selloffer on(item=selloffer.article) left join selldsc on(item=selldsc.article)
                                        where item = '%1' and prbidask=%2;").arg(vaid).arg(n2d.code === 'trade:sell'? '-1':'1')))
                    if (vj.rows.length) {
                        prid = vj.rows[0].pkey
                    }
//                    console.log("#4h7 n2d data="+JSON.stringify(vj))
                }

                if (prid === ""){
                    vj = JSON.parse(dbDriver.getJSONRowsFromSQL_2(
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
        stackBind.children[stackBind.currentIndex].insert(n2d,0)
        if (param !== undefined && param.retfor !== undefined && param.retfor !== ""){
            stackBind.children[stackBind.currentIndex].startNewRow()
        }
    }

    function findText(vtext) {
        if (vtext === undefined || vtext ===""){
            new2Dcm("");
            return;
        }

        let sql = ""
        var vartjs = ({})
        if(isNaN(vtext)) {
            sql = "select pkey as id, clchar as name, coalesce('tel.'||phone,'') || coalesce(' '||clnote,'')  as fullname, '' as scancode, 0 as mask, 'Клієнти' as sect from client ";
            sql += "union select item.pkey as id, itemchar as name, coalesce(itemname, itemnote,'') as fullname, coalesce(scancode,'') as scancode, itemmask as mask, '' as sect from item ";
            sql += "where folder = 0 and itemmask&"+stackBind.children[stackBind.currentIndex].crntAcnt.mask;
            vartjs = JSON.parse(dbDriver.getJSONRowsFromSQL_2(sql,String(vtext)));
                if (vartjs.rows.length === 0) {
                   msgDialog.code = 'Info'
                   msgDialog.message = 'Main/bind\nНічого не знайдено'
                   msgDialog.open()
                   stackBind.children[stackBind.currentIndex].startNewRow()
                   return
                }
                if (vartjs.rows.length === 1){
                   // create docum
                   if (Number(vartjs.rows[0].mask)===0){
                       setClient(vartjs.rows[0].id)
                   } else {
                       new2Dcm(vartjs.rows[0].id)

                   }
                } else {
                   // choice article from list
                   selectPopup.jsdata = vartjs.rows
                   selectPopup.open()
                }

        } else {
            let ok = true;
            if (vtext.length < 4) {
                sql = "select item.pkey as id, itemchar as name, coalesce(itemname, itemnote,'') as fullname, itemmask as mask, '' as sect from item "

                sql += "where folder = 0 and (itemmask=2) and substr(cast(item.pkey as string),1,"+vtext.length+")='"+vtext+"'";
//                vartstr = dbDriver.getJSONRowsFromSQL_2(sql)
                vartjs = JSON.parse(dbDriver.getJSONRowsFromSQL_2(sql));
                ok &= ok && vartjs.rowCount === 0;
            }
            if (ok) {
                sql = "select pkey as id, clchar as name, coalesce('tel.'||phone,'') || coalesce(' '||clnote,'')  as fullname, 0 as mask, 'Клієнти' as sect from client ";
                sql += "where id='"+vtext+"';"
//                vartstr = dbDriver.getJSONRowsFromSQL_2(sql)
                vartjs = JSON.parse(dbDriver.getJSONRowsFromSQL_2(sql));
                ok &= ok && vartjs.rowCount === 0;
            }
            if (ok) {
                sql = "select item.pkey as id, itemchar as name, coalesce(itemname, itemnote,'') as fullname, itemmask as mask, '' as sect from item ";
                sql += "where item.pkey='"+vtext+"' and (itemmask&6) and folder = 0;";
//                vartstr = dbDriver.getJSONRowsFromSQL_2(sql)
                vartjs = JSON.parse(dbDriver.getJSONRowsFromSQL_2(sql));
                ok &= ok && vartjs.rowCount === 0;
            }

//                        msg('1='+vv)
            if (ok) {
                sql = "select item.pkey as id, itemchar as name, coalesce(itemname, itemnote,'') as fullname, itemmask as mask, '' as sect from item ";
                sql += "where folder = 0 and (substr(cast(item.pkey as string),1,"+vtext.length+")='"+vtext+"' or (itemmask&"+stackBind.children[stackBind.currentIndex].crntAcnt.mask+") and scancode like '%"+vtext+"%') order by pkey;";
//                                msg("#03k findArticle sql="+sql )
//                vartstr = dbDriver.getJSONRowsFromSQL_2(sql)
                vartjs = JSON.parse(dbDriver.getJSONRowsFromSQL_2(sql));
                ok &= ok && vartjs.rowCount === 0;
//                                       msg("#05j ok="+sql)
            }
//                    msg('2='+vv)

            if (vartjs.rowCount === 0) {
                msgDialog.code = 'Info'
                msgDialog.message = 'Main/bind\nНічого не знайдено'
                msgDialog.open()
                stackBind.children[stackBind.currentIndex].startNewRow()
                return
            }

            if (vartjs.rowCount === 1){
                // create docum
                if (Number(vartjs.rows[0].mask)===0){
                    setClient(vartjs.rows[0].id)
                } else {
                    new2Dcm(vartjs.rows[0].id)
                }
            } else {
                // choice article from list
                selectPopup.jsdata = vartjs.rows
                selectPopup.open()
            }

//                        msg(vv)
        }

    }

    function selectAcnt(){
        let sql = ""
        if (stackBind.children[stackBind.currentIndex].state !== "incas") {
            let flt = (stackBind.children[stackBind.currentIndex].crntClient.id === undefined || stackBind.children[stackBind.currentIndex].crntClient.id === '') ?
                         "where cl = '' and acntbal.trade = 0 and mask!=0 and acntno != 'rslt' and acntno != '"+stackBind.children[stackBind.currentIndex].cashAcnt.acntno+"' and substr(acntno,1,4)!='3800'"
                         : "where cl = '"+stackBind.children[stackBind.currentIndex].crntClient.id+"' and acntbal.trade = 0 and mask!=0 and acntno != 'rslt' and acntno != '"+stackBind.children[stackBind.currentIndex].cashAcnt.acntno+"'";
            sql = "select acntno as id, coalesce(acntnote,balname,'') as name, coalesce(clchar, '') as fullname, '' as scancode, '128' as mask, 'Рахунки' as sect, acntbal.trade, coalesce(pkey,'') as cl "
            sql += " from acntbal left join client on (pkey=client) left join balname on (substr(acntno,1,2)=bal) where acntbal.trade and acntbal.mask!=0 "
            sql += "union select acntno as id, coalesce(acntnote,balname,'') as name, coalesce(clchar, '') as fullname, '' as scancode, '128' as mask, 'Рахунки' as sect, acntbal.trade, coalesce(pkey,'') as cl  "
            sql += "from acntbal left join client on (pkey=client) left join balname on (substr(acntno,1,2)=bal) " + flt + " order by acntbal.trade desc, acntno";
        } else {
            sql = "select acntno as id, coalesce(acntnote,balname,'') as name, coalesce(clchar, '') as fullname, '' as scancode, '128' as mask, 'Рахунки' as sect, acntbal.trade, coalesce(pkey,'') as cl "
            sql += " from acntbal left join client on (pkey=client) left join balname on (substr(acntno,1,2)=bal) where (acntbal.trade or substr(acntno,1,4)='3003') and acntbal.mask!=0 order by acntbal.trade desc, acntno"
        }
        selectPopup.jsdata = JSON.parse(dbDriver.getJSONRowsFromSQL_2(sql)).rows;
        // Lib.log("#34rs HERE")
        selectPopup.open()
        // Lib.log("#47reh HERE")
    }

    function cdTaxCheck(vid) {
//        msg("#6s9 cdTaxCheck vid="+vid); return;
//        if (vid === undefined ) { return; }


        let ok = true;
        let strg = false;
        let vsql = "";
        let vstr = dbDriver.getJSONRowsFromSQL_2("select coalesce(dcmno,'') as dcmno, amount from docum where id="+vid)
        let vj= JSON.parse(vstr);
        if (vj.rowCount === 0) {
            strg = true
            vstr = dbDriver.getJSONRowsFromSQL_2("select coalesce(dcmno,'') as dcmno, amount from strgdocum where dcmid="+vid)
            vj= JSON.parse(vstr);
        }
        ok &= (ok && !(vj.errId || vj.rowCount === 0 || vj.rows[0].dcmno !== ""))
        if (strg){
            vsql = "select dcmtype, strgdocum.item as atclid, itemchar as atclname, amount, eqamount,discount, uktzed, taxchar, taxprc, coalesce(defunit,'') as unitid ,coalesce(unitprec,2) as prec, ";
            vsql += "coalesce(unitchar,'') as unitchar, coalesce(unitname,'') as unitname, coalesce(code,'') as unitcode, itemmask as mask ";
            vsql += "from strgdocum left join item on(strgdocum.item=item.pkey) left join itemunit on(defunit=itemunit.pkey) where strgdocum.parentid="
        } else {
            vsql = "select dcmtype, docum.item as atclid, itemchar as atclname, amount, eqamount,discount, uktzed, taxchar, taxprc, coalesce(defunit,'') as unitid ,coalesce(unitprec,2) as prec, ";
            vsql += "coalesce(unitchar,'') as unitchar, coalesce(unitname,'') as unitname, coalesce(code,'') as unitcode, itemmask as mask ";
            vsql += "from docum left join item on(docum.item=item.pkey) left join itemunit on(defunit=itemunit.pkey) where docum.parentid="
        }
//         msg("#o93 sql="+vsql+vid)
//        msg("#o93 sql="+vsql+vid)m.substring(0,m.indexOf('#'))
        vstr = dbDriver.getJSONRowsFromSQL_2(vsql+vid)
        let vja= JSON.parse(vstr);
        ok &= ok && !(vja.errId || vja.rowCount === 0)
        let vatcl = ""
        for (let r=0; r < vja.rows.length; ++r){
            ok &= ok && (vja.rows[r].dcmtype === "trade:sell" && Number(vja.rows[r].mask) === 4 && Number(vja.rows[r].amount) < 0)
            vatcl += (vatcl!=""?", ":"") + '{"unit_code": "'+vja.rows[r].unitcode+'","unit_name": "'+vja.rows[r].unitchar+'","name": "'+ vja.rows[r].atclname +'",';
            vatcl += '"amount": "'+Math.abs(vja.rows[r].amount)+'","price": "'+ Math.abs(Number(vja.rows[r].eqamount)/Number(vja.rows[r].amount)).toFixed(3) +'","cost": "'+Math.abs(vja.rows[r].eqamount)+'"';
            vatcl += (Number(vja.rows[r].discount)===0 ? '':(', "sum_discount":"'+(0-Number(vja.rows[r].discount).toFixed(2))+'"'))+'}';
        }

//        msg("#64s ok="+ok)
        let lnmb = 0;
        if (ok){
            lnmb = dbDriver.dbInsert("insert into taxdcm (dcmid) values ('"+vid+"')");
            ok &= (lnmb !== 0)
        }

//        msg("#s1s ok="+ok+' rid='+lnmb)
        let tsum = Math.round(10*Math.abs(vj.rows[0].amount))/10;
        let rsum = tsum - Math.abs(vj.rows[0].amount)
        let bind = '{"api_token":"'+ cdtoken + '","num_fiscal":'+ cdcash + ',"action_type": "Z_SALE","local_number":'+lnmb+',';
        bind += '"total_sum":'+tsum.toFixed(2)+',"round_sum":'+ rsum.toFixed(2)+',';
        bind += '"products":['+vatcl+'],';
        bind += '"payments": [{"code": 0,"name": "ГОТIВКА","sum": ' + tsum.toFixed(2) + ',"sum_provided": ' + tsum.toFixed(2) + ',"sum_remains": 0}],';
        bind += '"no_text_print":true,"no_pdf":true,"no_qr":true,"open_shift":true,"print_width": 32,"pdf_width": 48}';
        if (ok){
            ok &= dbDriver.dbUpdate("update taxdcm set request = '" + bind + "' where pkey="+lnmb)
        }

//        console.log("#392j main ok="+ok+" bind="+bind); return;
        if (ok){
            taxRequest(String("/check/sale?api_token=%1").arg(cdtoken), bind, (response) => {
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
            });
        } else {
            // TODO error
            msg("Документ не фіскалізовано", 'EE')
        }
        return ok
//        msg("#04k ok="+ok+" taxBind="+bind)
    }


    DbDriver{
        id: dbDriver

        onDriverStatusChanged: status => {
            // Lib.log("#39j dbStatus="+status + " is1="+(status === 1))
            if (status === 1){
                let cashAcnt = getAccount(acnts.cash);
                let dfltAcnt = getAccount();
                let dfltClnt = getClient();
                for (let i =0; i < stackBind.children.length; ++i ){
                    if (stackBind.children[i].state === "facture"){
                       stackBind.children[i].printDcm = ""
                       stackBind.children[i].autoPrint = "0"
                       stackBind.children[i].dfltAmnt = "1"
                       stackBind.children[i].dfltClient = dfltClnt;
                       stackBind.children[i].cashAcnt = cashAcnt;
                       stackBind.children[i].dfltAcnt = dfltAcnt;
                    } else {
                       stackBind.children[i].printDcm = checkPrintDcm
                       stackBind.children[i].autoPrint = checkAutoPrint
                       stackBind.children[i].dfltAmnt = Number(checkAmnt)
                       stackBind.children[i].dfltClient = dfltClnt;
                       stackBind.children[i].cashAcnt = cashAcnt;
                       stackBind.children[i].dfltAcnt = dfltAcnt;
                    }
                    stackBind.children[i].startBind()
                }
            } else {
                // error
            }
        }

        onError: message => {
            msgDialog.code = 'Error'
            msgDialog.message = 'Driver error\n'+message
            msgDialog.open()
        }

        onVkEvent: (eventId,eventParam) => {
            if (eventId === 'findDocum'){
//                msg('findDocum='+eventParam+'\n')
//                dcmView.appendDcm(eventParam, dcmFilterEdit.text)
            } else if (eventId === 'msg'){
//                           msg('#81g main.qml pwd='+eventParam+'\n')
                       }
        }

        Component.onCompleted: {
            // Lib.log("27y dbDriver onCompleted")
            var vdir = './data/'
            // default setting
            if (dbDriver.settingsValue("database/last_db_driver","n/a")==="n/a"){dbDriver.setSettingsValue("database/last_db_driver", "QSQLITE")}

            // if (dbDriver.settingsValue("terminal/code","n/a")==="n/a"){dbDriver.setSettingsValue("terminal/code", "TEST")}
            // if (dbDriver.settingsValue("terminal/name","n/a")==="n/a"){dbDriver.setSettingsValue("terminal/name", "TestName")}
            // if (dbDriver.settingsValue("terminal/address","n/a")==="n/a"){dbDriver.setSettingsValue("terminal/address", "")}
            // if (dbDriver.settingsValue("terminal/pos_printer","n/a")==="n/a"){dbDriver.setSettingsValue("terminal/pos_printer", "")}

//            if (dbDriver.settingsValue("program/path","n/a")==="n/a"){dbDriver.setSettingsValue("program/path","~/snap/vksoft")}
            // if (dbDriver.settingsValue("program/pwd","n/a")==="n/a"){dbDriver.setSettingsValue("program/pwd",".")}
            if (dbDriver.settingsValue("program/client","n/a")==="n/a"){dbDriver.setSettingsValue("program/client", "")}
            if (dbDriver.settingsValue("program/auto_close","n/a")==="n/a"){dbDriver.setSettingsValue("program/auto_close", "1")}
            if (dbDriver.settingsValue("program/auto_revaluation","n/a")==="n/a"){dbDriver.setSettingsValue("program/auto_revaluation", "1")}
            // if (dbDriver.settingsValue("program/binds","n/a")==="n/a"){dbDriver.setSettingsValue("program/binds", "check,tax,facture")}
            // if (dbDriver.settingsValue("program/incas_acnt","n/a")==="n/a"){dbDriver.setSettingsValue("program/incas_acnt", "")}

/*            if (dbDriver.settingsValue("upload/http_host","n/a")==="n/a"){dbDriver.setSettingsValue("upload/http_host", "")}
            if (dbDriver.settingsValue("upload/source_dir","n/a")==="n/a"){dbDriver.setSettingsValue("upload/source_dir", "./upload")}
            if (dbDriver.settingsValue("upload/http_user","n/a")==="n/a"){dbDriver.setSettingsValue("upload/http_user", "")}
            if (dbDriver.settingsValue("upload/http_password","n/a")==="n/a"){dbDriver.setSettingsValue("upload/http_password", "")}
*/
/*            if (settingsValue("check/amnt","n/a")==="n/a"){ setSettingsValue("check/amnt", "-1"); }
            if (settingsValue("check/auto_print","n/a")==="n/a"){ setSettingsValue("check/auto_print", ""); }
            if (settingsValue("check/print_dcm","n/a")==="n/a"){ setSettingsValue("check/print_dcm", ""); }
*/
            if (settingsValue("tax/amnt","n/a")==="n/a"){ setSettingsValue("tax/amnt", "-1"); }
            if (settingsValue("tax/auto_print","n/a")==="n/a"){ setSettingsValue("tax/auto_print", ""); }
            if (settingsValue("tax/print_dcm","n/a")==="n/a"){ setSettingsValue("tax/print_dcm", ""); }

            if (settingsValue("facture/amnt","n/a")==="n/a"){ setSettingsValue("facture/amnt", "1"); }
            if (settingsValue("facture/auto_print","n/a")==="n/a"){ setSettingsValue("facture/auto_print", ""); }
            if (settingsValue("facture/print_dcm","n/a")==="n/a"){ setSettingsValue("facture/print_dcm", ""); }


//            msg('#29d main.qml pwd='+currentDir()+'\n')
//             for testing
            root.term = settingsValue("terminal/code","TEST")

            let vbinds = String(dbDriver.settingsValue("program/binds","check"))
            pageTaxAction.enabled = ~vbinds.indexOf("tax")
            winTaxServiceAction.enabled = ~vbinds.indexOf("tax")
            pageFactureAction.enabled = ~vbinds.indexOf("facture")
            pageIncasAction.enabled = ~vbinds.indexOf("incas")


            // if(crsh.id === 0 || crsh.shftend !== "" || crsh.shftdate !== Qt.formatDateTime(new Date(), "yyyy-MM-dd")) {
            //     if (isIncas()) {
            //         modeShiftAction.trigger();
            //     } else { modeBindAction.trigger(); }

            // } else { modeBindAction.trigger(); }

            // incasAcntno = settingsValue("program/incas_acnt","")
            let pathToDb = "/data/"

//pathToDb = String("%1/$2/data/").arg(env().appPath).arg(settingsValue("program/pwd","."))
            // for Mac OS
            // pathToDb = env().appPath + "/"+settingsValue("program/pwd","") + "/data/"

            pathToDb = "./data/"
            var dbList = dirEntryList(pathToDb,'*.sqlite', 2,0)
//            console.log('main db list='+dbList)
            var vj = [];
            if (dbList.length === 1) {
                openConnection(pathToDb+dbList[0])
            } else if (dbList.length > 1) {
                changeDBAction.enabled = true
                changeDBAction.trigger()
// //                databaseView.model.clear()
//                 var crnt=''
//                 for (var i=0; i<dbList.length; ++i){
//                     vj[i]={'id':pathToDb+dbList[i], 'name':dbList[i],"fullname":'', 'mask':256, "sect":'Доступні БД'};
// //                    databaseView.model.append({'id':pathToDb+dbList[i], 'name':dbList[i]})
//                     if (String(pathToDb+dbList[i]) == String(dbDriver.settingsValue('database/last_db_name', ''))) {
//                         crnt = dbList[i]
//                     }
//                 }
// //                databasePopup.vdir = pathToDb
//                // Lib.log('#wy6 DB list count='+dbList.length+' crnt='+crnt + " last_db_name="+String(dbDriver.settingsValue('database/last_db_name', '')))
//                 if (crnt == '') {
//                     selectPopup.jsdata = vj;
//                     selectPopup.open()
//                 } else { openConnection(pathToDb+crnt) }

            } else {        // no database
                // error
                msgDialog.message = "No DB"
                msgDialog.open()
            }
        }
    }


    Timer{
        id: quitTimer
        interval: 5000
        repeat: false
        running: false
        onTriggered: {
            closeChildWindow()
            Qt.quit()
        }
    }

    Action {
        id: tranAction
        text: "Провести"        //qsTr("Tran")
//        icon.name: "edit-copy"
//        shortcut: StandardKey.Copy
        onTriggered: vdata => {
            // Lib.log("#94j bind="+JSON.stringify(vdata.jbind)); //return;
            vdata.jbind.id = "dcmbind"
            vdata.jbind.tm = Qt.formatDateTime(new Date(), "yyyy-MM-dd hh:mm:ss");
            vdata.jbind.cshr = root.cashier.id
            // console.log("#94yb tranAction autotax="+vdata.autoTax+" jbind="+JSON.stringify(vdata.jbind)); //return
            let tbId = dbDriver.dbBindTranFromJSON( vdata.jbind );
            if (tbId){
                if (vdata.autoPrint && vdata.printDcm !== ""){
                    if (vdata.printDcm === 'check') {
                     dbDriver.printCheck(tbId)

                    } else if (vdata.printDcm === 'check_knt'){
                     dbDriver.printCheck(tbId, "-попередня")
                    }
                }
                if (winTaxServiceAction.enabled && vdata.autoTax){ cdTaxCheck(tbId); }

            stackBind.children[stackBind.currentIndex].startBind()
            setClient()
/*            let tbId = dbDriver.dbBindTranFromJSON( stackBind.children[stackBind.currentIndex].jbindToTran() );
            if (tbId){
                if (stackBind.children[stackBind.currentIndex].crntPrint && stackBind.children[stackBind.currentIndex].printDcm !== ""){
                    if (stackBind.children[stackBind.currentIndex].printDcm === 'check') {
                        dbDriver.printCheck(tbId)

                    } else if (stackBind.children[stackBind.currentIndex].printDcm === 'check_knt'){
                        dbDriver.printCheck(tbId, "-попередня")
                    }
                }
                if (stackBind.children[stackBind.currentIndex].autoTax){ cdTaxCheck(tbId); }

                stackBind.children[stackBind.currentIndex].startBind()
*/
                if (isOnline()) {
                    let vsend="", vacflt = "", vitflt = "";
                    for (let r=0; r < vdata.jbind.dcms.length; ++r){
                        if (!~vacflt.indexOf(String("'"+vdata.jbind.dcms[r].cdt+"'"))) { vacflt += (vacflt===""?"":",") + String("'"+vdata.jbind.dcms[r].cdt+"'"); }
                        if (!~vacflt.indexOf(String("'"+vdata.jbind.dcms[r].dbt+"'"))) { vacflt += (vacflt===""?"":",") + String("'"+vdata.jbind.dcms[r].dbt+"'"); }
                        if (!~vitflt.indexOf(String("'"+vdata.jbind.dcms[r].crn+"'"))) { vitflt += (vitflt===""?"":",") + String("'"+vdata.jbind.dcms[r].crn+"'"); }
                    }
                    let vsql = String("select acntno, coalesce(item,'') as articleid, (beginamnt+turndbt-turncdt) as amnt, turndbt, turncdt, case when coalesce(dbtupd,'')>coalesce(cdtupd,'') then substr(dbtupd,1,16) else substr(cdtupd,1,16) end as tm "
                                   +"from acnt where acntno in ("+vacflt+") and (item in ("+vitflt+") or item is null) and substr(acntno,1,4) not in ('eqvl','rslt','7000');")
                    // console.log("#64gb tranAction vacflt="+ vacflt +" vitflt="+vitflt + " vsql="+vsql); //return
                    var acntjson  = JSON.parse(dbDriver.getJSONRowsFromSQL_2(vsql)).rows
                    // [{"acntno":"3000","articleid":"","amnt":"1862399.4700000007","turndbt":"4040","turncdt":"0","tm":"2024-05-05T06:36"}]                                 var jresp = JSON.parse(response.content)
                    // Lib.log("#j8f0qj AcntState vacnt="+JSON.stringify(acntjson)); //return;
                    if (acntjson.length) {  //
                        Lib.postRequest(resthost+restapi+"/accounts/index.php?api_token="+resttoken, {"term":term,"reqid":"upd","shop":term,"data":acntjson}, (response) => {
                         // Lib.log(response.status);
                         // Lib.log(response.headers);
                         // Lib.log( response.content);
                         if (response.status === 200) {
                             let isPlainText = response.contentType.length === 0
                             if (isPlainText) { }
                         } else if (response.status === 0){ msg('Site connection error', 'EE');
                         } else { msg("#48e status="+response.status+" error="+JSON.parse(response.content).errstr, 'EE'); }
                        });
                    }
/*      select acnt by updeted time
                    let vt = new Date()//     Qt.formatDateTime(new Date(), "yyyy-MM-ddThh:mm:ss")
                    vt.setSeconds(vt.getSeconds()-50)
                    let vsql = String("select acntno, coalesce(item,'') as articleid, (beginamnt+turndbt-turncdt) as amnt, turndbt, turncdt, case when coalesce(dbtupd,'')>coalesce(cdtupd,'') then substr(dbtupd,1,16) else substr(cdtupd,1,16) end as tm "
                                      +"from acnt where (dbtupd>'%1' or cdtupd>'%1') and substr(acntno,1,4) not in ('eqvl','rslt','7000');")
                                 .arg(Qt.formatDateTime(vt, "yyyy-MM-ddThh:mm:ss"))
                    */
                    // vsend = 'dataid=json_data&values='+JSON.stringify(vdata.jbind);
                    // let vb64 = Qt.btoa(vsend);
                    // msg("#6gwb  vsend="+vsend+" base64="+vb64)
                    // Lib.log("#86g bind="+JSON.stringify({"term":term,"reqid":"upd","shop":term,"data":vdata.jbind}))
                    // Lib.log("#86g bind="+JSON.stringify(vdata.jbind))
                    Lib.postRequest(resthost+restapi+"/dcms/index.php?api_token="+resttoken, {"term":term,"reqid":"upd","shop":term,"data":vdata.jbind}, (response) => {
                    // Lib.log( "#326y status=" + response.status +"content=" + response.content);
                    if (response.status === 200) {
                      let isPlainText = response.contentType.length === 0
                      if (isPlainText) { }
                    } else if (response.status === 0){ msg('Site connection error', 'EE')
                    } else { msg("#93j status="+response.status+" error="+JSON.parse(response.content).errstr, 'EE'); }

                    });
                }
            } else { msg('Помилка обробки чеку', 'EE')
                // TODO
                // nothing to do or error
            }

        }
    }

    Action {
        id: pageCheckAction
        text: "Чек"        //qsTr("Check")
//        icon.name: "edit-copy"
//        shortcut: StandardKey.Copy
        onTriggered: {
            // btnClient.enabled = true
            modeBindAction.trigger()
            stackBind.currentIndex = 0;
        }
    }

    Action {
        id: pageTaxAction
        enabled: false
        text: "ФІСКАЛЬНИЙ чек"        //qsTr("")
        onTriggered: {
            modeBindAction.trigger()
            stackBind.currentIndex = 1;
        }
    }

    Action {
        id: pageFactureAction
        enabled: false
        text: "Фактура"
        onTriggered: {
            modeBindAction.trigger()
            stackBind.currentIndex = 2;
        }
    }

    Action {
        id: pageIncasAction
        enabled: true
        text: "Інкасація"
        onTriggered: {
            modeBindAction.trigger()
            btnClient.enabled = false
            stackBind.currentIndex = 3;
        }
    }

    Action {
        id: winDcmsAction
        checkable: true
        checked: dcmViewLoader.active
//        enabled: false
        text: "Документи"
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
        id: modeBindAction
        // text: qsTr("Зміна")
        onTriggered: {
            appToolBar.enabled = true
            bindContentMenu.enabled = true
            btnClient.enabled = true
            stackBind.visible = true
            shift.visible = false
            settingsArea.visible = false
        }
    }

    Action {
        id: modeShiftAction
        text: qsTr("Зміна")
        onTriggered: {
            closeChildWindow()
            shift.vpopulate(root.crntShift(),
                      JSON.parse(dbDriver.getJSONRowsFromSQL_2("select code, note, psw from cashier order by note;")).rows,
                      JSON.parse(dbDriver.getJSONRowsFromSQL_2(String("select acnt.id tid,acnt.acntno tno, acnt.item as curid, itemchar as cur, eq.id eid, eq.acntno eno,'rslt.'||acntrade.acntno||'/'||acntrade.article as rno, "
                                                                      +"bscprice, qtty as qty, price, 0-(acnt.beginamnt+acnt.turndbt-acnt.turncdt) amnt, (eq.beginamnt+eq.turndbt-eq.turncdt) as eqamnt, "
                                                                      +"round(0-(acnt.beginamnt+acnt.turndbt-acnt.turncdt) * bscprice - (eq.beginamnt+eq.turndbt-eq.turncdt),2) as profit from  acntrade join acnt on (acntrade.pkey = acnt.id) "
                                                                      +"left join price using(item) join item on (acnt.item=item.pkey)  join acnt as eq on (('eqvl.'||acntrade.acntno||'/'||acntrade.article) = eq.acntno) "
                                                                      +"where substr(acnt.acntno,1,4)='3500' and prbidask=1 and itemmask=2 order by acnt.acntno,itemnote;"))).rows
                      )
            appToolBar.enabled = false
            // bindContentMenu.enabled = false
            stackBind.visible = false
            settingsArea.visible = false
            shift.visible = true

        }
    }

    Action {
        id: modeSettingAction
        text: qsTr("Settings")
        onTriggered: {
            // settingsDialog.open()
            // appToolBar.enabled = false
            bindContentMenu.enabled = false
            btnClient.enabled = false
            stackBind.visible = false
            shift.visible = false
            settingsArea.visible = true
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
        id: incasBulkAction
        text: "Інкас ГУРТ"
        enabled: stackBind.currentIndex === 3
        onTriggered: {
            let r = 0;
            var vj = JSON.parse(dbDriver.getJSONRowsFromSQL_2(String("SELECT item, beginamnt+turndbt-turncdt amnt from acnt where acntno='%1' and amnt != 0;").arg(acnts.bulk))).rows
//            msg("#38d tot="+JSON.stringify(vj))
            setAccount(acnts.bulk)
            for (r=0; r<vj.length; ++r){
                new2Dcm(vj[r].item, { "amnt": String(Number(vj[r].amnt)) })
                // new2Dcm(vj[r].item, { "amnt": String(Number(vj[r].amnt)), "acntno":acnts.bulk })
            }
            stackBind.children[stackBind.currentIndex].startNewRow()
        }
    }

    Action {
        id: uahToAcntAction
        enabled: false
        text: "ГРН на рахунок"
        onTriggered: {
            let r = 0;
            let vj = stackBind.children[stackBind.currentIndex].articleTotal(1)
//            msg("#38d tot="+JSON.stringify(vj))
            var vjb = []
            for (r=0; r<vj.length; ++r) { vjb.push({"id":vj[r].id, "name":vj[r].name, "amnt":vj[r].amnt});}
            for (r=0; r<vjb.length; ++r){
                new2Dcm(vjb[r].id, { "amnt": String(0-vjb[r].amnt) })
            }
            stackBind.children[stackBind.currentIndex].startNewRow()
        }
    }

    Action {
        id: curToAcntAction
        enabled: false
        text: "ГРН+ВАЛЮТА на рахунок"
        onTriggered: {
            let r = 0;
            // let vj = stackBind.children[stackBind.currentIndex].articleTotal(3)
//            msg("#8eh tot="+JSON.stringify(vj))
            var vjb = []
            for (r=0; r<stackBind.children[stackBind.currentIndex].articleTotal(3).length; ++r) {
                vjb.push({"id":stackBind.children[stackBind.currentIndex].articleTotal(3)[r].id,
                            "name":stackBind.children[stackBind.currentIndex].articleTotal(3)[r].name,
                            "amnt":stackBind.children[stackBind.currentIndex].articleTotal(3)[r].amnt});
            }
            for (r=0; r<vjb.length; ++r){
                new2Dcm(vjb[r].id, { "amnt": String(0-vjb[r].amnt) })
            }
            stackBind.children[stackBind.currentIndex].startNewRow()
        }
    }

    Action {
        id: changeDBAction
        enabled: false
        text: "Змінити БД ["+root.dbname.substring(dbname.lastIndexOf('/'))+"]"
        onTriggered: {
            let pathToDb = "/data/"
            //pathToDb = String("%1/$2/data/").arg(env().appPath).arg(settingsValue("program/pwd","."))
            // pathToDb = env().appPath + "/"+settingsValue("program/pwd","") + "/data/"
            pathToDb = "./data/"
            var dbList = dbDriver.dirEntryList(pathToDb,'*.sqlite', 2,0)
//            console.log('main db list='+dbList)
            var vj = [];
            for (var i=0; i<dbList.length; ++i){
                vj[i]={'id':pathToDb+dbList[i], 'name':dbList[i],"fullname":'', 'mask':"256", "sect":'Доступні БД'};
//                    databaseView.model.append({'id':pathToDb+dbList[i], 'name':dbList[i]})
            }
            selectPopup.jsdata = vj;
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
                             item.jsclient = JSON.parse( dbDriver.getJSONRowsFromSQL_2("select pkey id, clchar, clnote from client order by pkey;") ).rows
                             item.jsacnt = JSON.parse( dbDriver.getJSONRowsFromSQL_2("select acntno, coalesce(client,'') clid, coalesce(acntnote,'') note, mask, trade, coalesce(clchar,'') clchar from acntbal left join client on acntbal.client=client.pkey;") ).rows
                             item.jscur = JSON.parse( dbDriver.getJSONRowsFromSQL_2("select item.pkey as id, itemchar, itemname, coalesce(scancode,'') as scan, coalesce(qty,1) as qty, coalesce(unitprec,2) as prec, itemmask mask "
                                            +"from item left join itemunit on (defunit=itemunit.pkey) left join articlepriceqty using(pkey) where folder=0;") ).rows
                             // item.jsbind = JSON.parse( dbDriver.getJSONRowsFromSQL_2("select id as dcmid, dcmtype, coalesce(item,'') atclid, acntdbt, acntcdt, amount, eqamount eq, discount dsc, bonus bns, coalesce(client,'') clid, coalesce(parentid,'') pid, coalesce(dcmnote,'') dnote, dcmtime dtm "
                             //                +"from docum where dcmtype='check' or dcmtype='facture' or dcmtype='folder';") ).rows
                             item.jsdcm = JSON.parse( dbDriver.getJSONRowsFromSQL_2("select 0 as shftid, id as dcmid, dcmtype, coalesce(item,'') atclid, acntdbt, acntcdt, amount, eqamount eq, discount dsc, bonus bns, coalesce(client,'') clid, coalesce(parentid,'') pid, coalesce(dcmnote,'') dnote, dcmtime dtm from docum order by dtm desc, dcmid;") ).rows
                             // item.jsdcm = JSON.parse( dbDriver.getJSONRowsFromSQL_2("select 0 as shftid, id as dcmid, dcmtype, coalesce(item,'') atclid, acntdbt, acntcdt, amount, eqamount eq, discount dsc, bonus bns, coalesce(client,'') clid, coalesce(parentid,'') pid, coalesce(dcmnote,'') dnote, dcmtime dtm from docum "
                             //                    +"where id in (select coalesce(parentid,id) from docum where item='978') or "
                             //                    +"parentid in (select coalesce(parentid,id) from docum where item='978') order by dtm desc, dcmid;") ).rows
                            // SQL for client + archive
                             // item.jsdcm = JSON.parse( dbDriver.getJSONRowsFromSQL_2("select shftid, id as dcmid, dcmtype, coalesce(item,'') atclid, acntdbt, acntcdt, amount, eqamount eq, discount dsc, bonus bns, coalesce(client,'') clid, coalesce(parentid,'') pid, "
                             //                    +"coalesce(dcmnote,'') dnote, dcmtime dtm from documall where id in (select id from documall where client='1000') or parentid in (select id from documall where client='1000') "
                             //                    +"or id in (select coalesce(parentid,id) from documall where acntcdt in (select acntno from acntbal where client='1000')) "
                             //                    +"or parentid in (select coalesce(parentid,id) from documall where acntcdt in (select acntno from acntbal where client='1000')) order by dtm desc, dcmid limit 500;") ).rows
                             // item.jdata = JSON.parse( dbDriver.getJSONRowsFromSQL_2(item.sqlStatement.arg("docum").arg("0 as shftid").arg("")) ).rows
                             // Lib.log("log", "#6eg cl="+JSON.stringify(item.jsdcm))
                         }
        Connections {
            target: dcmViewLoader.item
            function onClosing() {
                dcmViewLoader.active = false
            }
            function onVkEvent(id, param) {
                if (id === 'dataRequest'){
                   // console.log("#47h sql="+param.sql)
                    dcmViewLoader.item.jsdcm = JSON.parse( dbDriver.getJSONRowsFromSQL_2(param) ).rows
                } else if (id === "find"){
                    let sql = "select pkey as id, clchar as name, coalesce('tel.'||phone,'') || coalesce(' '||clnote,'')  as fullname, '' as scancode, 64 as mask, 'Клієнти' as sect, '0' as odr from client "
                    +"union select item.pkey as id, itemchar as name, coalesce(itemname, itemnote,'') as fullname, coalesce(scancode,'') as scancode, itemmask as mask, case when itemmask=4 then 'Товари' else 'Валюти' end as sect, '1' as odr from item where folder = 0 "
                    +"union select acntno as id, acntno||'-'||coalesce(acntnote,'['||balname||']','') as name, '' as fullname, '' as scancode, 128 as mask, 'Рахунки' as sect, '3' as odr from acntbal left join balname on(substr(acntno,1,2)=bal) where client is null "
                    +"order by odr, sect,itemmask,name;";
                    dcmViewLoader.item.findList = JSON.parse(dbDriver.getJSONRowsFromSQL_2(sql,param)).rows;

                } else if (id === "bind"){
                    // Lib.log('log','#62k pid='+param)
                    dcmViewLoader.item.bind = dbDriver.getJSONBind2(param)
                   // console.log("#93j id="+param+" bind="+JSON.stringify(dcmViewLoader.item.bind) )
                } else if (id === "return"){
                    // Lib.log('#01yb dcm='+JSON.stringify(param), 'dcmViewLoader'); return;
//                    param { acntno, code, amnt, price, dsc, bns, pratt, retfor}
                    if (stackBind.children[stackBind.currentIndex].state !== ""){   // move to check
                        let crnt = 0
                        for (crnt =0; crnt < stackBind.children.length; ++crnt ){
                            if (stackBind.children[crnt].state === "") { break;}
                        }
                        if ( crnt < stackBind.children.length ){ stackBind.currentIndex = crnt;}
                            else {
                            msgDialog.code = 'Error'
                            msgDialog.message = "Відсутній Чек для повернення"
                            msgDialog.open()
                            return;
                        }
                    }
                    let cl = dbDriver.getJSONRowFromSQL("select coalesce(client,'') as cl from documall where id ="+param.pid).cl
                    // console.log("#94j cl="+cl+" bindclid="+stackBind.children[stackBind.currentIndex].crntClient.id)
                    if (stackBind.children[stackBind.currentIndex].crntClient.id ===""){
                        setClient(cl)
                    }

                    if (stackBind.children[stackBind.currentIndex].crntClient.id !== cl){
                        msgDialog.code = 'Error'
                        msgDialog.message = "Клієнт Чеку вже визначений і відрізняється від чеку повернення"
                        msgDialog.open()
                        return;
                    }

//                    if (Math.abs(Number(param.bns)) > z0) {     // change client

//                    }
//return;
                    new2Dcm(param.atclid, { "acntno":param.acntcdt, "code":param.dcmtype,
                                "amnt": String(0-Number(param.amount)),
                                "price":Math.abs(Number(param.eq)/Number(param.amount)),
                                "dsc":Math.abs(Number(param.dsc)/Number(param.eq)),
                                "bns":Math.abs(Number(param.bns)/Number(param.eq)),
                                "pratt":0, "retfor":param.dcmid})
                } else if (id === "printCheck"){
                    dbDriver.printCheck(param.id, ' (копія)', "report/lastcheck.pdf")
                    if (stackBind.children[stackBind.currentIndex].printDcm === 'check') {
                        dbDriver.printCheck(param.id, ' (копія)')
                    } else if (stackBind.children[stackBind.currentIndex].printDcm === 'check_knt') {
                        dbDriver.printCheck(param.id, "-попередня (копія)")
                    }
                } else if (id === "printFacture"){
//                    msg('printid='+bindPopup.jsdata.bindid)
                    dbDriver.printOrder(param.id,"report/order.pdf")
                } else if (id === "fiscCheck"){
    //                msg('printid='+bindPopup.jsdata.bindid)
                    cdTaxCheck(param.id)
                } else if (id === 'log'){ Lib.log(param,"DcmView");
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
                             cashWizardLoader.item.cashAmnt = dbDriver.getJSONRowFromSQL(String("select item, beginamnt+turndbt-turncdt as total from acnt where item is null")).total
                         }
        Connections {
            target: cashWizardLoader.item
            function onClosing() {
                cashWizardLoader.active = false
            }
            function onVkEvent(event) {
                if (event.id === 'loadData'){
                     cashWizardLoader.item.cashAmnt = dbDriver.getJSONRowFromSQL(String("select item, beginamnt+turndbt-turncdt as total from acnt where item %1")
                                                                                 .arg(event.crn === '' ? 'is null' : String("= '%1'").arg(event.crn))).total
                }

            }
        }
    }

    Loader{
        id: statLoader
        active: false
        source: 'Stat.qml'
        onActiveChanged: if (active) {
                             item.visible = true
                             item.title = String("%1(%2)").arg(root.title).arg("Stat")
                             let cshr = crntShift().cshr
                             statLoader.item.jsdata =
                                     JSON.parse(dbDriver.getJSONRowsFromSQL_2(String("select substr(dcmtime,1,10) as tm, acntcdt, p.client, sum(amount) as amnt from strgdocum as d join "
                                                                + "(select dcmid, client from strgdocum where dcmtype='folder' and acntcdt='rslt') as p on (d.parentid=p.dcmid) "
                                                                + "where substr(acntcdt,1,9)='rslt.3500' and dcmtime > substr(date('now', '-4 month'),1,7) and p.client='%1' group by substr(dcmtime,1,10), acntcdt, p.client ORDER by tm desc;").arg(cshr))).rows
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
                             // item.height = root.height
                             item.jscur = JSON.parse(dbDriver.getJSONRowsFromSQL_2(
                                                         "select pkey as curid, itemchar as curchar, itemname as curname, coalesce(qty,1) as qty, "
                                                         +" itemnote as so from item left join articlepriceqty using(pkey) where folder = 0 "
                                                         +" and itemmask = 2 and itemnote!='' and itemnote is not null order by itemnote;")).rows
                             let vpath = resthost+restapi+"/rates/index.php?api_token="+resttoken
                             Lib.postRequest(vpath, {"term":term,"reqid":"sel","shop":root.term}, (response) => {
                              if (response.status === 200) {
                                  let isPlainText = response.contentType.length === 0
                                  if (isPlainText) { rateLoader.item.setWeb(JSON.parse(response.content)); }
                              } else if (response.status === 0){ msg(vpath+': Site connection error', 'EE')
                              } else { msg(vpath + ": status="+response.status+" error="+JSON.parse(response.content).errstr, 'EE'); }
                             });
                         }
        Connections {
            target: rateLoader.item
            function onClosing() { rateLoader.active = false; }

            function onVkEvent(id,param) {
                let vsql = ""
                // console.log("#09k Main HERE id="+id+" param="+JSON.stringify(param))
                if (id === "updLocalRate"){
                    vsql = String("update price set qtty=%1, price=%2 where id=%3;")
                    .arg(param.qty).arg(param.price).arg(param.id)
                    // console.log("#09k Main sql="+vsql)
                    dbDriver.dbUpdate(vsql)
                } else if (id === "newLocalRate"){
                    vsql = String("insert into price (item, qtty, price, prbidask) values ('%1', %2, %3, %4)")
                    .arg(param.curid).arg(param.qty).arg(param.price).arg(param.ba)
                    // console.log("#u7e Main sql="+vsql)
                    dbDriver.dbInsert(vsql)
                } else if (id === "getLocal"){
                    // console.log("#ow4 Main force refresh local")
                    rateLoader.item.setLocal(JSON.parse(dbDriver.getJSONRowsFromSQL_2(
                                            "select id, item curid, prbidask ba, qtty qty, price "
                                            +" from price join item on(item=pkey) where (prtype is null or prtype='') and itemmask = 2 and itemnote!='' and itemnote is not null ;")).rows)
                } else if (id === "getWeb"){
                    let vpath = resthost+restapi+"/rates/index.php?api_token="+resttoken
                    Lib.postRequest(vpath, {"term":term,"reqid":"sel","shop":root.term}, (response) => {
                     // Lib.log(response.status);
                     // Lib.log(response.headers);
                     // Lib.log( response.content);
                     if (response.status === 200) {
                         let isPlainText = response.contentType.length === 0
                         if (isPlainText) { rateLoader.item.setWeb(JSON.parse(response.content)); }
                     } else if (response.status === 0){ msg(vpath+': Site connection error', 'EE')
                     } else { msg(vpath + ": status="+response.status+" error="+JSON.parse(response.content).errstr, 'EE'); }
                    });
                } else if (id === "newDocum"){
                    new2Dcm(param)
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
                             item.jdata = JSON.parse(dbDriver.getJSONRowsFromSQL_2(String("select pkey, clchar, coalesce(phone,'') as phone, coalesce(clnote,'') as clnote from client order by clchar;"))).rows
                         }
        Connections {
            target: clientLoader.item
            function onClosing() {
                clientLoader.active = false
            }
            function onVkEvent(event) {
                if (event.id === 'newClient'){
                    var clid = dbDriver.dbClientInsert()
//                    drawerRightView.jdata = vdata.sort((a,b) => { return (((a.bind)+sortCoef(a.name.substring(0,3))) < ((b.bind)+sortCoef(b.name.substring(0,3)))) ? -1 : 1; } )
                    clientLoader.item.jdata = (JSON.parse(dbDriver.getJSONRowsFromSQL_2(String("select pkey, clchar, coalesce(phone,'') as phone, coalesce(clnote,'') as clnote from client;"))).rows)
                    .sort((a,b) => { return  a.clchar < b.clchar ? -1 : 1; })
                } else if (event.id === 'submit') {
                    dbDriver.dbUpdate(String("update client set clchar = '%1', phone=%2, clnote=%3 where pkey='%4'")
                                      .arg(event.name)
                                      .arg(event.phone === '' ? 'null' : String("'%1'").arg(event.phone))
                                      .arg(event.note === '' ? 'null' : String("'%1'").arg(event.note))
                                      .arg(event.pkey))
                    clientLoader.item.jdata = (JSON.parse(dbDriver.getJSONRowsFromSQL_2(String("select pkey, clchar, coalesce(phone,'') as phone, coalesce(clnote,'') as clnote from client;"))).rows)
                    .sort((a,b) => { return  a.clchar < b.clchar ? -1 : 1; })
                }

            }
        }
    }

    Loader{
        id: taxServiceLoader
        active: false
        source: 'TaxService.qml'
        onActiveChanged: if (active) {
                             item.visible = true
                             item.title = String("%1(%2)").arg(root.title).arg("Tax service")
                             item.host = cdhost
                             item.cash = cdcash
                             item.prefix = cdprefix
                             item.token = cdtoken
                         }
        Connections {
            target: taxServiceLoader.item
            function onClosing() {
                taxServiceLoader.active = false
            }
            function onVkEvent(event,param) {
                if (event === 'ping'){
//                    console.log("#5n4 Main ping started")
                    taxRequest("/shift/ping", { "api_token": cdtoken, "num_fiscal": cdcash }, (response) => {
                     // Lib.log(response.status);
                     // Lib.log(response.headers);
                     // Lib.log( response.content);
                    let jsresp = JSON.parse(response.content)
                    while (~response.content.indexOf(',"')){ response.content = response.content.replace(',"',',\n"'); }
                    if (response.status === 200) {
                        let isPlainText = response.contentType.length === 0
                        if (isPlainText && taxServiceLoader.active) {
                            taxServiceLoader.item.showResp({"code":"info", "sender":"ping",
                            "resp": "ping OK #" +jsresp.user_signature.user_id + " "+jsresp.user_signature.full_name, "tm":new Date()});
                        }
                    } else if (response.status === 0){
                        taxServiceLoader.active = true
                        taxServiceLoader.item.showResp({"code":"error", "sender":"ping", "resp":'Site connection error', "tm":new Date()});
                    } else {
                        taxServiceLoader.active = true
                        taxServiceLoader.item.showResp({"code":"error", "sender":"ping", "resp":"Status="+response.status+": "+response.content, "tm":new Date()});
                    }
                    });

                } else if (event === 'xreport'){
                    taxRequest("/shift/xReport", { "api_token": cdtoken, "num_fiscal": cdcash,"no_text_print": true,"no_pdf": true,"include_checks": false },
                               (response) => {
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
                    });
                } else if (event === 'zreport'){
                    askDialog.code = 'zreport'
                    askDialog.jdata =  { "text" : "Закрити фіскальну зміну ДПС ?" }
                    askDialog.open()
                } else if (event === 'settings'){
//                    console.log("#84y main cash="+param.cash+" host="+param.host+" prefix="+param.prefix+" token="+param.token)
                    cdhost = param.host !== undefined ? param.host : ""
                    cdprefix = param.prefix !== undefined ? param.prefix : ""
                    cdcash =  param.cash !== undefined ? param.cash : ""
                    cdtoken = param.token !== undefined ? param.token : ""
                } else {}

            }
        }
    }


    Popup{
        id: selectPopup
        property var jsdata     // JSON value: id, name, fullname, scancode, mask, sect
        onJsdataChanged: {
//            selectPopupView.vpopulate(jsdata)
        }
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
                        if (Number(mask)===0){                  // client
                            setClient(id); stackBind.children[stackBind.currentIndex].startNewRow();
                        } else if (Number(mask)===256) {        // database
                            openConnection(id)
                            // openConnection(name)
                        } else if (Number(mask)===128) {        // acntno
                            setAccount(id)
                            // stackBind.children[stackBind.currentIndex].crntAcnt = getAccount(id)
                            stackBind.children[stackBind.currentIndex].startNewRow();
                        } else {
                            new2Dcm(id);        // 1|2|4 article
                        }
//                        msg('index='+index+' name='+name)
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
        onVisibleChanged: if(!visible){selectPopupFilter.text='';} else {selectPopupView.vpopulate(selectPopupFilter.text); selectPopupFilter.forceActiveFocus();}

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
                    dbDriver.printCheck(askDialog.jdata.prid, askDialog.jdata.prname === 'check' ? "" : "-попередня")
                } else {
                    msgDialog.code = 'Error'
                    msgDialog.message = 'main'+'\n'+'Prind bind paraneter error'
                    msgDialog.open()
                }
            } else if (code === "askCloseShift"){       // { "text" : "Закрити попередню зміну ?","shid":crsh.id,"shdate":crsh.shftdate, "cshr":crsh.cshr }
                // Lib.log("#7rh askCloseShift"); return;
                if (isIncas()) {
                    modeShiftAction.trigger();
                } else {
                    shift.doClose({"shid":jdata.shid,"shdate":jdata.shdate, "cshr":jdata.cshr})
                    // modeBindAction.trigger();
                }
            } else if (code === "zreport"){
//                msg("#945 zReport ok")

                taxRequest("/shift", { "api_token": cdtoken, "num_fiscal": cdcash, "action_type": "Z_REPORT" },
                           (response) => {
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
                });


                // quitTimer.start()
//                Qt.quit();
            } else {
                console.log("#0i code undefined")
            }
        }
//        onRejected:  { console.log("#348j rejected"); }
        onClosed: { askDialog.jdata = ({}); }
    }

    Drawer {
        id: drawer2Right
//        onOpened: {
//            drawer2RightItem.jdata = JSON.parse(dbDriver.getJSONRowsFromSQL_2(drawer2RightItem.dfltSql)).rows
//        }

        width: parent.width < 500 ? parent.width*0.8 : 400
        height: parent.height
        edge: Qt.RightEdge
        DrawerItem{
            id: drawer2RightItem
            anchors.fill: parent
            onVkEvent: (id, param) => {
                if (id === "sqlRequest"){
                    jdata = JSON.parse(dbDriver.getJSONRowsFromSQL_2(param.sql)).rows
                } else if (id === "rowDClicked"){
//                    console.log("#283n param="+JSON.stringify(param))
                    if (param.acnt.substring(0,3) === "300") {
                        new2Dcm(param.atcl)
                    } else if (param.acnt.substring(0,3) === "350") {
                        setAccount(); new2Dcm(param.atcl)
                    } else if (param.acnt.substring(0,3) === "360" || param.acnt.substring(0,3) === "380") {
                        if (stackBind.children[stackBind.currentIndex].crntClient.id === undefined
                            || stackBind.children[stackBind.currentIndex].crntClient.id === '' || stackBind.children[stackBind.currentIndex].crntClient.id === param.clid){
                           setClient(param.clid)
                           setAccount(param.acnt);
                           new2Dcm(param.atcl, {"amnt": String(0-Number(param.amnt))})
                           if (param.acnt.substring(0,3) === "380"){ setAccount(); }

                        } else {    // not possible
                           msgDialog.code = 'Error'
                           msgDialog.message = 'Клієнта вже обрано'
                           msgDialog.open()
                        }
                    } else if (param.acnt.substring(0,3) === "302") {
                        new2Dcm(param.atcl, {"amnt": String(0-Number(param.amnt))})
                    } else if (param.acnt.substring(0,3) === "300") {

                    } else if (param.acnt === "300") {

                    }
                } else {
                      // unmanaged event
                }
            }
        }

        onVisibleChanged: if (!visible) {
                              drawer2RightItem.jdata = ({})
                              stackBind.children[stackBind.currentIndex].startNewRow()
                          } else {
                            drawer2RightItem.jdata = JSON.parse(dbDriver.getJSONRowsFromSQL_2(drawer2RightItem.dfltSql)).rows
                          }
    }

    StackLayout{
        id: stackBind
        anchors.fill: parent
        onCurrentIndexChanged: {
            // Lib.log("#833u current index = "+ currentIndex)
            root.crntClient = stackBind.children[stackBind.currentIndex].crntClient
            uahToAcntAction.enabled = (Number(stackBind.children[stackBind.currentIndex].crntAcnt.mask)&1)==1
            curToAcntAction.enabled = (Number(stackBind.children[stackBind.currentIndex].crntAcnt.mask)&3)==3
        }

        Bind{

            onVkEvent: (id, param) => {
    //                msg(' event.id='+event.refreshSite)
                if (id === 'tranBind'){
                    bindObj.jbind = jbindToTran()
                    bindObj.printDcm = printDcm
                    bindObj.autoPrint = crntPrint
                    bindObj.autoTax = autoTax
                    tranAction.trigger(bindObj)
                    startBind()
                } else if ((id === 'findArticle') && (param.text !== '')) { findText(param.text);
                } else if (id === 'createDcmUAH') { new2Dcm('')
                } else if (id === 'creditAcntClicked') { selectAcnt();
                } else if (id === 'crntAcntToTrade'){ crntAcnt = getAccount();
                } else if (id === 'viewCash'){ drawer2Right.open();
                } else if (id === 'error'){
                    msgDialog.code = 'Error'
                    msgDialog.message = 'Check\n'+param.text
                    msgDialog.open()
                } else if (id === 'log'){ msg(param.text,"Bind");
                } else {
                    // bad event
                }
            }
            Component.onCompleted: {
                // ++loadStatus
                printDcm = checkPrintDcm
                autoPrint = checkAutoPrint
                dfltAmnt = Number(checkAmnt)
                // Lib.log("#01i bindCheck onCompleted dfltClient="+dfltClient+" dfltAcnt="+JSON.stringify(getAccount()))
            }
        }

        Bind{
            state: "taxcheck"

            onVkEvent: (id, param) => {
    //                msg(' event.id='+event.refreshSite)
                if (id === 'tranBind'){
                    bindObj.jbind = jbindToTran()
                    bindObj.printDcm = printDcm
                    bindObj.autoPrint = crntPrint
                    bindObj.autoTax = autoTax
                    tranAction.trigger(bindObj)
                    startBind()
                } else if ((id === 'findArticle') && (param.text !== '')) { findText(param.text);
                } else if (id === 'createDcmUAH') { new2Dcm('')
                } else if (id === 'creditAcntClicked') { selectAcnt();
                } else if (id === 'crntAcntToTrade'){ crntAcnt = getAccount();
                } else if (id === 'viewCash'){ drawer2Right.open();
                } else if (id === 'error'){
                    msgDialog.code = 'Error'
                    msgDialog.message = 'Tax bind\n'+param.text
                    msgDialog.open()
                } else if (id === 'log'){ msg(param.text,"Bind");
                } else {
                    // bad event
                }
            }
            Component.onCompleted: {
                // ++loadStatus
                printDcm = checkPrintDcm
                autoPrint = checkAutoPrint
                dfltAmnt = Number(checkAmnt)
            }
        }

        Bind{
            state: "facture"

            onVkEvent: (id, param) => {
    //                msg(' event.id='+event.refreshSite)
                if (id === 'tranBind'){
                    bindObj.jbind = jbindToTran()
                    bindObj.printDcm = printDcm
                    bindObj.autoPrint = crntPrint
                    bindObj.autoTax = autoTax
                    tranAction.trigger(bindObj)
                    startBind()
                } else if ((id === 'findArticle') && (param.text !== '')) { findText(param.text);
                } else if (id === 'createDcmUAH') { new2Dcm('')
                } else if (id === 'creditAcntClicked') { selectAcnt();
                } else if (id === 'crntAcntToTrade'){ crntAcnt = getAccount();
                } else if (id === 'viewCash'){ drawer2Right.open();
                } else if (id === 'error'){
                    msgDialog.code = 'Error'
                    msgDialog.message = 'Facture\n'+param.text
                    msgDialog.open()
                } else if (id === 'log'){ msg(param.text,"Bind");
                } else {
                    // bad event
                }
            }
            Component.onCompleted: {
                // ++loadStatus
                printDcm = ""
                autoPrint = "0"
                dfltAmnt = "1"
            }
        }

        Bind{
            state: "incas"

            onVkEvent: (id, param) => {
    //                msg(' event.id='+event.refreshSite)
                if (id === 'tranBind'){
                    bindObj.jbind = jbindToTran()
                    bindObj.printDcm = printDcm
                    bindObj.autoPrint = crntPrint
                    bindObj.autoTax = autoTax
                    tranAction.trigger(bindObj)
                    startBind()
                } else if ((id === 'findArticle') && (param.text !== '')) { findText(param.text);
                } else if (id === 'createDcmUAH') { new2Dcm('')
                } else if (id === 'creditAcntClicked') { selectAcnt();
                } else if (id === 'crntAcntToTrade'){ crntAcnt = getAccount();
                } else if (id === 'viewCash'){ drawer2Right.open();
                } else if (id === 'error'){
                    msgDialog.code = 'Error'
                    msgDialog.message = 'Check\n'+param.text
                    msgDialog.open()
                } else if (id === 'log'){ msg(param.text,"Bind");
                } else {
                    // bad event
                }
            }
            Component.onCompleted: {
                // ++loadStatus
                printDcm = checkPrintDcm
                autoPrint = checkAutoPrint
                dfltAmnt = Number(checkAmnt)
            }
        }

    }

    Shift{
        id: shift
        visible: false
        anchors.centerIn: parent
        width: parent.width *0.8
        height: parent.height *0.6 // 250 //parent.height *0.3
        onVkEvent: (id, param) => {
//                msg(' event.id='+event.refreshSite)
            if (id === 'tranBind'){
                // console.log("#d7p Main jbindToTran="+ JSON.stringify(param)); return;
                bindObj.jbind = param
                bindObj.printDcm = ""
                bindObj.autoPrint = false
                bindObj.autoTax = false
                tranAction.trigger(bindObj)
                modeShiftAction.trigger()
            } else if(id==="cancel") {
                if(root.crntShift().shftend !== "") { modeShiftAction.trigger(); } else { modeBindAction.trigger(); }
            } else if(id==="open") {
                if( doOpen(param) ) { modeBindAction.trigger(); }
            } else if(id==="close") {       // param = {"shid":, "cshr":}
                // console.log("#6ev Main shiftid="+ JSON.stringify(param)); return;
                if( isTaxMode() ) {
                   askDialog.code = 'zreport'
                   askDialog.jdata =  { "text" : "Закрити фіскальну зміну ДПС ?" }
                   askDialog.open()
                }
                doClose(param)
                root.visible = false;
                quitTimer.start()
            } else {
               // bad event
           }
       }
        function doOpen(param) {        // param = {"id":cmb.currentValue, "name":cmb.currentText}
            let vnewd = new Date()
            let isNewMonth = (root.acnts.profit !== undefined &&  root.acnts.profit !== "")
            if (isNewMonth) {
                var vcrsh = crntShift()
                isNewMonth = (vcrsh.shftdate.substring(0,7) !== Qt.formatDateTime(vnewd, "yyyy-MM") )
            }
            // msg("#94i prev="+vcrsh.shftdate.substring(0,7)+" new="+Qt.formatDateTime(vnewd, "yyyy-MM")+" isNewMonth="+isNewMonth); return;

            let vsql = ("insert into shift (shftdate, shftbegin, cshr) values ('%1','%2','%3');")
                       .arg(Qt.formatDateTime(vnewd, "yyyy-MM-dd"))
                       .arg(Qt.formatDateTime(vnewd, "yyyy-MM-dd hh:mm"))
                       .arg(param.id)
            // console.log("#uhe4 sql="+vsql)
            let vid =  dbDriver.dbInsert(vsql)
            // console.log("#4eq id="+vid)
            if (isOnline()){
               let vpath = resthost+restapi+"/accounts/index.php?api_token="+resttoken
               Lib.postRequest(vpath, {"reqid":"del","shop": root.term}, (response) => {
                   if (response.status === 200) {
                       let isPlainText = response.contentType.length === 0
                       if (isPlainText) {  }
                   } else if (response.status === 0){ msg(vpath+': Site connection error', 'EE')
                   } else { msg(vpath + ": status="+response.status+" error="+JSON.parse(response.content).errstr, 'EE'); }
               });
                let vvv = String("select acntno, coalesce(item,'') as articleid, (beginamnt+turndbt-turncdt) as amnt, turndbt, turncdt, case when coalesce(dbtupd,'')>coalesce(cdtupd,'') then substr(dbtupd,1,16) else substr(cdtupd,1,16) end as tm "
                          +"from acnt where amnt!=0;")
                       // console.log("#24gb tranAction vacflt="+ vacflt +" vitflt="+vitflt + " vvv="+vvv); //return
                    var ojs  = JSON.parse(dbDriver.getJSONRowsFromSQL_2(vvv)).rows
                if (ojs.length) {  //
                       // msg("#j8f0qj AcntState vacnt="+vacnt)
                   Lib.postRequest(resthost+restapi+"/accounts/index.php?api_token="+resttoken, {"term":term,"reqid":"upd","shop":term,"data":ojs}, (response) => {
                    if (response.status === 200) {
                        let isPlainText = response.contentType.length === 0
                        if (isPlainText) { }
                    } else if (response.status === 0){ msg(vpath+': Site connection error', 'EE')
                    } else { msg(vpath + ": status="+response.status+" error="+JSON.parse(response.content).errstr, 'EE'); }
                   });
                }
            }
            root.cashier = {"id":param.id, "name":param.name }
            if (isNewMonth) { balancingTrade(); }

            return vid;
        }

        function doClose(param) {
            reval(param.cshr);
            dbDriver.closeShift2(param.shid)

            var dnow = new Date(param.shdate)
            var dprev = new Date(dnow.getFullYear(), dnow.getMonth()-1)
            var dnext = new Date(dnow.getFullYear(), dnow.getMonth()+1)
            let mprev = Qt.formatDate( dprev, "yyyy-MM")
            let mnow = param.shdate.substring(0,7);
            let mnext = Qt.formatDate( dnext, "yyyy-MM")
                       // console.log("#08jk prev="+ mprev+" now="+mnow + " next="+mnext)
            // trade profit from month start
            let vsql = String("select substr(dcmtime,1,7) as tm, acntcdt, p.client as cshr, sum(amount) as amnt from strgdocum as d join (select dcmid, client "
                        +"from strgdocum where dcmtype='folder' and acntcdt='rslt') as p on (d.parentid=p.dcmid) where substr(acntcdt,1,7)='rslt.35' "
                        +"and dcmtime > '%1' and dcmtime < '%2' group by acntcdt, tm, p.client;")
            var ajstmp  = JSON.parse(dbDriver.getJSONRowsFromSQL_2(vsql.arg(mnow).arg(mnext))).rows
            var ajs = []
            let i=0
            for (i=0; i< ajstmp.length; ++i){
               ajs.push({ "id": ajstmp[i].acntcdt.substring(ajstmp[i].acntcdt.indexOf("/")+1),
                        "amnt":Number(ajstmp[i].amnt).toFixed(0), "acnt": ajstmp[i].acntcdt.substring(5,9), "cshr": ajstmp[i].cshr })
            }

            // console.log("#2h7 m="+param.shdate.substring(0,7)+" str="+astr)
            let vpath = resthost+restapi+"/reports"
            if (ajs.length) {  // month report stream  -- profit
                Lib.postRequest(resthost+restapi+"/reports/index.php?api_token="+resttoken, {"term":term,"reqid":"upd", "period":mnow,"shop":term,"data":ajs}, (response) => {
                // Lib.log("#71u m="+mnow + ": status="+response.status+" str="+JSON.stringify(ajs))
                // Lib.log("#d7h "+vpath + ": status="+response.status + " content:"+response.content)
                                    if (response.status === 200) {
                    let isPlainText = response.contentType.length === 0
                    if (isPlainText) { }
                } else if (response.status === 0){ msg(vpath+': Site connection error', 'EE')
                } else { msg(vpath + ": status="+response.status+" error="+JSON.parse(response.content).errstr, 'EE'); }
                });
            }
            if (dnow.getDate() < 4){
                // console.log("#2h7 m="+param.shdate.substring(0,7)+" str="+astr)

                ajstmp  = JSON.parse(dbDriver.getJSONRowsFromSQL_2(vsql.arg(mprev).arg(mnow))).rows
                ajs = []
                for (i=0; i< ajstmp.length; ++i){
                  ajs.push({ "id": ajstmp[i].acntcdt.substring(ajstmp[i].acntcdt.indexOf("/")+1),
                           "amnt":Number(ajstmp[i].amnt).toFixed(0), "acnt": ajstmp[i].acntcdt.substring(5,9), "cshr": ajstmp[i].cshr })
                }
                if (ajs.length) {  // month report stream  -- profit
                  // console.log("#847h data="+JSON.stringify(ajs))
                    Lib.postRequest(resthost+restapi+"/reports/index.php?api_token="+resttoken, {"term":term,"reqid":"upd", "period":mprev,"shop":term,"data":ajs}, (response) => {
                    if (response.status === 200) {
                       let isPlainText = response.contentType.length === 0
                       if (isPlainText) { }
                    } else if (response.status === 0){ msg(vpath+': Site connection error', 'EE')
                    } else { msg(vpath + ": status="+response.status+" error="+JSON.parse(response.content).errstr, 'EE'); }
                    });
                }
            }
        }

        Component.onCompleted: {
            // set shift properties
            cash = acnts.cash
            trade = acnts.trade
            bulk = (acnts.bulk !== undefined ? acnts.bulk : "")
        }
    }

    Rectangle{
        id: settingsArea
        anchors{fill: parent; margins:10;}
        border{width:1; color:"LightGrey";}
        visible: false
        clip: true
        radius: 10
        color:"PowderBlue"
        Item {
            anchors{fill: parent; margins: 10;}
            // Label{ text: "DB: " + dbname; }
            Flow {
                // width: parent.width
                // anchors.centerIn: parent
                anchors.fill: parent
                spacing: 10
                RowLayout{

                    GroupBox {
                        title: qsTr("vkPOS")
                        Layout.fillWidth: true
                        ColumnLayout{
                            RowLayout { //Term code
                                spacing: 10
                                Label{
                //                    minimumPixelSize: 100
                                    text: "Term code:"
                                }
                                TextField{
                                    id: editTerm
                                    text: root.term
                                    placeholderText: "terminal code"
                                    onEditingFinished: root.term = text
                                }
                            }
                            RowLayout {
                                spacing: 10
                                Label{
                //                    minimumPixelSize: 100
                                    text: "POS printer:"
                                }
                                TextField{
                                    id: editPrinter
                                    Layout.fillWidth: true
                                    placeholderText: "POS printer"
                                    onEditingFinished: root.posPrinter = text
                                }
                            }
                            RowLayout {
                                spacing: 10
                                Label{
                //                    minimumPixelSize: 100
                                    text: "binds:"
                                }
                                TextField{
                                    id: editBinds
                                    Layout.fillWidth: true
                                    placeholderText: "check,tax,facture"
                                    onEditingFinished: root.bindList = text
                                }
                            }
                        }

                    }
                    GroupBox {
                        title: qsTr("Check")
                        Layout.fillWidth: true
                        ColumnLayout{
                            RowLayout {
                                spacing: 10
                                Label{
                //                    minimumPixelSize: 100
                                    text: "Amount:"
                                }
                                TextField{
                                    // id: editCheckAmnt
                                    text: root.checkAmnt
                                    placeholderText: "-1 | 1"
                                    onEditingFinished: root.checkAmnt = text
                                }
                            }
                            RowLayout {
                                spacing: 10
                                Label{
                                    text: "Autoprint:"
                                }
                                TextField{
                                    // id: editPrinter
                                    Layout.fillWidth: true
                                    placeholderText: "autoprint 1 | 0"
                                    onEditingFinished: root.checkAutoPrint = text
                                }
                            }
                            RowLayout {
                                spacing: 10
                                Label{
                                    text: "Print document:"
                                }
                                TextField{
                                    // id: editBinds
                                    Layout.fillWidth: true
                                    // placeholderText: ""
                                    onEditingFinished: root.checkPrintDcm = text
                                }
                            }
                        }

                    }
                }

                RowLayout{

                    GroupBox {
                        title: qsTr("Host")
                        Layout.fillWidth: true
                        ColumnLayout{
                            RowLayout {
                                spacing: 10
                                Label{ text: "host:" }
                                TextField{
                                    id: editUrl
                                    placeholderText: "host url"
                                    text: root.resthost
                                    onEditingFinished: root.resthost = text
                                }
                            }
                            RowLayout {
                                spacing: 10
                                Label{
                                    text: "api:"
                                }
                                TextField{
                                    id: editApi
                                    placeholderText: "api"
                                    text: root.restapi
                                    onEditingFinished: root.restapi = text
                                }
                            }
                            RowLayout {
                                spacing: 10
                                Label{
                //                    minimumPixelSize: 100
                                    text: "Login:"
                                }
                                TextField{
                                    id: editLogin
                                    // Layout.fillWidth: true
                                    placeholderText: "login user"
                                    text: root.restuser
                                    onEditingFinished: root.restuser = text
                                }
                            }
                            RowLayout {
                                spacing: 10
                                Label{
                                    minimumPixelSize: 100
                                    text: "password:"
                                }
                                TextField{
                                    id: editPassword
                                    // Layout.fillWidth: true
                                    echoMode: TextInput.Password
                                    placeholderText: "password"
                                    text: root.restpassword
                                    onEditingFinished: root.restpassword = text
                                }
                            }
                            RowLayout {
                                spacing: 10
                                Label{
                                    minimumPixelSize: 100
                                    text: "token:"
                                }
                                TextField{
                                    id: editToken
                                    readOnly: true
                                    placeholderText: "token"
                                    text: root.resttoken
                                }
                            }
                            Button{
                                action: actionLogin
                            }
                        }

                    }

                    GroupBox {
                        title: qsTr("Tax/cashdesk")
                        Layout.fillWidth: true
                        ColumnLayout{
                            RowLayout {
                                spacing: 10
                                Label{ text: "host:" }
                                TextField{
                                    Layout.preferredWidth: 250
                                    text: root.cdhost
                                    onEditingFinished: root.cdhost = text
                                }
                            }
                            RowLayout {
                                spacing: 10
                                Label{
                                    text: "api:"
                                }
                                TextField{
                                    text: root.cdprefix
                                    onEditingFinished: root.cdprefix = text
                                }
                            }
                            RowLayout {
                                spacing: 10
                                Label{
                                    text: "Cash:"
                                }
                                TextField{
                                    text: root.cdcash
                                    onEditingFinished: root.cdcash = text
                                }
                            }
                            RowLayout {
                                spacing: 10
                                Label{
                                    // minimumPixelSize: 100
                                    text: "Token:"
                                }
                                TextField{
                                    Layout.preferredWidth: 250
                                    text: root.cdtoken
                                    onEditingFinished: root.cdtoken = text
                                }
                            }
                        }

                    }

                    /*RowLayout{
                        Switch { text: qsTr("Allow"); }
                        ComboBox { model: ["", "+", "-"]; }
                        ComboBox { model: ["", "check", "check_knt"]; }
                        Switch { text: qsTr("Autoprint"); }
                    } */
                }
            }
        }

    }


    header: ToolBar {
        id: appToolBar
        height: 32
        Rectangle{
//            anchors.fill: parent
            width: parent.width
            height: 30
            color: stackBind.children[stackBind.currentIndex].state === "taxcheck" ? "khaki" : "transparent"
            RowLayout {
                anchors.fill: parent
    //            width: parent.width
                ToolButton {    //  ☰
                    text: "☰"
                    onClicked: naviMenu.open()
                    Menu{
                        id: naviMenu
                        y: parent.height
                        MenuItem { action: pageCheckAction; }
                        MenuItem { action: pageTaxAction; }
                        MenuItem { action: pageFactureAction; }
                        MenuItem { action: pageIncasAction; }
                        MenuItem { action: modeShiftAction; }
                        MenuSeparator { padding: 5; }
                        MenuItem { action: winDcmsAction; }
                        MenuItem { action: winClientAction; }
                        MenuItem { action: winCashWizardAction; }
                        MenuItem { action: winStatAction; }
                        MenuItem { action: winRateAction; }
                        MenuItem { action: winTaxServiceAction; }
                        MenuSeparator { padding: 5; }
                        MenuItem {
                            text: "Збалансувати дохід"
                            onClicked: { balancingTrade(); }
                        }
                        MenuSeparator {  padding: 5; }
                        MenuItem { action: modeSettingAction; }
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
                    text: stackBind.children[stackBind.currentIndex].title
                }
                Row {
                    id: btnClient
                    ToolButton{
                        text: root.crntClient.id !== ''?root.crntClient.name:""
                        icon.source: "qrc:/icon/account.svg"
//                        flat: true
                        onClicked: {
                            selectPopup.jsdata = JSON.parse(dbDriver.getJSONRowsFromSQL_2("select pkey as id, clchar as name, coalesce('tel.'||phone,'') || coalesce(' '||clnote,'')  as fullname, 0 as mask, 'Клієнти' as sect from client order by name")).rows;
                            selectPopup.open()
                        }
                    }
                    ToolButton{
                        width: 32
    //                    Layout.preferredHeight: 35
                        visible: root.crntClient.id !== ''
                        font.pointSize: 16
                        text:"⌫"
//                        flat: true
//                        icon.source:"qrc:/icon/undo.svg"
                        onClicked: {
                            setClient();
                        }
                    }
                    Label{
                        visible: Math.abs(Number(root.crntClient.bonusTotal)) >= 0.01
    //                        Layout.preferredWidth: visible?35:0
                        Layout.preferredHeight: 35
                        color:'slategray'
    //                        background: Rectangle{color:'gold'}
    //                        flat: true
                        text: Number(root.crntClient.bonusTotal).toFixed(0)
                        MouseArea{
                            anchors.fill: parent
                            onDoubleClicked: {
                                let ano = stackBind.children[stackBind.currentIndex].crntAcnt.acntno
                                stackBind.children[stackBind.currentIndex].crntAcnt = getAccount(root.crntClient.bonusAcnt);
                                new2Dcm('', {"amnt":(0 - Number(root.crntClient.bonusTotal)).toFixed(2)})
                                stackBind.children[stackBind.currentIndex].crntAcnt = getAccount(ano)
                            }

                        }

                    }
                }

                ToolButton {    // ⋮
                    text: qsTr("⋮")
                    onClicked: {
                        bindContentMenu.open()
                    }

                    Menu {
                        id: bindContentMenu
                        y: parent.height
                        // MenuItem { action: tranAction; }
                        // MenuSeparator { padding: 5; }
                        MenuItem { action: uahToAcntAction; }
                        MenuItem { action: curToAcntAction; }
                        MenuSeparator { padding: 5; }
                        MenuItem {
                            text: "Каса"
                            onClicked: drawer2Right.open();
                        }
                        MenuSeparator { padding: 5; }
                        MenuItem { action: incasBulkAction; }
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
//        msg("#84r onClosing")
        closeChildWindow()
        dbDriver.setSettingsValue("program/windowSize",String("%1,%2").arg(width).arg(height))
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
        if (resthost != undefined && resthost != "") {
            actionLogin.trigger();
        }
    }

}
