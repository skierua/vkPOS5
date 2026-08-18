.import "v147/sqlAcnt.js" as LibAcnt
.import "v147/sqlBind.js" as LibBind
.import "v147/sqlItem.js" as LibItem

const ROW_CACHE = []
const SECTION_CACHE = new Map();
const PAGE_CAPACITY = 25;
const PAGER = [];

function bindCount(){
    return SECTION_CACHE.size;
}

function sectInfo(sect) {
    return SECTION_CACHE.get(String(sect || ""));
}

function load(db, model, condition = "", ui) {
    ROW_CACHE.splice(0, ROW_CACHE.length);
    SECTION_CACHE.clear();

    if (!db) return;
    // if (!ui || !ui.acnt) return false;
    const source1 = LibBind.dbDocum(db, condition, false);
    const source2 = LibBind.dbDocum(db, condition, true);
    const joinSource = source1.concat(source2);
    // console.log(`II: dcmview.js source: ${JSON.stringify(joinSource)}`);
    const bindList = joinSource.filter(v => v.pid === "");
    for (let v of bindList) SECTION_CACHE.set(String(v.dcmid), v);

    const dcmList = joinSource
    .filter(v => v.pid !== "")
    .sort((a, b) =>
        (a.shftid === 0 && b.shftid !== 0) ? -1 :
        (a.shftid !== 0 && b.shftid === 0) ? 1 :
        ((b.shftid - a.shftid) || (b.pid - a.pid) || (a.dcmid - b.dcmid))
    )
    .map(function(v) {
            // Створюємо копію об'єкта v та додаємо jarticle
            return Object.assign({}, v, {
                jarticle: LibItem.getItemById(db, v.itemid),
                flt: true
            });
        });
    ROW_CACHE.push(...dcmList);

    filterData(model, ui)
}

function isAllowed(row, flt) {
    if (!row) return false;
    if (!flt || flt === "") return true;

    const dcm = ROW_CACHE[row];
    const filterLower = flt.toLowerCase();
    const noteStr = String(dcm.dcmnote || "").toLowerCase();
    const atclStr = String(dcm.jarticle?.itemchar || "").toLowerCase();
    const atclFStr = String(dcm.jarticle?.itemname || "").toLowerCase();

    return (dcm.dcmid === flt
            || noteStr.includes(filterLower)
            || (dcm.jarticle?.scancode || "").includes(filterLower)
            || (dcm.acntcdt || "") === filterLower
            || atclStr.includes(filterLower)
            || atclFStr.includes(filterLower)
            );
}


function filterData(model, ui){
    let tmpa = []
    const flt = ui?.filter || "";
    PAGER.splice(0, PAGER.length);
    let count =0, fcount =0
    let pid = 0, fpid = 0
    for ( let r =0; r < ROW_CACHE.length; ++r){
        if (flt === undefined || flt === "" || isAllowed(r, flt) ){
            if (fpid !== ROW_CACHE[r].pid) {
                fpid = ROW_CACHE[r].pid
                if (fcount % PAGE_CAPACITY === 0 ) PAGER.push(r);
                ++fcount
            }
            ROW_CACHE[r].flt = true;
        } else  { ROW_CACHE[r].flt = false; }
    }
    // const str =` з ${PAGER.length} (${fcount} позицій)`
    // ui.setFooter(str);
    ui?.setPages?.(PAGER.length);
    ui?.setBinds?.(fcount);

    // console.info(`II: dcmview.js/filterData PAGER:${JSON.stringify(PAGER)}`);
    // console.info(`II: dcmview.js/filterData pages:${PAGER.length} binds:${fcount}`);

    populate(model)
}

function populate(model, page =1){
    model.clear();

    let pid = ""
    let ofs = PAGER[page-1]
    let lim = (page >= PAGER.length ? ROW_CACHE.length : PAGER[page])
    // console.info(`II: dcmview.js/populate page=${page} ofs=${ofs} lim=${lim}`);
    for (; ofs < lim; ++ofs){
        // console.info(`II: dcmview.js/populate flt=[${ROW_CACHE[ofs].flt}]`);

        if (!ROW_CACHE[ofs].flt) continue;
        addNew(model, ROW_CACHE[ofs]);
    }
    // console.info(`II: dcmview.js/populate length=${ROW_CACHE.length} count=${model.count}`);
}


function addNew(model, row, idx){
    // console.info(`II: dcmview.js/addNew row=${JSON.stringify(row)} count=${model.count}`);
    if (!model || !row) return;
    const idxVal = (!!idx ? idx : model.count);
    const isTrade = row.eqamount !== 0 || row.dcmtype.startsWith("trade:");
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
        , "dcmnote": row.dcmnote
        , "itemid": row.itemid
        , "itemchar": row.jarticle.itemchar
        , "unitprec": row.jarticle.unitprec
        , "isTrade": isTrade
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
            "code": "currency",
           "sect": qsTr("Валюти")
        };
    })
    res.push(...crnlist)

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

