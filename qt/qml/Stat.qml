import QtQuick
import QtQuick.Controls.Fusion
import QtQuick.Layouts

Window {
    id: root
    width: 200  //parent.width *0.5
    height: 400 //parent.height *0.3
    property var jsdata
    onJsdataChanged: vw.spopulate()

    signal vkEvent(string id, var param)


    // Pane {
        // anchors.fill: parent
        Rectangle{
            // width: parent.width
            // height: parent.height
            anchors{fill: parent; margins:5;}
            ListView{
                id: vw
                // width: parent.width
                // height: parent.height
                property var total: []
                anchors.fill: parent
                model: ListModel{}
                delegate:
                    Row{
                        width:vw.width
                        spacing: 5
                        Label{ text:tm.substring(8); }
                        // Label{ text:bind; }
                        Label{ text:acntcdt.substring(acntcdt.indexOf("/")+1); }
                        Label{text:Math.abs(amnt); horizontalAlignment: Qt.AlignRight; color:Number(amnt)<0?"red":"black";}
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
                            // font.pixelSize: 12
                        }
                        Label{
    //                        Layout.minimumWidth: 70
                            text: vw.total[section]!==undefined?("= "+Number(vw.total[section]).toLocaleString(Qt.locale(),'f',0)):''
                            // font.pixelSize: 12
                            color: (vw.total[section]===undefined||Number(vw.total[section])<0)? 'red':'black'
    //                        horizontalAlignment: Text.AlignRight
                        }
                    }
                }

                function spopulate() {
                    // console.log("#4jm Stat jsdaata="+JSON.stringify(jsdata))
                    total = []
                    var srow = ({})
                    let i=0
                    for (let r=0; r< jsdata.length; ++r){
                        srow = jsdata[r];
                        srow.bind = jsdata[r].tm.substring(0,7)
                        if (total[srow.bind] === undefined) { total[srow.bind] = Number(jsdata[r].amnt);
                        } else { total[srow.bind] +=  Number(jsdata[r].amnt); }
                        // for (i=0; i < total.length && total[i].bind !== srow.bind; ++i) {}
                        // if (i == total.length) { total.push({"bind":srow.bind, "amnt": Number(jsdata[r].amnt)});
                        // } else { total[i].amnt +=  Number(jsdata[r].amnt); }
                        model.append(srow)
                    }
                }
            }

        }

    // }
}
