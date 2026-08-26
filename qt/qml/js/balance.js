.import "v147/sqlBalance.js" as LibBal
.import "v147/sqlItem.js" as LibItem
.import "v147/sqlPrice.js" as LibPrice

const ROW_CACHE = [];
const PROXY_DATA = [];
const SECTION_CACHE = new Map();
const PAGE_CAPACITY = 25;
let SORT_ID = "";

function bindCount(){
    return SECTION_CACHE.size;
}

function sectInfo(sect) {
    return SECTION_CACHE.get(String(sect || ""));
}

// Головна функція калькуляції та завантаження залишків
//
function load(db, model, ui) {
    ROW_CACHE.splice(0, ROW_CACHE.length);
    if (!db) return;
    const balVal = ui?.bal || "300";
    if (balVal.length < 2) return;

    const source = LibBal.balBalance(db, balVal) || [];
    for (let blnc of source){
        const crntItem = LibItem.getItemById(db, blnc.itemid);
        if (crntItem.mask !== 4) continue;
        blnc.item = crntItem ? crntItem : LibItem.dummyItem();
        if (balVal.substring(0,2) !== "30") {
           blnc.total = 0 -  blnc.total;
        }

        // Витягуємо курс обміну з бази
        const pr = LibPrice.sell(db, blnc.itemid) || { "price": 0, "qtty": 1 };
        const denominator = Number(pr.qtty || pr.qty || 1) === 0 ? 1 : Number(pr.qtty || pr.qty );
        const prval = Number(pr.price || 0) / denominator;

        // if (!prval) console.info(`II: balance.js/load prvalerror id=${blnc.itemid} prval=[${prval}] pr=${JSON.stringify(pr)}`)
        blnc.price = prval;

        blnc.eq = prval * Number(blnc.total || 0);

        ROW_CACHE.push(blnc);

    }

    // sortData();
    filterData(model, ui);
}

// ui: order? flt? setPages()
function setSortId(model, ui){
    const sortVal = (ui?.order || "").trim().toLowerCase();
    // console.info(`II: balance.js/setSortId order=${sortVal}`)
    if (sortVal === SORT_ID) return;
    SORT_ID = sortVal;
    filterData(model, ui);
}

function sortData(){
    // for (let r = 0; r < ROW_CACHE.length; ++ r){
    //     const bindVal = ((SORT_ID || "id") === "id") ? String(ROW_CACHE[r].balname || "") : String(ROW_CACHE[r].item.pathname || "");
    //     ROW_CACHE[r].bind = bindVal;

    // }

    if (SORT_ID === "name") {
        PROXY_DATA.sort((a, b) => {
            const pathComp = String(ROW_CACHE[a].item?.pathname || "").localeCompare(String(ROW_CACHE[b].item?.pathname || ""));
            if (pathComp !== 0) return pathComp;
            return String(ROW_CACHE[a].item?.itemchar || "").localeCompare(String(ROW_CACHE[b].item?.itemchar || ""));
        });
    } else if (SORT_ID === "cost") {
        PROXY_DATA.sort((a, b) => {
            const pathComp = String(ROW_CACHE[a].item?.pathname || "").localeCompare(String(ROW_CACHE[b].item?.pathname || ""));
            if (pathComp !== 0) return pathComp;
            return ROW_CACHE[b].eq - ROW_CACHE[a].eq; // Швидке математичне сортування чисел
        });
    } else if (SORT_ID === "datein") {
        PROXY_DATA.sort((a, b) => {
            const pathComp = String(ROW_CACHE[a].item?.pathname || "").localeCompare(String(ROW_CACHE[b].item?.pathname || ""));
            if (pathComp !== 0) return pathComp;
            if (ROW_CACHE[a].intm === ROW_CACHE[b].intm) return 0;
            return (ROW_CACHE[a].intm < ROW_CACHE[b].intm) ? 1 : -1;
        });
    } else if (SORT_ID === "dateout") {
        PROXY_DATA.sort((a, b) => {
            const pathComp = String(ROW_CACHE[a].item?.pathname || "").localeCompare(String(ROW_CACHE[b].item?.pathname || ""));
            if (pathComp !== 0) return pathComp;
            if (ROW_CACHE[a].outm === ROW_CACHE[b].outm) return 0;
            return (ROW_CACHE[a].outm < ROW_CACHE[b].outm) ? 1 : -1;
        });
    } else PROXY_DATA.sort((a, b) => Number(ROW_CACHE[a].item?.id || 0) - Number(ROW_CACHE[b].item?.id || 0));
}

// Безпечна валідація фільтра (Захищена від null значень у SQLite базі)
function isAllowed(row, flt) {
    if (!row) return false;
    if (!flt || flt === "") return true;
    const item = row.item;
    const filterLower = flt.toLowerCase();

    const scancodeStr = String(item.scancode || "").toLowerCase();
    const charStr = String(item.itemchar || "").toLowerCase();
    const nameStr = String(item.itemname || "").toLowerCase();
    const noteStr = String(item.itemnote || "").toLowerCase();

    return (item.id === flt
            || scancodeStr.includes(filterLower)
            || charStr.includes(filterLower)
            || nameStr.includes(filterLower)
            || noteStr.includes(filterLower));
}

// ui: filter? setPages?
function filterData(model, ui){
    // console.info(`II: balance.js/filterData filter=${ui.filter}`)
    PROXY_DATA.splice(0, PROXY_DATA.length);
    SECTION_CACHE.clear();
    const fltVal = (ui?.filter || "").trim().toLowerCase();
    for (let i = 0; i < ROW_CACHE.length; ++ i){
        const bindVal = ((SORT_ID || "id") === "id") ? String(ROW_CACHE[i].balname || "") : String(ROW_CACHE[i].item.pathname || "");
        ROW_CACHE[i].bind = bindVal;

    }

    // let rows = 0;
    for ( let r =0; r < ROW_CACHE.length; ++r){
        if (fltVal === undefined || fltVal === "" || isAllowed(ROW_CACHE[r], fltVal) ){
            const bindVal = ROW_CACHE[r].bind;
            if (SECTION_CACHE.has(bindVal)){
                const sectInfo = SECTION_CACHE.get(bindVal);
                // console.info(`II: BEFORE balance.js/filterData ${JSON.stringify(sectInfo)} +=${ROW_CACHE[r].eq}`)
                sectInfo.totaleq = sectInfo.totaleq + ROW_CACHE[r].eq;
                // console.info(`II: AFTER balance.js/filterData ${JSON.stringify(sectInfo)}`)
                SECTION_CACHE.set(bindVal, sectInfo)
            } else SECTION_CACHE.set(bindVal, {"name": bindVal.includes("/") ? bindVal.substring(bindVal.lastIndexOf("/") + 1) : bindVal, "totaleq": ROW_CACHE[r].eq});
            PROXY_DATA.push(r);
        }
    }
    sortData();
    const p = !!PAGE_CAPACITY ? Math.ceil(PROXY_DATA.length / PAGE_CAPACITY) : 1;
    // console.info(`II: balance.js/filterData p=${p}`)
    // console.info(`II: balance.js/filterData ${JSON.stringify([...SECTION_CACHE.entries()])}`)
    ui?.setPages?.(p);
    populate(model)
}

function populate(model, page =1){
    // console.info(`II: balance.js/populate page=${page}`)
    model.clear();

    const pageNum = Number(page);
    const startIndex = (pageNum < 2) ? 0 : (pageNum - 1) * PAGE_CAPACITY;
    let endIndex = pageNum * PAGE_CAPACITY;

    for (let offset = startIndex; offset < PROXY_DATA.length && offset < endIndex; ++offset) {
        model.append(ROW_CACHE[PROXY_DATA[offset]]);
    }
}
