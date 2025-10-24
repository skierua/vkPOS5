.pragma library
/**
  JS library
  CashDesk
*/
var gl_host = "https://test.cashdesk.com.ua"
var gl_prefix = "/api/v2"
var gl_token = ""
var gl_cash = ""

function parse(raw){
    try {
        return JSON.parse(raw);
    } catch (err) {
        return false;
    }
}

function set(host, preffix){
    gl_host = host
    gl_prefix = preffix
}

function ping(callback) {
    const req = { "api_token": gl_token, "num_fiscal": gl_cash }
    // console.log("ping "+ JSON.stringify(req))
    postRequest("/shift/ping", req, callback)

}

function x_report(callback) {
    const req = { "api_token": gl_token, "num_fiscal": gl_cash, "action_type": "Z_REPORT" }
    postRequest("/shift/xReport", req, callback)

}

function z_report(callback) {
    const req = { "api_token": gl_token, "num_fiscal": gl_cash,"no_text_print": true,"no_pdf": true,"include_checks": false }
    postRequest("/shift", req, callback)

}

function postRequest(path, req, callback) {
    let request = new XMLHttpRequest();
    let  err = null, resp = null;
    const url = gl_host + gl_prefix + path
    request.onreadystatechange = function() {
        if (request.readyState === XMLHttpRequest.DONE) {
            if (request.status === 200) {
                let isPlainText = request.responseType === ''
                resp = parse(request.response)
                if (!isPlainText || !resp) {
                    err = "EE: Response error.\n" + request.response
                }
            } else if (request.status === 0){
                err = "EE: Site connection error"
            } else {
                err = "EE: URL: " + url
                        + "\nRequest: "+JSON.stringify(req)
                        + "\nResponse: "+request.response
            }

            callback(err,resp);
        }
    }
    request.open("POST", url);
    request.setRequestHeader("Content-Type","application/json");
    request.setRequestHeader("Accept","application/json");
    request.setRequestHeader("developer-id","linux,mppanna");
    request.send(JSON.stringify(req));
    // request.send("data=" + JSON.stringify(req));
}

/*
  /check/sale
  /shift/ping
  /shift/xReport
  /shift        // Z_REPORT
  */
