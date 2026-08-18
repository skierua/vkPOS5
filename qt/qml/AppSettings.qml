// AppSettings.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "js/v147/config.js" as JS
import "js/libREST.js" as REST
import "js/CashDesk.js" as TAX
import "js/v147/sqlAcnt.js" as LibAcnt

Item {
    id: root
    property var dbDriver                 // Драйвер бази даних (C++)
    onDbDriverChanged: {
            if (root.dbDriver && root.visible) {
                actBasic.trigger();
            }
        }
    property string title: "Налаштування системи"
    property string codeid: "settings"

    // Список дій контекстного меню (перемикачі вкладок)
    property list<Action> vkContextActions: [
        actBasic,
        actREST,
        actTAX,
        actDfltAccounts,
        actAccounts
    ]

    signal vkEvent(string id, var param)

    function textForMenu() { return root.title; }

    function loadTAX(){
        if (!root.dbDriver) return;
        console.log(`AppSettings.qml/loadTAX `)
        TAX.reset(root.dbDriver);
        editTaxHost.text = TAX.HOST;
        editTaxApi.text = TAX.API;
        editTaxCash.text = TAX.CASH;
        editTaxToken.text = TAX.TOKEN;
    }

    function loadAcntTab(acnt){
        if (!root.dbDriver || !acnt){
            root.vkEvent("error", "Помилка вхідних параметрів рахунку");
            return;
        }
        const valList = LibAcnt.dbAcntbal(dbDriver, `acntno = '${acnt}'`);
        // console.log(`II: AppSettings.qml#q6t3 valList=${JSON.stringify(valList)}`)
        if (!valList || !valList.length) {
            root.vkEvent("error", "Помилка заватаження рахунку");
            return;
        }

        const v = valList[0];
        editAcntTabNote.text = v.note;
        editAcntTabMaskDomestic.checked = (Number(v.mask || 0) & 1) === 1;
        editAcntTabMaskForeign.checked = (Number(v.mask || 0) & 2) === 2;
        editAcntTabMaskArticles.checked = (Number(v.mask || 0) & 4) === 4;
        editAcntTabTrade.checked = (Number(v.trade || 0) === 1);

    }

    // --- Блок логіки вкладок ---
    Action {
        id: actBasic
        text: "Базові"
        onTriggered: {
            const val = JS.getBasic(dbDriver);

            modeGroup.currentModeid = Number(val?.appmode || 3);
            editTerm.text = String(val?.id || "TEST");
            editTermName.text = String(val?.name || "");
            editPrinter.text = String(val?.pos_printer || "");
            editCheckAmnt.text = String(val?.amnt_sign || "1");

            if (typeof switchAutoPrint !== "undefined") {
                switchAutoPrint.checked = String(val?.auto_print || "0") === "1";
            }
            editCheckPrintDcm.text = String(val?.print_dcm || "check");

            stack.currentIndex = 0;
        }
    }

    Action {
            id: actREST
            text: "REST API"
            onTriggered: {
                if (!root.dbDriver) return;
                REST.reset(root.dbDriver);
                editRestHost.text = REST.HOST;
                editRestApi.text = REST.API;
                editRestUser.text = REST.USER;
                editRestPsw.text = REST.PSW;
                editRestToken.text = REST.TOKEN;

                stack.currentIndex = 1;
            }
        }

    Action {
        id: actTAX
        text: "ПРРО / Фіскалізація"
        onTriggered: {
            loadTAX();
            // console.log(`AppSettings.qml 23sde`)
            stack.currentIndex = 2;
        }
    }

    Action {
        id: actDfltAccounts
        text: "Тирові рахунки"
        onTriggered: {
            if (!root.dbDriver) return;
            const val = JS.getAcntList(dbDriver);
            // if (!val) {
            //     editAcntCash.text = val?.cash.substring(2) || "";
            //     editAcntTrade.text = val?.trade.substring(2) || "";
            //     editAcntBulk.text = val?.bulk.substring(2) || "";
            //     editAcntIncas.text = val?.incas.substring(2) || "";
            //     editAcntProfit.text = val?.profit.substring(2) || "";
            //     stack.currentIndex = 3;
            //     return;
            // }

            const cashStr = String(val?.cash || "");
            const tradeStr = String(val?.trade || "");
            const bulkStr = String(val?.bulk || "");
            const incasStr = String(val?.incas || "");
            const profitStr = String(val?.profit || "");

            // Відсікаємо префікси, захищаючи довжину рядка
            editAcntCash.text = cashStr.substring(Math.min(cashStr.length, (JS.glCashPrefix || "30").length));
            editAcntTrade.text = tradeStr.substring(Math.min(tradeStr.length, (JS.glTradePrefix || "35").length));
            editAcntBulk.text = bulkStr.substring(Math.min(bulkStr.length, (JS.glTradePrefix || "35").length));
            editAcntIncas.text = incasStr.substring(Math.min(incasStr.length, (JS.glCashPrefix || "30").length));
            editAcntProfit.text = profitStr.substring(Math.min(profitStr.length, (JS.glDepoPrefix || "36").length));

            stack.currentIndex = 3; // Перемикаємо StackLayout на вкладку №4
        }
    }
    Action {
        id: actAccounts
        text: "Параметри рахунків"
        onTriggered: {
            stack.currentIndex = 4;
            const val = LibAcnt.dbAcntbal(dbDriver);
            const sortVal = val.sort((a,b)=> a.acntno.localeCompare(b.acntno))
            .map(v => {
                 return { "code": v.acntno,
                     "name": `${v.acntno} - ${v.note || ("[" + v.name + "]")} ${v.clname || ""}`
                 }})
            for (let v of sortVal) acntTabCombo.model.append(v)
            if (!!acntTabCombo.count ) acntTabCombo.currentIndex = 0
        }
    }
    // ✨ ФОН ВСЬОГО ЕКРАНА (М'який трендовий студійний сірий)
    Rectangle {
        anchors.fill: parent
        color: "#f3f4f6" // Ultra-clean gray background
    }

    // Головний контейнер з відступами
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 16

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Label {
                text: "⚙"
                font.pixelSize: 22
                color: "#0288d1"
            }
            Label {
                text: stack.currentIndex === 0 ? "Базові параметри каси" :
                      stack.currentIndex === 1 ? "Синхронізація REST API" :
                      stack.currentIndex === 2 ? "Фіскалізація та ПРРО" :
                      stack.currentIndex === 3 ? "Типові рахунки" : "Параметри рахунків"
                font.pixelSize: 18
                font.bold: true
                color: "#1f2937" // Dark charcoal
            }
        }

        StackLayout {
            id: stack
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: 0

            ScrollView {
                id: basicTab
                clip: true
                Layout.fillWidth: true
                Layout.fillHeight: true

                ColumnLayout {
                    width: basicTab.width - 12
                    spacing: 16

                    // --- 🧩 КАРТКА БЛОКУ СИСТЕМИ (Групування налаштувань) ---
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: contentColumn.implicitHeight + 32
                        color: "#ffffff"
                        radius: 12

                        // Легка сучасна тінь-градієнт
                        border.color: "#e5e7eb"
                        border.width: 1

                        ColumnLayout {
                            id: contentColumn
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 14

                            Item{
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                ButtonGroup {
                                        id: modeGroup
                                        property int currentModeid: 3
                                        onCheckedButtonChanged: {
                                            if (checkedButton) {
                                                currentModeid = checkedButton.modeid
                                                // console.log("II: AppSettings.qml#w5t Активний тип:", currentModeid)
                                            }
                                        }
                                    }

                                    RowLayout {
                                        width: parent.width
                                        spacing: 5

                                        Label {
                                            text: "Оберіть тип підрозділу:"
                                            font.bold: true
                                            color: "#666666"
                                        }

                                        RadioButton {
                                            readonly property int modeid: 2
                                            text: "KANTOR"
                                            ButtonGroup.group: modeGroup
                                            checked: modeid === modeGroup.currentModeid    //true // Початковий вибір
                                            font.pixelSize: 14
                                        }

                                        RadioButton {
                                            readonly property int modeid: 1
                                            text: "SHOP"
                                            ButtonGroup.group: modeGroup
                                            checked: modeid === modeGroup.currentModeid
                                            font.pixelSize: 14
                                        }

                                    }
                            }

                            // Поле: Код терміналу
                            UITextField{
                                id: editTerm;
                                Layout.fillWidth: true
                                Layout.preferredHeight: 56
                                title: "Ідентифікатор (Код терміналу)"
                                placeholderText: "Введіть унікальний код каси..."
                            }
                            // Поле: Назва терміналу
                            UITextField{
                                id: editTermName;
                                Layout.fillWidth: true
                                Layout.preferredHeight: 56
                                title: "Ідентифікатор (Назва терміналу)"
                                placeholderText: "Введіть назву каси..."
                            }
                            // Поле: POS Принтер
                            UITextField{
                                id: editPrinter;
                                Layout.fillWidth: true
                                Layout.preferredHeight: 56
                                title: "Мережеве ім'я POS-принтера чеків"
                                placeholderText: "Наприклад: POSprn"
                            }
                            // Поле: Знак операції
                            UITextField{
                                id: editCheckAmnt;
                                Layout.fillWidth: true
                                Layout.preferredHeight: 56
                                title: "Математичний знак суми (Amount Sign)"
                                placeholderText: "-1 (витратний чек) | 1 (прибутковий)"
                            }
                            // Поле: Шаблон друку
                            UITextField{
                                id: editCheckPrintDcm;
                                Layout.fillWidth: true
                                Layout.preferredHeight: 56
                                title: "Дефолтний шаблон друку документа"
                                placeholderText: "Наприклад: check або check_knt"
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.topMargin: 4
                                ColumnLayout {
                                    spacing: 2
                                    Layout.fillWidth: true
                                    Label { text: "Автоматичний друк чека"; font.pixelSize: 13; font.bold: true; color: "#1f2937" }
                                    Label { text: "Друкувати нефіскальний чек одразу після закриття транзакції"; font.pixelSize: 11; color: "#6b7280" }
                                }
                                Switch {
                                    id: switchAutoPrint
                                    Layout.alignment: Qt.AlignVCenter
                                    // Стилізація Switch під колірну гаму каси (опціонально для Material/Fusion)
                                }
                            }
                        }
                    }

                    UIBtn{
                        id: btnSaveSettings
                        palette: "blue"
                        text: "💾 Зберегти зміни"
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44
                        onClicked: {
                            const val = {
                                id: editTerm.text.trim(),
                                appmode: modeGroup.currentModeid,
                                name: editTermName.text.trim(),
                                amnt_sign: editCheckAmnt.text.trim(),
                                pos_printer: editPrinter.text.trim(),
                                auto_print: switchAutoPrint.checked ? "1" : "0",
                                print_dcm: editCheckPrintDcm.text.trim()
                            };
                            const ok = JS.setBasic(dbDriver, val);
                            if (ok) {
                                root.vkEvent("modeidChanged", modeGroup.currentModeid);
                                root.vkEvent("info", "Конфігурацію успішно збережено");
                            } else root.vkEvent("error", "Помилка збереження конфігурації")
                        }
                    }

                }
            }

            ScrollView {
                id: restTab
                clip: true
                Layout.fillWidth: true
                Layout.fillHeight: true

                ColumnLayout {
                    // Залишаємо відступ для скроллбару та гарного сприйняття
                    width: restTab.width - 16
                    spacing: 14

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: restColumn.implicitHeight + 32
                        color: "#ffffff"
                        radius: 12
                        border.color: "#e5e7eb"
                        border.width: 1

                        ColumnLayout {
                            id: restColumn
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 14

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10
                                // Поле: Host URL
                                UITextField{
                                    id: editRestHost;
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 56
                                    title: "🔗 Адреса REST сервера (Host URL"
                                    placeholderText: "Введіть REST URL (https://example.com) ..."
                                }
                                // Поле: API version
                                UITextField{
                                    id: editRestApi;
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 56
                                    title: "📦 Версія / Ендпоінт API (API Version)"
                                    placeholderText: "Введіть версію API (api/v1) ..."
                                }
                            }

                            // Горизонтальний рядок: Авторизаційні дані (Логін та Пароль)
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                // Поле: Login
                                UITextField{
                                    id: editRestUser;
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 56
                                    title: "👤 Логін (Login)"
                                    placeholderText: "REST login"
                                }

                                // Поле: Password
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 4
                                    Label { text: "🔑 Пароль (Password)"; font.pixelSize: 11; font.bold: true; color: "#6b7280" }
                                    Rectangle {
                                        Layout.fillWidth: true; height: 38; color: "#f9fafb"; radius: 6;
                                        border.color: editRestPsw.activeFocus ? "#0288d1" : "#d1d5db"; border.width: editRestPsw.activeFocus ? 2 : 1
                                        TextField { id: editRestPsw; anchors.fill: parent; leftPadding: 10; font.pixelSize: 13; selectByMouse: true; echoMode: TextInput.Password; background: null; placeholderText: "REST password" }
                                    }
                                }
                            }

                            // Роздільник перед зоною авторизації та токена
                            Rectangle { Layout.fillWidth: true; height: 1; color: "#e5e7eb"; Layout.topMargin: 4; Layout.bottomMargin: 4 }

                            // Блок перевірки зв'язку та токена
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                // Кнопка перевірки з'єднання (Connect) - тепер вона на всю ширину і має правильний тач-розмір
                                Button {
                                    id: btnConnectREST
                                    property bool isConnected: REST.isConnected
                                    text: isConnected ? "⚡ З'єднання встановлено (Перепідключити)" : "🔌 Перевірити з'єднання (Connect)"
                                    font.pixelSize: 13
                                    font.bold: true
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 38

                                    background: Rectangle {
                                        color: btnConnectREST.isConnected ? (btnConnectREST.pressed ? "#1b5e20" : (btnConnectREST.hovered ? "#2e7d32" : "#4caf50"))
                                                                     : (btnConnectREST.pressed ? "#b0bec5" : (btnConnectREST.hovered ? "#cfd8dc" : "#eaedf0"))
                                        radius: 6
                                    }

                                    contentItem: Text {
                                        text: parent.text; font: parent.font
                                        color: editRestToken.text !== "" ? "white" : "#37474f"
                                        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                                    }

                                    onClicked: {
                                        editRestToken.text = "";
                                        btnConnectREST.isConnected = false;
                                        REST.setParam(editRestHost.text.trim(),
                                                      editRestApi.text.trim(),
                                                      editRestUser.text.trim(),
                                                      editRestPsw.text.trim(),
                                                      editRestToken.text.trim())

                                        REST.connect((err, msg) => {
                                            if (!err) {
                                                editRestToken.text = REST.TOKEN;
                                                root.vkEvent("info", "З'єднання з REST сервером успішно встановлено!");
                                            } else {
                                                root.vkEvent("error", "Помилка REST шлюзу: " + String(msg));
                                            }
                                            btnConnectREST.isConnected = REST.isConnected;
                                        });
                                    }
                                }

                                // Поле відображення токена (Token)
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 4
                                    Label { text: "🔑 Авторизаційний токен сесії (Bearer Token)"; font.pixelSize: 11; font.bold: true; color: "#6b7280" }
                                    Rectangle {
                                        Layout.fillWidth: true; height: 38; color: "#f3f4f6"; radius: 6; // Світло-сірий фон для readOnly поля
                                        border.color: editRestToken.text !== "" ? "#4caf50" : "#d1d5db"
                                        border.width: 1

                                        TextField {
                                            id: editRestToken
                                            anchors.fill: parent; leftPadding: 10; font.pixelSize: 12; font.family: "monospace"
                                            selectByMouse: true; readOnly: true; background: null
                                            color: text !== "" ? "#2e7d32" : "#757575"
                                            placeholderText: "Токен відсутній. Натисніть 'Connect' для авторизації..."
                                        }
                                    }
                                }
                            }
                        }
                    }
                    UIBtn{
                        id: btnSaveREST
                        palette: "blue"
                        text: "💾 Зберегти зміни REST API"
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44
                        onClicked: {
                            REST.setParam(editRestHost.text.trim(),
                                          editRestApi.text.trim(),
                                          editRestUser.text.trim(),
                                          editRestPsw.text.trim(),
                                          editRestToken.text.trim())

                            if (REST.save(dbDriver)) {
                                root.vkEvent("info", "Конфігурацію зв'язку з сервером успішно збережено");
                            } else {
                                root.vkEvent("error", "Помилка запису мережевих налаштувань у базу SQLite");
                            }
                        }

                    }

                    UIBtn{
                        id: btnSyncBalanceREST
                        text: "Синхронізувати баланс з REST"
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44

                        onClicked: {
                            REST.uploadBalance2(dbDriver, 0,
                                                (e) => {
                                                   if (!!e) root.vkEvent("error", e || "REST sync error");
                                                });
                        }
                    }
                }
            }

            ScrollView {
                id: taxTab
                clip: true
                Layout.fillWidth: true
                Layout.fillHeight: true

                ColumnLayout {
                    // Залишаємо відступ для комфортного скролу на POS-терміналах
                    width: taxTab.width - 16
                    spacing: 14

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: taxColumn.implicitHeight + 32
                        color: "#ffffff"
                        radius: 12
                        border.color: "#e5e7eb"
                        border.width: 1

                        ColumnLayout {
                            id: taxColumn
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 14

                            // Поле 1: Host URL фіскального сервера
                            UITextField{
                                id: editTaxHost;
                                Layout.fillWidth: true
                                Layout.preferredHeight: 56
                                title: "🖥 Адреса фіскального сервера (Tax Host URL)"
                                placeholderText: "Наприклад: http://localhost:8080 або https://check.gov.ua"
                            }

                            // Поле 2: API Ендпоінт драйвера РРО
                            UITextField{
                                id: editTaxApi;
                                Layout.fillWidth: true
                                Layout.preferredHeight: 56
                                title: "📦 Шлях до фіскального API (Tax API Endpoint)"
                                placeholderText: "Наприклад: api/v1/rro або prro/sign"
                            }

                            // Поле 3: Ідентифікатор касового апарату (Cash ID)
                            UITextField{
                                id: editTaxCash;
                                Layout.fillWidth: true
                                Layout.preferredHeight: 56
                                title: "🆔 Номер каси / Фіскальний код ПРРО (Cash ID)"
                                placeholderText: "Введіть унікальний фіскальний номер каси..."
                            }

                            Rectangle { Layout.fillWidth: true; height: 1; color: "#e5e7eb"; Layout.topMargin: 4; Layout.bottomMargin: 4 }

                            // Блок авторизації ПРРО та отримання сесійного ключа
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                // Кнопка: Перевірити фіскальне з'єднання (Connect)
                                Button {
                                    id: btnConnectTAX
                                    property bool isConnected: TAX.isConnected
                                    text: isConnected ? "✅ РРО авторизовано (Перепідключити)" : "⚙ Перевірити зв'язок з ПРРО (Connect)"
                                    font.pixelSize: 13
                                    font.bold: true
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 38

                                    background: Rectangle {
                                        color: btnConnectTAX.isConnected ? (btnConnectTAX.pressed ? "#1b5e20" : (btnConnectTAX.hovered ? "#2e7d32" : "#4caf50"))
                                                                       : (btnConnectTAX.pressed ? "#b0bec5" : (btnConnectTAX.hovered ? "#cfd8dc" : "#eaedf0"))
                                        radius: 6
                                    }

                                    contentItem: Text {
                                        text: parent.text; font: parent.font
                                        color: "#37474f"
                                        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                                    }

                                    onClicked: {
                                        btnConnectTAX.isConnected = false;
                                        TAX.setParam(editTaxHost.text.trim(),
                                                     editTaxApi.text.trim(),
                                                     editTaxCash.text.trim(),
                                                     editTaxToken.text.trim());

                                        TAX.connect((err, errorMsg) => {
                                            if (!err) {
                                                root.vkEvent("info", "З'єднання з фіскальним сервером успішно встановлено!");
                                            } else {
                                                root.vkEvent("error", "Помилка фіскального шлюзу: " + String(errorMsg));
                                            }
                                            btnConnectTAX.isConnected = TAX.isConnected;
                                        });
                                    }
                                }

                                // Поле 4: Сесійний Фіскальний Токен (Token - ReadOnly)
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 4
                                    Label { text: "🔑 Фіскальний токен відкритої зміни (Tax Token)"; font.pixelSize: 11; font.bold: true; color: "#6b7280" }
                                    Rectangle {
                                        Layout.fillWidth: true; height: 38; color: "#f3f4f6"; radius: 6;
                                        border.color: editTaxToken.text !== "" ? "#4caf50" : "#d1d5db"
                                        border.width: 1

                                        TextField {
                                            id: editTaxToken
                                            anchors.fill: parent; leftPadding: 10; font.pixelSize: 12; font.family: "monospace"
                                            selectByMouse: true; background: null
                                            color: text !== "" ? "#2e7d32" : "#757575"
                                            placeholderText: "Токен відсутній. Перевірте з'єднання для відкриття фіскальної сесії..."
                                        }
                                    }
                                }
                            }
                        }
                    }

                    UIBtn{
                        id: btnSaveTAX
                        palette: "blue"
                        text: "💾 Зберегти конфігурацію РРО / ПРРО"
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44
                        onClicked: {
                            TAX.setParam(editTaxHost.text.trim(),
                                         editTaxApi.text.trim(),
                                         editTaxCash.text.trim(),
                                         editTaxToken.text.trim());

                            const ok = TAX.save(root.dbDriver);

                            if (ok) {
                                root.vkEvent("info", "Параметри фіскалізації успішно збережено в базі даних каси");
                            } else {
                                root.vkEvent("error", "Помилка запису фіскальної конфігурації у локальну базу SQLite");
                            }
                        }
                    }

                    UIBtn{
                        id: btnRestoreTAX
                        text: "Відновити конфігурацію РРО / ПРРО"
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44

                        onClicked: loadTAX();
                    }

                }
            }

            ScrollView {
                id: dfltAcntTab
                clip: true
                Layout.fillWidth: true
                Layout.fillHeight: true

                ColumnLayout {
                    width: dfltAcntTab.width - 16
                    spacing: 14

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: acntColumn.implicitHeight + 32
                        color: "#ffffff"
                        radius: 12
                        border.color: "#e5e7eb"
                        border.width: 1

                        ColumnLayout {
                            id: acntColumn
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 14

                            // 1. Поле: Готівка (Default pre-fix: 30)
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                Label { text: "💰 Основна каса готівки (Cash Account)"; font.pixelSize: 11; font.bold: true; color: "#6b7280" }
                                RowLayout {
                                    spacing: 6
                                    Rectangle { width: 36; height: 38; color: "#e3f2fd"; radius: 6; border.color: "#bbdefb"; Label { text: JS.glCashPrefix || "30"; font.bold: true; color: "#1565c0"; anchors.centerIn: parent } }
                                    Rectangle {
                                        Layout.fillWidth: true; height: 38; radius: 6
                                        color: editAcntCash.text !== "" ? "#ffffff" : "#f3f4f6"
                                        border.color: editAcntCash.activeFocus ? "#0288d1" : (editAcntCash.text !== "" ? "#9ca3af" : "#d1d5db")
                                        border.width: editAcntCash.activeFocus ? 2 : 1
                                        TextField { id: editAcntCash;
                                            anchors.fill: parent;
                                            leftPadding: 10;
                                            font.pixelSize: 13;
                                            font.bold: text !== "";
                                            color: "#1f2937";
                                            selectByMouse: true;
                                            background: null; placeholderText: "00";
                                            placeholderTextColor: "#9ca3af"
                                        }
                                    }
                                }
                            }

                            // 2. Поле: Сейф TRADE (Default pre-fix: 35)
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                Label { text: "🏬 Роздрібний TRADE (Trade Account)"; font.pixelSize: 11; font.bold: true; color: "#6b7280" }
                                RowLayout {
                                    spacing: 6
                                    Rectangle { width: 36; height: 38; color: "#fff3e0"; radius: 6; border.color: "#ffe0b2"; Label { text: JS.glTradePrefix || "35"; font.bold: true; color: "#e65100"; anchors.centerIn: parent } }
                                    Rectangle {
                                        Layout.fillWidth: true; height: 38; radius: 6
                                        color: editAcntTrade.text !== "" ? "#ffffff" : "#f3f4f6"
                                        border.color: editAcntTrade.activeFocus ? "#0288d1" : (editAcntTrade.text !== "" ? "#9ca3af" : "#d1d5db")
                                        border.width: editAcntTrade.activeFocus ? 2 : 1
                                        TextField { id: editAcntTrade;
                                            anchors.fill: parent;
                                            leftPadding: 10;
                                            font.pixelSize: 13;
                                            font.bold: text !== "";
                                            color: "#1f2937";
                                            selectByMouse: true;
                                            background: null;
                                            placeholderText: "00";
                                            placeholderTextColor: "#9ca3af"
                                        }
                                    }
                                }
                            }

                            // 3. Поле: Опт/Гуртові операції BULK (Default pre-fix: 35)
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                Label { text: "📦 Гуртовий рахунок (Bulk Account)"; font.pixelSize: 11; font.bold: true; color: "#6b7280" }
                                RowLayout {
                                    spacing: 6
                                    Rectangle { width: 36; height: 38; color: "#fff3e0"; radius: 6; border.color: "#ffe0b2"; Label { text: JS.glTradePrefix || "35"; font.bold: true; color: "#e65100"; anchors.centerIn: parent } }
                                    Rectangle {
                                        Layout.fillWidth: true; height: 38; radius: 6
                                        color: editAcntBulk.text !== "" ? "#ffffff" : "#f3f4f6"
                                        border.color: editAcntBulk.activeFocus ? "#0288d1" : (editAcntBulk.text !== "" ? "#9ca3af" : "#d1d5db")
                                        border.width: editAcntBulk.activeFocus ? 2 : 1
                                        TextField { id: editAcntBulk;
                                            anchors.fill: parent;
                                            leftPadding: 10;
                                            font.pixelSize: 13;
                                            font.bold: text !== "";
                                            color: "#1f2937";
                                            selectByMouse: true;
                                            background: null;
                                            placeholderText: "01";
                                            placeholderTextColor: "#9ca3af"
                                        }
                                    }
                                }
                            }

                            // 4. Поле: Інкасація INCAS (Default pre-fix: 30)
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                Label { text: "🚚 Транзитний рахунок між підрозділами"; font.pixelSize: 11; font.bold: true; color: "#6b7280" }
                                RowLayout {
                                    spacing: 6
                                    Rectangle { width: 36; height: 38; color: "#e3f2fd"; radius: 6; border.color: "#bbdefb"; Label { text: JS.glCashPrefix || "30"; font.bold: true; color: "#1565c0"; anchors.centerIn: parent } }
                                    Rectangle {
                                        Layout.fillWidth: true; height: 38; radius: 6
                                        color: editAcntIncas.text !== "" ? "#ffffff" : "#f3f4f6"
                                        border.color: editAcntIncas.activeFocus ? "#0288d1" : (editAcntIncas.text !== "" ? "#9ca3af" : "#d1d5db")
                                        border.width: editAcntIncas.activeFocus ? 2 : 1
                                        TextField { id: editAcntIncas;
                                            anchors.fill: parent;
                                            leftPadding: 10;
                                            font.pixelSize: 13;
                                            font.bold: text !== "";
                                            color: "#1f2937";
                                            selectByMouse: true;
                                            background: null;
                                            placeholderText: "03";
                                            placeholderTextColor: "#9ca3af"
                                        }
                                    }
                                }
                            }

                            // 5. Поле: Фінансовий результат PROFIT (Default pre-fix: 36)
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                Label { text: "📊 Рахунок зарахування доходів/результату (Profit Account)"; font.pixelSize: 11; font.bold: true; color: "#6b7280" }
                                RowLayout {
                                    spacing: 6
                                    Rectangle { width: 36; height: 38; color: "#e8f5e9"; radius: 6; border.color: "#c8e6c9"; Label { text: JS.glDepoPrefix || "36"; font.bold: true; color: "#2e7d32"; anchors.centerIn: parent } }
                                    Rectangle {
                                        Layout.fillWidth: true; height: 38; radius: 6
                                        color: editAcntProfit.text !== "" ? "#ffffff" : "#f3f4f6"
                                        border.color: editAcntProfit.activeFocus ? "#0288d1" : (editAcntProfit.text !== "" ? "#9ca3af" : "#d1d5db")
                                        border.width: editAcntProfit.activeFocus ? 2 : 1
                                        TextField { id: editAcntProfit;
                                            anchors.fill: parent;
                                            leftPadding: 10;
                                            font.pixelSize: 13;
                                            font.bold: text !== "";
                                            color: "#1f2937";
                                            selectByMouse: true;
                                            background: null;
                                            placeholderText: "07-55";
                                            placeholderTextColor: "#9ca3af"
                                        }
                                    }
                                }
                            }
                        }
                    }

                    UIBtn{
                        id: btnSaveAccounts
                        palette: "blue"
                        text: "💾 Зберегти аналітичні рахунки"
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44

                        onClicked: {
                            const cashTxt = editAcntCash.text.trim();
                            const tradeTxt = editAcntTrade.text.trim();
                            const bulkTxt = editAcntBulk.text.trim();
                            const incasTxt = editAcntIncas.text.trim();
                            const profitTxt = editAcntProfit.text.trim();

                            const val = {};
                            if (!!cashTxt) val.cash = (JS.glCashPrefix || "30") + cashTxt
                            if (!!tradeTxt) val.trade = (JS.glTradePrefix || "35") + tradeTxt
                            if (!!bulkTxt) val.bulk = (JS.glTradePrefix || "35") + bulkTxt
                            if (!!incasTxt) val.incas = (JS.glCashPrefix || "30") + incasTxt
                            if (!!profitTxt) val.profit = (JS.glDepoPrefix || "36") + profitTxt

                            const ok = JS.setAcntList(dbDriver, val);

                            if (ok) {
                                root.vkEvent("info", "Конфігурацію рахунків обліку успішно збережено в базі каси");
                            } else {
                                root.vkEvent("error", "Помилка збереження плану рахунків у SQLite");
                            }
                        }
                    }
                }
            }

            ScrollView {
                id: acntTab
                clip: true
                Layout.fillWidth: true
                Layout.fillHeight: true
                ColumnLayout {
                    // Залишаємо відступ для комфортного скролу на POS-терміналах
                    width: acntTab.width - 16
                    spacing: 14
                    RowLayout{
                        Layout.fillWidth: true
                        Label { text: qsTr("Рахунок:"); font { pixelSize: 11; bold: true } color: "#4B5563" }
                        ComboBox {
                            id: acntTabCombo
                            textRole: "name"
                            valueRole: "code"
                            model:ListModel{}
                            Layout.fillWidth: true
                            onCurrentValueChanged: loadAcntTab(currentValue);
                        }
                    }
                    UITextField{
                        id: editAcntTabNote
                        Layout.fillWidth: true
                        Layout.preferredHeight: 56
                        title: "Опис, примітка"
                        placeholderText: "Введіть короткий опис або примітку..."
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 4
                        ColumnLayout {
                            spacing: 2
                            Layout.fillWidth: true
                            Label { text: "Маска"; font.pixelSize: 13; font.bold: true; color: "#1f2937" }
                            Label { text: "Дозвіл на операції"; font.pixelSize: 11; color: "#6b7280" }
                        }
                        CheckBox {
                            id: editAcntTabMaskDomestic
                            text: "НАЦ.ВАЛЮТА"
                            font.pixelSize: 14
                        }
                        CheckBox {
                            id: editAcntTabMaskForeign
                            text: "ІНОЗ.ВАЛЮТА"
                            font.pixelSize: 14
                        }
                        CheckBox {
                            id: editAcntTabMaskArticles
                            text: "ТОВАРИ"
                            font.pixelSize: 14
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 4
                        ColumnLayout {
                            spacing: 2
                            Layout.fillWidth: true
                            Label { text: "Торговий"; font.pixelSize: 13; font.bold: true; color: "#1f2937" }
                            Label { text: "Рахунок для торгових операцій (купівля, продаж)"; font.pixelSize: 11; color: "#6b7280" }
                        }
                        Switch {
                            id: editAcntTabTrade
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }
                    UIBtn{
                        id: btnSaveAcntTab
                        palette: "blue"
                        text: "💾 Зберегти зміни"
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44
                        onClicked: {
                            if (editAcntTabTrade.checked && editAcntTabMaskDomestic.checked){
                                root.vkEvent("error", "НАЦ.ВАЛЮТА заборонені для Торгового рахунку");
                                return;
                            }

                            const noteVal = editAcntTabNote.text.trim();
                            const maskVal = (editAcntTabMaskDomestic.checked ? 1 : 0)
                            + (editAcntTabMaskForeign.checked ? 2 : 0)
                            + (editAcntTabMaskArticles.checked ? 4 : 0)
                            const tradeVal = editAcntTabTrade.checked ? 1 : 0
                            // console.log(`II: AppSettings.qml#q6t3 noteVal=${noteVal} maskVal=[${maskVal}] tradeVal=[${tradeVal}]`)

                            const ok = LibAcnt.updAcntbal(root.dbDriver, acntTabCombo.currentValue, noteVal, maskVal, tradeVal)
                            if (ok) {
                                root.vkEvent("info", "Рахунок успішно оновлено");
                                loadAcntTab(acntTabCombo.currentValue)
                            } else root.vkEvent("error", "Помилка оновлення рахунку");
                        }
                    }
                }
            }
        }
    }
}










