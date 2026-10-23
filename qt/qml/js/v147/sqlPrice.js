.pragma library

const RATE_STMT = `
    SELECT
        id,
        item,
        prbidask,
        qtty AS qty,
        price
    FROM price
`;

const LASTRATE_STMT = `
    SELECT
        article,
        bscprice,
        lastpricebuy,
        lastpricesell,
        acntno
    FROM acntrade
`;

const OFFER_STMT = `
    SELECT
        article,
        qtty AS qty,
        price,
        pricetime
    FROM selloffer
`;

const DISCOUNT_STMT = `
    SELECT
        article,
        price,
        pricetime
    FROM selldsc
`;

// main.js
const DfltPriceQty = (() => {
    // Створюємо карту для миттєвого пошуку кратності пакувань за O(1)
    let dfltQtyMap = new Map();

    return {
        /**
         * Наповнення кешу кратності пакувань з бази даних SQLite
         * @param {Object} db - C++ драйвер бази даних
         */
        populate(db) {
            dfltQtyMap.clear();
            if (!db) return;

            const vsql = "SELECT pkey, qty FROM articlepriceqty;";
            const list = db.dbSelectRowsJSON(vsql);

            for (const row of list) {
                if (row && row.pkey !== undefined) {
                    dfltQtyMap.set(row.pkey, Number(row.qty || 1));
                }
            }
            // console.log(`sqlPrice#di39 ${JSON.stringify([...dfltQtyMap.entries()])}`);
        },

        /**
         * Швидке отримання кратності для конкретного товару
         * @param {number|string} id - Ідентифікатор товару (pkey)
         * @returns {number} - Кратність пакування (дефолт: 1)
         */
        val(id) {
            if (!id) return 1; // Для фінансів безпечніше повертати 1 як дефолтний множник кількості
            if (dfltQtyMap.has(id)) {
                return dfltQtyMap.get(id);
            }
            return 1;
        }
    };
})();

/**
 * Дефолтна структура курсу валюти (Захист від null/undefined)
 */
function dummyPrice(atclid, price = 0) {
    const qtyVal = !atclid ? 1 : (DfltPriceQty.val(atclid) || 1);
    return {
        "id": "",   // rate id in DB table
        "item": atclid || "",
        "qty": qtyVal,
        "price": Number(price || 0.0),
        "offer": 0.0,
        "dsc": 0.0,
        "bsc": 0.0, // basic price for accounting
    };
}

const  buildWhereClause = (conditionsArray) => {
    if (!conditionsArray || conditionsArray.length === 0) return "";
    return "WHERE " + conditionsArray.join(" AND ");
}

/**
 * Отримання курсу для конкретної валюти за її ID
 * @param {Object} db - Драйвер бази даних
 * @param {string} itemid - ID валюти
 * @param {number} ba - bid|ask
 * @param {string} acntno - bal acntno
 */
function price(db, itemid, ba, acntno){
    // console.info(`kjw#sqlPrice START id=${itemid} ba=${ba} no=${acntno}`);
    let res = dummyPrice(itemid);
    if (!db || !itemid) return res;
    const isAsk = Number(ba || -1) < 0;
    let ok = false;
    if (isAsk) {
        const fltOfr = `article = '${itemid}'`;
        const offer = dbOffer(db, fltOfr);
        if (offer?.length > 0 && (offer[0].price || 0) !== 0) {
            ok = true
            res.id = "";
            res.qty = offer[0].qty || 1;
            res.offer = offer[0].price || 0.0;
        }
    }
    // console.info(`832#sqlPrice 11 id=${JSON.stringify(res)}`)
    if (ok) return res;

    let fltP = `prbidask = ${isAsk ? -1 : 1} AND item = '${itemid}'`;
    // const pr = dbPrice(db, fltP);
    const pr = dbPrice(db, itemid, Number(ba || -1));
    console.info(`s83#sqlPrice 22 pr=${JSON.stringify(pr)}`)
    if (pr?.length > 0 && (pr[0].price || 0) !== 0) {
        ok = true
        res.id = pr[0].id || "";
        res.qty = pr[0].qty || 1;
        res.price = pr[0].price || 0.0;
        const fltDsc = `article = '${itemid}'`;
        const dsc = dbDsc(db, fltDsc);
        if (dsc?.length > 0) {
            res.dsc = dsc[0].price || 0.0;
        }
    }
    // console.info(`s83#sqlPrice 33 id=${JSON.stringify(res)}`)
    // then last price
    if (!ok){
        const prlast = dbLastRate(db, acntno, itemid);
        if (!!prlast) {
            if (!res.qty) res.qty = prlast.qty;
            const coef = res.qty !== prlast.qty ? (res.qty / prlast.qty) : 1;
            const priceBsc = (isAsk
                            ? coef * (prlast.sell || prlast.bsc || 0.0)
                            : coef * (prlast.buy || prlast.bsc || 0.0) );
            res.bsc = priceBsc;
            // res.price = priceBsc;
            // if (res.qty !== 1) res.price = priceBsc * res.qty;
            // else res.price = priceBsc;

        }
    }
    // console.info(`iw9#sqlPrice 55 id=${JSON.stringify(res)}`)
    return res;
}

function sell(db, itemid) {
    if (!db || !itemid) return dummyPrice();

    const pr = dbPrice(db, itemid, -1);

    if (pr && pr.length > 0) {
        return pr[0];
    }

    return dummyPrice(itemid);
}

// shift.js
function buy(db, itemid) {
    if (!db || !itemid) return dummyPrice();

    const pr = dbPrice(db, itemid, 1);

    if (pr && pr.length > 0) {
        return pr[0];
    }

    return dummyPrice();
}

// rates.js
function currencyRates(db) {
    if (!db) return [];

    const flt = "item in (SELECT pkey FROM item WHERE itemmask & 2 AND folder=0)"
    const param = [];
    const condStr = "WHERE (prtype IS NULL OR prtype = '') AND item in (SELECT pkey FROM item WHERE itemmask & 2 AND folder=0)";
    const vsql = `${RATE_STMT} ${condStr};`;
    // console.log(`II: 7wy3#sqlPrice.js vsql=${vsql}`)

    return db.dbSelectRows(vsql, param) || [];
}

/**
 *
 */
// function dbPrice(db, flt = "") {
function dbPrice(db, atclid, ba, prtype) {
    if (!db) return null;

    const  l_build = (conditionsArray, prIsBlank) => {
        if (!conditionsArray || conditionsArray.length === 0) return prIsBlank ? "WHERE prtype IS NULL OR prtype = '' " : "";
        return "WHERE " + (prIsBlank ? " (prtype IS NULL OR prtype = '') AND " : "") + conditionsArray.join(" AND ");
    }
    let isPrBlank = false;
    const cond = [];
    const param = [];
    if (!!atclid){
        cond.push("item = ?");
        param.push(atclid);
    }
    if (!!ba){
        cond.push("prbidask = ?");
        param.push(Number(ba || 0) < 0 ? -1 : 1 );
    }
    if (!!prtype){
        cond.push("item = ?");
        param.push(atclid);
    } else isPrBlank = true;

    const condStr = l_build(cond, isPrBlank);

    const vsql = `${RATE_STMT} ${condStr};`;
    // const vsql = "SELECT id, item, prbidask, qtty, price FROM price "
    //            + "WHERE (prtype IS NULL OR prtype = '')" + (flt === "" ? "" : (" AND " + flt)) + ";";
    // console.log(`sqlPrice sql=${vsql}`);
    return db.dbSelectRows(vsql, param) || [];
}

function dbOffer(db, atclid) {
    if (!db) return [];
    const cond = [];
    const param = [];
    if (!!atclid){
        cond.push("article = ?");
        param.push(atclid);
    }
    const whereCondition = buildWhereClause(cond);
    const vsql = `${OFFER_STMT} ${whereCondition};`;
    return db.dbSelectRows(vsql, param) || [];
}

function dbDsc(db, atclid) {
    if (!db) return [];
    const cond = [];
    const param = [];
    if (!!atclid){
        cond.push("article = ?");
        param.push(atclid);
    }
    const whereCondition = buildWhereClause(cond);
    const vsql = `${DISCOUNT_STMT} ${whereCondition};`;

    return db.dbSelectRows(vsql, param) || [];
}

// last price from acntrade
function dbLastRate(db, acntno, atclid) {
    if (!db) return null;
    if (!atclid) return null;

    const cond = [];
    const param = [];
    if (!!atclid){
        cond.push("article = ?");
        param.push(atclid);
    }
    if (!!acntno){
        cond.push("acntno = ?");
        param.push(acntno);
    }
    const condStr = buildWhereClause(cond);
    const vsql = `${LASTRATE_STMT} ${condStr};`;

    // console.log(`II: 7wy3#sqlItem.js vsql=${vsql}`)
    const dbrate = db.dbSelectRow(vsql,param);
    // console.log(`II: 214#sqlItem.js dbrate=${JSON.stringify(dbrate)}`)
    if (!dbrate.errid){
        const qtyVal = DfltPriceQty.val(atclid);
        const res = {
            "item": String(dbrate.article || ""),
            "acntno": String(dbrate.acntno || ""),
            "qty": qtyVal,
            "bsc": Number(dbrate.bscprice || 0.0) * qtyVal,
            "buy": Number(dbrate.lastpricebuy || 0.0) * qtyVal,
            "sell": Number(dbrate.lastpricesell || 0.0) * qtyVal,
        };
        // console.log(`II: 133s#sqlItem.js res=${JSON.stringify(res)}`)
        return res;
    }

    return null;
}

function dbLastRateList(db, acntno, atclid) {
    const res = [];
    if (!db) return res;

    const cond = [];
    const param = [];
    if (!!acntno){
        cond.push("acntno = ?");
        param.push(acntno);
    }
    if (!!atclid){
        cond.push("article = ?");
        param.push(atclid);
    }
    const condStr = buildWhereClause(cond);
    const vsql = `${LASTRATE_STMT} ${condStr};`;

    // console.log(`II: 7wy3#sqlItem.js vsql=${vsql}`)
    const source = db.dbSelectRows(vsql,param);
    // console.log(`II: 214#sqlItem.js source=${JSON.stringify(source)}`)
    // for (let i =0; i < 10; ++i ) console.log("62j#sqlPrice=", JSON.stringify(source[i]));
    if (source?.length > 0){
        for (let v of source){
            const qtyVal = DfltPriceQty.val(atclid);
            res.push({
                         "item": String(v.article || ""),
                         "acntno": String(v.acntno || ""),
                         "qty": qtyVal,
                         "bsc": Number(v.bscprice || 0.0) * qtyVal,
                         "buy": Number(v.lastpricebuy || 0.0) * qtyVal,
                         "sell": Number(v.lastpricesell || 0.0) * qtyVal,
                     })
        }
    }
    // for (let i =0; i < 10; ++i ) console.log("62j#sqlPrice=", JSON.stringify(res[i]));

    return res;
}
// DEPRECATED
function dbLast(db, flt = "") {
    console.warn("WW: sqlPrice.js/dbLast DEPRECATED, use dbLastRate !!!")
    if (!db) return [];
    const whereCondition = (flt === "" ? "" : `WHERE ${flt}`)
    const vsql = `
        SELECT
            article,
            bscprice,
            lastpricebuy,
            lastpricesell,
            acntno
        FROM acntrade
        ${whereCondition};
            `

    return db.dbSelectRowsJSON(vsql);
}

/**
 * Універсальний запис або оновлення курсу в таблиці price (SQLite)
 */
// rate.js
function updRate(db, price, qty, id, curid, ba) {
    if (!db) return 0;

    let res = 0;
    const qtyVal = Number(qty || 1);
    const priceVal = Number(price || 0);
    const idVal = Number(id || 0);
    const curVal = String(curid || "")
    const baVal = Number(ba || -1) > 0 ? "1" : "-1";

    // Перевіряємо наявність існуючого ID запису (id як рядок може прийти порожнім або "0")
    if (idVal !== 0) {
        const updParam = [qtyVal, priceVal, idVal];
        const updStmt = "UPDATE price SET qtty = ? , price = ? WHERE id = ? ;";
        res = db.dbUpdate(updStmt, updParam);
    } else {
        const insParam = [curVal, qtyVal, priceVal, baVal];
        const insStmt = `INSERT INTO price (item, qtty, price, prbidask) VALUES ( ? , ? , ? , ? );`;
        res = db.dbInsert(insStmt, insParam);
    }

    return res;
}

