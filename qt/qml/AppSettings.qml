// AppSettings.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "js/v147/config.js" as JS
import "js/libREST.js" as REST
import "js/CashDesk.js" as TAX

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
        id: actAccounts
        text: "Рахунки"
        onTriggered: {
            if (!root.dbDriver) return;
            const val = JS.getVal(dbDriver, root.acntDbKey);
            if (!val) {
                editAcntCash.text = "00";
                editAcntTrade.text = "00";
                editAcntBulk.text = "01";
                editAcntIncas.text = "03";
                editAcntProfit.text = "07-55";
                stack.currentIndex = 3;
                return;
            }

            const cashStr = String(val.cash || "");
            const tradeStr = String(val.trade || "");
            const bulkStr = String(val.bulk || "");
            const incasStr = String(val.incas || "");
            const profitStr = String(val.profit || "");

            // Відсікаємо префікси, захищаючи довжину рядка
            editAcntCash.text = cashStr.substring(Math.min(cashStr.length, (JS.glCashPrefix || "30").length));
            editAcntTrade.text = tradeStr.substring(Math.min(tradeStr.length, (JS.glTradePrefix || "35").length));
            editAcntBulk.text = bulkStr.substring(Math.min(bulkStr.length, (JS.glTradePrefix || "35").length));
            editAcntIncas.text = incasStr.substring(Math.min(incasStr.length, (JS.glCashPrefix || "30").length));
            editAcntProfit.text = profitStr.substring(Math.min(profitStr.length, (JS.glDepoPrefix || "36").length));

            stack.currentIndex = 3; // Перемикаємо StackLayout на вкладку №4
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
                      stack.currentIndex === 2 ? "Фіскалізація та ПРРО" : "Параметри рахунків"
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
                                                console.log("Активний тип:", currentModeid)
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
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                Label { text: "Ідентифікатор (Код терміналу)"; font.pixelSize: 11; font.bold: true; color: "#6b7280" }
                                Rectangle {
                                    Layout.fillWidth: true; height: 38; color: "#f9fafb"; radius: 6; border.color: editTerm.activeFocus ? "#0288d1" : "#d1d5db"; border.width: editTerm.activeFocus ? 2 : 1
                                    TextField { id: editTerm; anchors.fill: parent; leftPadding: 10; font.pixelSize: 13; selectByMouse: true; background: null; placeholderText: "Введіть унікальний код каси..." }
                                }
                            }

                            // Поле: Назва терміналу
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                Label { text: "Ідентифікатор (Назва терміналу)"; font.pixelSize: 11; font.bold: true; color: "#6b7280" }
                                Rectangle {
                                    Layout.fillWidth: true; height: 38; color: "#f9fafb"; radius: 6; border.color: editTermName.activeFocus ? "#0288d1" : "#d1d5db"; border.width: editTermName.activeFocus ? 2 : 1
                                    TextField { id: editTermName; anchors.fill: parent; leftPadding: 10; font.pixelSize: 13; selectByMouse: true; background: null; placeholderText: "Введіть назву каси..." }
                                }
                            }

                            // Поле: POS Принтер
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                Label { text: "Мережеве ім'я POS-принтера чеків"; font.pixelSize: 11; font.bold: true; color: "#6b7280" }
                                Rectangle {
                                    Layout.fillWidth: true; height: 38; color: "#f9fafb"; radius: 6; border.color: editPrinter.activeFocus ? "#0288d1" : "#d1d5db"; border.width: editPrinter.activeFocus ? 2 : 1
                                    TextField { id: editPrinter; anchors.fill: parent; leftPadding: 10; font.pixelSize: 13; selectByMouse: true; background: null; placeholderText: "Наприклад: Sam4s_Xprinter" }
                                }
                            }

                            // Поле: Кратність суми
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                Label { text: "Математичний знак суми (Amount Sign)"; font.pixelSize: 11; font.bold: true; color: "#6b7280" }
                                Rectangle {
                                    Layout.fillWidth: true; height: 38; color: "#f9fafb"; radius: 6; border.color: editCheckAmnt.activeFocus ? "#0288d1" : "#d1d5db"; border.width: editCheckAmnt.activeFocus ? 2 : 1
                                    TextField { id: editCheckAmnt; anchors.fill: parent; leftPadding: 10; font.pixelSize: 13; selectByMouse: true; background: null; placeholderText: "-1 (витратний чек) | 1 (прибутковий)" }
                                }
                            }

                            // Поле: Шаблон друку
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                Label { text: "Дефолтний шаблон друку документа"; font.pixelSize: 11; font.bold: true; color: "#6b7280" }
                                Rectangle {
                                    Layout.fillWidth: true; height: 38; color: "#f9fafb"; radius: 6; border.color: editCheckPrintDcm.activeFocus ? "#0288d1" : "#d1d5db"; border.width: editCheckPrintDcm.activeFocus ? 2 : 1
                                    TextField { id: editCheckPrintDcm; anchors.fill: parent; leftPadding: 10; font.pixelSize: 13; selectByMouse: true; background: null; placeholderText: "Наприклад: check або check_knt" }
                                }
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

                    Button {
                        id: btnSaveSettings
                        text: "💾 Зберегти зміни"
                        font.pixelSize: 14
                        font.bold: true
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44

                        background: Rectangle {
                            color: btnSaveSettings.pressed ? "#01579b" : (btnSaveSettings.hovered ? "#0277bd" : "#0288d1")
                            radius: 8

                            Rectangle {
                                anchors.fill: parent; anchors.margins: -1; color: "transparent"; border.color: "#20000000"; border.width: 1; radius: 9; z: -1
                            }
                        }

                        contentItem: Text {
                            text: parent.text
                            font: parent.font
                            color: "white"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

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

                            // Поле: Host URL
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                Label { text: "🔗 Адреса REST сервера (Host URL)"; font.pixelSize: 11; font.bold: true; color: "#6b7280" }
                                Rectangle {
                                    Layout.fillWidth: true; height: 38; color: "#f9fafb"; radius: 6;
                                    border.color: editRestHost.activeFocus ? "#0288d1" : "#d1d5db"; border.width: editRestHost.activeFocus ? 2 : 1
                                    TextField { id: editRestHost; anchors.fill: parent; leftPadding: 10; font.pixelSize: 13; selectByMouse: true; background: null; placeholderText: "Введіть REST URL (https://example.com) ..." }
                                }
                            }

                            // Поле: API version
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                Label { text: "📦 Версія / Ендпоінт API (API Version)"; font.pixelSize: 11; font.bold: true; color: "#6b7280" }
                                Rectangle {
                                    Layout.fillWidth: true; height: 38; color: "#f9fafb"; radius: 6;
                                    border.color: editRestApi.activeFocus ? "#0288d1" : "#d1d5db"; border.width: editRestApi.activeFocus ? 2 : 1
                                    TextField { id: editRestApi; anchors.fill: parent; leftPadding: 10; font.pixelSize: 13; selectByMouse: true; background: null; placeholderText: "Введіть версію API (api/v1) ..." }
                                }
                            }

                            // Горизонтальний рядок: Авторизаційні дані (Логін та Пароль)
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                // Поле: Login
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 4
                                    Label { text: "👤 Логін (Login)"; font.pixelSize: 11; font.bold: true; color: "#6b7280" }
                                    Rectangle {
                                        Layout.fillWidth: true; height: 38; color: "#f9fafb"; radius: 6;
                                        border.color: editRestUser.activeFocus ? "#0288d1" : "#d1d5db"; border.width: editRestUser.activeFocus ? 2 : 1
                                        TextField { id: editRestUser; anchors.fill: parent; leftPadding: 10; font.pixelSize: 13; selectByMouse: true; background: null; placeholderText: "REST login" }
                                    }
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

                    Button {
                        id: btnSaveREST
                        text: "💾 Зберегти зміни REST API"
                        font.pixelSize: 14
                        font.bold: true
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44

                        background: Rectangle {
                            color: btnSaveREST.pressed ? "#01579b" : (btnSaveREST.hovered ? "#0277bd" : "#0288d1")
                            radius: 8
                            Rectangle {
                                anchors.fill: parent; anchors.margins: -1; color: "transparent"; border.color: "#20000000"; border.width: 1; radius: 9; z: -1
                            }
                        }

                        contentItem: Text {
                            text: parent.text; font: parent.font; color: "white"
                            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                        }

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

                    Item{
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44
                        RowLayout{
                            width: parent.width
                            // anchors.horizontalCenter: parent.horizontalCenter
                            anchors.verticalCenter: parent.verticalCenter
                            Button {
                                id: btnSyncBalanceREST
                                text: "Синхронізувати баланс з REST"
                                font.pixelSize: 12
                                font.bold: true
                                Layout.fillWidth: true
                                // Layout.preferredHeight: 44

                                // background: Rectangle {
                                //     color: btnSaveREST.pressed ? "#01579b" : (btnSaveREST.hovered ? "#0277bd" : "#0288d1")
                                //     radius: 8
                                //     Rectangle {
                                //         anchors.fill: parent; anchors.margins: -1; color: "transparent"; border.color: "#20000000"; border.width: 1; radius: 9; z: -1
                                //     }
                                // }

                                // contentItem: Text {
                                //     text: parent.text; font: parent.font; color: "white"
                                //     horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                                // }

                                onClicked: {
                                    REST.uploadBalance2(dbDriver, 0,
                                                        (e) => {
                                                           if (!!e) root.vkEvent("error", e || "REST sync error");
                                                        });

                                }
                            }

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
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                Label { text: "🖥 Адреса фіскального сервера (Tax Host URL)"; font.pixelSize: 11; font.bold: true; color: "#6b7280" }
                                Rectangle {
                                    Layout.fillWidth: true; height: 38; color: "#f9fafb"; radius: 6;
                                    border.color: editTaxHost.activeFocus ? "#0288d1" : "#d1d5db"; border.width: editTaxHost.activeFocus ? 2 : 1
                                    TextField { id: editTaxHost; anchors.fill: parent; leftPadding: 10; font.pixelSize: 13; selectByMouse: true; background: null; placeholderText: "Наприклад: http://localhost:8080 або https://check.gov.ua" }
                                }
                            }

                            // Поле 2: API Ендпоінт драйвера РРО
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                Label { text: "📦 Шлях до фіскального API (Tax API Endpoint)"; font.pixelSize: 11; font.bold: true; color: "#6b7280" }
                                Rectangle {
                                    Layout.fillWidth: true; height: 38; color: "#f9fafb"; radius: 6;
                                    border.color: editTaxApi.activeFocus ? "#0288d1" : "#d1d5db"; border.width: editTaxApi.activeFocus ? 2 : 1
                                    TextField { id: editTaxApi; anchors.fill: parent; leftPadding: 10; font.pixelSize: 13; selectByMouse: true; background: null; placeholderText: "Наприклад: api/v1/rro або prro/sign" }
                                }
                            }

                            // Поле 3: Ідентифікатор касового апарату (Cash ID)
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                Label { text: "🆔 Номер каси / Фіскальний код ПРРО (Cash ID)"; font.pixelSize: 11; font.bold: true; color: "#6b7280" }
                                Rectangle {
                                    Layout.fillWidth: true; height: 38; color: "#f9fafb"; radius: 6;
                                    border.color: editTaxCash.activeFocus ? "#0288d1" : "#d1d5db"; border.width: editTaxCash.activeFocus ? 2 : 1
                                    TextField { id: editTaxCash; anchors.fill: parent; leftPadding: 10; font.pixelSize: 13; selectByMouse: true; background: null; placeholderText: "Введіть унікальний фіскальний номер каси..." }
                                }
                            }

                            // Роздільна тонка лінія
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

                    Button {
                        id: btnSaveTAX
                        text: "💾 Зберегти конфігурацію РРО / ПРРО"
                        font.pixelSize: 14
                        font.bold: true
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44

                        background: Rectangle {
                            color: btnSaveTAX.pressed ? "#01579b" : (btnSaveTAX.hovered ? "#0277bd" : "#0288d1")
                            radius: 8
                            Rectangle {
                                anchors.fill: parent; anchors.margins: -1; color: "transparent"; border.color: "#20000000"; border.width: 1; radius: 9; z: -1
                            }
                        }

                        contentItem: Text {
                            text: parent.text; font: parent.font; color: "white"
                            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                        }

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

                    Button {
                        id: btnRestoreTAX
                        text: "Відновити конфігурацію РРО / ПРРО"
                        font.pixelSize: 14
                        font.bold: true
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44

                        background: Rectangle {
                            color: btnRestoreTAX.pressed ? "#b0bec5" : (btnRestoreTAX.hovered ? "#cfd8dc" : "#eaedf0")
                            radius: 8
                            Rectangle {
                                anchors.fill: parent; anchors.margins: -1; color: "transparent"; border.color: "#d1d5db"; border.width: 1; radius: 9; z: -1
                            }
                        }

                        contentItem: Text {
                            text: parent.text; font: parent.font;
                            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                        }

                        onClicked: loadTAX();
                    }

                }
            }

            ScrollView {
                id: acntTab
                clip: true
                Layout.fillWidth: true
                Layout.fillHeight: true

                ColumnLayout {
                    width: acntTab.width - 16
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
                                        TextField { id: editAcntCash; anchors.fill: parent; leftPadding: 10; font.pixelSize: 13; font.bold: text !== ""; color: "#1f2937"; selectByMouse: true; background: null; placeholderText: "00"; placeholderTextColor: "#9ca3af" }
                                    }
                                }
                            }

                            // 2. Поле: Сейф TRADE (Default pre-fix: 35)
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                Label { text: "🏬 Роздрібний сейф TRADE (Trade Account)"; font.pixelSize: 11; font.bold: true; color: "#6b7280" }
                                RowLayout {
                                    spacing: 6
                                    Rectangle { width: 36; height: 38; color: "#fff3e0"; radius: 6; border.color: "#ffe0b2"; Label { text: JS.glTradePrefix || "35"; font.bold: true; color: "#e65100"; anchors.centerIn: parent } }
                                    Rectangle {
                                        Layout.fillWidth: true; height: 38; radius: 6
                                        color: editAcntTrade.text !== "" ? "#ffffff" : "#f3f4f6"
                                        border.color: editAcntTrade.activeFocus ? "#0288d1" : (editAcntTrade.text !== "" ? "#9ca3af" : "#d1d5db")
                                        border.width: editAcntTrade.activeFocus ? 2 : 1
                                        TextField { id: editAcntTrade; anchors.fill: parent; leftPadding: 10; font.pixelSize: 13; font.bold: text !== ""; color: "#1f2937"; selectByMouse: true; background: null; placeholderText: "00"; placeholderTextColor: "#9ca3af" }
                                    }
                                }
                            }

                            // 3. Поле: Опт/Гуртові операції BULK (Default pre-fix: 35)
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                Label { text: "📦 Гуртовий рахунок / Пакування (Bulk Account)"; font.pixelSize: 11; font.bold: true; color: "#6b7280" }
                                RowLayout {
                                    spacing: 6
                                    Rectangle { width: 36; height: 38; color: "#fff3e0"; radius: 6; border.color: "#ffe0b2"; Label { text: JS.glTradePrefix || "35"; font.bold: true; color: "#e65100"; anchors.centerIn: parent } }
                                    Rectangle {
                                        Layout.fillWidth: true; height: 38; radius: 6
                                        color: editAcntBulk.text !== "" ? "#ffffff" : "#f3f4f6"
                                        border.color: editAcntBulk.activeFocus ? "#0288d1" : (editAcntBulk.text !== "" ? "#9ca3af" : "#d1d5db")
                                        border.width: editAcntBulk.activeFocus ? 2 : 1
                                        TextField { id: editAcntBulk; anchors.fill: parent; leftPadding: 10; font.pixelSize: 13; font.bold: text !== ""; color: "#1f2937"; selectByMouse: true; background: null; placeholderText: "01"; placeholderTextColor: "#9ca3af" }
                                    }
                                }
                            }

                            // 4. Поле: Інкасація INCAS (Default pre-fix: 30)
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                Label { text: "🚚 Транзитний рахунок інкасації (Incas Account)"; font.pixelSize: 11; font.bold: true; color: "#6b7280" }
                                RowLayout {
                                    spacing: 6
                                    Rectangle { width: 36; height: 38; color: "#e3f2fd"; radius: 6; border.color: "#bbdefb"; Label { text: JS.glCashPrefix || "30"; font.bold: true; color: "#1565c0"; anchors.centerIn: parent } }
                                    Rectangle {
                                        Layout.fillWidth: true; height: 38; radius: 6
                                        color: editAcntIncas.text !== "" ? "#ffffff" : "#f3f4f6"
                                        border.color: editAcntIncas.activeFocus ? "#0288d1" : (editAcntIncas.text !== "" ? "#9ca3af" : "#d1d5db")
                                        border.width: editAcntIncas.activeFocus ? 2 : 1
                                        TextField { id: editAcntIncas; anchors.fill: parent; leftPadding: 10; font.pixelSize: 13; font.bold: text !== ""; color: "#1f2937"; selectByMouse: true; background: null; placeholderText: "03"; placeholderTextColor: "#9ca3af" }
                                    }
                                }
                            }

                            // 5. Поле: Фінансовий результат PROFIT (Default pre-fix: 36)
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                Label { text: "📊 Рахунок прибутків та збитків / Депозити (Profit Account)"; font.pixelSize: 11; font.bold: true; color: "#6b7280" }
                                RowLayout {
                                    spacing: 6
                                    Rectangle { width: 36; height: 38; color: "#e8f5e9"; radius: 6; border.color: "#c8e6c9"; Label { text: JS.glDepoPrefix || "36"; font.bold: true; color: "#2e7d32"; anchors.centerIn: parent } }
                                    Rectangle {
                                        Layout.fillWidth: true; height: 38; radius: 6
                                        color: editAcntProfit.text !== "" ? "#ffffff" : "#f3f4f6"
                                        border.color: editAcntProfit.activeFocus ? "#0288d1" : (editAcntProfit.text !== "" ? "#9ca3af" : "#d1d5db")
                                        border.width: editAcntProfit.activeFocus ? 2 : 1
                                        TextField { id: editAcntProfit; anchors.fill: parent; leftPadding: 10; font.pixelSize: 13; font.bold: text !== ""; color: "#1f2937"; selectByMouse: true; background: null; placeholderText: "07-55"; placeholderTextColor: "#9ca3af" }
                                    }
                                }
                            }
                        }
                    }

                    Button {
                        id: btnSaveAccounts
                        text: "💾 Зберегти аналітичні рахунки"
                        font.pixelSize: 14
                        font.bold: true
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44

                        background: Rectangle {
                            color: btnSaveAccounts.pressed ? "#01579b" : (btnSaveAccounts.hovered ? "#0277bd" : "#0288d1")
                            radius: 8
                            Rectangle { anchors.fill: parent; anchors.margins: -1; color: "transparent"; border.color: "#20000000"; border.width: 1; radius: 9; z: -1 }
                        }

                        contentItem: Text { text: parent.text; font: parent.font; color: "white"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }

                        onClicked: {
                            const cashTxt = editAcntCash.text.trim();
                            const tradeTxt = editAcntTrade.text.trim();
                            const bulkTxt = editAcntBulk.text.trim();
                            const incasTxt = editAcntIncas.text.trim();
                            const profitTxt = editAcntProfit.text.trim();

                            const val = {
                                "cash":   !cashTxt ? "" : (JS.glCashPrefix || "30") + cashTxt,
                                "trade":  !tradeTxt ? "" : (JS.glTradePrefix || "35") + tradeTxt,
                                "bulk":   !bulkTxt ? "" : (JS.glTradePrefix || "35") + bulkTxt,
                                "incas":  !incasTxt ? "" : (JS.glCashPrefix || "30") + incasTxt,
                                "profit": !profitTxt ? "" : (JS.glDepoPrefix || "36") + profitTxt
                            };

                            const ok = JS.setVal(dbDriver, root.acntDbKey, val);

                            if (ok) {
                                root.vkEvent("info", "Конфігурацію рахунків обліку успішно збережено в базі каси");
                            } else {
                                root.vkEvent("error", "Помилка збереження плану рахунків у SQLite");
                            }
                        }
                    }
                }
            }
        }
    }
}










