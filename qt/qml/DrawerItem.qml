import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    width: 320
    height: 500
    property var dbDriver                 // Драйвер бази даних (C++)

    signal vkEvent(string id, var param)

    // ✅ ВИПРАВЛЕНО: Безпечне очищення моделі без руйнування біндінгів Qt 6
    onVisibleChanged: {
        if (visible) {
            viewCashAction.trigger();
        } else {
            if (typeof drawerModel.clear === "function") drawerModel.clear();
            dataFilter.text = "";
        }
    }

    ModelDrawer {
        id: drawerModel
    }

    // --- Блок логічних дій (Actions) з виправленим очищенням потрібного ID поля ---
    Action {
        id: viewCashAction
        text: "Каса"
        onTriggered: {
            dataFilter.text = ""; // ✅ ВИПРАВЛЕНО ID
            vw.section.property = "bind";
            drawerModel.load(dbDriver, ["30"], 3);
        }
    }

    Action {
        id: viewDebtAction
        text: "Дебітори"
        onTriggered: {
            dataFilter.text = "";
            vw.section.property = "";
            drawerModel.load(dbDriver, ["36", "38", "42"], 3, true);
        }
    }

    Action {
        id: viewTradeAction
        text: "TRADE"
        onTriggered: {
            dataFilter.text = "";
            vw.section.property = "bind";
            drawerModel.load(dbDriver, ["35"], 3, true);
        }
    }

    Action {
        id: viewArticleAction
        text: "Товар"
        onTriggered: {
            dataFilter.text = "";
            vw.section.property = "";
            drawerModel.load(dbDriver, ["3000"], 4, false);
        }
    }

    Action {
        id: viewDeffectiveAction
        text: "Брак"
        onTriggered: {
            dataFilter.text = "";
            vw.section.property = "";
            drawerModel.load(dbDriver, ["3020"], 4, false);
        }
    }

    // ✨ ГОЛОВНИЙ СУЧАСНИЙ МАКЕТ КОМПОНЕНТА
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 4
/*            Label {
                text: "📈"
                // text: "📈 Звіти та залишки"
                font.pixelSize: 16
                font.bold: true
                color: "#263238"
                Layout.fillWidth: true
                Layout.bottomMargin: 2
            }*/
            Button {
                id: btnViewCash
                Layout.preferredWidth: 48
                Layout.preferredHeight: 48
                Layout.alignment: Qt.AlignVCenter
                action: viewCashAction

                background: Rectangle {
                    color: btnViewCash.pressed ? "#cfd8dc" : (btnViewCash.hovered ? "#e2e8f0" : "#eceff1")
                    radius: 8
                    border.color: "#b0bec5"
                    border.width: 1
                }
                contentItem: Text {
                    text: "₴"
                    font.pixelSize: 20
                    font.bold: true
                    color: "#455a64"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
            Button {
                id: btnViewTrade
                Layout.preferredWidth: 48
                Layout.preferredHeight: 48
                Layout.alignment: Qt.AlignVCenter
                action: viewTradeAction

                background: Rectangle {
                    color: btnViewTrade.pressed ? "#cfd8dc" : (btnViewTrade.hovered ? "#e2e8f0" : "#eceff1")
                    radius: 8
                    border.color: "#b0bec5"
                    border.width: 1
                }
                contentItem: Text {
                    text: "📈"
                    // text: "$€£"
                    font.pixelSize: 20
                    font.bold: true
                    color: "#455a64"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
            Button {
                id: btnViewDebt
                Layout.preferredWidth: 48
                Layout.preferredHeight: 48
                Layout.alignment: Qt.AlignVCenter
                action: viewDebtAction

                background: Rectangle {
                    color: btnViewDebt.pressed ? "#cfd8dc" : (btnViewDebt.hovered ? "#e2e8f0" : "#eceff1")
                    radius: 8
                    border.color: "#b0bec5"
                    border.width: 1
                }
                contentItem: Text {
                    text: "Dbt"
                    font.pixelSize: 20
                    font.bold: true
                    color: "#455a64"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
            Button {
                id: btnViewArticle
                Layout.preferredWidth: 48
                Layout.preferredHeight: 48
                Layout.alignment: Qt.AlignVCenter
                action: viewArticleAction

                background: Rectangle {
                    color: btnViewArticle.pressed ? "#cfd8dc" : (btnViewArticle.hovered ? "#e2e8f0" : "#eceff1")
                    radius: 8
                    border.color: "#b0bec5"
                    border.width: 1
                }
                contentItem: Text {
                    text: "📦"
                    font.pixelSize: 20
                    font.bold: true
                    color: "#455a64"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }

        }

        ListView {
            id: vw
            Layout.fillHeight: true
            Layout.fillWidth: true
            spacing: 4
            clip: true
            model: drawerModel

            // ✨ Кастомний скроллбар
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            delegate: Rectangle {
                id: rowContainer
                width: vw.width - 4
                height: 48 // Збільшена висота для кращої читабельності
                radius: 6
                color: "#ffffff"
                border.color: "#eef0f2"
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 8

                    // Ліва колонка: Назва рахунку/товару та коди
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            // Форматування тексту імені з виправленим синтаксисом .arg()
                            text: name
                            // text: `${model.name || ""}` + model.clchar !== "" ? String(" %1[%2]").arg(model.clchar).arg(model.clid) : model.bind || ""
                            font.pixelSize: 12
                            font.bold: true
                            color: "#2c3e50"
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                        Text {
                            text: `[${model.acntno || ""}] ${model.subname || ""}`
                            font.pixelSize: 10
                            color: '#7f8c8d'
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                    }

                    // Права колонка: Баланс фінансів (Усього / Надходження / Видатки)
                    ColumnLayout {
                        Layout.preferredWidth: 90
                        spacing: 2
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignRight
                            text: Math.abs(Number(model.total || 0)).toLocaleString(Qt.locale(), 'f', Number(model.prec))
                            font.pixelSize: 13
                            font.bold: true
                            // Якщо баланс від'ємний (борг) — підсвічуємо червоним
                            color: Number(model.total || 0) < 0 ? '#d32f2f' : '#2e7d32'
                        }

                        // Рядок оборотів (Дебет / Кредит або Прихід / Розхід)
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            visible: Number(model.income || 0) !== 0 || Number(model.outcome || 0) !== 0

                            Text {
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignRight
                                text: Number(model.income || 0) === 0 ? "" : Number(model.income).toLocaleString(Qt.locale(), 'f', 0)
                                font.pixelSize: 9
                                // color: '#27ae60' // Зелений прихід
                            }
                            Text {
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignRight
                                text: Number(model.outcome || 0) === 0 ? "" : Number(model.outcome).toLocaleString(Qt.locale(), 'f', 0)
                                font.pixelSize: 9
                                // color: '#7f8c8d' // Сірий розхід
                            }
                        }
                    }
                }
            }

            // ✨ СУЧАСНИЙ СТИЛЬ РОЗДІЛЬНИКІВ СЕКЦІЙ
            section.property: "bind"
            section.criteria: ViewSection.FullString
            section.delegate: Rectangle {
                width: vw.width
                // ✅ ВИПРАВЛЕНО: Якщо секція пуста, схлопуємо її висоту в 0
                height: section !== "" ? 26 : 0
                color: "transparent"
                visible: section !== ""

                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: 4
                    height: 18
                    radius: 4
                    color: "#cfd8dc" // Ніжний сіро-блакитний роздільник

                    Label {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: section.toUpperCase()
                        font.pixelSize: 10
                        font.bold: true
                        color: "#455a64"
                    }
                }
            }
        }

        // 3. ПОЛЕ ПОШУКУ / ФІЛЬТРАЦІЇ (У єдиному стилі з нашою системою)
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 38
            Layout.maximumHeight: 38
            color: "#ffffff"
            radius: 8
            border.color: dataFilter.activeFocus ? "#0288d1" : "#e0e0e0"
            border.width: dataFilter.activeFocus ? 2 : 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 4
                spacing: 6

                Label {
                    text: "🔍"
                    font.pixelSize: 13
                    color: "#9e9e9e"
                }

                TextField {
                    id: dataFilter
                    Layout.fillWidth: true
                    placeholderText: 'Швидкий фільтр залишків...'
                    font.pixelSize: 13
                    selectByMouse: true
                    background: null
                    // Жива ES6 фільтрація при введенні символів
                    onTextChanged: drawerModel.filterData(text.trim())
                    onAccepted: drawerModel.filterData(text.trim())
                }
                ToolButton {
                    text: "✕"
                    visible: dataFilter.text !== ""
                    Layout.preferredWidth: 26
                    Layout.preferredHeight: 26
                    onClicked: {
                        dataFilter.text = "";
                        drawerModel.filterData("");
                    }
                    background: Rectangle { color: "transparent" }
                }
            }
        }
    }
}


