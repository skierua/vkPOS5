import QtQuick
import "../lib.js" as Lib

ListModel {
    id: root

    property real pmntTotal: 0
    property real eqTotal: 0
    property real dscMoney: 0
    property real bnsMoney: 0

    property real crntDsc: 0
    property real crntBns: 0
    property real crntRate: 1


    property real rate: 1
    onRateChanged:{
        if (rate <=0) return
        for (let r=0; r < count; ++r){
            setProperty(r,'drate', rate);
            // if (Number(bindView.model.get(r).darticle.mask) === 4) { bindView.model.setProperty(r,'drate', Number(crntRate)); }
        }
    }


    // property int dfltAmnt: 1
    property string code
    // onCodeChanged: dbg("code =" + code, "#5ga")
    property string cashno
    property string client: ""      // client id

    property string lastError: ""      //

    signal vkEvent(string id, var param)

    function dbg(str, code ="") {
        console.log( String("%1[ModelBind] %2").arg(code).arg(str));
    }

    function isCorrect(atcl, acnt, code, amnt){
        let ok = true
        ok &= (Number(atcl.mask) & Number(acnt.mask)) !== 0
        ok &= (acnt !== undefined && acnt.acntno !== "")
        ok &= (code !== "")
        ok &= (amnt !== undefined && amnt !== 0)
        // ok &= (root.code !== "taxcheck" && (atcl.mask !== "4" || code !== ""))
        return ok
    }

    function isTaxBindCorrect(){
        let ok = true
        for (var r =0; r < count && ok; ++r) {
            ok &= get(r).dcode === "trade:sell"
            ok &= get(r).darticle.mask === "4"
            ok &= get(r).dprice !== 0
        }
        return ok
    }

    function isTradeInner(){
        let ok = true
        for (var r =0; r < count && ok; ++r) {
            if (get(r).dacnt.trade === "1") continue
            ok &= get(r).dacnt.acntno.substring(0,2) === "36"
            ok &= get(r).dacnt.acntno.substring(0,4) !== "3607"
        }
        return !ok
    }

    function addDcm(db, atclid, acntno, amnt, price){
        const datcl = Lib.getArticle(db, atclid)
        const dacnt = Lib.getAccount(db, acntno)
        const damnt = Number(amnt)
        let dcode = resolveCode(datcl, dacnt, damnt)
        let ddsc = 0
        let dbns = 0

        let dprice = 0
        let dtag = ""
        let datt = 0
        if (dacnt.trade === "1") {      //{"pkey":"", "price":"0" , "offer":"0", "dsc":"0"}
            datt = 1
            if (price === undefined) {
                const jprice = Lib.getPrice(db, datcl.id, (dcode === "trade:sell" ? -1 : 1), dacnt.acntno)
                dprice = Number(jprice.price)
                if (Number(datcl.mask) === 4) {
                    datt = 7
                    if (jprice.dsc !== "0") {
                        ddsc = Number(jprice.dsc)
                        datt = 0
                        dtag = " #ЗНИЖКА!"
                    }
                    if (jprice.offer !== "0") {
                        dprice = Number(jprice.offer)
                        ddsc = 0
                        datt = 0
                        dtag = " #АКЦІЯ!"
                    }
                }

            } else dprice = price


        }

        if (!isCorrect(datcl, dacnt, dcode, damnt)){
            lastError = qsTr("Unsupported document parameters")
            return false
        }

        insert(0,
            {
                "dsign": damnt < 0 ? -1 : 1,
                "dcode": dcode,
                "darticle": datcl,
                "dacnt": dacnt,
                "damnt": Math.abs(Number(damnt)),  //String(crntAmnt),
                "dsubName":"#"+datcl.id + (Number(dacnt.trade) === 0 ? (" ["+dacnt.acntno+"/"+dacnt.note+"]") : "") + dtag,
                "dnote": datcl.name + (Number(dacnt.trade) === 0 ? (" ["+dacnt.clname+"/"+dacnt.note+"]") : "") + dtag,
                "dprice": Number(dprice),
                "ddsc": ddsc,
                "dbns": dbns,
                "dpratt": datt,
                "drate": root.rate,
                "retfor": ""
            }
        )
        // dbg(JSON.stringify(get(0)), "#8qeh")
        return true
    }

    function addRefused(db, dcmid){
        const dcms = Lib.getBindList(db, "dcmid = '" + dcmid + "'")
        if (dcms.length < 1){
            lastError = "Неможливо відкрити документ."
            return false
        }
        const datcl = Lib.getArticle(db, dcms[0].atclid)
        const dacnt = Lib.getAccount(db, dcms[0].acntcdt)
        const dcode = dcms[0].dcmtype
        const damnt = 0 - Number(dcms[0].amount)

        if (!isCorrect(datcl, dacnt, dcode, damnt)){
            lastError = qsTr("Unsupported document parameters")
            return false
        }

        const dtag = " #ПОВЕРНЕННЯ!"

        insert(0,
            {
                "dsign": damnt < 0 ? -1 : 1,
                "dcode": dcode,
                "darticle": datcl,
                "dacnt": dacnt,
                "damnt": Math.abs(Number(damnt)),  //String(crntAmnt),
                "dsubName":"#"+datcl.id + (Number(dacnt.trade) === 0 ? (" ["+dacnt.acntno+"/"+dacnt.note+"]") : "") + dtag,
                "dnote": dcms[0].dnote + dtag,
                "dprice": damnt !== 0 ? Math.abs(Number(dcms[0].eq) / damnt) : 0,
                "ddsc": Number(dcms[0].eq) !== 0 ? Math.abs(Number(dcms[0].dsc)/Number(dcms[0].eq)) : 0,
                "dbns": Number(dcms[0].eq) !== 0 ? Math.abs(Number(dcms[0].bns)/Number(dcms[0].eq)) : 0,
                "dpratt": 0,
                "drate": root.rate,
                "retfor": String(dcmid)
            }
        )
        return true
    }

    function resolveCode(atcl, acnt, amnt){
        let res = ""
        if (acnt.trade === "0") {
            res = (amnt < 0 ?  "pay:out" : "pay:in")
        } else if (acnt.trade === "1"){
            if (isTradeInner()) res = "trade:buy"
                else res = (amnt < 0 ?  "trade:sell" : "trade:buy")

            // if (root.code == "check") {
            //     if (atcl.mask === "4") { res = "trade:sell" }
            //     else if (atcl.mask === "2") {
            //         res = (amnt < 0 ?  "trade:sell" : "trade:buy")
            //     }
            // } else if (root.code == "facture") {
            //     if (atcl.mask === "4") { res = "trade:buy" }
            //     else if (atcl.mask === "2") {
            //         res = (amnt < 0 ?  "trade:sell" : "trade:buy")
            //     }
            // } else if (root.code == "taxcheck") {
            //     if (atcl.mask === "4") res = "trade:sell"
            // }
        }
        return res
    }

    function curBalanceList(){
        let res = []
        let f =0;
        for (let i =0; i < count; ++i){
            if ((Number(get(i).darticle.mask) & 2) !== 2) continue;
            f =0;
            for ( ; f < res.length && res[f].atcl.id !== get(i).darticle.id; ++f){}
            if (f === res.length) res[f] = {"atcl": get(i).darticle, "amnt": get(i).dsign * get(i).damnt}
            else res[f].amnt += get(i).dsign * get(i).damnt
        }
        if (res.length > 1) res.sort( (a,b) => {return  Number(a.atcl.note) < Number(b.atcl.note) ? -1 : 1;} )
        // dbg(JSON.stringify(res), "#73h")
        return res
    }

    function uahToAcnt(db, acnt){
        addDcm(db, "", acnt, -1 * root.pmntTotal)
        recalculate()
    }

    function curToAcnt(db, acnt){
        const tarr = curBalanceList()
        // dbg(JSON.stringify(tarr), "#7h2")
        for (let i =0; i < tarr.length; ++i)
            addDcm(db, tarr[i].atcl.id, acnt, -1 * tarr[i].amnt)
        recalculate()
    }

    function bindToJSON(client ="", dbt ="", cdt =""){
        // let ok = true
        if (client === "" && isTradeInner()) {
            for (let i =0; i < count; ++i){
                if (get(i).dacnt.trade === "1") setProperty(i,"dcode", "trade:inner")
            }
        }

        var vj = {
            "id": "dcmbind",
            "dcm": code,
            "dbt": dbt,
            "cdt": cdt,
            "amnt": root.pmntTotal.toFixed(2),
            "eq": root.eqTotal.toFixed(2),
            "dsc": root.dscMoney.toFixed(2),
            "bns": root.bnsMoney.toFixed(2),
            "note": "",
            "clnt": client,
            "tm": Qt.formatDateTime(new Date(), "yyyy-MM-dd hh:mm:ss"),
            "cshr": "",
            "dcms": []
        }
        for (var r =0; r < count; ++r) {
            vj.dcms[r] = {
                "dcm": get(r).dcode,
                "dbt": root.cashno,
                "cdt": get(r).dacnt.acntno,
                "crn": get(r).darticle.id,
                "amnt": (get(r).dsign * get(r).damnt).toFixed(get(r).darticle.prec),
                "eq": (get(r).dsign * get(r).damnt * get(r).dprice).toFixed(2),
                "dsc": (-1 * get(r).dsign * get(r).damnt * get(r).dprice * get(r).ddsc).toFixed(2),
                "bns": (-1 * get(r).dsign * get(r).damnt * get(r).dprice * get(r).dbns).toFixed(2),
                "note": get(r).dnote,
                "retfor": get(r).retfor
            }
        }
        // dbg(JSON.stringify(vj), "#-0149h")
        return vj
    }

    function tran(db, jbind){
        if (jbind === undefined) jbind = bindToJSON()
        // dbg(JSON.stringify(jbind), "#49h");
        // return 0;
        const bid = Lib.tranBind(db, jbind)
        if (!bid) {
            root.lastError = "Помилка. Дукумент не проведено."
        }
        return bid
    }

    function recalculate(){
        let v_pmnt = 0;
        let v_eq = 0;
        let v_dsc = 0;
        let v_bns = 0;
        let i = 0;
        let vtmp = '';

        for (let r =0; r < count; ++r) {
            if ( get(r).darticle.id === ''
                     || get(r).darticle.id === '980') {
                v_pmnt += get(r).damnt * get(r).dsign
            }
            vtmp = (get(r).dsign * get(r).damnt * get(r).dprice).toFixed(2)
            v_eq += Number(vtmp)
            v_dsc -= Number((Number(vtmp) * get(r).ddsc).toFixed(2))
            v_bns -= Number((Number(vtmp) * get(r).dbns).toFixed(2))
        }
//                console.log('total v_pmnt=['+v_pmnt+'] v_eq='+v_eq+' v_dsc='+v_dsc)
        root.pmntTotal = v_pmnt - (v_eq + v_dsc)
        root.eqTotal = v_eq
        root.dscMoney = v_dsc
        root.bnsMoney = v_bns

    }

    function getPriceStr(row){
        const pr = (get(row).dprice * Number(get(row).darticle.qty)/get(row).drate).toFixed((Number(get(row).darticle.mask)&2)==2 ? 3 : 2)
                                              + (Number(get(row).darticle.qty)===1?'':('/'+get(row).darticle.qty))
         return pr
    }

    function setRate(vv){
        vv = Number(vv)
        if (vv <=0) return
        root.crntRate = vv
        for (let r=0; r < count; ++r){
            setProperty(r,'drate', vv);
        }
        recalculate()
    }

    function setDsc(vv){
        vv = Number(vv) / 100
        root.crntDsc = vv
        for (let r=0; r < count; ++r){
            if ((get(r).dpratt & 2) != 2) continue;
            setProperty(r,'ddsc', vv);
        }
        recalculate()
    }

    function setBns(vv){
        vv = Number(vv) / 100
        root.crntBns = vv
        for (let r=0; r < count; ++r){
            if ((get(r).dpratt & 4) != 4) continue;
            setProperty(r,'dbns', vv);
        }
        recalculate()
    }

}

/* structures
  create(vdcm, vrow) IN vdcm
  {
    "price":41.63,
    "dsc":0,
    "bns":0,
    "tag":"",
    "retfor":"",
    "atcl":{"id":"840","name":"USD","fullname":"долар США","mask":"2","qty":"1","scan":"","uktzed":"","taxchar":"","taxprc":"","unitid":"","prec":"2","unitchar":"","unitname":"","unitcode":"","term":"0"},
    "acnt":{"acntno":"3500","clid":"","clname":"","note":"Торгівля","mask":"14","clnote":"","trade":"1","name":"Торгівля"},
    "amnt":"-1",
    "code":"trade:sell",
    "pratt":7
  }

  create(vdcm, vrow) OUT vdcm at vrow
  {
    "dsign":-1,
    "dcode":"trade:sell",
    "darticle":{"fullname":"долар США","id":"840","mask":"2","name":"USD","prec":"2","qty":"1","scan":"","taxchar":"","taxprc":"","term":"0","uktzed":"","unitchar":"","unitcode":"","unitid":"","unitname":""},
    "dacnt":{"acntno":"3500","clid":"","clname":"","clnote":"","mask":"14","name":"Торгівля","note":"Торгівля","trade":"1"},
    "damnt":"1",
    "dsubName":"#840",
    "dnote":"USD",
    "dprice":41.63,
    "ddsc":0,
    "dbns":0,
    "dpratt":1,
    "drate":"1",
    "retfor":""
  }

*/
