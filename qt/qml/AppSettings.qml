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

    function isBasicTabChanged(){
        const id = editTerm.text.trim();
        const appmode = modeGroup.currentModeid;
        const name = editTermName.text.trim();
        const amnt_sign = editCheckAmnt.text.trim();
        const pos_printer = editPrinter.text.trim();
        const auto_print = switchAutoPrint.checked ? "1" : "0";
        const print_dcm = editCheckPrintDcm.text.trim();
        return String(basicTab.dataObj?.id || "TEST") !== id
            || String(basicTab.dataObj?.name || "") !== name
            || String(basicTab.dataObj?.pos_printer || "") !== pos_printer
            || String(basicTab.dataObj?.amnt_sign || "1") !== amnt_sign
            || String(basicTab.dataObj?.auto_print || "0") !== auto_print
            || String(basicTab.dataObj?.print_dcm || "check") !== print_dcm
            || Number(basicTab.dataObj?.appmode || 3) !== appmode;
    }

    function populateBasicTab(jval){
        basicTab.dataObj = jval;
        btnSaveSettings.enabled = false;
        modeGroup.currentModeid = Number(jval?.appmode || 3);
        editTerm.text = String(jval?.id || "TEST");
        editTermName.text = String(jval?.name || "");
        editPrinter.text = String(jval?.pos_printer || "");
        editCheckAmnt.text = String(jval?.amnt_sign || "1");

        if (typeof switchAutoPrint !== "undefined") {
            switchAutoPrint.checked = String(jval?.auto_print || "0") === "1";
        }
        editCheckPrintDcm.text = String(jval?.print_dcm || "check");
    }

    function refreshRESTConn(){
        const host = editRestHost.text.trim();
        const api = editRestApi.text.trim();
        const user = editRestUser.text.trim();
        const psw = editRestPsw.text.trim();
        if (host === REST.HOST
                && api === REST.API
                && user === REST.USER
                && psw === REST.PSW){
            editRestToken.text = REST.TOKEN;
            restTab.connected = !!REST.isConnected;
            btnSaveREST.enabled = false
            btnRestoreREST.enabled = false
        } else {
            editRestToken.text = "";
            restTab.connected = false;
            btnSaveREST.enabled = true
            btnRestoreREST.enabled = true
        }
    }

    function populateREST(){
        editRestHost.text = REST?.HOST || "";
        editRestApi.text = REST?.API || "";
        editRestUser.text = REST?.USER || "";
        editRestPsw.text = REST?.PSW || "";
        editRestToken.text = REST?.TOKEN || "";
        restTab.connected = REST?.isConnected || false;

    }

    function refreshTAXConn(){
        const host = editTaxHost.text.trim();
        const api = editTaxApi.text.trim();
        const cash = editTaxCash.text.trim();
        const token = editTaxToken.text.trim();
        if (host === TAX.HOST
                && api === TAX.API
                && cash === TAX.CASH
                && token === TAX.TOKEN){
            taxTab.connected = !!TAX.isConnected;
            btnSaveTAX.enabled = false
            btnRestoreTAX.enabled = false
        } else {
            taxTab.connected = false;
            btnSaveTAX.enabled = true
            btnRestoreTAX.enabled = true
        }
    }

    function populateTAX(){
        editTaxHost.text = TAX?.HOST || "";
        editTaxApi.text = TAX?.API || "";
        editTaxCash.text = TAX?.CASH || "";
        editTaxToken.text = TAX?.TOKEN || "";
        taxTab.connected = TAX?.isConnected || false;
    }

    function isAcntTabChanged(){
        const noteVal = editAcntTabNote.text.trim();
        const maskVal = (editAcntTabMaskDomestic.checked ? 1 : 0)
        + (editAcntTabMaskForeign.checked ? 2 : 0)
        + (editAcntTabMaskArticles.checked ? 4 : 0)
        const tradeVal = editAcntTabTrade.checked ? 1 : 0;

        return acntTab.dataObj.note !== noteVal
            || acntTab.dataObj.mask !== maskVal
            || acntTab.dataObj.trade !== tradeVal;
    }

    function populateAcntTab(acnt){
        acntTab.dataObj = acnt;
        btnSaveAcntTab.enabled = false;
        btnAcntTabCrntAcnt.text = `${acnt.acntno} - ${acnt.note || ("[" + acnt.name + "]")} ${acnt.clname || ""}`;
        editAcntTabNote.text = acnt.note;
        editAcntTabMaskDomestic.checked = (Number(acnt.mask || 0) & 1) === 1;
        editAcntTabMaskForeign.checked = (Number(acnt.mask || 0) & 2) === 2;
        editAcntTabMaskArticles.checked = (Number(acnt.mask || 0) & 4) === 4;
        editAcntTabTrade.checked = (Number(acnt.trade || 0) === 1);
    }

    // --- Блок логіки вкладок ---
    Action {
        id: actBasic
        text: "Базові"
        onTriggered: {
            stack.currentIndex = 0;
            const val = JS.getBasic(dbDriver);
            populateBasicTab(val);

        }
    }

    Action {
            id: actREST
            text: "REST API"
            onTriggered: {
                stack.currentIndex = 1;
                populateREST();
            }
        }

    Action {
        id: actTAX
        text: "ПРРО / Фіскалізація"
        onTriggered: {
            populateTAX();
            // console.log(`AppSettings.qml 23sde`)
            stack.currentIndex = 2;
        }
    }
    function populateDfltAcntTab(jval){

        const cashStr = String(jval?.cash || "");
        const tradeStr = String(jval?.trade || "");
        const bulkStr = String(jval?.bulk || "");
        const incasStr = String(jval?.incas || "");
        const profitStr = String(jval?.profit || "");

        const cashSuffix = cashStr.substring(Math.min(cashStr.length, (JS.glCashPrefix || "30").length));
        const tradeSuffix = tradeStr.substring(Math.min(tradeStr.length, (JS.glTradePrefix || "35").length));
        const bulkSuffix = bulkStr.substring(Math.min(bulkStr.length, (JS.glTradePrefix || "35").length));
        const incasSuffix = incasStr.substring(Math.min(incasStr.length, (JS.glCashPrefix || "30").length));
        const profitSuffix = profitStr.substring(Math.min(profitStr.length, (JS.glDepoPrefix || "36").length));

        // Відсікаємо префікси, захищаючи довжину рядка
        dfltAcntTab.dataObj = {
            cash: cashSuffix,
            trade: tradeSuffix,
            bulk: bulkSuffix,
            incas: incasSuffix,
            profit: profitSuffix,
        }
        editAcntCash.text = cashSuffix;
        editAcntTrade.text = tradeSuffix;
        editAcntBulk.text = bulkSuffix;
        editAcntIncas.text = incasSuffix;
        editAcntProfit.text = profitSuffix;
        btnSaveDfltAcntTab.enabled = false;
        btnRestoreDfltAcntTab.enabled = false;
    }

    function refreshDfltAcntTab(){
        const cashTxt = editAcntCash.text.trim();
        const tradeTxt = editAcntTrade.text.trim();
        const bulkTxt = editAcntBulk.text.trim();
        const incasTxt = editAcntIncas.text.trim();
        const profitTxt = editAcntProfit.text.trim();

        if (dfltAcntTab.dataObj.cash !== cashTxt
            || dfltAcntTab.dataObj.trade !== tradeTxt
        || dfltAcntTab.dataObj.bulk !== bulkTxt
        || dfltAcntTab.dataObj.incas !== incasTxt
        || dfltAcntTab.dataObj.profit !== profitTxt){
            btnSaveDfltAcntTab.enabled = true;
            btnRestoreDfltAcntTab.enabled = true;
        } else {
            btnSaveDfltAcntTab.enabled = false;
            btnRestoreDfltAcntTab.enabled = false;
        }
    }


    Action {
        id: actDfltAccounts
        text: "Тирові рахунки"
        onTriggered: {
            stack.currentIndex = 3; // Перемикаємо StackLayout на вкладку №4
            if (!root.dbDriver) return;
            const val = JS.getAcntList(dbDriver);
            populateDfltAcntTab(val);
        }
    }
    Action {
        id: actAccounts
        text: "Параметри рахунків"
        onTriggered: {
            stack.currentIndex = 4;
            const acnt = LibAcnt.DfltAcnt.cash(dbDriver);
            populateAcntTab(acnt);
        }
    }
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
                      stack.currentIndex === 1 ? "REST API" :
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
                property var dataObj
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
                                            btnSaveSettings.enabled = isBasicTabChanged();
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
                                onTextChanged: btnSaveSettings.enabled = isBasicTabChanged();
                            }
                            // Поле: Назва терміналу
                            UITextField{
                                id: editTermName;
                                Layout.fillWidth: true
                                Layout.preferredHeight: 56
                                title: "Ідентифікатор (Назва терміналу)"
                                placeholderText: "Введіть назву каси..."
                                onTextChanged: btnSaveSettings.enabled = isBasicTabChanged();
                            }
                            // Поле: POS Принтер
                            UITextField{
                                id: editPrinter;
                                Layout.fillWidth: true
                                Layout.preferredHeight: 56
                                title: "Мережеве ім'я POS-принтера чеків"
                                placeholderText: "Наприклад: POSprn"
                                onTextChanged: btnSaveSettings.enabled = isBasicTabChanged();
                            }
                            // Поле: Знак операції
                            UITextField{
                                id: editCheckAmnt;
                                Layout.fillWidth: true
                                Layout.preferredHeight: 56
                                title: "Математичний знак суми (Amount Sign)"
                                placeholderText: "-1 (витратний чек) | 1 (прибутковий)"
                                onTextChanged: btnSaveSettings.enabled = isBasicTabChanged();
                            }
                            // Поле: Шаблон друку
                            UITextField{
                                id: editCheckPrintDcm;
                                Layout.fillWidth: true
                                Layout.preferredHeight: 56
                                title: "Дефолтний шаблон друку документа"
                                placeholderText: "Наприклад: check або check_knt"
                                onTextChanged: btnSaveSettings.enabled = isBasicTabChanged();
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
                                    onClicked: btnSaveSettings.enabled = isBasicTabChanged();
                                }
                            }
                        }
                    }

                    UIBtn{
                        id: btnSaveSettings
                        enabled: false
                        palette: enabled ? "blue" : ""
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
                                const val = JS.getBasic(dbDriver);
                                if (!!val) populateBasicTab(val);
                                root.vkEvent("modeidChanged", modeGroup.currentModeid);
                                root.vkEvent("info", "Конфігурацію успішно збережено");
                            } else root.vkEvent("error", "Помилка збереження конфігурації")
                        }
                    }

                }
            }

            ScrollView {
                id: restTab
                property bool connected: false
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
                                    onTextChanged: refreshRESTConn()
                                }
                                // Поле: API version
                                UITextField{
                                    id: editRestApi;
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 56
                                    title: "📦 Версія / Ендпоінт API (API Version)"
                                    placeholderText: "Введіть версію API (api/v1) ..."
                                    onTextChanged: refreshRESTConn()
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
                                    onTextChanged: refreshRESTConn()
                                }
                                UITextField{
                                    id: editRestPsw;
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 56
                                    title: "🔑 Пароль (Password)"
                                    echoMode: TextInput.Password;
                                    placeholderText: "REST password"
                                    onTextChanged: refreshRESTConn()
                                }
                            }

                            // Роздільник перед зоною авторизації та токена
                            Rectangle { Layout.fillWidth: true; height: 1; color: "#e5e7eb"; Layout.topMargin: 4; Layout.bottomMargin: 4 }

                            // Блок перевірки зв'язку та токена
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                // Кнопка перевірки з'єднання (Connect) - тепер вона на всю ширину і має правильний тач-розмір
                                UIBtn{
                                    id: btnConnectREST
                                    palette: restTab.connected ? "green" : ""
                                    text: restTab.connected ? "⚡ З'єднання встановлено (Перепідключити)" : "🔌 Перевірити з'єднання (Connect)"
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 44
                                    onClicked: {
                                        editRestToken.text = "";
                                        restTab.connected = false;
                                        REST.setParam(editRestHost.text.trim(),
                                                      editRestApi.text.trim(),
                                                      editRestUser.text.trim(),
                                                      editRestPsw.text.trim(),
                                                      editRestToken.text.trim())

                                        REST.connect((err, msg) => {
                                            restTab.connected = REST.isConnected;
                                            editRestToken.text = REST.TOKEN;
                                            if (!err) {
                                                root.vkEvent("info", "З'єднання з REST сервером успішно встановлено!");
                                            } else {
                                                root.vkEvent("error", "Помилка REST шлюзу: " + String(msg));
                                            }
                                        });
                                    }
                                }
                                UITextField{
                                    id: editRestToken;
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 56
                                    title: "🔑 Авторизаційний токен сесії (Bearer Token)"
                                    readOnly: true
                                    placeholderText: "Токен відсутній. Натисніть 'Connect' для авторизації..."
                                    color: "#2e7d32"
                                }
                            }
                        }
                    }
                    UIBtn{
                        id: btnSaveREST
                        enabled: false
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
                        id: btnRestoreREST
                        enabled: false
                        text: "Відновити конфігурацію REST"
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44

                        onClicked: {
                            if (!dbDriver) return;
                            REST.restore(dbDriver);
                            populateREST();
                        }
                    }

                    RowLayout{
                        Layout.fillWidth: true
                        // Layout.preferredHeight: 44
                        spacing: 10
                        UIBtn{
                            id: btnSyncBalanceREST
                            // Layout.fillWidth: true
                            Layout.preferredHeight: 44
                            text: "Синхронізувати баланс з REST"

                            onClicked: {
                                REST.setBalanceSync();      // reset to ""
                                REST.uploadBalance(dbDriver,
                                                    (e) => {
                                                       if (!!e) root.vkEvent("error", e || "REST sync error");
                                                    });
                            }
                        }
                        Item{
                            Layout.fillWidth: true
                            Layout.preferredHeight: 44

                        }

                    }

                }
            }

            ScrollView {
                id: taxTab
                property bool connected: false
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

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10
                                UITextField{
                                    id: editTaxHost;
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 56
                                    title: "🖥 Адреса фіскального сервера (Tax Host URL)"
                                    placeholderText: "Наприклад: http://localhost:8080 або https://check.gov.ua"
                                    onTextChanged: refreshTAXConn()
                                }

                                UITextField{
                                    id: editTaxApi;
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 56
                                    title: "📦 Шлях до фіскального API (Tax API Endpoint)"
                                    placeholderText: "Наприклад: api/v1/rro або prro/sign"
                                    onTextChanged: refreshTAXConn()
                                }
                            }

                            UITextField{
                                id: editTaxCash;
                                Layout.fillWidth: true
                                Layout.preferredHeight: 56
                                title: "🆔 Номер каси / Фіскальний код ПРРО (Cash ID)"
                                placeholderText: "Введіть унікальний фіскальний номер каси..."
                                onTextChanged: refreshTAXConn()
                            }

                            Rectangle { Layout.fillWidth: true; height: 1; color: "#e5e7eb"; Layout.topMargin: 4; Layout.bottomMargin: 4 }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                // Кнопка: Перевірити фіскальне з'єднання (Connect)
                                UIBtn{
                                    id: btnConnectTAX
                                    palette: taxTab.connected ? "green" : ""
                                    text: taxTab.connected ? "✅ РРО авторизовано (Перепідключити)" : "⚙ Перевірити зв'язок з ПРРО (Connect)"
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 44
                                    onClicked: {
                                        taxTab.connected = false;
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
                                            taxTab.connected = TAX.isConnected;
                                        });
                                    }
                                }

                                UITextField{
                                    id: editTaxToken;
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 56
                                    title: "🔑 Фіскальний токен сесії (Tax Token)"
                                    placeholderText: "Токен відсутній. Натисніть 'Connect' для авторизації..."
                                    color: "#2e7d32"
                                    onTextChanged: refreshTAXConn()
                                }
                            }
                        }
                    }

                    UIBtn{
                        id: btnSaveTAX
                        enabled: false
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
                        enabled: false
                        text: "Відновити конфігурацію РРО / ПРРО"
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44

                        onClicked: {
                            if (!dbDriver) return;
                            TAX.restore(dbDriver);
                            populateTAX();
                        }
                    }

                }
            }

            ScrollView {
                id: dfltAcntTab
                property var dataObj
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
                                    UITextField{
                                        id: editAcntCash
                                        Layout.fillWidth: true
                                        placeholderText: "00"
                                        onTextChanged: refreshDfltAcntTab()
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
                                    UITextField{
                                        id: editAcntTrade
                                        Layout.fillWidth: true
                                        placeholderText: "00"
                                        onTextChanged: refreshDfltAcntTab()
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
                                    UITextField{
                                        id: editAcntBulk
                                        Layout.fillWidth: true
                                        placeholderText: "00"
                                        onTextChanged: refreshDfltAcntTab()
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
                                    UITextField{
                                        id: editAcntIncas
                                        Layout.fillWidth: true
                                        placeholderText: "00"
                                        onTextChanged: refreshDfltAcntTab();
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
                                    UITextField{
                                        id: editAcntProfit
                                        Layout.fillWidth: true
                                        placeholderText: "00"
                                        onTextChanged: refreshDfltAcntTab();
                                    }
                                }
                            }
                        }
                    }

                    UIBtn{
                        id: btnSaveDfltAcntTab
                        enabled: false
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
                                const val = JS.getAcntList(dbDriver);
                                populateDfltAcntTab(val);
                            } else {
                                root.vkEvent("error", "Помилка збереження плану рахунків у SQLite");
                            }
                        }
                    }

                    UIBtn{
                        id: btnRestoreDfltAcntTab
                        enabled: false
                        text: "Відновити збережені аналітичні рахунки"
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44

                        onClicked: {
                            const val = JS.getAcntList(dbDriver);
                            populateDfltAcntTab(val);
                        }
                    }
                }
            }

            ScrollView {
                id: acntTab
                property var dataObj
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
                        UIBtn{
                            id: btnAcntTabCrntAcnt
                            // property var acnt
                            // palette: "blue"
                            text: "Acnt"
                            Layout.fillWidth: true
                            Layout.preferredHeight: 44
                            onClicked: {
                                const acntSource = LibAcnt.dbAcntbal(dbDriver);
                                const acntLlist = acntSource
                                .sort((a,b) => a.acntno.localeCompare(b.acntno) )
                                .map(v => {
                                    return {
                                       "id": v.acntno,
                                       "name": v.note || v.name,
                                       "fullname": v.name,
                                       "code" : "acntno",
                                       "sect": qsTr("Рахунки")
                                    };
                               })
                                selectPopup.jsdata = acntLlist
                                selectPopup.open()
                            }
                        }
                    }
                    UITextField{
                        id: editAcntTabNote
                        Layout.fillWidth: true
                        Layout.preferredHeight: 56
                        title: "Опис, примітка"
                        placeholderText: "Введіть короткий опис або примітку..."
                        onTextChanged: btnSaveAcntTab.enabled = isAcntTabChanged();
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
                            onClicked: btnSaveAcntTab.enabled = isAcntTabChanged();
                        }
                        CheckBox {
                            id: editAcntTabMaskForeign
                            text: "ІНОЗ.ВАЛЮТА"
                            font.pixelSize: 14
                            onClicked: btnSaveAcntTab.enabled = isAcntTabChanged();
                        }
                        CheckBox {
                            id: editAcntTabMaskArticles
                            text: "ТОВАРИ"
                            font.pixelSize: 14
                            onClicked: btnSaveAcntTab.enabled = isAcntTabChanged();
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
                            onClicked: btnSaveAcntTab.enabled = isAcntTabChanged();
                        }
                    }
                    UIBtn{
                        id: btnSaveAcntTab
                        enabled: false
                        palette: enabled ? "blue" : ""
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
                            const acntno = acntTab.dataObj.acntno || ""
                            if (!acntno){
                                root.vkEvent("error", "Відсутній номер рахуунку");
                                return;
                            }

                            const ok = LibAcnt.updAcntbal(root.dbDriver, acntno, noteVal, maskVal, tradeVal)
                            if (ok) {
                                root.vkEvent("info", "Рахунок успішно оновлено");
                                const acnt = LibAcnt.acntbal(dbDriver, acntno);
                                if (!!acnt) populateAcntTab(acnt);
                            } else root.vkEvent("error", "Помилка оновлення рахунку");
                        }
                    }
                }
            }
        }

        UIPopupSelect{
            id: selectPopup
            // width: 360
            height: root.height * 0.85
            x: (root.width - width) / 2
            y: (root.height - height) / 2 // Центруємо також по вертикалі
            onSelected: (code, id) => {
                const acnt = LibAcnt.acntbal(dbDriver, id);
                if (!!acnt) populateAcntTab(acnt);
                selectPopup.close()
            }
        }
    }


}










