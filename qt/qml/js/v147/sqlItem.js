// sqlItem.js
.pragma library

// Код національної валюти за замовчуванням (Гривня)
const DomesticCurrencyCode = "980";

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

function findFolder(id) {
    return folderPathCache.findIndex((v) => v.id === id);
}

function findItem(id) {
    return itemCache.findIndex((v) => v.id === id);
}

// ✅ ОПТИМІЗАЦІЯ $O(N)$: Швидка побудова кешу папок через хеш-мапу без вкладених циклів findIndex
function fillFolderCache(db) {
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

        let depthLimit = 0; // ✅ ЗАХИСТ ВІД ВІЧНОГО ЦИКЛУ ТА КРАШУ ПАМ'ЯТІ

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
}

// Завантаження картки валюти в оперативну пам'ять
function pushItemToCache(db, id) {
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
}
// OLD version struct
// const vsql = "select item.pkey as id, itemchar as name, coalesce(itemname, itemnote,'') as fullname, coalesce(itemnote,'') as note, itemmask as mask, coalesce(qty,1) as qty, coalesce(scancode,'') as scan, uktzed, taxchar, taxprc, "
// +" coalesce(defunit,'') as unitid ,coalesce(unitprec,2) as prec, coalesce(unitchar,'') as unitchar, coalesce(unitname,'') as unitname, coalesce(code,'') as unitcode, "
// +" coalesce(term,0) as term from item left join itemunit on(defunit=itemunit.pkey) left join articlepriceqty on (item.pkey=articlepriceqty.pkey) left join warranty on (item.pkey=article) ";
/*let ret = {"id":"",
    "name":"",
    "fullname":"",
    "mask":"",
    "qty":"1",
    "scan":"",
    "uktzed":"",
    "taxchar":"",
    "taxprc":"",
    "unitid":"",
    "prec":"0",
    "unitchar":"",
    "unitname":"",
    "unitcode":"",
    "term":""
}; */

// ГОЛОВНИЙ ОПТИМІЗОВАНИЙ МЕТОД: Отримання картки валюти з пам'яті (або з бази, якщо перший запит)
function getItemById(db, id = "") {
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
}

// Низькорівневий вибір характеристик з таблиці номенклатури
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
    // ✅ ОПТИМІЗАЦІЯ QT6: Пряме завантаження масиву QVariantList без JSON.parse
    return db.dbSelectRowsJSON(vsql, filter) || [];
}
