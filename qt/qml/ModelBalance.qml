import QtQuick

import "js/sqlItem.js" as LibItem
import "js/sqlAcnt.js" as LibAcnt
import "js/sqlPrice.js" as LibPrice


ListModel {
    id: root
    property var data
    property int pageCapacity: 40
    property list<int> pager: []
    property var sectTotal: []         // sum for sections

    // function isLastPage(){
    //     return crntPage * pageCapacity >=
    // }

    function load(db, bal = "300", mode = "code", order = "asc") {
        // bal = "350"; // for testing
        // return
        root.clear();
        let jdata = ({})
        let i=0;

        if (bal.length > 1 && (bal.substring(0,2) === "35")){
            jdata = LibAcnt.dbTradeBalance(db,
                                          String("substr(acntno,1,%1)='%2'").arg(bal.length).arg(bal))
            for (i=0; i < jdata.length/* && i < 10*/; ++i){
                jdata[i].item = LibItem.getItemById(db, jdata[i].itemid)
                jdata[i].price = Number(jdata[i].bscprice)
                jdata[i].eq = Number(jdata[i].eqtotal)
                if (mode === "code_asc") jdata[i].bind = jdata[i].balname
                else jdata[i].bind = jdata[i].item.pathname.substr(jdata[i].item.pathname.lastIndexOf("/") +1)
            }
        } else {
            let reverse = true
            if (bal.length > 1
                    && (bal.substring(0,2) === "30" || bal.substring(0,2) === "31")) reverse = false
            jdata = LibAcnt.dbBalance(db,
                                          String("substr(acntno,1,%1)='%2'").arg(bal.length).arg(bal),
                                          reverse)
            let pr = ({})
            let prval = 0
            let sect = ""
            for (i=0; i < jdata.length/* && i < 10*/; ++i){
                jdata[i].item = LibItem.getItemById(db, jdata[i].itemid)
                pr = LibPrice.sell(db, jdata[i].itemid)
                prval = Number(pr.price)/Number(pr.qtty)
                jdata[i].price = prval
                jdata[i].eq = prval * Number(jdata[i].total)
                // console.log(JSON.stringify(root.data[i]))
                if (mode === "code_asc") jdata[i].bind = jdata[i].balname
                else jdata[i].bind = jdata[i].item.pathname.substr(jdata[i].item.pathname.lastIndexOf("/") +1)
            }
        }
        if (mode === "code_asc") {
            jdata.sort ((a,b) => { return (a.item.id < b.item.id ? -1 : 1)})
        } else if (mode === "name_asc") {
            jdata.sort ((a,b) => {
                                 const pathComp = a.item.pathname.localeCompare(b.item.pathname)
                                 if (pathComp !== 0) return pathComp
                                 else return a.item.itemchar.localeCompare(b.item.itemchar)})
        } else if (mode === "name_desc") {
            jdata.sort ((a,b) => {
                                 const pathComp = a.item.pathname.localeCompare(b.item.pathname)
                                 if (pathComp !== 0) return pathComp
                                 else return 0 - a.item.itemchar.localeCompare(b.item.itemchar)})
        } else if (mode === "remind_asc") {
            jdata.sort ((a,b) => {
                                 const pathComp = a.item.pathname.localeCompare(b.item.pathname)
                                 if (pathComp !== 0) return pathComp
                                 else return a.eq < b.eq ? -1 : 1 })
        } else if (mode === "remind_desc") {
            jdata.sort ((a,b) => {
                                 const pathComp = a.item.pathname.localeCompare(b.item.pathname)
                                 if (pathComp !== 0) return pathComp
                                 else return a.eq < b.eq ? 1 : -1 })
        } else if (mode === "income_asc") {
            jdata.sort ((a,b) => {
                                 const pathComp = a.item.pathname.localeCompare(b.item.pathname)
                                 if (pathComp !== 0) return pathComp
                                 else return a.intm < b.intm ? -1 : 1 })
        } else if (mode === "income_desc") {
            jdata.sort ((a,b) => {
                                 const pathComp = a.item.pathname.localeCompare(b.item.pathname)
                                 if (pathComp !== 0) return pathComp
                                 else return a.intm < b.intm ? 1 : -1})
        } else if (mode === "outcome_asc") {
            jdata.sort ((a,b) => {
                                 const pathComp = a.item.pathname.localeCompare(b.item.pathname)
                                 if (pathComp !== 0) return pathComp
                                 else return a.outm < b.outm ? -1 : 1 })
        } else if (mode === "outcome_desc") {
            jdata.sort ((a,b) => {
                                 const pathComp = a.item.pathname.localeCompare(b.item.pathname)
                                 if (pathComp !== 0) return pathComp
                                 else return a.outm < b.outm ? 1 : -1})
        }
        root.data = jdata
        filterData()
    }

    function isAllowed(row, flt){
        return (root.data[row].key === flt
                || root.data[row].itemid === flt
                || root.data[row].clid === flt
                || ~(root.data[row].item.scancode).indexOf(flt)
                || ~(root.data[row].item.itemchar.toLowerCase()).indexOf(flt.toLowerCase())
                || ~(root.data[row].item.itemname.toLowerCase()).indexOf(flt.toLowerCase())
                // || ~(root.data[row].clchar.toLowerCase()).indexOf(flt.toLowerCase())
                || ~(root.data[row].item.itemnote.toLowerCase()).indexOf(flt.toLowerCase())
                // || ~(root.data[row].aname.toLowerCase()).indexOf(flt.toLowerCase())
                );
    }

    function filterData(flt =""){
        let tmpager = []
        let tmpTotal = []

        let sect ="", tot =0;
        for ( let r =0, f =0; r < root.data.length; ++r){
            if (flt === undefined || flt === "" || isAllowed(r, flt) ){
                // console.log("Balance.qml/filterData #w42 bind=" + data[r].bind +"\tsect=" +sect)
                if (sect === data[r].bind) { tot += Number(data[r].eq)
                } else {
                    tmpTotal.push({"path":sect, "total": tot})
                    sect = data[r].bind
                    tot = data[r].eq;
                }

                data[r].flt = true;
                ++f
                if (!(f % root.pageCapacity)) tmpager.push(r);
            } else  { data[r].flt = false; }
        }
        tmpTotal.push({"path":sect, "total": tot})
        root.pager = tmpager
        root.sectTotal = tmpTotal
        // console.log("Balance.qml/filterData #443 len=" + sectTotal.length)
        // root.sectTotal.forEach(v => console.log(String("[%1]\t%2").arg(v.path).arg(v.total)))
        // for (let i=0; i < pager.length && i < 10; ++i)
        //     console.log("Balance/populate #721 page=" + pager[i])
        // console.log("Balance.qml/filterData #q5fg")
        // for(let ii =0; ii < data.length && ii < 25; ++ii) {
        //     console.log(data[ii].id + "\t" + data[ii].acntno + "\t" + data[ii].itemid + "\t" + data[ii].total  + "\t" + data[ii].item.itemchar)
        // }
        // for(let ii =data.length-1; ii >= 0 && ii > data.length-25; --ii) {
        //     console.log(data[ii].id + "\t" + data[ii].acntno + "\t" + data[ii].itemid + "\t" + data[ii].total  + "\t" + data[ii].item.itemchar)
        // }
        populate()
    }

    function populate(page =1){
        root.clear();
        for ( let offset = (Number(page) < 2 ? 0 : root.pager[page -2] +1);
             offset < (page > pager.length ? root.data.length : root.pager[page -1] +1);
             ++offset){

            if (!root.data[offset].flt) continue;

            root.append(data[offset]);
        }
    }

    function getTotal(id) {
        const sect = sectTotal.find( (v) => v.path === id );
        if (sect !== undefined) return sect.total
        return 0
    }


}
