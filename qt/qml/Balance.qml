import QtQuick
import QtQuick.Controls
// import QtQuick.Controls.Fusion
import QtQuick.Layouts

Window {
    id: root
    width: 720
    height: 720

    property var dbDriver: null                 // DataBase driver
    onDbDriverChanged: {
        // loadAction.trigger()
    }
    property real zero: 0.0000001

    function dbg(str, code ="") {
        console.log(`[Balance.qml]#${code} ${str}`);
    }
    Action {
        id: previousAction
        // Безпечне порівняння через валідатор інпуту сторінки
        enabled: vcrntEdit.validator && Number(vcrntEdit.text) > vcrntEdit.validator.bottom
        text: "◀" // Стабільна Юнікод-стрілка «назад» (підтримується всіма ОС)

        onTriggered: {
            let prevPage = Number(vcrntEdit.text) - 1;
            vcrntEdit.text = String(prevPage);
            if (vw.model && typeof vw.model.populate === "function") {
                vw.model.populate(prevPage);
            }
        }
    }

    Action {
        id: nextAction
        // ✅ ВИПРАВЛЕНО CRASH-БАГ QT6: Захищена перевірка типу масиву через typeof
        enabled: vw.model !== null
                 && typeof vw.model.rawData !== "undefined"
                 && vw.model.rawData !== null
                 && Number(vcrntEdit.text) < Math.ceil(vw.model.rawData.length / vw.model.pageCapacity)
        text: "▶" // Стабільна Юнікод-стрілка «вперед»

        onTriggered: {
            let nextPage = Number(vcrntEdit.text) + 1;
            vcrntEdit.text = String(nextPage);
            if (vw.model && typeof vw.model.populate === "function") {
                vw.model.populate(nextPage);
            }
        }
    }

 /*   Action {
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
    } */


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

        Rectangle {
            id: headerRoot

            width: vw.width
            height: 32 // Трохи збільшимо висоту для сучасного вигляду
            color: "#F3F4F6" // Приємний нейтральний сірий фон шапки таблиці (Tailwind Gray 100)

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
                    text: qsTr("КУРС")
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

/*    Component {
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
    }*/

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
                spacing: 1
                clip: true
                // model: ListModel{ }
                model: dataModel
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
                section.delegate: Rectangle {
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
                                }
/*                section.delegate: Rectangle{
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
*/
                function load() {
                    vcrntEdit.text = "1";
                    if (root.dbDriver) {
                        model.load(root.dbDriver, balAcnt || "300", sortOrder || "", vfilterEdit.text);

                        // ✅ ВИПРАВЛЕНО: Замість застарілого String().arg використовуємо сучасний qsTr().arg
                        let totalPages = Math.ceil(vw.model.rawData.length / vw.model.pageCapacity) || 1;
                        footerCount.text = qsTr(" з %1").arg(totalPages);
                    }
                }
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
                            // ✅ ВИПРАВЛЕНО: Використовуємо сучасний .popup() без жорстких координат y
                            onClicked: naviMenu.popup()

                            Menu {
                                id: naviMenu
                                MenuItem { action: loadStockAction; }
                                MenuItem { action: loadBrackAction; }
                                MenuItem { action: loadTradeAction; }
                                MenuItem { action: loadBulkAction; }
                            }
                        }
                        UIFindEdit{
                            id: vfilterEdit
                            Layout.fillWidth: true
                            Layout.preferredHeight: 32
                            placeholderText: "Фільтрувати..."
                            // onTextChanged: vw.load()
                            onEditingFinished: vw.load()
                        }

                        Label {
                            id: headerTitle
                            elide: Label.ElideRight
                            horizontalAlignment: Qt.AlignHCenter
                            verticalAlignment: Qt.AlignVCenter
                            Layout.fillWidth: true
                            text: qsTr("Залишки валют")
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


/*        header: ToolBar {
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

        } */

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

/*              TextField {
                  id: vfilterEdit
                  Layout.preferredWidth: 120
                  Layout.preferredHeight: 28
                  selectByMouse: true
                  font.pixelSize: 12
                  onActiveFocusChanged: if (activeFocus) selectAll()
                  horizontalAlignment: Text.AlignHCenter
                  placeholderText: "Пошук/Фільтр"
                  onEditingFinished: vw.load()
              }*/

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
                      validator: IntValidator { bottom: 1; }
                      onActiveFocusChanged: if (activeFocus) selectAll()
                      horizontalAlignment: Text.AlignHCenter
                      text: "1"
                      onEditingFinished: {
                          let maxPage = Math.ceil(vw.model.rawData.length / vw.model.pageCapacity) || 1;
                          if (Number(text) > maxPage) text = maxPage;
                          vw.model.populate(Number(text));
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
              }
            }
        }

/*        footer: ToolBar {
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
        } */
    }

}
