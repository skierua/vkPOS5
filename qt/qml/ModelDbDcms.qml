import QtQuick
import "../lib.js" as Lib

ListModel {
    id: root
    property var bind
    property var data
    property int pageCapacity: 10
    property list<int> pager: []
    property int bindCount: 0   // filtered bind count
    property bool acntOnly: false
    // onAcntOnlyChanged: filterData()

    // signal vkEvent(string id, var param)

    function dbg(str, code ="") {
        console.log( String("%1[ModelDbDcms] %2").arg(code).arg(str));
    }

    function load(db, from ="") {
        // vkEvent("log","load() " + JSON.stringify(root.queryData.req));
        const vflt = String("parentid != '' %1").arg(from !== "" ? (" AND " + from): "")
        root.bind = Lib.getBindList(db, String("dcmid in (SELECT DISTINCT parentid FROM documall WHERE %1)").arg(vflt))
        root.data = Lib.getDcmList(db, vflt)
        // console.log("[ModelDbDcms]:")
        // for (let i=0; i < 10; ++i){
        //     console.log(JSON.stringify(root.bind[i]))
        // }
        // for (let k = root.bind.length - 1, m=0; k >=0 && m < 20; --k, ++m){
        //     console.log(JSON.stringify(root.bind[k]))
        // }
        filterData()
    }

    function isAllowed(row, flt){
        return ( ~((root.data[row].dnote).toLowerCase()).indexOf(String(flt).toLowerCase())
        || ~((root.data[row].iname).toLowerCase()).indexOf(String(flt).toLowerCase())
        || ~((root.data[row].ifname).toLowerCase()).indexOf(String(flt).toLowerCase())
        || ~((root.data[row].scan).toLowerCase()).indexOf(String(flt).toLowerCase())
        || (root.data[row].acntcdt === flt))
    }

    function filterData(flt =""){
        let tmpa = []
        // root.offset = 0
        let count =0, fcount =0
        let pid = "", fpid = ""
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
        root.pager = tmpa
        bindCount = fcount;
        populate()
    }

    function populate(page =1){
        root.clear();
        let pid = ""
        let ofs = root.pager[page-1]
        let lim = (page >= root.pager.length ? data.length : root.pager[page])
        // dbg("page="+page+" ofs="+ofs+" lim="+lim, "#sh48")
        for (; ofs < lim; ++ofs){

            if (!data[ofs].flt) continue;

            root.append(data[ofs])
        }
        // dbg("count="+ root.count, "#74y")
    }

    function price(row) {
        if (row < 0) return ""
        // dbg("price(row)="+ row, "#5qgf")
        const coef = Number(data[row].qty)
        const res = coef * (Number(data[row].eq) + Number(data[row].dsc))/Number(data[row].amount)
        return res.toFixed(4) + (coef !== 1 ? ("/" + String(coef)) : "")
    }

    function bindInfo(vid){
        // vkEvent("log", "bindInfo vid="+vid)
        // let i = 0
        // for (i = 0; (i < data.length && data[i].pid !== vid); ++i) {}
        // binary search
        let lf =0, rt = root.bind.length -1, md =0;
        while (lf < rt) {
            // dbg("bindInfo vid="+vid + " lf="+ lf + "/" + root.bind[lf].dcmid + " rt="+rt + "/" + root.bind[rt].dcmid+ " md="+md)
            md = lf + Math.floor((rt - lf)/2)
            if (root.bind[md].dcmid < vid) lf = md + 1
            else rt = md
        }
        // dbg("bindInfo vid="+vid + " finded="+ root.bind[lf].dcmid)

        return root.bind[lf];
    }

    function showFullBind(row){
        const pid = get(row).pid
        ++row
        for( ; row < count && pid === get(row).pid; ++row){ }
        let lf =0, rt = root.data.length -1, md =0;
        while (lf < rt /*&& pid !== root.data[lf].pid*/) {
            // dbg("showFullBind pid="+ pid + " lf="+ lf + "/" + root.data[lf].pid + " rt="+rt + "/" + root.data[rt].pid+ " md="+md)
            md = lf + Math.floor((rt - lf)/2)
            if (root.data[md].pid > pid) lf = md + 1
            else rt = md
        }
        // dbg("showFullBind pid="+pid + " lf=" + lf + " finded="+ root.data[lf].pid)
        for( ; lf > 0 && pid === root.data[lf-1].pid; --lf){}
        // dbg("showFullBind AFTER pid="+pid + " lf=" + lf + " finded="+ root.data[lf].pid)
        for( ; lf < data.length && pid === root.data[lf].pid; ++lf) {
            if (data[lf].flt) continue;
            insert(row, data[lf])
        }
    }

//     function humanDate(vdate) {
//         var vtmp = Date()
//         var vdiff = Math.floor(((new Date().getTime())-(new Date(String(vdate).substring(0,10)).getTime()))/(1000*60*60*24))
//         if (vdiff == 0) { return vdate.substring(11,16) // Qt.formatDate(new Date(vdate), 'hh:mm')
//         } else if (vdiff == 1) { return 'вч '+vdate.substring(11,16)  //Qt.formatDate(new Date(vdate), 'вч hh:mm')
// //        } else if (vdiff < 8) { return Math.floor(((new Date().getTime())-(new Date(String(vdate).substring(0,10)).getTime()))/(1000*60*60*24))+' дн.'
//         } else if (vdiff < 360) { return Qt.formatDate(new Date(vdate), 'dd MMM')
//         } else { return Qt.formatDate(new Date(vdate), 'MMM yy'); /*String(vdate).substring(0,10);*/ }

//     }

}

/*
  db Bind structure
  [{
    "shftid":"1433",
    "dcmid":"556252",
    "dcmno":"",
    "dcmtype":"check",
    "atclid":"",
    "acntdbt":"3000",
    "acntcdt":"",
    "amount":"-11390",
    "eq":"11390",
    "dsc":"0",
    "bns":"0","clid":"",
    "pid":"",
    "dnote":"",
    "dtm":"2025-10-03T12:22:28",
    "clchar":""
  }]
*/

/*
  db docum structure
  [{
    "shftid":"1433",
    "dcmid":"556267",
    "dcmno":"",
    "dcmtype":"trade:sell",
    "atclid":"978",
    "acntdbt":"3000",
    "trade":"1",
    "acntcdt":"3500",
    "amount":"-1000",
    "eq":"-48800",
    "dsc":"0",
    "bns":"0",
    "clid":"",
    "pid":"556266",
    "dnote":"EUR",
    "dtm":"2025-10-03T13:16:07",
    "clchar":"",
    "iname":"EUR",
    "ifname":"ЄВРО",
    "scan":"",
    "imask":"2",
    "qty":"1",
    "prec":"2"
}]
  */
