.pragma library
/**
  JS library
*/
var gl_host = ""
var gl_api =  ""
var gl_token = ""

/* function log(vstring, vmodule, vtype) {
    if (vtype === undefined) { vtype = 'II'}
    if (vmodule === undefined) { vmodule = '???main.qml'}
    console.log(String("%1[%2]: %3").arg(vtype).arg(vmodule).arg(vstring))
} */

function parse(raw){
    try {
        return JSON.parse(raw);
    } catch (err) {
        return false;
    }
}

function connected(){
    return (gl_token !== "");
}

/* function ping(callback) {
    const req = { "api_token": gl_token, "num_fiscal": gl_cash }
    // console.log("ping "+ JSON.stringify(req))
    postRequest("/shift/ping", req, callback)

} */

function login(usr, psw, callback) {
    loginRequest(usr, psw, (err, token) => {
                     // console.log("libREST token=" + token)
                     if (err === null){
                         gl_token = token
                         callback(null)
                     } else {
                         gl_token = ""
                         // Lib.log(err.text, 'lib.login', err.code)
                         callback(err.text)
                         // callback("Login failed")
                     }
                 });
}

function loginRequest(usr, psw, callback) {
    let request = new XMLHttpRequest();
    let  err = null, resp = null;
    const url = gl_host + gl_api + "/auth"
    request.onreadystatechange = function() {
        if (request.readyState === XMLHttpRequest.DONE) {
            // log( "responseType="+request.responseType )
            // console.log( "#1267 libREST response="+request.response )
            if (request.status === 200) {
                let isPlainText = request.responseType === ''
                let presp = parse(request.response)
                if (isPlainText && presp) {
                    resp = presp.token
                }
            } else if (request.status === 0){
                err = {text:'loginRequest. Site connection error', code:'EE'}
            } else {
                // TODO off online mode
                err = {text:url + "\nU:"+usr+" P:"+psw+"\n"+request.response, code: 'EE'}
            }

            callback(err, resp);
        }
    }

    let jdata = { "usr": usr, "psw": psw }
    let v64 = Qt.btoa(JSON.stringify(jdata));
    // console.log("json="+JSON.stringify(jdata)+" ba v64="+v64)
    request.open("POST", url);
    request.setRequestHeader("Content-Type","application/x-www-form-urlencoded");
    // request.send("usr="+usr+"&psw="+psw);
    request.send("data=" + v64);
}

function uploadBind(req, callback) {
    postRequest("/dcms", req, (err, resp) => { callback(err); });
}

function uploadBalance(req, callback) {
    postRequest("/accounts", req, (err, resp) => { callback(err); });
}

function uploadBindTran(term, shop, dcms, acnts, callback) {
    let req = {"term": term,"reqid":"upd", "shop": term,"data":dcms}
    uploadBind(req,
               (err) => { if (err === null) {
                   if (acnts !== undefined && acnts.length !== 0) {
                       req = {"term": term,"reqid":"upd", "shop": term,"data":acnts}
                       uploadBalance(req, (berr) => { callback(berr) } )
                   } else callback(err)
               } else {
                   callback(err)
               } })
}

function postRequest(path, req, callback) {
    let request = new XMLHttpRequest();
    let  err = null, resp = null;
    const url = gl_host + gl_api + path + "?api_token=" + gl_token

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
                err = "EE: Site connection error"
            } else {
                err = "EE: URL: "+ url + "\nRequest: "+JSON.stringify(req)+"\nResponse: "+request.response
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

/*
  "/dcms?api_token="+resttoken
  "/accounts?api_token="+resttoken.  {"term":root.term,"reqid":"upd","shop":root.term,"data":jacnt.rows}
  "/accounts?api_token="+resttoken.  {"term":root.term,"reqid":"del","shop":root.term}

  */

