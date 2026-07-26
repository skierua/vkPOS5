import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Controls

// import com.singleton.dbdriver4 1.0
import "../lib.js" as Lib

Window {
    id: root
    width: 480
    height: 480

    property var dbDriver                 // DataBase driver
    onDbDriverChanged: {
        // vw.model.populate(dbDriver)
        loadAction.trigger()
    }

    property var prnDriver                 // printer manager

/*    property bool fiscMode
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
*/

/*    property string sqlFilter: "select pkey as id, clchar as name, coalesce('tel.'||phone,'') || coalesce(' '||clnote,'')  as fullname, '' as scancode, 64 as mask, 'Клієнти' as sect, '0' as odr from client "
    +"union select item.pkey as id, itemchar as name, coalesce(itemname, itemnote,'') as fullname, coalesce(scancode,'') as scancode, itemmask as mask, case when itemmask=4 then 'Товари' else 'Валюти' end as sect, '1' as odr from item where folder = 0 "
    +"union select acntno as id, acntno||'-'||coalesce(acntnote,'['||balname||']','') as name, '' as fullname, '' as scancode, 128 as mask, 'Рахунки' as sect, '3' as odr from acntbal left join balname on(substr(acntno,1,2)=bal) where client is null "
    +"order by odr, sect,itemmask,name;";
*/
    // property alias sqlMode : vw.sm // mode=EMPTY|1|2|4|64(client)|128(acnt)

    signal vkEvent(string eventId, var eventParam)

    ModelDbDcms{
        id: dataModel
        pageCapacity: 25
    }

    Action {
        id: previousAction
        enabled: Number(vcrntEdit.text) > vcrntEdit.validator.bottom
        text: "❮"
        onTriggered: vcrntEdit.text = Number(vcrntEdit.text) -1
    }

    Action {
        id: nextAction
        enabled: vw.model !== null && Number(vcrntEdit.text) !== vw.model.pager.length
        text: "❯"
        onTriggered: vcrntEdit.text = Number(vcrntEdit.text) +1
    }

    Action {
        id: loadAction
        // text: "🔄"
        icon.source:"qrc:/icon/reload.svg"
        onTriggered: {
            vfilterEdit.text = ""
            if (dbDriver !== undefined) dataModel.load(dbDriver, findInterval.model.get(findInterval.currentIndex).filter)
        }
    }

    Action {
        id: bindModeAction
        text: qsTr("Bind")
        checkable: true
        checked: true
        onTriggered: { vw.section.property = (checked ? "pid" : "")}
    }

    Action {
        id: viewFullBindAction
        text: "Показати весь чек"
        onTriggered: vw.model.showFullBind(vw.currentIndex)
    }

    Action {
        id: refuseAction
        // enabled: vw.model.get(vw.currentIndex).trade === "1"
        text: "Повернути"
        onTriggered: {
            const dcm = vw.model.dcmForRefuse(vw.currentIndex)
            // console.log(`DcmView#hys70 res=${JSON.stringify(dcm)}`); return;
            if (dcm){
                vkEvent("refuse", dcm);
            } else logView.append("[bindForPrint] Dcm refuse error", 0)
        }
    }

    Action {
        id: actionPrintCheck
        text: "Друкувати чек"
        onTriggered: {
            const jbind = vw.model.bindForPrint(vw.currentIndex)
            // console.log(`DcmView#d7hf res=${JSON.stringify(jbind)}`); return;
            if (jbind){
                prnDriver.saveCheckCopy( jbind )
                prnDriver.printCheckCopy( jbind )
            } else logView.append("[bindForPrint] Bind retrieving error", 0)
        }
    }

    Action {
        id: actionPrintOrder
        text: "Зберегти накладну"
        onTriggered: {
            const jbind = vw.model.bindForPrint(vw.currentIndex)
            if (jbind){
                prnDriver.saveOrder( jbind )
            } else logView.append("[bindForPrint] Bind retrieving error", 0)
        }
    }

/*    Action {
        id: actionFiscalizate
        enabled: false
        text: "Фіскалізувати"
        onTriggered: { vkEvent("docum.fiscCheck", vw.model.get(vw.currentIndex).bind); }
    }
*/

    Component {
        id: dlg
        FocusScope{
            id: rootDlg
            width: rootDlg.ListView.view.width;
            height: childrenRect.height;
            // readonly property bool isTrade: eqamount !== 0 || dcmtype.startsWith("trade:")
            readonly property real dcmPrice: Number(eqamount || 0)/Number(amount || 1)
            MouseArea{
                anchors.fill: parent;
                onClicked: {vw.currentIndex = index;}
                // onDoubleClicked: {vw.currentIndex = index; viewFullBindAction.trigger(); }
            }
            Item {
//             width: rootDlg.ListView.view.width //childrenRect.width;
                width:parent.width;
                height: 32;
                clip: true
                // color: (index === vw.currentIndex) ?  'lightsteelblue' : (match ? 'honeydew' : 'white')
                //                                         // (index%2 == 0 ?  Qt.darker('white',1.01) : 'white')
                Row{
                    anchors{fill: parent; margins: 1}
                    spacing: 2
                    Text{ width: 0.05*parent.width;
                        anchors.verticalCenter: parent.verticalCenter;
                        horizontalAlignment: Text.AlignHCenter;
                        text: Number(amount) > 0 ? "+" : "-" }

                    Column{     // name
                        width: (isTrade ?  0.4 * parent.width - 2 : 0.7 * parent.width - 4);
                        spacing: 2
                        clip:true
                        Text {
                            clip: true
                            font.italic: !flt
                            text: isTrade ? (dcmnote.indexOf("#") === -1
                                    ? '['+ itemchar + '] '+ dcmnote
                                    : dcmnote.substring(0,dnote.indexOf("#")))
                                : dcmnote
                        }
                        Row{
                            spacing: 2
                            Text {
                                clip: true
                                text: dcmid
                                font{pointSize: 10; italic: !flt}
                                color: 'gray'
                            }
                            Text{
                                text: '['+ acntcdt + ']'
                                font{pointSize: 10; italic: !flt}
                                color: 'gray'
                            }
                        }
                    }

                    Column{     // price, eq,...
                        visible: isTrade
                        width: visible ? 0.3 * parent.width - 2 : 0;
                        spacing: 2
                        clip: true
                        Text {
                            font.italic: !flt
                            text: rootDlg.dcmPrice.toFixed(4)
                            // text: rootDlg.ListView.view.model.price(index)
                        }
                        Row{
                            Text {
                                font{pointSize: 10; italic: !flt}
                                color: 'dimgray'
                                text: Math.abs(Number(eqamount)).toLocaleString(Qt.locale(),'f',2)
                            }
                            Text {
                                text:Number(discount)===0?'':('D:'+Math.abs(Number(discount)).toLocaleString(Qt.locale(),'f',2))
                                font{pointSize: 10; italic: !flt}
                                color: 'dimgray'
                            }
                            Text {
                                text:Number(bonus)===0?'':('B:'+Math.abs(Number(bonus)).toLocaleString(Qt.locale(),'f',2))
                                font{pointSize: 10; italic: !flt}
                                color: 'dimgray'
                            }
                        }
                    }

                    Text {
                        width: 0.25*parent.width-4;
                        anchors.verticalCenter: parent.verticalCenter;
                        horizontalAlignment: Text.AlignRight
                        font{pointSize: 14; italic: !flt}
                        text:Math.abs(Number(amount)).toLocaleString(Qt.locale(),'f',Number(unitprec))
                    }
                }
            }
        }
    }

    Component {
        id: highlight
        Rectangle {
            width: vw.width; height: 32
            color: "lightsteelblue"; radius: 5
            y: vw.currentItem === null ? null : vw.currentItem.y
            Behavior on y {
                SpringAnimation {
                    spring: 3
                    damping: 0.2
                }
            }
        }
    }

    Component {
        id: secDlg
        Rectangle{
            id: rootSec
            width: rootSec.ListView.view.width
            height: 34  //childrenRect.height //*1.2
            color: "whitesmoke"
            Row{
                anchors{fill: parent; margins:1}
                spacing: 2
                Text{
                    width:parent.width * 0.4;
                    anchors.verticalCenter: parent.verticalCenter;
                    font.pointSize: 15;
                    text: rootSec.ListView.view.model.bindInfo(section).dcmtype}
                Column{
                    width:parent.width * 0.3 -2;
                    Text{ text: Number(rootSec.ListView.view.model.bindInfo(section).amount).toLocaleString(Qt.locale(),'f',2)}
                    Row{
                        spacing: 2
                        Text{ font.pointSize: 10; color: 'gray'; text: rootSec.ListView.view.model.bindInfo(section).eqamount}
                        Text{ font.pointSize: 10; color: 'gray'; text: rootSec.ListView.view.model.bindInfo(section).discount}
                        Text{ font.pointSize: 10; color: 'gray'; text: rootSec.ListView.view.model.bindInfo(section).bonus}
                    }

                }
                // Item{  }
                Text{
                    width:parent.width * 0.15 -4;
                    anchors.verticalCenter: parent.verticalCenter;
                    font.pointSize: 12;
                    clip: true
                    elide: Text.ElideRight
                    text: rootSec.ListView.view.model.bindInfo(section).clid
                }
                Column{
                    width:parent.width * 0.15 -2;
                    Text{
                        width: parent.width
                        // anchors.right: parent.right;
                        // font.pointSize: 12;
                        horizontalAlignment: Text.AlignRight
                        clip: true
                        elide: Text.ElideLeft
                        text: rootSec.ListView.view.model.bindInfo(section).dcmtime.substring(11,16)
                    }
                    Text{
                        width: parent.width
                        // anchors.right: parent.right;
                        horizontalAlignment: Text.AlignRight
                        clip: true
                        elide: Text.ElideLeft
                        text: rootSec.ListView.view.model.bindInfo(section).dcmtime.substring(0,10)
                    }
                }

            }

        }

    }

    Page{
        anchors.fill: parent
        Pane{
            anchors.fill: parent
            ListView{
                id: vw
                anchors{fill: parent; /*margins:2*/}
                clip: true
                spacing: 1
                model: dataModel
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
                ScrollBar.vertical: ScrollBar{
                    parent: vw.parent
                    anchors.top: vw.top
                    anchors.left: vw.right
                    anchors.bottom: vw.bottom
                }
                section.property: "pid"
                section.criteria: ViewSection.FullString
                section.delegate: secDlg
                highlight: highlight
                highlightFollowsCurrentItem: false
                focus: true
            }

            LogView{
                id: logView
                width: parent.width
                height: (count * 25 < parent.height / 4) ? count * 25 : parent.height / 4
                z: 10
                anchors.bottom: parent.bottom
            }
        }

        header: ToolBar {
            RowLayout {
                anchors.fill: parent
                ToolButton{
                    action: loadAction
//                    font.pixelSize: 24;
                }

                Label {
                    id: headerTitle
                    // text: sqlMode.text
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
                        ListElement { text: "за зміну"; table: "docum"; filter: "shftid = 0" }
                        ListElement { text: "2 тижні"; table: "documall"; filter: "dcmtime >= date('now', '-14 day')" }
                        ListElement { text: "місяць"; table: "documall"; filter:"dcmtime >= date('now', '-1 month')" }
                        ListElement { text: "квартал"; table: "documall"; filter:"dcmtime >= date('now', '-3 month')" }
                        ListElement { text: "рік"; table: "documall"; filter:"dcmtime >= date('now', '-1 year')" }
                        ListElement { text: "з поч.місяця"; table: "documall"; filter:"dcmtime >= date('now','start of month')" }
                        ListElement { text: "з поч.року"; table: "documall"; filter:"dcmtime >= date('now','start of year')" }
                        ListElement { text: "весь період"; table: "documall"; filter:"" }
                    }
                    textRole: 'text'
                    valueRole: 'filter'
                    onCurrentIndexChanged: loadAction.trigger()
                }
                ToolButton {    // ⋮
                    text: qsTr("⋮")
                    onClicked: {
                        contextMenu.open()
                    }
                    Menu{
                        id: contextMenu
                        // MenuItem { action: clearFilterAction; }
                        MenuItem { action: viewFullBindAction; }
                        MenuItem { action: refuseAction; }
                        MenuSeparator { padding: 5; }
                        MenuItem { action: actionPrintCheck; }
                        MenuItem { action: actionPrintOrder; }
                        MenuSeparator { padding: 5; }
                        MenuItem { action: bindModeAction; }
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
                    // text: vw.vfilter
                    onAccepted: {
                        vw.model.filterData(text)
                        vcrntEdit.text = 1
                    }
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
                    validator: IntValidator {bottom: 1; }
                    onActiveFocusChanged: if (activeFocus) { selectAll(); }
                    horizontalAlignment: Text.AlignHCenter
                    text: "1"
                    onTextChanged: {
                        if (Number(text) > vw.model.pager.length ) text = vw.model.pager.length
                        vw.model.populate(text)
                    }
                }
                ToolButton{ action: nextAction; }

                Label{
                    id: footerCount
                    // text: String(" з %1 (%2)").arg(Math.ceil(vw.bindList.length/vw.vlen)).arg(vw.bindList.length)
                    text: String(" з %1 (%2)")
                    .arg(vw.model === null ? 0 : vw.model.pager.length)
                    .arg(vw.model === null ? 0 : vw.model.bindCount)
                }
            }
        }
    }



    Component.onCompleted: {
        // statusChanged.connect(handleComponentStatusChange) //console.log("status="+ root.status
        // Db.msg("Test message FROM DcmView.");
        // console.log("#73h main TEST fiscMode="+ fiscMode)

        // contextMenu.addAction(clearFilterAction)
        // contextMenu.addAction(viewFullBindAction)
        // contextMenu.addAction(refuseAction)
        // contextMenu.addItem( Qt.createQmlObject('import QtQuick.Controls; MenuSeparator {}', contextMenu.contentItem, "dynamicSeparator") )
        // contextMenu.addAction(actionPrintCheck)
        // contextMenu.addAction(actionPrintOrder)
        // contextMenu.addItem( Qt.createQmlObject('import QtQuick.Controls; MenuSeparator {}', contextMenu.contentItem, "dynamicSeparator") )
        // contextMenu.addAction(bindModeAction)
    }

}

