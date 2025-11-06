import QtQuick
import "../lib.js" as Lib

ListModel {
    id: root
    property var data

    function dbg(str, code ="") {
        console.log( String("%1[ModelDrawer] %2").arg(code).arg(str));
    }

    function load(db, bal, mask =0, reverse =false) {
        // dbg("loaded bal="+bal+" cur="+mask, "#sh48")
        let jdata = Lib.getBalance(db, bal, mask, reverse)
/*        jdata.sort((a,b) => {
                       if (a.mask < b.mask) return -1;
                       else if (a.mask > b.mask) return 1;
                       else if (a.itemnote < b.itemnote) return -1
                       else if (a.itemnote > b.itemnote) return 1
                       return 1
                   }
                       ) */
        // dbg("")
        // for (let i=0; i < root.data.length && i < 10; ++i){
        //     console.log(JSON.stringify(root.data[i]))
        // }
        root.data = jdata
        filterData()
    }

    function isAllowed(row, flt){
        return (root.data[row].key === flt || root.data[row].clid === flt
                || ~(root.data[row].name.toLowerCase()).indexOf(flt.toLowerCase())
                || ~(root.data[row].subname.toLowerCase()).indexOf(flt.toLowerCase())
                || ~(root.data[row].clchar.toLowerCase()).indexOf(flt.toLowerCase())
                || ~(root.data[row].acntno.toLowerCase()).indexOf(flt.toLowerCase())
                || ~(root.data[row].aname.toLowerCase()).indexOf(flt.toLowerCase())
                || ~(root.data[row].scan).indexOf(flt));
    }

    function filterData(flt =""){

        for ( let r =0; r < data.length; ++r){
            if (flt === undefined || flt === "" || isAllowed(r, flt) ){
                data[r].flt = true;
            } else  { data[r].flt = false; }
        }

        populate()
    }

    function populate(){
        root.clear();

        for ( let ofs =0; ofs < data.length; ++ofs){

            if (!data[ofs].flt) continue;

            root.append(data[ofs])
        }
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
