import QtQuick
import "js/v147/config.js" as Conf
import "js/v147/sqlAcnt.js" as LibAcnt
import "js/v147/sqlClient.js" as LibClient
import "js/v147/sqlItem.js" as LibItem

ListModel {
    id: mRoot
    property var data
    property var rawCachedData: []

    function load(db, balList, mask =0, reverse =false) {
        if (!balList || balList.length < 1) return;
        const res = [];
        const condition = Number(mask < 4) ? `(item IS NULL OR length(item) < 4)` : ""
        for (let bal of balList){
            const source = LibAcnt.balBalance2(db, bal, condition) || [];
            // console.log(`ModelDrawer/load source=${JSON.stringify(source)}`)
            if (!source || source.length < 1) continue;
            for (let acnt of source){
                const item = LibItem.getItemById(db, acnt.itemid);
                // console.log(`ModelDrawer/load item=${JSON.stringify(item)}`)
                if (!(mask & (item?.mask || 0))) continue;
                const client = LibClient.client(db, acnt.clid);
                const total = reverse ? 0 - Number(acnt?.total || 0.0) : Number(acnt?.total || 0.0);
                const income = reverse ? 0 - Number(acnt?.income || 0.0) : Number(acnt?.income || 0.0);
                const outcome = reverse ? 0 - Number(acnt?.outcome || 0.0) : Number(acnt?.outcome || 0.0);
                const clnt = !!(acnt?.clid || "")? `${client?.name}[${acnt.clid}]` : "";
                const nameVal = (item?.itemchar || "???")
                            + ((bal.startsWith(String(Conf.glDepoPrefix || "")) || bal.startsWith(String(Conf.glInitPrefix || ""))) ? ` ${(acnt?.note || "")}` : "")
                            + (!!(acnt?.clid || "")? `${client?.name}[${acnt.clid}]` : "");
                const rowData = {
                    "bind": acnt?.note || "",
                    "name": nameVal,
                    "subname":`[${ item?.id || ""}] ${ item?.itemname || ""}`,
                    "total": total,
                    "income": income,
                    "outcome": outcome,
                    "key": item?.id || "",
                    "prec": item?.unitprec ?? 2,
                    "scan": item?.scancode || "",
                    "totaleq": 0,
                    "clid": acnt?.clid || "",
                    "clchar": client?.name || "",
                    "acntno": acnt?.acntno || "",
                    "mask": item?.mask || 0,
                    "so": item?.itemnote || "",
                };
                res.push(rowData);
                // console.log(`ModelDrawer/load source=${JSON.stringify(rowData)}`)
            }
        }
        // console.log(`ModelDrawer/load res=${JSON.stringify(res)}`)
        res.sort((a,b) => {
                     const compBind = (a.bind || "").localeCompare(b.bind || "");
                     if (compBind !== 0) return compBind;

                     const maskA = Number(a.mask);
                     const maskB = Number(b.mask);
                     if (!isNaN(maskA) && !isNaN(maskB) && maskA !== maskB) {
                         return maskA - maskB;
                     }

                     const numA = Number(a.so);
                     const numB = Number(b.so);
                     if (!isNaN(numA) && !isNaN(numB) && numA !== numB) {
                         return numA - numB;
                     }
                     const compSo = (a.so || "").localeCompare(b.so || "");
                     if (compSo !== 0) return compSo;

                     return (a.acntno || "").localeCompare(b.acntno || "");
                 })
        mRoot.rawCachedData = res;
        filterData()
    }

    function isAllowed(row, flt) {
        if (!row) return false;
        if (!flt || flt === "") return true;

        const filterLower = flt.trim().toLowerCase();
        const scancodeStr = String(row.scan || "").toLowerCase();
        const charStr = String(row.name || "").toLowerCase();
        const nameStr = String(row.subname || "").toLowerCase();
        const clStr = String(row.clchar || "").toLowerCase();

        // console.log(`ModelDrawer/isAllowed flt=${filterLower} name=${charStr}`)
        return (row.acntno === flt
                || row.clid === flt
                || scancodeStr.includes(filterLower)
                || charStr.includes(filterLower)
                || nameStr.includes(filterLower)
                || clStr.includes(filterLower));
    }

    function filterData(flt =""){

        for ( let r =0; r < rawCachedData.length; ++r){
            if (flt === undefined || flt === "" || isAllowed(mRoot.rawCachedData[r], flt) ){
                rawCachedData[r].flt = true;
            } else  { rawCachedData[r].flt = false; }
        }

        populate()
    }

    function populate(){
        mRoot.clear();
            const cachedArr = mRoot.rawCachedData;
            if (!Array.isArray(cachedArr)) return;

            for (let ofs = 0; ofs < cachedArr.length; ++ofs) {
                if (!cachedArr[ofs].flt) continue;
                mRoot.append(cachedArr[ofs]);
            }
        // mRoot.clear();

        // for ( let ofs =0; ofs < rawCachedData.length; ++ofs){

        //     if (!rawCachedData[ofs].flt) continue;

        //     mRoot.append(rawCachedData[ofs])
        // }
    }

}

/*
  data structure
  [{
    "bind":"",
    "name":"USD",
    "subname":"[840] долар США",
    "total":"25580",
    "income":"0",
    "outcome":"0",
    "key":"840",
    "prec":"2",
    "scan":"",
    "totaleq":"0",
    "clid":"",
    "clchar":"",
    "ano":"3000",
    "mask":"2"
}]


*/
