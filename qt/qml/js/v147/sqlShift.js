.pragma library

.import "../common.js" as JS
.import "config.js" as LibConf
.import "sqlAcnt.js" as LibAcnt
.import "sqlPrice.js" as LibPrice

const SHIFT_STMT = `
    SELECT
        id,
        shftdate,
        shftbegin,
        shftend,
        cshr,
        cashier.note AS cshrname
    FROM shift
        LEFT JOIN cashier ON(cshr = code)
`;

const CASHIER_STMT = `
    SELECT
        code,
        note,
        psw
    FROM cashier
`;


function dbShift(db, condition){
    if (!db) return null;
    const vsql = `${SHIFT_STMT} ${condition};`;
    // console.log(`sqlShift.js#73yu ${vsql}`)
    return db.dbSelectRowsJSON(vsql);
}

function dbCashier(db/*, condition, filter*/){
    if (!db) return null;
    // const whereCondition = (condition ? `WHERE ${condition}` : "")
    const vsql = `${CASHIER_STMT};`;
    // console.log(`sqlShift.js#73yu ${vsql}`)
    return db.dbSelectRows(vsql, []);
}

/**
 * bind.js, shift.js, main.js
 */
function crntShift(db) {
    if (!db) return null;

    // const condition = "ORDER BY id DESC LIMIT 1";
    const  vsql = `${SHIFT_STMT} ORDER BY id DESC LIMIT 1;`;
    const res = db.dbSelectRows(vsql, []);
    // console.log(`sqlShift#e7h len=${res.length} shift=${JSON.stringify(res)}`)
    if (res && res.length > 0)  return res[0];
    return null;
}

// bind.js, sqlTran.js
function crntShiftData(db) {
    if (!db) return null;

    // const condition = "ORDER BY id DESC LIMIT 1";
    const  vsql = `${SHIFT_STMT} ORDER BY id DESC LIMIT 1;`;
    const source = db.dbSelectRows(vsql, []);
    // console.log(`sqlShift#e7h len=${res.length} shift=${JSON.stringify(res)}`)
    if (!source || source.length === 0)  return null;
    const row = source[0];
    const res = {
        id: Number(row.id || 0),
        date: String(row.shftdate || ""),
        start: String(row.shftbegin || ""),
        finish: String(row.shftend || ""),
        isActive: !row.shftend,
        cshrId: String(row.cshr || ""),
        cshrName: String(row.cshrname || ""),
    }

    return res;
}

function cashierList(db) {
    if (!db) return null;

    const res = dbCashier(db);

    return res;
}

// shift.js
function dbStartShift(db, cshrid = "") {
    if (!db) return null;
    const vnewd = new Date().toISOString();

    const param = [
                    vnewd.substring(0, 10),
                    vnewd,
                    cshrid
                ];

    const vsql = " INSERT INTO shift (shftdate, shftbegin, cshr) VALUES ( ? , ? , ?);";
    const vid =  db.dbInsert(vsql, param)

    return vid;
}

function dbRevalList(db, tradeAcntNo) {
    // console.log(`sqlClient.js#14rc tradeAcntNo=${tradeAcntNo}`)
    if (!db) return null;
    const cond = [];
    const param = [];
    if ( !!tradeAcntNo ) {
        cond.push("acntrade.acntno = ?");
        param.push(tradeAcntNo);
    }

    const condStr = JS.buildWhereClause(cond);
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
        ${condStr};
    `
    // console.log(`sqlClient.js#0ru ${vsql}`);
    return db.dbSelectRows(vsql, param);
}

function fakeDbCloseShift(db, shiftid){
    const vnewd = new Date().toISOString();
    const vsql = `UPDATE shift SET shftend = '${vnewd}' WHERE id = ${shiftid} ;`
    const ok = db.dbUpdate(vsql)
    return ok;
}





