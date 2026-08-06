.pragma library

function monProfit(db, flt) {
    if (!db) return [];
    const period =  (!flt || flt.length < 7)
                 ? new Date().toISOString().substring(0, 7)
                 : flt.substring(0, 7);
    const whereCondition = `WHERE substr(acntcdt,1,7)='rslt.35' AND substr(dcmtime,1,7) = '${period}'`;
    const vsql = `
    SELECT
        substr(dcmtime,1,7) AS tm,
        acntcdt AS acnt,
        p.client AS cshr,
        sum(amount) AS amnt
    FROM strgdocum AS d JOIN
        (SELECT dcmid, client  FROM strgdocum WHERE dcmtype='folder' AND acntcdt='rslt') AS p
        ON (d.parentid=p.dcmid)
    ${whereCondition}
    GROUP BY acntcdt, tm, p.client;
    `
    return db.dbSelectRowsJSON(vsql);
}
