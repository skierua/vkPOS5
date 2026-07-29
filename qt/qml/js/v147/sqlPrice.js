.pragma library

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

/**
 * Отримання курсу продажу для конкретної валюти за її ID
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
            res.qty = offer[0].qtty || 1;
            res.offer = offer[0].price || 0.0;
        }
    }
    // console.info(`832#sqlPrice 11 id=${JSON.stringify(res)}`)
    if (ok) return res;

    let fltP = `prbidask = ${isAsk ? -1 : 1} AND item = '${itemid}'`;
    const pr = dbPrice(db, fltP);
    // console.info(`s83#sqlPrice 22 fltP=${fltP} id=${JSON.stringify(pr)}`)
    if (pr?.length > 0 && (pr[0].price || 0) !== 0) {
        ok = true
        res.id = pr[0].id || "";
        res.qty = pr[0].qtty || 1;
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
        const fltL = `article = '${itemid}' AND acntno='${acntno || ""}'`
        const prlast = dbLast(db, fltL);
        if (prlast.length > 0) {
            res.id = "";
            // if (!res.qty) res.qty = 1;
            const priceBsc = (isAsk
                            ? (prlast.lastpricesell || prlast.bscprice || 0.0)
                            :(prlast.lastpricebuy || prlast.bscprice || 0.0) );
            res.bsc = priceBsc;
        }
    }
    // console.info(`iw9#sqlPrice 55 id=${JSON.stringify(res)}`)
    return res;
}

function sell(db, itemid) {
    if (!db || !itemid) return dummyPrice();

    const flt = `prbidask = -1 AND item = '${itemid}'`;

    const pr = dbPrice(db, flt);

    if (pr && pr.length > 0) {
        return pr[0];
    }

    return dummyPrice();
}

function buy(db, itemid) {
    if (!db || !itemid) return dummyPrice();

    const flt = `prbidask = 1 AND item = '${itemid}'`;

    const pr = dbPrice(db, flt);

    if (pr && pr.length > 0) {
        return pr[0];
    }

    return dummyPrice();
}

function currencyRates(db) {
    if (!db) return [];

    const flt = "item in (SELECT pkey FROM item WHERE itemmask & 2 AND folder=0)"

    const pr = dbPrice(db, flt);

    if (pr) {
        return pr;
    }

    return [];
}


/**
 *
 */
function dbPrice(db, flt = "") {
    if (!db) return null;

    const vsql = "SELECT id, item, prbidask, qtty, price FROM price "
               + "WHERE (prtype IS NULL OR prtype = '')" + (flt === "" ? "" : (" AND " + flt)) + ";";

    return db.dbSelectRowsJSON(vsql);
}

function dbOffer(db, flt = "") {
    if (!db) return [];
    const whereCondition = (flt = "" ? "" : `WHERE ${flt}`)
    const vsql = `
            SELECT
                article,
                qtty,
                price,
                pricetime
            FROM selloffer
            ${whereCondition};
            `

    return db.dbSelectRowsJSON(vsql);
}

function dbDsc(db, flt = "") {
    if (!db) return [];
    const whereCondition = (flt === "" ? "" : `WHERE ${flt}`)
    const vsql = `
            SELECT
                article,
                price,
                pricetime
            FROM selldsc
            ${whereCondition};
            `

    return db.dbSelectRowsJSON(vsql);
}

// last price from acntrade
function dbLast(db, flt = "") {
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
function updRate(db, price, qty, id, curid, ba) {
    if (!db) return 0;

    let vsql = "";
    let res = 0;

    // Перевіряємо наявність існуючого ID запису (id як рядок може прийти порожнім або "0")
    if (id !== undefined && id !== null && id !== "" && id !== "0") {
        // ✅ ВИПРАВЛЕНО CRASH-БАГ: Замість видаленого String().arg використовуємо сучасні шаблонні рядки
        vsql = `UPDATE price SET qtty = ${Number(qty || 1)}, price = ${Number(price || 0)} WHERE id = ${id};`;
        res = db.dbUpdate(vsql);
    } else {
        // Якщо курсу для цієї валюти ще не було в базі — робимо чистий INSERT
        // Поле prtype залишається NULL (як ми з'ясували, для комерційних курсів обмінника)
        const baVal = (ba || -1) > 0 ? "1" : "-1";
        vsql = `INSERT INTO price (item, qtty, price, prbidask) VALUES ('${curid}', ${Number(qty || 1)}, ${Number(price || 0)}, ${baVal});`;
        res = db.dbInsert(vsql);
    }

    return res;
}