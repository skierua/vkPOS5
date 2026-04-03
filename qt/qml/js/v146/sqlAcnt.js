.pragma library
/**
  JS library
*/


function acntBalance(db, acnt){
    if (acnt.length < 2) return []
    const reverse = (acnt.substring(0,2) !== "30" ? true : false)
    // const flt = "" + (String("substr(acntno,1,%1)='%2' AND abs(total) > 0.0009").arg(bal.length).arg(bal))
    const flt = "" + (String("acntno ='%1' AND abs(total) > 0.0009")
                      .arg(acnt))
        // .arg(" AND (abs(total) > 0.0009 OR dbtupd>date(coalesce((select max(shftdate) from shift),date('now')), '-0 days')")
        // .arg(" OR  cdtupd > date(coalesce((select max(shftdate) from shift),date('now')), '-0 days'))")
    return dbBalance(db, flt, "id", reverse)
}

function balBalance(db, bal){
    if (bal.length < 2) return []
    const reverse = (bal.substring(0,2) !== "30" ? true : false)
    const flt = "" + (String("substr(acntno,1,%1)='%2' AND abs(total) > 0.0009").arg(bal.length).arg(bal))
    // const flt = "" + (String("acntno ='%1' AND abs(total) > 0.0009")
    //                   .arg(bal))
        // .arg(" AND (abs(total) > 0.0009 OR dbtupd>date(coalesce((select max(shftdate) from shift),date('now')), '-0 days')")
        // .arg(" OR  cdtupd > date(coalesce((select max(shftdate) from shift),date('now')), '-0 days'))")
    return dbBalance(db, flt, "id", reverse)
}

function tradeBalance(db, bal = "3500"){
    if (bal.length < 2) return []
    const flt = (String("substr(acntrade.acntno,1,%1)='%2'").arg(bal.length).arg(bal))
    return dbTradeBalance(db, flt)
}


function dbBalance(db, flt = "", order = "", reverse = false){
    if (db === undefined) return []
    // console.log("sqlAcnts #y37 reverse=" + reverse + " comp=" + (reverse === false))
    let amount = " (beginamnt+turndbt-turncdt) as total, coalesce(turndbt, '') income, coalesce(turncdt, '') outcome, coalesce(dbtupd, '') intm, coalesce(cdtupd, '') outm,"
    if (reverse) { amount = " (0 - (beginamnt+turndbt-turncdt)) as total, coalesce(turncdt, '') income, coalesce(turndbt, '') outcome, coalesce(cdtupd, '') intm, coalesce(dbtupd, '') outm,"; }
    const vsql = "select id, acntno, coalesce(item, '') itemid," + amount
            + " coalesce(client, '') clid, coalesce(acntbal.acntnote,'') note, coalesce(acntbal.mask,'') mask, coalesce(acntbal.trade,'') trade, balname "
            + " from acnt left join acntbal using(acntno) LEFT JOIN balname ON (substr(acntno,1,2) = bal) "
            +  (flt === "" ? "" : (" WHERE " + flt))
            +  (order === "" ? ";" : (" ORDER BY  " + order + ";"))
    // .arg(" AND (abs(total) > 0.0009 OR dbtupd>date(coalesce((select max(shftdate) from shift),date('now')), '-0 days')")
    // .arg(" OR  cdtupd > date(coalesce((select max(shftdate) from shift),date('now')), '-0 days'))")

    try {
        const res = JSON.parse(db.dbSelectRows(vsql));
        // console.log("sqlAcnts #28747 data")
        // console.log("sqlAcnts #28747 vsql=" + vsql)
        // res.rows.forEach(v => console.log(v.id + "\t" + v.acntno + "\t" + v.item + "\t" + v.total + "\t" + v.note))
        return res.rows;
    } catch (err) {
        console.log("sqlAcnts #ai8 err=" + err)
        console.log("qry=" + vsql)
        return [];
    }
}

function old_dbBalance(db, flt = "", reverse = false){
    if (db === undefined) return []
    // console.log("sqlAcnts #5t2 reverse=" + reverse + " comp=" + (reverse === false))
    let amount = " (beginamnt+turndbt-turncdt) as total, coalesce(turndbt, '') income, coalesce(turncdt, '') outcome, coalesce(dbtupd, '') intm, coalesce(cdtupd, '') outm,"
    if (reverse) { amount = " (0 - (beginamnt+turndbt-turncdt)) as total, coalesce(turncdt, '') income, coalesce(turndbt, '') outcome, coalesce(cdtupd, '') intm, coalesce(dbtupd, '') outm,"; }
    const vsql = "select id, acntno, coalesce(item, '') itemid," + amount
            + " coalesce(client, '') clid, coalesce(acntbal.acntnote,'') note, coalesce(acntbal.mask,'') mask, coalesce(acntbal.trade,'') trade, balname "
            + " from acnt left join acntbal using(acntno) LEFT JOIN balname ON (substr(acntno,1,2) = bal) "
            +  " WHERE " + (flt === "" ? "" : (flt + " AND "))
            + " (abs(total) > 0.0009 OR dbtupd>date(coalesce((select max(shftdate) from shift),date('now')), '-0 days')"
            + " OR  cdtupd > date(coalesce((select max(shftdate) from shift),date('now')), '-0 days'));"

    try {
        const res = JSON.parse(db.dbSelectRows(vsql));
        // console.log("sqlAcnts #5t2 data")
        // console.log("sqlAcnts #5t2 vsql=" + vsql)
        // res.rows.forEach(v => console.log(v.id + "\t" + v.acntno + "\t" + v.item + "\t" + v.total + "\t" + v.note))
        return res.rows;
    } catch (err) {
        console.log("sqlAcnts #w8j err=" + err)
        console.log("qry=" + vsql)
        return [];
    }
}

// acnt should start with 35

function dbTradeBalance(db, flt =""){
    const vsql = "SELECT acntrade.pkey id, eqid, (beginamnt+turndbt-turncdt) total, bscprice, lastpricebuy buyprice, lastpricesell sellprice, article"
    + " FROM acntrade JOIN acnt ON (eqid=acnt.id)"
              + (flt === "" ? "" : (" WHERE "+ flt)) + " ORDER BY id;";
    try {
        // console.log("sqlAcnts/dbTradeBalance sql=" + vsql)
        const res = JSON.parse(db.dbSelectRows(vsql));
        return res.rows;
    } catch (err) {
        console.log("sqlAcnts/dbTradeBalance err=" + err)
        console.log("qry=" + vsql)
        return [];
    }

}

function old_dbTradeBalance(db, flt = "", reverse = false){
    if (db === undefined) return []
    // let amount = " (beginamnt+turndbt-turncdt) as total, coalesce(turndbt, '') income, coalesce(turncdt, '') outcome, coalesce(dbtupd, '') intm, coalesce(cdtupd, '') outm,"
    // if (reverse) { amount = " (0 - (beginamnt+turndbt-turncdt)) as total, coalesce(turncdt, '') income, coalesce(turndbt, '') outcome, coalesce(cdtupd, '') intm, coalesce(dbtupd, '') outm,"; }
    // console.log("sqlAcnts #5t2 reverse=" + reverse + " comp=" + (reverse === false) + " amnt=" + amount)
    const vsql = "SELECT id, acntno, coalesce(item, '') itemid,(0 - (beginamnt+turndbt-turncdt)) as total, coalesce(turncdt, '') income, coalesce(turndbt, '') outcome, coalesce(cdtupd, '') intm, coalesce(dbtupd, '') outm,"
        + " coalesce(client, '') clid, coalesce(acntbal.acntnote,'') note, coalesce(acntbal.mask,'') mask,"
        + " coalesce(acntbal.trade,'') trade, balname, bscprice, eqtotal"
        + " FROM acnt LEFT JOIN acntbal USING(acntno) LEFT JOIN balname ON (substr(acntno,1,2) = bal) JOIN"
        + " (SELECT pkey, eqid, bscprice, (beginamnt+turndbt-turncdt) AS eqtotal FROM acntrade JOIN acnt ON (eqid=id)) eqacnt ON (id = eqacnt.pkey)"
        +  " WHERE " + (flt === "" ? "" : (flt + " AND "))
        + " (abs(total) > 0.0009 OR dbtupd>date(coalesce((select max(shftdate) from shift),date('now')), '-0 days')"
        + " OR  cdtupd > date(coalesce((select max(shftdate) from shift),date('now')), '-0 days'));"

    try {
        const res = JSON.parse(db.dbSelectRows(vsql));
        // console.log("sqlAcnts/dbTradeBalance #6we data")
        // console.log("sqlAcnts/dbTradeBalance #5t2 vsql=" + vsql)
        // res.rows.forEach(v => console.log(v.id + "\t" + v.acntno + "\t" + v.item + "\t" + v.total + "\t" + v.note))
        return res.rows;
    } catch (err) {
        console.log("sqlAcnts/dbTradeBalance #0wj err=" + err)
        console.log("qry=" + vsql)
        return [];
    }
}


function acntbal (db, flt = ""){
    const vsql = "select acntno, coalesce(client, '') client, acntnote, mask, trade from acntbal "
              + (flt === "" ? "" : (" WHERE "+ flt)) + " ORDER BY acntno;";
    try {
        const res = JSON.parse(db.dbSelectRows(vsql));
        return res.rows;
    } catch (err) {
        console.log("sqlAcnts/acntbal err=" + err)
        console.log("qry=" + vsql)
        return [];
    }
}




