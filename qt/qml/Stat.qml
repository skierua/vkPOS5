import QtQuick
import QtQuick.Controls
// import QtQuick.Controls.Fusion
import QtQuick.Layouts

import "../lib.js" as Lib

Window {
    id: root
    width: 200  //parent.width *0.5
    height: 400 //parent.height *0.3
    property alias cshr: dataModel.cashier        // cashier
    property var dbDriver                 // DataBase driver
    onDbDriverChanged: {
        vw.model.populate(dbDriver)
    }

    // signal vkEvent(string id, var param)

    ListModel{
        id: dataModel
        property string cashier
        property var total: []

        function populate(db){
           let jsdata = Lib.parse(db.dbSelectRows(String("select substr(dcmtime,1,10) as tm, acntcdt, p.client, sum(amount) as amnt from strgdocum as d join "
                                       + "(select dcmid, client from strgdocum where dcmtype='folder' and acntcdt='rslt') as p on (d.parentid=p.dcmid) "
                                       + "where substr(acntcdt,1,9)='rslt.3500' and dcmtime > substr(date('now', '-4 month'),1,7) and p.client='%1' group by substr(dcmtime,1,10), acntcdt, p.client ORDER by tm desc;").arg(cashier))).rows
            // console.log("#4jm Stat jsdaata="+JSON.stringify(jsdata))
            clear()

            let ttl = []
            let i=0
            for (let r=0; r< jsdata.length; ++r){
                jsdata[r].bind = jsdata[r].tm.substring(0,7)
                if (ttl[jsdata[r].bind] === undefined) { ttl[jsdata[r].bind] = Number(jsdata[r].amnt);
                } else { ttl[jsdata[r].bind] +=  Number(jsdata[r].amnt); }
                // for (i=0; i < ttl.length && ttl[i].bind !== jsdata[r].bind; ++i) {}
                // if (i == ttl.length) { ttl.push({"bind":jsdata[r].bind, "amnt": Number(jsdata[r].amnt)});
                // } else { ttl[i].amnt +=  Number(jsdata[r].amnt); }
                append(jsdata[r])
            }
            dataModel.total = ttl
        }

        function getTotal(section){
            return (total[section] !== undefined ? total[section] : 0);
        }

    }


    Pane {
        anchors.fill: parent
        // Rectangle{
            // width: parent.width
            // height: parent.height
            // anchors{fill: parent; margins:5;}
            ListView{
                id: vw
                // width: parent.width
                // height: parent.height
                property var total: []
                anchors.fill: parent
                model: dataModel
                delegate:
                    Row{
                        width:vw.width
                        spacing: 5
                        Label{ text:tm.substring(8); }
                        // Label{ text:bind; }
                        Label{ text:acntcdt.substring(acntcdt.indexOf("/")+1); }
                        Label{text:Math.abs(amnt); horizontalAlignment: Qt.AlignRight; color:Number(amnt) < 0 ? "red" : "black";}
                        // Label{ text:client; }
                    }
                ScrollBar.vertical: ScrollBar{
                    parent: vw.parent
                    anchors.top: vw.top
                    anchors.left: vw.right
                    anchors.bottom: vw.bottom
                }
                section.property: "bind"
                section.criteria: ViewSection.FullString
                section.delegate: Rectangle{
                    width: vw.width
                    height: /*40  //*/childrenRect.height//*1.2
                    color: "silver"
                    RowLayout{
    //                        anchors.fill: parent
                        width: vw.width-10
                        Label{
                            Layout.fillWidth: true
                            text:'  '+section
                        }
                        Label{
                            text: model.getTotal(section).toLocaleString(Qt.locale(),'f',0)
                            color: (model.getTotal(section) < 0) ? 'red' : 'black'
    //                        horizontalAlignment: Text.AlignRight
                        }
                    }
                }
            }

        // }

    }
}
