.import "libREST.js" as REST
// .import "CashDesk.js" as TAX
// .import "v147/config.js" as Conf
.import "v147/sqlAcnt.js" as LibAcnt
.import "v147/sqlBalance.js" as LibBal
.import "v147/sqlItem.js" as LibItem
.import "v147/sqlPrice.js" as LibPrice
.import "v147/sqlRepo.js" as LibRepo
.import "v147/sqlShift.js" as LibShift
.import "v147/sqlTran.js" as LibTran

let LAST_ERROR = "";
// Оголошуємо властивість-геттер для читання ззовні
Object.defineProperty(this, "lastError", {
    get: function() { return LAST_ERROR; },
    configurable: true
});

function handleDriverChanged(db, model, ui){
   if (!db) return;
   const shift = LibShift.crntShiftData(db);
   if (!shift) return;
   ui.setShiftData(shift);
   const dfltAcnts = LibAcnt.DfltAcnt.acnts(db);
   // console.info(`II: shift.js/handleDriverChanged bulk=[${dfltAcnts?.bulk}]`)
   const hasBulkVal = !!dfltAcnts?.bulk || false;
   ui?.setHasBulk?.(hasBulkVal);
   // console.info(`II: shift.js/handleDriverChanged hasBulkVal=[${hasBulkVal}]`)
   // const isShiftActive = (shift?.shftend === '');
   ui.setStackIndex(shift.isActive);
   if (shift.isActive){
      // LibShift.dbRefreshTradeRate(db);
   } else {
      const cashiers = [{"code":"", "note":"Оберіть касира...", "psw":"11"},
                        ...(LibShift.dbCashier(db) || []).sort((a,b) => a.note.localeCompare(b.note))];

      model.clear();
      cashiers.forEach(row => model.append(row));
   }

   // populateIncas();
}


function buildRsltBind(db, bind, cshr){
   if (!bind && typeof bind.rsltToProfit === 'function') return null;

   bind.flush();
   bind.rsltToProfit(db);
   const cashAcntNo = LibAcnt.DfltAcnt.cashAcntNo(db);
   const dcmList = bind.dcmsToTran(cashAcntNo || "");

   const total = bind.total();
   const utcTimeStamp = new Date().toISOString();
   const jbind = {
       "id": "dcmbind",
       "dcm": "folder",
       "dbt": "profit",
       "cdt": "blnc",
      "amnt": (total?.pmnt || 0).toFixed(2),
      "eq": (0 - Number(total?.pmnt || 0)).toFixed(2),
      "dsc": (total?.dsc || 0).toFixed(2),
      "bns": (total?.bns || 0).toFixed(2),
       "note": "rslt>profit",
       "clnt": "",
      "cshr": cshr || "",
       "tm": utcTimeStamp,
       "dcms": dcmList
   }
   return jbind;
}

function startShift(db, bind, ui) {
   if (!db) {
      if (!!ui && typeof ui.error === "function") ui.error("DB connection is broken");
      return -1;
   };
   // console.log("dhift.js startShift 111")
    const shift = LibShift.crntShiftData(db);
    ui.setShiftData(shift);
    // console.log(`10j#shift.js/ shftend=[${shift?.shftend === ""}]`)
    if (shift?.isActive) {
       if (!!ui && typeof ui.warn === "function") ui.warn("shift IS allready active");
       return -1;
    }

    // UNBLOCK !!!
    const shid = LibShift.dbStartShift(db, ui.cshr || "");
    if (!shid) {
       if (!!ui && typeof ui.error === "function") ui.error("DB не вдалося відкрити зміну");
       return -1;
    }
    const newShift = LibShift.crntShiftData(db);
    ui.setShiftData(newShift);

    const currentYearMonth = new Date().toISOString().substring(0, 7);
    const lastShiftMonth = shift.date.substring(0, 7)
    const isNewMonth = (lastShiftMonth !== currentYearMonth);

   if(isNewMonth){
   // if(1){
      // send reports to REST API
      if (REST.IS_CONNECTED || false){
         uploadMonRepoAsync(db, lastShiftMonth)
                 .then(function(result) {
                    ui.info("Звіт за попередній місяць синхронізовано:");
                 })
                 .catch(function(error) {
                     LAST_ERROR = error.text;
                     ui.error("Помилка відправки звіту за попередній місяць: " + error.text);
                 });
      }

      let bid = 0;
      const jbind = buildRsltBind(db, bind, shift?.cshrId || "")
      if (!!jbind && jbind.dcms.length > 0) {
         bid = LibTran.tranBind(db, jbind);
      }
      // if (!!ui && typeof ui.warn === "function") ui.warn("Bind fo rslt is empty");
      // return -1;


      if (!!bid && REST.IS_CONNECTED){
         sendBindToRESTAsync(db, jbind)
             .then((msg) => {
                 ui.info("Операції успішно відправлено на сервер.");
             })
             .catch((err) => {
                 if (err === "REST_DISCONNECTED") {
                     ui.warn("Немає зв'язку з сервером, дані збережено локально.");
                     resolve();
                 } else {
                     LAST_ERROR = err;
                     ui.error("Помилка переоцінки: " + err);
                 }
             });
      } else {
         if (!!ui && typeof ui.warn === "function") ui.warn("Помилка проведення балансування TRADE");
         // return -1;
      }
   }

   if (!!ui && typeof ui.info === "function") ui.info("Зміну успішно ВІДКРИТО");

   return 0;
}

function finishShift(db, bind, ui) {
   LAST_ERROR = "";
   let ok = true;

   if (!db) {
      // if (!!ui && typeof ui.error === "function") ui.error("DB connection is broken");
      LAST_ERROR = "DB connection is broken";
      return -1;
   };

   const cashAcntNo = LibAcnt.DfltAcnt.cashAcntNo(db);
   const shift = LibShift.crntShiftData(db);
   if (!shift || !shift.isActive) {
      // if (!!ui && typeof ui.warn === "function") ui.warn("shift IS NOT active");
      LAST_ERROR = "shift IS NOT active";
      return -1;
   }


   ok = bind.tradeRevaluation(db);
   if (ok && !!bind.count){
      const dcmList = bind.dcmsToTran(cashAcntNo);
      if (!!dcmList && dcmList.length > 0){
         // if (!!ui && typeof ui.error === "function")
         //    ui.error(bind.lastError || "Помилка формування ордерів інкасації" || "Bind unknown error");

         // const total = bind.total();
         const utcTimeStamp = new Date().toISOString();
         const jbind = {
             "id": "dcmbind",
             "dcm": "folder",
             "dbt": cashAcntNo,
             "cdt": "rslt",
            "amnt": "0.00",
            "eq": "0.00",
            "dsc": "0.00",
            "bns": "0.00",
             "note": "reval",
             "clnt": shift?.cshrId || "",
            "cshr": shift?.cshrId || "",
             "tm": utcTimeStamp,
             "dcms": dcmList
         }

         // console.info(`shift.js#98u3 bind=${JSON.stringify(jbind)}`);
         // continue;
         const bid = LibTran.tranBind(db, jbind);
         if (bid > 0){
            // всередині вашої великої функції закриття зміни:
            ui.info("Синхронізація даних з REST...");

            if (REST.IS_CONNECTED){
               sendBindToRESTAsync(db, jbind)
                   .then((msg) => {
                       ui.info("Дані успішно відправлено на сервер.");
                       // Переходимо до наступного кроку (наприклад, закриття в локальній БД)
                       // return nextStepPromise();
                   })
                   .catch((err) => {
                       if (err === "REST_DISCONNECTED") {
                           ui.warn("Немає зв'язку з сервером, дані збережено локально.");
                           resolve();
                       } else {
                           LAST_ERROR = err;
                           ui.error("Помилка переоцінки: " + err);
                       }
                   });
            }

         } else {
            ui?.error("Помилка проведення переоцінки");
            LAST_ERROR = "Помилка проведення переоцінки";
            console.info("II:#5tw shift.js ", LAST_ERROR)
            return -1;
         }
      }
   }

   // if (!!ui && typeof ui.info === "function") ui.info("Переоцінку успішно завершено");


//    console.info(`II: shift.js/finishShift#256y bindList=${JSON.stringify(bindList)}`)
// return null;

   // console.log(`w87y#shift.js bind=${JSON.stringify(bindList)}`)
   ok = db.closeShift(shift.id);

   if (!ok){
      // if (!!ui && typeof ui.error === "function")
      ui.error(db.dbLastError() || "Помилка фіналізації зміни в C++");
      LAST_ERROR = "Помилка фіналізації зміни в C++";
      // console.info("II:#42s shift.js ", LAST_ERROR)
      return -1;
   }

   // send reports to REST API
   // if (1){
   if (REST.IS_CONNECTED){
      const period = new Date().toISOString().substring(0, 7);
      uploadMonRepoAsync(db, period)
              .then(function(result) {
                  // Цей блок виконується як код після await
                  // console.log("Звіт синхронізовано:", JSON.stringify(result));
                 ui.info("Звіт синхронізовано");
                  // bindModel.update(result);
              })
              .catch(function(error) {
                  // Сюди прилетить помилка мережі, статус 0 або код 'EE'
                  LAST_ERROR = error.text;
                  ui.error("Помилка: " + error.text);
              });
   }
   return 0;
}

function populateIncas(db, model, ui) {
   // console.log("hs7#shift.js/populateIncas STARTED")
   if (!db) {
      if (ui && typeof ui.error === "function") ui.error("DB connection is broken");
      return -1;
   };
   model.clear();
   let hasIncas = false;
   const bulkAcntNo = LibAcnt.DfltAcnt.bulkAcntNo(db);
   const tradeAcntNo = LibAcnt.DfltAcnt.tradeAcntNo(db);

   if (!bulkAcntNo) {
      ui.setHasIncas(hasIncas);
      if (!!ui && typeof ui.warn === "function") ui.error("Немає рахунку інкасації!");
      return -1;
   }

   const source = LibShift.dbRevalList(db, tradeAcntNo) || [];
   // let vam = 0;
   const modelData = source
   .filter(v => v.amnt !==0 || v.eqamnt !== 0 )
   .map(v => {
            const item = LibItem.getItemById(db, v.item);      // itemSource
            const buyPrice = LibPrice.buy(db, v.item);
            const qtyVal = Number(buyPrice?.qtty || item?.qty || 1)
           // console.log(`item=${v.item} qtyVal=[${qtyVal}] pq=[${buyPrice?.qtty}] iq=[${item?.qty}]`)
            return {
               "item": item,
               "amnt": v.amnt,
               "eqamount": v.eqamnt,
               "incas": 0 - v.amnt,
              "priceVal": v.bscprice * qtyVal  || (Number(buyPrice?.price ?? 0) * qtyVal / (buyPrice?.qtty|| 1)) || 0,
              "priceQty": qtyVal
            };
         })
    // console.log(`e7u#shift.js len=${JSON.stringify(modelData)}`)
    // if (modelData && Array.isArray(modelData) && modelData.length > 0) {
    if (modelData && modelData.length > 0) {
       modelData.sort((a, b) => Number(a.item?.itemnote || 0) - Number(b.item?.itemnote || 0));
        for (let r = 0; r < modelData.length; ++r) {
           // console.log(`27h#shift.js ${JSON.stringify(modelData[r])}`)
           if (modelData[r].item?.mask === 2) {
               model.append(modelData[r]);
               hasIncas |= (Number(modelData[r].amnt || 0) !== 0)
               // vam += Math.abs(Number(modelData[r].amnt || 0));
            }
        }
    }
    // vw.amntTotal = vam;
    ui.setHasIncas(hasIncas);
    if (!!ui && typeof ui.info === "function")
       ui.info(hasIncas ? "Інкасацію сформовано" : "Інкасація не потібна");
}

function handleIncasAction(db, model, bind, ui){
   if (!db) {
      if (!!ui && typeof ui.error === "function") ui.error("DB connection is broken");
      return -1;
   };
   const shift = LibShift.crntShiftData(db);
   if (!shift || !shift.isActive) {
      if (!!ui && typeof ui.warn === "function") ui.warn("shift IS NOT active");
      return -1;
   }

   const cashAcntNo = LibAcnt.DfltAcnt.cashAcntNo(db);
   const tradeAcntNo = LibAcnt.DfltAcnt.tradeAcntNo(db);
   const bulkAcntNo = LibAcnt.DfltAcnt.bulkAcntNo(db);
   const tradeAcnt = LibAcnt.DfltAcnt.trade(db);
   const bulkAcnt = LibAcnt.acntbal(db, bulkAcntNo, true);

   if (!cashAcntNo || !tradeAcntNo || !bulkAcntNo
         || typeof model === "undefined" || typeof bind === "undefined") {
      if (!!ui && typeof ui.error === "function") ui.error("Критична помилка: Не налаштовано конфігурацію рахунків каси!");
      return -1;
   }
   bind.flush();
   // let totalEq = 0;
   let ok = true;
   for (let r = 0; ok && r < model.count; ++r) {
       let rowItem = model.get(r);
       let incasValue = Number(rowItem.incas || 0);
       if (Math.abs(incasValue) > 0.0001) {
           let priceNum = Number(rowItem.priceVal || 0);
           let qtyNum = Number(rowItem.priceQty || 1) === 0 ? 1 : Number(rowItem.priceQty);
           let eq = (incasValue * priceNum) / qtyNum;
           // totalEq += eq;
            const priceObj = {"price": priceNum, "qty": qtyNum};
          const dcm_1 = {
             atclId: rowItem.item.id,
             acntNo: bulkAcntNo,
             amnt: 0 - rowItem.amnt,
             type: "trade:inner",
             note: String(rowItem.item?.itemchar || ""),
             jprice: priceObj
          }
          const dcm_2 = {
             atclId: rowItem.item.id,
             acntNo: tradeAcntNo,
             amnt: rowItem.amnt,
             type: "trade:inner",
             note: String(rowItem.item?.itemchar || ""),
             jprice: priceObj
          }
         ok &= bind.addDcm(db, dcm_1);
         ok &= bind.addDcm(db, dcm_2);
          // ok &= bind.addDcm(rowItem.item, bulkAcnt, "trade:inner", 0 - rowItem.amnt, priceObj, String(rowItem.item?.itemchar || ""))
          // ok &= bind.addDcm(rowItem.item, tradeAcnt, "trade:inner", rowItem.amnt, priceObj, String(rowItem.item?.itemchar || ""))
       }
   }
   // bindModel.eqTotal = totalEq;
   const dcmList = bind.dcmsToTran(cashAcntNo);
   if (!dcmList){
      if (!!ui && typeof ui.error === "function") ui.error(bind.lastError || "Bind serialization error");
       return -1;
   }
   const utcTimeStamp = new Date().toISOString();
   const jbind = {
       "id": "dcmbind",
       "dcm": "folder",
       "dbt": "incas",
       "cdt": "bulk",
       "amnt": "0.00",
       "eq": "0.00",
       "dsc": "0.00",
       "bns": "0.00",
       "note": "incas>bulk",
       "clnt": shift?.cshrId || "",
      "cshr": shift?.cshrId || "",
       "tm": utcTimeStamp,
       "dcms": dcmList
   }
   // console.info(`shift.js#u621 bind=${JSON.stringify(jbind)}`);
   // return;
   const bid = LibTran.tranBind(db, jbind);

   if (!bid || bid < 0){
      if (!!ui && typeof ui.error === "function") ui.error("Помилка формування ордерів інкасації");

      return -1;
   }
   if (REST.IS_CONNECTED){
      sendBindToRESTAsync(db, jbind)
          .then((msg) => {
              ui.info("Дані успішно відправлено на сервер.");
          })
          .catch((err) => {
              if (err === "REST_DISCONNECTED") {
                  ui.warn("Немає зв'язку з сервером, дані збережено локально.");
                  resolve();
                  // Тут можна зробити resolve(), щоб не переривати закриття зміни через офлайн
              } else {
                  LAST_ERROR = err;
                  ui.error("REST Помилка інкасації: " + err);
              }
          });
   }
   if (!!ui && typeof ui.info === "function") ui.info("Валюти успішно ІНКАСОВАНО");
   return bid;
}

function isIncas(db){
   const bulkAcntNo = LibAcnt.DfltAcnt.bulkAcntNo(db);
   return !!bulkAcntNo;
}

function uploadMonRepoAsync(url, period) {
    return new Promise((resolve, reject) => {
      if (!REST || typeof REST.uploadMonRepo !== "function") {
         return reject("REST_DISCONNECTED");
      }
        REST.uploadMonRepo(url, period, (err, resp) => {
            if (err) {
                // Якщо є помилка, передаємо її в секцію .catch()
                reject(err);
            } else {
                // Якщо все добре, передаємо результат у наступний .then()
                resolve(resp);
            }
        });
    });
}

function uploadBalancePromise(db) {
    return new Promise((resolve, reject) => {
        if (!REST || typeof REST.uploadBalance !== "function") {
            return resolve(); // Якщо методу немає, просто пропускаємо без помилки
        }
        REST.uploadBalance(db, (err) => {
            if (err) reject("REST sync error: " + err);
            else resolve();
        });
    });
}

function uploadBindPromise(jbind) {
    return new Promise((resolve, reject) => {
        if (!REST || typeof REST.uploadBind !== "function") {
            return reject("REST.uploadBind is missing");
        }
        REST.uploadBind(jbind, (err) => {
            if (err) reject("REST sending error: " + err);
            else resolve();
        });
    });
}

function sendBindToRESTAsync(db, jbind) {
    return new Promise((resolve, reject) => {
        if (!REST.IS_CONNECTED) {
            return reject("REST_DISCONNECTED");
        }

        Promise.all([
            uploadBalancePromise(db),
            uploadBindPromise(jbind)
        ])
        .then(() => {
            // Обидва запити завершилися успішно
            resolve("Sync successful");
        })
        .catch((error) => {
            // Будь-яка помилка з балансу або біндінгу прилетить сюди
            console.warn(error);
            reject(error);
        });
    });
}

// uploadBalancePromise(db)
//     .then(() => uploadBindPromise(jbind))
//     .then(() => resolve())
//     .catch(reject);
