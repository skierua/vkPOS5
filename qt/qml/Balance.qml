import QtQuick
import QtQuick.Controls
// import QtQuick.Controls.Fusion
import QtQuick.Layouts

import "js/balance.js" as JS;

Window {
    id: balanceRoot
    width: 720
    height: 720

    property var dbDriver: null                 // DataBase driver
    // property real zero: 0.0000001

    property int countPage: 1
    Action {
        id: previousAction
        enabled: Number(vcrntEdit.text) > (vcrntEdit.validator ? vcrntEdit.validator.bottom : 1)
        text: "❮" // ◀ Стабільна Юнікод-стрілка «назад» (підтримується всіма ОС)
        onTriggered: {
            const currentPage = parseInt(vcrntEdit.text) || 1;
            vcrntEdit.text = String(currentPage - 1);
            JS?.populate?.(vw.model, vcrntEdit.text);
        }
    }

    Action {
        id: nextAction
        enabled: Number(vcrntEdit.text) < (vcrntEdit.validator ? vcrntEdit.validator.top : balanceRoot.countPage)
        text: "❯" // ▶ Стабільна Юнікод-стрілка «вперед»
        onTriggered: {
            const currentPage = parseInt(vcrntEdit.text) || 1;
            vcrntEdit.text = String(currentPage + 1);
            JS?.populate?.(vw.model, vcrntEdit.text);
        }
    }


    Action {
        id: loadAction
        onTriggered: source => {
            const brige = {
                 bal: source.bal,
                 setPages: (v) => { balanceRoot.countPage = Number(v || 1);},
             }
            headerTitle.text = source?.text || "Unknown"
            JS.load(dbDriver, vw.model, brige);
        }
    }

    Action {
        id: loadStockAction
        property string bal: "300"
        text: qsTr("Stock")
        onTriggered: loadAction.trigger(loadStockAction)
    }

    Action {
        id: loadBrackAction
        property string bal: "302"
        text: qsTr("Брак")
        onTriggered: loadAction.trigger(loadBrackAction)
    }

    Action {
        id: loadTradeAction
        property string bal: "3500"
        text: qsTr("TRADE")
        onTriggered: loadAction.trigger(loadTradeAction)
    }

    Action {
        id: loadBulkAction
        property string bal: "3501"
        text: qsTr("BULK")
        onTriggered: loadAction.trigger(loadBulkAction)
    }

    Action {
        id: sortByIdAction
        property string code: "id"
        checkable: true
        checked: vw.sortOrder === sortByIdAction.code || !vw.sortOrder
        text: qsTr("Sort by ID")
        onTriggered: vw.sortOrder = sortByIdAction.code;
    }

    Action {
        id: sortByNameAction
        property string code: "name"
        checkable: true
        checked: vw.sortOrder === sortByNameAction.code
        text: qsTr("Sort by name")
        onTriggered: vw.sortOrder = sortByNameAction.code;
    }

    Action {
        id: sortByCostAction
        property string code: "cost"
        checkable: true
        checked: vw.sortOrder === sortByCostAction.code
        text: qsTr("Sort by cost")
        onTriggered: vw.sortOrder = sortByCostAction.code;
    }

    Action {
        id: sortByDateinAction
        property string code: "datein"
        checkable: true
        checked: vw.sortOrder === sortByDateinAction.code
        text: qsTr("Sort by income date")
        onTriggered: vw.sortOrder = sortByDateinAction.code;
    }

    Action {
        id: sortByDateoutAction
        property string code: "dateout"
        checkable: true
        checked: vw.sortOrder === sortByDateoutAction.code
        text: qsTr("Sort by outcome date")
        onTriggered: vw.sortOrder = sortByDateoutAction.code;
    }

    Component {
        id: vwHeader

        Rectangle {
            id: headerRoot

            width: vw.width
            height: 32
            color: "#F3F4F6"
            // Тонка роздільна лінія під шапкою
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: "#D1D5DB"
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 8

                // --- КОЛОНКА ID ---
                Item {
                    Layout.preferredWidth: 60
                    Layout.fillHeight: true

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 2

                        Label {
                            text: "ID"
                            font { pixelSize: 11; bold: true }
                            color: "#4B5563"
                        }
                        ToolButton {
                            id: btnSortId
                            Layout.preferredWidth: 16
                            Layout.preferredHeight: 16
                            flat: true
                            visible: vw.sortOrder === "id"
                            text: "↑"
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onDoubleClicked: vw.sortOrder = "id"
                    }
                }

                // --- КОЛОНКА NAME ---
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 2

                        Label {
                            text: qsTr("НАЗВА")
                            font { pixelSize: 11; bold: true }
                            color: "#4B5563"
                        }
                        ToolButton {
                            Layout.preferredWidth: 16
                            Layout.preferredHeight: 16
                            flat: true
                            visible: vw.sortOrder === "name"
                            text: "↑"
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onDoubleClicked: vw.sortOrder = "name"
                    }
                }

                // --- КОЛОНКА QTY ---
                Label {
                    Layout.preferredWidth: 65
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    Layout.fillHeight: true
                    text: qsTr("К-СТЬ")
                    font { pixelSize: 11; bold: true }
                    color: "#4B5563"
                }

                // --- КОЛОНКА PRICE ---
                Label {
                    id: colPrice
                    Layout.preferredWidth: 65
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    Layout.fillHeight: true
                    text: qsTr("ЦІНА")
                    font { pixelSize: 11; bold: true }
                    color: "#4B5563"

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true

                        ToolTip.delay: 800
                        ToolTip.timeout: 4000
                        ToolTip.visible: containsMouse
                        ToolTip.text: qsTr("Поточний курс продажу")
                    }
                }

                // --- КОЛОНКА COST ---
                Item {
                    Layout.preferredWidth: 65
                    Layout.fillHeight: true

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 2

                        Label {
                            text: qsTr("ЕКВ")
                            font { pixelSize: 11; bold: true }
                            color: "#4B5563"
                        }
                        ToolButton {
                            Layout.preferredWidth: 16
                            Layout.preferredHeight: 16
                            flat: true
                            visible: vw.sortOrder === "cost"
                            text: "↓"
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onDoubleClicked: vw.sortOrder = "cost"

                        ToolTip.delay: 800
                        ToolTip.timeout: 4000
                        ToolTip.visible: containsMouse
                        ToolTip.text: qsTr("Вартість залишку в еквіваленті")
                    }
                }

                // --- КОЛОНКА D-IN ---
                Item {
                    Layout.preferredWidth: 65
                    Layout.fillHeight: true

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 2

                        Label {
                            text: qsTr("Д-ВХ")
                            font { pixelSize: 11; bold: true }
                            color: "#4B5563"
                        }
                        ToolButton {
                            Layout.preferredWidth: 16
                            Layout.preferredHeight: 16
                            flat: true
                            visible: vw.sortOrder === "datein"
                            text: "↓"
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onDoubleClicked: vw.sortOrder = "datein"

                        ToolTip.delay: 800
                        ToolTip.timeout: 4000
                        ToolTip.visible: containsMouse
                        ToolTip.text: qsTr("Дата останнього надходження")
                    }
                }

                // --- КОЛОНКА D-OUT ---
                Item {
                    Layout.preferredWidth: 65
                    Layout.fillHeight: true

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 2

                        Label {
                            text: qsTr("Д-ВИХ")
                            font { pixelSize: 11; bold: true }
                            color: "#4B5563"
                        }
                        ToolButton {
                            Layout.preferredWidth: 16
                            Layout.preferredHeight: 16
                            flat: true
                            visible: vw.sortOrder === "dateout"
                            text: "↓"
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onDoubleClicked: vw.sortOrder = "dateout"

                        ToolTip.delay: 800
                        ToolTip.timeout: 4000
                        ToolTip.visible: containsMouse
                        ToolTip.text: qsTr("Дата останньої видачі / продажу")
                    }
                }
            }
        }
    }

    Component {
        id: dlg

        FocusScope {
            id: delegateRoot
            width: vw.width
            height: 30 // Трохи збільшимо висоту рядка для кращої читаності сум касирами

            Rectangle {
                anchors.fill: parent
                // Ефект «зебри»: підсвічуємо парні рядки для кращої Usability
                color: (index % 2 === 0) ? "#FFFFFF" : "#F9FAFB"
                clip: true

                // Тонка роздільна лінія між рядками валют
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 1
                    color: "#F3F4F6"
                }

                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: 8
                        rightMargin: 8
                    }
                    spacing: 8

                    // --- КОЛОНКА ID (напр. код валюти USD/EUR) ---
                    Text {
                        Layout.preferredWidth: 60
                        text: item && item.id !== undefined ? item.id : ""
                        font.pixelSize: 12
                        color: "#4B5563"
                        verticalAlignment: Text.AlignVCenter
                    }

                    // --- КОЛОНКА NAME (Назва валюти) ---
                    Text {
                        Layout.fillWidth: true
                        text: item && item.itemchar !== undefined ? item.itemchar : ""
                        clip: true
                        font { pixelSize: 12; bold: true }
                        color: "#1F2937"
                        verticalAlignment: Text.AlignVCenter
                    }

                    // --- КОЛОНКА QTY (Кількість залишку на рахунку) ---
                    Text {
                        Layout.preferredWidth: 65
                        horizontalAlignment: Text.AlignRight
                        verticalAlignment: Text.AlignVCenter

                        // Безпечне форматування чисел відповідно до точності валюти (unitprec)
                        text: {
                            let totalNum = Number(total || 0);
                            let precision = item ? Number(item.unitprec || 0) : 0;
                            return Math.abs(totalNum).toLocaleString(Qt.locale(), 'f', precision);
                        }

                        // Якщо мінус на залишку — підсвічуємо чітким червоним кольором
                        color: Number(total || 0) < 0 ? "#DC2626" : "#111827"
                        font { pixelSize: 12; bold: true }
                    }

                    // --- КОЛОНКА PRICE  ---
                    Text {
                        Layout.preferredWidth: 65
                        horizontalAlignment: Text.AlignRight
                        verticalAlignment: Text.AlignVCenter
                        text: {
                            let priceNum = Number(price || 0);
                            return priceNum.toFixed(priceNum < 10 ? 2 : 0);
                        }
                        font.pixelSize: 12
                        color: "#4B5563"
                        clip: true
                    }

                    // --- КОЛОНКА COST (Сумарний еквівалент залишку) ---
                    Text {
                        Layout.preferredWidth: 65
                        horizontalAlignment: Text.AlignRight
                        verticalAlignment: Text.AlignVCenter
                        text: Math.abs(eq).toLocaleString(Qt.locale(), 'f', 0);
                        // {
                        //     let priceNum = Number(price || 0);
                        //     let totalNum = Number(total || 0);
                        //     return Math.abs(priceNum * totalNum).toLocaleString(Qt.locale(), 'f', 0);
                        // }
                        color: (Number(price || 0) * Number(total || 0)) < 0 ? "#DC2626" : "#111827"
                        font { pixelSize: 12; bold: true }
                        clip: true
                    }

                    // --- КОЛОНКА D-IN (Дата надходження) ---
                    Text {
                        Layout.preferredWidth: 65
                        horizontalAlignment: Text.AlignRight
                        verticalAlignment: Text.AlignVCenter
                        // Викликаємо оптимізовану нами раніше функцію конвертації дат
                        text: vw.humanDate(intm)
                        font.pixelSize: 11
                        color: "#6B7280"
                        clip: true
                    }

                    // --- КОЛОНКА D-OUT (Дата видачі) ---
                    Text {
                        Layout.preferredWidth: 65
                        horizontalAlignment: Text.AlignRight
                        verticalAlignment: Text.AlignVCenter
                        text: vw.humanDate(outm)
                        font.pixelSize: 11
                        color: "#6B7280"
                        clip: true
                    }
                }
            }
        }
    }

    Component {
        id: sectDlg

        Rectangle {
            id: rootSect
            width: vw.width
            height: 32
            color: "#E5E7EB" // Сучасний світло-сірий фон роздільника (Tailwind Gray 200)
            // readonly property var viewObj: rootSect.ListView.view
            readonly property var infoObj: JS?.sectInfo?.(section) || null
            // readonly property var sectName: section.includes("/") ? section.substring(section.lastIndexOf("/") + 1) : section

            RowLayout {
                anchors {
                    fill: parent
                    leftMargin: 12
                    rightMargin: 12
                }
                spacing: 10

                Text {
                    Layout.fillWidth: true
                    verticalAlignment: Text.AlignVCenter
                    // Безпечне відсікання назви каси з рядка секції
                    text: rootSect.infoObj.name
                    font { pixelSize: 13; bold: true }
                    color: "#374151"
                }

                Text {
                    Layout.preferredWidth: 120
                    horizontalAlignment: Text.AlignRight
                    verticalAlignment: Text.AlignVCenter
                    // Безпечний виклик підсумку по касі
                    text: rootSect.infoObj?.totaleq || "0"    // JSON.stringify(rootSect.infoObj)  //
                    font { pixelSize: 13; bold: true }
                    color: "#1F2937"
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
                property string sortOrder: "id" // id | name | cost | datein | dateout
                onSortOrderChanged: {
                    // console.log(`II: Balance.qml/onSortOrderChanged sortOrder=${sortOrder}`)
                    vcrntEdit.text = vcrntEdit.validator.bottom;
                    const brige = {
                        order: sortOrder,
                        filter: vfilterEdit.text,
                        setPages: (v) => { balanceRoot.countPage = Number(v || 1);},
                     }
                    JS.setSortId(vw.model, brige)

                }

                anchors.fill: parent
                spacing: 1
                clip: true
                model: ListModel{ }
                header: vwHeader
                delegate: dlg
                add: Transition {
                    NumberAnimation { properties: "x,y"; from: 100; duration: 250; easing.type: Easing.OutQuad }
                }
                addDisplaced: Transition {
                    NumberAnimation { properties: "x,y"; duration: 250; easing.type: Easing.OutQuad }
                }
                remove: Transition {
                    ParallelAnimation {
                        NumberAnimation { property: "opacity"; to: 0; duration: 200 }
                        NumberAnimation { properties: "x,y"; to: 100; duration: 200 }
                    }
                }
                removeDisplaced: Transition {
                    NumberAnimation { properties: "x,y"; duration: 200 }
                }
                section.property: "bind"
                section.criteria: ViewSection.FullString
                section.delegate: sectDlg
/*                section.delegate: Rectangle {
                                    width: vw.width
                                    height: 32
                                    color: "#E5E7EB" // Сучасний світло-сірий фон роздільника (Tailwind Gray 200)

                                    RowLayout {
                                        anchors {
                                            fill: parent
                                            leftMargin: 12
                                            rightMargin: 12
                                        }
                                        spacing: 10

                                        Text {
                                            Layout.fillWidth: true
                                            verticalAlignment: Text.AlignVCenter
                                            // Безпечне відсікання назви каси з рядка секції
                                            text: section.includes("/") ? section.substring(section.lastIndexOf("/") + 1) : section
                                            font { pixelSize: 13; bold: true }
                                            color: "#374151"
                                        }

                                        Text {
                                            Layout.preferredWidth: 120
                                            horizontalAlignment: Text.AlignRight
                                            verticalAlignment: Text.AlignVCenter
                                            // Безпечний виклик підсумку по касі
                                            text: (vw.model && typeof vw.model.getTotal === "function")
                                                  ? vw.model.getTotal(section).toLocaleString(Qt.locale(), 'f', 0)
                                                  : "0"
                                            font { pixelSize: 13; bold: true }
                                            color: "#1F2937"
                                        }
                                    }
                                }*/
                function humanDate(vdate) {
                    if (!vdate) return "";

                    const now = new Date();
                    const checkDate = new Date(String(vdate).substring(0, 10));

                    // Обчислюємо різницю в днях
                    const diffTime = Math.abs(now.getTime() - checkDate.getTime());
                    const vdiff = Math.floor(diffTime / (1000 * 60 * 60 * 24));

                    // Витягуємо час HH:MM із ISO-рядка "YYYY-MM-DD HH:MM:SS"
                    const timeStr = String(vdate).substring(11, 16);

                    if (vdiff === 0) {
                        return timeStr;
                    } else if (vdiff === 1) {
                        return "вч " + timeStr;
                    } else {
                        // Чистий кросплатформовий JS формат для старших дат замість видаленого Qt.formatDate
                        return checkDate.toLocaleDateString("uk-UA", { month: "short", day: "numeric" });
                    }
                }
 /*               function humanDate(vdate) {
                    var vtmp = Date()
                    var vdiff = Math.floor(((new Date().getTime())-(new Date(String(vdate).substring(0,10)).getTime()))/(1000*60*60*24))
                    if (vdiff === 0) { return vdate.substring(11,16) // Qt.formatDate(new Date(vdate), 'hh:mm')
                    } else if (vdiff === 1) { return 'вч '+vdate.substring(11,16)  //Qt.formatDate(new Date(vdate), 'вч hh:mm')
                    // } else if (vdiff < 8) { return Math.floor(((new Date().getTime())-(new Date(String(vdate).substring(0,10)).getTime()))/(1000*60*60*24))+' дн.'
                    } else if (vdiff < 360) { return Qt.formatDate(new Date(vdate), 'dd MMM')
                    } else { return Qt.formatDate(new Date(vdate), 'MMM yy');  }

                } */
            }

        }

        header: ToolBar {
                    id: appToolBar
                    height: 36

                    background: Rectangle { color: "#F9FAFB" }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 6
                        anchors.rightMargin: 6

                        ToolButton {
                            text: "☰"
                            flat: true
                            font.pixelSize: 14
                            onClicked: naviMenu.popup()

                            Menu {
                                id: naviMenu
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
                            text: qsTr("Залишки")
                            font { pointSize: 14; bold: true }
                            color: "#1F2937"
                        }

                        ToolButton {
                            text: "⋮"
                            flat: true
                            font.pixelSize: 14
                            onClicked: toolMenu.popup()

                            Menu {
                                id: toolMenu
                                MenuItem { action: sortByIdAction; }
                                MenuItem { action: sortByNameAction; }
                                MenuItem { action: sortByCostAction; }
                                MenuItem { action: sortByDateinAction; }
                                MenuItem { action: sortByDateoutAction; }
                            }
                        }
                    }
                }


        footer: ToolBar {
            id: appFooterBar
            height: 40
            background: Rectangle { color: "#F3F4F6" }

            RowLayout {
              anchors {
                  fill: parent
                  leftMargin: 10
                  rightMargin: 10
              }
              UIFindEdit{
                  id: vfilterEdit
                  Layout.fillWidth: true
                  Layout.preferredHeight: 32
                  placeholderText: "Фільтрувати..."
                  onAccepted: {
                      vcrntEdit.text = vcrntEdit.validator.bottom;
                      const brige = {
                           filter: text,
                           setPages: (v) => { balanceRoot.countPage = Number(v || 1);},
                       }
                      JS.filterData(vw.model, brige);
                  }
              }

              Item { Layout.fillWidth: true } // Розпірка

              RowLayout {
                  spacing: 4
                  ToolButton {
                      action: previousAction
                      Layout.preferredHeight: 28
                  }
                  TextField {
                      id: vcrntEdit
                      Layout.preferredWidth: 45
                      Layout.preferredHeight: 28
                      font.pixelSize: 12
                      selectByMouse: true
                      validator: IntValidator { bottom: 1; top: balanceRoot.countPage }
                      // validator: IntValidator { bottom: 1; }
                      onActiveFocusChanged: if (activeFocus) selectAll()
                      horizontalAlignment: Text.AlignHCenter
                      text: "1"
                      onAccepted: {
                          console.info(`II: Balance.qml#8e6g onAccepted`)
                          if (!text || text === "") return;
                          const maxPage = balanceRoot.countPage;
                          if (Number(text) > maxPage) text = String(maxPage);
                          JS?.populate?.(vw.model, text);
                      }
                  }

                  ToolButton {
                      action: nextAction;
                      Layout.preferredHeight: 28
                  }
              }

              Label {
                  id: footerCount
                  font.pixelSize: 12
                  color: "#4B5563"
                  text: ` з ${balanceRoot.countPage}`;
              }
            }
        }
    }

}
