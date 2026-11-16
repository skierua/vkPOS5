.pragma library

function selectPromise(db, sql, params = []) {
    return new Promise((resolve, reject) => {
        if (!db) {
            return reject("DB_UNDEFINED");
        }
        if (!sql) {
            return reject("SQL_MISSING");
        }

        try {
            const resp = db.dbSelectRows(sql, params);
            const err = db.dbLastError();

            if (err && err !== "") {
                reject(err);
            } else {
                resolve(resp || []);
            }
        } catch (e) {
            reject(e.message || String(e));
        }
    });
}

function updatePromise(db, sql, params) {
    return new Promise((resolve, reject) => {
        if (!db) {
            return reject("DB_UNDEFINED");
        }
        if (!sql) {
            return reject("SQL_MISSING");
        }
        try {
           const resp = db.dbUpdate(sql, params);
           const err = db.dbLastError();

           if (err && err !== "") {
               reject(err);
           } else {
               resolve(resp);
           }
        } catch (e) {
           reject(e.message || String(e));
        }
    });
}

function insertPromise(db, sql, params) {
    return new Promise((resolve, reject) => {
        if (!db) {
            return reject("DB_UNDEFINED");
        }
        if (!sql) {
            return reject("SQL_MISSING");
        }
        try {
          const resp = db.dbInsert(sql, params);
          const err = db.dbLastError();

          if (err && err !== "") {
              reject(err);
          } else {
              resolve(resp);
          }
        } catch (e) {
          reject(e.message || String(e));
        }
    });
}
