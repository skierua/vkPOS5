.import "v147/sqlItem.js" as LibItem
.import "./dbAsync.js" as LibDb

const FOLDERS = new Map();
const UNITS = new Map();

function preload(db, model){
    FOLDERS.clear();
    UNITS.clear();
    if (!db) return Promise.reject("Missing DB");
    if (!model) return Promise.reject("Missing model");
    return LibDb.selectPromise(db, LibItem.FOLDER_SQL_STMT)
    .then((resp) => {
        let rootPath = "/";
        for (const vv of resp){
          if (!vv.pid && vv.mask === 4){
              rootPath += vv.id;
              break;
          }
        }
        const tmp = new Map();
        for (const v of resp) tmp.set(v.id, {id: v.id, pid:v.pid, name: v.itemchar, mask: v.mask, unitid: v.unitid });
        tmp.forEach((folder, id) => {
              let current = folder;
              let pathIds = [];
              let pathNames = [];

              while (current) {
                  pathIds.unshift(current.id);
                  pathNames.unshift(current.name);
                  current = tmp.get(current.pid);
              }

              folder.pathid = "/" + pathIds.join("/") + "/";
              folder.pathname = pathNames.slice(1).join(" ➔ ");
            folder.deep = pathIds.length -1;
          });
        tmp.forEach((folder, id) =>
                    {if (folder.pathid.startsWith(rootPath)) FOLDERS.set(id, folder)});
        // FOLDERS.forEach((folder, id) => console.info("II:#736 article.js", id, JSON.stringify(folder)));
        refreshFolder(model);
        const vsql = LibItem.UNIT_SQL_STMT;
        return LibDb.selectPromise(db, vsql, [])
    })
    .then((uresp) => {
        for (const u of uresp) UNITS.set(u.id, u);
    })
    .catch(err => {
        throw err;
    });
}

function refreshFolder( model ) {
    if (!model) return;
    model.clear();
    const sorted = Array.from(FOLDERS.values())
        .sort((a,b) => {
                return a.pathname.localeCompare(b.pathname);
            } );
    sorted.forEach((f) => {
        model.append( f );
    });

}

function refreshArticlesList(db, model, crntPid) {
    // console.info("II:#45f article.js/refreshArticlesList START")
    if (!LibItem) return Promise.reject("Missing DB");
    const pid = crntPid || '';
    const vsql = LibItem.SQL_STMT + " WHERE item.parentid = ?  ORDER BY folder DESC, itemname ASC;"
    // const vsql = LibItem.SQL_STMT + " WHERE folder = 0 AND (itemmask & 4) AND item.parentid = ?  ORDER BY itemname ASC;"
    const params = [pid];

    return LibDb.selectPromise(db, vsql, params)
    .then((resp) =>{
        model.clear();
        resp.forEach(v => model.append(v))
    })
    .catch((err) =>{
        console.error("Failed to load articles:", err);
        throw err;
    });
}

function getUnit(id){
    const res = UNITS.get(id);
    if (!!res) return res;
    return {id: '', uchar: '', uprec: 2, uname: '[money]', ucode: ''};
}

function getUnitsList() {
    const list = Array.from(UNITS.values()).sort((a,b) => a.uname.localeCompare(b.uname));
    return list;
}

function getProductPathInfo(pid) {
    let f = FOLDERS.get(String(pid));
    return f || { pathid: "", pathname: "Корінь", name:"", mask: 0 };
}

function insItem(db, itemData){
    if (!db) return Promise.reject("Missing DB");
    let itemId = '';
    // START DB TRANSACTIONS
    if (!db.dbTransaction()) {
        const err = "Не вдалося розпочати транзакцію БД";
        return Promise.reject(err);
    }
    return LibDb.selectPromise(db, LibItem.NEW_ID_SQL_STMT)
    .then((keyData) => {
        if (!keyData.length) throw "Неможливо отримати код артикулу";
        itemId = String(Math.round(keyData[0].pkey));

        const fieldsName = ["pkey", "folder", "itemchar", "itemmask", "parentid", "defunit"];
        const params = [
          itemId,
          String(itemData.folder || "0"),
          String(itemData.itemchar ?? `[${itemId}]`),
          String(itemData.itemmask || 4),
          itemData.parentid === "" ? null : (itemData.parentid ?? null),
          itemData.defunit === "" ? null : (itemData.defunit || null)
        ];
        if (itemData.scancode !== undefined) { fieldsName.push("scancode"); params.push(String(itemData.scancode || "")); }
        if (itemData.itemname !== undefined) { fieldsName.push("itemname"); params.push(String(itemData.itemname || "")); }
        if (itemData.itemnote !== undefined) { fieldsName.push("itemnote"); params.push(String(itemData.itemnote || "")); }
        if (itemData.uktzed !== undefined) { fieldsName.push("uktzed"); params.push(String(itemData.uktzed || "")); }
        if (itemData.taxchar !== undefined) { fieldsName.push("taxchar"); params.push(String(itemData.taxchar || "")); }
        if (itemData.taxprc !== undefined) { fieldsName.push("taxprc"); params.push(String(itemData.taxprc || "")); }

        const placeholders = Array(fieldsName.length).fill("?").join(", ");
        const vsql = `INSERT INTO item ( ${fieldsName.join(", ")} ) VALUES (${placeholders});`;
              // console.info("II:#32r article.js params", JSON.stringify(params));
        return LibDb.insertPromise(db, vsql, params)
    })
    .then((rowid) => {
              // console.info("II:#t45 article.js COMMIT DB TRANSACTIONS");
        db.dbCommit();  // COMMIT DB TRANSACTIONS
        return itemId;
    })
    .catch(err => {
               // console.info("II:#t45 article.js ROLLBACK DB TRANSACTIONS");
        db.dbRollback();  // ROLLBACK DB TRANSACTIONS
        console.error("EE:#53r article.js Failed to add:", err);
        throw err;
    });
}

function updItem(db, itemData){
    if (!db) return Promise.reject("Missing DB");

    const itemId = String(itemData.id || '');
    if (!itemId) return Promise.reject("Missing item ID");

    const updateFields = {
        itemmask: 4,
    }
    if (itemData.scancode !== undefined) updateFields.scancode = String(itemData.scancode || '');
    if (itemData.parentid !== undefined) updateFields.parentid = String(itemData.parentid || '');
    if (itemData.itemchar !== undefined) updateFields.itemchar = String(itemData.itemchar || '');
    if (itemData.itemname !== undefined) updateFields.itemname = String(itemData.itemname || '');
    if (itemData.itemnote !== undefined) updateFields.itemnote = String(itemData.itemnote || '');
    if (itemData.defunit !== undefined) updateFields.defunit = String(itemData.defunit || '');
    if (itemData.uktzed !== undefined) updateFields.uktzed = String(itemData.uktzed || '');
    if (itemData.taxchar !== undefined) updateFields.taxchar = String(itemData.taxchar || '');
    if (itemData.taxprc !== undefined) updateFields.taxprc = String(itemData.taxprc || '');
    const setParts = [];
    const params = { ":condition_id": itemId };

    Object.keys(updateFields).forEach(key => {
        setParts.push(`${key} = :${key}`);
        params[`:${key}`] = updateFields[key];
    });

    const usql = `UPDATE item SET ${setParts.join(", ")} WHERE pkey = :condition_id`;
//     console.info("II:#73y article.js params", usql, JSON.stringify(itemData));
// return Promise.resolve("Missing DB");
    return LibDb.updatePromise(db, usql, params)
    .then((ok) => {
        return itemId;
    })
    .catch(err => {
        console.error("Failed to update:", err);
        throw err;
    })

}

function unitPopupList(){
    const list = Array.from(UNITS.values())
    .sort((a,b) => a.uname.localeCompare(b.uname))
    .map(v => {
             return {
                 id: v.id,
                 name: v.uchar,
                 fullname: v.uname,
                 code: 'unit'
             };
         });
    // console.info(`II:#62t article.js`, JSON.stringify(list))
    return list || [];
}


function pathPopupList(){
    const list = Array.from(FOLDERS.values())
    .sort((a,b) => a.pathname.localeCompare(b.pathname))
    .map(v => {
             return {
                 id: v.id,
                 name: "   ".repeat(v.deep || 0) + v.name,
                 fullname: v.pathname,
                 code: 'path'
             };
         });
    // console.info(`II:#62t article.js`, JSON.stringify(list))
    return list || [];
}

function newArticle(pid, dummy){
    const pidVal = String(pid || '');
    const pathInfo = getProductPathInfo(pidVal);
    const res = {
        id: '',
        pid: pidVal,
        folder: dummy?.folder ?? 0,
        pathid: dummy?.pathid || pathInfo.pathid || '',
        pathname: dummy?.pathname || pathInfo.pathname || '',
        scancode: '',
        itemchar: dummy?.itemchar || '',
        itemname: dummy?.itemname || '',
        itemnote: dummy?.itemnote || '',
        mask: dummy?.mask || 4,
        uktzed: dummy?.uktzed || '',
        taxchar: dummy?.taxchar || '',
        taxprc: dummy?.taxprc || '',
        unitid: dummy?.unitid || pathInfo.unitid || 'pc',
        unitchar: '',
        unitprec: '',
        unitname: '',
        unitcode: ''
    };
    return res;
}
function newFolder(pid){
    const pidVal = String(pid || '');
    const pathInfo = getProductPathInfo(pidVal);
    const res = {
        id: '',
        pid: pidVal,
        folder: 1,
        pathid: String(pathInfo.pathid || ''),
        pathname: String(pathInfo.pathname || ''),
        scancode: '',
        itemchar: '',
        itemname: '',
        itemnote: '',
        mask: 4,
        uktzed: '',
        taxchar: '',
        taxprc: '',
        unitid: String(pathInfo.unitid || 'pc') ,
        unitchar: '',
        unitprec: '',
        unitname: '',
        unitcode: ''
    };
    return res;
}

