.pragma library

const glCashPrefix = "30";
const glTradePrefix = "35";
const glDepoPrefix = "36";      // deposits
const glInitPrefix = "42";      // init capital
const glTradeEquivalentPrefix = "eqvl";
const glTradeResultPrefix = "rslt";
const TRADE_RESULT_PREFIX = "rslt";
const glBonusPrefix = "38";

const glDomesticCrn = "980";    // DEPRECATED, get fron conf.domestic instead
const zero = 0.0000001          // DEPRECATED

let TERM = "TEST";

function parse(raw){
    try {
        return JSON.parse(raw);
    } catch (err) {
        return null;
    }
}

function getBasic(db){
    const val = getVal(db, "term");
    TERM = val.id || "TEST";
    return val;
}
function setBasic(db, value){
    TERM = value?.id || "TEST";
    return setVal(db, "term", value);
}

function getREST(db){ return getVal(db, "rest"); }
function setREST(db, value){ return setVal(db, "rest", value); }

function getTAX(db){ return getVal(db, "tax"); }
function setTAX(db, value){ return setVal(db, "tax", value); }

function getAcntList(db){ return getVal(db, "acntlist"); }
function setAcntList(db, value){ return setVal(db, "acntlist", value); }

function getDomestic(db){ return getVal(db, "domestic"); }
function setDomestic(db, value){ return setVal(db, "domestic", value); }

function getVal(db, key, defaultValue) {
    if (defaultValue === undefined) defaultValue = null;
    if (!db || !key) return defaultValue;

    // Передаємо знак "?" у запит, а сам ключ — другим аргументом у масиві []
    const res = db.dbSelectRow("SELECT val FROM conf WHERE key = ?;", [key]);

    // Перевіряємо успішність (згідно з C++, успіх — це errid === 0)
    if (res && res.errid === 0 && res.val !== undefined && res.val !== null) {
        if (res.val === "") return "";

        const jres = parse(res.val);

        // Коректно повертаємо значення, навіть якщо розпарсилось логічне false або число 0
        return (jres !== false || res.val === "false" || res.val === "0") ? jres : res.val;
    }

    return defaultValue;
}

function setVal(db, key, value) {
    if (!db || !key) return false;

    // Перетворюємо складні типи (об'єкти, масиви) в JSON рядок,
    // а прості типи (числа, булеві) записуємо як є або через String
    let valToWrite = (typeof value === "object" && value !== null)
        ? JSON.stringify(value)
        : String(value);

    // SQL-запит з плейсхолдерами "?"
    const sql = "REPLACE INTO conf (key, val) VALUES (?, ?);";

    // Передаємо параметри масивом.
    // Оскільки REPLACE повертає rowid, dbInsert поверне ID створеного/заміненого рядка
    const ok = db.dbUpdate(sql, [key, valToWrite]);
    return ok;

    // const resultId = db.dbInsert(sql, [key, valToWrite]);
    // return resultId > 0;
}



// deprecated ? moved to sqlAcnt.js/createClientAcntNo
function getClntBonusAcntNo( clid ) {
    console.warn("!!! config.js, getClntBonusAcntNo is deprecated, moved to sqlAcnt.js/createClientAcntNo");
    const res = `${glBonusPrefix}00${clid || ""}`;
    return res;
}
