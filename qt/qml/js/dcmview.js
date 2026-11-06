.import "CashDesk.js" as TAX
.import "common.js" as COMM
.import "v147/sqlAcnt.js" as LibAcnt
.import "v147/sqlBind.js" as LibBind
.import "v147/sqlClient.js" as LibClient
.import "v147/sqlItem.js" as LibItem

const ROW_CACHE = []
const SECTION_CACHE = new Map();
const PROXY_ROW = [];
const PROXY_SECTION = new Set();

const PAGE_CAPACITY = 50;
const PAGER = [];
const CLIENT_CACHE = new Map();
const ACNT_CACHE = new Map();


function bindCount(){
    return SECTION_CACHE.size;
}

function sectInfo(code) {
    return SECTION_CACHE.get(String(code || ""));
}

function load_2(db, model, ui) {
    // ROW_CACHE.splice(0, ROW_CACHE.length);
    ROW_CACHE.length = 0;
    SECTION_CACHE.clear();

    if (!db) return;
    // TEST
    // LibBind.selList(db, {"article": "", "tmFrom": "last3Month"});
    const param = {
        // "article": "840",
        // "account": "3500",
        "tmFrom": ui?.dbFrom ?? "",
    };

    if (!!ui && !!ui.dbFilter){
        if (String(ui.dbFilter.code ?? "") === "acntno") param.acntno = String(ui.dbFilter.val ?? "");
        else if (String(ui.dbFilter.code ?? "") === "article") param.article = String(ui.dbFilter.val ?? "");
        else if (String(ui.dbFilter.code ?? "") === "client") param.client = String(ui.dbFilter.val ?? "");
    };

    const dcmSource = LibBind.selList(db, false, param);
    const bindSource = LibBind.selList(db, true, param);
    // console.log(`II: dcmview.js/load#618 dcmSource: ${JSON.stringify(dcmSource)}`);
    // console.log(`II: dcmview.js/load#618 bindSource: ${JSON.stringify(bindSource)}`);
    for (let v of bindSource) {
        const clid = v.clid || "";
        if (!!clid){
            if (!CLIENT_CACHE.has(String(clid))){
                const client = LibClient.client(db, clid);
                CLIENT_CACHE.set(clid, client);
            }
            // console.info(`II: dcmview,js/load clid=${clid}`)
            v.clname = CLIENT_CACHE.get(String(clid || ""))?.name || clid;
        } else v.clname = "";

        SECTION_CACHE.set(String(v.dcmid), v);
    }
    // const dcmList = dcmSource.sort((a, b) =>
    //      (a.shftid === 0 && b.shftid !== 0) ? -1 :
    //      (a.shftid !== 0 && b.shftid === 0) ? 1 :
    //      ((b.shftid - a.shftid) || (b.pid - a.pid) || (a.dcmid - b.dcmid))
    //  )
    const dcmList = dcmSource.sort((a, b) =>
         ((Number(b.shftid || Number.MAX_SAFE_INTEGER) - Number(a.shftid || Number.MAX_SAFE_INTEGER) )
          || (b.pid - a.pid)
          || (a.dcmid - b.dcmid))
     )
     .map(function(v) {
         const acntno = String(v.acntcdt || "");
         if (!ACNT_CACHE.has(String(acntno))){
             const acnt = LibAcnt.acntbal(db, acntno);
             ACNT_CACHE.set(String(acntno || ""), acnt);
         }
             // Створюємо копію об'єкта v та додаємо jarticle
         const cdtacnt = ACNT_CACHE.get(String(acntno || ""))
         const acntclnt = cdtacnt?.clname || "";
         const acntname = cdtacnt?.note || `[${cdtacnt?.name}]` || "N/A";
         // console.info(`II: dcmview.js/load#9ie ${JSON.stringify(cdtacnt)}`, `${acntclnt}:${acntname}:${v.acntcdt}` )
             return Object.assign({}, v, {
                 jarticle: LibItem.getItemById(db, v.itemid),
                 cdtacntname: `${acntclnt}:${acntname}:${v.acntcdt}`,
                 flt: true
             });
         });
    if (dcmList.length < 60000) ROW_CACHE.push(...dcmList);
    else for (let row of dcmList) { ROW_CACHE.push(row); };

    filterData(model, ui)

}


function isAllowed(row, flt, dcmType) {
    // if (!row) return false;
    if ((!flt || flt === "") && !dcmType) return true;
    const dcm = ROW_CACHE[row];
    const checkFlt = !dcmType ? true
                                : (PROXY_SECTION.has(String(dcm.pid)) || (SECTION_CACHE.get(String(dcm.pid))?.dcmtype || "") === dcmType)

    // console.info("II:#523 dcmview.js ", flt,  dcmType, checkFlt, String(dcm.pid), (SECTION_CACHE.get(String(dcm.pid))?.dcmtype || "---"));
    const filterLower = flt.toLowerCase();
    const noteStr = String(dcm.dcmnote || "").toLowerCase();
    // const subnoteStr = String(dcm.dcmsubnote || "").toLowerCase();
    const acntStr = String(dcm.cdtacntname || "").toLowerCase();
    const atclStr = String(dcm.jarticle?.itemchar || "").toLowerCase();
    const atclFStr = String(dcm.jarticle?.itemname || "").toLowerCase();

    // console.info(`II: dcmview.js/isAllowed`, JSON.stringify(dcm), row, flt)
    return checkFlt && (dcm.itemid === filterLower
            || noteStr.includes(filterLower)
            // || subnoteStr.includes(filterLower)
            || (dcm.jarticle?.scancode || "").includes(filterLower)
            || (dcm.acntcdt || "") === filterLower
            || acntStr.includes(filterLower)
            || atclStr.includes(filterLower)
            || atclFStr.includes(filterLower)
            );
}


function filterData(model, ui){
    // console.info("II: dcmview.js/filterData ", JSON.stringify(ui));
    model.clear();
    // PROXY_ROW.splice(0, PROXY_ROW.length);
    PROXY_ROW.length = 0;
    PROXY_SECTION.clear();
    const dcmType = String(ui?.dcmType || '') ;
    const flt = (ui?.filter || "");
    const isFlt = (!ui.dcmType || !flt);
    if (isFlt){
        for ( let r =0; r < ROW_CACHE.length; ++r){
            // console.info("II: dcmview.js/filterData ", r,  JSON.stringify(ROW_CACHE[r]));
            if (isAllowed(r, flt, dcmType) ){
                PROXY_SECTION.add(ROW_CACHE[r].pid)
                PROXY_ROW.push(r);
            }
        }
    } else {
        for (const k of SECTION_CACHE.keys()) {
            PROXY_SECTION.add(k);
        }
        ROW_CACHE.forEach((v,i) => PROXY_ROW.push(i));
    }

    ui?.setPages?.(Math.ceil(PROXY_ROW.length / PAGE_CAPACITY));
    ui?.setBinds?.(PROXY_SECTION.size);

    // console.info(`II: dcmview.js/filterData PAGER:${JSON.stringify(PAGER)}`);
    // console.info(`II: dcmview.js/filterData pages:${PAGER.length} binds:${fcount}`);

    populate(model)
}

function populate(model, page =1){
    model.clear();
    const ofs = PAGE_CAPACITY * (page-1);
    const lim = ((PAGE_CAPACITY * page) >= PROXY_ROW.length ? PROXY_ROW.length : (PAGE_CAPACITY * page));
    // console.info(`II: dcmview.js/populate page=${page} ofs=${ofs} lim=${lim}`);
    for ( let r = ofs; r < lim; ++r){
        // console.info(`II: dcmview.js/populate flt=[${ROW_CACHE[ofs].flt}]`);
        addNew(model, ROW_CACHE[PROXY_ROW[r]]);
    }
    // console.info(`II: dcmview.js/populate length=${ROW_CACHE.length} count=${model.count}`);
}


function addNew(model, row, idx){
    // console.info(`II: dcmview.js/addNew row=${JSON.stringify(row)} count=${model.count}`);
    if (!model || !row) return;
    const idxVal = (!!idx ? idx : model.count);
    const isTrade = row.eqamount !== 0 || row.dcmtype.startsWith("trade:");
    const noteStr = String(row.dcmnote || "");
    let noteVal = "";
    let subnoteVal = "";
    if (isTrade) {
        const hashIdx = noteStr.indexOf("#");
        if (hashIdx === -1) {
            noteVal = `[${row.itemid || ""}] ${row.jarticle?.itemchar || "???"}`;
        } else {
            noteVal = noteStr.substring(0, hashIdx).trim();
            subnoteVal = noteStr.substring(hashIdx).trim();
        }
    } else noteVal = `[${row.itemid || ""}] ${row.jarticle.itemchar || "???"} ${noteStr}`;
    const dcm = {
        "dcmid": row.dcmid
        , "pid": row.pid
        ,"dcmtype": row.dcmtype || ""
        , "acntdbt": row.acntdbt
        , "acntcdt": row.acntcdt
        , "amount": row.amount
        , "eqamount": row.eqamount
        , "discount": row.discount
        , "bonus": row.bonus
        , "dcmnote": noteVal
        , "dcmsubnote": subnoteVal
        , "itemid": row.itemid
        // , "itemchar": row.jarticle.itemchar
        , "unitprec": row.jarticle.unitprec
        , "isTrade": isTrade
        , "cdtacntname": row.cdtacntname
        , "flt": row.flt
        ,
    };
    if (idxVal === model.count) model.append(dcm)
    else model.insert(idx, dcm);

}


function showFullBind(model, idx){
    if (idx < 0 || idx >= model.count) return null;
    const pid = model.get(idx).pid;
    let modelCounter = idx;
    for( ; modelCounter < model.count && model.get(modelCounter).pid === pid; ++modelCounter){ }
    let bindCounter = 0;
    for( --modelCounter; modelCounter >= 0 && model.get(modelCounter).pid === pid; --modelCounter, ++bindCounter){ }
    // if (get(modelCounter).pid !== pid)
    ++modelCounter;
    // console.log(`ModelDbDcm#wy7 count=${count} modelCounter=${modelCounter} bidCounter=${bindCounter}`)
    model.remove(modelCounter, bindCounter);
    const bind = ROW_CACHE.filter(v => v.pid === pid);
    for (const dcm of bind)
        addNew(model, dcm, modelCounter);
}

function bindForPrint(db, pid){
    if (!db) return null;
    // if (idx < 0 || idx >= model.count) return null;
    // const pid = model.get(idx).pid
    if (Number(pid || -1) <= 0) return null;
    const res = LibBind.dbBind(db, pid)
    // console.info(`II: ModelDbDcms.qml/bindForPrint bind=${JSON.stringify(res)}`)
    return res;
}

function dcmForRefuse(dcm){
    if (!dcm) return null;
    const clidVar = Number(dcm.bonus || 0) === 0 ? "" : (sectInfo(dcm.pid)?.clnt || "");
// console.info(`II:#98d dcmview.js dcm=${JSON.stringify(dcm)}`);
    const res =
        {
         "dcmid": dcm.dcmid
         , "pid": dcm.pid
        ,"dcmtype": dcm.dcmtype || ""
         , "acntdbt": dcm.acntdbt
         , "acntcdt": dcm.acntcdt
         , "amount": dcm.amount
         , "eqamount": dcm.eqamount
         , "discount": dcm.discount
         , "bonus": dcm.bonus
         , "dcmnote": dcm.dcmnote
         , "itemid": dcm.itemid
         , "isTrade": dcm.isTrade
        , "clid": clidVar
         // , "flt": row.flt
        };
    return res;
}

function handleSelect(db, popup) {
    const res = []
    res.push({
            "id": "",
            "name": "Всі документи",
            "fullname": "Вибрати всі документи за період",
            "code": "default",
            "sect": ""
              })
    const domestic = LibItem.getItemById(db);
    res.push({
                "id": domestic.id,
                "name": domestic.itemchar,
                "fullname": domestic.itemname,
                "code": "currency",
                "sect": qsTr("НАЦ.ВАЛЮТА")
             })

    const crnsource = LibItem.dbItems(db, `itemmask & 2`)
    // console.info(`II: dcmview.js#47 crnsource=${JSON.stringify(crnsource)}`)
    const crnlist = crnsource
    .filter(v => !!v.itemnote || v.mask === 1)
    .sort((a, b) => Number(a.mask || 0) - Number(b.mask || 0)
          || Number(a.itemnote || 0) - Number(b.itemnote || 0))
    .map(v => {
        return {
           "id": v.id,
           "name": v.itemchar,
           "fullname": v.itemname,
            "code": "article",
           "sect": qsTr("Валюти")
        };
    })
    res.push(...crnlist)

    const clsource = LibClient.dbClient(db, null)
    const clntlist = clsource
    .map(v => {
        return {
            "id": v.id,
            "name": v.name,
            "fullname": `${v.phone} ${v.clnote}`,
            "code": "client",
            "sect": qsTr("Клієнти")
        };
    });

    res.push(...clntlist);

    const atclsource = LibItem.dbItems(db, `itemmask & 4`)
    const atcllist = atclsource
    .sort((a,b) => a.itemchar.localeCompare(b.itemchar) )
    .map(v => {
        return {
           "id": v.id,
           "name": v.itemchar,
           "fullname": v.itemname,
           "scancode": v.scancode,
            "code": "article",
           "sect": qsTr("Товари")
        };
    })
    res.push(...atcllist)

    const cashAcntNo = LibAcnt.DfltAcnt.cashAcntNo(db);
    const acntSource = LibAcnt.acntbalClientList(db)
    const acntLlist = acntSource
    .filter(v => v.acntno !== cashAcntNo
            && v.mask !== 0
            && !String(v.acntno || "").startsWith("rslt")
            && !String(v.acntno || "").startsWith("eqvl"))
    .sort((a,b) => 0 - (Number(a.trade)-Number(b.trade))
          || a.acntno.localeCompare(b.acntno) )
    .map(v => {
        return {
           "id": v.acntno,
           "name": v.note || v.name,
           "fullname": v.name,
           "code" : "acntno",
           "sect": qsTr("Рахунки")
        };
   })
    res.push(...acntLlist)

    popup.jsdata = res
    popup.open()

}

function handleLoadTAXCheckAsync(row) {
    const uuid = sectInfo(String(row?.pid || "")).dcmno
    return new Promise((resolve, reject) => {
        if (!TAX || typeof TAX.getCheckPdf !== "function") {
         return reject("TAX_DISCONNECTED");
        }
        TAX.getCheckPdf(uuid, null, (err, pdfBuffer) => {
            if (err) reject(err);
            else resolve(pdfBuffer);
        });
    });
}

function handleFiscalizateAsync(db, row) {
    // console.log("II:#98e dcmview.js ", JSON.stringify(row))
    const bid = String(row?.pid || "")
    return new Promise((resolve, reject) => {
        if (!TAX || typeof TAX.sale !== "function") {
         return reject("TAX_DISCONNECTED");
        }
        TAX.sale(db, bid, 0, (err, resp) => {
            if (err) reject(err);
            else {
                 const updateData = {
                     "dcmnote": JSON.stringify(resp)
                 };
                 resolve(resp);
                 const parsed = COMM.parse(resp);
                 const taxNo = String(parsed?.uuid || "");
                 if (!!taxNo) updateData.dcmno = taxNo;
                  // console.info(`II: bind.js#4r21 updateData=${JSON.stringify(updateData)}\ntaxNo=${taxNo}`)
                 const uOk = LibBind.updDocum(db, bid, updateData);
                 if (!uOk) reject("DB_ERROR");
              }
        });
    });
}
