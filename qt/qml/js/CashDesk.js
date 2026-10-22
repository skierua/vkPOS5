.pragma library

.import "v147/config.js" as Conf
.import "v147/sqlBind.js" as LibBind
.import "v147/sqlItem.js" as LibItem
/**
  JS library
  CashDesk
*/

// sending is prohibited for debugging purposes
// sending sale, z_report is prohibited
// sending connect, ping, x_report is NOT prohibited
// raw postRequest is NOT prohibite !!!
// const BAN_SEND = true;
const BAN_SEND = false;

let HOST = "";
let API = "";
let CASH = "";
let TOKEN = "";
let IS_CONNECTED = false;


/*const DfltPingTimer = (() => {
    const intervalMs = 30 * 60 * 1000; // 30 minutes
    let pingTimer = null;

    return {
        start() {
            if (pingTimer) clearInterval(pingTimer);

            // Calls ping() every 30 minutes.
            pingTimer = setInterval(() => {
                ping((err, resp) => {}
                     );
            }, intervalMs);
        },
        stop() {
            if (pingTimer) {
                clearInterval(pingTimer);
                pingTimer = null;
            }
        }
    };
})();*/

function setParam(host, api, cash, token){
    HOST = host ? String(host) : "";
    API = api ? String(api) : "";
    CASH = cash ? String(cash) : "";
    TOKEN = token ? String(token) : "";
}

// main.js
function reset(){
    IS_CONNECTED = false;
    setParam();
}

// main.js
function restore(db){
    if (!db) return;

    const val = Conf.getTAX(db);
    if (!!val) setParam(val.host, val.api, val.cash, val.token)
    else setParam();
}

function save(db) {
    if (!db) return false;

    const paramData = {
        "host": String(HOST || ""),
        "api": String(API || ""),
        "cash": String(CASH || ""),
        "token": String(TOKEN || "")
    };

    return Conf.setTAX(db, paramData);
}

function parse(raw){
    try {
        return JSON.parse(raw);
    } catch (err) {
        return false;
    }
}

// AppSettings.qml
function ping(callback) {
    const path = "/shift/ping";
    const req = { "api_token": TOKEN, "num_fiscal": CASH };
    postRequest(path, req, callback);
}

// main.js
function connect(callback) {
    // DfltPingTimer.stop();
    IS_CONNECTED = false;

    if (!String(HOST || "").trim()
        || !String(API || "").trim()
        || !String(CASH || "").trim()
        || !String(TOKEN || "").trim()
        || String(HOST).startsWith("*")) {
        return;
    }

    ping((err, resp) => {
        if (err) {
            IS_CONNECTED = false;
            if (typeof callback === "function") {
                callback(true, err || "Невідома помилка мережі");
            }
        } else {
            // DfltPingTimer.start();
            IS_CONNECTED = true;
            // if (resp && resp.token) TOKEN = resp.token;

            if (typeof callback === "function") {
                callback(false, null);
            }
        }
    });
}

function ping(callback) {
    const path = "/shift/ping";
    const req = { "api_token": TOKEN, "num_fiscal": CASH }
    postRequest(path, req, callback)

}

// DEPRECATED, use sale() instead
/*function sendSaleToTax(db, dcmid, payType, callback){
    console.log("CashDesk.js/sendSaleToTax DEPRECATED, use sale() instead");
    // console.log(`01hs#CashDesk START dcmid=${dcmid}`);
    let  err = null, resp = null;
    let archive = false;
    let bind = LibBind.selDcmById(db, dcmid);
    if (!bind || bind?.errid || null) {
        err = bind?.errname || "Data retrieving error"
        archive = true;
        bind = LibBind.selDcmById(db, dcmid, archive);
    }
    // console.log(`id82#CashDesk ${JSON.stringify(bind)}`);
    if (!bind || bind?.errid || null) {
        err = bind?.errname || "Data retrieving error"
        callback(err,resp);
        return;
    }
    const dcmSource = LibBind.selDcmsByPid(db, dcmid, archive);
    if (!dcmSource || dcmSource?.errid || null) {
        err = dcmSource?.errname || "Data retrieving error"
        callback(err,resp);
        return;
    }
    let ok = (bind?.dcmtype || "") === "check";
    let articles = [];
    let total_eq = 0;
    for (let r = 0; ok && r < dcmSource.length; ++r) {
        const dcm = dcmSource[r];
        // console.log(`id82#CashDesk ${JSON.stringify(dcm)}`);
        const price = dcm.amount !== 0 ? Math.abs(Number(dcm.eqamount || 0)/Number(dcm.amount)) : 0;
        total_eq += Number(dcm.amount || 0);
        ok &= (dcm.dcmtype === "trade:sell");
        // ok &= (Number(dcm.mask || 0) === 4); // Маска 4 — роздрібні товари (Goodies)
        ok &= Number(dcm.amount || 0) < 0;
        ok &= (Number(dcm.eqamount || 0) < 0);

        articles.push({
            "unit_code": dcm.unitcode ?? "",
            "unit_name": dcm.unitchar ?? "",
            "name": dcm.itemchar ?? "",
            "amount": Math.abs(dcm.amount).toFixed(dcm.unitprec || 2),
            "price": price.toFixed(3),
            "cost": Math.abs(dcm.eqamount || 0).toFixed(2),
            "sum_discount": Math.abs(dcm.discount || 0).toFixed(2)
        });
    }

    if (!ok){
        err = "TAX serialization error"
        callback(err,resp);
        return;
    }


    // CashDesk.js (додаємо параметр payType, наприклад: "cash" або "card")
    // payType може приходити з інтерфейсу вибору оплати
    const isCash = (payType === "cash" || payType === 0);

    // 1. Чиста сума товарів у копійках без жодних округлень
    const totalEqCents = Math.round(Math.abs(total_eq) * 100);
    const pure_total_val = totalEqCents / 100;

    // 2. Розраховуємо копійки з урахуванням типу оплати (НБУ тільки для готівки!)
    const totalSumCents = isCash ? (Math.round(totalEqCents / 10) * 10) : totalEqCents;

    const total_sum_val = totalSumCents / 100;
    const round_sum_val = (totalSumCents - totalEqCents) / 100;

    // 3. Динамічно формуємо масив платежів під ПРРО
    let paymentsArray = [];
    if (isCash) {
        paymentsArray.push({
            "code": 0,
            "name": "ГОТIВКА",
            "sum": pure_total_val.toFixed(2), // Сума товарів до округлення
            "sum_provided": total_sum_val.toFixed(2), // Фактично отримано
            "sum_remains": "0.00"
        });
    } else {
        paymentsArray.push({
            "code": 1, // Код 1 або 2 залежно від налаштувань вашого ПРРО шлюзу для безготівки
            "name": "КАРТКА",
            "sum": total_sum_val.toFixed(2), // Для картки сума платежу = сумі товарів
            "sum_provided": total_sum_val.toFixed(2),
            "sum_remains": "0.00"
        });
    }

    const taxbind = {
        "action_type": "Z_SALE",
        "local_number": dcmid,
        "total_sum": total_sum_val.toFixed(2),  // Для готівки — округлена, для картки — точна
        "round_sum": round_sum_val.toFixed(2),  // Для картки тут автоматично вийде "0.00"
        "products": articles,
        "payments": paymentsArray,
        "no_text_print": true,
        "no_pdf": true,
        "no_qr": true,
        "open_shift": true,
        "print_width": 32,
        "pdf_width": 48
    };


    // console.log(`kq5d#CashDesk ok=[${ok}] ${JSON.stringify(taxbind)}`); return;
    if (taxbind && taxbind.products.length > 0) {
        sale(taxbind, (e, r) =>{
                 if (e) err = `TAX server error. ${e || ""}`;
                 else {
                     // const setVal = `dcmtype = 'taxchek', dcmnote = ${r}`;
                     const updateData = {
                                     "dcmtype": "taxchek",
                                     "dcmnote": String(r)
                                 };
                     // const uOk = LibBind.updDocum(db, dcmid, setVal);
                     const uOk = LibBind.updDocum(db, dcmid, updateData);
                     if (!uOk) err = db.dbLastError();
                     resp = r;
                 }
             })
    } else {
        err = "TAX serialization error"
    }
    callback(err,resp);
}
*/

function bindToSale(db, dcmid, payType) {
    let archive = false;
    let bind = LibBind.selDcmById(db, dcmid);
    if (!bind || bind?.errid || null) {
        archive = true;
        bind = LibBind.selDcmById(db, dcmid, archive);
    }
    if (!bind || bind?.errid || null) {
        return null;
    }
    const dcmSource = LibBind.selDcmsByPid(db, dcmid, archive);
    if (!dcmSource || dcmSource?.errid || null) {
        return null;
    }
    // console.log(`II: 83yg#CashDesk ${JSON.stringify(dcmSource)}`);
    let ok = (bind?.dcmtype || "") === "check";
    let articles = [];
    let total_eq = 0;
    for (let r = 0; ok && r < dcmSource.length; ++r) {
        const dcm = dcmSource[r];
        const article = LibItem.getItemById(db, dcm.itemid);
        ok &= (!!article.id ?? false);
        // console.log(`id82#CashDesk ${JSON.stringify(dcm)}`);
        const price = dcm.amount !== 0 ? Math.abs(Number(dcm.eqamount || 0)/Number(dcm.amount)) : 0;
        total_eq += Number(dcm.eqamount || 0);
        ok &= (dcm.dcmtype === "trade:sell");
        // ok &= (Number(dcm.mask || 0) === 4); // Маска 4 — роздрібні товари (Goodies)
        ok &= Number(dcm.amount || 0) < 0;
        ok &= (Number(dcm.eqamount || 0) < 0);

        articles.push({
            "unit_code": article.unitcode ?? "",
            "unit_name": article.unitchar ?? "",
            "name": article.itemchar ?? "",
            "amount": Math.abs(dcm.amount).toFixed(dcm.unitprec || 2),
            "price": price.toFixed(3),
            "cost": Math.abs(dcm.eqamount || 0).toFixed(2),
            "sum_discount": Math.abs(dcm.discount || 0).toFixed(2)
        });
    }

    if (!ok){
        return null;
    }
    // console.log(`II: u2y#CashDesk ${total_eq}`);

    // CashDesk.js (додаємо параметр payType, наприклад: "cash" або "card")
    // payType може приходити з інтерфейсу вибору оплати
    const isCash = (payType === "cash" || Number(payType || 0) === 0);

    // 1. Чиста сума товарів у копійках без жодних округлень
    const totalEqCents = Math.round(Math.abs(total_eq) * 100);
    const pure_total_val = totalEqCents / 100;

    // 2. Розраховуємо копійки з урахуванням типу оплати (НБУ тільки для готівки!)
    const totalSumCents = isCash ? (Math.round(totalEqCents / 50) * 50) : totalEqCents;

    const total_sum_val = totalSumCents / 100;
    const round_sum_val = (totalSumCents - totalEqCents) / 100;

    // 3. Динамічно формуємо масив платежів під ПРРО
    let paymentsArray = [];
    if (isCash) {
        paymentsArray.push({
            "code": 0,
            "name": "ГОТIВКА",
            "payment_method": "готівка",
            "sum": total_sum_val,
            "sum_provided": total_sum_val, // Фактично отримано
            // "sum": pure_total_val.toFixed(2), // Сума товарів до округлення
            // "sum_provided": total_sum_val.toFixed(2), // Фактично отримано
            "sum_remains": "0.00"
        });
    } else {
        paymentsArray.push({
            "code": 1, // Код 1 або 2 залежно від налаштувань вашого ПРРО шлюзу для безготівки
            "name": "КАРТКА",
            "payment_method": "безготівка",
            "sum": total_sum_val, // Для картки сума платежу = сумі товарів
            "sum_provided": total_sum_val,
            "sum_remains": "0.00"
        });
    }

    const taxbind = {
        "api_token": TOKEN,
        "num_fiscal": CASH,
        "action_type": "Z_SALE",
        "local_number": dcmid,
        "total_sum": total_sum_val,  // Для готівки — округлена, для картки — точна
        "round_sum": round_sum_val,  // Для картки тут автоматично вийде "0.00"
        "round_rule": 50,
        "products": articles,
        "payments": paymentsArray,
        "no_text_print": true,
        "no_pdf": true,
        "no_qr": true,
        "open_shift": true,
        "print_width": 32,
        "pdf_width": 48
    };

    return taxbind;
}

// bind.js
function sale(db, dcmid, payType, callback) {
    // data.api_token = TOKEN
    // data.num_fiscal = CASH
    // console.warn(`WW: CashDesk.js/sale TAX is blocked !!!`);
    // return;
    if (!dcmid || Number(dcmid || -1) < 0) {
        callback("Id for document is missing", null);
        return;
    }
    const bind = bindToSale(db, dcmid, String(payType || 0));   // cash default
    if (!bind) {
        callback("Bind serialization error", null);
        return;
    }

    if (BAN_SEND) {
    // debug info
        console.warn("TAX.send is PROHIBITED (BAN_SEND = true) !!!")
    } else {
        postRequest(`/check/sale?api_token=${TOKEN}`, bind, callback)
    }
}

// AppSettings.qml
function x_report(callback) {
    const req = {
        "api_token": TOKEN,
        "num_fiscal": CASH,
        "no_text_print": true,
        "no_pdf": true,
    }
    postRequest("/shift/xReport", req, callback)

}

// main.js, AppSettings.qml
function z_report(callback) {
    const req = {
        "api_token": TOKEN,
        "num_fiscal": CASH,
        "action_type": "Z_REPORT",
        "no_text_print": true,
        "no_pdf": true,
        "include_checks": false,
    }
    // console.warn(`WW: CashDesk.js/z_report TAX is blocked !!!`);
    // return;
    if (BAN_SEND) {
    // debug info
        console.warn("WW: TAX.z_report send is PROHIBITED (BAN_SEND = true) !!!")
    } else {
        postRequest("/shift", req, callback)
    }
}

// /api/v2/checks/f301ab5f-21a4-491e-83ce-396fa2a47cbe/pdf?api_token=42b5eaccba739f08***e7fe157eba8bf&pdf_width=80
function getCheckPdf(uuid, width, callback) {
    const widthVal = String(width || "80");
    const path = `/checks/${uuid}/pdf?api_token=${TOKEN}&pdf_width=${widthVal}`;
    getRequest(path, callback)
}

function postRequest(path, req, callback) {
    // console.log("[libTAX] data=" + JSON.stringify(req)); return;
    // console.log(`CashDesk.js/postRequest req=${JSON.stringify(req)}`)
    // callback(null,`Ok sendToTax ${JSON.stringify(req)}`);
    // return;

    let request = new XMLHttpRequest();
    let  err = null, resp = null;
    const url = HOST + API + path
    // console.log(`CashDesk.js/postRequest url=${url}`)
    // console.info(`II: CashDesk.js#666 ${request.readyState}`)
    request.onreadystatechange = function() {
        // console.info(`II: CashDesk.js#555 ${request.readyState}`)
        // console.info(`II: CashDesk.js#7777 status=${request.status} ${request.response}`)
        if (request.readyState === XMLHttpRequest.DONE) {
            if (request.status === 200) {
                let isPlainText = request.responseType === ''
                resp = parse(request.response)
                if (!isPlainText || !resp) {
                    err = request.response
                }
            } else if (request.status === 403){
                err = request.response
            } else if (request.status === 0){
                err = "Site connection error"
            } else {
                console.error(`EE: CashDesk.ls/postRequest\n${JSON.stringify(req)}`);
                err = request.response
            }
            // console.log(`CashDesk.js/postRequest request=${JSON.stringify(request)}`)
            callback(err,request.response);
        }
    }

    request.open("POST", url);
    request.setRequestHeader("Content-Type","application/json");
    request.setRequestHeader("Accept","application/json");
    request.setRequestHeader("developer-id","linux,mppanna");
    // console.warn(`WW: CashDesk.js#111 send id BLOCKED !!!`)
    request.send(JSON.stringify(req));
    // request.send("data=" + JSON.stringify(req));
}

function getRequest(path, callback) {

    let request = new XMLHttpRequest();
    let  err = null, resp = null;
    const url = HOST + API + path
    console.log(`CashDesk.js/getRequest url=${url}`)
    request.onreadystatechange = function() {
        // console.info(`II: CashDesk.js#555 ${request.readyState}`)
        // console.info(`II: GET CashDesk.js#1234 ${request.responseText}`)
        if (request.readyState === XMLHttpRequest.DONE) {
            if (request.status === 200) {
                resp = request.response;
                // resp = Qt.atob(request.response);
            } else {
                // console.error(`EE: CashDesk.ls/postRequest\n${JSON.stringify(request)}`);
                err = request.response
            }
            // console.log(`CashDesk.js/getRequest resp=${resp}`)
            callback(err, resp);
        }
    }

    request.open("GET", url);
    request.setRequestHeader("Content-Type","application/json");
    request.setRequestHeader("Accept","application/json");
    request.setRequestHeader("developer-id","linux,mppanna");
    request.send();
}

/*
  /check/sale
  /shift/ping
  /shift/xReport
  /shift        // Z_REPORT
  */

