.pragma library
/**
  JS library
*/

function version() { return "1.5*";}

const glBonusPrefix = "3800";
const glDomesticCrn = "980";

function log(vstring, vmodule, vtype) {
    if (vtype === undefined) { vtype = 'II'}
    if (vmodule === undefined) { vmodule = '???main.qml'}
    console.log(String("%1[%2]: %3").arg(vtype).arg(vmodule).arg(vstring))
}

function ttest(db){ // clear duccent data
  let ok = db.dbDelete("delete from documtran;")
  ok &= db.dbDelete("delete from docum;")
  ok &= db.dbDelete("DELETE from acnt where item='980';")
  ok &= db.dbUpdate("update acnt set beginamnt=0, turncdt=0, turndbt=0;")
  return (ok ? "II: (lib.ttest) DB cleared" : "EE: (lib.ttest) DB clearing ERROR");
  // return Qt.formatDateTime(new Date(), "yyyy-MM-dd hh:mm");
}

function parse(raw){
    try {
        return JSON.parse(raw);
    } catch (err) {
        return false;
    }
}

function sortCoef(vcrn) {
    if (vcrn === '' || vcrn === 'UAH' || vcrn === 'ГРН') { return '' }
    else if (vcrn === 'USD') {return '005'}
    else if (vcrn === 'EUR') {return '010'}
    else if (vcrn === 'PLN') {return '015'}
    else if (vcrn === 'RUB') {return '020'}
    else if (vcrn === 'GBP') {return '025'}
    else if (vcrn === 'CAD') {return '030'}
    else if (vcrn === 'CZK') {return '035'}
    else if (vcrn === 'AUD') {return '040'}
    else if (vcrn === 'CHF') {return '045'}
    else if (vcrn === 'SEK') {return '050'}
    else if (vcrn === 'HUF') {return '055'}
    else if (vcrn === 'EURUSD') {return '070'}
    else if (vcrn === 'USDPLN') {return '075'}
    else if (vcrn === 'LITO') {return '100'}
    else if (vcrn === 'ELSV') {return '110'}
    else if (vcrn === 'KHRV') {return '120'}
    else if (vcrn === 'DOBR') {return '130'}
    else if (vcrn === 'KNMAIN') {return '140'}
    else if (vcrn === 'SHELS1') {return '200'}
    else if (vcrn === 'SHELS2') {return '210'}
    else if (vcrn === 'offer') {return '500'}
    return '999'
}

function humanDate(vdate) {
    var vtmp = Date()
    var vdiff = Math.floor(((new Date().getTime())-(new Date(String(vdate).substring(0,10)).getTime()))/(1000*60*60*24))
    if (vdiff === 0) { return vdate.substring(11,16) // Qt.formatDate(new Date(vdate), 'hh:mm')
    } else if (vdiff === 1) { return 'вч '+vdate.substring(11,16)  //Qt.formatDate(new Date(vdate), 'вч hh:mm')
    // } else if (vdiff < 8) { return Math.floor(((new Date().getTime())-(new Date(String(vdate).substring(0,10)).getTime()))/(1000*60*60*24))+' дн.'
    } else if (vdiff < 360) { return Qt.formatDate(new Date(vdate), 'dd MMM')
    } else { return Qt.formatDate(new Date(vdate), 'MMM yy'); /*String(vdate).substring(0,10);*/ }

}


function crntShift(db){
    // let shft = db.getJSONRowFromSQL("select id, shftdate, coalesce(shftbegin,'') shftbegin, coalesce(shftend,'') shftend, cshr, coalesce(cashier.note,'') as cshrname from shift left join cashier on(cshr=code) order by id desc limit 1;")
    const jdata = parse(db.dbSelectRows("select id, shftdate, coalesce(shftbegin,'') shftbegin, coalesce(shftend,'') shftend, cshr, coalesce(cashier.note,'') as cshrname from shift left join cashier on(cshr=code) order by id desc limit 1;"))
  // Lib.log("#w34 shft id="+ JSON.stringify(shft) )
    // if (shft.errid === 0) { return shft; }
    return (jdata && jdata.rows.length) ? jdata.rows[0] : { "id":0,"errid":1,"errname":"","shftdate":"","shftbegin":"","shftend":"","cshr":"","cshrname":""}
}

function findText(db, vtext, mask, callback) {
    // if (vtext === undefined || vtext ===""){
    //     // new2Dcm("");
    //     return;
    // }
    let res=null, err=null;
    let sql = ""
    var vartjs = ({})
    if(isNaN(vtext)) {
        sql = "select pkey as id, clchar as name, coalesce('tel.'||phone,'') || coalesce(' '||clnote,'')  as fullname, '' as scancode, 0 as mask, 'Клієнти' as sect from client ";
        sql += "union select item.pkey as id, itemchar as name, coalesce(itemname, itemnote,'') as fullname, coalesce(scancode,'') as scancode, itemmask as mask, '' as sect from item ";
        sql += "where folder = 0 and itemmask&"+mask;
        vartjs = parse(db.dbSelectRows(sql,String(vtext)));
        if (vartjs.rows.length === 0) {
            callback({code:'Info', text:'Main/bind\nНічого не знайдено'},res)
            return
        }
        res = vartjs.rows
    } else {
        let ok = true;
        if (vtext.length < 4) {
            sql = "select item.pkey as id, itemchar as name, coalesce(itemname, itemnote,'') as fullname, itemmask as mask, '' as sect from item "

            sql += "where folder = 0 and (itemmask=2) and substr(cast(item.pkey as string),1,"+vtext.length+")='"+vtext+"'";
            vartjs = parse(db.dbSelectRows(sql));
            ok &= ok && vartjs && vartjs.rowCount === 0;
        }
        if (ok) {
            sql = "select pkey as id, clchar as name, coalesce('tel.'||phone,'') || coalesce(' '||clnote,'')  as fullname, 0 as mask, 'Клієнти' as sect from client ";
            sql += "where id='"+vtext+"';"
            vartjs = parse(db.dbSelectRows(sql));
            ok &= ok && vartjs && vartjs.rowCount === 0;
        }
        if (ok) {
            sql = "select item.pkey as id, itemchar as name, coalesce(itemname, itemnote,'') as fullname, itemmask as mask, '' as sect from item ";
            sql += "where item.pkey='"+vtext+"' and (itemmask&6) and folder = 0;";
            vartjs = parse(db.dbSelectRows(sql));
            ok &= ok && vartjs && vartjs.rowCount === 0;
        }

        if (ok) {
            sql = "select item.pkey as id, itemchar as name, coalesce(itemname, itemnote,'') as fullname, itemmask as mask, '' as sect from item ";
            sql += "where folder = 0 and (substr(cast(item.pkey as string),1,"+vtext.length+")='"+vtext+"' or (itemmask&"+mask+") and scancode like '%"+vtext+"%') order by pkey;";
            vartjs = parse(db.dbSelectRows(sql));
            ok &= ok && vartjs && vartjs.rowCount === 0;
        }

        if (vartjs.rowCount === 0) {
            callback({code:'Info', text:'Main/bind\nНічого не знайдено'},res)
            return
        }
        res = vartjs.rows
    }
    callback(err, res)
}

function getSQLData(db, vsql) {
    // console.log("#dr3 sql="+vsql+filt)
    var jdata = parse(db.dbSelectRows(vsql));
    if (jdata){ return jdata.rows; }
    // console.log("#235 article="+JSON.stringify(ret))
    return [];
}


function getIncas(db) {
    // console.log("#dr3 sql="+vsql+filt)
    const vsql = String("select acnt.id tid,acnt.acntno tno, acnt.item as curid, itemchar as cur, eq.id eid, eq.acntno eno,'rslt.'||acntrade.acntno||'/'|| acntrade.article as rno, "
                        +"bscprice, qtty as qty, price, 0-(acnt.beginamnt+acnt.turndbt-acnt.turncdt) amnt, (acnt.beginamnt+acnt.turndbt-acnt.turncdt) incas, (eq.beginamnt+eq.turndbt-eq.turncdt) as eqamnt, "
                        +"round(0-(acnt.beginamnt+acnt.turndbt-acnt.turncdt) * bscprice - (eq.beginamnt+eq.turndbt-eq.turncdt),2) as profit "
                        +"from  acntrade join acnt on (acntrade.pkey = acnt.id) left join price using(item) join item on (acnt.item=item.pkey) join acnt as eq "
                        +"on (('eqvl.'||acntrade.acntno||'/'||acntrade.article) = eq.acntno) where substr(acnt.acntno,1,4)='3500' and prbidask=1 and itemmask=2 AND amnt!=0 AND eqamnt!=0 "
                        +"order by acnt.acntno,itemnote;")
    const jdata = parse(db.dbSelectRows(vsql));
    // console.log("#235 article="+JSON.stringify(jdata.rows))
    if (jdata){ return jdata.rows; }
    return [];
}

function getAccount(db, vno) {
    let vsql = "select acntno, coalesce(pkey,'') as clid, coalesce(clchar, '') as clname, coalesce(acntnote,balname,'') as note, mask, clnote, acntbal.trade as trade, balname as name "
    vsql += "from acntbal left join client on (pkey=client) left join balname on (substr(acntno,1,2)=bal) ";
    let ret = { "acntno":"", "clid":"", "clname":"", "note":"", "mask":"", "clnote":"", "trade":"", "name":"" };
    var jdata = ({})
    vsql += ((vno === undefined || vno === '')
                 ? (" where acntbal.trade=1 and mask!=0 order by acntno")
                 : (" where acntno='"+vno+"' order by acntno"))
    jdata = parse(db.dbSelectRows(vsql));
    // log("no="+(vno || '')+"  "+JSON.stringify(jdata))
    return (jdata && jdata.rows.length) ? jdata.rows[0] : { "acntno":"", "clid":"", "clname":"", "note":"", "mask":"", "clnote":"", "trade":"", "name":"" };
}


function getAcntList(db, cashno, clid='', mode=''){
    let sql = ""
    if (mode !== "incas") {
        let flt = (clid === undefined || clid === '') ?
                     "where cl = '' and acntbal.trade = 0 and mask!=0 and acntno != 'rslt' and acntno != '"+cashno+"' and substr(acntno,1,4)!='3800'"
                     : "where cl = '"+clid+"' and acntbal.trade = 0 and mask!=0 and acntno != 'rslt' and acntno != '"+cashno+"'";
        sql = "select acntno as id, coalesce(acntnote,balname,'') as name, coalesce(clchar, '') as fullname, '' as scancode, '128' as mask, 'Рахунки' as sect, acntbal.trade, coalesce(pkey,'') as cl "
        sql += " from acntbal left join client on (pkey=client) left join balname on (substr(acntno,1,2)=bal) where acntbal.trade and acntbal.mask!=0 "
        sql += "union select acntno as id, coalesce(acntnote,balname,'') as name, coalesce(clchar, '') as fullname, '' as scancode, '128' as mask, 'Рахунки' as sect, acntbal.trade, coalesce(pkey,'') as cl  "
        sql += "from acntbal left join client on (pkey=client) left join balname on (substr(acntno,1,2)=bal) " + flt + " order by acntbal.trade desc, acntno";
    } else {
        sql = "select acntno as id, coalesce(acntnote,balname,'') as name, coalesce(clchar, '') as fullname, '' as scancode, '128' as mask, 'Рахунки' as sect, acntbal.trade, coalesce(pkey,'') as cl "
        sql += " from acntbal left join client on (pkey=client) left join balname on (substr(acntno,1,2)=bal) where (acntbal.trade or substr(acntno,1,4)='3003') and acntbal.mask!=0 order by acntbal.trade desc, acntno"
    }
    let jdata = parse(db.dbSelectRows(sql));
    return (jdata && jdata.rows.length) ? jdata.rows : [];
}

function getAcntSettings(db) {
  // const jdata = parse(db.dbSelectRows("select acnts from settings limit 1;"))
    var va = db.dbSelectRow("select acnts from settings limit 1;")
    // // Lib.log('#92uj acnts='+JSON.stringify(va))
    if (!va.errid){
    //     // Lib.log('#671g acnts='+va.acnts)
        const aa = parse(va.acnts)
        if(aa) {
            return aa;/* Lib.log('#671g acnts='+JSON.stringify(root.acnts));*/}
        else {
            log('JSON.parse error acnt=' + JSON.stringify(va),'lib getAcntSettings', 'EE');
        }
    }
    return { "cash":"3000", "incas":"3003ELSV", "trade":"3500", "bulk":"3501", "profit":"3607-55" };
  // log("getAcntSettings 199 " + JSON.parse(jdata.rows[0].acnts))
    // return (jdata && jdata.rows.length) ? jdata.rows[0].acnts : { "cash":"3000", "incas":"3003ELSV", "trade":"3500", "bulk":"3501", "profit":"3607-55" };
}


// select item.pkey as id, itemchar/name, itemname/fullname, itemmask mask, coalesce(qty,1) as qty, coalesce(scancode,'') as scan, coalesce(unitprec,2) as prec "
// +"from item left join itemunit on (defunit=itemunit.pkey) left join articlepriceqty using(pkey) where folder=0;
function getArticle(db, vaid) {
    var jdata = ({})
    const vsql = "select item.pkey as id, itemchar as name, coalesce(itemname, itemnote,'') as fullname, itemmask as mask, coalesce(qty,1) as qty, coalesce(scancode,'') as scan, uktzed, taxchar, taxprc, "
    +" coalesce(defunit,'') as unitid ,coalesce(unitprec,2) as prec, coalesce(unitchar,'') as unitchar, coalesce(unitname,'') as unitname, coalesce(code,'') as unitcode, "
    +" coalesce(term,0) as term from item left join itemunit on(defunit=itemunit.pkey) left join articlepriceqty on (item.pkey=articlepriceqty.pkey) left join warranty on (item.pkey=article) ";
    let ret = {"id":"", "name":"", "fullname":"", "mask":"", "qty":"1", "scan":"", "uktzed":"", "taxchar":"","taxprc":"",
    "unitid":"", "prec":"0", "unitchar":"", "unitname":"", "unitcode":"", "term":"" };
    let filt = " where mask='1'"
    if (vaid !== undefined && vaid !== ''){
        filt = " where id='"+vaid+"'"
    }
    // console.log("#ueh9 sql="+vsql+filt)
    jdata = parse(db.dbSelectRows(vsql+filt));
    if (jdata){
        if (jdata.rows.length){
            ret = jdata.rows[0];
            if (vaid === undefined || vaid === '' || vaid === glDomesticCrn){
                ret.id = ''
            }
        }
    }
    // console.log("#16q article="+JSON.stringify(ret))
    return ret;
}

// almost same as getArticle
function getArticles(db, vaid = "") {
    let jdata = ({})
    const vsql = "select item.pkey as id, itemchar as name, coalesce(itemname, itemnote,'') as fullname, itemmask as mask, coalesce(qty,1) as qty, coalesce(scancode,'') as scan, uktzed, taxchar, taxprc, "
    +" coalesce(defunit,'') as unitid ,coalesce(unitprec,2) as prec, coalesce(unitchar,'') as unitchar, coalesce(unitname,'') as unitname, coalesce(code,'') as unitcode, "
    +" coalesce(term,0) as term from item left join itemunit on(defunit=itemunit.pkey) left join articlepriceqty on (item.pkey=articlepriceqty.pkey) left join warranty on (item.pkey=article) ";
    let ret = {"id":"", "name":"", "fullname":"", "mask":"", "qty":"1", "scan":"", "uktzed":"", "taxchar":"","taxprc":"",
    "unitid":"", "prec":"0", "unitchar":"", "unitname":"", "unitcode":"", "term":"" };
    let filt = ""
    if (vaid !== undefined && vaid !== ''){
        filt = " where id='"+vaid+"'"
    }
    // console.log("#ueh9 sql="+vsql+filt)
    jdata = parse(db.dbSelectRows(vsql+filt));
    // console.log("#16q article="+JSON.stringify(jdata.rows))
    return (jdata && jdata.rows.length) ? jdata.rows : [];
}

// similar to getAccount
function getBalAccounts(db, bal) {
  let vsql = "select acntno, coalesce(client,'') clid, coalesce(clchar,'') clname, coalesce(acntnote,'') note, mask, trade from acntbal left join client on acntbal.client=client.pkey %1 order by acntno"
  let flt = "";
    // let ret = { "acntno":"", "clid":"", "clname":"", "note":"", "mask":"", "trade":"" };
    var jdata = ({})
  if (bal !== undefined && bal !== ''){
    flt = String(" where substr(acntno,1,%1)='%2'").arg(bal.length).arg(bal)
  }
  vsql = vsql.arg(flt);
  jdata = parse(db.dbSelectRows(vsql));
  // log("no="+(bal || '')+"  "+JSON.stringify(jdata))
  return (jdata && jdata.rows.length) ? jdata.rows : [];
}

// only bind rows from table
function getBindList(db, flt=""){
  const vsql = "select shftid, id as dcmid, coalesce(dcmno,'') dcmno, dcmtype, coalesce(item,'') atclid, acntdbt, acntcdt, amount, eqamount eq, discount dsc, "
            + " bonus bns, coalesce(client,'') clid, coalesce(parentid,'') pid, coalesce(dcmnote,'') dnote, dcmtime dtm, coalesce(clchar, '') clchar "
            + " from documall left join client on(clid = pkey) " + (flt==="" ? "" : ( "where "+flt)) + " order by id DESC;";
  // log("#82 lib.getBindList vsql=" + vsql)
    const vj = parse(db.dbSelectRows(vsql));
    if (!vj){
        log('getDcmList #823y JSON.parse error sql='+ vsql);
        return [];
    }
    return vj.rows;
}

function getClient(db,vid){
    // log("getClient vid="+vid)
    let ret = {'id':'', 'name':'', "bonusTotal": 0, "bonusAcnt":''};
    if (vid !== undefined && vid !== "" && vid !== 0){
        let vsql = "select pkey as id, clchar as name, coalesce('tel.'||phone,'') || coalesce(' '||clnote,'')  as fullname, coalesce(a.acntno,'') as bonusAcnt, coalesce(a.total,0) as bonusTotal ";
        vsql += "from client left join (select acntno, client as pkey, (0-(beginamnt+turndbt-turncdt)) as total from acntbal join acnt using(acntno) where item is null and substr(acntno,1,4)='3800') as a using (pkey) ";
        vsql += "where id = '" + vid + "'";
        const vj = parse(db.dbSelectRows(vsql));
        if (!vj){log('getClient #25fa JSON.parse error'); return false; }
        if (vj.rows.length){
            ret = vj.rows[0];
        }
    }
//        msg("#dj3 cl="+JSON.stringify(ret))
    return ret;
}

function getClientList(db){
    const vsql = "select pkey as id, clchar as name, coalesce('tel.'||phone,'') || coalesce(' '||clnote,'')  as fullname, coalesce(phone,'') as phone, coalesce(clnote,'') as clnote, 0 as mask, 'Клієнти' as sect from client order by name";
    const vj = parse(db.dbSelectRows(vsql));
    if (!vj){
        log('getClient #25fa JSON.parse error');
        return [];
    }
    return vj.rows;
}


function getCurrency(db, id){
    const flt = (id === undefined || id === '') ? '': String(" and curid='%1'").arg(id);

    let vsql = String("select pkey as curid, itemchar as curchar, itemname as curname, coalesce(qty,1) as qty,  itemnote as so from item left join articlepriceqty using(pkey) "
            + " where %1 folder = 0  and itemmask = 2 and itemnote!='' and itemnote is not null order by itemnote;").arg(flt);
    const vj = parse(db.dbSelectRows(vsql));
    if (!vj){
        log('getClient #25fa error');
        return [];
    }
    return vj.rows;
}

function getDcmList(db, flt=""){
  const vsql = "select shftid, id as dcmid, coalesce(dcmno,'') dcmno, dcmtype, coalesce(item,'') atclid, acntdbt, trade, acntcdt, amount, eqamount eq, discount dsc, bonus bns, coalesce(acntbal.client,'') clid, "
  + " coalesce(parentid,'') pid, coalesce(dcmnote,'') dnote, dcmtime dtm, coalesce(clchar, '') clchar, coalesce(iname,'UAH') iname, coalesce(ifname,'українська гривня') ifname, coalesce(scancode,'') scan, "
  + " coalesce(imask,1) imask, coalesce(qty,1) qty, coalesce(unitprec,2) prec from documall LEFT join acntbal on(acntcdt = acntno) left join client on(acntbal.client = pkey) LEFT join "
  + " (select item.pkey aid, itemchar iname, itemname ifname, scancode, itemmask imask, unitprec, qty from item  left join articlepriceqty on(item.pkey=articlepriceqty.pkey) LEFT join itemunit on (defunit=itemunit.pkey) where folder=0) atcl on (item = atcl.aid) "
       + (flt==="" ? "" : ( "where "+flt)) + " order by pid DESC;";
    const vj = parse(db.dbSelectRows(vsql));
    if (!vj){
        log('getDcmList #823y JSON.parse error sql='+ vsql);
        return [];
    }
    return vj.rows;
}

function getRate(db, id){
    const flt = (id === undefined || id === '') ? '': String("item='%1' AND ").arg(id);

    let vsql = String("select id, item curid, prbidask ba, qtty qty, price "
                      +" from price join item on(item=pkey) where %1 (prtype is null or prtype='') and itemmask = 2 and itemnote!='' and itemnote is not null ;").arg(flt);
    const vj = parse(db.dbSelectRows(vsql));
    if (!vj){
        log('getRate #7dy error');
        return [];
    }
    return vj.rows;
}

function openConnection(db, vname, vdriver){
    if (vdriver === undefined) { vdriver = 'QSQLITE'}
    db.clearSqlData()
    // Lib.log("#625a db="+vname)
    db.setDbParameter(vname,vdriver)
    return
    // set root acnts
}

function acnt_id(db, acnt, article = ""){
  const vsql = String("select id acid, 0 eqid, 0 rsid from acnt where acntno = '%1' and %2")
  .arg(acnt).arg(article === "" ? "(item IS NULL or item='' )" : ("item = '"+article+"'"))
  let res =  db.dbSelectRow(vsql)
  if (res.errid !== 0 || res.acid === 0){
    db.dbInsert(String("insert into acnt (acntno, item) values ('%1', %2)").arg(acnt).arg(article === "" ? "null" : String("'%1'").arg(article)))
    res =  db.dbSelectRow(vsql)
  }
  if (res.errid !== 0 && res.acid === 0){
    res.errid = 1;
    res.errname = qsTr("Missing account")
  }
  return res;
}

function acntTrade_id(db, acnt, article = ""){
  let res = ({})
  if (article === ""){
    res.errid = 1;
    res.errname = qsTr("Wrong article code")
  }

  const vsql = String("select id acid, coalesce(eqid,0) eqid, coalesce(rsltid,0) rsid from acnt left join acntrade on(id=pkey) where acnt.acntno = '%1' and %2")
  .arg(acnt).arg(article === "" ? "(item IS NULL or item='' )" : ("item = '"+article+"'"))
  res =  db.dbSelectRow(vsql)
  if (res.errid !== 0 || res.acid === 0){
    db.dbInsert(String("insert into acntrade (pkey, acntno, article) values ((select max(id)+1 from acnt), '%1', '%2')").arg(acnt).arg(article))
    res =  db.dbSelectRow(vsql)
  }
  if (res.errid !== 0 && res.acid === 0){
    res.errid = 1;
    res.errname = qsTr("Missing account")
  }

  return res;
}

function tranBind(db, jbind) {
    let pid = 0;
    // Lib.log("#94j bind="+JSON.stringify(jbind)); //return;
    // let tbId = db.dbBindTranFromJSON( jbind );

  let vlog = ""
  let r =0
  let dbtid = ({})
  let cdtid = ({})
  let bnsid = {"errid":1, "errname":"invalid"};   // BONUS acnt id
  // cdtid = acnt_id(db, jbind.dcms[r].cdt, "000")
  // console.log(JSON.stringify(cdtid) + "\n" + JSON.stringify(cdtid),"\n")

  // check client BONUS account if nessesary
  let ok = false;
  for (r = 0; r < jbind.dcms.length; ++r){
    ok |= (Number(jbind.dcms[r].bns) !== 0)
  }
  ok &= (jbind.clnt !== "")
  if (ok) {
    let balacnt = db.dbSelectRow(String("select acntno, client, mask from acntbal where acntno='%1' and client = '%2'")
                                 .arg(glBonusPrefix + jbind.clnt).arg(jbind.clnt))
    if (balacnt.errid !== 0) {
      db.dbInsert(String("insert into acntbal (acntno, client, mask) values('%1', '%2', %3)").arg(glBonusPrefix + jbind.clnt).arg(jbind.clnt).arg(1))
    }
    bnsid = acnt_id(db, glBonusPrefix + jbind.clnt)
  }

  // tran dcms scheduler
  for (r = 0; r < jbind.dcms.length; ++r){
    jbind.dcms[r].tran = []
    dbtid = acnt_id(db, jbind.dcms[r].dbt, jbind.dcms[r].crn)
// console.log(jbind.dcms[r].dcm.substring(0,6))

    // for TRADE
    if (jbind.dcms[r].dcm.substring(0,6) === "trade:"){
      cdtid = acntTrade_id(db, jbind.dcms[r].cdt, jbind.dcms[r].crn)
      if (dbtid.errid === 0 && cdtid.errid === 0){
        jbind.dcms[r].tran.push({"amount":jbind.dcms[r].amnt, "dbtid": dbtid.acid, "cdtid": cdtid.acid})
      }
      dbtid = acnt_id(db, jbind.dcms[r].dbt)
      if (dbtid.errid === 0 &&  dbtid.acid !== 0 && cdtid.eqid !== 0){
        jbind.dcms[r].tran.push({"amount":jbind.dcms[r].eq, "dbtid": cdtid.eqid, "cdtid": dbtid.acid})
        // for DISCOUNT
        if (Number(jbind.dcms[r].dsc) !== 0){
          jbind.dcms[r].tran.push({"amount":jbind.dcms[r].dsc, "dbtid": cdtid.eqid, "cdtid": dbtid.acid})
        }
      }
      // for BONUS
      if (bnsid.errid === 0 && Number(jbind.dcms[r].bns) !== 0) {
        dbtid = acnt_id(db, glBonusPrefix + jbind.clnt)
        if (dbtid.errid === 0 && dbtid.acid !== 0 && cdtid.eqid !== 0){
          jbind.dcms[r].tran.push({"amount":jbind.dcms[r].bns, "dbtid": cdtid.eqid, "cdtid": dbtid.acid})
        }
      }

      // update basic rates/prices
      if (jbind.dcms[r].dcm === "trade:buy" && Number(jbind.dcms[r].amnt) > 0){
        db.dbUpdate(String("update acntrade set lastpricebuy = %1 where acntno = '%2' and article = '%3'")
                    .arg(Math.abs((Number(jbind.dcms[r].eq) + Number(jbind.dcms[r].dsc))/Number(jbind.dcms[r].amnt)))
                    .arg(jbind.dcms[r].cdt)
                    .arg(jbind.dcms[r].crn))
      } else if (jbind.dcms[r].dcm === "trade:sell" && Number(jbind.dcms[r].amnt) < 0){
          db.dbUpdate(String("update acntrade set lastpricesell = %1 where acntno = '%2' and article = '%3'")
                      .arg(Math.abs((Number(jbind.dcms[r].eq) + Number(jbind.dcms[r].dsc))/Number(jbind.dcms[r].amnt)))
                      .arg(jbind.dcms[r].cdt)
                      .arg(jbind.dcms[r].crn))
      }
    } else {  // NON TRADE
      cdtid = acnt_id(db, jbind.dcms[r].cdt, jbind.dcms[r].crn)
      if (dbtid.errid === 0 && cdtid.errid === 0){
        jbind.dcms[r].tran.push({"amount":jbind.dcms[r].amnt, "dbtid": dbtid.acid, "cdtid": cdtid.acid})
      }
    }

    // vlog += JSON.stringify(dbtid) + "\n" + JSON.stringify(cdtid) +"\n"
  }

  let vqry = String("insert into docum (dcmtype, acntdbt, amount, eqamount, discount, bonus, dcmstate, acntcdt, dcmnote, client) "
                    + " values ('%1', '%2', %3, %4, %5, %6, 1, '%7', null, %8); ")
          .arg(jbind.dcm)
          .arg(jbind.dbt)
          .arg(jbind.amnt)
          .arg(jbind.eq)
          .arg(jbind.dsc)
          .arg(jbind.bns)
          .arg(jbind.cdt)
          .arg(jbind.clnt === "" ? "null" : jbind.clnt)
          ;
  // vlog += vqry +"\n"
  // const pid = 0;  // bind/parent id
  ok = true
  let did = 0;    // dcm id
  let tid = 0;    // transaction id
  pid = db.dbInsert(vqry);
  ok &= (pid != 0);

  for (r = 0; r < jbind.dcms.length; ++r){
    vqry = String("insert into docum (dcmtype, acntdbt, amount, eqamount, discount, bonus, dcmstate, acntcdt, dcmnote, item, parentid, retfor) "
                  + " values ('%1', '%2', %3, %4, %5, %6, 1, '%7', '%8', %9, %10, %11); ")
      .arg(jbind.dcms[r].dcm)
      .arg(jbind.dcms[r].dbt)
      .arg(jbind.dcms[r].amnt)
      .arg(jbind.dcms[r].eq)
      .arg(jbind.dcms[r].dsc)
      .arg(jbind.dcms[r].bns)
      .arg(jbind.dcms[r].cdt)
      .arg(jbind.dcms[r].note)
      .arg(jbind.dcms[r].crn === "" ? "null" : String("'" + jbind.dcms[r].crn + "'") )
      .arg(pid)
      .arg(jbind.dcms[r].retfor === "" ? "null" : jbind.dcms[r].retfor )
    ;
    did = db.dbInsert(vqry);
    ok &= (did != 0);
    // vlog += "\n" + vqry
    if (did != 0) {
      for (let j = 0; j < jbind.dcms[r].tran.length; ++j) {
        vqry = String("insert into documtran (dcmid, amount, dbtid, cdtid) values(%1, %2, %3, %4); ")
        .arg(did).arg(jbind.dcms[r].tran[j].amount).arg(jbind.dcms[r].tran[j].dbtid).arg(jbind.dcms[r].tran[j].cdtid)
        // vlog += "\n" + vqry
        tid = db.dbInsert(vqry);
        ok &= (tid != 0);
      }
    }


  }
  // console.log("#94yb SUSPENDED tranAction vlog="+vlog+"\n jbind="+JSON.stringify(jbind));

  return pid;
}



function uploadAcnt(db, updated) {
    let sql = "select acntno, coalesce(item,'') as articleid, (beginamnt+turndbt-turncdt) as amnt, turndbt, turncdt, case when coalesce(dbtupd,'')>coalesce(cdtupd,'') then substr(dbtupd,1,16) else substr(cdtupd,1,16) end as tm "
        + String("from acnt where %1;").arg( updated ? "datetime(tm)>datetime('now','-00:10')" : "amnt!=0" );
    return parse(db.dbSelectRows(sql))
}

function uploadReport(db, ifrom, ito/*, rest*/) {
    let vsql = String("select substr(dcmtime,1,7) as tm, acntcdt, p.client as cshr, sum(amount) as amnt from strgdocum as d join (select dcmid, client "
                +"from strgdocum where dcmtype='folder' and acntcdt='rslt') as p on (d.parentid=p.dcmid) where substr(acntcdt,1,7)='rslt.35' "
                +"and dcmtime > '%1' and dcmtime < '%2' group by acntcdt, tm, p.client;")
    var ajs = []
    // log("#62g lib "+vsql.arg(ifrom).arg(ito))
    var js  = parse(db.dbSelectRows(vsql.arg(ifrom).arg(ito)))
    if (!js) {    // error or nothing to do
        return false
    }
    for (let i=0; i< js.rows.length; ++i){
       ajs.push({ "id": js.rows[i].acntcdt.substring(js.rows[i].acntcdt.indexOf("/")+1),
                "amnt":Number(js.rows[i].amnt).toFixed(0), "acnt": js.rows[i].acntcdt.substring(5,9), "cshr": js.rows[i].cshr })
    }
    return ajs;
}


function makeBind_balancingTrade(db, acnts){
    let r =0;
    let total = 0;
    var vj;
    // var jsrow;
    // for testing only START !!!
    // jsrow = [{"acntno":"rslt.3500/840","amnt":"55.11"},{"acntno":"rslt.3500/978","amnt":"-66.2"}]
    // for testing only FINISH !!!

    const jsrow = parse(db.dbSelectRows("select acntno, beginamnt+turndbt-turncdt as amnt from acnt where substr(acntno,1,4)='rslt' and amnt!=0;"))
    // if (!jsrow){ log('balancingTrade #32gt JSON.parse error','lib balancingTrade', 'EE' ); return; }
    // if (!jsrow.rows.length) { log('balancingTrade #1e2 Nothing to do','lib balancingTrade', 'II' ); return; }

    vj = {"id":"dcmbind","dcm":"folder","dbt":"profit","cdt":"blnc","amnt":"0","eq":"0","dsc":"0","bns":"0","note":"rslt>profit", "clnt":"","cshr":"", "dcms":[]}
    total = 0
    for (r =0; r < jsrow.rows.length; ++r) {
        total += Number(jsrow.rows[r].amnt)
        vj.dcms.push({"dcm":"memo","dbt":acnts.cash,"cdt":jsrow.rows[r].acntno,"crn":"","amnt":Number(jsrow.rows[r].amnt).toFixed(2),"eq":"0","dsc":"0","bns":"0","note":"","retfor":""})
        vj.dcms.push({"dcm":"memo","dbt":acnts.cash,"cdt":acnts.profit,"crn":"",
            "amnt":((0-Number(jsrow.rows[r].amnt)).toFixed(2)),"eq":"0","dsc":"0","bns":"0","note":"","retfor":""})
    }
    vj.amnt = total.toFixed(2)
    vj.eq = (0-total).toFixed(2)

    return vj;
}

function makeBind_reval(db, cshr ){
  var ret = []
    let ok = true;
    let r=0, prf = 0;
    let vsql = ""
    vsql = String("select item as curid, case when qtty=1 then price else price/qtty end as rate from  price where price!=0 and prbidask=1 and (prtype='' or prtype is null);")
    var vdata = JSON.parse(db.dbSelectRows(vsql));
    if (!vdata || vdata.errid) { // error
        log(vdata.errname,"lib reval", "EE");
        return ret;
    }
    let vrows = vdata.rows
    for (r =0; r < vrows.length; ++r) {
        vsql = String("update acntrade set lastpricebuy = %1 where article='%2';").arg(vrows[r].rate).arg(vrows[r].curid)
        ok &= db.dbUpdate(vsql)
    }
    vsql = String("update acntrade set lastpricebuy = 0 where lastpricebuy IS NULL;")
    ok &= db.dbUpdate(vsql)
    vsql = String("update acntrade set lastpricesell = 0 where lastpricesell IS NULL;")
    ok &= db.dbUpdate(vsql)
    vsql = String("update acntrade set bscprice = (case when lastpricebuy = 0 then lastpricesell else lastpricebuy end) "
                + "where (lastpricebuy != 0 or lastpricesell != 0 ) "
                + "and bscprice != (case when lastpricebuy = 0 then lastpricesell else lastpricebuy end);")
    ok &= db.dbUpdate(vsql)
    vsql = String("select acnt.id tid,acnt.acntno tno, acnt.item, eq.id eid, eq.acntno eno,'rslt.'||acntrade.acntno||'/'||acntrade.article as rno, bscprice, 0-(acnt.beginamnt+acnt.turndbt-acnt.turncdt) amnt, "
                  + "round(0-(acnt.beginamnt+acnt.turndbt-acnt.turncdt) * bscprice - (eq.beginamnt+eq.turndbt-eq.turncdt),2) as profit "
                  + " from  acntrade join acnt on (acntrade.pkey = acnt.id) join acnt as eq on (('eqvl.'||acntrade.acntno||'/'||acntrade.article) = eq.acntno) where substr(acnt.acntno,1,2)='35' and abs(profit)>1 "
                  + "order by acnt.acntno;")  // and profit!=0
    vdata = JSON.parse(db.dbSelectRows(vsql));
    if (vdata.errid) { // error
        msg(vdata.errname,"EE #8ey");
        return ret;
    }
    // console.log("#9e7h main "+JSON.stringify(vdata))
    var vj = ({})
    var vjdcms = []
    let m = vdata.rows
    let vtno = ""
    for (r =0; r < m.length; ++r) {
        if (vtno !== m[r].tno) {
            vtno = m[r].tno
            prf = 0
            vj = {"id":"dcmbind","dcm":"folder","dbt":m[r].tno,"cdt":"rslt","amnt":"0","eq":"0","dsc":"0","bns":"0","note":"reval", "clnt":cshr,"cshr":cshr, "dcms":[]}
        }
        prf += Number(m[r].profit)
        vj.dcms.push({"dcm":"memo","dbt":m[r].eno,"cdt":m[r].rno,"crn":"","amnt":m[r].profit,
            "eq":"0","dsc":"0","bns":"0","note":String("reval %1*%2/%3").arg(m[r].amnt).arg(m[r].bscprice).arg(m[r].item),"retfor":""})
        if ( r+1 === m.length || vtno !== m[r+1].tno) {
            vj.amnt = prf.toFixed(0)
            ret.push(vj)
            vtno = ""
        }
    }

    return ret;

}


function isIncas(db, acnts) {
  // log(JSON.stringify(acnts) )
  // log(JSON.parse(acnts) )
    if (acnts.bulk === undefined || acnts.bulk === "") { return false; }
    let vsql = "select sum(abs(beginamnt+turndbt-turncdt)) as total from acnt where acntno='3500';";
    let vj = parse(db.dbSelectRows(vsql));
    // log(JSON.stringify(vj) )
    if (vj && vj.rows.length){
       // log("#e8u isIncas="+(vj.rows[0].total>0))
        return (Number(vj.rows[0].total) > 0);
    }
    return false;
}

function isShiftOpen(db) {
    let sh = crntShift(db);
    if (Number(sh.id)!==0 && sh.shftend==='') { return true; }
    return false;
}

function newShift(db, acnts, cshr) {        // cshr = {"id", "name"}
    let vnewd = new Date()

    let vsql = ("insert into shift (shftdate, shftbegin, cshr) values ('%1','%2','%3');")
               .arg(Qt.formatDateTime(vnewd, "yyyy-MM-dd"))
               .arg(Qt.formatDateTime(vnewd, "yyyy-MM-dd hh:mm"))
               .arg(cshr.id)
    // console.log("#uhe4 sql="+vsql)
    let vid =  db.dbInsert(vsql)
    // console.log("#4eq id="+vid)

    return vid;
}


/**
*   param = {"shid":str,"shdate":str, "cshr":str}
*/
function closeShift(db, param) {
    return db.closeShift(param.shid);

    // var dnow = new Date(param.shdate)
    // var dprev = new Date(dnow.getFullYear(), dnow.getMonth()-1)
    // var dnext = new Date(dnow.getFullYear(), dnow.getMonth()+1)
    // let mprev = Qt.formatDate( dprev, "yyyy-MM")
    // let mnow = param.shdate.substring(0,7);
    // let mnext = Qt.formatDate( dnext, "yyyy-MM")
    // uploadReport(db, mnow, mnext, rest);
    // if (dnow.getDate() < 4){
    //     uploadReport(db, mprev, mnow, rest);
    // }
}

function acntForUpload(db, updated = true) {
    let sql = "select acntno, coalesce(item,'') as articleid, (beginamnt+turndbt-turncdt) as amnt, turndbt, turncdt, case when coalesce(dbtupd,'')>coalesce(cdtupd,'') then substr(dbtupd,1,16) else substr(cdtupd,1,16) end as tm "
        + String("from acnt where %1;").arg( updated ? "datetime(tm)>datetime('now','-00:10')" : "amnt!=0" );
    let jobj = parse(db.dbSelectRows(sql))
    if (jobj && jobj.rows.length) {
        return jobj.rows
    }
    return false;
}

// vkEvent({'id':'submit', 'pkey':id, 'name':name.replace("'","''"), 'note':clnote.replace("'","''"), 'phone':phone.replace("'","''")})

function updClient(db, id, name, phone, note = ''){
    let vsql = "";
    if (id !== ''){
          vsql = String("update client set clchar = '%1', phone='%2', clnote='%3' where pkey='%4'")
        .arg(name.replace("'","''")).arg(phone.replace("'","''")).arg(note.replace("'","''")).arg(id)
        const rupd = db.dbUpdate(vsql)
        return String(rupd)
    } else {
        const rins = db.dbClientInsert(name, phone, note)
        return String(rins);
    }

}

function updRate(db, price, qty, id, curid, ba){
    let vsql = "";
    let res = 0;
    if (id !== ''){
        vsql = String("update price set qtty=%1, price=%2 where id=%3;")
        .arg(qty).arg(price).arg(id)
        res = db.dbUpdate(vsql)
    } else {
        vsql = String("insert into price (item, qtty, price, prbidask) values ('%1', %2, %3, %4)")
        .arg(curid).arg(qty).arg(price).arg(ba)
        res = db.dbInsert(vsql)
    }
    return res;

}

function bindFromDb(db, bindid, cb){
  let tbl = "docum";
  const vsql = String("select id, dcmtype, amount,coalesce(eqamount,0) eq,coalesce(discount,0) dsc, coalesce(dcmnote,itemchar,'') note, dcmtime, coalesce(itemchar,'ГРН') ichar, coalesce(' ('||itemname||')','') iname, "
  + "coalesce(itemmask,1) mask, coalesce(unitprec,2) prec, coalesce(itemunit.code,'') ucode, coalesce(unitchar,'') uchar, coalesce(qty,1) qty, coalesce(term,0) term, coalesce(item.pkey,'') iid, coalesce(dcmno,'') dcmno "
  + "from %1 left join item on (item=item.pkey) left join itemunit on (defunit=itemunit.pkey) left join articlepriceqty on (item=articlepriceqty.pkey) "
  + "left join warranty on (item=warranty.article) ");
  const fltBind = String(" where %1.id = %2;")
  let jbind = db.dbSelectRow(vsql.arg(tbl) + fltBind.arg(tbl).arg(bindid));
  // log("#2w44 printCheck " + JSON.stringify(jbind))
  if (jbind.errid === 1){
    tbl = "documall"
    jbind = db.dbSelectRow(vsql.arg(tbl) + fltBind.arg(tbl).arg(bindid))
    if (jbind.errid === 1){ // error
      log(jbind.errname, "lib.printCheck", "EE")
      cb(jbind.errname)
      // return jbind
    }
  }
  const fltDcm = String(" where %1.parentid = %2;")
  const jdcm = parse(db.dbSelectRows(vsql.arg(tbl) + fltDcm.arg(tbl).arg(bindid)));
  // log("#2w44 printCheck " + (vsql.arg(tbl) + fltDcm.arg(tbl).arg(id)))
  // log("#898 printCheck " + JSON.stringify(jdcm))
  if (!jdcm){
    jbind.errid = 1
    jbind.errname = "Bind documents not found"
    log("Bind documents not found","lib.printCheck", "EE")
    cb(jbind.errname)
    // return jbind
  }
  jbind.dcms = jdcm.rows

  // log("#898 printCheck " + JSON.stringify(jbind))
  cb(null, jbind)
  // return jbind
}

/**
  CashDesk
  */
function cdtaxFromBind(db, jbind, cb) {
  if (jbind.dcmno !== "") {
    cb("Неможливо повторно фіскалізувати чек")
    return
  }

  let ok = true;
  const rows = jbind.dcms
  let cdatcl = [];    // cashDesc articles
  for (let r =0; r < rows.length && ok; ++r){
    ok &= (rows[r].dcmtype === "trade:sell" && Number(rows[r].mask) === 4 && Number(rows[r].amount) < 0)
    cdatcl.push( {"unit_code": rows[r].ucode, "unit_name": rows[r].uchar, "name": rows[r].ichar,
                "amount": Math.abs(rows[r].amount).toFixed(rows[r].prec),
                "price": Math.abs(Number(rows[r].eq)/Number(rows[r].amount)).toFixed(3),
                "cost": Math.abs(rows[r].eq).toFixed(2),
                "sum_discount":(0-Number(rows[r].dsc).toFixed(2))} )
  }
  if (!ok) { cb("Чек не підлягає фіскалізації"); return; }

  let lnmb = 0;
  lnmb = db.dbInsert("insert into taxdcm (dcmid) values ('"+jbind.id+"')");
  if (lnmb == 0) { cb("Не отримано локальний номер фіскалізації"); return; }

  let tsum = Math.round(10*Math.abs(jbind.amount))/10;
  let rsum = tsum - Math.abs(jbind.amount)
  if (tsum == 0) { cb("Помидка фіскалізації. Сума чеку 0"); return; }

  // cashDesc bind
  let taxbind = {
    // "api_token": token,
    // "num_fiscal": cash,
    "action_type": "Z_SALE",
    "local_number": lnmb,
    "total_sum": tsum.toFixed(2),
    "round_sum":rsum.toFixed(2),
    "products": cdatcl,
    "payments": [{"code": 0,"name": "ГОТIВКА", "sum": tsum.toFixed(2),"sum_provided": tsum.toFixed(2),"sum_remains": 0}],
    "no_text_print":true,"no_pdf":true,"no_qr":true,"open_shift":true,"print_width": 32,"pdf_width": 48
  }

  cb(null, taxbind)
}


