.pragma library
.import "v147/config.js" as Conf

// sending is prohibited for debugging purposes
// sending uploadBind, uploadBalance is prohibited
// sending connect, loginRequest, loadRates is NOT prohibited
// const BAN_SEND = true;
const BAN_SEND = false;

let HOST = "https://test.kantorfk.com";
let API = "/api/v5";
let USER = "";
let PSW = "";
let TOKEN = "";
let isConnected = false;

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
function reset(db) {
    isConnected = false;
    setParam()

    if (!db) return;

    const val = Conf.getREST(db);
    if (!val) return;
    setParam(val.host, val.api, val.user, val.psw, val.token)
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

function loadRates(req, callback) {
    // console.info(`II: libREST.js req=${req}`)
    postRequest("/rates", req, (err, resp) => { callback(err, resp); });
}

function uploadBind(req, callback) {
    if (BAN_SEND) {
    // debug info
        console.warn("WW: REST.uploadBind is PROHIBITED (BAN_SEND = true) !!!")
        console.warn(`WW: REST.uploadBind req=${JSON.stringify(req)}`)
    } else {
        postRequest("/dcms", req, (err, resp) => { callback(err); });
    }

}
function uploadBalance(req, callback) {
    // console.warn(`WW: libREST.js/uploadBalance BLOKKED !!!`); return;
    if (BAN_SEND) {
    // debug info
        console.warn("WW: REST.uploadBalance is PROHIBITED (BAN_SEND = true) !!!")
        // console.warn(`WW: REST.uploadBalance req=${JSON.stringify(req)}`)
    } else {
        postRequest("/accounts", req, (err, resp) => { callback(err); });
    }

}

// deprecated
function uploadBindTran(term, shop, dcms, acnts, callback) {
    console.warn(`WW: libREST.js/uploadBindTran DEPRECATED BLOKKED !!!`);
    return;
    let req = { "term": term, "reqid": "upd", "shop": term, "data": dcms };
    uploadBind(req, (err) => {
        if (err === null) {
            if (acnts !== undefined && acnts.length !== 0) {
                req = { "term": term, "reqid": "upd", "shop": term, "data": acnts };
                uploadBalance(req, (berr) => { callback(berr); });
            } else {
                callback(err);
            }
        } else {
            callback(err);
        }
    });
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
            // console.log(`libREST request.status=${request.status}`)
            // console.log(`libREST request.status=${request.response}`)
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
            // console.log(`libREST resp=${JSON.stringify(resp)}`)
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
    console.log("REST postRequest2 using noticed")
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

