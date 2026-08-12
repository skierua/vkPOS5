.import "libREST.js" as REST
.import "CashDesk.js" as TAX
.import "v147/sqlAcnt.js" as LibAcnt
.import "v147/sqlClient.js" as LibClient
.import "v147/sqlBind.js" as LibBind
.import "v147/sqlItem.js" as LibItem
.import "v147/sqlPrice.js" as LibPrice
.import "v147/sqlShift.js" as LibShift
.import "v147/sqlTran.js" as LibTran

function crnTotalList(model) {
    // Використовуємо Map для миттєвого пошуку валюти за її ID за O(1)
    const totalsMap = new Map();
    const maxSortOrder = 99;

    for (let i = 0; i < model.count; ++i) {
        const item = model.get(i);
        const mask = Number(item.darticle?.mask || 0);
        // console.log(`bind.js#w924 ${JSON.stringify(item)}`)

        // Фільтруємо тільки іноземну валюту (маска 2)
        if ((mask & 2) !== 2) continue;

        const articleId = item.darticle.id;
        const transactionAmount = item.dsign * Number(item.damnt || 0);

        if (totalsMap.has(articleId)) {
            // Валюта вже є в списку — просто додаємо суму
            const existing = totalsMap.get(articleId);
            existing.amnt += transactionAmount;
        } else {
            // Нова валюта — створюємо запис
            totalsMap.set(articleId, {
                "id": item.darticle.id,
                "itemchar": item.darticle.itemchar,
                "amnt": transactionAmount,
                "so": Number(item.darticle?.itemnote || maxSortOrder)
            });
        }
    }

    // Перетворюємо Map назад у масив результатів
    const res = Array.from(totalsMap.values());
// console.log(`bind.js#8fj ${JSON.stringify(res)}`)
    // Сортуємо, якщо знайдено більше однієї валюти
    if (res.length > 1) {
        res.sort((a, b) => Number(a.so || maxSortOrder) - Number(b.so || maxSortOrder));
    }

    return res;
}

function handleDomToAcnt(db, model, acnt, amnt){
    const atcl = LibItem.getItemById(db);
    const type = amnt < 0 ? "pay:out" : "pay:in"
    const ok = model.addDcm(atcl, acnt, type, amnt, null, "зарахування на рахунок");
    if (!ok) console.error(model.lastError);
}

function handleCrnToAcnt(db, crnTotal, model, acnt){
    // const crnTotal = crnTotalList(model);
    for (let i = 0; i < crnTotal.length; ++i) {
        // console.info(`II: bind.js/handleCrnToAcnt acntno=${acnt} cur=${crnTotal[i].id} amnt=${-1 * crnTotal[i].amnt}`)
        const atcl = LibItem.getItemById(db, crnTotal[i].id);
        const type = crnTotal[i].amnt > 0 ? "pay:out" : "pay:in"
        const ok = model.addDcm(atcl, acnt, type, -1 * crnTotal[i].amnt, null, "ВАЛ. зарахування на рахунок");
        if (!ok) console.error(model.lastError);
    }
}

/**
 * Балансування торгових результатів та перенесення залишків на рахунок прибутку
 * @param {Object} db - Драйвер бази даних C++
 * @param {Object} model - Екземпляр bindModel (передаємо явно)
 * @param {Object} ui - Контекст для виклику логів/подій
 */
function handleRsltToProfit(db, model, ui) {
    const cashAcntNo = LibAcnt.DfltAcnt.cashAcntNo(db);
    const profitAcntNo = LibAcnt.DfltAcnt.profitAcntNo(db);
    const profitAcnt = LibAcnt.acntbal(db, (profitAcntNo || ""));

    if (!profitAcnt) {
        ui?.error?.("[profit] account is undefined")
        return;
    }

    const acntList = LibAcnt.dbBalance(db, `substr(acntno,1,4)='rslt' AND ABS(beginamnt+turndbt-turncdt) > 0.009`);

    if (!acntList || acntList.length === 0) {
        ui?.info?.("data list is empty")
        return;
    }

    if (!model || typeof model.flush !== "function") {
        ui?.error?.("bindModel missing")
        return;
    }

    let ok = true;
    const tradeMap = new Map();
    model.flush();

    const atcl = LibItem.getItemById(db);
    for (let i = 0; ok && i < acntList.length; ++i) {
        const currentTotal = Number(acntList[i].total || 0);
        const rsltAcnt = LibAcnt.acntbal(db, acntList[i].acntno);
        const dcmType = currentTotal < 0 ? "pay:out" : "pay:in";
        const noteVal = (currentTotal < 0 ? "+++ rslt" : "--- rslt")

        ok &= model.addDcm( atcl, rsltAcnt, dcmType, currentTotal, null, noteVal);
        const tradeAcnt = acntList[i].acntno.substring(5,9);
        // console.log(`bind.js/handleBalancingTrade ${tradeAcnt}`)
        tradeMap.set(tradeAcnt, (tradeMap.get(tradeAcnt) || 0) + currentTotal);
    }

    const currentPeriod = new Date().toISOString().substring(0, 7); // Формат: YYYY-MM
    for (let k of tradeMap.keys()) {
        const pmnt = 0 - tradeMap.get(k);

        ok &= model.addDcm( atcl,
                          profitAcnt,
                          (pmnt < 0 ? "pay:out" : "pay:in"),
                          pmnt,
                          null,
                           `${(pmnt < 0 ? "--- rslt" : "+++ rslt")} ${currentPeriod} ${k}`);

    }

    // for (let r =0; r < model.count; ++r) console.log(`iw3w#bind/handleBalancingTrade ${JSON.stringify(model.get(r))}`)

    if (!ok) {
        ui?.error?.("Помилка при додаванні memo")
    }
}

function handleTranAction(db, prn, model, ui) {
    if (!model.count) return -1;

    const l_isTaxCorrect = () => {
        let ok = true;
        for (let i = 0; ok && i < model.count; ++i){
            const dcm = get(i);
            ok &= (dcm.dcode || "") === "trade:sell"
            && Number(dcm.dsign || 0) < 0
            && Number(dcm.darticle?.mask || 0) === 4;
        }

        return ok;
    };

    let sendToTax = false;
    let bindForTax = null;
    if (!!ui && ui.state === "taxcheck") {
        // Якщо перевірка фіскального блоку НЕ пройшла успішно
        if (!l_isTaxCorrect()) {
            ui?.error?.("Помилка фіскалізації. Некоректний фіскальний документ");
            return -2;
        }

        // Якщо все коректно — дозволяємо відправку на сервер ДПС
        sendToTax = true;

    }

    const cashAcntNo = LibAcnt.DfltAcnt.cashAcntNo(db);

    const dcmList = model.dcmsToTran(cashAcntNo);
    if (!dcmList){
        ui?.error?.(model.lastError || "Serialization error");
        return -2;
    }
    const shft = LibShift.crntShift(db)
    const total = model.total();
    const utcTimeStamp = new Date().toISOString();  //.substring(0, 19);
    const jbind = {
        "id": "dcmbind",
        "dcm": String(ui.state || "check"),
        "dbt": cashAcntNo,
        "cdt": "",
        "amnt": (total?.pmnt || 0).toFixed(2),
        "eq": (total?.eq || 0).toFixed(2),
        "dsc": (total?.dsc || 0).toFixed(2),
        "bns": (total?.bns || 0).toFixed(2),
        "note": "",
        "clnt": ui.clid || "",
        "cshr": shft?.cshr || "",
        "tm": utcTimeStamp,
        "dcms": dcmList
    }
    const bid = LibTran.tranBind(db, jbind);
    if (!bid) {
        ui?.error?.("Критична помилка: Фінансовий документ не проведено базою даних!");
        return -2;
    } else {
        sendBindToREST(db, jbind, ui);
    }

    if (sendToTax && TAX.isConnected) {
        TAX.sale(db, bid, 0, (err, resp) => {
                      if (!!err)  ui?.error?.(err || "TAX sending error");
                  });
    }

    const pMode = Number(ui?.printMode || 0)
    const pCode = Number(ui?.printCode || 0)
    if (pCode !== 0 && (pCode === 1 || pMode !== 0)) {
        const bindforPrint = LibBind.dbBind(db, bid);
        if (bindforPrint){
            const printer = prn
                          ? prn
                          : (typeof Prn !== "undefined" ? Prn : null);
            if (printer) {
                printer.saveCheckCopy(bindforPrint);
                const prnOk = printer.printCheckCopy(bindforPrint);
                if (prnOk) ui?.error?.( printer.lastError() || "Printer error");
            } else {
                ui?.error?.("Драйвер принтера чеків не ініціалізовано!");
            }
        }

    }
    return 0;
}


function getClient(db, clid){
    let cl = clid ?  LibClient.client(db, clid)
                 : null;
    if (cl && cl.id && cl.id !== ""){
        const bonusAcnt = LibAcnt.createClientBonusAcntNo(cl.id);
        const bonus = LibAcnt.acntItemBalance(db, bonusAcnt )
        cl.bonusAcnt = bonusAcnt;
        cl.bonusBalance = bonus?.total ?? 0.0;

    }

    return cl || null;
}

function handleSelectClientAction(db, popup){
    popup.jsdata = []
    const source = LibClient.dbClient(db)
    const list = source
    .sort((a,b) => a.name.localeCompare(b.name) )
    .map(v => {
        return {
           "id": v.id,
           "name": v.name,
           "fullname": v.name,
            "code": "client",
           "sect": qsTr("Клієнти")
        };
   })
    // console.log(`main.js#98wh ${JSON.stringify(list)}`)
    popup.jsdata = list
    popup.open()
}

function getAcnt(db, acntNo){
    // console.log(`bind.js.js#92jw acntNo=[${acntNo}]`)
    const acnt = acntNo ? LibAcnt.acntbal(db, acntNo)
                 : LibAcnt.DfltAcnt.trade(db);
    return acnt || null;
}

// function setCrntAcnt(db, uiAcnt, acntNo){
//     // console.log(`bind.js.js#92jw acntNo=[${acntNo}]`)
//     const acnt = acntNo ? LibAcnt.acntbal(db, acntNo)
//                  : LibAcnt.DfltAcnt.trade(db);
//     uiAcnt = acnt || null;
// }

function handleSelectAcntAction(db, popup, ui){
    popup.jsdata = [];
    const cashAcntNo = LibAcnt.DfltAcnt.cashAcntNo(db);
    const source = LibAcnt.acntbalClientList(db, ui.clid)
    const list = source
    .filter(v => (v.acntno !== cashAcntNo && !v.acntno.startsWith("rslt")))
    .sort((a,b) => 0 - (Number(a.trade)-Number(b.trade))
          || a.acntno.localeCompare(b.acntno) )
    .map(v => {
        return {
           "id": v.acntno,
           "name": v.note || v.name,
           "fullname": v.name,
           "code" : "acntno",
           "sect": qsTr("Рахунки")
        };
   })
    // console.log(`jw8#bind.js source=${JSON.stringify(source)} \n list=${JSON.stringify(list)}`)
    popup.jsdata.push(...list);
    popup.open()
}

function handleStartBindAction(db, model, ui){
    model.flush()
    // model.code = ui.state || "check"
    ui.setDfltClient();
    ui.setAcnt(LibAcnt.DfltAcnt.trade(db));
}

/*
 *
*/
function handleFind(db, str, popup, ui) {
    const cleanText = str.trim();
    if (cleanText === "") return;
    popup.jsdata = [];
    let res = []
    if(isNaN(cleanText)) {
        const clsource = LibClient.dbClient(db, null, cleanText)
        const cllist = clsource
        .sort((a,b) => a.name.localeCompare(b.name) )
        .map(v => {
            return {
               "id": v.id,
               "name": v.name,
               "fullname": v.name,
                "code": "client",
               "sect": qsTr("Клієнти")
            };
        })
        res.push(...cllist)

        const atclsource = LibItem.dbItems(db, `itemmask & ${Number(ui.mask) ?? 7}`, cleanText)
        const atcllist = atclsource
        .sort((a,b) => a.itemchar.localeCompare(b.itemchar) )
        .map(v => {
            return {
               "id": v.id,
               "name": v.itemchar,
               "fullname": v.itemname,
               "scancode": v.scancode,
                "code": "article",
               "sect": qsTr("Валюти + Товари")
            };
        })
        res.push(...atcllist)

        const cashAcntNo = LibAcnt.DfltAcnt.cashAcntNo(db);
        const acntSource = LibAcnt.acntbalClientList(db, ui.clid, cleanText)
        const acntLlist = acntSource
        .filter(v => v.acntno !== cashAcntNo)
        .sort((a,b) => 0 - (Number(a.trade)-Number(b.trade))
              || a.acntno.localeCompare(b.acntno) )
        .map(v => {
            return {
               "id": v.acntno,
               "name": v.note || v.name,
               "fullname": v.name,
               "code" : "acntno",
               "sect": qsTr("Рахунки")
            };
       })
        res.push(...acntLlist)

    } else {
        if (str.length < 4) {
            const cursource = LibItem.dbItems(db,
                               `(itemmask = 2) AND substr(cast(item.pkey as string),1,${str.length}) = '${str}'`)
            if (cursource.length > 0){
                const curlist = cursource
                .sort((a,b) => a.itemchar.localeCompare(b.itemchar) )
                .map(v => {
                    return {
                       "id": v.id,
                       "name": v.itemchar,
                       "fullname": v.itemname,
                       "scancode": v.scancode,
                        "code": "article",
                       "sect": qsTr("Валюти")
                    };
                })
                res.push(...curlist)
            }
        }
        if (res.length === 0 && str.length < 5) {
            if (str === "0000"){
                console.info(`bind.js#j480 cl=0000`)
                ui.setClient();
                return;
            }

            const cl = LibClient.client(db, str)
            if (cl){
                res.push({
                            "id": cl.id,
                            "name": cl.name,
                            "fullname": cl.name,
                            "code": "client",
                            "sect": qsTr("Клієнти")
                        });
            }
        }
        if (res.length === 0 && str.length < 7) {
            const atclsource = LibItem.dbItems(db,
                               `(itemmask = 4) AND substr(cast(item.pkey as string),1,${str.length}) = '${str}'`)
            if (atclsource.length > 0){
                const atcllist = atclsource
                .sort((a,b) => a.itemchar.localeCompare(b.itemchar) )
                .map(v => {
                    return {
                       "id": v.id,
                       "name": v.itemchar,
                       "fullname": v.itemname,
                       "scancode": v.scancode,
                        "code": "article",
                       "sect": qsTr("Валюти")
                    };
                })
                res.push(...atcllist)
            }
        }
        if (res.length === 0 && str.length < 14) {
            const scansource = LibItem.dbItems(db,
                               `(itemmask = 4) AND scancode LIKE '%${str}%')`)
            if (scansource.length > 0){
                const scanlist = scansource
                .sort((a,b) => a.itemchar.localeCompare(b.itemchar) )
                .map(v => {
                    return {
                       "id": v.id,
                       "name": v.itemchar,
                       "fullname": v.itemname,
                       "scancode": v.scancode,
                        "code": "article",
                       "sect": qsTr("Валюти")
                    };
                })
                res.push(...scanlist)
            }
        }

    }
    // console.log(`bind.js#9fsj str=${str}`)
    if (res.length > 0){
        if (res.length > 1){
            popup.jsdata = res
            popup.open()
        } else {
            if (res[0].code==="client"){                  // client
                // handleClientChanged(db, res[0].id)
                const clnt = getClient(db, res[0].id);
                ui.setClient(clnt || null);
                ui.vkEvent("clientChanged", clnt)
            } else if (res[0].code === "acntno") {        // acntno
                const acnt = getAcnt(db, res[0].id);
                ui.setAcnt(acnt || null)
                ui.startNewRow();
            } else if (res[0].code==="article") {
                ui.createDocum(res[0].id)
            } else {
                ui.vkEvent("warn", "[Bind] bad code, nothing to do")
            }
        }
    } else ui.vkEvent("info", "Нічого не знайдено") // nothing has found


}

function handleNewDcm(db, model, ui){
    // console.log(`bind.js#o9w ui.state=${ui.state}`)
    if (!db) return false;
    if (!ui || !ui.acnt) return false;
    const jatcl = LibItem.getItemById(db, (ui.atclid || ""));
    const isCurrency = Number(jatcl?.mask || 0) !== 4;
    const amntVal = Number(ui.amnt || 0);
    const stateVal = (ui.state || "check");
    let dcmType = (amntVal < 0 ? "pay:out" : "pay:in");
    if (stateVal === "folder") dcmType = "memo";
    const isTrade = !!(ui.atclid || "") && Number(ui.acnt?.trade ?? 0) === 1;
    let jprice = null;
    let note = "";
    if (isTrade) {
        dcmType = "";
        if (isCurrency){
            dcmType = (amntVal < 0 ? "trade:sell" : "trade:buy");
        } else {
            if (stateVal === ""|| stateVal === "check" || stateVal === "taxcheck") dcmType = "trade:sell";
            else if (stateVal === "facture") dcmType = "trade:buy";
            else if (stateVal === "folder") dcmType = "trade:inner";
        }
        const bidAskSign = (dcmType === "trade:sell" ? -1
                                                     : (dcmType === "trade:buy" ? 1 :
                                                                                  (amntVal < 0 ? -1 : 1)));
        if (isCurrency){
            jprice = model.rate !== 1 ?
                        LibPrice.dummyPrice(jatcl.id, 1.0)
                      : LibPrice.price(db, jatcl.id, bidAskSign, ui.acnt?.acntno || "")
        } else {
            jprice = LibPrice.price(db, jatcl.id, bidAskSign, ui.acnt?.acntno || "")
        }

        // console.log(`bind.js#mdh30 crn=${jatcl.id} ba=${bidAskSign} no=${ui.acnt?.acntno || ""}`)
        // console.log(`bind.js#mdh30 price=${JSON.stringify(jprice)}\natcl=${JSON.stringify(jatcl)}`)
        note = jatcl.itemchar + " " + ((!!jprice?.offer) ? "#АКЦІЯ!" : (!!jprice?.dsc ? "#ЗНИЖКА!" : ""))
    }
    if (stateVal === "taxcheck"){
        if (dcmType !== "trade:sell" || amntVal > 0) return false;
    }
    const ok = model.addDcm(jatcl, ui.acnt, dcmType, amntVal, jprice, note)
    return ok;

}

function handleNewRefuse(db, model, dcm){
    if (!db) return false;
    if (!model || !dcm) return false;
    const datcl = LibItem.getItemById(db, String(dcm.itemid || ""));
    const dacnt = LibAcnt.acntbal(db, String(dcm.acntcdt || ""));
    console.log(`bind.js#wlp0/handleNewRefuse dcm=${JSON.stringify(dcm)}`)
    const res = model.addRefused(dcm, datcl, dacnt);
    console.log(`bind.js#wlp0/handleNewRefuse res=[${res}]`)
    return res;

}

/* // for CashDesk
function createBindForTax_cd(db, dcmid, payType) {
    let  err = null, resp = null;
    let archive = false;
    let bind = LibBind.selDcmById(db, dcmid);
    if (!bind || bind?.errid || null) {
        archive = true;
        bind = LibBind.selDcmById(db, dcmid, archive);
    }
    // console.log(`id82#CashDesk ${JSON.stringify(bind)}`);
    if (!bind || bind?.errid || null) {
        return null;
    }
    const dcmSource = LibBind.selDcmsByPid(db, dcmid, archive);
    if (!dcmSource || dcmSource?.errid || null) {
        return null;
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
        return null;
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

    return taxbind;
}
*/

function sendBindToREST(db, jbind, ui){
   if (REST.isConnected){
      REST.uploadBind2(jbind,
                 (err)=>{
                    if (!err){
                       if (typeof REST.uploadBalance2 === "function") {
                           REST.uploadBalance2(db, 10,
                             (e)=>{
                                if (!!e) ui?.warn?.(e || "REST sync error");
                             });
                       }
                    } else {
                        ui?.warn?.(err || "REST sending error");
                    }

            });
   }

}

