.pragma library


const dummyPrice = {
        "id": "",
        "item": "",
        "qtty": "1",
        "price": "0"
    }

function sell(db, itemid) {

    const pr = dbPrice(db, String("prbidask = -1 AND item='%1'").arg(itemid))
    // console.log("sqlPrice/bid pr=" + JSON.stringify(pr))
    if (pr.length > 0) return pr[0];

    return dummyPrice;
}

function dbPrice (db, flt = ""){
    const vsql = "select id, item, qtty, price from price "
            +  " WHERE prtype IS NULL"+ (flt === "" ? "" : (" AND "+ flt)) + ";";
    // console.log("sqlPrice/dbPrice vsql=" + vsql)
    try {
        const res = JSON.parse(db.dbSelectRows(vsql));
        return res.rows;
    } catch (err) {
        console.log("sqlPrice/dbPrice err=" + err)
        console.log("qry=" + vsql)
        return [];
    }
}
