.import "libREST.js" as REST
.import "v147/config.js" as Conf
.import "v147/sqlItem.js" as LibItem
.import "v147/sqlPrice.js" as LibPrice

function loadCurrencies(db, model) {
    if (!db || !model) return;
    model.clear();

    const cur = LibItem.dbItems(db, "(itemmask & 2) AND itemnote IS NOT NULL AND itemnote != ''");
    // console.log(`ModelRates cur ${JSON.stringify(cur)} `)

    if (!cur || cur.length === 0) return;

    cur.sort((a, b) => Number(a.itemnote || 0) - Number(b.itemnote || 0));

    // 3. Наповнюємо модель
    for (let r = 0; r < cur.length; ++r) {
        model.append({
            "curid": String(cur[r].id || ""),
            "qty": Number(cur[r].qty || 1),
            "curchar": String(cur[r].itemchar || ""),
            "curname": String(cur[r].itemname || ""),
            "bid": 0.0, "ask": 0.0,
            "lbid": 0.0, "lask": 0.0,
            "lbidid": "", "laskid": "",
            "dfltbid": 0.0, "dfltask": 0.0
        });
    }
// console.log(`ModelRates got ${count} currencies`)
    populateLocalRates(db, model);
}

function populateLocalRates(db, model) {
    if (!db || (model?.count || 0) === 0) return;

    const jdata = LibPrice.currencyRates(db) || [];
    // console.log(`rate.js/populateLocalRates ${JSON.stringify(jdata)}`)

    // ОПТИМІЗАЦІЯ $O(N)$: Швидка мапа індексів замість важкого вкладеного циклу for
    let indexMap = {};
    for (let i = 0; i < model.count; ++i) {
        indexMap[model.get(i).curid] = i;
    }

    for (let r = 0; r < jdata.length; ++r) {

        let localRate = jdata[r];
        let idx = indexMap[localRate.item];
        // if (r < 2){
        //     console.log(`ModelRates populateLocalRates idx=${idx} ${JSON.stringify( jdata[r])}`)

        // }

        if (idx !== undefined) {
            let localQty = Number(model.get(idx).qty || 1);
            let rateQty = Number(localRate.qty || 1);
            let vprice = Number(localRate.price || 0);

            // Корекція кратності номіналу
            if (rateQty !== localQty && rateQty !== 0) {
                vprice = (localQty * vprice) / rateQty;
            }

            // Розкладаємо дані по полях купівлі/продажу на основі вашого знаку ba (1 або -1)
            if (String(localRate.prbidask) === "1") {
                model.setProperty(idx, "lbid", vprice);
                model.setProperty(idx, "dfltbid", vprice);
                model.setProperty(idx, "lbidid", String(localRate.id || ""));
            } else {
                model.setProperty(idx, "lask", vprice);
                model.setProperty(idx, "dfltask", vprice);
                model.setProperty(idx, "laskid", String(localRate.id || ""));
            }
        }
    }
}

function updateLocalRate(db, model, msg, row, amnt, ba) {
    // console.info(`II: rate.js/updateLocalRate`)
    if (!db || row < 0 || row >= model.count) {
        if (!!msg && typeof msg.error === "function") msg.error("Помилка параметрів");
        return ;
    }

    const targetAmount = (amnt === undefined || amnt === "") ? 0.0 : Number(amnt);
    const currentItem = model.get(row);
    const rowId = Number(ba || 1) > 0 ? currentItem.lbidid : currentItem.laskid;
    // Викликаємо функцію з правильним аліасом LibPrice
    const ok = LibPrice.updRate(db, targetAmount, currentItem.qty, rowId, currentItem.curid, ba);
    if (ok) {
        if (Number(ba) > 0) {
            model.setProperty(row, "lbid", targetAmount);
        } else {
            model.setProperty(row, "lask", targetAmount);
        }
    } else
        if (!!msg && typeof msg.error === "function") msg.error("Помилка поновлення курсу");

}


function loadWebRates(model, msg, ui){
    // const basicConf = Conf.getBasic(db);
    const req = {
        "term": Conf.TERM ?? "TEST",
        "reqid": "sel",
        "shop": Conf.TERM ?? "TEST"
    }
    REST.loadRates(req, (err, resp) => {
                       if (err === null){
                           // console.log("#278 ModelRates "+JSON.stringify(resp))
                           const actionEnabled = (ui.online && (resp.length > 0));
                           ui.setActionEnabled(actionEnabled);
                           populateWebRates(model, resp)
                           msg.info(`Ok ${resp.length}-s loaded`)
                       } else {
                          msg.error(err.text)
                       }
  });
}


function populateWebRates(model, jdata) {
    if (!jdata || jdata.length === 0 || (model?.count || 0) === 0){
        return;
    }
    // ОПТИМІЗАЦІЯ $O(N)$: Будуємо швидку індексну мапу для моментального пошуку валюти за 1 крок
    let indexMap = {};
    for (let i = 0; i < model.count; ++i) {
        indexMap[model.get(i).curid] = i;
    }

    // let refresh = false;

    for (let r = 0; r < jdata.length; ++r) {
        const serverRate = jdata[r];
        const idx = indexMap[serverRate.atclcode];

        // Якщо така валюта активована в нашій касі
        if (idx !== undefined) {
            const localQty = Number(model.get(idx).qty || 1);
            const serverQty = Number(serverRate.rqty || 1);

            let vbid = Number(serverRate.bid || 0);
            let vask = Number(serverRate.ask || 0);

            // Коррегуємо курс, якщо кратність на сайті та на касі відрізняється
            if (serverQty !== localQty && serverQty !== 0) {
                vbid = (localQty * vbid) / serverQty;
                vask = (localQty * vask) / serverQty;
            }

            // Зберігаємо курси як чисті точні числа
            model.setProperty(idx, "bid", vbid);
            model.setProperty(idx, "ask", vask);

            // refresh |= (vbid !== model.get(idx).lbid || vask !== model.get(idx).lask);
        }
    }
}

function updateLocalRates(db, model, msg, zero = 0.0000001) {
    if (!(db) || model.count === 0) return;

    let refreshLocal = false;
    let ok = true;

    (db).dbTransaction();

    for (let i = 0; i < model.count; ++i) {
        const currentItem = model.get(i);

        // 1. Перевіряємо зміну курсу КУПІВЛІ (Bid)
        let serverBid = Number(currentItem.bid || 0);
        let localBid = Number(currentItem.lbid || 0);

        if (!!serverBid && Math.abs(serverBid - localBid) > zero) {
            refreshLocal = true;
            let res = LibPrice.updRate((db), serverBid, currentItem.qty, currentItem.lbidid, currentItem.curid, "1");
            if (res === 0) ok = false; // Якщо запит повернув помилку (0), фіксуємо збій
        }

        // 2. Перевіряємо зміну курсу ПРОДАЖУ (Ask)
        let serverAsk = Number(currentItem.ask || 0);
        let localAsk = Number(currentItem.lask || 0);

        if (!!serverAsk && Math.abs(serverAsk - localAsk) > zero) {
            refreshLocal = true;
            let res = LibPrice.updRate((db), serverAsk, currentItem.qty, currentItem.laskid, currentItem.curid, "-1");
            if (res === 0) ok = false;
        }
    }

    // --- ФІНАЛІЗАЦІЯ ТРАНЗАКЦІЇ ---
    if (ok) {
        // Якщо ВСІ запити пройшли бездоганно — фіксуємо дані на диск одним махом!
        (db).dbCommit();

        if (refreshLocal) {
            // console.log(`II: rate.js/updateLocalRates populateLocalRates`)
            populateLocalRates(db, model);
            if(!!msg && typeof msg.info === "function")
                msg.info("Курси успішно оновлені та зафіксовані в БД.");
        }
    } else {
        // Якщо стався бодай ОДИН збій (наприклад, база виявилась LOCKED) — скасовуємо все оновлення повністю.
        (db).dbRollback();
        if(!!msg && typeof msg.error === "function")
            msg.error("Критична помилка запису! Оновлення скасовано.");
    }
}
