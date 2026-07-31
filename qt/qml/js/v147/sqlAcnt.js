.pragma library
/**
  JS library
*/
.import "config.js" as Conf

const DfltAcnt = ( () => {
    let dfltAcnts = null;
    let dfltCashAcnt = null;
    let dfltTradeAcnt = null;
    return {
        reset(){
        dfltAcnts = null;
        dfltCashAcnt = null;
        dfltTradeAcnt = null;
        },
        acnts(db){
            const l_parse = (raw) => {
                try {
                  return JSON.parse(raw);
                } catch (err) {
                  return null;
                }
            };
            if (dfltAcnts) return dfltAcnts;
            if (!db) return null;
            const jlist = Conf.getVal(db, "acntlist");
            if (!!jlist) dfltAcnts = jlist;

            // console.log(`II: sqlAcnts.js/DfltAcnt tmp=${tmp}`)
            // const vsql = "select acnts from settings limit 1;"
            // const va = db.dbSelectRow(`SELECT val FROM conf WHERE key = 'acntlist';`);
            // console.log(`II: sqlAcnts.js/DfltAcnt va=${JSON.stringify(va)}`)
            // if (!va.errid){
            //   dfltAcnts = l_parse(va.val);
            // }
            // console.log(`II: sqlAcnts.js/DfltAcnt dfltAcnts=${JSON.stringify(dfltAcnts)}`)
            return dfltAcnts;
        },
        trade(db) {
            if (dfltTradeAcnt) return dfltTradeAcnt;
            DfltAcnt.acnts(db);
            dfltTradeAcnt = acntbal(db, dfltAcnts?.trade || "", true);
            return dfltTradeAcnt;
        },
        cash(db) {
            if (dfltCashAcnt) return dfltCashAcnt;
            DfltAcnt.acnts(db);
            dfltCashAcnt = acntbal(db, dfltAcnts?.trade || "", true);
            return dfltCashAcnt;
        },
        cashAcntNo(db){
            if (dfltAcnts) return dfltAcnts?.cash || "";
            DfltAcnt.acnts(db);
            return dfltAcnts?.cash || "";
        },
        tradeAcntNo(db){
            if (dfltAcnts) return dfltAcnts?.trade || "";
            DfltAcnt.acnts(db);
            return dfltAcnts?.trade || "";
        },
        bulkAcntNo(db){
            if (dfltAcnts) return dfltAcnts?.bulk || "";
            DfltAcnt.acnts(db);
            return dfltAcnts?.bulk || "";
        },
        profitAcntNo(db){
            if (dfltAcnts) return dfltAcnts?.profit || "";
            DfltAcnt.acnts(db);
            return dfltAcnts?.profit || "";
        },
    };
})();

function createCashAcntNo() {
    const res = `${Conf.glCashPrefix}00`;
    return res;
}

function createTradeAcntNo() {
    const res = `${Conf.glTradePrefix}00`;
    return res;
}

function createClientBonusAcntNo( clid ) {
    const res = `${Conf.glBonusPrefix}00${clid || ""}`;
    return res;
}

/**
 * Залишок по конкретному рахунку + item
 * main.js
 */
function acntItemBalance(db, acnt, article = "", notzero = true) {
    if (!db || !acnt || acnt.length < 2) return null;

    const reverse = (acnt.substring(0, 2) !== "30");
    const flt = `
    acntno = '${acnt}'
    ${article==="" ? "AND (item ISNULL OR item = '')" : `AND item = ${article}`}
    ${notzero ? "AND abs(beginamnt + turndbt - turncdt) > 0.0001" : ""}
    `
// console.log(`sqlAcnt.js ${flt}`)

    const balance = dbBalance(db, flt, "id", reverse);
    return balance?.[0] ?? null

}

/**
 * Залишок по конкретному рахунку
 */
function acntBalance(db, acnt) {
    if (!db || !acnt || acnt.length < 2) return [];

    const reverse = (acnt.substring(0, 2) !== "30");

    const flt = "acntno = '" + acnt + "' AND abs(beginamnt + turndbt - turncdt) > 0.0009";

    return dbBalance(db, flt, "id", reverse);
}

/**
 * Залишки по групі рахунків (напр. по всьому 300)
 */
function balBalance(db, bal) {
    console.log("WW: sqlAcnt.js/balBalance is DEPRECATED !!!")
    if (!db || !bal || bal.length < 2) return [];

    const reverse = (String(bal).startsWith("30"));

    // ✅ ВИПРАВЛЕНО: Замість видаленого String().arg використовуємо стабільну збірку рядка
    const flt = "substr(acntno, 1, " + bal.length + ") = '" + bal + "' AND abs(beginamnt + turndbt - turncdt) > 0.0009";

    return dbBalance(db, flt, "id", reverse);
}
/**
 * Залишки по групі рахунків (напр. по всьому 300)
 * NO reverse, NO sort
 */
function balBalance2(db, bal, condition) {
    if (!db || !bal || bal.length < 2) return [];

    const flt = `substr(acntno, 1, ${bal.length}) = '${bal}' AND abs(beginamnt + turndbt - turncdt) > 0.0009`
        + (!condition ? "" : ` AND ${condition}`);

    return dbBalance(db, flt);
}

/**
 * Обороти та баланс по торгових рахунках (3500)
 */
function tradeBalance(db, bal = "3500") {
    if (!db || bal.length < 2) return [];

    const flt = "substr(acntrade.acntno, 1, " + bal.length + ") = '" + bal + "'";
    return dbTradeBalance(db, flt);
}


/**
 * ГЕНЕРАТОР ЗАПИТІВ БАЛАНСУ (Головна функція, повністю оптимізована)
 */
function dbBalance(db, flt = "", order = "", reverse = false) {
    // console.log(`26#sqlAcnt.js db=[${db}]`)
    if (!db) return [];
    // console.log(`984#sqlAcnt.js db=[Ok]`)

    // Розрахунок сальдо залежно від типу рахунку (Актив / Пасив)
    let amount = " (beginamnt+turndbt-turncdt) as total, coalesce(turndbt, '') income, coalesce(turncdt, '') outcome, coalesce(dbtupd, '') intm, coalesce(cdtupd, '') outm,";
    if (reverse) {
        amount = " (0 - (beginamnt+turndbt-turncdt)) as total, coalesce(turncdt, '') income, coalesce(turndbt, '') outcome, coalesce(cdtupd, '') intm, coalesce(dbtupd, '') outm,";
    }
    const whereCondition = (flt === "" ? "" : `WHERE ${flt}`)
    const sortCondition = (order === "" ? "" : `ORDER BY ${order}`)
    const vsql = `
        SELECT
            id,
            acntno,
            coalesce(item, '') itemid,
            ${amount}
            coalesce(client, '') clid,
            coalesce(acntbal.acntnote,'') note,
            coalesce(acntbal.mask,'') mask,
            coalesce(acntbal.trade,'') trade,
            balname
        FROM acnt
            LEFT JOIN acntbal using(acntno)
            LEFT JOIN balname ON (substr(acntno,1,2) = bal)
        ${whereCondition}
        ${sortCondition};
    `
    // console.log(`sqlAcnt.js ${vsql}`)
    return db.dbSelectRowsJSON(vsql);
    // const res = db.dbSelectRowsJSON(vsql);
    // console.log(`0wh#sqlAcnt.js ${JSON.stringify(res)}`)
    // return res;
}

/**
 * Отримання комерційних цін та залишків для торгівлі (35)
 * acnt should start with 35
 */
function dbTradeBalance(db, condition = "", order = "") {
    if (!db) return [];
    const whereCondition = (condition === "" ? "" : `WHERE ${condition}`)
    const sortCondition = (order === "" ? "" : `ORDER BY ${order}`)
    const vsql = `
    SELECT
        acntrade.pkey id,
        eqid,
        (beginamnt+turndbt-turncdt) total,
        bscprice,
        lastpricebuy buyprice,
        lastpricesell sellprice,
        article
    FROM acntrade JOIN acnt ON (eqid=acnt.id)
    ${whereCondition}
    ${sortCondition};
`
    return db.dbSelectRowsJSON(vsql);
}

/*{ "acntno":"",
    "clid":"",
    "clname":"",
    "note":"",
    "mask":"",
    "clnote":"",
    "trade":"",
    "name":""
}*/
/**
 * main.js
 */
function acntbal(db, acntno, forceCreate = false) {
    // if (!db) throw new Error("Database instance is required");
    // console.log(`js94#sqlAcnt/acntbal acntno=[${acntno}]`)
    if (acntno && acntno.length < 2) return null;
    const dummy = {
        "acntno":acntno,
        "clid":"",
        "clname":"",
        "note":"",
        "mask":1,
        "trade":0,
        "name":""
    }
    if (acntno && (acntno.startsWith("rslt") || acntno.startsWith("eqvl")))
        return dummy;

    if (!db) return null;
    if (!acntno ||acntno.length < 4) return null;

    const flt = acntno
              ? `acntno='${acntno}' ORDER BY acntno`
              : `acntbal.trade = 1 AND mask != 0 ORDER BY acntno`

    let res = dbAcntbal(db, flt);
    if (forceCreate){
        const vsql = `
            SELECT
                bal,
                balname,
                articlemask,
                trade
            FROM balname
            WHERE bal = substr('${acntno}', 1, 2);
        `
        const balList = db.dbSelectRowsJSON(vsql);
        const bal = balList?.[0] || null;
        // console.log(`276#sqlAcnt ${JSON.stringify(bal)}`)
        if (res && res.length > 0){
            if (res?.[0].mask === 0){
                if (bal){
                    const updSql =`
                        UPDATE acntbal
                        SET mask = ${bal.articlemask}, trade = ${bal.trade}
                        WHERE acntno = '${acntno}'
                    `
                    // console.log(`w8u2#sqlAcnt ${updSql}`)
                    db.dbUpdate(updSql);
                    res = dbAcntbal(db, flt);
                } else return null;
            }
        } else {
            if (bal){
                const insSql =`
                    INSERT INTO acntbal (acntno, mask, trade)
                    VALUES ('${acntno}', ${bal.articlemask}, ${bal.trade});
                `
                // console.log(`q63#sqlAcnt ${insSql}`)
                db.dbInsert(insSql);
                res = dbAcntbal(db, flt);
            } else return null;

        }

    }


    return res?.[0] ?? null;
}

/**
 * main.js
 */
function acntbalClientList(db, clid, filter) {
    // if (!db) throw new Error("Database instance is required");
    if (!db) return null;

    const fltClient = !clid ? "AND (client IS NULL OR client = '')"
                           : `AND client = '${clid}'`;
    const condition = `acntbal.mask != 0 ${fltClient}`;

    const res = dbAcntbal(db, condition, filter);

    return res;
}

/**
 * sqlShift.js
 */
function dbAcntbal(db, condition, filter) {
    if (!db) return [];
    const whereCondition = (condition ? `WHERE ${condition}` : "")
    const vsql = `
        SELECT
            acntno,
            coalesce(client, '') clid,
            coalesce(clchar, '') AS clname,
            acntnote AS note,
            mask,
            acntbal.trade AS trade,
            balname as name
        FROM acntbal
            LEFT JOIN client ON (pkey=client)
            LEFT JOIN balname ON (substr(acntno,1,2)=bal)
        ${whereCondition};
    `
// console.log(`sqlAcnt.js#89au sql=${vsql}`);
    return db.dbSelectRowsJSON(vsql, filter);
}


function balanceForUpload(db, updatedOnly) {
    if (!db) return [];

    // Прибрано 'localtime'. Тепер порівняння часу транзакцій
    // з системним 'now' за Гринвічем відбувається безпомилково і миттєво!
    const whereCondition = updatedOnly
        ? "datetime(tm) > datetime('now', '-10 minutes')"
        : "abs(beginamnt + turndbt - turncdt) > 0.001";

    const sql = `
        SELECT
            acntno,
            coalesce(item, '') AS articleid,
            (beginamnt + turndbt - turncdt) AS amnt,
            turndbt,
            turncdt,
            CASE
                WHEN coalesce(dbtupd, '') > coalesce(cdtupd, '') THEN substr(dbtupd, 1, 16)
                ELSE substr(cdtupd, 1, 16)
            END AS tm
        FROM acnt
        WHERE ${whereCondition};
    `;

    return db.dbSelectRowsJSON(sql) || [];
}



