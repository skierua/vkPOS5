// ModelBind.qml (Частина 1: Оптимізований фінансовий процесор транзакцій)
import QtQuick

import "js/v147/config.js" as Conf
import "js/v147/sqlAcnt.js" as LibAcnt
import "js/v147/sqlBalance.js" as LibBal
import "js/v147/sqlItem.js" as LibItem
import "js/v147/sqlPrice.js" as LibPrice
import "js/v147/sqlShift.js" as LibShift

// dcm: {
//     dsign: number (-1 | 1),
//     dcode: string,
//     darticle: atStringcl,
//     dacnt: acnt,
//     damnt: number ( > 0 ),
//     dnote: string,
//     dprice: number ( >= 0 ) =0.0,
//     dpriceQty: number ( >= 0 ) =1,
//     drate: number ( >= 0 ) =1,
//     retfor: string =''
// };

ListModel {
    id: mRoot

    property real crntDsc: 0    //  0 <= crntDsc <= 1
    property real crntBns: 0    //  0 <= crntBns <= 1

    property real rate: 1

    property string lastError: ""   // Текст останньої помилки для індикації касиру

    signal vkEvent(string id, var param)

    function dbg(str, code = "") {
        console.log(`[ModelBind.qml]#${code} ${str}`);
    }

    function flush() {
        clear();
        mRoot.crntDsc = 0;
        mRoot.crntBns = 0;
        mRoot.rate = 1;
        mRoot.lastError = "";

        // bindCdt = "";
        // note = "";

        // recalculate();
    }

    function dummy(){
        const dcm = {
            dsign: 0,
            dcode: "",
            darticleId: "",
            darticlePrec: 2,
            darticleMask: 0,
            dacntNo: "",
            dacntNote: "",
            damnt: 0,
            dnote: "",
            disTrade: false,
            dprice: 0.0,
            dpriceDsc: 0.0,
            dpriceBns: 0.0,
            dpriceType: "", // ''|'offer'
            dpriceQty: 1,
            drate: 1,
            dscEditable: false,
            moneyEq: 0.0,
            moneyDsc: 0.0,
            moneyBns: 0.0,
            dnotetag: '',
            retfor: "",
            err: ""
        };
        return dcm;
    }

    // Сувора валідація параметрів проводки (Захист від некоректних даних)
    function isCorrect(atcl, acnt, dtype, amnt) {
        let errstr = null;
        if (!atcl)
            errstr = "Параменти. Відсутній валюта/артикул документу";
        if (!acnt)
            errstr = "Параменти. Відсутній рахунок документу";
        if (!dtype)
            errstr = "Параменти. Відсутній код типу документу";
        if (amnt === undefined || amnt === 0)
            errstr = "Параменти. Відсутня сума документу";

        let atclMask = Number(atcl?.mask || 0);
        let acntMask = Number(acnt?.mask || 0);

        if ((atclMask & acntMask) === 0)
            errstr = "Не сумісний артикул та рахунок документу";
        if (acnt.acntno === "")
            errstr = "Відсутній код рахунку документу";

        if (!errstr)
            return true;
        mRoot.lastError = errstr;
        return false;
    }


    function dcmsToTran(targetAcntNo) {
        mRoot.lastError = "";
        if (!targetAcntNo){
            mRoot.lastError = "Відсутній рахунок пакету документів.";
            return null;
        }
        let ok = true;
        let dcmList = []
        let errstr = "";
        // const utcTimeStamp = new Date().toISOString();  //.substring(0, 19);
        for (let r = 0; ok && r < count; ++r) {
            let row = get(r);
            // console.log(`ModelBind#s729 ${JSON.stringify(row)}`); return;
            // console.log(`ModelBind#s729 1=[${!!(row.dcode || "")}] 2=[${Number(row.amnt || 0) !== 0}]`)
            let precision = Number(row.darticlePrec || 2);

            ok &= (!!(row.dcode || "") && (Number(row.damnt || 0) !== 0));
            if (row.disTrade || false) {
                ok &= Number(row.moneyEq || 0) !== 0
            }

            // if ((row.dacnt?.trade || 0) !== 0) {
            //     ok &= (row.moneyEq !== 0)
            // }
            errstr += (row.err || "");
            // const rowPrice = {
            //     "price": row.jprice?.offer || row.jprice?.price || 0,
            //     "qty": row.jprice?.qty || 1
            // }
            dcmList.push({
                "dcm": row.dcode,
                "dbt": targetAcntNo,
                "cdt": row.dacntNo || "",
                "crn": row.darticleId || "",
                "amnt": (row.dsign * Number(row.damnt || 0)).toFixed(precision),
                "eq": (row.moneyEq || 0).toFixed(2),
                "dsc": (row.moneyDsc || 0).toFixed(2),
                "bns": (row.moneyBns || 0).toFixed(2),
                "note": `${row.dnote || ""}${row.dnotetag}`,
                // "jitem": row.darticle,
                // "tm": utcTimeStamp,
                "retfor": row.retfor || ""
            });
        }

        // console.log(`ModelBind#7at2 ${JSON.stringify(dcmList)}`); return;
        if ( ok ) return dcmList;
        mRoot.lastError = "Serialization error";
        return null;
    }

    // ДОДАВАННЯ ОДНОГО ДОКУМЕНТА (ПРОВОДКИ) В ЧЕК
/*    jdata{
        atclId,
        acntNo,
        amnt,
        type,
        note?,
        jprice?{
            id?,    // rowid in DB
            item?,  // itemid
            qty?,
            price?,
            offer?,
            dsc?,
            bsc?,
        }
    } */
    function addDcm(db, jdata) {
        // console.log(`II: START ModelBind/addDcm#103k`, JSON.stringify(jdata));
        const atclIdData = String(jdata?.atclId || "")
        const acntNoData = String(jdata?.acntNo || "")

        const jatcl = LibItem.getItemById(db, atclIdData);
        const jacnt = !!acntNoData ? LibAcnt.acntbal(db, acntNoData)
                     : LibAcnt.DfltAcnt.trade(db);
        // console.log(`II: ModelBind/addDcm#82js`, JSON.stringify(jatcl));
        const typeVal = String(jdata?.type || "");

        if (!jatcl || !jacnt || !typeVal) {
            mRoot.lastError = "Document parameter missing";
            return false;
        }

        const signVal = Number(jdata?.amnt || 0) < 0 ? -1 : 1;
        const noteVal = String(jdata?.note || "");
        const atclIdVal = String(jatcl?.id || "");
        const atclPrecVal = Number(jatcl?.unitprec ?? 2);
        const atclMaskVal = Number(jatcl?.mask || 0);
        let noteTagVal = '';

        const acntNoVal = String(jacnt?.acntno || "");
        const acntNoteVal = String(jacnt?.note || "");
        const acntMaskVal = Number(jacnt?.mask || 0);

        if ((atclMaskVal & acntMaskVal) === 0){
            mRoot.lastError = "Не сумісний артикул та рахунок документу";
            return false;
        }

        const isTrade = Number(jacnt?.trade ?? 0) === 1;
        // const dtag = (price?.offer) ? "#АКЦІЯ!" : (price?.dsc ? "#ЗНИЖКА!" : "")
        // const dnote = `${String(atcl.itemchar || "")}${Number(acnt.trade || 0) !== 0
        //             ? "" : ` [${acnt.clname || ""}/${acnt.note || ""}]`} ${dtag}`;
        const idx = 0;
        const absAmnt = Math.abs(Number(jdata?.amnt || 0));
        const rndAmnt = Number.isInteger(absAmnt) ? absAmnt : Math.round(absAmnt * 1000) / 1000;
        const dcm = dummy();
        dcm.dsign = signVal
        dcm.dcode = typeVal
        dcm.darticleId = atclIdVal
        dcm.darticlePrec = atclPrecVal
        dcm.darticleMask = atclMaskVal
        dcm.dacntNo = acntNoVal
        dcm.dacntNote = acntNoteVal
        dcm.damnt = rndAmnt
        dcm.dnote = noteVal
        dcm.disTrade = isTrade

/*        let dcm = {
            dsign: signVal,
            dcode: typeVal,
            darticleId: atclIdVal,
            darticlePrec: atclPrecVal,
            darticleMask: atclMaskVal,
            dacntNo: acntNoVal,
            dacntNote: acntNoteVal,
            damnt: rndAmnt,
            dnote: noteVal,
            disTrade: isTrade,
            dprice: 0.0,
            dpriceDsc: 0.0,
            dpriceBns: 0.0,
            dpriceType: "", // ''|'offer'
            dpriceQty: 1,
            drate: 1,
            dscEditable: true,
            moneyEq: 0.0,
            moneyDsc: 0.0,
            moneyBns: 0.0,
            dnotetag: '',
            retfor: "",
            err: ""
        }; */

        if (isTrade){
            // if (!jdata?.jprice) {
            //     mRoot.lastError = "Document rate's missing";
            //     return false;
            // }
            dcm.dpriceQty = jdata.jprice?.qty || 1;
            dcm.drate = mRoot.rate;

            if (jatcl.mask === 4) { // articles
                if (!!jdata.jprice?.offer){
                    dcm.dprice = jdata.jprice.offer;
                    dcm.dscEditable = false;
                    dcm.dpriceType = 'offer';
                    noteTagVal = 'АКЦІЯ!';
                } else {
                    dcm.dprice = jdata.jprice?.price || jdata.jprice?.bsc || 0;
                    dcm.dscEditable = !jdata.jprice?.dsc
                    dcm.dpriceDsc = jdata.jprice?.dsc || mRoot.crntDsc;
                    dcm.dpriceBns = mRoot.crntBns;
                }
                dcm.dprice /= mRoot.rate
                dcm.dnotetag = !!noteTagVal ? `# ${noteTagVal}` : '';
            } else {
                dcm.dprice = mRoot.rate !== 1 ? 1 : jdata.jprice?.price || jdata.jprice?.bsc || 0;
                dcm.dscEditable = false
            }

            // dcm.jprice = price;
        }
// console.log(`II: ModelBind#42t1 ${JSON.stringify(dcm)}`)
        insert(idx, dcm);
        setDcmTradeData(idx);
        // for (let r =0; r < count; ++r) console.log(`II: ModelBind#i920 ${JSON.stringify(get(r))}`)

        return true;
    }

    function addRefused(db,dcm/*, atcl, acnt*/) {
        if (!dcm) return false;
        console.log(`ModelBind/addRefused 111`)

        const dtype = String(dcm.dcmtype || "");
        const amntMoney = 0 - Number(dcm.amount || 0);
        const eqMoney = 0 - Number(dcm.eqamount || 0)
        const dscMoney = 0 - Number(dcm.discount || 0)
        const bnsMoney = 0 - Number(dcm.bonus || 0)
        const jatcl = LibItem.getItemById(db, String(dcm.itemid || ""));
        const jacnt = LibAcnt.acntbal(db, String(dcm.acntcdt || ""));
        if (!isCorrect(jatcl, jacnt, dtype, amntMoney)) {
            mRoot.lastError = `Непідтримувані параметри документу.\n${JSON.stringify(dcm)}`;
            return false;
        }
        const atclPrecVal = Number(jatcl?.unitprec ?? 2);
        const atclMaskVal = Number(jatcl?.mask || 0);
        const acntNoVal = String(jacnt?.acntno || "");
        const acntNoteVal = String(jacnt?.note || "");
        const isTrade = Number(jacnt?.trade ?? 0) === 1;

        const refused = dummy();
        refused.dsign = amntMoney < 0 ? -1 : 1
        refused.dcode = dtype
        refused.darticleId = String(dcm.itemid || "")
        refused.darticlePrec = atclPrecVal
        refused.darticleMask = atclMaskVal
        refused.dacntNo = acntNoVal
        refused.dacntNote = acntNoteVal
        refused.damnt = Math.abs(amntMoney)
        refused.dnote = String(dcm?.dcmnote || "")
        refused.disTrade = isTrade
        refused.dnotetag = " #ПОВЕРНЕННЯ!";
        refused.dscEditable = false
        refused.moneyEq = eqMoney
        refused.moneyDsc = dscMoney
        refused.moneyBns = bnsMoney
        refused.retfor = String(dcm.dcmid || "")
        if (isTrade){
            const qtyVal = Number(jatcl?.qty || 1);
            const priceVal = amntMoney !== 0 ? Math.abs(qtyVal * eqMoney / amntMoney) : 0;
            const priceDsc = eqMoney !== 0 ? Math.abs(dscMoney / eqMoney) : 0;
            const priceBns = eqMoney !== 0 ? Math.abs(bnsMoney / eqMoney) : 0;
            refused.dprice = priceVal
            refused.dpriceDsc = priceDsc
            refused.dpriceBns = priceBns
            refused.dpriceQty = qtyVal
        }

        const idx = 0;
        if (dcm.isTrade || false){
            let jprice = {
                "id": "",
                "item": dcm.itemid,
                "qty": 1,
                "price": Number(dcm.amount || 0) === 0 ? 0.0
                                                      : Math.abs(Number(dcm.eqamount || 0) / Number(dcm.amount || 1)) / mRoot.rate,
                "offer": 0.0,
                "dsc": Number(dcm.eqamount || 0) === 0 ? 0.0
                                                     : Math.abs(Number(dcm.discount || 0) / Number(dcm.eqamount || 1)),
                "bsc": 0.0, // basic price for accounting
            };
            refused.jprice = jprice;
            refused.moneyEq = 0 - Number(dcm?.eqamount || 0);
            refused.moneyDsc = 0 - Number(dcm?.discount || 0);
            refused.moneyBns = 0 - Number(dcm?.bonus || 0);
            refused.clid = String(dcm?.clid || "");
            refused.bns = Math.abs(Number(dcm.eqamount || 0) !== 0 ? dcm.bonus / dcm.eqamount : 0);

        }
        insert(idx, refused);
        setDcmTradeData(idx);
        return true;
    }

    function addMemo(db, dcm) {         // DEPRECATED use addDcm() instead
        console.warn("WW: DEPRECATED ModelBind.qml/addMemo()")
        // console.log(`287#addMemo Дані: ${JSON.stringify(dcm)}`)
        if (!db || !dcm)
            return false;

        const datcl = LibItem.getItemById(db, dcm.crn ?? "");
        const dacnt = LibAcnt.acntbal(db, dcm.cdt);
        const damnt = Number(dcm.amnt || 0);
        const dtag = "";

        if (!isCorrect(datcl, dacnt, dcm.dcm, damnt)) {
            mRoot.lastError = `Непідтримувані параметри документу.\nДані: ${JSON.stringify(dcm)}`;
            return false;
        }

        insert(0, {
            "dsign": damnt < 0 ? -1 : 1,
            "dcode": dcm.dcm,
            "darticle": datcl,
            "dacnt": dacnt,
            "damnt": Math.abs(damnt),
            "dnote": String(dcm.note || "") + dtag,
            "drate": 1,
            "retfor": ""
        });
        // recalculate();
        return true;
    }

    function total() {
        let v_pmnt = 0;
        let v_eq = 0;
        let v_dsc = 0;
        let v_bns = 0;
        for (let r = 0; r < count; ++r) {
            let row = get(r);
            const itemId = String(get(r).darticleId || "");
            if (itemId === "" || itemId === Conf.glDomesticCrn) {
                v_pmnt += Number(row.damnt || 0) * Number(row.dsign || 0);
            }
            v_eq += (row.moneyEq || 0);
            v_dsc += (row.moneyDsc || 0);
            v_bns += (row.moneyBns || 0);
        }

        const res = {
            "pmnt":v_pmnt - (v_eq + v_dsc),
            "eq":v_eq,
            "dsc":v_dsc,
            "bns":v_bns};
        // console.info(`II:#83y ModelBind.qml `, JSON.stringify(res));
        return res;
    }

    function setRate(vv) {
        // console.info("II:#7wy setRate START", vv)
        const newRate = Number(vv || 1);
        if (newRate <= 0) return;
        mRoot.rate = newRate;
        for (let r = 0; r < count; ++r) {
            const dcm = get(r);
            const prevRate = dcm.drate;
            if (dcm.disTrade && newRate !== prevRate ){
                // const prevPrice = dcm.dprice;
                // const newPrice = prevPrice * prevRate / newRate
                // console.info("II:#7wy", newPrice, newRate, prevPrice, prevRate)
                // setProperty(r, 'dprice', newPrice);
                setProperty(r, 'drate', newRate);
                setDcmTradeData(r)
            }
        }
        // for (let q =0; q < count; ++q) console.log(`7hw2#ModelBind ${JSON.stringify(get(q))}`)
    }

    function setBindDsc(vv) {
        // console.log(`yw7#ModelBind setBindDsc STARTED`, vv)
        const val = Number(vv || 0);
        if (val < 0 || val > 1) return; // 0 < vv < 1
        mRoot.crntDsc = val;
        for (let r = 0; r < count; ++r) {
            const dcm = get(r);
            if (dcm.disTrade && dcm.dpriceType !== 'offer' && dcm.dscEditable){
                setProperty(r, 'dpriceDsc', val);
                setDcmTradeData(r);
            }
        }
        // for (let q =0; q < count; ++q) console.log(`s5t3#ModelBind ${JSON.stringify(get(q))}`)
    }

    function setBindBns(vv) {
        // console.log(`yw2#ModelBind setBindBns STARTED`, vv)
        const val = Number(vv || 0);
        if (val < 0 || val > 1) return; // 0 < vv < 1
        mRoot.crntBns = val;
        for (let r =0; r < count; ++r) {
            const dcm = get(r);
            if (dcm.disTrade && dcm.dpriceType !== 'offer' && dcm.dscEditable){
                setProperty(r, 'dpriceBns', val);
                setDcmTradeData(r);
            }
        }
        // for (let r =0; r < count; ++r) console.log(`s5t3#ModelBind ${JSON.stringify(get(r))}`)
    }

    function setDcmTradeData(idx) {
        if (idx < 0 || idx >= count) return;
/*        const l_effPrice = (idx) => {
            const dcm = get(idx);
            const offer = (dcm.jprice?.offer || 0) / (dcm.jprice?.qty || 1)
            const price = (dcm.jprice?.price || 0) / (dcm.jprice?.qty || 1)
            // console.log(`hs7#ModelBind idx=${idx} offer=${offer} price=${price}`)
            return (offer || price || dcm.jprice?.bsc || 0) * (mRoot.rate || 1);
        }; */

        const l_isArticle = (idx) => {  // not for currencies
            if (idx < 0 || idx >= count) return false;
    // console.warn("ModelBind#8su UNBLOCK !!!")
    //         return true;
            return ((get(idx).darticleMask || 0) === 4);
        };

        const dcm = get(idx);
        // const isTrade = (dcm.disTrade || ) === 1;

        if ((dcm.disTrade || false) && ((dcm.retfor || "") === "")){
            const sign = dcm.dsign || 0;
            const amnt = dcm.damnt || 0;
            const dscVal = dcm.dpriceDsc || 0;
            const bnsVal = dcm.dpriceBns || 0;
            const effPrice = dcm.dprice * dcm.drate / dcm.dpriceQty;
            setProperty(idx, 'err', "");
            // const effectivePrice = (dcm.dprice || 0) * (mRoot.rate || 1);
            // const eq = Math.round(100 * (sign * amnt * l_effPrice(idx))) / 100;
            const eq = Math.round(100 * (sign * amnt * effPrice)) / 100;
            // console.log(`3he7#ModelBind idx=${idx} eq=${eq} pr=${l_effPrice(idx)}`)
            setProperty(idx, 'moneyEq', eq);
            if (eq === 0) setProperty(idx, 'err', "Missing document price");
            if (l_isArticle(idx) && !dcm.priceType !== 'offer'){
                setProperty(idx, 'moneyDsc', Math.round(100 * (-1 * eq * dscVal)) / 100);
                setProperty(idx, 'moneyBns', Math.round(100 * (-1 * eq * bnsVal)) / 100);
            }
            // if (recalc) recalculate();
        }
        // console.log(`a93#ModelBind ${JSON.stringify(get(idx))}`)
    }

    function rsltToProfit(db) {
        flush();
        const acntList = LibBal.dbBalance(db, `substr(acntno,1,4)='rslt' AND ABS(beginamnt+turndbt-turncdt) > 0.009`);
        let ok = true;
        const tradeMap = new Map();
        // console.info("II:#e89j bindModel.js/rsltToProfit",JSON.stringify(acntList))

        if (acntList.length === 0) return ok; // probably nothing to do

       const atcl = LibItem.getItemById(db);
       // const cashAcntNo = LibAcnt.DfltAcnt.cashAcntNo(db);
       const profitAcntNo = LibAcnt.DfltAcnt.profitAcntNo(db);
       // const profitAcnt = LibAcnt.acntbal(db, (profitAcntNo || ""));

        for (let acnt of acntList){
       // for (let i =0; ok && i < acntList.length; ++i){
           const acntParts = acnt.acntno.split(/\.|\//);
           const realAtcl = LibItem.getItemById(db, acntParts[2] || "");
          const currentTotal = Number(acnt.total || 0);
          const noteVal = `${(currentTotal < 0 ? "+++" : "---")} rslt ${realAtcl.itemchar}`
            // console.info("II:#23td bindModel.js/rsltToProfit",acnt.acntno,JSON.stringify(acntParts))
          const dcm = {
             atclId: "", // donestic currency
             acntNo: String(acnt.acntno || ""),
             amnt: currentTotal,
             type: "memo",
             note: noteVal,
          }
          ok &= addDcm( db, dcm);

          const tradeAcnt = acntParts[1] || "";
          tradeMap.set(tradeAcnt, (tradeMap.get(tradeAcnt) || 0) + currentTotal);

       }
       const currentPeriod = new Date().toISOString().substring(0, 7); // Формат: YYYY-MM
       for (let k of tradeMap.keys()) {
           const pmnt = 0 - tradeMap.get(k);
          const dcm_total = {
             atclId: "", // donestic currency
             acntNo: String(profitAcntNo || ""),
             amnt: pmnt,
             type: "memo",
             note: `${(pmnt < 0 ? "--- rslt" : "+++ rslt")} ${currentPeriod} ${k}`,
          }
          ok &= addDcm( db, dcm_total);

       }
        // }
        return ok;
    }

    function tradeRevaluation(db) {
        flush();
        let ok = true;
        if (!!LibPrice && typeof LibPrice.dbRefreshTradeRate == "function") {
            ok = LibPrice.dbRefreshTradeRate(db);
        } else {
            mRoot.lastError = "LibPrice.dbRefreshTradeRate's missing"
            return false;
        }

        if (!ok) {
              mRoot.lastError = "SQL Error: refresh trade rates";
           return false;
        }
        const atcl = LibItem.getItemById(db);   // domestic currency
        const source = LibShift.dbRevalList(db) || [];
        const revalSource = source
            .filter(v => v && (v.amnt !== 0 || v.eqamnt !== 0))
            .sort((a,b) => a.tno.localeCompare(b.tno));
        // const revalSet = new Set(
        //     revalSource.map(v => v.tno || "")
        //         .filter(code => code !== "")
        // );
        for (const reval of revalSource){
            const priceVal = Number(reval.bscprice || 0);
            const amntVal = Number(reval.amnt || 0);
            if (!priceVal && !!amntVal) continue;
            const eqVal = Number(reval.eqamnt || 0);
            const profitVal = amntVal * priceVal + eqVal;
            if (Math.abs(100 * profitVal) < 1) continue;
            const acntParts = reval.eno.split(/\.|\//);
            const realAtcl = LibItem.getItemById(db, acntParts[2] || "");
            const noteVal = `${(profitVal < 0 ? "+++" : "---")} reval ${realAtcl.itemchar} ${reval.amnt} * ${reval.bscprice}`;
            const dcm_1 = {
               atclId: atcl.id,
               acntNo: String(reval.eno || ""),
               amnt: profitVal,
               type: "memo",
               note: noteVal,
            }
            const dcm_2 = {
               atclId: atcl.id,
               acntNo: String(reval.rno || ""),
               amnt: 0 - profitVal,
               type: "memo",
               note: noteVal,
            }
            ok &= addDcm(db, dcm_1);
            ok &= addDcm(db, dcm_2);

        }
        return ok;
    }

}

