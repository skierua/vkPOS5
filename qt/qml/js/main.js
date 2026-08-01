.import "libREST.js" as REST
.import "CashDesk.js" as TAX
.import "v147/dbMigration.js" as Migrator
.import "v147/config.js" as Conf
.import "v147/sqlAcnt.js" as LibAcnt
.import "v147/sqlBind.js" as LibBind
.import "v147/sqlPrice.js" as LibPrice
.import "v147/sqlShift.js" as LibShift

// mode all | updated account
function uploadBalance(db, mode = "upd", msg){
    if (!(REST.isConnected ?? false)) return;
    // const basicConf = Conf.getBasic(db);
    const currentTerm = String(Conf.TERM || "TEST");
    const currentShop = currentTerm;
    let acntData = [];
    const loadMode = (mode === "all" ? false : true);
    if (typeof LibAcnt.balanceForUpload === "function") {
        acntData = LibAcnt.balanceForUpload(db, loadMode);
    }
    if (acntData && acntData.length > 0) {
        if (mode === "all"){
           REST.uploadBalance({ "term": currentTerm, "reqid": "del", "shop": currentShop, "data": [] }, ()=>{} );
        }

        const balanceReq = { "term": currentTerm, "reqid": "upd", "shop": currentShop, "data": acntData }
        REST.uploadBalance(balanceReq,
           (err)=>{
               if (!!err) {
                   msg.error("[uploadBalance] Помилка: " + err);
               } else {
                   // msg.info("[uploadBalance] Баланс успішно синхронізовано з вебом");
               }
           })
    } else  msg.info("[uploadBalance] Nothing to do");
}

function uploadBind(bind, msg){
    if (!(REST.isConnected ?? false)) return;
    if (!bind) {
        msg.error("[uploadBind] Bind is missing");
        return;
    }
    // const basicConf = Conf.getBasic(db);
    const currentTerm = String(Conf.TERM || "TEST");
    const currentShop = currentTerm;
    const bindReq = { "term": currentTerm, "reqid": "upd", "shop": currentShop, "data": bind }
    REST.uploadBind(bindReq,
        (err)=>{
         if (!!err) {
             msg.error("[uploadBind] Помилка: " + err);
         } else {
             // msg.info("[uploadBind] Документ успішно синхронізовано з вебом");
         }
    })

}

function handleDbNameChanged(db, prn, container, msg, ui){
    if (!db) return false;
    const len = container.count;
    for (let i = len -1; i >=0 && i < len; --i){
        handleCloseTab(i, container)
    }
    if (!String(ui.dbname || "")) return false;
    const ok = db.setDbParameter(String(ui.dbname || ""));
    if (!ok){
        return false;
    }

    Migrator.initDatabase(db);



    const dfltAcnts = LibAcnt.DfltAcnt.acnts(db);
    // if needed we should open account or set proper mask
    // console.log(`II: main.js/handleDbNameChanged [${JSON.stringify(dfltAcnts)}]`);
    if (dfltAcnts) {
        for (let key in dfltAcnts){
            // console.log(`36g#Main.qmlkey=${key} acnt=${dfltAcnts[key]}`)
            const acnt = LibAcnt.acntbal(db, dfltAcnts[key], true);
        }
    } else {
        const cashAcntNo = LibAcnt.createCashAcntNo();
        const tradeAcntNo = LibAcnt.createTradeAcntNo();
        const cashOpen = LibAcnt.acntbal(db, cashAcntNo, true);
        const tradeOpen = LibAcnt.acntbal(db, tradeAcntNo, true);
        if (!cashOpen || !tradeOpen){
            console.log("Critical. Default accounts missing !!!", 0);
            return false;
        } else {
            const settingsObj = {
                    "cash": String(cashAcntNo || ""),
                    "trade": String(tradeAcntNo || "")
                };
                const jsonString = JSON.stringify(settingsObj);

                const usql = `UPDATE conf SET val = :acnts WHERE key = 'acntlist'`;

                const params = {
                    ":acnts": jsonString
                };
// console.log(`II: main.js/handleDbNameChanged ${JSON.stringify(jsonString)}`);
                const success = db.dbUpdate(usql, params);

                if (!success) {
                    console.log(`EE: Помилка збереження налаштувань рахунків: ${db.dbLastError()}`, 0)
                    return false;
                }
        }
    }
// populate price qty cache
    // console.log(`main.js#hds63 lp=${!!LibPrice} typeof = [${LibPrice.DfltPriceQty}]`)
    if (!!LibPrice && typeof LibPrice.DfltPriceQty.populate !== "undefined"){
            LibPrice.DfltPriceQty.populate(db);
    }

    const basicConf = Conf.getBasic(db);
    const shft = LibShift.crntShift(db)

    prn.setTerm(basicConf?.id || "TEST")
    prn.setUser(shft?.cshrname || "")
    prn.setCheck(basicConf?.print_dcm || "")

    if (typeof REST !== "undefined") {
        REST.reset(db);
        // console.log(`main.js/handleDbNameChanged usr:${REST.USER} psw:${REST.PSW} h:${REST.HOST} api:${REST.API} t:${REST.TOKEN} `)
        REST.connect((err, errstr) => {
            if (!err) {
                REST.save(db);
                if (!!ui && typeof ui.setRateOnline === "function")
                    ui.setRateOnline(REST.isConnected);
                if (!!ui && typeof ui.setFooter === "function")
                    ui.setFooter(` ${String(Conf.TERM || "TEST")}@${String(REST.HOST || "")}`);
                msg.info("З'єднання з REST сервером успішно встановлено!");
            } else {
                if (!!ui && typeof ui.setRateOnline === "function")
                    ui.setRateOnline(REST.isConnected);
                if (!!ui && typeof ui.setFooter === "function")
                    ui.setFooter(`DISCONNECTED ${String(Conf.TERM || "TEST")}@${String(REST.HOST || "")}`);
                msg.warn("Помилка REST шлюзу: " + String(errstr));
            }
        });
    }
    if (typeof TAX !== "undefined") {
        TAX.reset(db);
        // if(!!String(TAX.HOST || "")
        //     && !!String(TAX.API || "")
        //     && !!String(TAX.CASH || "")
        //     && !!String(TAX.TOKEN || "")
        //     && !String(TAX.HOST).startsWith("*")
        //     ){
                TAX.connect((err, msg) => {
                    if (!err) {
                        if (!!ui && typeof ui.setTaxAction === "function")
                            ui.setTaxAction(TAX.isConnected);
                        msg.info("З'єднання з фіскальним сервером успішно встановлено!");
                    } else {
                        msg.warn("Помилка фіскального шлюзу: " + String(msg));
                    }
                });
        // }
    }

    if (shft?.shftend !== '') {
        // Зміна вже закрита — відкриваємо вікно менеджменту змін
        ui.winShift();
    } else {
        const currentDateStr = new Date().toISOString().substring(0, 10);
        // console.log(`main.js/handleDbNameChanged#i83
        //             currentDateStr=${currentDateStr} shftdate = [${shft?.shftdate}]`)
        if (shft?.shftdate !== currentDateStr)  ui.winShift();
    }
    return true;
}

function handleCloseTab(idx, container) {
    if (!container || idx < 0 || idx >= container.count) return;
    const itemToRemove = container.itemAt(idx);
    if (itemToRemove) {
        container.takeItem(idx);
        itemToRemove.destroy();
    }
}

function sendTaxSale(db, taxbind, msg){
    if (!(TAX.isConnected ?? false)) return;
    if (!!taxbind && taxbind.products.length > 0) {
        if (typeof TAX.sendSaleToTax === "function") {
            TAX.sale(taxbind, (e, r) =>{
                     if (e) msg.error(`TAX server error. ${e || ""}`);
                     else {
                         // const setVal = `dcmtype = 'taxchek', dcmnote = ${r}`;
                         const updateData = {
                                         "dcmtype": "taxchek",
                                         "dcmnote": String(r)
                                     };
                         // const uOk = LibBind.updDocum(db, dcmid, setVal);
                         const uOk = LibBind.updDocum(db, dcmid, updateData);
                         if (!uOk) msg.warn(`TAX sended but not updated. ${db.dbLastError()}`);
                     }
                 })
        } else msg.error("TAX sale function missing");
    } else {
        msg.error("TAX bind is empty or serialization error");
    }
}

function handleAddBindTab(db, prn, comp, msg, container, ui){
    const basicConf = Conf.getBasic(db);
    const dfltAmnt = (ui.state === "facture")
                   ? 1
                   : Number(basicConf?.amnt_sign || -1);
// console.info(`main.js/handleAddBindTab container ${container.count}`);
    const newObj = comp.createObject(container, {
        dbDriver: db,
        dfltAmnt: Number(dfltAmnt),
        state: String(ui?.state || "")
    });
    newObj.vkEvent.connect((id, param) => {
        if (id === 'openDrawer') {
            if (ui && typeof ui.drawer === "function") ui.drawer();
        } else if (id === 'clientChanged') {
            if (ui && typeof ui.setClientFromBind === "function")
                ui.setClientFromBind(param || null);
        } else if (id === 'tranOk') {
           uploadBind(param?.bind || null, msg);
           uploadBalance(db, "upd", msg);
           // print dcm
           const pMode = Number(param?.prnMode ?? 2);
                                   console.info(`II: main.js/handleAddBindTab pMode=${pMode} auto=${(basicConf?.auto_print || 0)}`)
           if (pMode !== 0 && (pMode === 1 || (basicConf?.auto_print || 0) !== 0)) {
              prn.saveCheck(param?.bind || null);
              prn.printCheck(param?.bind || null);
           }
           if (!!(param?.sendToTax || false )){
               sendTaxSale(Db,(param?.bindForTax || null), msg);
           }
        } else if (id === 'info') {
           if (msg && typeof msg.info === "function")
                msg.info(`${param ?? "Unknown info"}`);
        } else if (id === 'warning') {
           if (msg && typeof msg.warn === "function")
                msg.warn(`${param ?? "Unknown info"}`);
        } else if (id === 'error') {
           if (msg && typeof msg.error === "function")
                msg.error(`${param ?? "Unknown info"}`);
        } else if (id === 'close' || id === 'destroy') {
           container.pop();
           newObj.destroy();
        } else {
           msg.warn("[Bind] Невідома подія від компонента Bind");
        }
    });
    container.currentIndex = container.count - 1;
}

function handleShiftWinClose(db, timer){
    if (typeof LibShift !== "undefined" && typeof LibShift.crntShift === "function") {
        const shft = LibShift.crntShift(db)
        // Якщо зміна закрита в базі — примусово вимикаємо термінал
        if (shft && shft.shftend !== "") {
            if (typeof timer !== "undefined") timer.start();
        }
    }
}

function handleZReport(msg){
    if (!TAX.isConnected) return false;
    TAX.z_report( (err, resp) =>
                {
                    if (err){
                        msg.error(`Z_report: ${err}`)
                        return false;
                    } else {
                        msg.info(`Z_report: OK # ${resp}`)
                        return true;
                    }
                }
            )
}

function handleXReport(msg){
    if (!TAX.isConnected) return false;
    TAX.x_report( (err, resp) =>
                {
                    if (err){
                        msg.error(`X_report: ${err}`)
                        return false;
                    } else {
                        msg.info(`X_report: OK # ${resp}`)
                        return true;
                    }
                }
            )
}

// NOT USED
/*function executeZReportProcedure() {
    // 1. Робимо автоматичне службове вилучення (Cash Out) через вашу JS бізнес-логіку.
    // Це обнуляє гроші на рахунку каси ('3000'), переносячи їх в інкасацію транзиту.
    if (typeof JS !== "undefined" && typeof JS.handleCashOut === "function") {
        const currentCashAmt = Db.dbSelectRowsJSON("SELECT total FROM acnt WHERE id = '3000';");
        let cashInBox = Array.isArray(currentCashAmt) && currentCashAmt.length > 0 ? Number(currentCashAmt[0].total || 0) : 0;

        if (cashInBox > 0) {
            console.log("[РРО] Авто-вилучення залишку готівки: " + cashInBox);
            JS.handleCashOut(Db, cashInBox, "Авто-вилучення при закритті зміни");
        }
    }

    // 2. Надсилаємо команду закриття зміни безпосередньо у фіскальний блок ПРРО
    // Припускаємо, що у вашому TAX модулі є метод closeShift()
    if (typeof TAX !== "undefined" && typeof TAX.closeShift === "function") {
        TAX.closeShift((err, fiscalZResp) => {
            if (err === null) {
                // Зміна успішно закрита на сервері податкової!
                root.vkEvent("info", "Зміну успішно закрито! Фіскальний номер Z-звіту: " + String(fiscalZResp?.z_number || ""));

                // Очищаємо сесійний токен ПРРО, оскільки зміна закрита
                TAX.Param.setToken("");

                // Скидаємо інтерфейс чека
                if (typeof bindCheckAction !== "undefined") bindCheckAction.trigger();

                popupCloseShift.close();
            } else {
                root.vkEvent("error", "Критична помилка шлюзу ДПС при спробі Z-закриття: " + String(err));
            }
            btnConfirmZReport.enabled = true;
        });
    } else {
        // Фаллбек якщо РРО працює в тестовому автономному режимі
        root.vkEvent("info", "Зміну закрито в автономному (тестовому) режимі.");
        popupCloseShift.close();
        btnConfirmZReport.enabled = true;
    }
}*/
