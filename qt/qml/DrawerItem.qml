import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item{
    id: root
    anchors{fill: parent}
//    property string mode: "cash"
    property string dfltSql
    property var jdata
    onJdataChanged: {
        // for (let i=0; i<jdata.length; ++i){console.log(String("#84hd DrawerItem %1/%2").arg(jdata[i].name).arg(jdata[i].ano))}
        vfilter = ""
        vw.vpopulate()
    }
    property alias vfilter: filterEdit.text
        onVfilterChanged: vw.vpopulate()

    signal vkEvent(string id, var param)
//    color: 'lightgray'
    ColumnLayout{
        anchors{fill: parent;}
        spacing: 1
        RowLayout{
            Button{
                Layout.fillWidth: true
                text: 'Каса'
                onClicked: {
//                    mode = "cash"
                    vkEvent("sqlRequest",{"sql": dfltSql })
                }
            }
            Button{
                Layout.fillWidth: true
                text: 'Дебітори'
                onClicked: {
//                    mode = "debt"
                    let sql = "select '' as bind, coalesce(itemchar, item, 'ГРН') || ' : '|| coalesce(clchar,'внутрішній') as name, coalesce(acntnote, '['||balname||']',acntno) ||  ' #'|| acntno || ': '||coalesce(itemname, item, 'гривня україни') as subname,";
                    sql += "(turncdt-beginamnt-turndbt) as total, turncdt as subamnt1, turndbt as subamnt2, item.pkey as key, coalesce(unitprec,2) as prec, scancode as scan, 0 as totaleq, coalesce(client.pkey,'') as clid, acnt.acntno as ano, coalesce(itemmask,1) as mask ";
                    sql += "from acnt join acntbal using(acntno) left join client on(client=client.pkey) left join balname on (substr(acntno,1,2)=bal) left join item on (item = item.pkey)  left join itemunit on (defunit=itemunit.pkey) ";
                    sql += "where substr(acntno,1,2) in('36','38','42') and (abs(total) > 0.0009 or dbtupd>date(coalesce((select max(shftdate) from shift),date('now')), '-0 days')  or  cdtupd>date(coalesce((select max(shftdate) from shift),date('now')), '-0 days')) order by mask,clchar,name;";
                    vkEvent("sqlRequest",{"sql": sql })
                }
            }
            Button{
                Layout.fillWidth: true
                text: 'TRADE'
                onClicked: {
//                    mode = "trade"
                    let sql = "select coalesce(acntnote,'') as bind, coalesce(itemchar, item, 'ГРН') as name, '[' || coalesce(item,'980') || '] ' || coalesce(itemname, item, 'гривня україни') as subname,"
                    + " (turncdt-beginamnt-turndbt) as total, (turncdt-beginamnt-turndbt)*bscprice as totaleq, turncdt as subamnt1, turndbt as subamnt2, item.pkey as key, coalesce(unitprec,2) as prec, scancode as scan, coalesce(client,'') as clid, acnt.acntno as ano, coalesce(itemmask,1) as mask, itemchar "
                    + " from acnt join acntrade on(acnt.acntno=acntrade.acntno and acnt.item=acntrade.article) join acntbal using(acntno) left join balname on (substr(acntbal.acntno,1,2)=bal) left join item on (item =item.pkey)  left join itemunit on (defunit=itemunit.pkey)  "
                    + " where acntbal.trade=1 and (abs(total) > 0.0009 or turndbt!=0 or turncdt!=0) order by bind, itemmask, itemnote;";
                    vkEvent("sqlRequest",{"sql": sql })
                }
            }

        }
        RowLayout{
            TextField{
                id: filterEdit
                Layout.fillWidth: true
                font.pixelSize: 12
                selectByMouse: true
                placeholderText: 'фільтр'
                color: text===''?'lightgray':'black'
//                onAccepted: vw.vpopulate(text)
            }
            Button{
                Layout.fillWidth: true
                text: 'Товар'
                onClicked: {
//                    mode = "stock"
                    let sql = "select '' as bind, coalesce(itemchar, item, 'ГРН') as name, '#' || coalesce(item,'980')||coalesce(' '||itemnote,'') as subname, (beginamnt+turndbt-turncdt) as total,";
                    sql += "turndbt as subamnt1, turncdt as subamnt2, item.pkey as key, coalesce(unitprec,2) as prec, scancode as scan, 0 as totaleq, coalesce(client,'') as clid, acnt.acntno as ano, coalesce(itemmask,1) as mask ";
                    sql += "from acnt join acntbal using(acntno) left join item on (item =item.pkey) left join itemunit on (defunit=itemunit.pkey) ";
                    sql += "where acntno = '3000' and (itemmask=4) and (abs(total) > 0.0009 or dbtupd>date(coalesce((select max(shftdate) from shift),date('now')), '-0 days')  ";
                    sql += "or  cdtupd>date(coalesce((select max(shftdate) from shift),date('now')), '-0 days')) order by mask, name;";
                    vkEvent("sqlRequest",{"sql": sql })
                }
            }
            Button{
                Layout.fillWidth: true
                text: 'Брак'
                onClicked: {
//                    mode = "deffective"
                    let sql = "select '' as bind, coalesce(itemchar, item, 'ГРН') as name,'#' || coalesce(item,'980')||coalesce(' '||itemnote,'') as subname, (beginamnt+turndbt-turncdt) as total,";
                    sql += "turndbt as subamnt1, turncdt as subamnt2, item.pkey as key, coalesce(unitprec,2) as prec, scancode as scan, 0 as totaleq, coalesce(client,'') as clid, acnt.acntno as ano, coalesce(itemmask,1) as mask ";
                    sql += "from acnt join acntbal using(acntno) left join item on (item =item.pkey) left join itemunit on (defunit=itemunit.pkey) ";
                    sql += "where acntno = '3020' and (itemmask=4) and (abs(total) > 0.0009 or dbtupd>date(coalesce((select max(shftdate) from shift),date('now')), '-0 days')  ";
                    sql += "or  cdtupd>date(coalesce((select max(shftdate) from shift),date('now')), '-0 days')) order by name;";
                    vkEvent("sqlRequest",{"sql": sql })
                }
            }

        }

        Rectangle{
            id: debtMsg
            Layout.fillWidth: true
            Layout.preferredHeight: 20
            visible: false
            color: 'ivory'
            Label{
                anchors.horizontalCenter: parent.horizontalCenter
                color: 'red'
                text: 'Червоним борг клієнта'

            }

        }

        ListView{
            id: vw
            property var totalEq: []
            Layout.fillHeight: true
            Layout.fillWidth: true
            spacing: 1
            clip: true
            model: ListModel{ }
            delegate:
                Rectangle{
                    width: vw.width
                    height: 35       //visible ? childrenRect.height+2 : 0
                    clip: true
                    Row{
                        anchors{fill: parent; leftMargin: 5; rightMargin: 5;}
                        Column{
                            width: parent.width *0.6 - parent.spacing
                            anchors.verticalCenter: parent.verticalCenter
//                                    spacing: 0
                            clip: true
                            Label{text: name; font.pixelSize: 12 }
                            Label{text: subname; font.pixelSize: 10; color: 'grey'; }
                        }
                        Column{
                            width: parent.width *0.4
                            anchors.verticalCenter: parent.verticalCenter
//                                    spacing: 0
                            Label{
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: Math.abs(Number(total)).toLocaleString(Qt.locale(),'f', Number(prec))
                                font.pixelSize: 12
                                color: Number(total) < 0 ? 'red' : 'black'
                            }
                            Row{
                                width: parent.width
                                spacing: 5
//                                        Item{
                                    Label{
                                        width: (parent.width - parent.spacing)/2
//                                                anchors.verticalCenter: parent.verticalCenter
                                        horizontalAlignment: Text.AlignHCenter
                                        text: Number(subamnt1)===0 ? "" : Number(subamnt1).toLocaleString(Qt.locale(),'f',Number(prec))
                                        font.pixelSize: 8
                                        color: 'grey'
                                    }
//                                        }
//                                        Item{
                                    Label{
                                        width: (parent.width - parent.spacing)/2
//                                                anchors.horizontalCenter: parent.horizontalCenter
                                        horizontalAlignment: Text.AlignHCenter
                                        text: Number(subamnt2)===0 ? "" : Number(subamnt2).toLocaleString(Qt.locale(),'f',Number(prec))
                                        font.pixelSize: 8
                                        color: 'grey'
                                    }
//                                        }


                            }

                        }
                    }
                    MouseArea{
                        anchors.fill: parent
                        onDoubleClicked: { vkEvent("rowDClicked",{"atcl":key, "clid":clid, "acnt":ano, "mask":mask, "amnt":Number(total).toFixed(prec) }); }
                    }
                }
            section.property: "bind"
            section.criteria: ViewSection.FullString
            section.delegate: Rectangle{
                width: vw.width
                height: /*40  //*/childrenRect.height   //*1.2
                color: "silver"
                RowLayout{
                    Label{
//                            anchors.verticalCenter: parent.verticalCenter
                        text:'  '+section
    //                    font.bold: true
                        font.pixelSize: 14
                    }
                    Label{
                        Layout.minimumWidth: 70
                        text: (vw.totalEq[section]!==undefined && vw.totalEq[section]!==0)?Number(vw.totalEq[section]).toLocaleString(Qt.locale(),'f',0):''
//                                font.bold: true
                        font.pixelSize: 12
//                                color: (contentView.total[section]===undefined||Number(contentView.total[section])<0)? 'red':'black'
                        horizontalAlignment: Text.AlignRight
                    }

                }

            }
            function vpopulate(){
                debtMsg.visible = false;
                totalEq =[]
                model.clear()
                if (jdata === undefined){ return; }
                var r = 0
                var i = 0
                for (r =0; r < jdata.length; ++r){
//                    console.log("#73y sub="+jdata[r].ano.substring(0,2))
                    if (!debtMsg.visible && jdata[r].ano.substring(0,2)==="36" ) { debtMsg.visible = true; }
//                    debtMsg.visible = true;
                    if (vfilter === ''
                            || jdata[r].key === vfilter
                            || ~(jdata[r].name.toLowerCase()).indexOf(vfilter.toLowerCase())
                            || ~(jdata[r].subname.toLowerCase()).indexOf(vfilter.toLowerCase())
                            || ~(jdata[r].scan).indexOf(vfilter)
                            ) {
                        model.append(jdata[r])
                        vw.totalEq[jdata[r].bind] = (vw.totalEq[jdata[r].bind] === undefined)
                                ? (Number(jdata[r].totaleq)) : (Number(vw.totalEq[jdata[r].bind]) + Number(jdata[r].totaleq))

                    }

                }
                filterEdit.forceActiveFocus()
            }
        }
    }
    Component.onCompleted: {
        let sql = "select coalesce(acntnote,'') as bind, coalesce(itemchar, item, 'ГРН') as name,'[' || coalesce(item,'980') || '] ' || coalesce(itemname,item, 'гривня україни') as subname,"
        + " (beginamnt+turndbt-turncdt) as total,turndbt as subamnt1, turncdt as subamnt2, item.pkey as key, coalesce(unitprec,2) as prec,"
        + " scancode as scan, 0 as totaleq, coalesce(client,'') as clid, acnt.acntno as ano, coalesce(itemmask,1) as mask  "
        + " from acntbal join acnt using(acntno) left join item on (item = item.pkey)  left join itemunit on (defunit=itemunit.pkey)"
        + " where substr(acntno,1,2) = '30' and (itemmask is null or itemmask=2) and (abs(total) > 0.0009 or dbtupd>date(coalesce((select max(shftdate) from shift),date('now')), '-0 days')"
        + " or  cdtupd>date(coalesce((select max(shftdate) from shift),date('now')), '-0 days')) order by bind, itemmask, itemnote;";
        dfltSql = sql;
    }
}
