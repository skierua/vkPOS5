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
    // console.log("[libTAX] data=" + JSON.stringify(req)); return;
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

/**
  CashDesk
  */
function bindFromId(db, bindid) {
    let jbind = bindFromDb(db, bindid)
    if (!jbind || jbind.dcmno !== "") return false;

  let ok = true;
  const rows = jbind.dcms
  let cdatcl = [];    // cashDesc articles
  for (let r =0; r < rows.length && ok; ++r){
    ok &= (rows[r].dcmtype === "trade:sell" && Number(rows[r].mask) === 4 && Number(rows[r].amount) < 0)
    cdatcl.push( {"unit_code": rows[r].ucode, "unit_name": rows[r].uchar, "name": rows[r].ichar,
                "amount": Math.abs(rows[r].amount).toFixed(rows[r].prec),
                "price": Math.abs(Number(rows[r].eq)/Number(rows[r].amount)).toFixed(3),
                "cost": Math.abs(rows[r].eq).toFixed(2),
                "sum_discount":(0-Number(rows[r].dsc).toFixed(2))} )
  }
  if (!ok) {
      // cb("Чек не підлягає фіскалізації");
      return false; }

  let lnmb = 0;
  lnmb = db.dbInsert("insert into taxdcm (dcmid) values ('"+jbind.id+"')");
  if (lnmb == 0) {
      // cb("Не отримано локальний номер фіскалізації");
      return false; }

  let tsum = Math.round(10*Math.abs(jbind.amount))/10;
  let rsum = tsum - Math.abs(jbind.amount)
  if (tsum == 0) {
      // cb("Помидка фіскалізації. Сума чеку 0");
      return false; }

  // cashDesc bind
  let taxbind = {
    // "api_token": token,
    // "num_fiscal": cash,
    "action_type": "Z_SALE",
    "local_number": lnmb,
    "total_sum": tsum.toFixed(2),
    "round_sum":rsum.toFixed(2),
    "products": cdatcl,
    "payments": [{"code": 0,"name": "ГОТIВКА", "sum": tsum.toFixed(2),"sum_provided": tsum.toFixed(2),"sum_remains": 0}],
    "no_text_print":true,"no_pdf":true,"no_qr":true,"open_shift":true,"print_width": 32,"pdf_width": 48
  }

  // cb(null, taxbind)
  return taxbind
}

/*
  /check/sale
  /shift/ping
  /shift/xReport
  /shift        // Z_REPORT
  */
