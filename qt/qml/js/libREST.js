.pragma library
.import "v147/config.js" as Conf

let HOST = "https://test.kantorfk.com";
let API = "/api/v5";
let USER = "";
let PSW = "";
let TOKEN = "";
let isConnected = false;

// var gl_host = ""
// var gl_api =  ""
// var gl_token = ""

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

/*const Param = (() => {
    const db_key = "rest";

    let v_url = null;
    let v_api = null;
    let v_token = null;
    let v_user = null;
    let v_psw = null;

    // Створюємо об'єкт інтерфейсу
    const apiInstance = {
        reset(db) {
            v_url = null;
            v_api = null;
            v_token = null;
            v_user = null;
            v_psw = null;

            if (!db) return;

            // Чистий виклик з бази даних без друкарських помилок
            const val = Conf.getREST(db);
            if (!val) return;

            apiInstance.setUrl(val.host ? String(val.host) : "");
            apiInstance.setApi(val.api ? String(val.api) : "");
            apiInstance.setLogin(
                val.user ? String(val.user) : "",
                val.psw ? String(val.psw) : ""
            );
        },

        save(db) {
            if (!db) return false;

            const paramData = {
                "host": String(v_url || ""),
                "api": String(v_api || ""),
                "user": String(v_user || ""),
                "psw": String(v_psw || "")
            };

            return Conf.setREST(db, paramData);
        },

        // --- Сетери (Встановлення значень) ---
        setUrl(val) { v_url = val; },
        setApi(val) { v_api = val; },
        setToken(val) { v_token = val; },
        setLogin(userVal, pswVal) {
            v_user = userVal;
            v_psw = pswVal;
        },

        // --- Гетери (Отримання значень) ---
        url() { return v_url; },
        api() { return v_api; },
        token() { return v_token; },
        user() { return v_user; },
        psw() { return v_psw; }
    };

    return apiInstance;
})();
*/

function parse(raw) {
    try {
        return JSON.parse(raw);
    } catch (err) {
        return false;
    }
}


// DEPRECATED, use connect instead
function login(callback) {
    console.log("libREST.js/login DEPRECATED, use connect instead")
    loginRequest(Param.user(), Param.psw(), (err, token) => {
        if (err === null) {
            Param.setToken(token);
            TOKEN = token;
            callback(null);
        } else {
            TOKEN = "";
            callback(err.text);
        }
    });
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
    postRequest("/rates", req, (err, resp) => { callback(err, resp); });
}

function uploadBind(req, callback) {
    console.log(`WW: libREST.js/uploadBind BLOKKED !!!`); return;
    postRequest("/dcms", req, (err, resp) => { callback(err); });
}
function uploadBalance(req, callback) {
    console.log(`WW: libREST.js/uploadBalance BLOKKED !!!`); return;
    postRequest("/accounts", req, (err, resp) => { callback(err); });
}

// deprecated
function uploadBindTran(term, shop, dcms, acnts, callback) {
    console.log(`WW: libREST.js/uploadBindTran DEPRECATED BLOKKED !!!`); return;
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

    console.log("REST.postRequest send is BLOCKED !!!")
    // console.log(`${JSON.stringify(req)}`)
    // request.send("data=" + encodeURIComponent(JSON.stringify(req)));
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
    request.open("PATCH", url);
    request.setRequestHeader("Content-Type","application/x-www-form-urlencoded");
    request.setRequestHeader("Bearer",token);
    // request.send("term="+term+"&reqid=curAmnt&acnt=" + crntacnt);
    request.send("data=" + Qt.btoa(JSON.stringify(req)));
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
    request.open("POST", url);
    request.setRequestHeader("Content-Type","application/x-www-form-urlencoded");
    // request.setRequestHeader("Content-Type","multipart/form-data");
    request.setRequestHeader("Accept","application/json");
    // request.setRequestHeader("Bearer",token);
    // request.send("data=" + Qt.btoa(JSON.stringify(req)));
    request.send("data=" + JSON.stringify(req));
}

/*
  "/dcms?api_token="+resttoken
  "/accounts?api_token="+resttoken.  {"term":root.term,"reqid":"upd","shop":root.term,"data":jacnt.rows}
  "/accounts?api_token="+resttoken.  {"term":root.term,"reqid":"del","shop":root.term}

  */

