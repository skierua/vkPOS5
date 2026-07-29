// Shift.qml — ПОВНА СУЧАСНА ВЕРСІЯ (UI/UX Модернізація 2026)
import QtQuick
import QtQuick.Window
import QtQuick.Controls
// import QtQuick.Controls.Basic
import QtQuick.Layouts

import "js/shift.js" as JS
import "js/v147/sqlAcnt.js" as LibAcnt

Window {
    id: root
    width: 720  // Трохи збільшимо ширину для ідеального простору Dashboard
    height: 480
    minimumWidth: 680
    minimumHeight: 420
    modality: Qt.WindowModal
    color: "#F9FAFB" // Світлий пастельний фон усього вікна (Tailwind Gray 50)

    property string title: "Управління зміною"
    property string codeid: "shift"
    property var dbDriver: null
    onDbDriverChanged: {
        const uiBridge = {
            setShiftData: (v) => { root.crntShiftData = v; },
            setStackIndex: (v) => {shftStack.currentIndex = (v ? 1 : 0);},
        };
        JS.handleDriverChanged(dbDriver, cmb.model, uiBridge);
        cmb.currentIndex = 0;
        if (shftStack.currentIndex === 1){
            populateIncasAction.trigger();
        }
    }
    property var crntShiftData: null
    property bool isProcessing: false

    signal vkEvent(string id, var param)

    function dbg(str, code = "") {
        console.log(`[Shift.qml]#${code} ${str}`);
    }

    ModelBind{
        id: bindModel
        // code: "folder"
    }

    // --- ACTIONS BLOCK ---
    Action {
        id: startAction
        // enabled: cmb.currentIndex === 0 //&& (psw.text !== "" && cmb.model && psw.text === atob(cmb.model[cmb.currentIndex].psw || ""))
        enabled: !root.isProcessing
                 && typeof cmb !== "undefined"
                 && cmb.currentIndex > 0
                 && typeof psw !== "undefined"
                 && psw.text !== ""
        text: qsTr("Відкрити зміну")
        onTriggered: {
            if (typeof JS.startShift === "function") {
                root.isProcessing = true;
                const uiBridge = {
                    setShiftData: (v) => { root.crntShiftData = v; },
                    cmb: cmb,
                };
                const res = JS.startShift(root.dbDriver, bindModel, uiBridge);
                root.isProcessing = false;
                // console.log(`237#Shift.qml status=${(res?.status ?? -1)}`)
                if((res?.status ?? -1) > 0) {
                    vkEvent("shiftStarted", res);
                    // vkEvent("info", "Зміну успішно ВІДКРИТО");
                    root.close();
                } else if((res?.status ?? -1) < 0){
                    vkEvent("error", `Не вдалося відкрити зміну: ${bindModel.lastError || "???"}`);
                } else {
                    vkEvent("warning", res?.errstr || bindModel.lastError || "Unknown status returned");
                    root.close();
                }
            } else { vkEvent("error", "Системна помилка: Відсутня функція відкриття зміни"); }

        }
    }
    Action { id: cancelAction; text: qsTr("Скасувати"); onTriggered: root.close() }
    Action {
        id: incasAction;
        text: qsTr("Зарахувати на ГУРТ 📥");
        enabled: !root.isProcessing
                 && typeof vw !== "undefined"
                 && vw.hasIncas
                 && JS.isIncas(dbDriver)
        onTriggered: {
            if (typeof JS.handleIncasAction === "function") {
                root.isProcessing = true;
                const res = JS.handleIncasAction(dbDriver, vw.model, bindModel);
                root.isProcessing = false;
                if((res?.status ?? -1) > 0) {
                    vkEvent("incasFinished", res);
                    populateIncasAction.trigger();
                } else if((res?.status ?? -1) < 0){
                    vkEvent("error", `Помилка інкасації: ${res?.errstr || bindModel.lastError || "???"}`);
                } else vkEvent("warning", res?.errstr || bindModel.lastError || "???");
            } else {
                vkEvent("error", "Системна помилка: Відсутня функція інкасації");
            }
        }
    }

    Action {
        id: closeAction
        text: qsTr("Завершити зміну 🔒")
        enabled: !root.isProcessing
                 && typeof vw !== "undefined"
                 && (!vw.hasIncas || !JS.isIncas(dbDriver))
        onTriggered: {
            if (typeof JS.finishShift === "function") {
                root.isProcessing = true;
                const res = JS.finishShift(dbDriver, bindModel);
                root.isProcessing = false;
                if((res?.status ?? -1) > 0) {
                    vkEvent("shiftFinished", res);
                    root.close();
                } else if((res?.status ?? -1) < 0){
                    vkEvent("error", `Не вдалося закрити зміну: ${res?.errstr || bindModel.lastError || "???"}`);
                } else vkEvent("warning", res?.errstr || bindModel.lastError || "???");
            } else {
                vkEvent("error", "Системна помилка: Відсутня функція закриття зміни");
            }
        }
    }
    Action {
        id: populateIncasAction
        text: "Populate incas"
        onTriggered: {
            const uiBridge = {
                setHasIncas: (v) => { vw.hasIncas = v; },
            }
            JS.populateIncas(dbDriver, vw.model, uiBridge)
       }
    }

    // =============================================================================
    // ГОЛОВНИЙ СТЕК ШАРІВ ІНТЕРФЕЙСУ (Декларативний менеджер станів зміни)
    // =============================================================================
    StackLayout {
        id: shftStack
        anchors.fill: parent
        onCurrentIndexChanged: populateIncasAction.trigger();

        // ---------------------------------------------------------------------
        // СЛАТ 0: МОДУЛЬ АВТОРИЗАЦІЇ ТА ВХОДУ (ПЕРЕД ПОЧАТКОМ РОБОТИ)
        // ---------------------------------------------------------------------
        Pane {
            id: openGroup
            padding: 24

            ColumnLayout {
                anchors.centerIn: parent
                width: 340
                spacing: 16

                // Красивий заголовок вітання касира
                ColumnLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 4
                    Label {
                        text: qsTr("vkPOS Terminal");
                        font { pixelSize: 22; bold: true }
                        color: "#1E429F";
                        Layout.alignment: Qt.AlignHCenter
                    }
                    Label { text: qsTr("Будь ласка, авторизуйтесь для старту дня"); font.pixelSize: 12; color: "#6B7280"; Layout.alignment: Qt.AlignHCenter }
                }

                // Картка форми введення
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: formLayout.implicitHeight + 24
                    radius: 10
                    color: "#FFFFFF"
                    border { width: 1; color: "#E5E7EB" }

                    ColumnLayout {
                        id: formLayout
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 12

                        ColumnLayout {
                            spacing: 4
                            Label { text: qsTr("Логін:"); font { pixelSize: 11; bold: true } color: "#4B5563" }
                            ComboBox {
                                id: cmb
                                textRole: "note"
                                valueRole: "code"
                                model:ListModel{}
                                Layout.fillWidth: true
                                onCurrentIndexChanged: { psw.text = "";
                                    if (currentIndex > 0) {
                                        startAction.enabled = false
                                        psw.forceActiveFocus();
                                    } else startAction.enabled = true
                                }
                            }
                        }

                        ColumnLayout {
                            spacing: 4
                            Label { text: qsTr("Пароль:"); font { pixelSize: 11; bold: true } color: "#4B5563" }
                            TextField {
                                id: psw
                                Layout.fillWidth: true
                                echoMode: TextInput.Password
                                selectByMouse: true
                                font.pixelSize: 13
                                placeholderText: cmb.currentIndex === 0 ? qsTr("Оберіть користувача...") : qsTr("Введіть ключ доступу")
                                enabled: cmb.currentIndex > 0

                                background: Rectangle {
                                    radius: 6
                                    color: parent.activeFocus ? "#FFFFFF" : "#F9FAFB"
                                    border { width: 1; color: parent.activeFocus ? "#3B82F6" : "#D1D5DB" }
                                }
                                onActiveFocusChanged: if (activeFocus) selectAll()
                                onAccepted: {
                                    if (cmb.model && cmb.currentIndex >= 0) {
                                        let cshr = cmb.model[cmb.currentIndex];
                                        if (cshr && (cshr.psw === "" || text === atob(cshr.psw)))
                                            startAction.trigger();
                                    }
                                }
                            }
                        }
                        // Кнопки дій відкриття дня
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12
                            Button {
                            action: cancelAction
                            Layout.fillWidth: true
                            Layout.preferredHeight: 36
                            }
                            Button {
                                action: startAction
                                Layout.fillWidth: true
                                Layout.preferredHeight: 36
                                highlighted: true
                                background: Rectangle {
                                    radius: 6
                                    color: parent.enabled ? (parent.down ? "#1D4ED8" : "#3B82F6") : "#E5E7EB"
                                }
                                contentItem: Text { text: parent.text; font.bold: true; color: parent.enabled ? "#FFFFFF" : "#9CA3AF"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                            }
                        }
                    }
                }
            }
        }
        // ---------------------------------------------------------------------
        // СЛАТ 1: ПАНЕЛЬ ДЕННОГО МОНІТОРИНГУ ТА ЗАКРИТТЯ ЗМІНИ (DASHBOARD)
        // ---------------------------------------------------------------------
        Pane {
            id: closeGroup
            padding: 14
            RowLayout {
                anchors.fill: parent
                spacing: 16
                // ЛІВА ПАНЕЛЬ: Картка метаданих та сервісних сповіщень
                ColumnLayout {
                    Layout.alignment: Qt.AlignTop
                    Layout.preferredWidth: 220
                    spacing: 10
                    Label { text: qsTr("МОНІТОР СТАТУСУ ЗМІНИ"); font { pixelSize: 11; bold: true } color: "#4B5563" }
                    Rectangle { Layout.fillWidth: true; height: 1; color: "#E5E7EB" }
                    // Інформаційний блок-віджет
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: infoLayout.implicitHeight + 16
                        radius: 8
                        color: "#FFFFFF"
                        border { width: 1; color: "#E5E7EB" }
                        ColumnLayout {
                            id: infoLayout
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 6
                            RowLayout { Label { text: qsTr("ID:"); color: "#6B7280"; Layout.preferredWidth: 65 } Label { id: shid; font.bold: true; text: String(crntShiftData.id || "0") } }
                            RowLayout { Label { text: qsTr("Касир:"); color: "#6B7280"; Layout.preferredWidth: 65 } Label { id: shcshr; font.bold: true; elide: Text.ElideRight; Layout.fillWidth: true; text: String(crntShiftData.cshrname || "—") } }
                            RowLayout { Label { text: qsTr("Дата:"); color: "#6B7280"; Layout.preferredWidth: 65 } Label { id: shdate; text: String(crntShiftData.shftdate || "—") } }
                            RowLayout { Label { text: qsTr("Старт:"); color: "#6B7280"; Layout.preferredWidth: 65 } Label { id: shopen; text: String(crntShiftData.shftbegin || "—") } }
                            RowLayout { Label { text: qsTr("Кінець:"); color: "#6B7280"; Layout.preferredWidth: 65 } Label { id: shclose; color: "#6B7280"; text: String(crntShiftData.shftend || "—") } }
                        }
                    }
                    Rectangle {
                        id: redyToCloseAlert
                        Layout.fillWidth: true
                        visible: JS.isIncas(dbDriver) && vw && vw.hasIncas
                        implicitHeight: alertTxt.implicitHeight + 20
                        radius: 8
                        color: "#FEF2F2"
                        border { width: 1; color: "#FCA5A5" }
                        ColumnLayout {
                            anchors.centerIn: parent
                            width: parent.width - 16
                            spacing: 2
                            Label { text: "⚠ " + qsTr("УВАГА КАСИРА!"); font { pixelSize: 11; bold: true } color: "#9B1C1C"; Layout.alignment: Qt.AlignHCenter }
                            Label { id: alertTxt; text: qsTr("Виявлено неінкасовану валюту.\nЗакриття касового дня заблоковано!"); font.pixelSize: 10; color: "#9B1C1C"; horizontalAlignment: Text.AlignHCenter; Layout.fillWidth: true }
                        }
                    }
                    Item { Layout.fillHeight: true } // Розпірка
                    // Нижній блок кнопок лівої панелі
                    Button { action: cancelAction; Layout.fillWidth: true; Layout.preferredHeight: 32 }
                }
                // ПРАВА ПАНЕЛЬ: Велика картка таблиці інкасацій валют
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 8
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 8
                        color: "#FFFFFF"
                        border { width: 1; color: "#E5E7EB" }
                        clip: true
                        ListView {
                            id: vw
                            anchors.fill: parent
                            anchors.margins: 4
                            clip: true
                            spacing: 4
                            property bool hasIncas: false
                            readonly property real colW1: (width - 16) * 0.22 - spacing
                            readonly property real colW2: (width - 16) * 0.24 - spacing
                            // readonly property real colW3: (width - 16) * 0.16 - spacing
                            // readonly property real colW4: (width - 16) * 0.16 - spacing
                            readonly property real colW5: (width - 16) * 0.30 - spacing
                            readonly property real colW6: (width - 16) * 0.24 - spacing
                            header: Rectangle {
                                width: vw.width; height: 26; color: "#F3F4F6"; radius: 4
                                RowLayout {
                                    anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8
                                    Label {
                                        Layout.preferredWidth: vw.colW1;  horizontalAlignment: Text.AlignHCenter;
                                        text: qsTr("ВАЛ");
                                        font { pixelSize: 10; bold: true }
                                        color: "#4B5563"
                                    }
                                    Label {
                                        Layout.preferredWidth: vw.colW2;  horizontalAlignment: Text.AlignHCenter
                                        text: qsTr("СУМА");
                                        font { pixelSize: 10; bold: true }
                                        color: "#4B5563";
                                    }
                                    // Label { Layout.preferredWidth: vw.colW3; text: qsTr("ІНКАС"); font { pixelSize: 10; bold: true } color: "#4B5563"; horizontalAlignment: Text.AlignRight }
                                    // Label { Layout.preferredWidth: vw.colW4; text: qsTr("ЗАЛИШ"); font { pixelSize: 10; bold: true } color: "#4B5563"; horizontalAlignment: Text.AlignRight }
                                    Label {
                                        Layout.preferredWidth: vw.colW5; horizontalAlignment: Text.AlignHCenter;
                                        text: qsTr("КУРС");
                                        font { pixelSize: 10; bold: true }
                                        color: "#4B5563";
                                    }
                                    Label {
                                        Layout.preferredWidth: vw.colW6; horizontalAlignment: Text.AlignHCenter
                                        text: qsTr("ДОХІД");
                                        font { pixelSize: 10; bold: true }
                                        color: "#4B5563";
                                    }
                                }
                            }
                            model: ListModel {}
                            delegate: FocusScope {
                                id: delegateRoot
                                width: vw.width; height: 32
                                Rectangle {
                                    anchors { fill: parent; /*leftMargin: 2; rightMargin: 2*/ } radius: 6
                                    color: vw.currentIndex === index ? "#EFF6FF" : ((index % 2 === 0) ? "#FFFFFF" : "#F9FAFB")
                                    border { width: 1; color: vw.currentIndex === index ? "#BFDBFE" : "#F3F4F6" }
                                    RowLayout {
                                        anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8
                                        Rectangle {
                                            Layout.preferredWidth: vw.colW1 - 6; Layout.preferredHeight: 18; radius: 4
                                            color: Number(amnt || 0) > 0 ? "#FDE8E8" : "#d7f5d7"
                                            // color: Number(amnt || 0) > 0 ? "#FDE8E8" : "#F3F4F6"
                                            Text { anchors.centerIn: parent;
                                                text: (Number(priceQty || 1) === 1 ? "" : (priceQty || 1) + " ") + (item?.itemchar || "—");
                                                // text: (item.qty === "1" || item.qty === 1 || !item.qty ? "" : item.qty + " ") + (item?.itemchar || "—");
                                                font { pixelSize: 10; bold: true }
                                                color: Number(amnt || 0) > 0 ? "#DC2626" : "#16A34A";
                                                // color: Number(amnt || 0) > 0 ? "#9B1C1C" : "#374151";
                                            }
                                        }
                                        Text {
                                            Layout.preferredWidth: vw.colW2; horizontalAlignment: Text.AlignRight;
                                            text: Math.abs(Number(amnt || 0)).toLocaleString(Qt.locale(), 'f', 2);
                                            color: Number(amnt || 0) > 0 ? "#DC2626" : "#16A34A";
                                            // color: Number(amnt || 0) > 0 ? "#DC2626" : "#1F2937";
                                            font { pixelSize: 12; family: "Courier New, Consolas, Monospace" }
                                        }
                                        /*Text {
                                            Layout.preferredWidth: vw.colW3; horizontalAlignment: Text.AlignRight;
                                            text: Math.abs(Number(incas || 0)).toLocaleString(Qt.locale(), 'f', 2);
                                            // color: Number(incas || 0) < 0 ? "#16A34A" : "#6B7280";
                                            font { pixelSize: 12; bold: true; family: "Courier New, Consolas, Monospace" }
                                        }*/
                                        /*Text {
                                            Layout.preferredWidth: vw.colW4; horizontalAlignment: Text.AlignRight;
                                            readonly property real resVal: Number(amnt || 0) + Number(incas || 0);
                                            text: Math.abs(resVal).toLocaleString(Qt.locale(), 'f', 2);
                                            // color: resVal < 0 ? "#DC2626" : "#111827";
                                            font { pixelSize: 12; bold: resVal !== Number(amnt || 0); family: "Courier New, Consolas, Monospace" }
                                        } */
                                        Text {
                                            // readonly property real priceVal: Number(price || 0) * Number(item?.qty || 1)
                                            Layout.preferredWidth: vw.colW5; horizontalAlignment: Text.AlignRight;
                                            text: (Number(priceVal || 0)).toFixed(4);
                                            font { pixelSize: 12; family: "Courier New, Consolas, Monospace" }
                                            // color: "#4B5563"
                                        }
                                        Text {
                                            Layout.preferredWidth: vw.colW6; horizontalAlignment: Text.AlignRight;
                                            property real profitVal: 0 - Number(eqamount || 0) - Number(amnt || 0) * Number(priceVal || 0) /  Number(priceQty || 1) ;
                                            text: Math.abs(profitVal).toFixed(0);
                                            color: profitVal < 0 ? "#DC2626" : "#16A34A";
                                            // color: profitVal < 0 ? "#DC2626" : "#111827";
                                            font { pixelSize: 12; bold: true; family: "Courier New, Consolas, Monospace" }
                                        }
                                    }
                                    MouseArea { anchors.fill: parent; onClicked: vw.currentIndex = index; onDoubleClicked: { incasRateEdit.incasid = index; incasRateEdit.open(); } }
                                }
                            }
                        }
                    }
                    // Акцентні нижні кнопки управління днем
                    RowLayout {
                        Layout.fillWidth: true; spacing: 12
                        Button {
                        action: incasAction; Layout.fillWidth: true; Layout.preferredHeight: 36; visible: JS.isIncas(dbDriver); highlighted: enabled
                        background: Rectangle { radius: 6; color: parent.enabled ? (parent.down ? "#047857" : "#10B981") : "#E5E7EB" }
                        contentItem: Text { text: parent.text; font.bold: true; color: parent.enabled ? "#FFFFFF" : "#9CA3AF"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        }
                        Button {
                            action: closeAction; Layout.fillWidth: true; Layout.preferredHeight: 36; highlighted: enabled
                            background: Rectangle { radius: 6; color: parent.enabled ? (parent.down ? "#B91C1C" : "#EF4444") : "#E5E7EB" }
                            contentItem: Text { text: parent.text; font.bold: true; color: parent.enabled ? "#FFFFFF" : "#9CA3AF"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        }
                    }
                }
            }
        }
        // --- МОДАЛЬНИЙ ПОПУП РЕДАГУВАННЯ СУМИ ТА КУРСУ ІНКАСАЦІЇ ---
        Popup {
            id: incasRateEdit
            property int incasid: 0
            width: 320; height: 160; anchors.centerIn: parent; modal: true; focus: true
            closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
            z: 9999
            background: Rectangle { radius: 12; color: "#FFFFFF"; border { width: 1; color: "#E5E7EB" } }
            readonly property var currentModelItem: (vw.model && incasid >= 0 && incasid < vw.model.count) ? vw.model.get(incasid) : null
            ColumnLayout {
                anchors.fill: parent; anchors.margins: 16; spacing: 12
                RowLayout {
                    Layout.fillWidth: true
                    Label { text: qsTr("Корегування інкасації"); font { pixelSize: 14; bold: true } color: "#111827" }
                    Item { Layout.fillWidth: true }
                    Rectangle { width: 50; height: 18; radius: 4; color: "#EBF5FF";
                        Label { anchors.centerIn: parent; text: incasRateEdit.currentModelItem
                                                                ? `${incasRateEdit.currentModelItem.item.itemchar || "???"}[${incasRateEdit.currentModelItem.item.id || ""}]`
                                                                : "";
                            font { pixelSize: 10; bold: true }
                            color: "#1E429F" }
                    }
                }
                RowLayout {
                    Layout.fillWidth: true; spacing: 12
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 4
                        Label { text: qsTr("Сума інкасації"); font.pixelSize: 10; color: "#6B7280" }
                        TextField { id: edtIncasAmount;
                            enabled: false;
                            Layout.fillWidth: true;
                            Layout.preferredHeight: 34;
                            selectByMouse: true;
                            horizontalAlignment: Text.AlignHCenter;
                            font { pixelSize: 13; bold: true }
                            background: Rectangle { radius: 6; color: parent.activeFocus ? "#FFFFFF" : "#F9FAFB"; border { width: 1; color: parent.activeFocus ? "#3B82F6" : "#D1D5DB" } }
                            validator: DoubleValidator {notation: "StandardNotation"; locale: "en_US" }
                            onActiveFocusChanged: if (activeFocus) selectAll();
                            text: incasRateEdit.currentModelItem ? String(incasRateEdit.currentModelItem.incas || "0") : "0";
                            onEditingFinished: { if (incasRateEdit.currentModelItem) vw.model.setProperty(incasRateEdit.incasid, "incas", Number(text)); }
                            onAccepted: incasRateEdit.close() }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 4
                        Label { text: `Курс${(incasRateEdit.currentModelItem?.item.qty || 1) === 1 ? "": ` /${incasRateEdit.currentModelItem.item.qty}`}`; font.pixelSize: 10; color: "#6B7280" }
                        TextField { id: edtIncasPrice;
                            // readonly property real priceVal: Math.abs(Number(incasRateEdit.currentModelItem?.price || 0) * Number(incasRateEdit.currentModelItem?.item.qty || 1))
                            Layout.fillWidth: true;
                            Layout.preferredHeight: 34;
                            focus: true; selectByMouse: true;
                            horizontalAlignment: Text.AlignHCenter;
                            font { pixelSize: 13; bold: true }
                            background: Rectangle { radius: 6; color: parent.activeFocus ? "#FFFFFF" : "#F9FAFB"; border { width: 1; color: parent.activeFocus ? "#3B82F6" : "#D1D5DB" } }
                            validator: DoubleValidator {
                                bottom: (incasRateEdit.currentModelItem && !!incasRateEdit.currentModelItem.priceVal) ? incasRateEdit.currentModelItem.priceVal * 0.98 : 0.0;
                                top: (incasRateEdit.currentModelItem && !!incasRateEdit.currentModelItem.priceVal) ? incasRateEdit.currentModelItem.priceVal * 1.02 : 999999.0;
                                decimals: 4;
                                notation: "StandardNotation"; locale: "en_US" }
                            onActiveFocusChanged: if (activeFocus) selectAll();
                            text: incasRateEdit.currentModelItem ? String(incasRateEdit.currentModelItem.priceVal || 0) : "0";
                            onEditingFinished: { if (incasRateEdit.currentModelItem) {
                                    // console.log(`BE ue3#Shift.qml idx=${incasRateEdit.incasid} text=${text} priceVal=${incasRateEdit.currentModelItem.priceVal}`);
                                    incasRateEdit.currentModelItem.priceVal = Number(text);
                                    // vw.model.setProperty(incasRateEdit.incasid, "priceVal", Number(text));
                                    // console.log(`AF ue3#Shift.qml idx=${incasRateEdit.incasid} text=${text} priceVal=${incasRateEdit.currentModelItem.priceVal}`);
                                }
                            }
                            onAccepted: incasRateEdit.close()
                        }
                    }
                }
                Button { Layout.fillWidth: true; Layout.preferredHeight: 32; text: qsTr("Зберегти зміни");
                    contentItem: Text { text: parent.text; font { pixelSize: 12; bold: true } color: "#FFFFFF"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    background: Rectangle { radius: 6; color: parent.down ? "#1D4ED8" : (parent.hovered ? "#2563EB" : "#3B82F6") }
                    onClicked: incasRateEdit.close() }
            }
            // onClosed: { if (typeof populateIncasAction !== "undefined") populateIncasAction.trigger(); }
        }
    }
}
