import QtQuick

import "js/v146/sqlItem.js" as LibItem
import "js/v146/sqlAcnt.js" as LibAcnt
import "js/v146/sqlPrice.js" as LibPrice


ListModel {
    id: root
    property var data
    property int pageCapacity: 40
    property list<int> pager: []
    property var sectTotal: []         // sum for sections

    function dbg(str, code ="") {
        console.log( String("[ModelBalance.qml]#%1 %2").arg(code).arg(str));
    }

    function isAllowed(item, flt){
        const ok = (flt === undefined || flt === ""
                    || item.id === flt
                || ~(item.scancode).indexOf(flt)
                || ~(item.itemchar.toLowerCase()).indexOf(flt.toLowerCase())
                || ~(item.itemname.toLowerCase()).indexOf(flt.toLowerCase())
                || ~(item.itemnote.toLowerCase()).indexOf(flt.toLowerCase())
                );

        return ok
    }

    function load(db, bal = "300", order = "id", flt = "") {
        // bal = "350"; // for testing
        // dbg("bal="+bal+" order="+order+" flt=["+flt+"]", "7wqh")
        // return
/*  =      {"id":"19501",
    =        "acntno":"3000",
    =        "itemid":"204884",
    =        "total":"1",
    =        "income":"0",
    =        "outcome":"0",
    =        "intm":"2026-03-30T10:04:15",
    =        "outm":"",
    =        "clid":"",
    =        "note":"",
    =        "mask":"1",
    =        "trade":"0",
    =        "balname":"Залишок",
            "item":{"id":"204884",
                "pid":"203300",
                "scancode":"4820273270865",
                "itemchar":"Світ-к LED Al6163-1ARD 35W  круг",
                "itemname":"",
                "itemnote":"",
                "mask":"4",
                "uktzed":"", "taxchar":"","taxprc":"",
                "unitid":"pc","unitchar":"шт","unitprec":"0","unitname":"штук","unitcode":"2009",
                "pathid":"/100004/203300/",
                "pathname":"/ТОВАР/Світильник LED/"},
            "price":1600,
            "eq":1600,
            "bind":"Залишок"
        } */
        let dummyRow = ()=>{
            const row = {
                "id":"",
                "acntno":"",
                "itemid":"",
                "total":"",
                "income":"",
                "outcome":"",
                "intm":"",
                "outm":"",
                "clid":"",
                "note":"",
                "mask":"1",
                "trade":"0",
                "balname":"",
                "item": undefined,
            /*    {"id":"",
                    "pid":"",
                    "scancode":"",
                    "itemchar":"",
                    "itemname":"",
                    "itemnote":"",
                    "mask":"",
                    "uktzed":"", "taxchar":"","taxprc":"",
                    "unitid":"","unitchar":"","unitprec":"","unitname":"","unitcode":"",
                    "pathid":"",
                    "pathname":""
                }, */
                "price": 0,
                // "eq": 0,
                "bind":""
            }
            return row
        }

        root.clear();
        let jdata = ({}), row = ({})
        let tmp = []
        let r=0;
        let crntItem = LibItem.dummyItem()

        if (bal.length < 2) return

        const acntBalance = LibAcnt.balBalance(db, bal)
        // dbg(JSON.stringify(acntBalance), "5r7")
        for (r=0; r < acntBalance.length/* && r < 10*/; ++r){
            crntItem = LibItem.getItemById(db, acntBalance[r].itemid)
            if (!isAllowed(crntItem, flt)) continue
            let row = acntBalance[r]
            row.item = crntItem
            row.bind = (order === "id"
                        ? acntBalance[r].balname
                        : crntItem.pathname
                        )
            const pr = LibPrice.sell(db, acntBalance[r].itemid)
            const prval = Number(pr.price)/Number(pr.qtty)
            row.price = prval
            // row.eq = prval * Number(jdata[i].total)
            tmp.push(row)
        }

        if (order === "id") {
            tmp.sort ((a,b) => { return (a.item.id < b.item.id ? -1 : 1)})
        } else if (order === "name") {
            tmp.sort ((a,b) => {
                                 const pathComp = a.item.pathname.localeCompare(b.item.pathname)
                                 if (pathComp !== 0) return pathComp
                                 else return a.item.itemchar.localeCompare(b.item.itemchar)})
        } else if (order === "cost") {
            tmp.sort ((a,b) => {
                                 const pathComp = a.item.pathname.localeCompare(b.item.pathname)
                                 if (pathComp !== 0) return pathComp
                                 else return a.eq < b.eq ? 1 : -1 })
        } else if (order === "datein") {
            tmp.sort ((a,b) => {
                                 const pathComp = a.item.pathname.localeCompare(b.item.pathname)
                                 if (pathComp !== 0) return pathComp
                                 else return a.intm < b.intm ? 1 : -1})
        } else if (order === "dateout") {
            tmp.sort ((a,b) => {
                                 const pathComp = a.item.pathname.localeCompare(b.item.pathname)
                                 if (pathComp !== 0) return pathComp
                                 else return a.outm < b.outm ? 1 : -1})
        }
        // tmp.forEach(v => {
        //                 dbg(JSON.stringify(v), "82k")
        //             })
        // let tmpager = []
        let tmpTotal = []

        let sect ="", tot =0;
        for ( r =0; r < tmp.length; ++r){
            if (sect === tmp[r].bind) { tot += Number(tmp[r].price * Number(tmp[r].total))
            } else {
                tmpTotal.push({"path":sect, "total": tot})
                sect = tmp[r].bind
                tot = Number(tmp[r].price * Number(tmp[r].total));
            }
        }
        tmpTotal.push({"path":sect, "total": tot})
        root.sectTotal = tmpTotal

        root.data = tmp

        populate()
    }

    function populate(page =1){
        root.clear();

        for (let offset = (Number(page) < 2 ? 0 : (Number(page)-1) * root.pageCapacity);
             offset < root.data.length && offset < Number(page) * root.pageCapacity;
             ++offset) {
            root.append(data[offset]);
            // dbg(JSON.stringify(data[offset]), "1rf5")
        }
    }

    function getTotal(id) {
        const sect = sectTotal.find( (v) => v.path === id );
        if (sect !== undefined) return sect.total
        return 0
    }


}
