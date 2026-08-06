.pragma library

.import "config.js" as LibConf
.import "sqlAcnt.js" as LibAcnt
.import "sqlPrice.js" as LibPrice


function dbShift(db, condition){
    if (!db) return null;
    const vsql = `
        SELECT
            id,
            shftdate,
            shftbegin,
            shftend,
            cshr,
            cashier.note AS cshrname
        FROM shift
            LEFT JOIN cashier ON(cshr = code)
        ${condition};
    `
    // console.log(`sqlShift.js#73yu ${vsql}`)
    return db.dbSelectRowsJSON(vsql);
}

function dbCashier(db, condition, filter){
    if (!db) return null;
    const whereCondition = (condition ? `WHERE ${condition}` : "")
    const vsql = `
        SELECT
            code,
            note,
            psw
        FROM cashier
        ${whereCondition}
        ORDER BY note;
    `
    // console.log(`sqlShift.js#73yu ${vsql}`)
    return db.dbSelectRowsJSON(vsql, filter);
}

/**
 *
 */
function crntShift(db) {
    if (!db) return null;

    const condition = "ORDER BY id DESC LIMIT 1";
    const res = dbShift(db, condition);
// console.log(`sqlShift#e7h len=${res.length} shift=${JSON.stringify(res)}`)
    if (res && res.length > 0)  return res[0];
    return null;
}

function cashierList(db) {
    if (!db) return null;

    const res = dbCashier(db);

    return res;
}

function dbStartShift(db, cshrid = "") {
    if (!db) return null;
    const vnewd = new Date().toISOString();

    let vsql = `
    INSERT INTO shift (shftdate, shftbegin, cshr)
        VALUES ('${vnewd.substring(0, 10)}',
                '${vnewd}',
                '${cshrid}');
    `
    // console.log("#uhe4 sql="+vsql)
    const vid =  db.dbInsert(vsql)
    // console.log("#4eq id="+vid)

    return vid;
}

function dbRefreshTradeRate(db) {
    if (!db) return false;

    const priceList = LibPrice.dbPrice(db, "prbidask = 1 AND price != 0")
    // if (!priceList) return false;
    let vsql = "";
    let ok = true;
    for (let r =0; priceList && r < priceList.length && ok; ++r) {
        vsql = `UPDATE acntrade
                    SET lastpricebuy = ${priceList[r].price/priceList[r].qtty}
                WHERE article='${priceList[r].item}';
        `
        ok &= db.dbUpdate(vsql)
    }
    vsql = "UPDATE acntrade SET lastpricebuy = 0 WHERE lastpricebuy ISNULL;"
    ok &= db.dbUpdate(vsql)
    vsql = "UPDATE acntrade SET lastpricesell = 0 WHERE lastpricesell IS NULL;"
    ok &= db.dbUpdate(vsql)
    vsql = `UPDATE acntrade
                SET bscprice = (CASE WHEN lastpricebuy = 0 THEN lastpricesell ELSE lastpricebuy END)
            WHERE (lastpricebuy != 0 OR lastpricesell != 0 );
            `
    // AND bscprice != (CASE WHEN lastpricebuy = 0 THEN lastpricesell ELSE lastpricebuy END);
    ok &= db.dbUpdate(vsql)

    return ok;
}

function makeBind_reval(db, cshrid ){
    var res = []
    let ok = true;
    let r=0, total = 0;
    let vsql = ""

    const acntList = LibAcnt.dbAcntbal(db, `substr(acntno,1,${LibConf.glTradePrefix.length}) = '${LibConf.glTradePrefix}'`)
    for (r =0; r < acntList.length; ++r){
        const revalList = dbRevalList(db, acntList[r].acntno);
        let dcms = []
        total = 0;
        for (let i =0; i < revalList.length; ++i){
            total += Number(revalList[i].profit)
            dcms.push({
                       "dcm":"memo",
                       "dbt":revalList[i].eno,
                       "cdt":revalList[i].rno,
                       "crn":"",
                       "amnt":revalList[i].profit.toFixed(3),
                       "eq":"0","dsc":"0","bns":"0",
                       "note":`reval ${revalList[i].amnt}*${revalList[i].bscprice.toFixed(3)}/${revalList[i].item}`,
                       "retfor":""
                    })
        }
        if (dcms.length > 0){
           const bind =  {
                "id": "dcmbind",
                "dcm": "folder",
                "dbt": acntList[r].acntno,
                "cdt": "rslt",
                "amnt": "0","eq":"0","dsc":"0","bns":"0",
                "note": "reval",
                "clnt": cshrid,
                "cshr": cshrid,
                "dcms": dcms}
            res.push(bind);
        }
    }

    return res;
}

function dbRevalList(db, tradeAcntNo) {
    // console.log(`sqlClient.js#14rc tradeAcntNo=${tradeAcntNo}`)
    if (!db) return null;
    // if (!tradeAcntNo) return null;
    // const whereCondition = `WHERE acntrade.acntno ='${tradeAcntNo}' AND (acnt.beginamnt+acnt.turndbt-acnt.turncdt) != 0 `;
    // const whereCondition = `WHERE substr(acntrade.acntno, 1, ${tradeAcntNo.length}) ='${tradeAcntNo}'`;
    const whereCondition = !!tradeAcntNo ? `WHERE acntrade.acntno ='${tradeAcntNo}'` : "";
    const vsql = `
        SELECT
            acnt.id tid,
            acnt.acntno tno,
            acnt.item AS item,
            eq.id eid,
            eq.acntno eno,
            'rslt.'||acntrade.acntno||'/'||acntrade.article AS rno,
            bscprice,
            acnt.beginamnt+acnt.turndbt-acnt.turncdt AS amnt,
            eq.beginamnt+eq.turndbt-eq.turncdt AS eqamnt,
            round(0-(acnt.beginamnt+acnt.turndbt-acnt.turncdt) * bscprice - (eq.beginamnt+eq.turndbt-eq.turncdt),2) AS profit
        FROM acntrade
            JOIN acnt ON (acntrade.pkey = acnt.id)
            JOIN acnt AS eq ON (('eqvl.'||acntrade.acntno||'/'||acntrade.article) = eq.acntno)
        ${whereCondition};
    `
    // console.log(`sqlClient.js#0ru ${vsql}`);
    return db.dbSelectRowsJSON(vsql);
}

function fakeDbCloseShift(db, shiftid){
    const vnewd = new Date().toISOString();
    const vsql = `UPDATE shift SET shftend = '${vnewd}' WHERE id = ${shiftid} ;`
    const ok = db.dbUpdate(vsql)
    return ok;
}





