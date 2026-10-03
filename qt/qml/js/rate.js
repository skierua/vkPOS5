.import "libREST.js" as REST
.import "v147/sqlItem.js" as LibItem
.import "v147/sqlPrice.js" as LibPrice

const CURRENCY = new Map();
const LOCAL_RATE = new Map();
const WEB_RATE = new Map();

function loadCurrencies(db, model) {
    if (!db || !model) return;
    CURRENCY.clear();
    LOCAL_RATE.clear();
    // WEB_RATE.clear();
    // console.log(`ModelRates cur ${JSON.stringify(cur)} `)
    const rawCur = LibItem.itemList(db, 2);
    if (!rawCur || rawCur.length === 0) return;

    for (let v of rawCur){
        if (String(v.itemnote || "") !== "")
            CURRENCY.set(String(v.id), v);
    };
    populateLocalRates(db, model);
}

function buildLocalKey(curid, ba){
    return `${String(curid || "")} ${String(ba || "")}`;
}

function populateLocalRates(db, model) {
    if (!db || !model) return;
    model.clear();

    const rawRate = LibPrice.currencyRates(db) || [];
    // console.log(`II: 971d#rate.js rawRate ${JSON.stringify(rawRate)} `)
    for (let r of rawRate){
            LOCAL_RATE.set(buildLocalKey(r.item, r.prbidask), r);
    };

    const curs = [...CURRENCY.values()]
    .sort((a, b) => Number(a.itemnote || 99) - Number(b.itemnote || 99));
    // console.log(`II: 6st3#rate.js cur ${JSON.stringify(curs)} `);
    for ( let cur of curs){
        const curQty = Number(cur.qty || 1);
        let bidVal = 0.0;
        let bidId = 0;
        const bidKey = buildLocalKey(cur.id, 1);
        if (LOCAL_RATE.has(bidKey)){
            const bidRate = LOCAL_RATE.get(bidKey);
            const bidQty = bidRate.qty;
            bidVal = Number(bidRate.price || 0.0);
            bidId = Number(bidRate.id || 0);
            if (curQty !== bidQty && curQty !== 0) bidVal *= (bidQty / curQty)
            // console.log(`II: ya61#rate.js`, bidKey, curQty, bidQty, bidVal);
        }
        let askVal = 0.0;
        let askId = 0;
        const askKey = buildLocalKey(cur.id, -1);
        if (LOCAL_RATE.has(askKey)){
            const askRate = LOCAL_RATE.get(askKey);
            const askQty = askRate.qty;
            askVal = Number(askRate.price || 0.0)
            askId = Number(askRate.id || 0);
            if (curQty !== askQty && curQty !== 0) askVal *= (askQty / curQty)
            // console.log(`II: ya61#askrate.js`, askKey, curQty, askQty, askVal);
        }

        model.append({
            "curid": String(cur.id || ""),
            "qty": Number(cur.qty || 1),
            "curchar": String(cur.itemchar || ""),
            "curname": String(cur.itemname || ""),
            "bidDisplay": bidVal, "askDisplay": askVal,
            "bidEdited": bidVal, "askEdited": askVal,
            "bidId": bidId, "askId": askId,
        });
    };
    // console.log(`II: ya61#rate.js count=${model.count} `);
}

function populateWebRates(model, msg) {
    WEB_RATE.clear();

    const l_populate = (jdata) => {
        const rates = jdata
            .filter(v => !v.pricecode)
            .map(r => Object.assign({}, r, {
                "qty": Number(r.qty || 1),
                "bid": Number(r.bid || 0),
                "ask": Number(r.ask || 0),
            }));

        for (let r of rates) {
            WEB_RATE.set(String(r.atclcode || ""), r);
        }

        for (let i = 0; i < model.count; ++i) {
            const row = model.get(i);

            if (WEB_RATE.has(String(row.curid || ""))) {
                const webRate = WEB_RATE.get(row.curid);

                const localQty = Number(row.qty || 1);
                const webQty = webRate.qty;

                // Розраховуємо коефіцієнт (якщо номінали відрізняються)
                const qtyCoef = (webQty !== 0 && localQty !== webQty) ? (localQty / webQty) : 1;

                model.setProperty(i, "bidEdited", qtyCoef * webRate.bid);
                model.setProperty(i, "askEdited", qtyCoef * webRate.ask);
            }
        }
        return;
    };

    REST.loadRates((err, resp) => {
        if (err === null) {
            l_populate(resp);
            msg.info(`Ok ${resp.length}-s loaded`);
        } else {
            msg.error(err);
        }
    });
}

/*function old_populateWebRates(model, msg){
    // console.log(`II: 273#rate.js/populateWebRates`)

    WEB_RATE.clear();
    const l_populate = (jdata) =>
    {
        const rates = jdata
        .filter(v => !v.pricecode)
        .map(r => {
                 return Object.assign({}, r, {
                     "qty": Number(r.qty || 1),
                     "bid": Number(r.bid || 0),
                     "ask": Number(r.ask || 0),
                 });
             });
        // console.log(`II: 827#rate.js ${JSON.stringify(rates)}`)

        for (let r of rates){
                WEB_RATE.set(r.atclcode, r);
        };

        for (let i =0; i < model.count; ++i){
            const row = model.get(i);
            if (WEB_RATE.has(row.curid)){
                const webRate = WEB_RATE.get(row.curid);
                const qtyCoef = Number(webRate.qty || 1) !== 0
                                && row.qty !== Number(webRate.qty || 1) ?
                                row.qty / Number(webRate.qty || 1) : 1;
                if (qtyCoef !== 1){
                    model.setProperty(i,"bidEdited", qtyCoef * Number(webRate.bid || 0))
                    model.setProperty(i,"askEdited", qtyCoef * Number(webRate.ask || 0))
                } else {
                    model.setProperty(i,"bidEdited", Number(webRate.bid || 0))
                    model.setProperty(i,"askEdited", Number(webRate.ask || 0))
                }
            }
        }

        return;
    };

    REST.loadRates((err, resp) => {
                       if (err === null){
                           // console.log("#278 rate.js/populateWebRates "+JSON.stringify(resp))
                           l_populate(resp);
                           // populateWebRates(model, resp)
                           msg.info(`Ok ${resp.length}-s loaded`)
                       } else {
                          msg.error(err)
                       }
  });
}*/

function updateLocalRates(db, model, msg, zero = 0.0000001) {
    if (!(db) || model.count === 0) return;

    let refreshLocal = false;
    let ok = true;

    (db).dbTransaction();

    for (let i = 0; i < model.count; ++i) {
        const currentItem = model.get(i);

        // 1. Перевіряємо зміну курсу КУПІВЛІ (Bid)
        let dBid = Number(currentItem.bidDisplay || 0);
        let eBid = Number(currentItem.bidEdited || 0);

        if (Math.abs(dBid - eBid) > zero) {
            refreshLocal = true;
            let res = LibPrice.updRate((db), eBid, currentItem.qty, currentItem.bidId, currentItem.curid, 1);
            if (res === 0) ok = false; // Якщо запит повернув помилку (0), фіксуємо збій
        }

        // 2. Перевіряємо зміну курсу ПРОДАЖУ (Ask)
        let dAsk = Number(currentItem.askDisplay || 0);
        let eAsk = Number(currentItem.askEdited || 0);

        if (Math.abs(dAsk - eAsk) > zero) {
            refreshLocal = true;
            let res = LibPrice.updRate((db), eAsk, currentItem.qty, currentItem.askId, currentItem.curid, 1);
            if (res === 0) ok = false; // Якщо запит повернув помилку (0), фіксуємо збій
        }
    }

    // --- ФІНАЛІЗАЦІЯ ТРАНЗАКЦІЇ ---
    if (ok) {
        (db).dbCommit();

        if (refreshLocal) {
            // console.log(`II: rate.js/updateLocalRates populateLocalRates`)
            populateLocalRates(db, model);
            if(!!msg && typeof msg.info === "function")
                msg.info("Курси успішно оновлені.");
        }
    } else {
        (db).dbRollback();
        if(!!msg && typeof msg.error === "function")
            msg.error("Критична помилка запису! Оновлення скасовано.");
    }
}



