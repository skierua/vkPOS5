.import "libREST.js" as REST
.import "CashDesk.js" as TAX
.import "v147/dbMigration.js" as Migrator
.import "v147/config.js" as Conf
.import "v147/sqlAcnt.js" as LibAcnt
.import "v147/sqlBind.js" as LibBind
// .import "v147/sqlItem.js" as LibItem
.import "v147/sqlPrice.js" as LibPrice
.import "v147/sqlShift.js" as LibShift

// FOR TEST
// .import "v147/sqlRepo.js" as LibTest
.import "v147/sqlItem.js" as LibItem


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



    const dfltAcnts = Conf.getAcntList(db);
    // if needed we should open account or set proper mask
    // console.log(`II: main.js/handleDbNameChanged [${JSON.stringify(dfltAcnts)}]`);
    if (dfltAcnts) {
        for (let key in dfltAcnts){
            // console.log(`36g#Main.qmlkey=${key} acnt=${dfltAcnts[key]}`)
            if (!!dfltAcnts[key]){
                const acnt = LibAcnt.acntbal(db, dfltAcnts[key], true);
            }
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

    ui.setModeId(Number(basicConf?.appmode || 3)) // this fires prn mode change
    prn.setTerm(basicConf?.id || "TEST")
    prn.setUser(shft?.cshrname || "")
    // prn.setCheck(basicConf?.print_dcm || "")
    prn.setPrinterName(basicConf?.pos_printer || "")

    if (typeof REST !== "undefined") {
        REST.reset();
        REST.restore(db);
        // console.log(`main.js/handleDbNameChanged usr:${REST.USER} psw:${REST.PSW} h:${REST.HOST} api:${REST.API} t:${REST.TOKEN} `)
        REST.connect((err, errstr) => {
            ui?.setRateOnline?.(REST.IS_CONNECTED || false);
            if (!err) {
                REST.save(db);
                ui?.setFooter?.(` ${String(Conf.TERM || "")}@${String(REST.HOST || "")}`);
                // ui?.setFooter?.(` ${String(REST.USER || "")}@${String(REST.HOST || "")}`);
                msg.info("З'єднання з REST сервером успішно встановлено!");
            } else {
                ui?.setFooter?.(`DISCONNECTED ${String(Conf.TERM || "")}@${String(REST.HOST || "")}`);
                // ui?.setFooter?.(`DISCONNECTED ${String(REST.USER || "")}@${String(REST.HOST || "")}`);
                msg.warn("Помилка REST шлюзу: " + String(errstr));
            }
        });
    }
    if (typeof TAX !== "undefined") {
        TAX.reset();
        TAX.restore(db);
        TAX.connect((err, errstr) => {
            if (!err) {
                if (!!ui && typeof ui.setTaxAction === "function")
                    ui.setTaxAction(TAX.IS_CONNECTED);
                    ui.pingTAX?.restart()
                msg.info("З'єднання з фіскальним сервером успішно встановлено!");
            } else {
                ui.pingTAX?.stop()
                msg.warn("Помилка фіскального шлюзу: " + String(errstr));
            }
        });
    }
    // console.info('WW:110 main.js REMOVE on production')
    //             ui.setTaxAction(true);

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

function handlePingTAX(ui){
    TAX.ping((err, resp) => {
                 if (!!err) ui?.warn?.("Connection to the TAX server has been lost.")
             });
}

function handleCloseTab(idx, container) {
    if (!container || idx < 0 || idx >= container.count) return;
    const itemToRemove = container.itemAt(idx);
    if (itemToRemove) {
        container.takeItem(idx);
        itemToRemove.destroy();
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
        prnDriver: prn,
        autoPrint: Number(basicConf?.auto_print || 0),
        dfltAmnt: Number(dfltAmnt),
        state: String(ui?.state || "")
    });
    newObj.vkEvent.connect((id, param) => {
        if (id === 'openDrawer') {
            if (ui && typeof ui.drawer === "function") ui.drawer();
        } else if (id === 'clientChanged') {
            if (ui && typeof ui.setClientFromBind === "function")
                ui.setClientFromBind(param || null);
        } else if (id === 'info') {
           // if (msg && typeof msg.info === "function")
                msg?.info?.(`${param ?? "Unknown info"}`);
        } else if (id === 'warn') {
           // if (msg && typeof msg.warn === "function")
                msg?.warn?.(`${param ?? "Unknown warn"}`);
        } else if (id === 'error') {
           // if (msg && typeof msg.error === "function")
                msg?.error?.(`${param ?? "Unknown error"}`);
        } else if (id === 'close' || id === 'destroy') {
           container.pop();
           newObj.destroy();
        } else {
           msg?.warn?.("[Bind] Невідома подія");
        }
    });
    container.currentIndex = container.count - 1;
}

function handleShiftWinClose(ui){
    // if (typeof LibShift !== "undefined" && typeof LibShift.crntShift === "function") {
    //     const shft = LibShift.crntShift(db)
    //     // Якщо зміна закрита в базі — примусово вимикаємо термінал
    //     if (shft && shft.shftend !== "") ui?.error?.("Shift closing ERROR");
    // }
    if (TAX.IS_CONNECTED) {
        if (!!ui && typeof ui.z_popup !== "undefined") ui.z_popup.open();
    } else if (typeof ui?.quitApp === "function") ui.quitApp();
}

function reloadNaviMenu(menu, instantiator){
    for (let i = menu.count - 1; i >= 0; --i) {
        let item = menu.itemAt(i);
        menu.removeItem(item);

    }
    instantiator.model = menu.menuStructure;
    // ui?.reloadModel?.()

}

function handleZReport(msg){
    if (!TAX.IS_CONNECTED) return false;
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

function fix_acnt_item_980(db, msg){
    let ok = false;
    try {
        db.dbSelectRowsJSON("PRAGMA foreign_keys = OFF;");

        db.dbSelectRowsJSON("BEGIN TRANSACTION;");

        db.dbSelectRowsJSON("DELETE FROM acnt WHERE item = '980';");

        db.dbSelectRowsJSON("COMMIT;");

        ok = true;
        const strOk = "Проблему 980 УСУНУТО!"
        if (!!msg && typeof msg.info === "function") msg.info(strOk);

    } catch (error) {
        const strErr = `Критична помилка: ${String(error)}`
        db.dbSelectRowsJSON("ROLLBACK;");
        console.error(strErr);
        if (!!msg && typeof msg.error === "function") msg.error(strErr);
    } finally {
        db.dbSelectRowsJSON("PRAGMA foreign_keys = ON;");
    }
    return ok;
}

function handleDrawerEvent(db, id, row, ui){
    // console.info(`II: main.js#ue72\n id=${id} row=${JSON.stringify(row)}`)
    if (!ui) {
        console.error("EE: ui brige missing");
        return;
    }
    if (!ui.crntComp) {
        ui.error?.("EE: ui Bind missing");
        ui.closeDrawer();
        return;
    }
    // if (row.acntno === LibAcnt.DfltAcnt.cashAcntNo(db)){
    //     return;
    // }

    if (!id || !row) ui.error?.("Drawer event bad param");
    if (id === "rowDoubleClicked"){
       if (String(ui.crntComp?.codeid || "") === "bind") {
           let ok = true;
           const clid = row.clid ?? ""
           const acntno = row.acntno ?? ""
           if ( clid !== ""
                && clid !== String(ui.crntComp.crntClient?.clid ?? "")){
               // const cl = LibClient.client(db, clid)
               ui.crntComp?.setCrntClient(clid);
               ui.warn("Змінено клієнта")
           }

           if (acntno !== ui.crntComp.crntAcnt.acntno
                   && acntno !== LibAcnt.DfltAcnt.cashAcntNo(db) ){
               const acnt = LibAcnt.acntbal(db, acntno);
               ui.crntComp.crntAcnt = acnt;
               ui.warn("Змінено типовий рахунок")
           }

           if (String(row?.acntno || "").startsWith(Conf.DEPO_ACNT_PREFIX)
                   || String(row?.acntno || "").startsWith(Conf.BONUS_ACNT_PREFIX)){
                ok = ui?.crntComp.newDcm(String(row?.key || ""),
                            0 - Number(row?.total || 0),
                            false);
           }  else if (String(row?.acntno || "").startsWith(Conf.CASH_ACNT_PREFIX)
                       || String(row?.acntno || "").startsWith(Conf.TRADE_ACNT_PREFIX)){
                ok = ui?.crntComp.newDcm(String(row?.key || ""),
                            0,
                            false);
           } else {
               ui?.warn?.("Unsupported account");
               ui.closeDrawer();
           }
            if (!ok) ui.closeDrawer();
       } else {
           ui?.error?.("Target component missmatch");
           ui.closeDrawer();
       }
    } else {
        ui.closeDrawer();
        ui?.warn?.("Drawer bad event");
    }

}

function testAction_handled(db, ui){
    const bid = 245756;
    const resp = {
    "ORDERNUM":"1rT89b5xMDE",
    "ORDERDATE":"2026-08-13",
    "ORDERTIME":"15:18:58",
    "MAC":"85ebfa326a3919896b7d4082eef850240e28b0bd7bf7d22a4bf593e9e829ef35",
    "is_offline":false,
    "qr":null,
    "qr_data":"https:\/\/cabinet.tax.gov.ua\/cashregs\/check?id=1rT89b5xMDE&date=20260813&fn=4000196849&time=1518&sm=270&mac=85ebfa326a3919896b7d4082eef850240e28b0bd7bf7d22a4bf593e9e829ef35",
    "link":"https:\/\/web.cashdesk.com.ua\/check\/f140086c-790e-459f-94a5-eb811e08f13a\/html",
    "pdf":null,
    "text_print":null,
    "uuid":"f140086c-790e-459f-94a5-eb811e08f13a",
    "local_number":6487,
    "cash_in_box":5244
};
    const updateData = {
                    "dcmtype": "check",
                    "dcmno": String(resp.uuid || ""),
                    "dcmnote": JSON.stringify(resp)
                };
    const uOk = LibBind.updDocum(db, bid, updateData);
    if (!uOk) ui?.error?.(db.dbLastError() || "Docum updating error");
    return;

    // const d = new Date();
    // const dd = new Date(d);
    // dd.setSeconds(dd.getSeconds()-10);
    // const ddIso = dd.toISOString();
    // console.info(`II: e7ge#maim.js ${Date.now()} d=${d} ddIso=${ddIso}`)
    // console.info(`II: e7ge#maim.js ${Date.now()} d=${d} ddIso=${ddIso}`)
    // return;

    // ["840", "", "978","200111", "124", "840", "200111"]
    // .forEach(v =>
    //      {
    //         const q = LibItem.new_getItemById(db, v);
    //         console.info(`II: e7ge#maim.js ${Date.now()} \n${JSON.stringify(q)}`)
    //      })

    // REST.uploadMonRepo(db, new Date().toISOString(),
    //                    (err)=>{})
    // const t = LibTest.monProfit(db)
    // console.info(`II: 63gt#main.js/testAction_handled \n ${JSON.stringify(t)}`)
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
