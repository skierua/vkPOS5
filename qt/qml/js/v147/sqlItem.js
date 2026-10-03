// sqlItem.js
.pragma library

// Код національної валюти за замовчуванням (Гривня)
const DomesticCurrencyCode = "980";

const SQL_STMT = `
SELECT item.pkey AS id,
    coalesce(item.parentid, '') AS pid,
    scancode,
    itemchar,
    itemname,
    itemnote,
    itemmask AS mask,
    uktzed,
    taxchar,
    taxprc,
    coalesce(defunit, '') AS unitid,
    unitchar,
    coalesce(unitprec, 2) AS unitprec,
    coalesce(unitname, '') AS unitname,
    coalesce(code, '') AS unitcode,
    coalesce(qty,1) AS qty
FROM item
    LEFT JOIN itemunit ON (defunit = itemunit.pkey)
    LEFT JOIN articlepriceqty using(pkey)
`;
const FOLDERS = new Map();
const ARTICLES = new Map(); // for currencies only

// Локальний кеш в пам'яті (RAM Caching)
let folderPathCache = [];
let itemCache = [];

function dummyFolder() {
    return { "id": "", "pid": "", "pathid": "", "name": "", "pathname": "" };
}

function dummyItem() {
    return {
        "id": "", "pid": "", "pathid": "", "pathname": "", "scancode": "",
        "itemchar": "", "itemname": "", "itemnote": "", "mask": 0, "uktzed": "",
        "taxchar": "", "taxprc": "", "unitid": "", "unitchar": "",
        "unitprec": 2, "unitname": "", "unitcode": ""
    };
}

function buildWhereClause(conditionsArray) {
    if (!conditionsArray || conditionsArray.length === 0) {
        return "";
    }
    // Склеюємо умови через AND з правильними пробілами
    return "WHERE " + conditionsArray.join(" AND ");
}

function fillFolders(db) {
    FOLDERS.clear();
    const vsql = "SELECT pkey as id, coalesce(parentid, '') pid, itemchar FROM item WHERE folder = 1;";

    // Читаємо нативний масив об'єктів без JSON.parse
    const rows = db.dbSelectRows(vsql, []) || [];
    if (rows.length === 0) return;

    // Створюємо індексну мапу для миттєвого доступу до папок за O(1)
    const folderMap = rows.reduce((map, row) => {
        map[row.id] = row;
        return map;
    }, {});

    // Збираємо повні шляхи для кожної папки
    for (let i = 0; i < rows.length; ++i) {
        const current = rows[i];
        let vpid = current.pid;
        let vpathid = "/";
        let vpathname = "/";

        let depthLimit = 0;

        while (vpid !== "" && depthLimit < 10) {
            const parent = folderMap[vpid];
            if (!parent) break;

            vpathid = "/" + parent.id + vpathid;
            vpathname = "/" + parent.itemchar + vpathname;
            vpid = parent.pid;

            depthLimit++; // Страхує касу від зациклення при пошкодженні зв'язків у SQLite
        }
        FOLDERS.set(current.id,
            {
                "id": current.id,
                "pid": current.pid,
                "pathid": vpathid,
                "name": current.itemchar,
                "pathname": vpathname
            });
    }
}

// ГОЛОВНИЙ ОПТИМІЗОВАНИЙ МЕТОД: Отримання картки валюти з пам'яті (або з бази, якщо перший запит)
// balance.js, bind.js, dcmview.js, drawer.js, shift.js
function getItemById(db, id = "") {
    // console.log(`II: 8623y#sqlItem.js id=${id}`)
    const idT = id.trim();
    const idVal = (idT !== DomesticCurrencyCode) ? idT : "";
    if (ARTICLES.has(idVal)) {
        // console.log("II: 23ej#sqlItem.js from CACHE")
        const mapRes = ARTICLES.get(idVal);
        return mapRes;
    }

    const cond = [];
    const param = [];
    if (idVal !== ""){
        cond.push("item.pkey = ?");
        param.push(idVal);
    } else {
        cond.push("item.itemmask = ?");
        param.push(1);
    }
    const condStr = buildWhereClause(cond);
    const vsql = `${SQL_STMT} ${condStr};`;
    // console.log(`II: 7wy3#sqlItem.js vsql=${vsql}`)

    const dbatcl = db.dbSelectRows(vsql, param);
    // console.log(`II: 7wy3#sqlItem.js dbatcl=${JSON.stringify(dbatcl)}`)
    if (!dbatcl || dbatcl.length === 0) {
        return dummyItem();
    }
    const res = dbatcl[0];
    if (idVal === "") res.id = "";
    res.pathid = "";
    res.pathname = "";

    // Перевіряємо та оновлюємо кеш структур папок, якщо його немає
    if (!FOLDERS.has(res.pid)) fillFolders(db);

    // Наповнюємо валюту текстовими «хлібними крихтами» її розташування
    if (FOLDERS.has(res.pid)) {
        const path = FOLDERS.get(res.pid);
        res.pathid = path.pathid + path.id;
        res.pathname = path.pathname + path.name;
    }

    const mask = Number(res.mask || 0);
    if (mask === 2 || mask === 1) ARTICLES.set(idVal, res);
    return res;
}

// function findFolder(id) {
//     return folderPathCache.findIndex((v) => v.id === id);
// }

// function findItem(id) {
//     return itemCache.findIndex((v) => v.id === id);
// }

/*function fillFolderCache(db) {
    folderPathCache = [];
    if (!db) return false;

    const vsql = "SELECT pkey as id, coalesce(parentid, '') pid, itemchar FROM item WHERE folder = 1 ORDER BY pkey;";

    // Читаємо нативний масив об'єктів без JSON.parse
    const rows = db.dbSelectRowsJSON(vsql) || [];
    if (rows.length === 0) return true;

    // Створюємо індексну мапу для миттєвого доступу до папок за O(1)
    const folderMap = rows.reduce((map, row) => {
        map[row.id] = row;
        return map;
    }, {});

    // Збираємо повні шляхи для кожної папки
    for (let i = 0; i < rows.length; ++i) {
        const current = rows[i];
        let vpid = current.pid;
        let vpathid = "/";
        let vpathname = "/";

        let depthLimit = 0;

        while (vpid !== "" && depthLimit < 10) {
            const parent = folderMap[vpid];
            if (!parent) break;

            vpathid = "/" + parent.id + vpathid;
            vpathname = "/" + parent.itemchar + vpathname;
            vpid = parent.pid;

            depthLimit++; // Страхує касу від зациклення при пошкодженні зв'язків у SQLite
        }

        folderPathCache.push({
            "id": current.id,
            "pid": current.pid,
            "pathid": vpathid,
            "name": current.itemchar,
            "pathname": vpathname
        });
    }

    // Сортуємо кеш папок для стабільного пошуку
    folderPathCache.sort((a, b) => a.id > b.id ? 1 : -1);
    return true;
}*/

// Завантаження картки валюти в оперативну пам'ять
/*function pushItemToCache(db, id) {
    if (!db) return false;

    const flt = (id === "") ? "item.itemmask = 1" : `item.pkey = '${id}'`;

    const dbatcl = dbItems(db, flt);
    if (!dbatcl || dbatcl.length === 0) {
        return false;
    }

    let res = dbatcl[0];
    if (id === "") res.id = "";

    res.pathid = "";
    res.pathname = "";

    // Перевіряємо та оновлюємо кеш структур папок, якщо його немає
    let fidx = findFolder(res.pid);
    if (fidx < 0) {
        fillFolderCache(db);
        fidx = findFolder(res.pid);
    }

    // Наповнюємо валюту текстовими «хлібними крихтами» її розташування
    if (fidx !== -1) {
        res.pathid = folderPathCache[fidx].pathid + folderPathCache[fidx].id;
        res.pathname = folderPathCache[fidx].pathname + folderPathCache[fidx].name;
    }

    itemCache.push(res);
    return true;
}*/

// ГОЛОВНИЙ ОПТИМІЗОВАНИЙ МЕТОД: Отримання картки валюти з пам'яті (або з бази, якщо перший запит)
// balance.js, bind.js, dcmview.js, drawer.js, shift.js
/*function old_getItemById(db, id = "") {
    if (id === DomesticCurrencyCode) id = "";

    let cacheidx = findItem(id);
    if (cacheidx === -1) {
        pushItemToCache(db, id);
        cacheidx = findItem(id);
    }

    if (cacheidx === -1) {
        return dummyItem();
    }

    return itemCache[cacheidx];
}*/

// Низькорівневий вибір характеристик з таблиці номенклатури
// bind.jd, dcmview.js, rate.js
function dbItems(db, condition, filter) {
    if (!db) return [];
    const whereCondition = (condition === "" ? "" : `WHERE folder = 0 AND ${condition}`)

    const vsql = `
        SELECT item.pkey as id,
            coalesce(item.parentid, '') pid,
            scancode, itemchar,
            coalesce(itemname, '') itemname,
            coalesce(itemnote, '') itemnote,
            itemmask mask,
            coalesce(uktzed, '') uktzed,
            coalesce(taxchar, '') taxchar,
            coalesce(taxprc, '') taxprc,
            coalesce(defunit, '') unitid,
            unitchar,
            coalesce(unitprec, 2) unitprec,
            coalesce(unitname, '') unitname,
            coalesce(code, '') unitcode,
            coalesce(qty,1) as qty
        FROM item
            LEFT JOIN itemunit ON (defunit = itemunit.pkey)
            LEFT JOIN articlepriceqty using(pkey)
        ${whereCondition};
    `
// console.log(`sqlItem vsql= ${vsql}`)
    return db.dbSelectRowsJSON(vsql, filter) || [];
}

// rate.js
function itemList(db, mask){
    const maskVal = Number(mask ?? 0);
    const param = [maskVal];
    const vsql = `${SQL_STMT} WHERE (itemmask & ?);`;
    return db.dbSelectRows(vsql, param) || [];
}




