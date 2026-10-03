.pragma library
.import "v147/config.js" as Conf
.import "v147/sqlBalance.js" as LibBal
.import "v147/sqlRepo.js" as LibRepo

// sending is prohibited for debugging purposes
// sending uploadBind, uploadBalance is prohibited
// sending connect, loginRequest, loadRates is NOT prohibited
// const BAN_SEND = true;
const BAN_SEND = false;

// REST API
// POST
// /auth
// /accounts upd
// /dcms upd
// /rates sel
// /reports updprofit?

// GET

let HOST = "https://test.kantorfk.com";
let API = "/api/v5";
let USER = "";
let PSW = "";
let TOKEN = "";
let IS_CONNECTED = false;
let isConnected = false;    // DEPRECATED, use IS_CONNECTED instead
let BALANCE_SYNC = new Date().toISOString();

function setParam(host, api, user, psw, token){
    HOST = !!host ? String(host) : "";
    API = !!api ? String(api) : "";
    USER = !!user ? String(user) : "";
    PSW = !!psw ? String(psw) : "";
    TOKEN = !!token ? String(token) : "";
}

/**
 * Скидання та вичитування актуальних налаштувань підключення з бази SQLite
 * @param {Object} db - Драйвер бази даних
 */
function reset() {
    IS_CONNECTED = false;
    isConnected = false;
    setParam();
}

function restore(db) {
    if (!db) return;

    const val = Conf.getREST(db);
    if (!!val) setParam(val.host, val.api, val.user, val.psw, val.token);
    else setParam();
}

function setBalanceSync(tm){
    const tmVal = String(tm || "");
    BALANCE_SYNC = tmVal;
}

/**
 * Збереження поточних параметрів мережі у базу даних SQLite
 * @param {Object} db - Драйвер бази даних
 * @returns {boolean} - Результат транзакції збереження
 */
function save(db) {
    if (!db) return false;

    const paramData = {
        "host": String(HOST || ""),
        "api": String(API || ""),
        "user": String(USER || ""),
        "psw": String(PSW || ""),
        "token": String(TOKEN || ""),
    };

    return Conf.setREST(db, paramData);
}

function connect(callback) {
    TOKEN = "";
    IS_CONNECTED = false;
    isConnected = false;
    if(!String(HOST || "")
        || !String(API || "")
        // && !!String(USER || "")
        // && !!String(PSW || "")
        || String(HOST).startsWith("*")
        ){
        if (typeof callback === "function")  callback(true, "Помилка параметрів");
        return false;
    }

    loginRequest(USER, PSW, (err, token) => {
        if (!err) {
            TOKEN = token;
            IS_CONNECTED = true;
            isConnected = true;
            if (typeof callback === "function") callback(false, null);
            return true;
        } else {
            if (typeof callback === "function")  callback(true, err || "Невідома помилка мережі");
            return false;
        }
    });
}

function parse(raw) {
    try {
        return JSON.parse(raw);
    } catch (err) {
        return false;
    }
}

function loginRequest(usr, psw, callback) {
    const request = new XMLHttpRequest();
    let err = null, resp = null;
    const url = HOST + API + "/auth";

    request.onreadystatechange = () => {
        if (request.readyState === XMLHttpRequest.DONE) {
            if (request.status === 200) {
                const presp = parse(request.response);
                if (presp) {
                    resp = presp.token || (presp.rslt ? presp.rslt.token : null);
                    if (!resp) {
                        err = "Token missing in server response";
                    }
                } else {
                    err = "Invalid JSON response from server";
                }
            } else if (request.status === 0) {
                err = "Site connection error";
            } else {
                err = `${url}\nUser:${usr} Psw:${psw}\n${request.response}`;
            }
            callback(err, resp);
        }
    };

    const jdata = { "usr": usr, "psw": psw };
    const v64 = Qt.btoa(JSON.stringify(jdata));

    request.open("POST", url);
    request.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
    request.send("data=" + encodeURIComponent(v64));
}

// rate.js
function loadRates(callback) {
    const req = {
        "term": Conf.TERM ?? "TEST",
        "reqid": "selrate",
        "shop": Conf.TERM ?? "TEST"
    }
    // console.info(`II: libREST.js req=${JSON.stringify(req)}`)
    postRequest("/app_api", req, (err, resp) => { callback(err, resp); });
}

function uploadBind(bind, callback) {
    const currentTerm = String(Conf.TERM || "TEST");
    const currentShop = currentTerm;
    const req = { "reqid": "upddcm", "term": currentTerm, "shop": currentShop, "data": bind }
    if (BAN_SEND) {
    // debug info
        console.warn("WW: REST.uploadBind is PROHIBITED (BAN_SEND = true) !!!")
        // console.warn(`WW: REST.uploadBind req=${JSON.stringify(req)}`)
        callback(null);
    } else {
        postRequest("/app_api", req, (err, resp) => { callback(err); });
    }
}

// is using in: bind.js, shift.js, AppSettings.qml
function uploadBalance(db, callback) {
    // console.warn(`WW: libREST.js/uploadBalance BLOKKED !!!`); return;
    // console.info(`II: libREST.js/uploadBalance BALANCE_SYNC=${BALANCE_SYNC}`)
    const currentTerm = String(Conf.TERM || "TEST");
    const currentShop = currentTerm;
    const source = LibBal.balanceForUpload(db, BALANCE_SYNC);
    const l_round4 = (num) => Math.round((Number(num) || 0) * 10000) / 10000;
    const cleanData = source.map(v => {
        // Створюємо копію об'єкта, сумісну навіть зі старим QML
        const cleanItem = {
                         "acntno": v.acntno,
                         "amnt": l_round4(v.total),
                         "articleid": v.itemid,
                         "tm": v.intm < v.outm ? v.outm : v.intm,
                         "turncdt":  l_round4(v.outcome),
                         "turndbt": l_round4(v.income),
                     }

        return cleanItem;
    });
    if (!cleanData.length){ // NOTHING TO DO
        return;
    }

    const req = { "reqid": "updacnt",
        "term": currentTerm,
        "shop": currentShop,
        "del": !BALANCE_SYNC ? "1" : "0",
        "data": cleanData }
    if (BAN_SEND) {
    // debug info
        console.warn("WW: REST.uploadBalance is PROHIBITED (BAN_SEND = true) !!!")
        console.warn(`WW: REST.uploadBalance req=${JSON.stringify(req)}`)
        setBalanceSync(new Date().toISOString());
    } else {
        // postRequest("/accounts", req, (err, resp) => {
        postRequest("/app_api", req, (err, resp) => {
                        if (!err){
                            // console.info(`II: REST.uploadBalance#w89 callback  BALANCE_SYNC=${BALANCE_SYNC}`)
                            setBalanceSync(new Date().toISOString());
                        }
                        if (typeof callback === "function") callback(err, null);
                    });
    }

}

function uploadMonRepo(db, vdate = new Date().toISOString(), callback) {
    if (!db) return [];
    const vdateT = !!vdate ? vdate.trim() : "";
    const period =  (!vdateT || !Date.parse(vdateT) || vdateT.length < 7)
                 ? new Date().toISOString().substring(0, 7)
                 : vdateT.substring(0, 7);
    const source = LibRepo.monProfit(db, period);
    const repo = source.map(v => {
           const parts = v.acnt.split(/\.|\//);
           if (!parts[1] || !parts[2] ) return null;
           return {
              "itemid": parts[2] || "",
              "acnt": parts[1] || "",
              "amnt": Math.round(v.amnt),
              "cshr": v.cshr || ""}
        });
    if (!repo || !repo.length) {
        callback("Nothing to upload");
        return;
    };
    const crnterm = String(Conf.TERM || "TEST");
    const repoReq = { "reqid": "updprofit",
        "term": crnterm,
        "shop": crnterm,
        "period": period,
        "data": repo }
    if (BAN_SEND) {
    // debug info
        console.warn("WW: REST.uploadMonRepo is PROHIBITED (BAN_SEND = true) !!!")
        console.warn(`WW: REST.uploadMonRepo req=${JSON.stringify(repoReq)}`)
    } else {
        // console.warn(`WW: REST.uploadMonRepo req=${JSON.stringify(repoReq)}`)
        postRequest("/app_api", repoReq, (err, resp) => { callback(err); });
        // postRequest("/reports", repoReq, (err, resp) => { callback(err); });
    }

}

function postRequest(path, req, callback) {
    const request = new XMLHttpRequest();
    let err = null, resp = null;

    // Надійний парсинг версії (наприклад, з "/api/v5" дістаємо число 5)
    const apiVersionMatch = API.match(/\/v(\d+)/);
    const apiVersion = apiVersionMatch ? parseInt(apiVersionMatch[1], 10) : 4;
    const isLegacyApi = (apiVersion < 5);

    let url = HOST + API + path;
    if (isLegacyApi) {
        url += "?api_token=" + encodeURIComponent(TOKEN);
    }
// console.log(`libREST url=${url}\nreq=${JSON.stringify(req)}`)
    request.onreadystatechange = () => {
        if (request.readyState === XMLHttpRequest.DONE) {
            // console.log(`libREST/postRequest request.status=${request.status}`)
            // console.log(`libREST#5er request.status=${request.response}`)
            if (request.status === 200) {
                const presp = parse(request.response);
                if (presp) {
                    if (presp.status !== undefined && presp.status !== 0) {
                        err = `EE: Server Error: ${presp.str || "Unknown error"} (Code: ${presp.status})`;
                    } else {
                        // console.log(`libREST OK `)
                        resp = presp.rslt !== undefined ? presp.rslt : presp;
                        // console.log(`libREST resp=${JSON.stringify(resp)}`)
                    }
                } else {
                    err = "EE: Failed to parse JSON response";
                }
            } else if (request.status === 401) {
                err = "EE: 401 Unauthorized. Session expired";
            } else if (request.status === 0) {
                err = "EE: Site connection error (Offline)";
            } else {
                err = `EE: URL: ${url}\nRequest: ${JSON.stringify(req)}\nResponse: ${request.response}`;
            }
            // console.log(`libREST#7et3 err=${err} resp=${JSON.stringify(resp)}`)
            callback(err, resp);
        }
    };

        request.open("POST", url);
        request.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
        request.setRequestHeader("Accept", "application/json");

        if (!isLegacyApi && TOKEN !== "") {
            request.setRequestHeader("Authorization", "Bearer " + TOKEN);
        }

        // console.log(`${JSON.stringify(req)}`)
        request.send("data=" + encodeURIComponent(JSON.stringify(req)));

}

// DEPRECATED
function patchRequest(url, req, token, callback) {
    let request = new XMLHttpRequest();

    request.onreadystatechange = function() {
        if (request.readyState === XMLHttpRequest.DONE) {
            let response = {
                status : request.status,
                headers : request.getAllResponseHeaders(),
                contentType : request.responseType,
                content : request.response
            };

            callback(response);
        }
    }

    if (BAN_SEND) {
    // debug info
        console.warn("WW: REST.patchRequest send is PROHIBITED (BAN_SEND = true) !!!")
    } else {
        request.open("PATCH", url);
        request.setRequestHeader("Content-Type","application/x-www-form-urlencoded");
        request.setRequestHeader("Bearer",token);
        // request.send("term="+term+"&reqid=curAmnt&acnt=" + crntacnt);
        request.send("data=" + Qt.btoa(JSON.stringify(req)));
    }
}

function getRequest(url, path, query, callback) {
    let request = new XMLHttpRequest();

    request.onreadystatechange = function() {
        if (request.readyState === XMLHttpRequest.DONE) {
            let response = {
                status : request.status,
                headers : request.getAllResponseHeaders(),
                contentType : request.responseType,
                content : request.response
            };

            callback(response);
        }
    }
    request.open("GET", url+path + (query === undefined ? '' : ("?"+query)));
    request.send();
}

function postRequest2(url, req, callback) {
    console.log("WW: DEPRECATED REST postRequest2 using noticed")
    let request = new XMLHttpRequest();
    let  err = null, resp = null;

    request.onreadystatechange = function() {
        if (request.readyState === XMLHttpRequest.DONE) {
            // log( "responseType="+request.responseType )
            // log( "response="+request.response )
            if (request.status === 200) {
                let isPlainText = request.responseType === ''
                let presp = parse(request.response)
                if (isPlainText && presp) {
                    resp = presp.rslt
                }
            } else if (request.status === 0){
                err = {text:'Site connection error', code:'EE'}
            } else {
                err = {text:"URL: "+ url + "\nRequest: "+JSON.stringify(req)+"\nResponse: "+request.response, code: 'EE'}
            }

            callback(err, resp);
        }
    }

    if (BAN_SEND) {
    // debug info
        console.warn("WW: REST.postRequest2 send is PROHIBITED (BAN_SEND = true) !!!")
    } else {
        request.open("POST", url);
        request.setRequestHeader("Content-Type","application/x-www-form-urlencoded");
        // request.setRequestHeader("Content-Type","multipart/form-data");
        request.setRequestHeader("Accept","application/json");
        // request.setRequestHeader("Bearer",token);
        // request.send("data=" + Qt.btoa(JSON.stringify(req)));
        request.send("data=" + JSON.stringify(req));
    }
}

/*
  "/dcms?api_token="+resttoken
  "/accounts?api_token="+resttoken.  {"term":root.term,"reqid":"upd","shop":root.term,"data":jacnt.rows}
  "/accounts?api_token="+resttoken.  {"term":root.term,"reqid":"del","shop":root.term}

  */

