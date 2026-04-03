.pragma library

// domestic currency code
const DomesticCurrencyCode = "980";
// cache for folders
let folderPathCache = [];
// cache for items
let itemCache = [];


/*function path(db){
    var jdata = ({});
    let vsql = String("SELECT pkey as id, coalesce(parentid, '') pid, itemchar FROM item WHERE folder = 1 ORDER BY pkey;");
    try {
        jdata = JSON.parse(db.dbSelectRows(vsql));
    } catch (err) {
        // log('getClient #25fa error');
        return [];
    }
    let i =0;
    console.log("sqlItem #73ry \n")
    let vid = "", vpid = "";
    let vpathid = "", vpathname = "";
    let idx = -1;
    for (i =0; i < jdata.rows.length; ++i){
        vid = jdata.rows[i].id;
        vpid = jdata.rows[i].pid;
        vpathid = "/" + jdata.rows[i].id;
        vpathname = "/" + jdata.rows[i].itemchar
        while (vpid !== "") {
            // TODO rewrite with binary search
            idx = jdata.rows.findIndex( (v) => v.id === vpid );
            if (idx === -1) break;
            vpathid = "/" + jdata.rows[idx].id + vpathid;
            vpathname = "/" + jdata.rows[idx].itemchar + vpathname;
            vpid = jdata.rows[idx].pid;
        }
        folderPath.push({
                     "pid": jdata.rows[i].id,
                     "pathid": vpathid,
                     "name": jdata.rows[i].itemchar,
                     "pathname": vpathname
                 }
                )
        // console.log(jdata.rows[i].id + "\t" + jdata.rows[i].pid + "\t" + vpathid + "\t" + jdata.rows[i].itemchar)
    }
    folderPath.sort((a,b) => {
                 return a.pid > b.pid ? 1 : -1;
                 // return a.pathid.localeCompare(b.pathid);
             })
    folderPath.forEach(v => console.log(v.pid + "\t" + v.pathid + "\t" + v.name + "\t" + v.pathname))
    return;
}
*/

function dummyFolder(){
    return {
        "id": "",
        "pid": "",
        "pathid": "",
        "name": "",
        "pathname": ""
    }
}

function dummyItem(){
    return {
        "id": "",
        "pid": "",
        "pathid": "",
        "pathname": "",
        "scancode": "",
        "itemchar": "",
        "itemname": "",
        "itemnote": "",
        "uktzed": "",
        "taxchar": "",
        "taxprc": "",
        "unitid": "",
        "unitchar": "",
        "unitprec": "",
        "unitname": "",
        "unitcode": ""
    };
}

function findFolder(id){
    return folderPathCache.findIndex( (v) => v.id === id );
}

// binary search
function b_findFolder(pid){
    if (folderPathCache.length  === 0) return -1
    let lf =0, rt = folderPathCache.length -1;
    let i =0;
    while (lf <= rt) {
        i = Math.floor((rt + lf) / 2);
        if (pid === folderPathCache[i].id) break
        if (pid < folderPathCache[i].id) rt = i -1
        else lf = i +1
    }
    // console.log("sqlItem/findFolder pid=" + pid + " cache=" + folderPathCache[i].pid +" lf="+ lf + " rt=" + rt)
    if (folderPathCache[lf].id === pid) return lf

    return -1;
}

function findItem(id){
    return itemCache.findIndex( (v) => v.id === id );
}

function fillFolderCache(db){
    folderPathCache = []
    var jdata = ({});
    let vsql = String("SELECT pkey as id, coalesce(parentid, '') pid, itemchar FROM item WHERE folder = 1 ORDER BY pkey;");
    try {
        jdata = JSON.parse(db.dbSelectRows(vsql));
    } catch (err) {
        // log('getClient #25fa error');
        return false;
    }
    let i =0;
    let vid = "", vpid = "";
    let vpathid = "", vpathname = "";
    let idx = -1;
    for (i =0; i < jdata.rows.length; ++i){
        vid = jdata.rows[i].id;
        vpid = jdata.rows[i].pid;
        vpathid = "/"  // + jdata.rows[i].id + "/"
        vpathname = "/"    // + jdata.rows[i].itemchar + "/"
        while (vpid !== "") {
            // TODO rewrite with binary search
            idx = jdata.rows.findIndex( (v) => v.id === vpid );
            if (idx === -1) break;
            vpathid = "/" + jdata.rows[idx].id + vpathid;
            vpathname = "/" + jdata.rows[idx].itemchar + vpathname;
            vpid = jdata.rows[idx].pid;
        }
        folderPathCache.push({
                    "id": jdata.rows[i].id,
                    "pid": jdata.rows[i].pid,
                    "pathid": vpathid,
                    "name": jdata.rows[i].itemchar,
                    "pathname": vpathname
                 }
                )
        // console.log(jdata.rows[i].id + "\t" + jdata.rows[i].pid + "\t" + vpathid + "\t" + jdata.rows[i].itemchar)
    }
    folderPathCache.sort((a,b) => {
                 return a.id > b.id ? 1 : -1;
                 // return a.pathid.localeCompare(b.pathid);
             })
    // console.log("sqlItem/fillFolderCache #73ry \n")
    // folderPathCache.forEach(v => console.log(v.pid + "\t" + v.pathid + "\t" + v.name + "\t" + v.pathname))

    return true;
}

function pushItemToCache(db, id){
    let res = dummyItem();
    const dbatcl = ( id === "" ?
                        dbItems(db, String("item.itemmask=1"))
                      : dbItems(db, String("item.pkey='%1'").arg(id)));
    // console.log("sqlItem/pushItemToCache #75h dbatcl.len=" + dbatcl.length + " a=" + JSON.stringify(dbatcl))
    if (dbatcl.length === 0) {
        return false
    }
    res = dbatcl[0]
    if (id === "") res.id = ""
    res.pathid = ""
    res.pathname = ""
    let fidx = findFolder(res.pid)
    if (fidx < 0) fillFolderCache(db)
    fidx = findFolder(res.pid)
    if (fidx !== -1) {
        res.pathid = folderPathCache[fidx].pathid + folderPathCache[fidx].id    // + "/"
        res.pathname = folderPathCache[fidx].pathname + folderPathCache[fidx].name  // + "/"
    }
    itemCache.push(res);
    // console.log("sqlItem #36g len=" + itemCache.length)
    return true
}

function getItemById(db, id ="") {
    if (id === DomesticCurrencyCode) id = "";
    let res = dummyItem();
    let cacheidx = findItem(id);
    // console.log("sqlItem #11ds7h cacheidx=" + cacheidx)
    if (cacheidx === -1) pushItemToCache(db, id)
    cacheidx = findItem(id);
    // console.log("sqlItem #22ds7h cacheidx=" + cacheidx)
    if (cacheidx === -1) return res;
    return itemCache[cacheidx];
}


function dbItems(db, flt){
    if (db === undefined) return []
    let vsql = String("select item.pkey as id, coalesce(item.parentid, '') pid, scancode, itemchar, coalesce(itemname, '') itemname, coalesce(itemnote, '') itemnote, itemmask mask,"
                      + " coalesce(uktzed, '') uktzed, coalesce(taxchar, '') taxchar, coalesce(taxprc, '') taxprc,"
                      + " coalesce(defunit, '') unitid, unitchar, coalesce(unitprec, 2) unitprec, coalesce(unitname, '') unitname, coalesce(code, '') unitcode"
                      + " FROM item LEFT JOIN itemunit ON (defunit=itemunit.pkey) "
            + " WHERE folder = 0 " + (flt === "" ? "" : (" AND "+ flt)) + ";");
    try {
        const res = JSON.parse(db.dbSelectRows(vsql));
        return res.rows;
    } catch (err) {
        console.log('dbItems #25fa error');
        console.log("sqlItem #6tcc sql=" + vsql)
        return [];
    }
}
