import QtQuick
import QtQuick.Controls.Fusion
import QtQuick.Layouts

Window {
    id: root
    width: 200
    height: 400
    property real zero: 0.0000001
    property var jscur
    onJscurChanged: {
        // console.log("#qwu7 RATE "+JSON.stringify(jscur))
        vw.model.clear();
        for (let r=0; r < jscur.length; ++r){
            vw.model.append({"rowid":r, "qty":jscur[r].qty, "bid":"","ask":"","lbid":"","lask":"","lbidid":"","laskid":"", "dfltbid":"","dfltask":""})
        }
        getLocalAction.trigger()
    }

/*    property var jsdata
    onJsdataChanged: {
        // console.log("#47hn Rate jsdata"+JSON.stringify(jsdata))
        let r=0,i =0
        for (r=0; r < jsdata.length; ++r){
            if (jsdata[r].rqty === "") { continue; }
            if (jsdata[r].rqty !== jsdata.qty) {
                jsdata[r].bid = String(Number(jsdata[r].bid)*Number(jsdata[r].qty)/Number(jsdata[r].rqty))
                jsdata[r].ask = String(Number(jsdata[r].ask)*Number(jsdata[r].qty)/Number(jsdata[r].rqty))
            }
        }
        for(r=0; r<root.jsdata.length; ++r ){
            for(i=0; i<vw.model.count && vw.model.get(i).curid !== jsdata[r].curid; ++i) {}
            if (i === vw.model.count) {
                vw.model.append({"curid":jsdata[r].curid,"curchar":jsdata[r].curchar,"curname":jsdata[r].curname,"qty":jsdata[r].qty,
                                "bid":jsdata[r].bid,"ask":jsdata[r].ask,"lbid":"","lask":"","lbidid":"","laskid":""})
            } else {
                vw.model.setProperty(i, "qty", jsdata[r].qty)
                vw.model.setProperty(i, "bid", jsdata[r].bid)
                vw.model.setProperty(i, "ask", jsdata[r].ask)
            }

        }
        vw.webChanged = true
        // vw.web_populate()
    }
*/

    signal vkEvent(string id, var param)


    Component {
        id: dlg
        FocusScope {
            id: root
            width: root.ListView.view.width //childrenRect.width;
            height: 28;
//            color: (index==root.ListView.view.currentIndex?"PaleGreen":(index%2 == 0 ?  "white" : 'HoneyDew'))
            // color: (index%2 == 0 ?  "whitesmoke" : 'white')
//            color: (index%2 == 0 ?  "PaleGreen" : 'Aquamarine')
//            color: (index%2 == 0 ?  Qt.darker('white',1.03) : 'white')
                MouseArea{
                    anchors.fill: parent
                    onClicked: { root.ListView.view.currentIndex=index; }
                }

            Row{
                anchors.fill: parent
                Label{          // bid
                    width: parent.width*0.35;
                    height: parent.height
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    text: Number(lbid)!==0 ? Number(lbid).toFixed(Number(lbid)<10?3:2) : "" //(bid==''||Number(bid)===0)?'':bid+"/"+lbid
                    font.bold: Math.abs(Number(bid)-Number(lbid))>zero
/*                    MouseArea{
                        anchors.fill: parent
                        hoverEnabled :true
                        onClicked: { bidedit.visible = true; bidedit.text=lbid; bidedit.forceActiveFocus() }
                    }
                    TextField{
                        id: bidedit
                        anchors.fill: parent
                        visible: false
                        selectByMouse: true
                        validator: DoubleValidator {bottom: 0; decimals: 4; notation: "StandardNotation"; locale: "en_US" }
                        onActiveFocusChanged: if (activeFocus) {selectAll()} else {visible = false}
                        onAccepted: {
                            if ((Number(text)===0) || (Math.abs((Number(text)-Number(lbid))/Number(lbid)) < 0.04)) { lbid = text
                            } else { text = lbid } // error
                            // root.forceActiveFocus()
                        }
                    }*/
                }
                Label{      // currency name
                    width: parent.width*0.3;height:parent.height;
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    text:(qty==='1'?'':(qty+' '))+jscur[index].curchar
                    font.bold: (Math.abs(Number(bid)-Number(lbid))>zero) || (Math.abs(Number(ask)-Number(lask))>zero)
                    MouseArea{
                        anchors.fill: parent
                        hoverEnabled :true
                        ToolTip{
                            id: rateToolTip
                            width: 150
                            visible: false
                            delay: 1000
                            timeout: 5000
                            text: 'код: '+jscur[index].curid+'\n'+jscur[index].curname+'\n'+'к-сть: '+ qty
                                + String("\nсайт: %1/%2").arg(bid===""?"--":bid).arg(ask===""?"--":ask)
                                + String("\nпопередні: %1/%2").arg(dfltbid===""?"--":dfltbid).arg(dfltask===""?"--":dfltask)
                        }
                        onEntered: {rateToolTip.visible = true}
                        onExited: rateToolTip.visible = false
                        onDoubleClicked: { root.ListView.view.newDoc(index); }
                    }
                }
                Label{      // ask
                    width: parent.width*0.35;
                    height: parent.height
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    text: Number(lask)!==0 ? Number(lask).toFixed(Number(lask)<10?3:2) : ""
                    font.bold: Math.abs(Number(ask)-Number(lask))>zero
                    font.underline: lask !== dfltask
/*                    MouseArea{
                        anchors.fill: parent
                        hoverEnabled :true
                        onClicked: { askedit.visible = true; askedit.text=lask; askedit.forceActiveFocus() }
                    }
                    TextField{
                        id: askedit
                        anchors.fill: parent
                        visible: false
                        selectByMouse: true
                        validator: DoubleValidator {bottom: 0; decimals: 4; notation: "StandardNotation"; locale: "en_US" }
                        onActiveFocusChanged: if (activeFocus) {selectAll()} else {visible = false}
                        onAccepted: {
                            if ((Number(text)===0) || (Math.abs((Number(text)-Number(lask))/Number(lask)) < 0.04)) { lask = text
                            } else { text = lask } // error
                            // root.forceActiveFocus()
                        }
                    } */
                }
            }
        }
    }

    Action {
        id: reloadAction
        text: "🔄"
        onTriggered: getLocalAction.trigger()
    }
    Action{
        id: getLocalAction
        text: "Локальні курси"
        onTriggered: {vkEvent('rate.getLocal', "");}
    }

    Action{
        id: getWebAction
        text: "Курси з сайту"
        onTriggered: {vkEvent('rate.getWeb', "");}
    }

    Action{
        id: saveWebAction
        enabled: false
        text: "Встановити з сайту"
        onTriggered: vw.updLocal();
    }

    Rectangle{
        anchors{fill: parent; margins:5;}
        ColumnLayout{
            anchors{fill: parent; }
            ListView{
                id: vw
                // property bool webChanged: false
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: ListModel{}
                header:
                    Row{
                        width: vw.width
                        height: 20
                        Label{
                            width: parent.width*0.35-parent.spacing
                            height: parent.height
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignHCenter
                            color: 'dimgrey'
                            text: 'СКУП'
                        }
                        Label{
                            width: parent.width*0.30;
                            height: parent.height
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignHCenter
                            color: 'dimgrey'
                            text: 'ВАЛ'
                        }
                        Label{
                            width: parent.width*0.35-parent.spacing
                            height: parent.height
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignHCenter
                            color: 'dimgrey'
                            text: 'ПРОД'
                        }

                    }

                delegate: dlg

                onCurrentIndexChanged: console.log("#527g index="+currentIndex)

                function updLocal(){
                    // console.log("#74hb data="+JSON.stringify(jslocal))
                    let refreshLocal = false;
                    saveWebAction.enabled = false
                    // update rates
                    for(let i=0; i<model.count; ++i) {
                        if ( Math.abs(Number(model.get(i).bid) - Number(model.get(i).lbid)) > zero ){
                            refreshLocal = true
                            // console.log("#29js Rate cur="+model.get(i).curchar + " w/l"
                            //             +" qty="+model.get(i).qty + " bid="+model.get(i).bid + "/" + model.get(i).lbid)
                            vkEvent("rate.updLocal", { "id":model.get(i).lbidid, "price":model.get(i).bid===""?"0":model.get(i).bid, "qty":jscur[i].qty, "curid":jscur[i].curid, "ba":"1" })
                        }
                        if ( Math.abs(Number(model.get(i).ask) - Number(model.get(i).lask)) > zero ){
                            refreshLocal = true
                            vkEvent("rate.updLocal", { "id":model.get(i).laskid, "price":model.get(i).ask===""?"0":model.get(i).ask, "qty":jscur[i].qty, "curid":jscur[i].curid, "ba":"-1" })
                        }
                    }
                    if (refreshLocal){ vkEvent("rate.getLocal", ""); }
                }

                function newDoc(vi){ vkEvent("rate.newDocum", jscur[vi].curid); }
            }

            Button{
                id: loadBtn
                Layout.fillWidth: true
                action: getWebAction
            }

            Button{
                id: saveBtn
                Layout.fillWidth: true
                action: saveWebAction
            }

        }

    }

    function setLocal(jdata){
        // console.log("#73yh Rate data="+JSON.stringify(jdata))
        let i =0; let vprice = "";
        for (let r =0; r<jdata.length; ++r) {
            for(i=0; i<vw.model.count && jscur[i].curid !== jdata[r].curid; ++i) {}

            if (i < vw.model.count) {
                // console.log("#753g Rate cur="+jscur[i].curchar+" lcurid="+jdata[r].curid+" pr/qty="+jdata[r].price+"/"+jdata[r].qty)
                vprice = jdata[r].price
                if (jdata[r].qty !== jscur[i].qty) {
                    vprice = String(Number(jscur[i].qty) * Number(jdata[r].price)/Number(jdata[r].qty))
                }
                if (jdata[r].ba === "1") {
                    vw.model.setProperty(i,"lbid",vprice)
                    vw.model.setProperty(i,"dfltbid",vprice)
                    vw.model.setProperty(i,"lbidid",jdata[r].id)
                } else {
                    vw.model.setProperty(i,"lask",vprice)
                    vw.model.setProperty(i,"dfltask",vprice)
                    vw.model.setProperty(i,"laskid",jdata[r].id)
                }
            }

        }
        getWebAction.triggered()
    }

    function setWeb(jdata){
        // console.log("#syw8 Rate data="+JSON.stringify(jdata));
        let i =0; let vbid = ""; let vask = "";
        let refresh = false;
        for (let r =0; r<jdata.length; ++r) {
            for(i=0; i<vw.model.count && jscur[i].curid !== jdata[r].atclcode; ++i) {}

            if (i < vw.model.count) {
                // console.log("#753g Rate cur="+jscur[i].curchar+" lcurid="+jdata[r].curid+" pr/qty="+jdata[r].price+"/"+jdata[r].qty)
                vbid = jdata[r].bid
                vask = jdata[r].ask
                // if (jdata[r].qty !== jdata[r].rqty) {
                //     vbid = String(Number(jdata[r].qty) * Number(jdata[r].bid)/Number(jdata[r].rqty))
                //     vask = String(Number(jdata[r].qty) * Number(jdata[r].ask)/Number(jdata[r].rqty))
                // }

                if (jdata[r].rqty !== jscur[i].qty) {
                    vbid = String(Number(jscur[i].qty) * Number(vbid)/Number(jdata[r].rqty))
                    vask = String(Number(jscur[i].qty) * Number(vask)/Number(jdata[r].rqty))
                }
                vw.model.setProperty(i,"bid",vbid)
                vw.model.setProperty(i,"ask",vask)
                refresh |= (vbid !== vw.model.get(i).lbid || vask !== vw.model.get(i).lask)
            }

        }
        saveWebAction.enabled = refresh
    }

}
