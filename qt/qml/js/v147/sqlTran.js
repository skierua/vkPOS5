.pragma library

.import "sqlAcnt.js" as LibAcnt
.import "sqlShift.js" as LibShift

/**
 * ПРОВЕДЕННЯ ФІНАНСОВОГО ПАКЕТА (ЧЕКА) В БАЗУ ДАНИХ SQLITE3
 * @param {Object} db - Оптимізований C++ драйвер DbDriver4
 * @param {Object} jbind - JSON-пакет чека з ModelBind.qml
 * @returns {number} - ID створеного головного документа (parent id)
 */
function tranBind(db, jbind) {
    if (!db || !jbind || !jbind.dcms) return 0;
    const shift = LibShift.crntShift(db);
    const isShiftActive = shift?.shftend === "";
    // console.log(`3dj9#ModelBind.qml ${JSON.stringify(shift)}`)
    if (!isShiftActive) {
        // lastError = "Немає відкритої зміни!";
        return 0;
    }

    let tranSchedule = [];
    let r = 0;
    let dbtid = {};
    let cdtid = {};
    let bnsid = { "errid": 1, "errname": "invalid" }; // Дефолтний бонусний рахунок

    // ✅ ЗАХИСТ ДИСКА ТА БАЛАНСУ: Відкриваємо єдину транзакцію через C++
    // Усі запити виконаються в RAM миттєво, а SSD-диск зафіксує чек одним махом!
    db.dbTransaction();

    let ok = true;

    // 1. Перевірка та автоматичне створення бонусного рахунку клієнта
    let hasBonus = false;
    for (r = 0; r < jbind.dcms.length; ++r) {
        if (Number(jbind.dcms[r].bns || 0) !== 0) {
            hasBonus = true;
            break;
        }
    }
    if (hasBonus && jbind.clnt !== "") {
        const bonusAcntNo = LibAcnt.createClientBonusAcntNo(clnt);
        // const bonusAcntNo = Config.getClntBonusAcntNo(clnt);

        // Використовуємо шаблонні рядки ES6 замість String().arg
        const selectBonusSql = `SELECT acntno, client, mask FROM acntbal WHERE acntno = '${bonusAcntNo}' AND client = '${jbind.clnt}';`;
        let balacnt = db.dbSelectRow(selectBonusSql);

        // Якщо бонусного рахунку для цього клієнта ще немає — створюємо його в аліасі acntbal
        if (!balacnt || balacnt.errid !== 0) {
            const insertBonusSql = `INSERT INTO acntbal (acntno, client, mask) VALUES ('${bonusAcntNo}', '${jbind.clnt}', 1);`;
            db.dbInsert(insertBonusSql);
        }
        bnsid = acnt_id(db, bonusAcntNo);
        ok &= (bnsid.errid === 0 && Number(bnsid.acid || 0) !== 0);
    }
    // 2. Планувальник проводок подвійного запису (Double-Entry Scheduler)
    for (r = 0; ok && r < jbind.dcms.length; ++r) {
        const dcmItem = jbind.dcms[r];

        // Визначаємо дебетовий ID рахунку
        dbtid = acnt_id(db, dcmItem.dbt, dcmItem.crn);
        ok &= (dbtid.errid === 0 && Number(dbtid.acid || 0) !== 0);
        if (!ok) break;

        // ЛОГІКА ДЛЯ ВАЛЮТНОЇ ТОРГІВЛІ (TRADE OPER)
        if (String(dcmItem.dcm).substring(0, 6) === "trade:") {
            cdtid = acntTrade_id(db, dcmItem.cdt, dcmItem.crn);
            ok &= (cdtid.errid === 0 && Number(cdtid.acid || 0) !== 0);
            if (!ok) break;
            // Проводка 1: Рух самої фізичної валюти (Код кількості)
            tranSchedule.push({"rowid": r, "amount": dcmItem.amnt, "dbtid": dbtid.acid, "cdtid": cdtid.acid });

            // Проводка 2: Рух фінансового еквівалента в гривні (eqvl.)
            dbtid = acnt_id(db, dcmItem.dbt);
            ok &= (dbtid.errid === 0 && Number(dbtid.acid || 0) !== 0);
            if (!ok) break;
            tranSchedule.push({"rowid": r, "amount": dcmItem.eq, "dbtid": cdtid.eqid, "cdtid": dbtid.acid });

            // Проводка 3: Персональна знижка клієнта (DISCOUNT)
            if (Number(dcmItem.dsc || 0) !== 0) {
                tranSchedule.push({"rowid": r, "amount": dcmItem.dsc, "dbtid": cdtid.eqid, "cdtid": dbtid.acid });
            }

            // Проводка 4: Нарахування або списання бонусів (BONUS)
            if (hasBonus) {
                tranSchedule.push({"rowid": r, "amount": dcmItem.bns, "dbtid": cdtid.eqid, "cdtid": bnsid.acid });
                // if (clntBnsDbtId.errid === 0 && Number(clntBnsDbtId.acid || 0) !== 0 && Number(cdtid.eqid || 0) !== 0) {
                //     tranSchedule.push({"rowid": r, "amount": dcmItem.bns, "dbtid": cdtid.eqid, "cdtid": clntBnsDbtId.acid });
                // }
            }

            // ОНОВЛЕННЯ СЕРЕДНЬОЇ ІСТОРІЙНОЇ ЦІНИ В ПАРІ АНАЛІТИКИ КАСИ (lastprice)
            let amntNum = Number(dcmItem.amnt || 0);
            if (amntNum !== 0) {
                let calculatedAvgPrice = Math.abs((Number(dcmItem.eq || 0) + Number(dcmItem.dsc || 0)) / amntNum)
                .toLocaleString('en-US', {
                                     minimumFractionDigits: 2,
                                     maximumFractionDigits: 6,
                                     useGrouping: false //Вимикає розділювачі тисяч (прибирає коми/пробіли)
                                 });

                if (dcmItem.dcm === "trade:buy" && amntNum > 0) {
                    const updateBuyPriceSql = `UPDATE acntrade SET lastpricebuy = ${calculatedAvgPrice} WHERE acntno = '${dcmItem.cdt}' AND article = '${dcmItem.crn}';`;
                    ok &= db.dbUpdate(updateBuyPriceSql);
                } else if (dcmItem.dcm === "trade:sell" && amntNum < 0) {
                    const updateSellPriceSql = `UPDATE acntrade SET lastpricesell = ${calculatedAvgPrice} WHERE acntno = '${dcmItem.cdt}' AND article = '${dcmItem.crn}';`;
                    ok &= db.dbUpdate(updateSellPriceSql);
                } else {
                    const updateBscPriceSql = `UPDATE acntrade SET bscprice = ${calculatedAvgPrice} WHERE acntno = '${dcmItem.cdt}' AND article = '${dcmItem.crn}';`;
                    ok &= db.dbUpdate(updateBscPriceSql);
                }
            }

        } else {
            // ЛОГІКА ДЛЯ СЛУЖБОВИХ ОРДЕРІВ ТА МЕМОРАНДУМІВ (NON TRADE)
            cdtid = acnt_id(db, dcmItem.cdt, dcmItem.crn);
            ok &= (cdtid.errid === 0 && Number(cdtid.acid || 0) !== 0);
            if (!ok) break;
            tranSchedule.push({"rowid": r, "amount": dcmItem.amnt, "dbtid": dbtid.acid, "cdtid": cdtid.acid });
        }
    }
// console.log(`sqlTran 33333 ok=[${ok}] \n ${JSON.stringify(tranSchedule)}`);
    const sqlClientField = (jbind.clnt === "") ? "NULL" : `'${jbind.clnt}'`;
    const sqlNoteField = (!jbind.note || jbind.note === "") ? "NULL" : `'${jbind.note}'`;

    const insertMainDocSql = `
        INSERT INTO docum (dcmtype, acntdbt, amount, eqamount, discount, bonus, dcmstate, acntcdt, dcmnote, client, dcmtime)
        VALUES ('${jbind.dcm}', '${jbind.dbt}', ${Number(jbind.amnt || 0)}, ${Number(jbind.eq || 0)}, ${Number(jbind.dsc || 0)}, ${Number(jbind.bns || 0)}, 1, '${jbind.cdt}', ${sqlNoteField}, ${sqlClientField}, '${jbind.tm}');
    `;

    let pid = db.dbInsert(insertMainDocSql);
    ok &= (pid !== 0);
    // console.log(`sqlTran 55555 ok=[${ok}]`);

    // 4. ЗАПИС ПОЗИЦІЙ ЧЕКА ТА БУХГАЛТЕРСЬКИХ ПРОВОДОК (Подвійний запис)
    // if (ok) {
    let did =0;
        for (r = 0; ok && r < jbind.dcms.length; ++r) {
            let subDcm = jbind.dcms[r];
            let sqlItemField = (subDcm.crn === "") ? "NULL" : `'${subDcm.crn}'`;
            let sqlRetforField = (subDcm.retfor === "") ? "NULL" : `${subDcm.retfor}`;
            let sqlCshrField = ((shift?.cshr || "") === "") ? "NULL" : `'${shift?.cshr || ""}'`;

            const insertSubDocSql = `
                INSERT INTO docum (dcmtype, acntdbt, amount, eqamount, discount, bonus, dcmstate, acntcdt, dcmnote, item, parentid, retfor, dcmaker, dcmtime)
                VALUES ('${subDcm.dcm}', '${subDcm.dbt}', ${Number(subDcm.amnt || 0)}, ${Number(subDcm.eq || 0)}, ${Number(subDcm.dsc || 0)}, ${Number(subDcm.bns || 0)}, 1, '${subDcm.cdt}', '${subDcm.note || ""}', ${sqlItemField}, ${pid}, ${sqlRetforField}, ${sqlCshrField}, '${jbind.tm}');
            `;

            did = db.dbInsert(insertSubDocSql);
            ok &= (did !== 0);
            for (let j = 0; ok && j < tranSchedule.length; ++j) {
                if (r !== tranSchedule[j].rowid) continue;
                const insertTranSql = `
                    INSERT INTO documtran (dcmid, amount, dbtid, cdtid)
                    VALUES (${did},
                            ${Number(tranSchedule[j].amount || 0)},
                            ${tranSchedule[j].dbtid},
                            ${tranSchedule[j].cdtid});
                `;

                let tid = db.dbInsert(insertTranSql);
                ok &= (tid !== 0);
            }
        }
    // }

    // console.log(`Bind transaction ${ok ? "OK" : "FALSE !!!"}`);
    // ok = false;
    // console.log(`Bind transaction  ok turned to FALSE !!!`);
    // --- СИНХРОНІЗАЦІЯ ФІНАЛУ ТРАНЗА КЦІЇ ---
    if (ok && pid !== 0) {
        // Якщо ВСІ кроки запису чека та проводок пройшли бездоганно — фіксуємо на диск!
        db.dbCommit();
        return pid; // повертаємо унікальний ID чека для ПРРО-друку
    } else {
        // Якщо стався бодай один збій — скасовуємо весь чек повністю, залишаючи базу в повній чистоті
        db.dbRollback();
        console.log("[sqlTran.js] Критична помилка проведення чека! Транзакцію скасовано SQLite.");
        return 0;
    }
}

/**
 * ВИЗНАЧЕННЯ ТОРГОВОГО ID РАХУНКУ ТА ЙОГО ЕКВІВАЛЕНТІВ (З автоматичним розгортанням тріади)
 */
function acntTrade_id(db, acnt, article = "") {
    let res = {};
    if (article === "") {
        res.errid = 1;
        res.errname = qsTr("Некоректний код валюти / товару");
        return res;
    }

    const itemFilter = `item = '${article}'`;
    const vsql = `SELECT id AS acid, coalesce(eqid, 0) AS eqid, coalesce(rsltid, 0) AS rsid
                FROM acnt LEFT JOIN acntrade ON (id = pkey)
                WHERE acnt.acntno = '${acnt}' AND ${itemFilter};`;

    res = db.dbSelectRow(vsql);

    // ✅ ВИПРАВЛЕНО БАГ АВТОІНКРЕМЕНТУ: Наповнюємо тільки таблицю acntrade.
    // Ваші С++ тригери SQLite t_acntrade_ai самі згенерують супутні eqvl та rslt рахунки!
    if (!res || res.errid !== 0 || Number(res.acid || 0) === 0) {
    // if (res?.acid) {
        const insertTradeAcntSql = `INSERT INTO acntrade (pkey, acntno, article) VALUES ((select max(id)+1 from acnt), '${acnt}', '${article}');`;
        db.dbInsert(insertTradeAcntSql);

        // Перечитуємо дані — тепер вони залізобетонно існують завдяки тригеру бази
        res = db.dbSelectRow(vsql);
    }

    if (!res || res.errid !== 0 || Number(res.acid || 0) === 0) {
        res = { "errid": 1, "errname": qsTr("Відсутній аналітичний рахунок у базі") };
    }

    return res;
}

/**
 * Отримання унікального внутрішнього ID рахунку з таблиці acnt.
 * Якщо рахунку немає в базі — функція автоматично створює його.
 * @param {Object} db - C++ драйвер бази даних DbDriver4
 * @param {string} acnt - Номер/код рахунку (напр. "3000", "3500")
 * @param {string} article - Код валюти або товару (item/article id)
 * @returns {Object} - Об'єкт { acid, eqid, rsid, [errid], [errname] }
 */
function acnt_id(db, acnt, article = "") {
    let res = {};
    if (!db || acnt === undefined || acnt === null || acnt === "") {
        return { "errid": 1, "errname": qsTr("Не вказано номер рахунку") };
    }

    // Формуємо умову для фільтрації валютного або гривневого аналітичного рахунку
    const itemFilter = (article === "") ? "(item IS NULL OR item = '')" : `item = '${article}'`;

    // Чистий SQL-запит за допомогою сучасних шаблонних рядків ES6 замість String().arg
    const vsql = `SELECT id AS acid, 0 AS eqid, 0 AS rsid FROM acnt WHERE acntno = '${acnt}' AND ${itemFilter};`;

    // Шукаємо рахунок у базі даних
    res = db.dbSelectRow(vsql);

    // Якщо рахунок не знайдено (або виникла сервісна помилка) — автоматично створюємо його в SQLite
    if (!res || res.errid !== 0 || Number(res.acid || 0) === 0) {
        // ✅ ВИПРАВЛЕНО СИНТАКСИС NULL: Замість тексту "null" підставляємо суворий системний NULL
        const sqlItemField = (article === "") ? "NULL" : `'${article}'`;
        const insertSql = `INSERT INTO acnt (acntno, item) VALUES ('${acnt}', ${sqlItemField});`;

        db.dbInsert(insertSql);

        // Перечитуємо дані з бази — тепер вони гарантовано існують
        res = db.dbSelectRow(vsql);
    }

    // Кінцева перевірка захисту від збоїв драйвера
    if (!res || res.errid !== 0 || Number(res.acid || 0) === 0) {
        res = {
            "errid": 1,
            "errname": qsTr("Критична помилка: Відсутній або не створений аналітичний рахунок")
        };
    } else {
        // Гарантуємо наявність дефолтних нулів для віртуальних супутніх рахунків
        res.eqid = 0;
        res.rsid = 0;
    }

    return res;
}
