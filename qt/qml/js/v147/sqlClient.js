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
