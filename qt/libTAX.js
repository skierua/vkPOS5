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

// function set(host, preffix){
//     gl_host = host
//     gl_prefix = preffix
// }

function ping(callback) {
    const req = { "api_token": gl_token, "num_fiscal": gl_cash }
    // console.log("ping "+ JSON.stringify(req))
    postRequest("/shift/ping", req, callback)

}

function sale(data, callback) {
    // data.api_token = gl_token
    // data.num_fiscal = gl_cash
    postRequest(String("/check/sale?api_token=%1").arg(gl_token), data, callback)

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

/*
function taxUploadBind(bindid){
        if (isTaxMode()) {



            Lib.log("#94hn TAX MODE IS BLOCKED !!! \n main.taxUploadBind id=" + bindid); return;



            Lib.bindFromDb(Db, bindid,
               (err,bind) => {
                    if (err){
                        Lib.log(err, "Main>bindFromDb", "EE")
                    } else {
                       Lib.cdtaxFromBind(Db, bind,
                        (err, taxbind)=>{
                            if (err){
                                Lib.log(err, "Main>cdtaxFromBind", "EE")
                            } else {
                                taxbind.api_token = cdtoken
                                taxbind.num_fiscal = cdcash
                                CashDesk.postRequest(cdhost + cdprefix + String("/check/sale?api_token=%1").arg(cdtoken), taxbind,
                                                    (taxerr, taxresp) =>
                                                     {
                                                         if (err){
                                                        // TODO
                                                         } else {
                                                             taxServiceLoader.item.showResp({"code":"info", "sender":"XReport",
                                                                 // "resp": "XReport OK #" +jsresp.user_signature.user_id + " "+jsresp.user_signature.full_name,
                                                                 "resp": "XReport OK #" + taxresp,
                                                                 "tm":new Date()});
                                                         }
                                                     } )
                                taxRequest(String("/check/sale?api_token=%1").arg(cdtoken), taxbind, (response) => {
                                // Lib.log(response.status);
                                // Lib.log(response.headers);
                                // Lib.log( response.content);
                                let jsresp = JSON.parse(response.content)
                                while (~response.content.indexOf(',"')){ response.content = response.content.replace(',"',',\n"'); }
                                if (response.status === 200) {
                                 let isPlainText = response.contentType.length === 0
                                 if (isPlainText && taxServiceLoader.active) {
                                     taxServiceLoader.item.showResp({"code":"info", "sender":"XReport",
                                         // "resp": "XReport OK #" +jsresp.user_signature.user_id + " "+jsresp.user_signature.full_name,
                                         "resp": "XReport OK #" +response.content,
                                         "tm":new Date()});
                                 }
                                } else if (response.status === 0){
                                 taxServiceLoader.active = true
                                 taxServiceLoader.item.showResp({"code":"error", "sender":"ping", "resp":'Site connection error', "tm":new Date()});
                                } else {
                                 taxServiceLoader.active = true
                                 taxServiceLoader.item.showResp({"code":"error", "sender":"ping", "resp":"Status="+response.status+": "+response.content, "tm":new Date()});
                                }
                                });
                            }
                        })
                    }
                })
        }
    }
*/
