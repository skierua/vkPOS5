.import "libREST.js" as REST
.import "CashDesk.js" as TAX
.import "v147/sqlAcnt.js" as LibAcnt
.import "v147/sqlClient.js" as LibClient
.import "v147/sqlBind.js" as LibBind
.import "v147/sqlItem.js" as LibItem
.import "v147/sqlPrice.js" as LibPrice
.import "v147/sqlShift.js" as LibShift
.import "v147/sqlTran.js" as LibTran

function crnTotalList(db, model) {
    // Використовуємо Map для миттєвого пошуку валюти за її ID за O(1)
    const totalsMap = new Map();
    const maxSortOrder = 99;

    for (let i = 0; i < model.count; ++i) {
        const item = model.get(i);
        const mask = Number(item.darticleMask|| 0);
        // console.log(`bind.js#w924 ${JSON.stringify(item)}`)

        // Фільтруємо тільки іноземну валюту (маска 2)
        if ((mask & 2) !== 2) continue;

        const articleId = item.darticleId;
        const transactionAmount = item.dsign * Number(item.damnt || 0);

        if (totalsMap.has(articleId)) {
            // Валюта вже є в списку — просто додаємо суму
            const existing = totalsMap.get(articleId);
            existing.amnt += transactionAmount;
        } else {
            // Нова валюта — створюємо запис
            const atcl = LibItem.getItemById(db, item.darticleId)
            totalsMap.set(articleId, {
                "id": item.darticleId,
                "itemchar": atcl.itemchar,
                "amnt": transactionAmount,
                "so": Number(atcl.itemnote || maxSortOrder)
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
            const dcm = model.get(i);
            ok &= (dcm.dcode || "") === "trade:sell"
            && Number(dcm.dsign || 0) < 0
            && Number(dcm.darticle?.mask || 0) === 4;
        }

        return ok;
    };

    const l_parse = (raw) => {
        try {
            return JSON.parse(raw);
        } catch (err) {
            return null;
        }
    }

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
    const dcmcode = String(ui.state || "check");
    const shft = LibShift.crntShiftData(db)
    const total = model.total();
    const utcTimeStamp = new Date().toISOString();  //.substring(0, 19);
    const jbind = {
        "id": "dcmbind",
        "dcm": dcmcode !== "taxcheck" ? dcmcode : "check",
        "dbt": cashAcntNo,
        "cdt": ui.bindCdt || "",
        "amnt": (total?.pmnt || 0).toFixed(2),
        "eq": (total?.eq || 0).toFixed(2),
        "dsc": (total?.dsc || 0).toFixed(2),
        "bns": (total?.bns || 0).toFixed(2),
        "note": ui.bindNote || "",
        "clnt": ui.clid || "",
        "cshr": shft?.cshrId || "",
        "tm": utcTimeStamp,
        "dcms": dcmList
    }
    // console.info(`II:#397- bind.js/handleTranAction jbind=${JSON.stringify(jbind)}`);
    // return 1;
    const bid = LibTran.tranBind(db, jbind);
    if (!bid) {
        ui?.error?.("Критична помилка: Фінансовий документ не проведено базою даних!");
        return -2;
    } else {
        sendBindToREST(db, jbind, ui);
    }

    // console.warn(`WW:200 bind.js change to previous\n sendToTax=${sendToTax}`);
    // if (sendToTax) {
    if (sendToTax && TAX.IS_CONNECTED) {
        TAX.sale(db, bid, 0, (err, resp) => {
                     // console.info(`II: bind.js#5et3 ${resp}`)
                    const updateData = {
                        "dcmnote": JSON.stringify(resp)
                    };
                    if (!!err)  ui?.error?.(err || "TAX sending error");
                    else {
                        const parsed = l_parse(resp);
                        const taxNo = String(parsed?.uuid || "");
                        if (!!taxNo) updateData.dcmno = taxNo;
                         // console.info(`II: bind.js#4r21 updateData=${JSON.stringify(updateData)}\ntaxNo=${taxNo}`)
                     }
                    const uOk = LibBind.updDocum(db, bid, updateData);
                    if (!uOk) ui?.error?.(db.dbLastError() || "Docum updating error");
                  });
    }

    const pMode = Number(ui?.printMode || 0)
    const pCode = Number(ui?.printCode || 0)
    if (pCode !== 0 && (pCode === 1 || pMode !== 0)) {
        const bindforPrint = LibBind.dbBind(db, bid);
        // console.info(`II: bind.js#242g ${JSON.stringify(bindforPrint)}`)
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
    const tradeAcnt = LibAcnt.DfltAcnt.trade(db);
    if (!!tradeAcnt){
        popup.jsdata.push({
                              "id": tradeAcnt.acntno,
                              "name": tradeAcnt.note || tradeAcnt.name,
                              "fullname": tradeAcnt.name,
                              "code" : "acntno",
                              "sect": ""
                           });
    }

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
           "sect": qsTr("Рахунки клієнта")
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
    const res = []
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
        const acntSource = LibAcnt.acntbalClientList(db, ui.clid, cleanText);
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
                               `(itemmask = 4) AND scancode LIKE '%${str}%'`)
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
                // const clnt = getClient(db, res[0].id);
                // ui.setClient(clnt || null);
                ui.setClient(res[0].id ?? "");
                // ui.vkEvent("clientChanged", clnt)
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
        // console.log(`bind.js#mdh30 price=${test}\natcl=${JSON.stringify(jprice)}`)
        note = jatcl.itemchar + " " + ((!!jprice?.offer) ? "#АКЦІЯ!" : (!!jprice?.dsc ? "#ЗНИЖКА!" : ""))
    }
    if (stateVal === "taxcheck"){
        if (dcmType !== "trade:sell" || amntVal > 0) return false;
    }
    const dcm = {
        atclId: jatcl.id,
        acntNo: ui.acnt.acntno,
        amnt: amntVal,
        type: dcmType,
        note: note,
        jprice: jprice,
    }
    const ok = model.addDcm(db, dcm);
    // const ok = model.addDcm(jatcl, ui.acnt, dcmType, amntVal, jprice, note)
    // const rtest = model.get(0);
    // const test = Number(rtest.jprice.offer || rtest.jprice.price || rtest.jprice.bsc || 0)
    // console.log(`bind.js#sj72 price=${test}\n rtest=${JSON.stringify(rtest.jprice)}`)
    return ok;

}

function sendBindToREST(db, jbind, ui){
    // console.info(`II: bind.js/sendBindToREST isConnected=${REST.IS_CONNECTED}`)
    if (REST.IS_CONNECTED){
       REST?.uploadBalance?.(db,
         (e)=>{
            if (!!e) ui?.warn?.(e || "REST sync error");
         });
      REST?.uploadBind?.(jbind,
                 (err)=>{
                    if (!!err){
                        ui?.warn?.(err || "REST sending error");
                    }

            });
   }

}

