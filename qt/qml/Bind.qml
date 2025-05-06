import QtQuick
import QtQuick.Controls
// import QtQuick.Controls.Fusion
import QtQuick.Layouts


Item {
    id: root
//    width: 480
//    height: 480
    property string title: "Чек"
    property string codeid: "bind"
/*    property list<Action> vkMenuActions: [
        test1Action,
        test2Action
    ]*/
/*    property list<MenuItem> vkMenuItems: [
        MenuItem { action: test1Action; },
        MenuItem { action: test2Action; }
    ]*/
    property Menu vkContentMenu: Menu{
        id: vkContentMenu_id
        MenuItem { action: uahToAcntAction; }
        MenuItem { action: curToAcntAction; }
        MenuSeparator { padding: 5; }
        MenuItem { action: drawerAction; }
        MenuSeparator { padding: 5; }
        MenuItem { action: checkAction; }
        MenuItem { action: factureAction; }
    }

    // property var fnTranBind      // object
    property var fnCreateDcm  // vaid, {param}

    property string printDcm: ""
    property int dfltAmnt: 1
    property var dfltClient
    // onDfltClientChanged: crntClient = dfltClient
    property var dfltAcnt
    // onDfltAcntChanged: crntAcnt = dfltAcnt
    property bool autoPrint: false
    property bool autoTax: false
//    property bool onlyLastPrice:false

    property alias dcms: bindView.model
    property real z0: 0.0000001

//    property var domesticCrn    //: {"id":"","name":"UAH","fullname":"українська гривня","mask":"1","qty":"1","uktzed":"","taxchar":"","taxprc":"","unitid":"","prec":"2","unitchar":"","unitname":"","unitcode":"","term":"0"}
//        onDomesticCrnChanged: if (domesticCrn !== undefined){ domesticCrn.id = ""; }


    property string parentCode: "check"
    property string crntCode: "trade:sell"
    property bool crntPrint
    property var cashAcnt   //  {"acntno":"3000","clid":"","note":"","mask":"1","trade":"0","name":"Залишок"}
    property var crntAcnt: { "acntno":"", "clid":"", "clname":"", "note":"", "mask":"", "clnote":"", "trade":"", "name":"" };
    onCrntAcntChanged: startNewRow()
    property string crntAmnt
    property var crntClient: {'id':'', 'name':'', "bonusTotal": 0, "bonusAcnt":''};
    onCrntClientChanged: startNewRow()

//    property var crntAtcl
//    property var crntPrice

    property string crntDsc: ''
    property string crntBns: ''
    property string crntRate: '1'

    onVisibleChanged: startNewRow()


//    property string dfltPrintDcm: ''
//    property bool doPrint: false


    signal vkEvent(string id, var param)

    states: [
            State {
                name: "facture"
                PropertyChanges { target: root; title: "Фактура" }
                PropertyChanges { target: root; parentCode: "facture" }
                PropertyChanges { target: root; crntCode: "trade:buy" }
//                PropertyChanges { target: root; onlyLastPrice: true }
                PropertyChanges { target: fldRate; visible: true }
            },
        State {
            name: "incas"
            PropertyChanges { target: root; title: "Інкасація" }
            // PropertyChanges { target: root; parentCode: "facture" }
            PropertyChanges { target: root; crntCode: "trade:inner" }
//                PropertyChanges { target: root; onlyLastPrice: true }
            PropertyChanges { target: fldDsc; visible: false }
            PropertyChanges { target: fldBns; visible: false }
            PropertyChanges { target: viewArea; color: "honeydew" }
        },
            State {
                name: "taxcheck"
                PropertyChanges { target: root; title: "Фіскальний чек" }
                PropertyChanges { target: root; autoTax: true }
                PropertyChanges { target: viewArea; color: "beige" }
        },
            State {
                name: "kantor"
                // PropertyChanges { target: root; title: "Фіскальний чек" }
                // PropertyChanges { target: root; autoTax: true }
                // PropertyChanges { target: viewArea; color: "beige" }
            }
        ]

    Action {
        id: uahToAcntAction
        enabled: Number(crntAcnt.mask)&1 == 1
        text: "ГРН на рахунок"
        onTriggered: {
            let vj = articleTotal(1)
            // console.log("#38d tot="+JSON.stringify(vj))
            for (let r=0; r<vj.length; ++r){
                // console.log("#83h id="+vj[r].id + " amnt="+ String(0-vj[r].amnt))
                insert(fnCreateDcm(vj[r].id, { "amnt": String(0-vj[r].amnt)} ))
            }
        }
    }

    Action {
        id: curToAcntAction
        enabled: Number(crntAcnt.mask)&3 == 3
        text: "ГРН+ВАЛЮТА на рахунок"
        onTriggered: {
            let r = 0;
            let vj = articleTotal(3)
            // console.log("#38d tot="+JSON.stringify(vj))
            let vdcm = []
            for (r=0; r<vj.length; ++r){
                // console.log("#83h r="+r+" id="+vj[r].id + " amnt="+ String(0-vj[r].amnt))
                vdcm.push( fnCreateDcm(vj[r].id, { "amnt": String(0-vj[r].amnt)} ) )
            }
            for (r=0; r<vdcm.length; ++r){ insert(vdcm[r]); }
        }
    }

    Action {
        id: drawerAction
        text: "Залишки"
        onTriggered: {vkEvent("drawer", "")}
    }


    Action {
        id: checkAction
        enabled: !bindView.model.count
        text: "Чек"
        onTriggered: { root.state = '' }
    }

    Action {
        id: factureAction
        enabled: !bindView.model.count
        text: "Фактура"
        onTriggered: { root.state = 'facture' }
    }

    function startNewRow() {
        bindView.recalculate2()
        crntAmnt = dfltAmnt
        fldMainInput.text = ''
        fldMainInput.forceActiveFocus()
    }

    function startBind() {
        bindView.model.clear()
        crntClient = dfltClient
//        crntAmnt = dfltAmnt
        crntAcnt = dfltAcnt
        crntPrint = autoPrint
        crntRate = '1'
        crntDsc = ""
        crntBns = ""
        // crntAmnt = dfltAmnt
        // fldMainInput.text = ''
        // fldMainInput.forceActiveFocus()
        startNewRow()
    }

    function makeBind() {
        var vj = {"id":"dcmbind",
                "dcm":parentCode,"dbt":cashAcnt.acntno,"cdt":"",
                "amnt":bindView.pmntTotal.toFixed(2),"eq":bindView.eqTotal.toFixed(2),"dsc":bindView.dscMoney.toFixed(2),"bns":bindView.bnsMoney.toFixed(2),
                "note":"", "clnt":crntClient.id,
                "tm":Qt.formatDateTime(new Date(), "yyyy-MM-dd hh:mm:ss"),
                "cshr":"",
                "dcms":[]}
        let m = bindView.model
        for (var r =0; r < m.count; ++r) {
            vj.dcms[r] = {"dcm":m.get(r).dcode,"dbt":cashAcnt.acntno,"cdt":m.get(r).dacnt.acntno,"crn":m.get(r).darticle.id,
                "amnt":(m.get(r).dsign * Number(m.get(r).damnt)).toFixed(m.get(r).darticle.prec),"eq":(m.get(r).dsign * Number(m.get(r).damnt)*m.get(r).dprice).toFixed(2),"dsc":(-1 * m.get(r).dsign * Number(m.get(r).damnt)*m.get(r).dprice*m.get(r).ddsc).toFixed(2),"bns":(-1 * m.get(r).dsign * Number(m.get(r).damnt)*m.get(r).dprice*m.get(r).dbns).toFixed(2),
                "note":m.get(r).dnote,"retfor":m.get(r).retfor}
        }
        return vj
    }

/*    function tran(callback) {
        var vj = {"id":"dcmbind",
                "dcm":parentCode,"dbt":cashAcnt.acntno,"cdt":"",
                "amnt":bindView.pmntTotal.toFixed(2),"eq":bindView.eqTotal.toFixed(2),"dsc":bindView.dscMoney.toFixed(2),"bns":bindView.bnsMoney.toFixed(2),
                "note":"", "clnt":crntClient.id,
                "tm":Qt.formatDateTime(new Date(), "yyyy-MM-dd hh:mm:ss"),
                "cshr":"",
                "dcms":[]}
        let m = bindView.model
        for (var r =0; r < m.count; ++r) {
            vj.dcms[r] = {"dcm":m.get(r).dcode,"dbt":cashAcnt.acntno,"cdt":m.get(r).dacnt.acntno,"crn":m.get(r).darticle.id,
                "amnt":(m.get(r).dsign * Number(m.get(r).damnt)).toFixed(m.get(r).darticle.prec),"eq":(m.get(r).dsign * Number(m.get(r).damnt)*m.get(r).dprice).toFixed(2),"dsc":(-1 * m.get(r).dsign * Number(m.get(r).damnt)*m.get(r).dprice*m.get(r).ddsc).toFixed(2),"bns":(-1 * m.get(r).dsign * Number(m.get(r).damnt)*m.get(r).dprice*m.get(r).dbns).toFixed(2),
                "note":m.get(r).dnote,"retfor":m.get(r).retfor}
        }
        if (callback(vj,crntPrint ? printDcm : "",autoTax)){
            startBind()
        }
    } */

    function articleTotal(vmask){
        if (vmask === undefined || vmask === '') { vmask = 1; }
        let vj = []
        if ((vmask&1)==1){
            if (Number(bindView.pmntTotal) !== 0) { vj.push({ "id": "", "name":"ГРН", "amnt": Number(bindView.pmntTotal)});}
        }
        if ((vmask&2)==2) {
            for (let r =0; r < totalCurrencyView.model.count; ++r){
                if (totalCurrencyView.model.get(r).amnt !== 0) { vj.push(totalCurrencyView.model.get(r)); }
            }
        }
        return vj
    }

    function insert(vdcm, vrow){
        // console.log("Bind.qml #928 artcl=" + JSON.stringify(vdcm.atcl))
        if (!vdcm){
            vkEvent('dialog', "Document is not alowed for this bind.");
        }
        let ok = true
        if (root.state === "facture") {
            ok &= ((Number(vdcm.atcl.mask) === 4 && vdcm.code === "trade:buy")
                   || (Number(vdcm.atcl.mask) === 2) || (Number(vdcm.atcl.mask) === 1))
        } else if (root.state === "taxcheck"){
            ok &= (Number(vdcm.atcl.mask) === 4 && vdcm.code === "trade:sell" && Number(vdcm.amnt) < 0)
        }
        if (ok) {
            vrow = vrow || 0;
            bindView.model.insert(vrow,
                {
                    "dsign":Number(vdcm.amnt) < 0 ? -1 : 1,
                    "dcode": vdcm.code,
                    "darticle": vdcm.atcl,
                    "dacnt": vdcm.acnt,
                    "damnt": String(Math.abs(Number(vdcm.amnt))),  //String(crntAmnt),
                    "dsubName":"#"+vdcm.atcl.id + (Number(vdcm.acnt.trade) === 0 ? (" ["+vdcm.acnt.acntno+"/"+vdcm.acnt.note+"]") : "") + vdcm.tag,
                    "dnote": vdcm.atcl.name + (Number(vdcm.acnt.trade) === 0 ? (" ["+vdcm.acnt.clname+"/"+vdcm.acnt.note+"]") : "") + vdcm.tag,
                    "dprice":vdcm.price,
                    "ddsc": Number(vdcm.atcl.mask)===4 ? (vdcm.dsc < z0 ? Number(crntDsc) : vdcm.dsc) : 0,
                    "dbns": Number(vdcm.atcl.mask)===4 ? (vdcm.bns < z0 ? Number(crntBns) : vdcm.bns) : 0,
                    "dpratt": Number(vdcm.atcl.mask)===4 ? vdcm.pratt : (vdcm.pratt & 1),
                    "drate":crntRate,
                    "retfor":vdcm.retfor
                }
            )
            bindView.currentIndex = vrow
            // console.log("#84yj bind vr="+JSON.stringify(bindView.model.get(vrow)))
            bindView.forceActiveFocus()
        } else {    // error
            // eDialog("Document is not alowed for this bind.",'error')
            vkEvent('dialog', "Document is not alowed for this bind.");
        }

    }

    Component {
        id: dlg1
        FocusScope{
            id: root
            property string test: 'for testing'
            width: childrenRect.width;
//            width: root.ListView.view.width;
            height: 40  //childrenRect.height;
            RowLayout{
                id: layout
                width: root.ListView.view.width
                clip: true
                spacing: 2
                Label{
                    font{pointSize: 30; bold:true;}
                    visible: Number(dacnt.trade) && dprice === 0
                    color: "tomato"
                    text: " ! "

                }

                Label{
                    id: fldSgn
                    property int value : (dsign < 0 ? -1 : 1)
                    Layout.preferredWidth: 30   //parent.height
                    Layout.preferredHeight: 40  //parent.height
                    font.pointSize: 30
                    horizontalAlignment: Text.AlignHCenter
                    text: dsign < 0 ? '-' : '+'
                }


                Item{   // note
                    Layout.fillWidth: true
                    Layout.preferredHeight: parent.height
                    ColumnLayout{
                        anchors.fill: parent
    //                    Layout.preferredWidth: 120
                        spacing: 0
                        clip: true
                        Label{
                            text: dnote
                            font.pointSize: 12
                        }
                        Label{
                            text: dsubName
    //                        elide: Label.ElideRight
                            color: 'dimgray'
                            font.pointSize: 10
                        }
                    }
                    MouseArea{
//                        width: parent.width; height: parent.height
                        anchors.fill: parent
                        enabled: Number(dacnt.trade) === 0
                        onClicked: {fldNoteEdit.visible = true; fldNoteEdit.forceActiveFocus();}
                    }

                    TextField{
                        id: fldNoteEdit
                        anchors.fill: parent
                        visible: false
                        selectByMouse: true
//                        validator: DoubleValidator {bottom: 0; decimals: 6; notation: "StandardNotation"; locale: "en_US" }
                        onActiveFocusChanged: if (activeFocus) {selectAll()} else {visible = false}
                        text: dnote
                        onAccepted: {
                            text = text.replace(/\\/g,"/")
                            dnote = text
                            root.ListView.view.restart()
//                            startNewRow()
                        }
                    }
                }

                Item {  // amnt & rate
//                    Layout.preferredWidth: 100
                    Layout.minimumWidth: 200
                    Layout.fillHeight: true
//                    clip: true

                    ColumnLayout{
                        anchors.fill: parent
                        spacing: 0
                        RowLayout{
                            Label{
                                id: fldAmnt
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                text: Math.abs(Number(damnt)).toLocaleString(Qt.locale(),'f',Number(darticle.prec))
                                font.pointSize: 14
                                clip: true
                                elide: Text.ElideLeft
                                MouseArea{
                                    anchors.fill: parent
                                    onClicked: {fldAmntEdit.visible = true; fldAmntEdit.forceActiveFocus();}
                                }
                            }
                            Label{
                                id: fldPrice
                                Layout.fillWidth: true
                                visible: Number(dacnt.trade)!==0
                                font.pointSize: 12
                                horizontalAlignment: Text.AlignHCenter
//                                text: dprice
                                text: (Number(dprice)*Number(darticle.qty)/drate).toFixed((Number(darticle.mask)&2)==2 ? 3 : 2)
                                      + (Number(darticle.qty)===1?'':('/'+darticle.qty))
//                                color: 'dimgray'
                                MouseArea{
                                    anchors.fill: parent
                                    enabled: (dpratt&1)===1
                                    onClicked: {fldPriceEdit.visible = true;
                                            fldPriceEdit.text=(Number(dprice)*Number(darticle.qty)/drate)//.toPrecision(4);
                                            fldPriceEdit.forceActiveFocus();}
                                }
                            }

                        }

                        RowLayout{
                            visible: Number(dacnt.trade)!==0
                            Label{
                                id: fldEq
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                                text: Math.abs(Number(damnt)*dprice/drate).toLocaleString(Qt.locale(),'f',2)
                                font.pointSize: 10
                                color: 'dimgray'
                                MouseArea{
                                    anchors.fill: parent
                                    onClicked: {
                                        fldEqEdit.text=(Number(damnt)*dprice/drate).toFixed(2)//.toPrecision(4);
                                        fldEqEdit.visible = true;
                                        fldEqEdit.forceActiveFocus();
                                    }
                                }
                            }
                            Label{
                                id: fldDsc
                                width: parent.width/2
                                text: ddsc === 0 ? 'знижка' : 100*Math.abs(ddsc) +'%' //.toLocaleString(Qt.locale(),'f',4)
//                                font.pointSize: 8
                                horizontalAlignment: Text.AlignHCenter
                                color: ddsc === 0 ? 'lightgray' : 'dimgray'
                                MouseArea{
                                    anchors.fill: parent
                                    enabled: (dpratt&2) == 2
//                                    onClicked: {fldPriceEdit.visible = true; fldPriceEdit.forceActiveFocus();}
                                }
                            }
                            Label{
                                id: fldBns
                                width: parent.width/2
                                text: dbns  === 0 ? 'бонус' : 100*Math.abs(dbns) +'%'
//                                font.pointSize: 8
                                horizontalAlignment: Text.AlignHCenter
                                color: dbns === 0 ? 'lightgray' : 'dimgray'
                                MouseArea{
                                    anchors.fill: parent
                                    enabled: (dpratt&4) == 4
//                                    onClicked: if () {fldPriceEdit.visible = true; fldPriceEdit.forceActiveFocus();}
                                }
                            }


                        }

                    }
                    TextField{
                        id: fldAmntEdit
//                        width: parent.width; height: parent.height
                        anchors.fill: parent
                        visible: activeFocus    //index === root.ListView.view.currentIndex
                        focus: true
                        selectByMouse: true
                        validator: DoubleValidator {bottom: 0; decimals: darticle.prec; notation: "StandardNotation"; locale: "en_US" }
                        onActiveFocusChanged: if (activeFocus) {selectAll()} else {visible = false}
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: 20
                        text: Math.abs(Number(damnt))
                        onEditingFinished: {
                            if (Number(text) !== 0){ damnt = Number(text).toFixed(darticle.prec); }
                            root.ListView.view.restart()
                        }
                    }
                    TextField{
                        id: fldPriceEdit
//                        width: parent.width; height: parent.height
                        anchors.fill: parent
                        visible: false
                        selectByMouse: true
                        validator: DoubleValidator {bottom: 0; decimals: 6; notation: "StandardNotation"; locale: "en_US" }
                        onActiveFocusChanged: if (activeFocus) {selectAll()} else {visible = false}
                        onAccepted: {
                            if (Number(text) !== 0){ dprice = Number(text)*drate/Number(darticle.qty); }
                            root.ListView.view.restart()
                        }
                    }
                    TextField{
                        id: fldEqEdit
//                        width: parent.width; height: parent.height
                        anchors.fill: parent
                        visible: false
                        selectByMouse: true
                        validator: DoubleValidator {bottom: 0; decimals: 2; notation: "StandardNotation"; locale: "en_US" }
                        onActiveFocusChanged: if (activeFocus) {selectAll()} else {visible = false}
//                        text: 'eq'//Math.abs(Number(eq))
                        onAccepted: {
                            // Math.abs(Number(damnt)*dprice/drate).toLocaleString(Qt.locale(),'f',2)
                            if (Number(text) !== 0){ damnt = (Number(text)/Number(dprice)).toFixed(darticle.prec); }
                            root.ListView.view.restart()
                        }
                    }
                }

                Button{
                    id: btnDelete
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    icon {source: "qrc:/icon/close.svg"}
                    onClicked: {
                        root.ListView.view.model.remove(index)
                        root.ListView.view.restart()
                    }
                }
            }
        }
    }


    ColumnLayout{
        anchors{fill: parent; margins: 2}



        RowLayout {
            Layout.fillWidth: true
            Button{
                id: btnAmnt
                Layout.preferredWidth: 32   //parent.height
                Layout.preferredHeight: 32   //parent.height
                font.pointSize: 30
                text: Number(crntAmnt) < 0 ? '-' : '+'
//                    icon {name:"add"; source:"qrc:/icon/add.svg"}
                onClicked: {crntAmnt = -1 * Number(crntAmnt); fldMainInput.forceActiveFocus()}
            }
            TextField{
                id: fldMainInput
                Layout.fillWidth: true
                selectByMouse: true
                onAccepted: {
                    if (text === ''){
                        if (Number(crntAcnt.mask)&1) {
//                                    msg(String("#6tww mask=%1 &1=%2").arg(crntAcnt.mask).arg(Number(crntAcnt.mask)&1),'CheckBind') //,Number(crntAcnt.mask)&1
                            // vkEvent('createDcmUAH', ({}));
                            insert(fnCreateDcm(''))
                        }
                        return;
                    }
                    if (text === '*') {
                        // actionTran2.trigger()
                        vkEvent('tranBind', 2);
                        return;
                    } else if (text === '*8') {
                        crntPrint = true;
                        vkEvent('tranBind', 1);
                        // tran()
                        return;
                    } else if (text === '*9') {
                        crntPrint = false;
                        vkEvent('tranBind', 0);
                        // tran()
                        return;
                    }
                    // TODO
//                    if (text == '0000') {
//                        setClient(); text =''; return;
//                    }

                    while ((text.substring(0,1) === '+') || (text.substring(0,1) === '-')) {
                        if (text.substring(0,1) === '+') {
                            text = text.substring(1)
                            crntAmnt = Math.abs(crntAmnt)
                        } else {
                            text = text.substring(1)
                            crntAmnt = 0 - Math.abs(crntAmnt)
                        }
                    }
                    if (text === ''){
                        if (Number(crntAcnt.mask)&1) {
                             // vkEvent('createDcmUAH', ({}));
                            insert(fnCreateDcm(''))
                        } //else { return; }
                    } else {
                        vkEvent('findText', {'text':text, 'mask':crntAcnt.mask})
                    }


                }

                Button{
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    visible: crntAcnt !== undefined && (Number(crntAcnt.mask)&1) == 1
                    text:'ГРН'
                    onClicked: { insert(fnCreateDcm('')); /*vkEvent('createDcmUAH', {});*/ }
                }
            }

            Row{
                spacing: 0
                Button{
                    id: btnCreditAcnt
                    text: (crntAcnt !== undefined && crntAcnt.note !== "") ? crntAcnt.note : crntAcnt.name   // 'ТОРГІВЛЯ'
    //                visible: crntAcnt.trade === '0'
                    onClicked: vkEvent('creditAcntClicked', {cashno:cashAcnt.acntno, clid:crntClient.id, mode:''})
                }
                Button{
                    id: btnReturnToTrade
                    width: 32
//                            Layout.preferredHeight: 32
                    visible: crntAcnt !== undefined && (crntAcnt.acntno).substring(0,2) !== '35' //crntAcnt.trade === '0'
                    icon {name:'undo'; source: "qrc:/icon/undo.svg"}
                    onClicked: vkEvent('crntAcntToTrade', "")
                }
            }


        }

        Rectangle{   // bindItem
            id: viewArea
            Layout.minimumWidth: 400
//                Layout.preferredWidth: 200
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip:true
//                color: 'beige'

            ListView{
                id: bindView
                anchors.fill: parent
                property real pmntTotal: 0
                property real eqTotal: 0
                property real dscMoney: 0
                property real bnsMoney: 0

                spacing: 2
                model: ListModel{ }
                delegate: dlg1
    //            onCountChanged:

                function recalculate2() {
                    var v_pmnt = 0; var v_eq = 0; var v_dsc =0; var v_bns =0; var i =0; var vtmp='';
                    totalCurrencyView.model.clear()
                    for (var r =0; r < model.count; ++r) {
    //                    console.log('crn=['+model.get(r).crn+'] amnt='+model.get(r).damnt+' eq='+model.get(r).eq+' rate='+model.get(r).crnrate +' mask='+(model.get(r).crnmask==='2'))
                        if ( model.get(r).darticle.id === ''
                                 || model.get(r).darticle.id === '980') {
                            v_pmnt += Number(model.get(r).damnt) * model.get(r).dsign
                        } else if (Number(model.get(r).darticle.mask) === 2){
                            for (i=0; (i< totalCurrencyView.model.count) &&(totalCurrencyView.model.get(i).id !== model.get(r).darticle.id); ++i){}
                            if (i === totalCurrencyView.model.count){
                                totalCurrencyView.model.append({'id':model.get(r).darticle.id, 'name':model.get(r).darticle.name, 'amnt': Number(model.get(r).damnt) * model.get(r).dsign})
                            } else {
                                totalCurrencyView.model.setProperty(i,'amnt', Number(totalCurrencyView.model.get(i).amnt)+Number(model.get(r).damnt) * model.get(r).dsign)
                            }
                        }
                        vtmp = (Number(model.get(r).damnt)*model.get(r).dprice * model.get(r).dsign).toFixed(2)
                        v_eq += Number(vtmp)
                        v_dsc -= Number((Number(vtmp)*model.get(r).ddsc).toFixed(2))
                        v_bns -= Number((Number(vtmp)*model.get(r).dbns).toFixed(2))
                    }
    //                console.log('total v_pmnt=['+v_pmnt+'] v_eq='+v_eq+' v_dsc='+v_dsc)
                    pmntTotal = (v_pmnt - (v_eq + v_dsc)).toFixed(2)
                    eqTotal = v_eq.toFixed(2)
                    dscMoney = v_dsc.toFixed(2)
                    bnsMoney = v_bns.toFixed(2)
    //                footerText = String('Всього рядків: %1(%2грн)').arg(count).arg(pmntTotal.toLocaleString(Qt.locale(),'f',2))
                }

                function restart(){
                    startNewRow();
                }

            }
        }

        Item{      // totalCurrencyView
            Layout.fillWidth: true
            Layout.preferredHeight: 20
//            color: 'ivory'
            RowLayout{
                anchors.fill: parent
                ListView{
                    id: totalCurrencyView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    orientation: ListView.Horizontal
                    spacing: 2
                    model: ListModel{}
                    delegate:
                        Label{
        //                        height: 25
                            color: amnt>0?'blue': (amnt<0?'red':'whitesmoke')
                            text: String(' %1%2 %3 ').arg(amnt<0?'-':'+').arg(name).arg(Math.abs(amnt))
                            background:
                            Rectangle{
                                color: 'lightgrey'
                            }
                        }

                }
            }


        }

        Rectangle{
            id:totalArea
            Layout.preferredHeight: childrenRect.height
            Layout.fillWidth: true
            color: 'whitesmoke'

            RowLayout{
                id:totalAreaLayout
                width: parent.width
//                anchors.fill: parent
//                anchors.verticalCenter: parent.verticalCenter
                spacing: 10

                Button{
                    id: btnTran
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    icon.name: "save"
                    icon.source: "qrc:/icon/save.svg"
//                        padding: 5
                    // onClicked: vkEvent('tranBind', jbindToTran());
                    onClicked: vkEvent('tranBind',2)       //tran2()
                }

                Label{
//                    anchors.horizontalCenter: parent.horizontalCenter
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    color: (bindView.pmntTotal) <0 ? 'red' : 'blue'
                    text: ((bindView.pmntTotal) <0 ? '- ':'+ ')+Math.abs(bindView.pmntTotal).toLocaleString(Qt.locale(),'f',2)
                    font.pixelSize: 30
                    font.bold: true
                }

                Item{
                    Layout.preferredWidth: childrenRect.width
                    Layout.fillHeight: true

                    RowLayout{
                        id:dbrArea
                        spacing: 10
                        ColumnLayout{
                            Label{
                                id: fldDsc
                                text:String('Dsc: %1 %2').arg((100 * Math.abs(Number(crntDsc))).toFixed(1)+'%')
                                     .arg(bindView.dscMoney == 0 ? '' : Math.abs(bindView.dscMoney).toLocaleString(Qt.locale(),'f',2))
                                MouseArea{
                                    anchors.fill: parent
                                    onClicked: {fldDscEdit.text = 100*Math.abs(Number(crntDsc)); fldDscEdit.visible = true; fldDscEdit.forceActiveFocus();}
                                }
                            }
                            Label{
                                id: fldBns
                                text:String('Bns: %1 %2').arg((100 * Math.abs(Number(crntBns))).toFixed(1)+'%')
                                     .arg(bindView.bnsMoney == 0 ? '' : Math.abs(bindView.bnsMoney).toLocaleString(Qt.locale(),'f',2))
                                MouseArea{
                                    anchors.fill: parent
                                    enabled: crntClient !== undefined && crntClient.id !==''
                                    onClicked: { fldBnsEdit.text = 100*Math.abs(Number(crntBns)); fldBnsEdit.visible = true; fldBnsEdit.forceActiveFocus();}
                                }
                            }
                        }

                        ColumnLayout{
                            id: fldRate
                            visible: false
                            Label{
                                text:'Rate: '+ crntRate
                                MouseArea{
                                    anchors.fill: parent
                                    onClicked: {console.log("094 clicked")
                                        fldRateEdit.visible = true; fldRateEdit.text=crntRate; fldRateEdit.forceActiveFocus();}
                                }
                            }
                            Label{ text: crntRate === '1' ? '' : (bindView.eqTotal/Number(crntRate)).toFixed(2); }
                        }
                    }
                    TextField{
                        id: fldDscEdit
                        anchors.fill: parent
                        visible: false; //activeFocus    //index === root.ListView.view.currentIndex
                        selectByMouse: true
                        validator: DoubleValidator {bottom: 0; top:100; decimals: 4; notation: "StandardNotation"; locale: "en_US" }
                        onActiveFocusChanged: if (activeFocus) {selectAll()} else {visible = false}
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: 14
                        onAccepted:  {
                            crntDsc = String(Number(text)/100)
                            for (let r = 0; r < bindView.model.count; ++r){
                                if ((Number(bindView.model.get(r).dpratt)&2) == 2){ bindView.model.setProperty(r,'ddsc', Number(crntDsc)); }
                            }
                            startNewRow()
                        }
                    }
                    TextField{
                        id: fldBnsEdit
                        anchors.fill: parent
                        visible: false; //activeFocus    //index === root.ListView.view.currentIndex
                        selectByMouse: true
                        validator: DoubleValidator {bottom: 0; top:100; decimals: 4; notation: "StandardNotation"; locale: "en_US" }
                        onActiveFocusChanged: if (activeFocus) {selectAll()} else {visible = false}
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: 14
                        onAccepted: {
                            crntBns = String(Number(text)/100)
                            for (let r = 0; r < bindView.model.count; ++r){
                                if ((Number(bindView.model.get(r).dpratt)&4) == 4){ bindView.model.setProperty(r,'dbns', Number(crntBns)); }
                            }
                            startNewRow()
                        }
                    }
                    TextField{
                        id: fldRateEdit
                        anchors.fill: parent
                        visible: false; //activeFocus    //index === root.ListView.view.currentIndex
                        selectByMouse: true
                        validator: DoubleValidator {bottom: 0; notation: "StandardNotation"; locale: "en_US" }
                        onActiveFocusChanged: if (activeFocus) {selectAll()} else {visible = false}
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: 12
                        onAccepted: {
                            crntRate = text
                            for (let r=0; r < bindView.model.count; ++r){
                                bindView.model.setProperty(r,'drate', Number(crntRate));
                                // if (Number(bindView.model.get(r).darticle.mask) === 4) { bindView.model.setProperty(r,'drate', Number(crntRate)); }
                            }
                            startNewRow()
                        }
                    }

                }

                Button{
                    id: btnDrawer
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    icon.source: "qrc:/icon/drawer.svg"
//                        contentItem: Image { source: "qrc:/icon/drawer.svg" }
    //                padding: 5
//                        flat: true
                    onClicked: {drawerAction.trigger();}
                    // onClicked: eViewDrawer()
                }


            }

        }

    }
}
