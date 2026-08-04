.import "v147/config.js" as Conf
.import "v147/sqlAcnt.js" as LibAcnt
.import "v147/sqlClient.js" as LibClient
.import "v147/sqlItem.js" as LibItem

const ROW_CACHE = []
const SECTION_CACHE = new Map();

function sectInfo(sect) {
    return SECTION_CACHE.get(String(sect || ""));
}

function load(db, model, balList, mask =0, reverse =false) {
    if (!balList || balList.length < 1) return;
    ROW_CACHE.splice(0, ROW_CACHE.length);
    SECTION_CACHE.clear();
    const condition = Number(mask < 4) ? `(item IS NULL OR length(item) < 4)` : ""
    for (let bal of balList){
        const source = LibAcnt.balBalance2(db, bal, condition) || [];
        // console.log(`ModelDrawer/load source=${JSON.stringify(source)}`)
        if (!source || source.length < 1) continue;
        for (let acnt of source){
            const code = acnt?.note || acnt?.balname || "";
            if (!SECTION_CACHE.has(code)) SECTION_CACHE.set(code, {"name": code});
            const item = LibItem.getItemById(db, acnt.itemid);
            // console.log(`ModelDrawer/load item=${JSON.stringify(item)}`)
            if (!(mask & (item?.mask || 0))) continue;
            const client = LibClient.client(db, acnt.clid);
            const total = reverse ? 0 - Number(acnt?.total || 0.0) : Number(acnt?.total || 0.0);
            const income = reverse ? 0 - Number(acnt?.income || 0.0) : Number(acnt?.income || 0.0);
            const outcome = reverse ? 0 - Number(acnt?.outcome || 0.0) : Number(acnt?.outcome || 0.0);
            const clnt = !!(acnt?.clid || "")? `${client?.name}[${acnt.clid}]` : "";
            const nameVal = (item?.itemchar || "???")
                        + ((bal.startsWith(String(Conf.glDepoPrefix || "")) || bal.startsWith(String(Conf.glInitPrefix || ""))) ? ` ${(acnt?.note || "")}` : "")
                        + (!!(acnt?.clid || "")? `${client?.name}[${acnt.clid}]` : "");
            const rowData = {
                "bind": code,
                "name": nameVal,
                "subname":`[${acnt?.acntno || ""}][${ item?.id || ""}] ${ item?.itemname || ""}`,
                "total": total,
                "income": income,
                "outcome": outcome,
                "key": item?.id || "",
                "prec": item?.unitprec ?? 2,
                "scan": item?.scancode || "",
                "totaleq": 0,
                "clid": acnt?.clid || "",
                "clchar": client?.name || "",
                "acntno": acnt?.acntno || "",
                "mask": item?.mask || 0,
                "so": item?.itemnote || "",
            };
            ROW_CACHE.push(rowData);
            // console.log(`ModelDrawer/load source=${JSON.stringify(rowData)}`)
        }
    }
    // console.log(`drawer.js/load ROW_CACHE=${JSON.stringify(ROW_CACHE)}`)
    sortData();
    filterData(model)
}


function loadProfit(db, model, balList) {
    const mask = 3;
    const reverse = true;
    ROW_CACHE.splice(0, ROW_CACHE.length);
    SECTION_CACHE.clear();
    const bal = `${Conf.TRADE_RESULT_PREFIX}.`;
    const source = LibAcnt.balBalance2(db, bal) || [];
    // console.info(`II: drawer.js/loadProfit ${JSON.stringify(source)}`);
    // const acntMap = new Map();
    for (let acnt of source){
        const [prefix, code, suffix] = acnt.acntno.split(/\.|\//);
        if (SECTION_CACHE.has(code)) {
            const mapAcnt = SECTION_CACHE.get(code);
            mapAcnt.total -= Number(acnt.total || 0);
            SECTION_CACHE.set(code, mapAcnt);
        } else SECTION_CACHE.set(code, {"name":acnt?.note || acnt?.balname || "", "total": 0 - Number(acnt.total || 0)});

        const item = LibItem.getItemById(db, (suffix || ""));
        const total = (reverse ? -1 : 1) * Number(acnt?.total || 0.0);
        const income = (reverse ? -1 : 1) * Number(acnt?.income || 0.0);
        const outcome = (reverse ? -1 : 1) * Number(acnt?.outcome || 0.0);

        const rowData = {
            "bind": code || "",
            "name": item?.itemchar || "",
            "subname":`[${ item?.id || ""}] ${ item?.itemname || ""}`,
            "total": total,
            "income": income,
            "outcome": outcome,
            "key": item?.id || "",
            "prec": item?.unitprec ?? 2,
            "scan": item?.scancode || "",
            "totaleq": 0,
            "clid": "",
            "clchar": "",
            "acntno": acnt?.acntno || "",
            "mask": item?.mask || 0,
            "so": item?.itemnote || "",
        };
        ROW_CACHE.push(rowData);
    }
// console.info(`II: drawer.js/loadProfit ${JSON.stringify([...SECTION_CACHE.entries()])}`)
    sortData();
    filterData(model)
    return;
}

function sortData(){
    ROW_CACHE.sort((a,b) => {
                 const compBind = (a.bind || "").localeCompare(b.bind || "");
                 if (compBind !== 0) return compBind;

                 const maskA = Number(a.mask);
                 const maskB = Number(b.mask);
                 if (!isNaN(maskA) && !isNaN(maskB) && maskA !== maskB) {
                     return maskA - maskB;
                 }

                 const numA = Number(a.so);
                 const numB = Number(b.so);
                 if (!isNaN(numA) && !isNaN(numB) && numA !== numB) {
                     return numA - numB;
                 }
                 const compSo = (a.so || "").localeCompare(b.so || "");
                 if (compSo !== 0) return compSo;

                 return (a.acntno || "").localeCompare(b.acntno || "");
             })
}

function isAllowed(row, flt) {
    if (!row) return false;
    if (!flt || flt === "") return true;

    const filterLower = flt.trim().toLowerCase();
    const scancodeStr = String(row.scan || "").toLowerCase();
    const charStr = String(row.name || "").toLowerCase();
    const nameStr = String(row.subname || "").toLowerCase();
    const clStr = String(row.clchar || "").toLowerCase();

    // console.log(`ModelDrawer/isAllowed flt=${filterLower} name=${charStr}`)
    return (row.acntno === flt
            || row.clid === flt
            || scancodeStr.includes(filterLower)
            || charStr.includes(filterLower)
            || nameStr.includes(filterLower)
            || clStr.includes(filterLower));
}


function filterData(model, flt =""){

    for ( let r =0; r < ROW_CACHE.length; ++r){
        if (flt === undefined || flt === "" || isAllowed(ROW_CACHE[r], flt) ){
            ROW_CACHE[r].flt = true;
        } else  { ROW_CACHE[r].flt = false; }
    }

    populate(model)
}

function populate(model){
    model.clear();

    for (let ofs = 0; ofs < ROW_CACHE.length; ++ofs) {
        if (!ROW_CACHE[ofs].flt) continue;
        model.append(ROW_CACHE[ofs]);
    }
}


