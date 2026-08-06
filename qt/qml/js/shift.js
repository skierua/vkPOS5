.import "v147/config.js" as Conf
.import "v147/sqlAcnt.js" as LibAcnt
.import "v147/sqlItem.js" as LibItem
.import "v147/sqlPrice.js" as LibPrice
.import "v147/sqlShift.js" as LibShift
.import "v147/sqlTran.js" as LibTran

 function handleDriverChanged(db, model, ui){
   if (!db) return;
   const shift = LibShift.crntShift(db);
   if (!shift) return;
   ui.setShiftData(shift);
   const isShiftActive = (shift?.shftend === '');
   ui.setStackIndex(isShiftActive);
   if (isShiftActive){
      // LibShift.dbRefreshTradeRate(db);
   } else {
      const cashiers = LibShift.dbCashier(db) || [];
      model.clear();
      model.append({"code":"", "note":"Оберіть касира...", "psw":"11"})
      for (const row of cashiers) model.append(row);
         // model = cashiers;
      // }
   }

   // populateIncas();
 }

// former BalancingTrade
// moves trade results to profit account
function rsltToProfit(db, bind, cshr) {
   const acntList = LibAcnt.dbBalance(db, `substr(acntno,1,4)='rslt' AND ABS(beginamnt+turndbt-turncdt) > 0.009`);
   let ok = true;
   const tradeMap = new Map();

   if (acntList.length > 0 && typeof bind !== "undefined"){
      const atcl = LibItem.getItemById(db);
      const cashAcntNo = LibAcnt.DfltAcnt.cashAcntNo(db);
      const profitAcntNo = LibAcnt.DfltAcnt.profitAcntNo(db);
      const profitAcnt = LibAcnt.acntbal(db, (profitAcntNo || ""));

      if (!profitAcnt || !cashAcntNo) return null;

      for (let i =0; ok && i < acntList.length; ++i){
         const currentTotal = Number(acntList[i]?.total || 0);
         const rsltAcnt = LibAcnt.acntbal(db, acntList[i].acntno);
         const noteVal = (currentTotal < 0 ? "+++ rslt" : "--- rslt")
         ok &= bind.addDcm( atcl, rsltAcnt, "memo", currentTotal, null, noteVal);

         const tradeAcnt = acntList[i].acntno.substring(5,9);
         // console.log(`bind.js/handleBalancingTrade ${tradeAcnt}`)
         tradeMap.set(tradeAcnt, (tradeMap.get(tradeAcnt) || 0) + currentTotal);

      //    ok &= bind.addMemo(db,
      //                            {"dcm":"memo",
      //                               "amnt":acntList[i].total,
      //                               "cdt":acntList[i].acntno,
      //                               "crn":"",
      //                            "note": (acntList[i].total < 0 ? "+++ rslt" : "--- rslt")})
      }
      const currentPeriod = new Date().toISOString().substring(0, 7); // Формат: YYYY-MM
      for (let k of tradeMap.keys()) {
          const pmnt = 0 - tradeMap.get(k);

          ok &= bind.addDcm( atcl,
                            profitAcnt,
                            "memo",
                            pmnt,
                            null,
                             `${(pmnt < 0 ? "--- rslt" : "+++ rslt")} ${currentPeriod} ${k}`);

      }
      const dcmList = bind.dcmsToTran(cashAcntNo || "");
      if (!dcmList) return null;

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
   return null;
}

function startShift(db, bind, ui) {
    if (!db) return {"status": -1};    // error
   // console.log("dhift.js startShift 111")
    const shift = LibShift.crntShift(db);
    ui.setShiftData(shift);
    // console.log(`10j#shift.js/ shftend=[${shift?.shftend === ""}]`)
    if (shift?.shftend === "") return {"status": -1}; // shift IS active

    // UNBLOCK !!!
    const shid = LibShift.dbStartShift(db, typeof ui.cmb !== "undefined" ? ui.cmb.currentValue : "");
    if (!shid) return {"status": -1};
    const newShift = LibShift.crntShift(db);
    ui.setShiftData(newShift);

    const currentYearMonth = new Date().toISOString().substring(0, 7);
    const isNewMonth = (shift && shift.shftdate.substring(0, 7) !== currentYearMonth);
    const profitAcntNo = LibAcnt.DfltAcnt.profitAcntNo(db);
    // console.log(`10j#shift.js/ profit=${profitAcntNo}`)
   let ok = true;
   if(isNewMonth && !!profitAcntNo){
   // if(1){
      // const acntList = LibAcnt.dbBalance(db, `substr(acntno,1,4)='rslt' AND ABS(beginamnt+turndbt-turncdt) > ${Conf.zero}`);
      const jbind = rsltToProfit(db, bind, shift?.cshr || "")
      if (!jbind) return {
            "status": 0,
            "errstr": "rsltToProfit error"
         }

      const bid = LibTran.tranBind(db, jbind);

      if (bid){
         return {
            "status": bid,
            "bind": jbind
         }
      } else {
         return {
            "status": 0,
            "errstr": "rsltToProfit transaction error"
         }
      }
   }

   return {"status": 1};
}

function finishShift(db, bind) {
   let ok = true;
   let r =0;
   let res = {
      "status": -1,
      "bindList": null,
      "errstr": null
   }

   if (!db) {
       res.errstr = "Критична помилка: Відсутній драйвер БД!";
       return res;
   }

   const cashAcntNo = LibAcnt.DfltAcnt.cashAcntNo(db);
   const shift = LibShift.crntShift(db);
   if (!shift || shift.shftend !== ""){
      res.errstr = "shift IS NOT active";
      return res;
   }

   if (typeof LibTran.tranBind !== "function"
         || typeof LibShift.dbRefreshTradeRate !== "function") {
      res.errstr = "System error: function is missed";
      return res;
   }
   ok = LibShift.dbRefreshTradeRate(db);
   if (!ok) {
      res.errstr = "SQL Error: refresh trade rates";
      return res;
   }

   // TEST AREA START --------------------------

   // tmp_reval(db, bind, cashAcntNo, shift?.cshr || "");
   // return;

   const atcl = LibItem.getItemById(db);
   const t_source = LibShift.dbRevalList(db) || [];
  // console.info(`II: shift.js/tmp_reval#5i5 t_source=${JSON.stringify(t_source)}`)
   const revalSet = new Set(
       t_source
           .filter(v => v && v.eno) // 1. Спочатку відсікаємо записи без eno
           .map(v => {
               const parts = v.eno.split(/\.|\//);
               return parts[1] || "";
           })
           .filter(code => code !== "") // 3. Прибираємо порожні результати з Set
   );
  // revalSet.forEach(k => { console.info(`II: shift.js/tmp_reval#732 k=${k}`); });
  const bindList = [];

  const revalSource = t_source.filter(v => v && (v.amnt !== 0 || v.eqamnt !== 0));
  // console.info(`II: shift.js/tmp_reval#203 revalSource=${JSON.stringify(revalSource)}`)
   for (const crntAcntNo of revalSet) {
      bind.flush();
       // console.info(`II: shift.js/tmp_reval crntAcntNo=${crntAcntNo}`);
      let ok = true;
      const revalAcntSource = revalSource.filter(v => {
                                              const parts = v.eno.split(/\.|\//);
                                              return crntAcntNo === (parts[1] || "");
                                           });
      // console.info(`II: shift.js/tmp_reval#8dj revalAcntSource=${JSON.stringify(revalAcntSource)}`)
      for (const reval of revalAcntSource){
         const priceVal = Number(reval.bscprice || 0);
         const amntVal = Number(reval.amnt || 0);
         if (!priceVal && !!amntVal) continue;
         const eqVal = Number(reval.eqamnt || 0);
         const profitVal = amntVal * priceVal + eqVal;
         if (Math.abs(100 * profitVal) < 1) continue;
         const acntEq = LibAcnt.acntbal(db, String(reval.eno || ""));
         const acntRslt = LibAcnt.acntbal(db, String(reval.rno || ""));
         const noteVal = `${(profitVal < 0 ? "+++" : "---")} reval(${reval.item}) ${reval.amnt} * ${reval.bscprice}`;
         ok &= bind.addDcm( atcl, acntEq, "memo", profitVal, null, noteVal);
         ok &= bind.addDcm( atcl, acntRslt, "memo", 0 - profitVal, null, noteVal);
         // console.info(`II: shift.js/tmp_reval#i24 noteVal=${noteVal} bind.count=${bind.count}`)
      }
      if (ok && !!bind.count){
         const dcmList = bind.dcmsToTran(cashAcntNo);
         if (!dcmList){
             if (ui && typeof ui.vkEvent === "function")
                 ui.vkEvent("error", bind.lastError || "Unknown error");
             return {
                "status": -1,
                "errstr": "Помилка формування ордерів інкасації"
             };
         }
         // const total = bind.total();
         const utcTimeStamp = new Date().toISOString();
         const jbind = {
             "id": "dcmbind",
             "dcm": "folder",
             "dbt": crntAcntNo,
             "cdt": "rslt",
            "amnt": "0.00",
            "eq": "0.00",
            "dsc": "0.00",
            "bns": "0.00",
             "note": "reval",
             "clnt": shift?.cshr || "",
            "cshr": shift?.cshr || "",
             "tm": utcTimeStamp,
             "dcms": dcmList
         }
         const bid = LibTran.tranBind(db, jbind);
         ok &= (bid > 0);
         if (!ok){
            return {
               "status": -1,
               "errstr": "Помилка проведення ордерів інкасації"
            };
         }
         bindList.push(jbind)

      }
   }

//    console.info(`II: shift.js/finishShift#256y bindList=${JSON.stringify(bindList)}`)
// return null;




   // TEST AREA FINISH --------------------------

/*
   const acntList = LibAcnt.dbAcntbal(db, `substr(acntno,1,${Conf.glTradePrefix.length}) = '${Conf.glTradePrefix}'`)
   if (!cashAcntNo || !acntList || typeof bind === "undefined") {
      res.errstr = "Критична помилка: Не налаштовано конфігурацію рахунків каси!";
      return res;
   }
   let bindList = [];
   ok = true;
   if (acntList.length > 0) {
      // console.log(`e001#shift.js bind=${JSON.stringify(acntList)}`)
      const atcl = LibItem.getItemById(db);
      for (r =0; r < acntList.length; ++r){
         bind.flush();
         const source = LibShift.dbRevalList(db, acntList[r].acntno) || [];
         const fltSource = source.filter(v => (v.amnt || 0) === 0 && ((v.eqamnt || 0) !== 0));
         // console.log(`7y3n#shift.js fltSource=${JSON.stringify(fltSource)}`)
         // let eqTotal =0;
         for (let i =0; ok && i < fltSource.length; ++i){
            const totalVal = Number(fltSource[i].eqamnt || 0);
            if (Math.abs(100 * totalVal ) < 1) continue;
            const acntEq = LibAcnt.acntbal(db, String(fltSource[i].eno || ""));
            const acntRslt = LibAcnt.acntbal(db, String(fltSource[i].rno || ""));
            const noteVal = `${(totalVal < 0 ? "+++" : "---")} reval(${fltSource[i].item}) ${fltSource[i].amnt} * ${fltSource[i].bscprice}`;
            // console.log(`ye7#shift.js totalVal=${totalVal}`)
            ok &= bind.addDcm( atcl, acntEq, "memo", totalVal, null, noteVal);
            ok &= bind.addDcm( atcl, acntRslt, "memo", 0 - totalVal, null, noteVal);



            // ok &= bind.addMemo(db, {"dcm":"memo", "amnt": fltSource[i].eqamnt, "cdt": String(fltSource[i].eno || ""), "crn":"", "note": note})
            // ok &= bind.addMemo(db, {"dcm":"memo", "amnt": 0 - fltSource[i].eqamnt, "cdt": String(fltSource[i].rno || ""), "crn":"", "note": note})
            // eqTotal -= fltSource[i].eqamnt;
         }
         if (ok && fltSource.length > 0) {

            const dcmList = bind.dcmsToTran(cashAcntNo);
            if (!dcmList){
                if (ui && typeof ui.vkEvent === "function")
                    ui.vkEvent("error", bind.lastError || "Unknown error");
                return {
                   "status": -1,
                   "errstr": "Помилка формування ордерів інкасації"
                };
            }
            const total = bind.total();
            const utcTimeStamp = new Date().toISOString();
            const jbind = {
                "id": "dcmbind",
                "dcm": "folder",
                "dbt": String(acntList[r].acntno || ""),
                "cdt": "rslt",
               "amnt": (total?.pmnt || 0).toFixed(2),
               "eq": (total?.eq || 0).toFixed(2),
               "dsc": "0.00",
               "bns": "0.00",
                "note": "reval",
                "clnt": shift?.cshr || "",
               "cshr": shift?.cshr || "",
                "tm": utcTimeStamp,
                "dcms": dcmList
            }
            const bid = LibTran.tranBind(db, jbind);
            ok &= (bid > 0);
            if (!ok){
               return {
                  "status": -1,
                  "errstr": "Помилка проведення ордерів інкасації"
               };
            }
            bindList.push(jbind)

         } else if (!ok) {
            // console.log(`17h#shift.js ERROR`)
            return res;
         }
      }

   } */
   // console.log(`w87y#shift.js bind=${JSON.stringify(bindList)}`)
   ok &= db.closeShift(shift.id);
   res.status = (ok ? 1 : -1);
   res.errstr = ok ? null : (db.dbLastError() || "Помилка фіналізації зміни в C++");
   res.bindList = bindList;
   return res;
}

function populateIncas(db, model, ui) {
   // console.log("hs7#shift.js/populateIncas STARTED")
   if (!model || !db) return;
   model.clear();
   let hasIncas = false;
   const bulkAcntNo = LibAcnt.DfltAcnt.bulkAcntNo(db);
   if (!bulkAcntNo) {
      ui.setHasIncas(hasIncas);
      return;
   }
   const tradeAcntNo = LibAcnt.DfltAcnt.tradeAcntNo(db);

   const source = LibShift.dbRevalList(db, tradeAcntNo) || [];
   // let vam = 0;
   const modelData = source
   .filter(v => v.amnt !==0 || v.eqamnt !== 0 )
   .map(v => {
            const item = LibItem.getItemById(db, v.item);      // itemSource
           // const item = {
           //                 "id": itemSource.id,
           //                 "itemchar": itemSource.itemchar,
           //                 "itemnote": itemSource.itemnote,
           //                 "mask": itemSource.mask,
           //                 "qty": itemSource.qty,
           //                 // "": itemSource.,
           //              };
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
}

function handleIncasAction(db, model, bind){
   if (!db) return { "status": -1, "bind": null };
   const shift = LibShift.crntShift(db);
   if (!shift || shift.shftend !== "") return {"status": -1, "bind": null}; // error or shift IS NOT active

   const cashAcntNo = LibAcnt.DfltAcnt.cashAcntNo(db);
   const tradeAcntNo = LibAcnt.DfltAcnt.tradeAcntNo(db);
   const bulkAcntNo = LibAcnt.DfltAcnt.bulkAcntNo(db);
   const tradeAcnt = LibAcnt.DfltAcnt.trade(db);
   const bulkAcnt = LibAcnt.acntbal(db, bulkAcntNo, true);

   if (!cashAcntNo || !tradeAcnt || !bulkAcnt
         || typeof model === "undefined" || typeof bind === "undefined") {
       return { "status": -1, "bind": null, "errstr": "Критична помилка: Не налаштовано конфігурацію рахунків каси!" };
   }
   bind.flush();
   // let totalEq = 0;
   let ok = true;
   for (let r = 0; ok && r < model.count; ++r) {
       let rowItem = model.get(r);
       let incasValue = Number(rowItem.incas || 0);
       if (Math.abs(incasValue) > Conf.zero) {
           let priceNum = Number(rowItem.priceVal || 0);
           let qtyNum = Number(rowItem.priceQty || 1) === 0 ? 1 : Number(rowItem.priceQty);
           let eq = (incasValue * priceNum) / qtyNum;
           // totalEq += eq;
            const priceObj = {"price": priceNum, "qty": qtyNum};

          ok &= bind.addDcm(rowItem.item, bulkAcnt, "trade:inner", 0 - rowItem.amnt, priceObj, String(rowItem.item?.itemchar || ""))
          ok &= bind.addDcm(rowItem.item, tradeAcnt, "trade:inner", rowItem.amnt, priceObj, String(rowItem.item?.itemchar || ""))
       }
   }
   // bindModel.eqTotal = totalEq;
   const dcmList = bind.dcmsToTran(cashAcntNo);
   if (!dcmList){
       if (ui && typeof ui.vkEvent === "function")
           ui.vkEvent("error", model.lastError || "Unknown error");
       return;
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
       "clnt": shift?.cshr || "",
      "cshr": shift?.cshr || "",
       "tm": utcTimeStamp,
       "dcms": dcmList
   }
   const bid = LibTran.tranBind(db, jbind);

   if (bid){
      return {
         "status": bid,
         "bind": jbind
      }
   }
   return {
      "status": -1,
      "errstr": "Помилка формування ордерів інкасації"
   }
}

function isIncas(db){
   const bulkAcntNo = LibAcnt.DfltAcnt.bulkAcntNo(db);
   return !!bulkAcntNo;
}


function tmp_reval(db, bind, cashAcntNo, cshr){
    // const t_acntList = LibAcnt.dbAcntbal(db, `substr(acntno,1,${Conf.glTradePrefix.length}) = '${Conf.glTradePrefix}'`)
    // console.info(`II: shift.js/tmp_reval t_acntList=${JSON.stringify(t_acntList)}`)
    const atcl = LibItem.getItemById(db);
    const t_source = LibShift.dbRevalList(db) || [];
   // console.info(`II: shift.js/tmp_reval#5i5 t_source=${JSON.stringify(t_source)}`)
    const revalSet = new Set(
        t_source
            .filter(v => v && v.eno) // 1. Спочатку відсікаємо записи без eno
            .map(v => {
                const parts = v.eno.split(/\.|\//);
                return parts[1] || "";
            })
            .filter(code => code !== "") // 3. Прибираємо порожні результати з Set
    );
   // revalSet.forEach(k => { console.info(`II: shift.js/tmp_reval#732 k=${k}`); });
   const bindList = [];

   const revalSource = t_source.filter(v => v && (v.amnt !== 0 || v.eqamnt !== 0));
   // console.info(`II: shift.js/tmp_reval#203 revalSource=${JSON.stringify(revalSource)}`)
    for (const crntAcntNo of revalSet) {
       bind.flush();
        console.info(`II: shift.js/tmp_reval crntAcntNo=${crntAcntNo}`);
       let ok = true;
       const revalAcntSource = revalSource.filter(v => {
                                               const parts = v.eno.split(/\.|\//);
                                               return crntAcntNo === (parts[1] || "");
                                            });
       console.info(`II: shift.js/tmp_reval#8dj revalAcntSource=${JSON.stringify(revalAcntSource)}`)
       for (const reval of revalAcntSource){
          const priceVal = Number(reval.bscprice || 0);
          const amntVal = Number(reval.amnt || 0);
          if (!priceVal && !!amntVal) continue;
          const eqVal = Number(reval.eqamnt || 0);
          const profitVal = 0 - amntVal * priceVal - eqVal; // TODO
          if (Math.abs(100 * profitVal) < 1) continue;
          const acntEq = LibAcnt.acntbal(db, String(reval.eno || ""));
          const acntRslt = LibAcnt.acntbal(db, String(reval.rno || ""));
          const noteVal = `${(profitVal < 0 ? "+++" : "---")} reval(${reval.item}) ${reval.amnt} * ${reval.bscprice}`;
          ok &= bind.addDcm( atcl, acntEq, "memo", profitVal, null, noteVal);
          ok &= bind.addDcm( atcl, acntRslt, "memo", 0 - profitVal, null, noteVal);
          console.info(`II: shift.js/tmp_reval#i24 noteVal=${noteVal} bind.count=${bind.count}`)
       }
       if (ok && !!bind.count){
          const dcmList = bind.dcmsToTran(cashAcntNo);
          if (!dcmList){
              if (ui && typeof ui.vkEvent === "function")
                  ui.vkEvent("error", bind.lastError || "Unknown error");
              return {
                 "status": -1,
                 "errstr": "Помилка формування ордерів інкасації"
              };
          }
          // const total = bind.total();
          const utcTimeStamp = new Date().toISOString();
          const jbind = {
              "id": "dcmbind",
              "dcm": "folder",
              "dbt": crntAcntNo,
              "cdt": "rslt",
             "amnt": "0.00",
             "eq": "0.00",
             "dsc": "0.00",
             "bns": "0.00",
              "note": "reval",
              "clnt": cshr || "",
             "cshr": cshr || "",
              "tm": utcTimeStamp,
              "dcms": dcmList
          }
          const bid = LibTran.tranBind(db, jbind);
          ok &= (bid > 0);
          if (!ok){
             return {
                "status": -1,
                "errstr": "Помилка проведення ордерів інкасації"
             };
          }
          bindList.push(jbind)

       }
    }
    console.info(`II: shift.js/tmp_reval#938n bindList=${JSON.stringify(bindList)}`)
    return bindList;
}



