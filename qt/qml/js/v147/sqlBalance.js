.pragma library

const SQL_STMT = `
SELECT
    id,
    acntno,
    coalesce(item, '') itemid,
    (beginamnt+turndbt-turncdt) as total,
    coalesce(turndbt, '') income,
    coalesce(turncdt, '') outcome,
    coalesce(dbtupd, '') intm,
    coalesce(cdtupd, '') outm,
    coalesce(client, '') clid,
    coalesce(acntbal.acntnote,'') note,
    coalesce(acntbal.mask,1) mask,
    coalesce(acntbal.trade,0) trade,
    balname
FROM acnt
    LEFT JOIN acntbal using(acntno)
    LEFT JOIN balname ON (substr(acntno,1,2) = bal)
`;

function buildWhereClause(conditionsArray) {
    if (!conditionsArray || conditionsArray.length === 0) {
        return "";
    }
    // Склеюємо умови через AND з правильними пробілами
    return "WHERE " + conditionsArray.join(" AND ");
}


/**
 * ГЕНЕРАТОР ЗАПИТІВ БАЛАНСУ (Головна функція, повністю оптимізована)
 */
function dbBalance(db, flt = "", order = "", reverse = false) {
    // console.log(`26#sqlAcnt.js db=[${db}]`)
    if (!db) return [];
    // console.log(`984#sqlAcnt.js db=[Ok]`)

    // Розрахунок сальдо залежно від типу рахунку (Актив / Пасив)
    const amount = reverse
                 ? " (0 - (beginamnt+turndbt-turncdt)) as total, coalesce(turncdt, '') income, coalesce(turndbt, '') outcome, coalesce(cdtupd, '') intm, coalesce(dbtupd, '') outm,"
                   :" (beginamnt+turndbt-turncdt) as total, coalesce(turndbt, '') income, coalesce(turncdt, '') outcome, coalesce(dbtupd, '') intm, coalesce(cdtupd, '') outm,";
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
            coalesce(acntbal.mask,1) mask,
            coalesce(acntbal.trade,0) trade,
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

/**
 * Залишки по групі рахунків (напр. по всьому 300)
 * NO reverse, NO sort
 * balace.js
 */
function balBalance(db, bal, condition) {
    if (!db || !bal || bal.length < 2) return [];

    const flt = `substr(acntno, 1, ${bal.length}) = '${bal}' AND (abs(beginamnt) + abs(turndbt) + abs(turncdt)) > 0.0001`
        + (!condition ? "" : ` AND ${condition}`);
// console.log(`II: sqlAcnt.js/balBalance2 flt = ${flt}`)
    return dbBalance(db, flt);
}

// libREST.js
function balanceForUpload(db, tm, ofset) {
    if (!db) return [];
    const param = [];
    const cond = [];

    if (!!tm){
        const ofsetVal = Number(ofset || 10);
        const tmVal = new Date(tm);
        tmVal.setSeconds(tmVal.getSeconds() - ofsetVal);
        const tmISO = tmVal.toISOString();
        param.push(tmISO);
        param.push(tmISO);
        cond.push(`(dbtupd > ? OR cdtupd > ? )`)
    } else {
        cond.push("(abs(beginamnt) + abs(turndbt) + abs(turncdt)) > 0.0001")
    }

    const condStr = buildWhereClause(cond);
    const vsql = `${SQL_STMT} ${condStr};`;

    return db.dbSelectRows(vsql, param);
}

function old_balanceForUpload(db, tm, ofset) {
    if (!db) return [];

    const tmVal = Number(tm ?? 0);
    const ofsetVal = `'-${String(ofset || 10)} seconds'`

    // Прибрано 'localtime'. Тепер порівняння часу транзакцій
    // з системним 'now' за Гринвічем відбувається безпомилково і миттєво!
    const whereCondition = !!tm
        ? `(datetime(dbtupd) > datetime('${tm}', ${ofsetVal} ) OR datetime(cdtupd) > datetime('${tm}', ${ofsetVal}))`
        : "(abs(beginamnt) + abs(turndbt) + abs(turncdt)) > 0.0001";
    // console.log(`II: sqlBalance/balanceForUpload flt=${whereCondition}`)

    return dbBalance(db, whereCondition);
}
