import QtQuick
import "js/v147/config.js" as Conf
import "js/v147/sqlItem.js" as LibItem
import "js/v147/sqlPrice.js" as LibPrice
import "js/libREST.js" as REST

ListModel {
    id: modelRoot
    property bool isWebEmpty: true

    signal vkEvent(string id, var param)


    // ModelRates.qml

    function populate(dbDriver) {
        clear();
        if (!dbDriver) return;

        let cur = LibItem.dbItems(dbDriver, "itemmask & 2 AND itemnote IS NOT NULL AND itemnote != ''");
        // console.log(`ModelRates cur ${JSON.stringify(cur)} `)

        if (!cur || cur.length === 0) return;

        cur.sort((a, b) => Number(a.itemnote || 0) - Number(b.itemnote || 0));

        // 3. Наповнюємо модель
        for (let r = 0; r < cur.length; ++r) {
            append({
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
        populateLocalRates(dbDriver);
    }

    function loadWebRates(){
        // console.log(`ModelRates term=${term}`)
        const basicConf = Conf.getBasic(db);
        const req = {
            "term": basicConf?.id ?? "TEST",
            "reqid": "sel",
            "shop": basicConf?.id ?? "TEST"
        }
        REST.loadRates(req, (err,resp) => {
                           if (err === null){
                               // console.log("#278 ModelRates "+JSON.stringify(resp))
                               populateWebRates(resp)
                               vkEvent("log", `Ok ${resp.length}-s loaded`)
                           } else {
                              vkEvent("err", err.text)
                           }
      });
    }


    function populateWebRates(jdata) {
        if (!jdata || jdata.length === 0 || count === 0){
            modelRoot.isWebEmpty = true
            return;
        }
        modelRoot.isWebEmpty = false
        // ✅ ОПТИМІЗАЦІЯ $O(N)$: Будуємо швидку індексну мапу для моментального пошуку валюти за 1 крок
        let indexMap = {};
        for (let i = 0; i < count; ++i) {
            indexMap[get(i).curid] = i;
        }

        let refresh = false;

        for (let r = 0; r < jdata.length; ++r) {
            let serverRate = jdata[r];
            let idx = indexMap[serverRate.atclcode];

            // Якщо така валюта активована в нашій касі
            if (idx !== undefined) {
                let localQty = Number(get(idx).qty || 1);
                let serverQty = Number(serverRate.rqty || 1);

                let vbid = Number(serverRate.bid || 0);
                let vask = Number(serverRate.ask || 0);

                // Коррегуємо курс, якщо кратність на сайті та на касі відрізняється
                if (serverQty !== localQty && serverQty !== 0) {
                    vbid = (localQty * vbid) / serverQty;
                    vask = (localQty * vask) / serverQty;
                }

                // Зберігаємо курси як чисті точні числа
                setProperty(idx, "bid", vbid);
                setProperty(idx, "ask", vask);

                refresh |= (vbid !== get(idx).lbid || vask !== get(idx).lask);
            }
        }
    }


    function populateLocalRates(dbDriver) {
        if (!dbDriver || count === 0) return;

        const jdata = LibPrice.currencyRates(dbDriver) || [];
        // console.log(`ModelRates populateLocalRates ${JSON.stringify(jdata)}`)

        // ✅ ОПТИМІЗАЦІЯ $O(N)$: Швидка мапа індексів замість важкого вкладеного циклу for
        let indexMap = {};
        for (let i = 0; i < count; ++i) {
            indexMap[get(i).curid] = i;
        }

        for (let r = 0; r < jdata.length; ++r) {

            let localRate = jdata[r];
            let idx = indexMap[localRate.item];
            // if (r < 2){
            //     console.log(`ModelRates populateLocalRates idx=${idx} ${JSON.stringify( jdata[r])}`)

            // }

            if (idx !== undefined) {
                let localQty = Number(get(idx).qty || 1);
                let rateQty = Number(localRate.qty || 1);
                let vprice = Number(localRate.price || 0);

                // Корекція кратності номіналу
                if (rateQty !== localQty && rateQty !== 0) {
                    vprice = (localQty * vprice) / rateQty;
                }

                // Розкладаємо дані по полях купівлі/продажу на основі вашого знаку ba (1 або -1)
                if (String(localRate.prbidask) === "1") {
                    setProperty(idx, "lbid", vprice);
                    setProperty(idx, "dfltbid", vprice);
                    setProperty(idx, "lbidid", String(localRate.id || ""));
                } else {
                    setProperty(idx, "lask", vprice);
                    setProperty(idx, "dfltask", vprice);
                    setProperty(idx, "laskid", String(localRate.id || ""));
                }
            }
        }
    }

    function updateLocalRate(dbDriver, row, amnt, ba) {
        if (!dbDriver || row < 0 || row >= count) return;

        let targetAmount = (amnt === undefined || amnt === "") ? 0.0 : Number(amnt);
        let currentItem = get(row);

        // Викликаємо функцію з правильним аліасом LibPrice
        LibPrice.updRate(dbDriver, targetAmount, currentItem.qty, currentItem.lbidid, currentItem.curid, ba);

        // Оновлюємо значення в поточній моделі для миттєвого відображення на екрані
        if (Number(ba) > 0) {
            setProperty(row, "lbid", targetAmount);
        } else {
            setProperty(row, "lask", targetAmount);
        }
    }

    function updateLocalRates(dbDriver) {
        if (!dbDriver || count === 0) return;

        let refreshLocal = false;
        let success = true;

        dbDriver.dbTransaction();

        for (let i = 0; i < count; ++i) {
            let currentItem = get(i);

            // 1. Перевіряємо зміну курсу КУПІВЛІ (Bid)
            let serverBid = Number(currentItem.bid || 0);
            let localBid = Number(currentItem.lbid || 0);

            if (Math.abs(serverBid - localBid) > zero) {
                refreshLocal = true;
                let res = LibPrice.updRate(dbDriver, serverBid, currentItem.qty, currentItem.lbidid, currentItem.curid, "1");
                if (res === 0) success = false; // Якщо запит повернув помилку (0), фіксуємо збій
            }

            // 2. Перевіряємо зміну курсу ПРОДАЖУ (Ask)
            let serverAsk = Number(currentItem.ask || 0);
            let localAsk = Number(currentItem.lask || 0);

            if (Math.abs(serverAsk - localAsk) > zero) {
                refreshLocal = true;
                let res = LibPrice.updRate(dbDriver, serverAsk, currentItem.qty, currentItem.laskid, currentItem.curid, "-1");
                if (res === 0) success = false;
            }
        }

        // --- ФІНАЛІЗАЦІЯ ТРАНЗАКЦІЇ ---
        if (success) {
            // Якщо ВСІ запити пройшли бездоганно — фіксуємо дані на диск одним махом!
            dbDriver.dbCommit();

            if (refreshLocal) {
                populateLocalRates(dbDriver);
                modelRoot.dbg("Всі курси успішно оновлені та зафіксовані в БД.", "RatesCommit");
            }
        } else {
            // Якщо стався бодай ОДИН збій (наприклад, база виявилась LOCKED) — скасовуємо все оновлення повністю.
            dbDriver.dbRollback();
            if (typeof logView !== "undefined") {
                logView.append("[Курси] Критична помилка запису! Оновлення скасовано.", 0);
            }
        }
    }

/*    function updateLocalRates(dbDriver){
        let refreshLocal = false;
        // saveWebAction.enabled = false
        // update rates
        for(let i =0; i < count; ++i) {
            if ( Math.abs(Number(get(i).bid) - Number(get(i).lbid)) > zero ){
                refreshLocal |= true
                LibPrice.updRate(dbDriver, get(i).bid === "" ? "0" : get(i).bid, get(i).qty, get(i).lbidid, get(i).curid, "1")
            }
            if ( Math.abs(Number(get(i).ask) - Number(get(i).lask)) > zero ){
                refreshLocal |= true
                LibPrice.updRate(dbDriver, get(i).ask === "" ? "0" : get(i).ask, get(i).qty, get(i).laskid, get(i).curid, "-1")
                // vkEvent("rate.updLocal", { "id":get(i).laskid, "price":get(i).ask===""?"0":get(i).ask, "qty":jscur[i].qty, "curid":jscur[i].curid, "ba":"-1" })
            }
        }
        if (refreshLocal) populateLocalRates(dbDriver)
    }
*/


}

/*

  loadWebRates structure
    [{
        "atclcode":"978",
        "rqty":"1",
        "bid":"47.16",
        "ask":"47.63",
        "bidtm":"2025-07-17T18:22:28.622Z",
        "asktm":"2025-07-17T18:22:28.622Z",
        "shop":"CITY",
        "chid":"EUR",
        "name":"ЄВРО",
        "cqty":"1",
        "sortorder":"15",
        "prc":""
    }]
  */
