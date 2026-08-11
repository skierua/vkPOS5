.pragma library

/**
 * Дефолтна структура курсу валюти (Захист від null/undefined)
 */
function dummy() {
    return {
        "id": "",
        "name": "",
        "phone": "",
        "clnote": "",
    };
}

/**
 *
 */
function dbClient(db, condition, filter) {
    if (!db) return null;
    const whereCondition = (condition ? `WHERE ${condition}` : "")
    const vsql = `
        SELECT
            pkey AS id,
            clchar AS name,
            phone,
            clnote
        FROM client
        ${whereCondition};
    `
    // console.log(`sqlClient.js#0ru ${vsql}`)
    return db.dbSelectRowsJSON(vsql, filter);
}

/**
 *
 */
function client(db, clid) {
    if (!db) return null;
    if (!clid) return null;     //dummy()

    const condition = `pkey = '${clid}'`;
    const res = dbClient(db, condition);

    if (res && res.length > 0)  return res[0];
    return null;
}

function ins(db, name, phone, note){
    if (!db) return false;

    const nameVal = String(name);
    const phoneVal = !!phone ? String(phone) : null;
    const noteVal = !!note ? String(note) : null;
     const sql = "INSERT INTO client (pkey, clchar, phone, clnote) VALUES ((SELECT coalesce(max(pkey), 0) +1 FROM client), ?, ?, ?); "
    const param = [ nameVal, phoneVal, noteVal ]
    // console.info(`II: sqlClient.js/upd sql=${sql}`)
    let ok = false;
    try {
        ok = db.dbInsert(sql, param);
    } catch (e) {
        console.error("[sqlClient.js] Критична помилка dbInsert: " + String(e));
        ok = false;
    }
    return ok;
}

function upd(db, id, name, phone, note){
    if (!db) return false;
    if (!id || Number(id || -1) < 0 || !name) return false;

    const nameVal = String(name);
    const phoneVal = !!phone ? String(phone) : null;
    const noteVal = !!note ? String(note) : null;
    const clid = String(id);
    const sql = "UPDATE client  SET clchar = ?, phone = ?, clnote = ? WHERE pkey = ?; "
    let ok = false;
    const param = [ nameVal, phoneVal, noteVal, clid ]
    // console.info(`II: sqlClient.js/upd sql=${sql}`)
    ok = db.dbUpdate(sql, param)
    return ok;
}
