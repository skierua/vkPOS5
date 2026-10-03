.pragma library

function monProfit(db, vdate) {
    if (!db) return [];
    const vdateT = !!vdate ? vdate.trim() : "";
    const period =  (!vdateT || !Date.parse(vdateT) || vdateT.length < 7)
                 ? new Date().toISOString().substring(0, 7)
                 : vdateT.substring(0, 7);
    const params = [];
    params.push(period)
    const whereCondition = `WHERE substr(acntcdt,1,7)='rslt.35' AND dcmnote LIKE '%reval%' AND dcmtime LIKE (? || '%')`;
    // const whereCondition = `WHERE substr(acntcdt,1,7)='rslt.35' AND dcmnote LIKE '%reval%' AND dcmtime LIKE '${period}%'`;
    const vsql = `
    SELECT
        substr(dcmtime,1,7) AS tm,
        acntcdt AS acnt,
        dcmaker AS cshr,
        sum(amount) AS amnt
    FROM strgdocum
    ${whereCondition}
    GROUP BY acntcdt, tm, dcmaker;
    `
    return db.dbSelectRows(vsql, params) || [];
}

