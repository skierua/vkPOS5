// ModelBind.qml (Частина 1: Оптимізований фінансовий процесор транзакцій)
import QtQuick

import "js/v147/config.js" as Conf
import "js/v147/sqlItem.js" as LibItem
import "js/v147/sqlAcnt.js" as LibAcnt

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
        crntDsc = 0;
        crntBns = 0;
        rate = 1;
        lastError = "";

        // bindCdt = "";
        // note = "";

        // recalculate();
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


    // DEPRECATED
    function resolveCode(atcl, acnt, amnt) {
        console.warn("ModelBind/resolveCode DEPRECATED !!!"); return false;


        if (!acnt || !atcl)
            return "";
        let res = "";
        // dbg(`acnt: ${JSON.stringify(acnt)}`, "415")
        // dbg(`mRoot.code=${mRoot.code} maskNum=${Number(atcl.mask || 0)} trade=${String(acnt.trade)} res=${res} `, "resolveCode")
        if (String(acnt.trade) === "0") {
            res = (amnt < 0 ? "pay:out" : "pay:in");
        } else if (String(acnt.trade) === "1") {
            let maskNum = Number(atcl.mask || 0);

            if (mRoot.dtype === "check") {
                if (maskNum === 4) res = "trade:sell";
                else if (maskNum === 2) {
                    res = (amnt >= 0) ? "trade:buy" : "trade:sell";
                }
            } else if (mRoot.dtype === "facture") {
                res = "trade:buy";
            } else if (mRoot.dtype === "folder") {
                res = "trade:inner";
                // if (maskNum === 4) res = "trade:inner";
            } else if (mRoot.dtype === "taxcheck") {
                if (maskNum === 4)
                    res = "trade:sell";
            }
        }
        // dbg(`mRoot.dtype=${mRoot.dtype} maskNum=${Number(atcl.mask || 0)} res=${res} `, "resolveCode")
        return res;
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
        for (let r = 0; ok && r < count; ++r) {
            let row = get(r);
            // console.log(`ModelBind#s729 ${JSON.stringify(row)}`)
            // console.log(`ModelBind#s729 1=[${!!(row.dcode || "")}] 2=[${Number(row.amnt || 0) !== 0}]`)
            let precision = Number(row.darticle?.prec || 2);

            ok &= (!!(row.dcode || "") && (Number(row.damnt || 0) !== 0));
            if (Number(row.dacnt?.trade || 0) !== 0) {
                ok &= Number(row.moneyEq || 0) !== 0
            }

            // if ((row.dacnt?.trade || 0) !== 0) {
            //     ok &= (row.moneyEq !== 0)
            // }
            errstr += (row.err || "");
            dcmList.push({
                "dcm": row.dcode,
                "dbt": targetAcntNo,
                "cdt": row.dacnt?.acntno || "",
                "crn": row.darticle?.id || "",
                "amnt": (row.dsign * Number(row.damnt || 0)).toFixed(precision),
                "eq": (row.moneyEq || 0).toFixed(2),
                "dsc": (row.moneyDsc || 0).toFixed(2),
                "bns": (row.moneyBns || 0).toFixed(2),
                "note": row.dnote || "",
                "retfor": row.retfor || ""
            });
        }

        if ( ok ) return dcmList;
        mRoot.lastError = "Serialization error";
        return null;
    }

    // ДОДАВАННЯ ОДНОГО ДОКУМЕНТА (ПРОВОДКИ) В ЧЕК
    function addDcm(atcl, acnt, type, amnt, price, note) {
        // console.log(`II: ModelBind/addDcm#82js
        //             atcl=${JSON.stringify(atcl)}
        //             acntno=${JSON.stringify(acnt)}
        //             // amnt=${amnt}
        //             // type=${type}
        //             // price=${JSON.stringify(price)}
        //             `)
        if (!atcl || !acnt || !type) {
            mRoot.lastError = "Document parameter missing";
            return false;
        }

        let atclMask = Number(atcl?.mask || 0);
        let acntMask = Number(acnt?.mask || 0);

        if ((atclMask & acntMask) === 0){
            mRoot.lastError = "Не сумісний артикул та рахунок документу";
            return false;
        }

        const isTrade = Number(acnt?.trade ?? 0) === 1;
        // const dtag = (price?.offer) ? "#АКЦІЯ!" : (price?.dsc ? "#ЗНИЖКА!" : "")
        // const dnote = `${String(atcl.itemchar || "")}${Number(acnt.trade || 0) !== 0
        //             ? "" : ` [${acnt.clname || ""}/${acnt.note || ""}]`} ${dtag}`;
        const idx = 0;
        let dcm = {
            "dsign": Number(amnt || 0) < 0 ? -1 : 1,
            "dcode": type,
            "darticle": atcl,
            "dacnt": acnt,
            "damnt": Math.abs(Number(amnt || 0)),
            "dnote": note,
            "retfor": ""
        };
        if (isTrade){
            if (!price) {
                mRoot.lastError = "Document rate's missing";
                return false;
            }
            dcm.jprice = price;
        }

        insert(idx, dcm);
        setDcmTradeData(idx);
        // for (let r =0; r < count; ++r) console.log(`II: ModelBind#i920 ${JSON.stringify(get(r))}`)

        return true;
    }

    function addRefused(dcm, datcl, dacnt) {
        if (!dcm) return false;
        console.log(`ModelBind/addRefused 111`)

        const dtype = String(dcm.dcmtype || "");
        const damnt = 0 - Number(dcm.amount || 0);
        if (!isCorrect(datcl, dacnt, dtype, damnt)) {
            mRoot.lastError = `Непідтримувані параметри документу.\nДані: ${JSON.stringify(dcm)}`;
            return false;
        }
        let refused = {
            "dsign": damnt < 0 ? -1 : 1,
            "dcode": dtype,
            "darticle": datcl,
            "dacnt": dacnt,
            "damnt": Math.abs(damnt),
            "dnote": `${String(dcm?.dcmnote || "")} #ПОВЕРНЕННЯ!`,
            "retfor": String(dcm.dcmid || "")
        };
        const idx = 0;
        if (dcm.isTrade || false){
            let jprice = {
                "id": "",
                "item": dcm.itemid,
                "qty": 1,
                "price": Number(dcm.amount || 0) === 0 ? 0
                                                      : Math.abs(Number(dcm.eqamount || 0) / Number(dcm.amount || 1)) / mRoot.rate,
                "offer": 0.0,
                "dsc": Number(dcm.eqamount || 0) === 0 ? 0
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


    // СТВОРЕННЯ СЛУЖБОВИХ КАСОВИХ МЕМОРАНДУМІВ (MEMO) ДЛЯ ЗАКРИТТЯ ЗМІНИ
    function addMemo(db, dcm) {
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
            const itemId = String(get(r).darticle?.id || "");
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
        return res;
    }
// deprecated
    function isTrade(idx){
        console.warn("ModelBind/isTrade DEPRECATED !!!"); return false;
        if (idx < 0 || idx >= count) return false;
        return ((get(idx).dacnt?.trade || 0) === 1);
    }

    function setRate(vv) {
        const val = Number(vv || 0);
        if (val <= 0) return;
        mRoot.rate = val;
        for (let r = 0; r < count; ++r) {
            setDcmTradeData(r)
        }
        // recalculate();
    }

    function setBindDsc(vv) {
        // console.log(`yw7#ModelBind setBindDsc STARTED`)
        const val = Number(vv || 0);
        if (val < 0 || val > 1) return; // 0 < vv < 1
        mRoot.crntDsc = val;
        for (let i =0; i < count; ++i) setDcmTradeData(i);
        // for (let r =0; r < count; ++r) console.log(`s5t3#ModelBind ${JSON.stringify(get(r))}`)
    }

    function setBindBns(vv) {
        // console.log(`yw7#ModelBind setBindBns STARTED`)
        const val = Number(vv || 0);
        if (val < 0 || val > 1) return; // 0 < vv < 1
        mRoot.crntBns = val;
        console.log(`ow8#ModelBind crntBns=${mRoot.crntBns}`)
        for (let i =0; i < count; ++i) setDcmTradeData(i);
        // for (let r =0; r < count; ++r) console.log(`s5t3#ModelBind ${JSON.stringify(get(r))}`)
    }

    function setDcmTradeData(idx) {
        if (idx < 0 || idx >= count) return;
        const l_effPrice = (idx) => {
            const dcm = get(idx);
            const offer = (dcm.jprice?.offer || 0) / (dcm.jprice?.qty || 1)
            const price = (dcm.jprice?.price || 0) / (dcm.jprice?.qty || 1)
            // console.log(`hs7#ModelBind idx=${idx} offer=${offer} price=${price}`)
            return (offer || price || dcm.jprice?.bsc || 0) * (mRoot.rate || 1);
        };

        const l_isArticle = (idx) => {  // not for currencies
            if (idx < 0 || idx >= count) return false;
    // console.warn("ModelBind#8su UNBLOCK !!!")
    //         return true;
            return ((get(idx).darticle.mask || 0) === 4);
        };

        const dcm = get(idx);
        const isTrade = (dcm.dacnt?.trade || 0) === 1;

        if (isTrade && ((dcm.retfor || "") === "")){
            const sign = dcm.dsign || 0;
            const amnt = dcm.damnt || 0;
            const dscVal = dcm.jprice?.dsc || mRoot.crntDsc || 0;
            const bnsVal = dcm?.bns || mRoot.crntBns || 0;
            setProperty(idx, 'err', "");
            // const effectivePrice = (dcm.dprice || 0) * (mRoot.rate || 1);
            const eq = Math.round(100 * (sign * amnt * l_effPrice(idx))) / 100;
            // console.log(`3he7#ModelBind idx=${idx} eq=${eq} pr=${l_effPrice(idx)}`)
            setProperty(idx, 'moneyEq', eq);
            if (eq === 0) setProperty(idx, 'err', "Missing document price");
            if (l_isArticle(idx) && !dcm.jprice?.offer && !dcm.jprice?.dsc){
                setProperty(idx, 'moneyDsc', Math.round(100 * (-1 * eq * dscVal)) / 100);
                setProperty(idx, 'moneyBns', Math.round(100 * (-1 * eq * bnsVal)) / 100);
            }
            // if (recalc) recalculate();
        }
        // console.log(`a93#ModelBind ${JSON.stringify(get(idx))}`)
    }
}

