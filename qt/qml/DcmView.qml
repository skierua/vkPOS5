import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Controls

// import com.singleton.dbdriver4 1.0

Window {
    id: root
    width: 480
    height: 480

    property bool fiscMode
    onFiscModeChanged: {
        if (fiscMode) {
            contextMenu.addItem( Qt.createQmlObject('import QtQuick.Controls; MenuSeparator {}', contextMenu.contentItem, "actionFiscalizate_separator") )
            contextMenu.addAction(actionFiscalizate)
        } else {
            contextMenu.removeItem( Qt.createQmlObject("actionFiscalizate_separator") )
            contextMenu.removeAction(actionFiscalizate)
        }

        // console.log("#89h DcmView.onFiscModeChanged fiscMode=" + fiscMode)
    }

    property string sqlFilter: "select pkey as id, clchar as name, coalesce('tel.'||phone,'') || coalesce(' '||clnote,'')  as fullname, '' as scancode, 64 as mask, 'Клієнти' as sect, '0' as odr from client "
    +"union select item.pkey as id, itemchar as name, coalesce(itemname, itemnote,'') as fullname, coalesce(scancode,'') as scancode, itemmask as mask, case when itemmask=4 then 'Товари' else 'Валюти' end as sect, '1' as odr from item where folder = 0 "
    +"union select acntno as id, acntno||'-'||coalesce(acntnote,'['||balname||']','') as name, '' as fullname, '' as scancode, 128 as mask, 'Рахунки' as sect, '3' as odr from acntbal left join balname on(substr(acntno,1,2)=bal) where client is null "
    +"order by odr, sect,itemmask,name;";


    property alias jbindList: vw.binds
    onJbindListChanged: loadDcms()

    property alias jdcmList: vw.dcms

    property var findList: []
    onFindListChanged: {
        if (findList.length){
            selectPopupView.vpopulate(selectPopupFilter.text)
            selectPopup.open()
        }
    }
    property alias sqlMode : vw.sm // mode=EMPTY|1|2|4|64(client)|128(acnt)

    property int pageCrnt: 0
    property int pageLen: 50

    signal vkEvent(string eventId, var eventParam)

    function loadDcms(){
        // vw.model.clear()
        let flt = ""
        for (let i = pageCrnt * pageLen; i < jbindList.length && i < pageCrnt * pageLen + pageLen; ++i){
            flt += (flt === ""? "" : ", ") + jbindList[i].dcmid
        }
        flt = "pid in (" + flt +")"
        vkEvent("documView.loadDcmList", flt )
    }


    Component {
        id: dlg
        FocusScope{
            id: root
            width: root.ListView.view.width;
            height: childrenRect.height;
            MouseArea{
                anchors.fill: parent;
                onClicked: {vw.currentIndex = index;}
                // onDoubleClicked: {vw.currentIndex = index; viewBindAction.trigger(); }
            }
            Rectangle {
//             // id: root
//             width: root.ListView.view.width //childrenRect.width;
                width:parent.width;
                height: 32;
                clip: true
                color: (index === vw.currentIndex) ?  'lightsteelblue' : (match ? 'honeydew' : 'white')
                                                        // (index%2 == 0 ?  Qt.darker('white',1.01) : 'white')
                Row{
                    // id: rootLayout
                    anchors.fill: parent
                    // width: parent.width
                    spacing: 2
                    Label{ width: 0.05*parent.width; anchors.verticalCenter: parent.verticalCenter; horizontalAlignment: Text.AlignHCenter; text: Number(root.ListView.view.dcms[sid].amount) > 0 ? "+" : "-" }

                    Column{     // name
                        width: (root.ListView.view.dcms[sid].trade === '0'? 0.7*parent.width-4:0.4*parent.width-2);
                        spacing: 2
                        clip:true
                        Label {
                            clip: true
                            text: root.ListView.view.dcms[sid].trade === '0'? (root.ListView.view.dcms[sid].dnote.indexOf("#")===-1
                                  ? '['+root.ListView.view.dcms[sid].iname + '] '+root.ListView.view.dcms[sid].dnote
                                  : root.ListView.view.dcms[sid].dnote.substring(0,root.ListView.view.dcms[sid].dnote.indexOf("#")))
                                                                                      : root.ListView.view.dcms[sid].dnote
    //                         MouseArea{
    //                             anchors.fill: parent
    // //                                hoverEnabled: true
    //                             ToolTip.delay: 1000
    //                             ToolTip.timeout: 5000
    //                             ToolTip.visible: containsMouse
    //                             ToolTip.text: root.ListView.view.sourceData[sid].dnote
                             // }

                        }
                        Row{
                            spacing: 2
                            Label {
                                clip: true
                                text: root.ListView.view.dcms[sid].dcmid  //+" "+root.ListView.view.sourceData[sid].acnt.note + root.ListView.view.sourceData[sid].acnt.mask
                                font.pointSize: 10
                                color: 'gray'
                            }
                            Label{
                                text: '['+root.ListView.view.dcms[sid].acntcdt + ']'
                                font.pointSize: 10
                                color: 'gray'
                            }
                            // Label {
                            //     Layout.fillWidth: true
                            //     horizontalAlignment: Text.AlignRight
                            //     clip: true
                            //     // text: sid
                            //     text: humanDate(root.ListView.view.dcms[sid].dtm) //Qt.formatDateTime(jdata[id].dcmtime, String('HH:mm dd-MM-yy'))
                            //     font.pointSize: 10
                            //     color: 'dimgray'
                            // }
                        }


                    }


                    Column{     // price, eq,...
                        visible: Number(root.ListView.view.dcms[sid].trade) !== 0
                        width: visible ? 0.3*parent.width-2 : 0;
                        spacing: 2
                        clip: true
                        Label {
                            text: Number(root.ListView.view.dcms[sid].qty) === 1 ? (Number(root.ListView.view.dcms[sid].eq)/Number(root.ListView.view.dcms[sid].amount)).toFixed(root.ListView.view.dcms[sid].imask === "4" ? 2 : 4)
                                                                 : ((Number(root.ListView.view.dcms[sid].eq)/Number(root.ListView.view.dcms[sid].amount)).toFixed(root.ListView.view.dcms[sid].imask === "4" ? 2 : 4)+'/'+root.ListView.view.dcms[sid].qty)
                        }
                        Row{
    //                            anchors.horizontalCenter: parent.horizontalCenter

                            Label {
                                font.pointSize: 10
                                color: 'dimgray'
                                text: Math.abs(Number(root.ListView.view.dcms[sid].eq)).toLocaleString(Qt.locale(),'f',2)
                            }
                            Label {
                                text:Number(root.ListView.view.dcms[sid].dsc)===0?'':('D:'+Math.abs(Number(root.ListView.view.dcms[sid].dsc)).toLocaleString(Qt.locale(),'f',2))
                                font.pointSize: 10
                                color: 'dimgray'
                            }
                            Label {
                                text:Number(root.ListView.view.dcms[sid].bns)===0?'':('B:'+Math.abs(Number(root.ListView.view.dcms[sid].bns)).toLocaleString(Qt.locale(),'f',2))
                                font.pointSize: 10
                                color: 'dimgray'
                            }
                        }
                    }
                    // Label {
                    //     anchors.fill: parent
                    //     visible: Number(root.ListView.view.sourceData[sid].acnt.trade) === 0
                    //     text: root.ListView.view.sourceData[sid].dnote
                    //     font.pointSize: 10
                    //     color: 'dimgray'
                    // }

                    Label {
                        width: 0.25*parent.width-2;
                        anchors.verticalCenter: parent.verticalCenter;
                        horizontalAlignment: Text.AlignRight
                        font.pointSize: 14
                        text:Math.abs(Number(root.ListView.view.dcms[sid].amount)).toLocaleString(Qt.locale(),'f',Number(root.ListView.view.dcms[sid].prec))
                    }

                }

            }
        }
    }

    Action {
        id: reloadAction
        // text: "🔄"
        icon.source:"qrc:/icon/reload.svg"
        onTriggered: {
            let vfilt = String("dcmid in (select DISTINCT parentid from documall where  %1)")
            if (sqlMode.mask === 2 || sqlMode.mask === 4){     // currency

                vfilt = String("dcmid in (SELECT DISTINCT parentid FROM documall WHERE item = '"+ sqlMode.code +"' AND %1 )")
            } else if (sqlMode.mask === 64){        // client

                vfilt = String("clid = '"+ sqlMode.code +"' OR dcmid in (SELECT DISTINCT parentid FROM documall WHERE acntcdt IN (select acntno from acntbal where client = '"+ sqlMode.code +"')  AND %1 )")

            } else if (sqlMode.mask === 128){       // account

                vfilt = String("dcmid in (SELECT DISTINCT parentid FROM documall WHERE acntcdt = '"+ sqlMode.code +"' AND %1 )")
            }
            vkEvent("documView.loadBindList", vfilt.arg(findInterval.currentValue ==='all' ? '1' : (findInterval.currentValue)) )

        }
    }

    Action {
        id: clearFilterAction
        text: "Скинути фільтри"
        icon.name: "edit"
        onTriggered: {
            sqlMode = {'mask':0, 'code':'','text':''}
            vfilterEdit.text = ""
            findInterval.currentIndex = 0
            reloadAction.trigger()
        }
    }
    Action {
        id: actionFilter
        // text: "Фільтр"
        icon.name: "filter"
        icon.source:"qrc:/icon/filter.svg"

        onTriggered: vkEvent("documView.find", text);
    }

 /*   Action {
        id: viewBindAction
        text: "Переглянути чек"
        onTriggered: { vkEvent("bind", vw.model.get(vw.currentIndex).bind); }
    } */

    Action {
        id: returnAction
//        enabled: vw.model.get(vw.currentIndex).dcmtype.substring(0,6)==="TRADE:"
        text: "Повернути"
        onTriggered: { vkEvent("documView.return", jdcmList[vw.model.get(vw.currentIndex).sid]); }
    }

    Action {
        id: actionPrintCheck
        text: "Друкувати чек"
        onTriggered: { vkEvent("docum.printCheck", vw.model.get(vw.currentIndex).bind); }
    }

    Action {
        id: actionPrintOrder
        text: "Зберегти накладну"
        onTriggered: { vkEvent("docum.saveOrder", vw.model.get(vw.currentIndex).bind); }
    }

    Action {
        id: actionFiscalizate
        // enabled: (vw.currentIndex !== -1 && vw.model.get(vw.currentIndex).fiscalizable)
        text: "Фіскалізувати"
        onTriggered: { vkEvent("docum.fiscCheck", vw.model.get(vw.currentIndex).bind); }
    }

    Action {
        id: actionShowBind
        text: qsTr("Bind")
        checkable: true
        checked: true
        onTriggered: { vw.section.property = (checked ? "bind" : "")}
    }

    Action {
        id: previousAction
        enabled: pageCrnt > 0
        text: "❮"
        onTriggered: { --pageCrnt; loadDcms(); }
    }

    Action {
        id: nextAction
        enabled: pageCrnt < vcrntEdit.validator.top -1
        text: "❯"
        onTriggered: { ++pageCrnt; loadDcms(); }
    }

    Popup{
        id: selectPopup
//        property var jsdata     // JSON value: id, name, fullname, scancode, mask, sect
        width:300
        height: root.height*0.8
        x: (root.width-width)/2
        modal: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
//        }
        ListView{
            id: selectPopupView
            anchors.fill: parent
            currentIndex: -1
            clip: true
            spacing: 0
            ScrollBar.vertical: ScrollBar{
                parent: selectPopupView.parent
                anchors.top: selectPopupView.top
                anchors.left: selectPopupView.right
                anchors.bottom: selectPopupView.bottom
            }
            model: ListModel{}
            delegate: Rectangle{
                width:selectPopupView.width
                height:childrenRect.height
                color: index%2==0 ? 'white' : 'whitesmoke'  // Qt.darker('white',0.5)
                ColumnLayout{
                    spacing: 0
                    Label{text:name}
                    RowLayout{
                        Label{text:id; color:'gray'}
                        Label{text:fullname; color:'gray'}
                    }
                }

                MouseArea{
                    anchors.fill: parent
                    onClicked: {
                        sqlMode = {'mask': Number(mask), 'code':String(id), 'text':name};
//                        msg('index='+index+' name='+name)
                        selectPopup.close()
                        // reloadAction.trigger()
                    }
                }
            }
            section.property: "sect"
            section.criteria: ViewSection.FullString
            section.delegate: Rectangle{
                width: selectPopupView.width
                height: 30  //*/childrenRect.height*1.2
                color: "silver"
                Label{
                    font.pixelSize: 12;
                    text:'  '+section;
                    anchors{verticalCenter: parent.verticalCenter}
                }
            }
            function vpopulate(vfilter) {
                model.clear()
                for (var r =0; r < findList.length; ++r){
                    if (vfilter === undefined || String(vfilter) === ''
                            || ~(findList[r].id.indexOf(String(vfilter)))
                            || ~(findList[r].name.toLowerCase()).indexOf(String(vfilter).toLowerCase())
                            || ~(findList[r].fullname.toLowerCase()).indexOf(String(vfilter).toLowerCase())
                            || (findList[r].scancode !== undefined && ~(findList[r].scancode).indexOf(String(vfilter)))
                            ){
                        model.append(findList[r])
                    }
                }
            }
        }
        TextField{
            id: selectPopupFilter
            height: 26
            width: 80
//            font.pixelSize: 8
            anchors{right:parent.right;bottom:parent.bottom}
            selectByMouse: true
            placeholderText: 'фільтр'
            onEditingFinished: selectPopupView.vpopulate(text)
        }
        // onVisibleChanged: if(!visible){selectPopupFilter.text='';} else {selectPopupView.vpopulate(selectPopupFilter.text); selectPopupFilter.forceActiveFocus();}

    }


    Popup{
        id: bindPopup
        property var rootDcm
        property alias fiscable: bfisc.enabled

        onRootDcmChanged: {
            if (rootDcm !== undefined){
//                bfisc.enabled = (rootDcm.dcmtype === 'check' && rootDcm.dcmno === '')
                bindPopupCode.text = rootDcm.dcmtype
                bindPopupClid.text = rootDcm.client
                bindPopupSum.text = Math.abs(Number(rootDcm.eqamount)).toFixed(2)
                bindPopupSign.text = Number(rootDcm.eqamount)>0 ? "-":"+"
                bindPopupCash.text = Math.abs(Number(rootDcm.eqamount)).toFixed(2)
                bindPopupCashSign.text = Number(rootDcm.amount)<0 ? "-":"+"
                bindPopupId.text = rootDcm.id+"/"+rootDcm.dcmno
                bindPopupTime.text = rootDcm.dcmtime.substring(0,16)
                bindPopupDsc.text = Math.abs(Number(rootDcm.discount)).toFixed(2)
                bindPopupBns.text = Math.abs(Number(rootDcm.bonus)).toFixed(2)
            } else {
                bfisc.enabled = false
            }
        }

        width:parent.width*0.8
        height: 400
        x: (parent.width-width)/2
        modal: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        ColumnLayout{
            anchors{fill:parent}
            RowLayout{
                Label{text:"Документ:"}
                Label{id: bindPopupCode; }
                Label{text:" Клієнт:"}
                Label{id: bindPopupClid; }

            }
            Rectangle{
                Layout.fillWidth: true
                Layout.preferredHeight: 2
                color: 'dimgray'
            }

            ListView{
                id: bindPopupView
                Layout.fillHeight: true
                Layout.fillWidth: true
                currentIndex: -1
                clip: true
                spacing: 2
                model: ListModel{}
                delegate: Rectangle{
                    width:bindPopupView.width
                    height:childrenRect.height
                    color: index%2==0 ? 'white' : 'whitesmoke'  // Qt.darker('white',0.5)
                    RowLayout{
                        width: parent.width
                        Item{
                            Layout.fillWidth:true;
                            Layout.preferredHeight: childrenRect.height
                            clip: true
                            ColumnLayout{
                                spacing: 0
                                Label{text:(Number(amount)<0?'- ':'+ ')+ String(dcmnote)}

                                RowLayout{
                                    Label{text:'#'+id; color:'gray'; font.pixelSize:7;}
                                    Label{text:'['+acntcdt+'.'+item+']'; color:'gray'; font.pixelSize:7;}
                                }
                            }

                        }

                        Label{
                            Layout.preferredWidth: parent.width*0.25
                            font.pixelSize: 12
                            text:Math.abs(Number(amount))
                            horizontalAlignment: Text.AlignRight
                        }
                        Item{
                            Layout.preferredWidth: parent.width*0.25
                            Layout.preferredHeight: childrenRect.height
                            ColumnLayout{
                                visible: Number(eqamount)!==0
                                Label{text: ((Number(eqamount)/Number(amount)).toLocaleString(Qt.locale(),'f',4))}
                                Label{
                                    text:Math.abs(Number(eqamount)).toLocaleString(Qt.locale(),'f',2)
                                         +(Number(discount)!==0?(' D:'+Number(discount)):'')+(Number(bonus)!==0?(' B:'+Number(bonus)):'')
                                    color:'gray'; font.pixelSize:7;
                                }

                            }

                        }
                        /*                        Button{
                            visible: dcmcode.substring(0,6) === 'trade:'
                            Layout.preferredWidth: parent.height
                            text: '<<<'
//                            icon.source:"qrc:/icon/undo.svg"

//                            ToolTip{text: 'Повернення'; visible: hovered}
//                            onClicked: {setDcmById(id)}
                        }*/

                    }
               }
            }
            Rectangle{
                Layout.fillWidth: true
                Layout.preferredHeight: 2
                color: 'dimgray'
            }
            RowLayout{
                Label{id: bindPopupSign; font.pointSize: 14;}
                Label{ font.pointSize: 14; text:"Сума: "}
                Label{id: bindPopupSum; font.pointSize: 14; font.bold: true;}
                Label{text:" Знижка:"}
                Label{id: bindPopupDsc; }
                Label{text:" Бонус:"}
                Label{id: bindPopupBns; }
            }
            RowLayout{
                Label{id: bindPopupCashSign; font.pointSize: 14;}
                Label{ font.pointSize: 14; text:"Готівка: "}
                Label{id: bindPopupCash; }
            }
            RowLayout{
                Label{text:"Id:"}
                Label{id: bindPopupId; }
                Label{text:" Time:"}
                Label{id: bindPopupTime; }
            }

            RowLayout{
    //            anchors{right: parent.right; bottom: parent.bottom}
                Button{
                    id: bfisc
                    text: 'Фіскалізувати'
                    onClicked: {
//                        enabled = false
                        vkEvent("fiscCheck", bindPopup.rootDcm)
                        bindPopup.close()
                    }
                }
                Item{ Layout.fillWidth: true; }
                Button{
                    id: bprCheck
//                    enabled: false
                    text: qsTr('Чек')
                    onClicked: {
        //                msg('printid='+bindPopup.jsdata.bindid)
                        vkEvent("printCheck", bindPopup.rootDcm)
                        bindPopup.close()
                    }
                }
                Button{
                    id:bprFacture
//                    enabled: false
                    text: qsTr('Накладна')
                    onClicked: {
                        vkEvent("printFacture", bindPopup.rootDcm)
                        bindPopup.close()
                    }
                }

            }

        }

    }

    Page{
        anchors.fill: parent
        // Pane{
        //     anchors.fill: parent
            ListView{
                id: vw
                property var dcms: []
                onDcmsChanged: test_vshow()

                property var binds: []

                property alias vfilter: vfilterEdit.text
                property var sm: {'mask':0, 'code':'','text':''}    // sql mode

                anchors{fill: parent; margins:2}
                clip: true
                spacing: 1
                model: ListModel{}
                delegate: dlg
                ScrollBar.vertical: ScrollBar{
                    parent: vw.parent
                    anchors.top: vw.top
                    anchors.left: vw.right
                    anchors.bottom: vw.bottom
                }
                onCurrentItemChanged: {
                    // viewBindAction.enabled = model.count
                    // returnAction.enabled = model.count && (model.get(currentIndex).dcmtype.substring(0,6)==="trade:")
                }
                // section.property: ""
                section.property: "bind"
                section.criteria: ViewSection.FullString
                section.delegate: Rectangle{
                    width: vw.width
                    height: 30  //childrenRect.height //*1.2
                    color: (vw.sm.mask === 64 && vw.sm.code === vw.bindInfo(section).clid  ? Qt.darker('HoneyDew',1.1) : "whitesmoke")
                    // color: (vw.sm.mask === 64 && vw.sm.code === vw.bindInfo(section).clid  ? 'MintCream' : "whitesmoke")
                    Row{
                        anchors{fill: parent}
                        spacing: 4
                        Label{ width:parent.width/2; anchors.verticalCenter: parent.verticalCenter; font.pointSize: 15; text: vw.bindInfo(section).dcmtype}
                        Column{
                            Label{ text: Number(vw.bindInfo(section).amount).toLocaleString(Qt.locale(),'f',2)}
                            Row{
                                spacing: 2
                                Label{ font.pointSize: 10; color: 'gray'; text: vw.bindInfo(section).eq}
                                Label{ font.pointSize: 10; color: 'gray'; text: vw.bindInfo(section).dsc; }
                                Label{ font.pointSize: 10; color: 'gray'; text: vw.bindInfo(section).bns}
                            }

                        }
                        // Item{  }
                        Label{ anchors.verticalCenter: parent.verticalCenter; font.pointSize: 12; text: vw.bindInfo(section).clchar}
                        Column{
                            Label{ anchors.right: parent.right; font.pointSize: 12; text: vw.bindInfo(section).dtm.substring(11,16)}
                            Label{ font.pointSize: 12; text: vw.bindInfo(section).dtm.substring(0,10)}
                        }

                    }

                }

                function bindInfo(vid){
                    let i = 0
                    for (i = 0; (i < binds.length && binds[i].dcmid !== vid); ++i) {}
                    if (i < binds.length ) return binds[i];
                    return {"dcmtype":"","amount":"","eq":"","dsc":"","bns":"","dtm":"", "clid":"","clchar":""}
                }

                function isCurrentRowFiscalizable(){
                    if (model.count){
                        return (vw.currentIndex !== -1 && model.get(currentIndex).fiscalizable);
                    }

                    return false;
                }

                function test_vshow(){
                    currentIndex = -1
                    delegate = null
                    model.clear()
                    let m = false
                    let fsc = true
                    for (let r = 0; r < dcms.length; ++r) {
                        if( vfilter===undefined || vfilter===''
                        || ~((dcms[r].dnote).toLowerCase()).indexOf(String(vfilter).toLowerCase())
                        || ~((dcms[r].iname).toLowerCase()).indexOf(String(vfilter).toLowerCase())
                        || ~((dcms[r].ifname).toLowerCase()).indexOf(String(vfilter).toLowerCase())
                        || ~((dcms[r].scan).toLowerCase()).indexOf(String(vfilter).toLowerCase())
                        || (dcms[r].acntcdt === vfilter)
                        ) {
                            m = false
                            fsc = (dcms[r].dcmtype === "trade:sell" && Number(dcms[r].imask) === 4 && Number(dcms[r].amount) < 0)
                            if (sm.mask) {
                                if (sm.mask === 2 || sm.mask === 4) { m = (dcms[r].atclid === sm.code); }
                                else if (sm.mask === 64) { m = (dcms[r].clid === sm.code); }
                                else if (sm.mask === 128) { m = (dcms[r].acntcdt === sm.code); }
                            }
                            vw.model.append({"bind": dcms[r].pid, "sid": r, 'match':m, 'fiscalizable': fsc})
                            // model.append(dcms[r])
                            // model.setProperty(model.count-1, "match", m)

                        }

                    }
                    delegate = dlg
                    if (model.count) {currentIndex = 0; }
                }

//                Component.onCompleted: currentIndex = -1
            }

        // }

        header: ToolBar {
            RowLayout {
                anchors.fill: parent
                ToolButton{
                    action: reloadAction
//                    font.pixelSize: 24;
                }
                ToolButton{
                    action: actionFilter
                }

                Label {
                    id: headerTitle
                    text: sqlMode.text
                    elide: Label.ElideRight
                    horizontalAlignment: Qt.AlignHCenter
                    verticalAlignment: Qt.AlignVCenter
                    Layout.fillWidth: true
                }
                ComboBox{
                    id: findInterval
                    Layout.preferredWidth: 150
//                    Layout.fillWidth: true
                    flat: true
                    model: ListModel {
//                        id: sqlFilterModel
                        ListElement { text: "за зміну"; table: "docum"; filter: "(shftid = 0 and parentid is not null)" }
                        ListElement { text: "2 тижні"; table: "documall"; filter: "dcmtime >= date('now', '-14 day')" }
                        ListElement { text: "місяць"; table: "documall"; filter:"dcmtime >= date('now', '-1 month')" }
                        ListElement { text: "квартал"; table: "documall"; filter:"dcmtime >= date('now', '-3 month')" }
                        ListElement { text: "рік"; table: "documall"; filter:"dcmtime >= date('now', '-1 year')" }
                        ListElement { text: "з поч.місяця"; table: "documall"; filter:"dcmtime >= date('now','start of month')" }
                        ListElement { text: "з поч.року"; table: "documall"; filter:"dcmtime >= date('now','start of year')" }
                        ListElement { text: "весь період"; table: "documall"; filter:"all" }
                    }
                    textRole: 'text'
                    valueRole: 'filter'
                    onCurrentIndexChanged: {
                        // vkEvent('log', '#9dj combo='+currentValue)
//                        btnReload.visible = true;
                    }
                }
                ToolButton {    // ⋮
                    text: qsTr("⋮")
                    onClicked: {
                        actionFiscalizate.enabled = vw.isCurrentRowFiscalizable()
                        contextMenu.open()
                    }
                    Menu{
                        id: contextMenu
                        MenuItem { action: clearFilterAction; }
                        // MenuItem { action: viewBindAction; }
                        MenuItem { action: returnAction; }
                        MenuSeparator { padding: 5; }
                        MenuItem { action: actionPrintCheck; }
                        MenuItem { action: actionPrintOrder; }
                        MenuSeparator { padding: 5; }
                        MenuItem { action: actionShowBind; }
                    }
                }

            }

        }
        footer: ToolBar {
            RowLayout {
                anchors{fill: parent;leftMargin:5; rightMargin:5;}
                TextField{
                    id: vfilterEdit
                    Layout.preferredWidth: 100
//                    focus: true
                    selectByMouse: true
                    onActiveFocusChanged: if (activeFocus) {selectAll()}
                    horizontalAlignment: Text.AlignHCenter
                    text: vw.vfilter
                    onAccepted: vw.test_vshow()
                }
                Item{
                    Layout.fillWidth: true
                }
                ToolButton{ action: previousAction; }
                TextField{
                    id: vcrntEdit
                    Layout.preferredWidth: 50
//                    focus: true
                    selectByMouse: true
                    validator: IntValidator {bottom: 1;  top: Math.ceil(vw.binds.length/pageLen)}
                    onActiveFocusChanged: if (activeFocus) { selectAll(); }
                    horizontalAlignment: Text.AlignHCenter
                    text: pageCrnt + 1
                    onAccepted: { pageCrnt = Number(text)-1; loadDcms(); }
                }
                ToolButton{ action: nextAction; }

                Label{
                    id: footerCount
                    text: ' '+ vcrntEdit.validator.top +'/'+ Math.ceil(vw.binds.length/pageLen) +'('+ jbindList.length+')'
                }
            }
        }
    }


    function humanDate(vdate) {
        var vtmp = Date()
        var vdiff = Math.floor(((new Date().getTime())-(new Date(String(vdate).substring(0,10)).getTime()))/(1000*60*60*24))
        if (vdiff == 0) { return vdate.substring(11,16) // Qt.formatDate(new Date(vdate), 'hh:mm')
        } else if (vdiff == 1) { return 'вч '+vdate.substring(11,16)  //Qt.formatDate(new Date(vdate), 'вч hh:mm')
//        } else if (vdiff < 8) { return Math.floor(((new Date().getTime())-(new Date(String(vdate).substring(0,10)).getTime()))/(1000*60*60*24))+' дн.'
        } else if (vdiff < 360) { return Qt.formatDate(new Date(vdate), 'dd MMM')
        } else { return Qt.formatDate(new Date(vdate), 'MMM yy'); /*String(vdate).substring(0,10);*/ }

    }


    Component.onCompleted: {
        // statusChanged.connect(handleComponentStatusChange) //console.log("status="+ root.status
        // Db.msg("Test message FROM DcmView.");
        // console.log("#73h main TEST fiscMode="+ fiscMode)

        // contextMenu.addAction(clearFilterAction)
        // contextMenu.addAction(viewBindAction)
        // contextMenu.addAction(returnAction)
        // contextMenu.addItem( Qt.createQmlObject('import QtQuick.Controls; MenuSeparator {}', contextMenu.contentItem, "dynamicSeparator") )
        // contextMenu.addAction(actionPrintCheck)
        // contextMenu.addAction(actionPrintOrder)
        // contextMenu.addItem( Qt.createQmlObject('import QtQuick.Controls; MenuSeparator {}', contextMenu.contentItem, "dynamicSeparator") )
        // contextMenu.addAction(actionShowBind)
    }

}

