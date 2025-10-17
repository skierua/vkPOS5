import QtQuick
import "../libREST.js" as REST
import "../lib.js" as Lib

ListModel {
    id: root

    signal vkEvent(string id, var param)


    function populate(dbDriver){
        clear();
        const cur = Lib.getCurrency(dbDriver)

        for (let r=0; r < cur.length; ++r){
            append({"curid":cur[r].curid, "qty":cur[r].qty, "curchar":cur[r].curchar, "curname":cur[r].curname,
                       "bid":"","ask":"","lbid":"","lask":"","lbidid":"","laskid":"", "dfltbid":"","dfltask":""})
        }
        populateLocalRates(dbDriver)
    }

    function loadWebRates(uri, query){
        REST.postRequest2(uri, query, (err,resp) => {
                             if (err === null){
                                 // console.log("#278 main "+JSON.stringify(resp))
                                 populateWebRates(resp)
                             } else {
                                vkEvent("err", "postReques: " + err.text)
                             }
        });
    }


    function populateWebRates(jdata){
        // console.log("#syw8 Rate data="+JSON.stringify(jdata));
        let i =0; let vbid = ""; let vask = "";
        let refresh = false;
        for (let r = 0; r<jdata.length; ++r) {
            for(i = 0; i < count && get(i).curid !== jdata[r].atclcode; ++i) {}

            if (i < count) {
                vbid = jdata[r].bid
                vask = jdata[r].ask

                if (jdata[r].rqty !== get(i).qty) {
                    vbid = String(Number(get(i).qty) * Number(vbid)/Number(jdata[r].rqty))
                    vask = String(Number(get(i).qty) * Number(vask)/Number(jdata[r].rqty))
                }
                setProperty(i,"bid",vbid)
                setProperty(i,"ask",vask)
                refresh |= (vbid !== get(i).lbid || vask !== get(i).lask)
            }

        }
        // saveWebAction.enabled = refresh
    }


    function populateLocalRates(dbDriver){
        const jdata = Lib.getRate(dbDriver)
        // console.log("#73yh Rate data="+JSON.stringify(jdata))
        let i =0; let vprice = "";
        for (let r =0; r<jdata.length; ++r) {
            for(i =0; i < count && get(i).curid !== jdata[r].curid; ++i) {}

            if (i < count) {
                // console.log("#753g Rate cur="+jscur[i].curchar+" lcurid="+jdata[r].curid+" pr/qty="+jdata[r].price+"/"+jdata[r].qty)
                vprice = jdata[r].price
                if (jdata[r].qty !== get(i).qty) {
                    vprice = String(Number(get(i).qty) * Number(jdata[r].price)/Number(jdata[r].qty))
                }
                if (jdata[r].ba === "1") {
                    setProperty(i,"lbid",vprice)
                    setProperty(i,"dfltbid",vprice)
                    setProperty(i,"lbidid",jdata[r].id)
                } else {
                    setProperty(i,"lask",vprice)
                    setProperty(i,"dfltask",vprice)
                    setProperty(i,"laskid",jdata[r].id)
                }
            }

        }
        // loadWebRates()
    }

    function updateLocalRates(dbDriver){
        let refreshLocal = false;
        // saveWebAction.enabled = false
        // update rates
        for(let i =0; i < count; ++i) {
            if ( Math.abs(Number(get(i).bid) - Number(get(i).lbid)) > zero ){
                refreshLocal |= true
                Lib.updRate(dbDriver, get(i).bid === "" ? "0" : get(i).bid, get(i).qty, get(i).lbidid, get(i).curid, "1")
            }
            if ( Math.abs(Number(get(i).ask) - Number(get(i).lask)) > zero ){
                refreshLocal |= true
                Lib.updRate(dbDriver, get(i).ask === "" ? "0" : get(i).ask, get(i).qty, get(i).laskid, get(i).curid, "-1")
                // vkEvent("rate.updLocal", { "id":get(i).laskid, "price":get(i).ask===""?"0":get(i).ask, "qty":jscur[i].qty, "curid":jscur[i].curid, "ba":"-1" })
            }
        }
        if (refreshLocal) populateLocalRates(dbDriver)
    }



}

/*
  currencies structure
    [{
        "curid":"840",
        "curchar":"USD",
        "curname":"долар США",
        "qty":"1",
        "so":"10"
    }]

  localRates structure
    [{
        "id":"3",
        "curid":"978",
        "ba":"1",
        "qty":"1",
        "price":"48.5"
    }]

  loadWebRates structure
    [{
        "atclcode":"978",
        "rqty":"1","bid":"47.16",
        "ask":"47.63",
        "bidtm":"2025-07-17T18:22:28.622Z",
        "asktm":"2025-07-17T18:22:28.622Z",
        "shop":"CITY",
        "chid":"EUR",
        "name":"ЄВРО",
        "cqty":"1",
        "sortorder":"15",
        "prc":""
    }]

  */
