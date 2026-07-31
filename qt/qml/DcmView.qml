import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Controls


Window {
    id: dcmViewRootWindow
    width: 600
    height: 600
    visible: true

    property var dbDriver                 // DataBase driver
    onDbDriverChanged: {
        // vw.model.populate(dbDriver)
        loadAction.trigger()
    }

    property var prnDriver                 // printer manager

    signal vkEvent(string eventId, var eventParam)

    Action {
        id: previousAction
        enabled: vcrntEdit.text !== "" && Number(vcrntEdit.text) > (vcrntEdit.validator ? vcrntEdit.validator.bottom : 1)
        text: "❮"
        onTriggered: {
            const currentPage = parseInt(vcrntEdit.text) || 1;
            vcrntEdit.text = String(currentPage - 1);
        }
    }

    Action {
        id: nextAction
        enabled: vw.model !== null && vcrntEdit.text !== "" && (vw.model.pager !== undefined) && parseInt(vcrntEdit.text) < vw.model.pager.length
        text: "❯"
        onTriggered: {
            const currentPage = parseInt(vcrntEdit.text) || 1;
            vcrntEdit.text = String(currentPage + 1);
        }
    }

    Action {
            id: loadAction
            icon.source: "qrc:/icon/reload.svg"
            onTriggered: {
                vfilterEdit.text = "";
                // console.info(`II: DcmView.qml/loadAction dbDriver=${dbDriver}`)
                if (dbDriver !== undefined && dbDriver !== null) {
                    // ✅ Захист від currentIndex === -1 за допомогою currentValue
                    const activeFilter = findInterval.currentValue !== undefined ? String(findInterval.currentValue) : "shftid = 0";
                    // console.info(`II: DcmView.qml/loadAction activeFilter=${activeFilter}`)
                    if (vw.model && typeof vw.model.load === "function") {
                        // console.info(`II: DcmView.qml/loadAction load`)
                        vw.model.load(dbDriver, activeFilter);
                    }
                } else {
                    console.warn("Драйвер бази даних відсутній")
                    // logView.error("Драйвер бази даних відсутній");
                }
            }
        }

    Action {
        id: bindModeAction
        text: qsTr("Bind")
        checkable: true
        checked: true
        onTriggered: { if (vw) vw.section.property = (checked ? "pid" : ""); }
    }

    Action {
        id: viewFullBindAction
        text: "Показати весь чек"
        onTriggered: {
            if (vw.model && typeof vw.model.showFullBind === "function" && vw.currentIndex !== -1) {
                vw.model.showFullBind(vw.currentIndex);
            }
        }
    }

    Action {
        id: refuseAction
        // enabled: vw.model.get(vw.currentIndex).trade === "1"
        text: "Повернути"
        onTriggered: {
            if (vw.currentIndex === -1 || !vw.model) return;
            const dcm = vw.model.dcmForRefuse(vw.currentIndex)
            // console.log(`DcmView#hys70 res=${JSON.stringify(dcm)}`); return;
            if (dcm){
                vkEvent("refuse", dcm);
            } else logView.error("Dcm refuse error")
        }
    }

    Action {
        id: actionPrintCheck
        text: "Друкувати чек"
        onTriggered: {
            if (vw.currentIndex === -1 || !vw.model) return;
            const jbind = vw.model.bindForPrint(vw.currentIndex)
            // console.log(`DcmView#d7hf res=${JSON.stringify(jbind)}`); return;
            if (jbind){
                const printer = prnDriver ? prnDriver : (typeof Prn !== "undefined" ? Prn : null);
                if (printer) {
                    printer.saveCheckCopy(jbind);
                    printer.printCheckCopy(jbind);
                    logView.info("Копію чека успішно відправлено на друк");
                } else {
                    logView.error("Драйвер принтера чеків не ініціалізовано!");
                }
            } else logView.error("Bind retrieving error")
        }
    }

    Action {
        id: actionPrintOrder
        text: "Зберегти накладну"
        onTriggered: {
            if (vw.currentIndex === -1 || !vw.model) return;
            const jbind = vw.model.bindForPrint(vw.currentIndex);
            if (jbind) {
                const printer = prnDriver ? prnDriver : (typeof Prn !== "undefined" ? Prn : null);
                if (printer) {
                    printer.saveOrder(jbind);
                    logView.info("Накладну успішно експортовано", 1);
                } else {
                    logView.error("Драйвер експорту накладних відсутній", 0);
                }
            } else {
                logView.error("Помилка отримання накладної", 0);
            }
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

        FocusScope {
            id: rootDlg

            // Переконуємося, що розміри чітко відповідають ListView вікна
            width: rootDlg.ListView.view ? rootDlg.ListView.view.width : 400
            height: 36 // Фіксована висота для усунення Binding loop

            // Явне безпечне оголошення логіки типу операції
            readonly property bool isTrade: model.isTrade !== undefined ? model.isTrade : (Number(model.eqamount || 0) !== 0)
            // Розрахунок ціни за одиницю товару
            readonly property real dcmPrice: Number(model.eqamount || 0) / Number(model.amount || 1)

            // Інтерактивна зона кліку (перенесена на самий низ для правильної обробки Z-індексів)
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (rootDlg.ListView.view) {
                        rootDlg.ListView.view.currentIndex = index;
                    }
                }
            }

            // Головний контейнер вмісту рядка позиції чека
            Item {
                anchors.fill: parent
                clip: true

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 6
                    anchors.rightMargin: 12
                    spacing: 6

                    // 1. Індикатор знаку операції (Прихід / Розхід)
                    Label {
                        Layout.preferredWidth: 16
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.bold: true
                        font.pixelSize: 14
                        color: Number(model.amount || 0) > 0 ? "#2e7d32" : "#d32f2f"
                        text: Number(model.amount || 0) > 0 ? "＋" : "−"
                    }

                    // 2. Колонка НАЗВИ ТОВАРУ / Нотатки та коду операції
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        Layout.alignment: Qt.AlignVCenter

                        Label {
                            Layout.fillWidth: true
                            font.pixelSize: 11
                            font.italic: !model.flt
                            color: "#212121"
                            elide: Text.ElideRight

                            text: {
                                const noteStr = String(model.dcmnote || "");
                                if (rootDlg.isTrade) {
                                    const hashIdx = noteStr.indexOf("#");
                                    if (hashIdx === -1) {
                                        return '[' + (model.itemid || "?") + '] ' + noteStr;
                                    } else {
                                        return noteStr.substring(0, hashIdx).trim();
                                    }
                                }
                                return noteStr;
                            }
                        }

                        RowLayout {
                            spacing: 6
                            Label {
                                text: "ID: " + String(model.dcmid || "")
                                font.pixelSize: 9
                                font.italic: !model.flt
                                color: "gray"
                            }
                            Label {
                                text: "[" + String(model.acntcdt || "") + "]"
                                font.pixelSize: 9
                                font.italic: !model.flt
                                color: "gray"
                            }
                        }
                    }

                    // 3. Фінансова колонка (Ціна, Еквівалент, Знижки, Бонуси) - Видима тільки для комерційного роздробу
                    ColumnLayout {
                        Layout.preferredWidth: 110
                        visible: rootDlg.isTrade
                        spacing: 1
                        Layout.alignment: Qt.AlignVCenter

                        // Розрахункова ціна за одиницю товару
                        Label {
                            Layout.fillWidth: true
                            font.pixelSize: 11
                            font.italic: !model.flt
                            color: "#37474f"
                            text: rootDlg.dcmPrice.toFixed(2) // Зазвичай для чеків 2 знаків достатньо, за потреби змініть на 4
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            Label {
                                font.pixelSize: 9
                                font.italic: !model.flt
                                color: "dimgray"
                                text: Math.abs(Number(model.eqamount || 0)).toFixed(2)
                            }
                            Label {
                                font.pixelSize: 9
                                font.italic: !model.flt
                                color: "#c62828" // Червоний маркер знижки
                                text: Number(model.discount || 0) === 0 ? "" : "🏷️ " + Math.abs(Number(model.discount)).toFixed(1)
                                visible: text !== ""
                            }
                            Label {
                                font.pixelSize: 9
                                font.italic: !model.flt
                                color: "#ff8f00" // Золотий маркер бонусів
                                text: Number(model.bonus || 0) === 0 ? "" : "⭐ " + Math.abs(Number(model.bonus)).toFixed(1)
                                visible: text !== ""
                            }
                        }
                    }

                    // 4. Колонка КІЛЬКОСТІ (Завжди притиснута праворуч, великий тач-шрифт)
                    Label {
                        Layout.preferredWidth: 70
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: 14
                        font.bold: true
                        font.italic: !model.flt
                        color: "#2c3e50"

                        // Форматуємо кількість відповідно до точності одиниці виміру товару з бази
                        text: Math.abs(Number(model.amount || 0)).toLocaleString(Qt.locale(), 'f', Number(model.unitprec ?? 2))
                    }
                }
            }
        }
    }



    Component {
        id: highlightComponent

        Rectangle {
            width: vw.width
            height: 34 // Повинно чітко відповідати висоті рядка делегата чека
            color: "#e3f2fd" // Ніжний пастельно-блакитний колір Material Active
            radius: 6

            // Захист від null-значень у Qt 6. Якщо об'єкта немає — повертаємо 0
            y: (vw.currentItem !== null && typeof vw.currentItem !== "undefined") ? vw.currentItem.y : 0

            // Плавна та красива пружинна анімація перетікання фокусу
            Behavior on y {
                SpringAnimation {
                    spring: 3
                    damping: 0.3 // Трохи збільшимо демпфування для зменшення зайвого "тремтіння"
                }
            }
        }
    }

    Component {
        id: secDlg

        Rectangle {
            id: rootSec
            width: rootSec.ListView.view ? rootSec.ListView.view.width : 400
            height: 38 // Трохи збільшимо для кращої верстки в два рядки
            color: "#eeeeee" // Whitesmoke / Light Gray для чіткого розділення чеків

            // Отримуємо посилання на модель через контекст ListView
            readonly property var viewObj: rootSec.ListView.view
            readonly property var infoObj: (viewObj && viewObj.model) ? viewObj.model.bindInfo(section) : null
            readonly property var dateObj: {
                if (!rootSec.infoObj) return null;

                let raw = String(rootSec.infoObj.dcmtime).trim();
                if (raw === "") return null;
                if (!raw.includes("T")) raw = raw.replace(" ", "T");
                if (!raw.endsWith("Z") && !raw.includes("+") && !raw.substring(10).includes("-")) raw += "Z";
                // return raw;

                return new Date(raw);
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 14
                spacing: 8

                // Колонка 1: Тип документа (наприклад: ЧЕК, ФАКТУРА)
                Label {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 40 // Займає близько 40% простору
                    font.pixelSize: 13
                    font.bold: true
                    color: "#2c3e50"
                    text: rootSec.infoObj ? String(rootSec.infoObj.dcmtype || "") : ""
                    elide: Text.ElideRight
                }

                // Колонка 2: Фінансові підсумки (Сума / Еквівалент / Знижки / Бонуси)
                ColumnLayout {
                    Layout.preferredWidth: 100
                    spacing: 1
                    Layout.alignment: Qt.AlignVCenter

                    Label {
                        font.pixelSize: 12
                        font.bold: true
                        // Якщо сума повернення (від'ємна) — підсвічуємо червоним
                        color: (rootSec.infoObj && Number(rootSec.infoObj.amount || 0) < 0) ? "#d32f2f" : "#2e7d32"
                        text: rootSec.infoObj ? Number(rootSec.infoObj.amount || 0).toLocaleString(Qt.locale(), 'f', 2) : "0.00"
                    }

                    RowLayout {
                        spacing: 4
                        visible: rootSec.infoObj ? (Number(rootSec.infoObj.eqamount || 0) !== 0 || Number(rootSec.infoObj.discount || 0) !== 0) : false

                        Label {
                            font.pixelSize: 10; color: 'gray'
                            text: rootSec.infoObj && rootSec.infoObj.eqamount ? "💱 " + String(rootSec.infoObj.eqamount) : ""
                            visible: text !== ""
                        }
                        Label {
                            font.pixelSize: 10; color: '#c62828'
                            text: rootSec.infoObj && rootSec.infoObj.discount ? "🏷️ " + String(rootSec.infoObj.discount) : ""
                            visible: text !== ""
                        }
                        Label {
                            font.pixelSize: 10; color: '#ff8f00'
                            text: rootSec.infoObj && rootSec.infoObj.bonus ? "⭐ " + String(rootSec.infoObj.bonus) : ""
                            visible: text !== ""
                        }
                    }
                }

                // Колонка 3: Код клієнта (Client ID)
                Label {
                    Layout.preferredWidth: 120
                    font.pixelSize: 11
                    color: "#546e7a"
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    text: (rootSec.infoObj && rootSec.infoObj.clid) ? "👤 ID: " + String(rootSec.infoObj.clid) : ""
                }

                // Колонка 4: Дата та час фіксації ордера (з виправленим безпечним UTC-парсингом)
                ColumnLayout {
                    Layout.preferredWidth: 80
                    spacing: 1
                    Layout.alignment: Qt.AlignVCenter

                    Label {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignRight
                        font.pixelSize: 11
                        font.bold: true
                        color: "#37474f"
                        text: isNaN(rootSec.dateObj.getTime()) ? "0000-00-00" : rootSec.dateObj.toLocaleTimeString(Qt.locale(), "HH:mm");
                    }
                    Label {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignRight
                        font.pixelSize: 9
                        color: "gray"
                        text: isNaN(rootSec.dateObj.getTime()) ? "0000-00-00" : rootSec.dateObj.toLocaleDateString(Qt.locale(), "yyyy-MM-dd");
                    }
                }
            }
        }
    }

    Page {
        id: dcmPage
        // Замість anchors використовуємо пряме зв'язування з розмірами вікна Window.
        // Це гарантує 100% точність відмальовки header та footer без графічних багів у Qt 6!
        width: parent.width
        height: parent.height

        // 1. СУЧАСНИЙ СПИСОК ЧЕКІВ ТА ОРДЕРІВ
        ListView {
            id: vw
            anchors{fill: parent}
            clip: true
            spacing: 2
            model: ModelDbDcms{}
            delegate: dlg

            // Плавні тач-анімації списку
            add: Transition { NumberAnimation { properties: "x,y"; from: 100; duration: 250; easing.type: Easing.OutQuad } }
            addDisplaced: Transition { NumberAnimation { properties: "x,y"; duration: 250 } }
            remove: Transition { ParallelAnimation { NumberAnimation { property: "opacity"; to: 0; duration: 200 } NumberAnimation { properties: "x,y"; to: 100; duration: 200 } } }
            removeDisplaced: Transition { NumberAnimation { properties: "x,y"; duration: 200 } }

            // Повзунок скролу (Притиснутий праворуч зсередини списку)
            ScrollBar.vertical: ScrollBar {
                id: verticalScrollBar
                policy: ScrollBar.AsNeeded
                anchors.top: vw.top
                anchors.right: vw.right
                anchors.bottom: vw.bottom
                contentItem: Rectangle { implicitWidth: 6; radius: 3; color: verticalScrollBar.pressed ? "#757575" : "#bdbdbd" }
            }

            section.property: "pid"
            section.criteria: ViewSection.FullString
            section.delegate: secDlg

            highlight: highlightComponent
            highlightFollowsCurrentItem: false
            focus: true
        }

        // Журнал логування (спливає знизу за потребою)
        LogView {
            id: logView
            anchors.bottom: parent.bottom
            width: parent.width < 400 ? parent.width - 16 : 360
            height: Math.min(count * 45, parent.height * 0.4)
            z: 999

            anchors {
                bottom: parent.bottom
                right: parent.right
                bottomMargin: 30
                rightMargin: 10
            }

            interactive: false
            debug: false
        }

        // 🏢 ВЕРХНЯ ПАНЕЛЬ: Інтервальний фільтр архіву
        header: ToolBar {
            background: Rectangle { color: "#f8f9fa"; border.color: "#e0e0e0"; border.width: 1 }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12; anchors.rightMargin: 12
                spacing: 12

                ToolButton {
                    action: loadAction
                    font.bold: true
                }

                Label {
                    id: headerTitle
                    elide: Label.ElideRight
                    font.bold: true
                    font.pixelSize: 14
                    color: "#263238"
                    horizontalAlignment: Qt.AlignHCenter
                    verticalAlignment: Qt.AlignVCenter
                    Layout.fillWidth: true
                }

                ComboBox {
                    id: findInterval
                    Layout.preferredWidth: 160
                    flat: true

                    // Фільтри адаптовані під новий ISO-UTC формат нашої міграції 147 версії
                    model: ListModel {
                        ListElement { text: "За поточну зміну"; table: "docum"; filter: "shftid = 0" }
                        ListElement { text: "Останні 2 тижні"; table: "documall"; filter: "datetime(dcmtime) >= datetime('now', 'localtime', '-14 day')" }
                        ListElement { text: "За останній місяць"; table: "documall"; filter: "datetime(dcmtime) >= datetime('now', 'localtime', '-1 month')" }
                        ListElement { text: "За поточний квартал"; table: "documall"; filter: "datetime(dcmtime) >= datetime('now', 'localtime', '-3 month')" }
                        ListElement { text: "За весь рік"; table: "documall"; filter: "datetime(dcmtime) >= datetime('now', 'localtime', '-1 year')" }
                        ListElement { text: "З початку місяця"; table: "documall"; filter: "datetime(dcmtime) >= datetime('now', 'localtime', 'start of month')" }
                        ListElement { text: "З початку року"; table: "documall"; filter: "datetime(dcmtime) >= datetime('now', 'localtime', 'start of year')" }
                        ListElement { text: "Весь період (архів)"; table: "documall"; filter: "" }
                    }

                    textRole: 'text'
                    valueRole: 'filter'
                    onCurrentValueChanged: loadAction.trigger();
                }

                ToolButton {
                    text: "⋮"
                    font.pixelSize: 16
                    font.bold: true
                    onClicked: contextMenu.open()

                    Menu {
                        id: contextMenu
                        MenuItem { action: viewFullBindAction }
                        MenuItem { action: refuseAction }
                        MenuSeparator { padding: 4 }
                        MenuItem { action: actionPrintCheck }
                        MenuItem { action: actionPrintOrder }
                        MenuSeparator { padding: 4 }
                        MenuItem { action: bindModeAction }
                    }
                }
            }
        }

        // 🏷 НИЖНЯ ПАНЕЛЬ: Пагінація сторінок журналу (Pager)
        footer: ToolBar {
            background: Rectangle { color: "#f8f9fa"; border.color: "#e0e0e0"; border.width: 1 }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12; anchors.rightMargin: 12
                spacing: 10

                // Пошуковий фільтр
                Rectangle {
                    Layout.preferredWidth: 140
                    height: 32
                    color: "white"
                    radius: 4
                    border.color: vfilterEdit.activeFocus ? "#0288d1" : "#bdbdbd"

                    TextField {
                        id: vfilterEdit
                        anchors.fill: parent
                        leftPadding: 6
                        selectByMouse: true
                        font.pixelSize: 12
                        placeholderText: "🔍 Фільтр чеків..."
                        background: null
                        onActiveFocusChanged: if (activeFocus) selectAll();
                        onAccepted: {
                            vw.model.filterData(text.trim());
                            vcrntEdit.text = "1";
                        }
                    }
                }

                Item { Layout.fillWidth: true } // Розпірка простору

                ToolButton { action: previousAction }

                Rectangle {
                    Layout.preferredWidth: 44
                    height: 32
                    color: "white"
                    radius: 4
                    border.color: vcrntEdit.activeFocus ? "#0288d1" : "#bdbdbd"

                    TextField {
                        id: vcrntEdit
                        anchors.fill: parent
                        font.pixelSize: 12
                        font.bold: true
                        selectByMouse: true
                        background: null
                        validator: IntValidator { bottom: 1 }
                        horizontalAlignment: Text.AlignHCenter
                        text: "1"
                        onActiveFocusChanged: if (activeFocus) selectAll();
                        onTextChanged: {
                            if (!text || text === "") return;
                            const maxPage = (vw.model && vw.model.pager) ? vw.model.pager.length : 1;
                            if (Number(text) > maxPage) text = String(maxPage);
                            if (vw.model && typeof vw.model.populate === "function") {
                                vw.model.populate(text);
                            }
                        }
                    }
                }

                ToolButton { action: nextAction }

                Label {
                    id: footerCount
                    font.pixelSize: 11
                    color: "#546e7a"
                    text: String(" з %1 (%2 позицій)")
                        .arg((vw.model && vw.model.pager) ? vw.model.pager.length : 0)
                        .arg((vw.model) ? (vw.model.bindCount || 0) : 0)
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

