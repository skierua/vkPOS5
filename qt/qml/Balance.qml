import QtQuick
import QtQuick.Controls
// import QtQuick.Controls.Fusion
import QtQuick.Layouts

Window {
    id: root
    width: 720
    height: 720

    property var dbDriver                 // DataBase driver
    onDbDriverChanged: {
        // loadAction.trigger()
    }
    property real zero: 0.0000001

    function dbg(str, code ="") {
        console.log( String("[Balance.qml]#%1 %2").arg(code).arg(str));
    }

    Action {
        id: previousAction
        enabled: Number(vcrntEdit.text) > vcrntEdit.validator.bottom
        text: "❮"
        onTriggered: {
            vcrntEdit.text = Number(vcrntEdit.text) -1
            vw.model.populate(vcrntEdit.text)
        }
    }

    Action {
        id: nextAction
        enabled: vw.model !== null
                 && vw.model.data !== undefined
                 && Number(vcrntEdit.text) < Math.ceil(vw.model.data.length / vw.model.pageCapacity)
        text: "❯"
        onTriggered: {
            vcrntEdit.text = Number(vcrntEdit.text) +1
            vw.model.populate(vcrntEdit.text)
        }
    }


    Action {
        id: loadStockAction
        text: qsTr("Stock")
        onTriggered: {
            // vfilterEdit.text = ""
            headerTitle.text = text
            vw.balAcnt = "300"
            vw.load()
        }
    }

    Action {
        id: loadBrackAction
        text: qsTr("Brack")
        onTriggered: {
            // vfilterEdit.text = ""
            headerTitle.text = text
            vw.balAcnt = "302"
            vw.load()
        }
    }

    Action {
        id: loadTradeAction
        text: qsTr("TRADE")
        onTriggered: {
            // vfilterEdit.text = ""
            headerTitle.text = text
            vw.balAcnt = "3500"
            vw.load()
        }
    }

    Action {
        id: loadBulkAction
        text: qsTr("BULK")
        onTriggered: {
            // vfilterEdit.text = ""
            headerTitle.text = text
            vw.balAcnt = "3501"
            vw.load()
        }
    }

    Action {
        id: sortAction
        onTriggered: source => {
            vw.sortOrder = source.order
            vw.load()
        }
    }

    Action {
        id: sortByIdAction
        property string order: "id"
        text: qsTr("Sort by ID")
        onTriggered: sortAction.trigger(sortByIdAction)
    }

    Action {
        id: sortByNameAction
        property string order: "name"
        text: qsTr("Sort by name")
        onTriggered: sortAction.trigger(sortByNameAction)
    }

    Action {
        id: sortByCostAction
        property string order: "cost"
        text: qsTr("Sort by cost")
        onTriggered: sortAction.trigger(sortByCostAction)
    }

    Action {
        id: sortByDateinAction
        property string order: "datein"
        text: qsTr("Sort by income date")
        onTriggered: sortAction.trigger(sortByDateinAction)
    }

    Action {
        id: sortByDateoutAction
        property string order: "dateout"
        text: qsTr("Sort by outcome date")
        onTriggered: sortAction.trigger(sortByDateoutAction)
    }

    ModelBalance{
        id: dataModel
    }


    Component {
        id: vwHeader
        Rectangle{
            id : root
            width: root.ListView.view.width //childrenRect.width;
            height: 30
            opacity: 0.7
            RowLayout{
                anchors{fill:parent}
                spacing: 5
                Item{
                    // color:"orange"
                    Layout.preferredWidth: 60
                    Layout.fillHeight: true
                    Row{
                        anchors{centerIn: parent}
                        // anchors.horizontalCenter: parent.horizontalCenter
                        // anchors.verticalCenter: parent.verticalCenter
                        Label{
                            text: "ID"
                            // background: Rectangle{color:"khaki"}
                        }
                        ToolButton{
                            width: 20
                            height: 20
                            visible: root.ListView.view.sortOrder === "id"
                            text:"↑"
                        }

                    }
                    MouseArea{
                        anchors.fill: parent
                        onDoubleClicked: root.ListView.view.sortOrder = "id"
                    }
                }
                Item{
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Row{
                        anchors{centerIn: parent}
                        Label{
                            text: qsTr("NAME")
                        }
                        ToolButton{
                            width: 20
                            height: 20
                            visible: root.ListView.view.sortOrder === "name"
                            text:"↑"
                        }

                    }
                    MouseArea{
                        anchors.fill: parent
                        onDoubleClicked: root.ListView.view.sortOrder = "name"
                    }
                }

                Label{
                    Layout.preferredWidth: 60
                    horizontalAlignment: Text.AlignHCenter
                    text: "QTY"
                    // font.bold: true
                    // background: Rectangle{color:"khaki"}
                }
                Label{
                    Layout.preferredWidth: 60
                    horizontalAlignment: Text.AlignHCenter
                    text: "PRICE"
                    MouseArea{
                        anchors.fill: parent
                        hoverEnabled :true
                        ToolTip{
                            id: headerPriceToolTip
                            delay: 1000
                            timeout: 5000
                            text: qsTr("Current sell price")
                        }
                        onEntered: headerPriceToolTip.visible = true
                        onExited: headerPriceToolTip.visible = false
                    }
                }
                Item{
                    Layout.preferredWidth: 60
                    Layout.fillHeight: true
                    Row{
                        anchors{centerIn: parent}
                        Label{
                            text: qsTr("COST")
                        }
                        ToolButton{
                            width: 20
                            height: 20
                            visible: root.ListView.view.sortOrder === "cost"
                            text:"↓"
                        }

                    }
                    MouseArea{
                        anchors.fill: parent
                        onDoubleClicked: root.ListView.view.sortOrder = "cost"
                        hoverEnabled :true
                        ToolTip{
                            id: headerCostToolTip
                            delay: 1000
                            timeout: 5000
                            text: qsTr("Cost in stock")
                        }
                        onEntered: headerCostToolTip.visible = true
                        onExited: headerCostToolTip.visible = false
                    }
                }
                Item{
                    Layout.preferredWidth: 60
                    Layout.fillHeight: true
                    Row{
                        anchors{centerIn: parent}
                        Label{
                            text: qsTr("D-IN")
                        }
                        ToolButton{
                            width: 20
                            height: 20
                            visible: root.ListView.view.sortOrder === "datein"
                            text:"↓"
                        }

                    }
                    MouseArea{
                        anchors.fill: parent
                        onDoubleClicked: root.ListView.view.sortOrder = "datein"
                        hoverEnabled :true
                        ToolTip{
                            id: headerDinToolTip
                            delay: 1000
                            timeout: 5000
                            text: qsTr("Last income date")
                        }
                        onEntered: headerDinToolTip.visible = true
                        onExited: headerDinToolTip.visible = false
                    }
                }
                Item{
                    Layout.preferredWidth: 60
                    Layout.fillHeight: true
                    Row{
                        anchors{centerIn: parent}
                        Label{
                            text: qsTr("D-OUT")
                        }
                        ToolButton{
                            width: 20
                            height: 20
                            visible: root.ListView.view.sortOrder === "dateout"
                            text:"↓"
                        }

                    }
                    MouseArea{
                        anchors.fill: parent
                        onDoubleClicked: root.ListView.view.sortOrder = "dateout"
                        hoverEnabled :true
                        ToolTip{
                            id: headerDoutToolTip
                            delay: 1000
                            timeout: 5000
                            text: qsTr("Last outcome date")
                        }
                        onEntered: headerDoutToolTip.visible = true
                        onExited: headerDoutToolTip.visible = false
                    }
                }
            }

        }
    }


    Component {
        id: dlg
        FocusScope {
            id: root
            width: root.ListView.view.width //childrenRect.width;
            height: 28;
            Rectangle{
                width: vw.width
                height: childrenRect.height * 1.2
                // height: 35       //visible ? childrenRect.height+2 : 0
                clip: true
                Row{
                    width: parent.width
                    spacing: root.ListView.view.headerItem.children[0].spacing
                    Text{
                        width: root.ListView.view.headerItem.children[0].children[0].width //- parent.spacing
                        text: item.id
                    }
                   Text{
                       width: root.ListView.view.headerItem.children[0].children[1].width //- parent.spacing
                       text: item.itemchar
                       clip: true
                   }
                   Text{
                       width: root.ListView.view.headerItem.children[0].children[2].width //- parent.spacing
                       horizontalAlignment: Text.AlignRight
                       // anchors.horizontalCenter: parent.horizontalCenter
                       text: Math.abs(Number(total)).toLocaleString(Qt.locale(),'f', Number(item.unitprec))
                       color: Number(total) < 0 ? 'red' : 'black'
                   }
                   Text{
                       width: root.ListView.view.headerItem.children[0].children[3].width //- parent.spacing
                       horizontalAlignment: Text.AlignRight
                       text: price.toFixed(price < 10 ? 2 : 0)
                       clip: true
                   }
                   Text{
                       width: root.ListView.view.headerItem.children[0].children[4].width //- parent.spacing
                       horizontalAlignment: Text.AlignRight
                       text: Math.abs(price * Number(total)).toLocaleString(Qt.locale(),'f', 0)
                       clip: true
                       color: (price * Number(total)) < 0 ? 'red' : 'black'
                   }

                   Text{
                       width: root.ListView.view.headerItem.children[0].children[5].width //- parent.spacing
                       horizontalAlignment: Text.AlignRight
                       text: root.ListView.view.humanDate(intm)
                       clip: true
                   }
                   Text{
                       width: root.ListView.view.headerItem.children[0].children[6].width //- parent.spacing
                       // width: 60    //parent.width *0.15 - parent.spacing
                       horizontalAlignment: Text.AlignRight
                       text: root.ListView.view.humanDate(outm)
                       clip: true
                   }
                }
            }

        }
    }

    Page{
        anchors.fill: parent
        Pane{
            anchors.fill: parent;


            ListView{
                id: vw
                property string balAcnt
                // onBalAcntChanged: load()
                property string sortOrder: "id" // id | name | cost | datein | dateout
                onSortOrderChanged: load()

                anchors.fill: parent
                // property var totalEq: []
                // Layout.fillHeight: true
                // Layout.fillWidth: true
                spacing: 1
                clip: true
                // model: ListModel{ }
                model: dataModel
                header: vwHeader
                delegate: dlg
                add: Transition {
                        NumberAnimation { properties: "x,y"; from: 100; duration: 300 }
                    }
                addDisplaced: Transition {
                        NumberAnimation { properties: "x,y"; duration: 300 }
                    }
                remove: Transition {
                        ParallelAnimation {
                            NumberAnimation { property: "opacity"; to: 0; duration: 300 }
                            NumberAnimation { properties: "x,y"; to: 100; duration: 300 }
                        }
                    }
                removeDisplaced: Transition {
                        NumberAnimation { properties: "x,y"; duration: 300 }
                    }
                section.property: "bind"
                section.criteria: ViewSection.FullString
                section.delegate: Rectangle{
                    width: vw.width
                    height: 30  // childrenRect.height   //*1.2
                    color: "lightgrey" //"silver"
                    Item {
                        anchors{fill: parent;}
                        Row {
                            anchors{fill: parent;leftMargin: 10; rightMargin: 10}
                            spacing: 5
                            Text{
                                width: parent.width - 100 - parent.spacing
                                anchors{verticalCenter: parent.verticalCenter;leftMargin: 50}
                                text:section.substring(section.lastIndexOf("/") +1)
                //                    font.bold: true
                                font.pixelSize: 14
                            }
                            Text{
                                width: 100
                                anchors{verticalCenter: parent.verticalCenter;leftMargin: 50}
                                horizontalAlignment: Text.AlignRight
                                text: vw.model.getTotal(section).toLocaleString(Qt.locale(),'f', 0)
                //                    font.bold: true
                                font.pixelSize: 14
                            }

                        }

                    }
                }

                function load(){
                                   // if (root.filter === undefined) return
                     // dbg("molel load flt=["+(root.filter===""? "EMPTY":"NO EMPTY")+"]","s78")
                    vcrntEdit.text = 1
                    model.load(root.dbDriver,
                                 balAcnt || "300",
                                 sortOrder || "",
                                 vfilterEdit.text
                                 )
                    footerCount.text = String(" з %1").arg(Math.ceil(vw.model.data.length / vw.model.pageCapacity))
                }

                function humanDate(vdate) {
                    var vtmp = Date()
                    var vdiff = Math.floor(((new Date().getTime())-(new Date(String(vdate).substring(0,10)).getTime()))/(1000*60*60*24))
                    if (vdiff === 0) { return vdate.substring(11,16) // Qt.formatDate(new Date(vdate), 'hh:mm')
                    } else if (vdiff === 1) { return 'вч '+vdate.substring(11,16)  //Qt.formatDate(new Date(vdate), 'вч hh:mm')
                    // } else if (vdiff < 8) { return Math.floor(((new Date().getTime())-(new Date(String(vdate).substring(0,10)).getTime()))/(1000*60*60*24))+' дн.'
                    } else if (vdiff < 360) { return Qt.formatDate(new Date(vdate), 'dd MMM')
                    } else { return Qt.formatDate(new Date(vdate), 'MMM yy'); /*String(vdate).substring(0,10);*/ }

                }
            }

        }

        header: ToolBar {
            id: appToolBar
            height: 32
            Rectangle{
                width: parent.width
                height: childrenRect.height // 30

                RowLayout {
                    width: parent.width
                    // anchors.fill: parent
                    ToolButton {
                        // action: loadAction
                        text: "☰"
                        onClicked: naviMenu.open()
                        Menu {
                            id: naviMenu
                            y: parent.height
                            MenuItem { action: loadStockAction; }
                            MenuItem { action: loadBrackAction; }
                            MenuItem { action: loadTradeAction; }
                            MenuItem { action: loadBulkAction; }
                        }
                    }
                    Label {
                        id: headerTitle
                        elide: Label.ElideRight
                        horizontalAlignment: Qt.AlignHCenter
                        verticalAlignment: Qt.AlignVCenter
                        Layout.fillWidth: true
                        font.pointSize: 20
                        // text: stack.currentItem.title
                    }

                    // Item{
                    //     Layout.fillWidth: true
                    //     Text{
                    //         id: title
                    //         anchors{horizontalCenter: parent.horizontalCenter; verticalCenter: parent.verticalCenter }
                    //         font.pointSize: 20
                    //     }
                    // }
                    // Item{
                    //     Layout.fillWidth: true
                    // }

                    ToolButton {
                        // id: contextMenu
                        text: "⋮"
                        onClicked: toolMenu.open()
                        Menu {
                            id: toolMenu
                            y: parent.height
                            MenuItem { action: sortByIdAction; }
                            MenuItem { action: sortByNameAction; }
                            MenuItem { action: sortByCostAction; }
                            MenuItem { action: sortByDateinAction; }
                            MenuItem { action: sortByDateoutAction; }
                        }
                    }
                }
            }

        }


        footer: ToolBar {
            RowLayout {
                anchors{fill: parent;leftMargin:10; rightMargin:10;}
                TextField{
                    id: vfilterEdit
                    Layout.preferredWidth: 100
//                    focus: true
                    selectByMouse: true
                    onActiveFocusChanged: if (activeFocus) {selectAll()}
                    horizontalAlignment: Text.AlignHCenter
                    placeholderText: "filter"
                    // text: vw.vfilter
                    // onAccepted: {
                    onEditingFinished: {
                        vw.load()
                    }
                }
                Item{
                    Layout.fillWidth: true
                }
                RowLayout {
                    ToolButton{ action: previousAction; }
                    TextField{
                        id: vcrntEdit
                        Layout.preferredWidth: 50
    //                    focus: true
                        selectByMouse: true
                        validator: IntValidator {bottom: 1; }
                        onActiveFocusChanged: if (activeFocus) { selectAll(); }
                        horizontalAlignment: Text.AlignHCenter
                        text: "1"
                        // onTextChanged: {
                        onEditingFinished: {
                            if (Number(text) > Math.ceil(vw.model.data.length / vw.model.pageCapacity) ) text = Math.ceil(vw.model.data.length / vw.model.pageCapacity)
                            vw.model.populate(text)
                        }
                    }
                    ToolButton{ action: nextAction; }

                }


                Label{
                    id: footerCount
                    // text: String(" з %1").arg(vw.model === null ? 0 : Math.ceil(vw.model.data.length / vw.model.pageCapacity))
                }
            }
        }
    }

}
