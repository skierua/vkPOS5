// Rate.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "js/rate.js" as JS

Window {
    id: root
    width: 280
    height: 420
    minimumWidth: 240
    minimumHeight: 350

    property bool online: false
    property var dbDriver: null

    onDbDriverChanged: {
        if (dbDriver) {
            JS.loadCurrencies(dbDriver, vw.model);
            if (getWebAction.enabled) {
                getWebAction.trigger();
            }
        }
    }

    property real zero: 0.0000001
    property var funcCreateDcm: null // Колбек для швидкого чека


    // Спливаюче попередження про перевищення ліміту курсу (Захист від помилок касира)
    Popup {
        id: rateWarningPopup
        property string str: ""
        width: root.width * 0.9
        height: 90
        x: (root.width - width) / 2
        y: (root.height - height) / 2
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            radius: 8
            color: "#FEF2F2" // Пастельний світло-червоний фон попередження
            border { width: 1; color: "#FCA5A5" }
        }

        Item {
            anchors.fill: parent
            Text {
                anchors.centerIn: parent
                text: rateWarningPopup.str
                horizontalAlignment: Text.AlignHCenter
                font { pixelSize: 12; bold: true }
                color: "#9B1C1C"
            }
        }
    }


    Component {
        id: dlg

        FocusScope {
            id: dlgroot
            property bool web: root.online

            width: vw.width
            height: 30

            // Інтерактивна підкладка для виділення поточної валюти та ефекту «зебри»
            Rectangle {
                anchors.fill: parent
                color: vw.currentIndex === index ? "#EFF6FF" : ((index % 2 === 0) ? "#FFFFFF" : "#F9FAFB")

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 1
                    color: "#F3F4F6"
                }

                MouseArea {
                    anchors.fill: parent
                    // Дозволяємо кліку проходити крізь MouseArea, щоб TextField міг перехоплювати фокус
                    propagateComposedEvents: true
                    onClicked: (mouse) => {
                        vw.currentIndex = index;
                        mouse.accepted = false; // Передаємо клік далі елементам
                    }
                }
            }

            RowLayout {
                anchors.fill: parent
                spacing: 0

                // =============================================================
                // 1. КОЛОНКА КУРСУ КУПІВЛІ (BID)
                // =============================================================
                Item {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 35
                    Layout.fillHeight: true

                    Text {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                        visible: !bidedit.visible

                        // Безпечне форматування курсу залежно від його номіналу
                        text: lbid !== 0 ? lbid.toFixed(lbid < 10 ? 3 : 2) : ""
                        // {
                        //     let bidNum = Number(lbid || 0);
                        //     return bidNum !== 0 ? bidNum.toFixed(bidNum < 10 ? 3 : 2) : "";
                        // }

                        // Підсвічуємо жирним, якщо курс відрізняється від сайту
                        font {
                            pixelSize: 12
                            bold: dlgroot.web && Math.abs(Number(bid || 0) - Number(lbid || 0)) > root.zero
                        }
                        color: font.bold ? "#1E429F" : "#1F2937" // Робимо невідповідний курс синішим

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                bidedit.text = String(lbid || "");
                                bidedit.visible = true;
                                bidedit.forceActiveFocus();
                            }
                        }
                    }

                    // Поле інпуту для миттєвої зміни курсу купівлі
                    TextField {
                        id: bidedit
                        anchors.fill: parent
                        visible: false
                        selectByMouse: true
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: 12

                        // Працює надійно під американську локаль чисел з крапкою
                        validator: DoubleValidator { bottom: 0; decimals: 4; notation: "StandardNotation"; locale: "en_US" }
                        onActiveFocusChanged: if (activeFocus) selectAll(); else visible = false;

                        onAccepted: {
                            vw.upd(index, text, "bid");
                            visible = false;
                            dlgroot.forceActiveFocus();
                        }
                    }
                }

                // =============================================================
                // 2. КОЛОНКА НАЗВИ ВАЛЮТИ (CURRENCY)
                // =============================================================
                Item {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 30
                    Layout.fillHeight: true

                    Text {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter

                        // Вивід кратності валюти (напр. "100 HUF" або просто "USD")
                        text: (qty === '1' || qty === 1 || !qty ? "" : (qty + " ")) + (curchar || "???")

                        font {
                            pixelSize: 12
                            bold: dlgroot.web && ((Math.abs(Number(bid || 0) - Number(lbid || 0)) > root.zero) ||
                                                 (Math.abs(Number(ask || 0) - Number(lask || 0)) > root.zero))
                        }
                        color: "#111827"

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true

                            // Подвійний клік по валюті автоматично відкриває швидкий чек у Bind.qml
                            onDoubleClicked: vw.newDoc(index)

                            ToolTip {
                                id: rateToolTip
                                width: 180
                                visible: parent.containsMouse
                                delay: 600
                                timeout: 4000

                                text: `Код: ${curid || "—"}\n` +
                                      `Назва: ${curname || "—"}\n` +
                                      `Кратність: ${qty || "1"}\n` +
                                      `Сайт (К/П): ${bid === "" ? "—" : bid} / ${ask === "" ? "—" : ask}\n` +
                                      `Попередні: ${dfltbid === "" ? "—" : dfltbid} / ${dfltask === "" ? "—" : dfltask}`
                            }
                        }
                    }
                }

                // =============================================================
                // 3. КОЛОНКА КУРСУ ПРОДАЖУ (ASK)
                // =============================================================
                Item {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 35
                    Layout.fillHeight: true

                    Text {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                        visible: !askedit.visible

                        text: lask !== 0 ? lask.toFixed(lask < 10 ? 3 : 2) : ""
                        // {
                        //     let askNum = Number(lask || 0);
                        //     return askNum !== 0 ? askNum.toFixed(askNum < 10 ? 3 : 2) : "";
                        // }

                        font {
                            pixelSize: 12
                            bold: dlgroot.web && Math.abs(Number(ask || 0) - Number(lask || 0)) > root.zero
                            underline: lask !== dfltask // підкреслюємо, якщо курс змінено від дефолтного
                        }
                        color: font.bold ? "#1E429F" : "#1F2937"

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                askedit.text = String(lask || "");
                                askedit.visible = true;
                                askedit.forceActiveFocus();
                            }
                        }
                    }

                    // Поле інпуту для миттєвої зміни курсу продажу
                    TextField {
                        id: askedit
                        anchors.fill: parent
                        visible: false
                        selectByMouse: true
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: 12

                        validator: DoubleValidator { bottom: 0; decimals: 4; notation: "StandardNotation"; locale: "en_US" }
                        onActiveFocusChanged: if (activeFocus) selectAll(); else visible = false;

                        onAccepted: {
                            vw.upd(index, text, "ask");
                            visible = false;
                            dlgroot.forceActiveFocus();
                        }
                    }
                }
            }
        }
    }

    // --- БЛОК ОПЕРАЦІЙНИХ КОМАНД (ACTIONS) ---
    Action {
        id: getWebAction
        enabled: root.online
        text: qsTr("Завантажити з сайту")
        onTriggered: {
            const uiBridge = {
                online: root.online,
                setActionEnabled:  (v)=> {saveWebAction.enabled = v;}
            }

            JS.loadWebRates(vw.model, logView, uiBridge)
        }
    }

    Action {
        id: saveWebAction
        enabled: root.online && root.dbDriver !== null
        text: qsTr("Встановити для каси")
        onTriggered: JS.updateLocalRates(root.dbDriver, vw.model, logView, root.zero)
    }

    // --- ГОЛОВНИЙ ЖУРНАЛ КУРСІВ ВАЛЮТ ---
    Pane {
        anchors.fill: parent
        padding: 6

        background: Rectangle { color: "#FFFFFF" }

        ColumnLayout {
            anchors.fill: parent
            spacing: 8

            ListView {
                id: vw
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: ListModel{}
                delegate: dlg

                header: Rectangle {
                    width: vw.width
                    height: 24
                    color: "#F3F4F6" // Світло-сіра підкладка шапки

                    RowLayout {
                        anchors.fill: parent
                        spacing: 0

                        Label {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 35
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font { pixelSize: 11; bold: true }
                            color: "#4B5563"
                            text: qsTr("КУПІВЛЯ")
                        }
                        Label {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 30
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font { pixelSize: 11; bold: true }
                            color: "#4B5563"
                            text: qsTr("ВАЛЮТА")
                        }
                        Label {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 35
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font { pixelSize: 11; bold: true }
                            color: "#4B5563"
                            text: qsTr("ПРОДАЖ")
                        }
                    }
                }

                // Швидке створення чека при подвійному кліку по валюті
                function newDoc(row) {
                    if (typeof root.funcCreateDcm === "function") {
                        let itemData = vw.model.get(row);
                        if (itemData && itemData.curid) {
                            root.funcCreateDcm(itemData.curid);
                        }
                    }
                }

                function upd(row, amnt, ba = "bid") {
                    let itemData = vw.model.get(row);
                    if (!itemData) return;

                    let amountNum = Number(amnt);
                    let baseBid = Number(itemData.lbid || 0);
                    // Якщо курс 0, або в базі немає старого курсу, або відхилення менше 4% — дозволяємо запис
                    if (amountNum === 0 || baseBid === 0 || (Math.abs(amountNum - baseBid) / baseBid < 0.04)) {
                        JS.updateLocalRate(root.dbDriver, vw.model, logView, row, amnt, ba === "bid" ? "1" : "-1");
                    } else {
                        rateWarningPopup.str = qsTr("Перевищення ліміту курсу!\nДопустимий діапазон відхилення ±4%:\nвід %1 до %2")
                            .arg((baseBid * 0.96).toFixed(4))
                            .arg((baseBid * 1.04).toFixed(4));
                        rateWarningPopup.open();
                    }
                }
            }

            // --- НИЖНІ КНОПКИ СИНХРОНІЗАЦІЇ ---
            UIBtn{
                id: loadBtn
                palette: "green"
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                action: getWebAction
            }
            UIBtn{
                id: saveBtn
                palette: "blue"
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                action: saveWebAction
            }

/*            Button {
                id: loadBtn
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                action: getWebAction
                font.bold: true
            }

            Button {
                id: saveBtn
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                action: saveWebAction
                font.bold: true
            } */
        }

        LogView {
            id: logView
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
    }
}
