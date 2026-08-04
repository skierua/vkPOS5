import QtQuick
import "js/v147/sqlBind.js" as LibBind
import "js/v147/sqlItem.js" as LibItem

ListModel {
    id: mRoot
    property var bind
    property var data
    property int pageCapacity: 25
    property list<int> pager: []
    property int bindCount: 0   // filtered bind count
    // property bool acntOnly: false
    // onAcntOnlyChanged: filterData()

    function dbg(str, code ="") {
        console.log( String("%1[ModelDbDcms] %2").arg(code).arg(str));
    }

    function load(db, from = "") {
        const source1 = LibBind.dbDocum(db, from, false);
        const source2 = LibBind.dbDocum(db, from, true);
        // console.log(`ModelDbDcms source1 ${JSON.stringify(source1)}`);
        const joinSource = source1.concat(source2);
        const bindMap = new Map(
            joinSource.filter(v => v.pid === "")
                // .sort((a, b) => new Date(b.dcmtime) - new Date(a.dcmtime))
                // .sort((a, b) => b.dcmtime > a.dcmtime ? 1 : -1
                // .sort((a,b) => b.pid - a.pid
                //       || b.dcmid - a.dcmid )
                .map(v => [v.dcmid, v])
        );
        // console.log(`ModelDbDcms#d7yh ${JSON.stringify([...bindMap.entries()])}`)
        const dcmList = joinSource
        .filter(v => v.pid !== "")
        .sort((a, b) =>
            (a.shftid === 0 && b.shftid !== 0) ? -1 :
            (a.shftid !== 0 && b.shftid === 0) ? 1 :
            ((b.shftid - a.shftid) || (b.pid - a.pid) || (a.dcmid - b.dcmid))
        )
        .map(function(v) {
                // Створюємо копію об'єкта v та додаємо jarticle
                return Object.assign({}, v, {
                    jarticle: LibItem.getItemById(db, v.itemid)
                });
            });
        // console.log(`ModelDbDcms source1 ${JSON.stringify(dcmList)}`);

        mRoot.bind = bindMap;
        mRoot.data = dcmList
        filterData()
    }

    function isAllowed(row, flt){
        const dcm = mRoot.data[row];
        const filterLower = flt.toLowerCase();
        const noteStr = String(dcm.dcmnote || "").toLowerCase();
        const atclStr = String(dcm.jarticle?.itemchar || "").toLowerCase();
        const atclFStr = String(dcm.jarticle?.itemname || "").toLowerCase();

        return (dcm.dcmid === flt
                || noteStr.includes(filterLower)
                || (dcm.jarticle?.scancode || "").includes(filterLower)
                || (dcm.acntcdt || "") === filterLower
                || atclStr.includes(filterLower)
                || atclFStr.includes(filterLower)
                );
    }

    function filterData(flt = ""){
        let tmpa = []
        // mRoot.offset = 0
        let count =0, fcount =0
        let pid = 0, fpid = 0
        for ( let r =0; r < data.length; ++r){
            if (flt === undefined || flt === "" || isAllowed(r, flt) ){
                if (fpid !== data[r].pid) {
                    fpid = data[r].pid
                    if (fcount % pageCapacity === 0 ) tmpa.push(r);
                    ++fcount
                }
                data[r].flt = true;
            } else  { data[r].flt = false; }
        }

        // dbg("pager=" + JSON.stringify(tmpa), "#84u");
        mRoot.pager = tmpa
        bindCount = fcount;
        populate()
    }

    function populate(page =1){
        mRoot.clear();
        let pid = ""
        let ofs = mRoot.pager[page-1]
        let lim = (page >= mRoot.pager.length ? data.length : mRoot.pager[page])
        // dbg("page="+page+" ofs="+ofs+" lim="+lim, "#sh48")
        for (; ofs < lim; ++ofs){

            if (!data[ofs].flt) continue;
            addNew(data[ofs]);
            // mRoot.append(data[ofs])
        }
        // dbg("count="+ mRoot.count, "#74y")
    }

    function addNew(row, idx = count){
        if (!row) return;
        const isTrade = row.eqamount !== 0 || row.dcmtype.startsWith("trade:");
        mRoot.insert(idx, {
                         // "dataRowId": dataId,
                         "dcmid": row.dcmid
                         , "pid": row.pid
                         ,"dcmtype": row.dcmtype || ""
                         , "acntdbt": row.acntdbt
                         , "acntcdt": row.acntcdt
                         , "amount": row.amount
                         , "eqamount": row.eqamount
                         , "discount": row.discount
                         , "bonus": row.bonus
                         , "dcmnote": row.dcmnote
                         , "itemid": row.itemid
                         , "itemchar": row.jarticle.itemchar
                         , "unitprec": row.jarticle.unitprec
                         , "isTrade": isTrade
                         , "flt": row.flt
                         ,
                     });

    }

   function bindInfo(pid){
        return mRoot.bind.get(Number(pid));


        // let lf =0, rt = mRoot.bind.length -1, md =0;
        // while (lf < rt) {
        //     // dbg("bindInfo vid="+vid + " lf="+ lf + "/" + mRoot.bind[lf].dcmid + " rt="+rt + "/" + mRoot.bind[rt].dcmid+ " md="+md)
        //     md = lf + Math.floor((rt - lf)/2)
        //     if (mRoot.bind[md].dcmid < vid) lf = md + 1
        //     else rt = md
        // }
        // // dbg("bindInfo vid="+vid + " finded="+ mRoot.bind[lf].dcmid)

        // return mRoot.bind[lf];
    }

    function showFullBind(idx){
        if (idx < 0 || idx >= count) return null;
        const pid = get(idx).pid
        let modelCounter = idx;
        for( ; modelCounter < count && get(modelCounter).pid === pid; ++modelCounter){ }
        let bindCounter = 0;
        for( --modelCounter; modelCounter >= 0 && get(modelCounter).pid === pid; --modelCounter, ++bindCounter){ }
        // if (get(modelCounter).pid !== pid)
            ++modelCounter;
        // console.log(`ModelDbDcm#wy7 count=${count} modelCounter=${modelCounter} bidCounter=${bindCounter}`)
        remove(modelCounter, bindCounter);
        const bind = mRoot.data.filter(v => v.pid === pid);
        for (const dcm of bind)
            addNew(dcm, modelCounter);
    }

    function bindForPrint(idx){
        if (idx < 0 || idx >= count) return null;
        const pid = get(idx).pid
        const bindDcms = mRoot.data
        .filter(v => v.pid === pid)
        .map((v) => { return {
                 "dcm": v.dcmtype || "",
                 "dbt": v.acntdbt || "",
                 "cdt": v.acntcdt || "",
                 "crn": v.itemid || "",
                 "amnt": (v.amount || 0).toFixed(v.jarticle?.unitprec || 2),
                 "eq": (v.eqamount || 0).toFixed(2),
                 "dsc": (v.discount || 0).toFixed(2),
                 "bns": (v.bonus || 0).toFixed(2),
                "jitem": v.jarticle,
                 "note": v.dcmnote || "",
                 "retfor": v.retfor || ""
             }; });
        const parent = bindInfo(Number(pid));
        const res = {
            "id": "dcmbind",
            "dcm": parent?.dcmtype || "",
            "dbt": parent?.acntdbt || "",
            "cdt": parent?.acntcdt || "",
            "amnt": (parent?.amount || 0).toFixed(2),
            "eq": (parent?.eqamount || 0).toFixed(2),
            "dsc": (parent?.discount || 0).toFixed(2),
            "bns": (parent?.bonus || 0).toFixed(2),
            "note": parent?.dcmnote || "",
            "clnt": parent?.clid || "",
            "tm": parent?.dcmtime || "",
            "dcms":bindDcms
        }
        return res;
    }

    function dcmForRefuse(idx){
        if (idx < 0 || idx >= count) return null;
        const v = get(idx);
        const clidVar = Number(v.bonus || 0) === 0 ? "" : (bindInfo(Number(v.pid))?.clnt || "");

        const res =
            {
             "dcmid": v.dcmid
             , "pid": v.pid
            ,"dcmtype": v.dcmtype || ""
             , "acntdbt": v.acntdbt
             , "acntcdt": v.acntcdt
             , "amount": v.amount
             , "eqamount": v.eqamount
             , "discount": v.discount
             , "bonus": v.bonus
             , "dcmnote": v.dcmnote
             , "itemid": v.itemid
             // , "itemchar": row.jarticle.itemchar
             // , "unitprec": row.jarticle.unitprec
             , "isTrade": v.isTrade
            , "clid": clidVar
             // , "flt": row.flt
            };
        return res;
    }

}
/*
{
    "id": "dcmbind",
    "dcm": model.code,
    "dbt": cashAcntNo,
    "cdt": "",
    "amnt": (total?.pmnt || 0).toFixed(2),
    "eq": (total?.eq || 0).toFixed(2),
    "dsc": (total?.dsc || 0).toFixed(2),
    "bns": (total?.bns || 0).toFixed(2),
    "note": "",
    "clnt": ui.clid || "",
    "tm": utcTimeStamp,
    "dcms":
        [
            {
                "dcm": row.dcode,
                "dbt": targetAcntNo,
                "cdt": row.dacnt?.acntno || "",
                "crn": row.darticle?.id || "",
                "amnt": (row.dsign * Number(row.damnt || 0)).toFixed(precision),
                "eq": (row.moneyEq || 0).toFixed(2),
                "dsc": (row.moneyDsc || 0).toFixed(2),
                "bns": (row.moneyBns || 0).toFixed(2),
                "note": row.dnote || "",
                "retfor": row.retfor || ""
            },
        ]
}
*/

