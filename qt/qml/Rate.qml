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
            readonly property bool isChanged: model.bidDisplay !== model.bidEdited || model.askDisplay !== model.askEdited
            readonly property bool isWarn: {
                const bidDiff = Number(model.bidEdited || 0) !== 0
                              ? Math.abs((model.bidEdited - model.bidDisplay)/model.bidEdited) : 0;
                const askDiff = Number(model.askEdited || 0) !== 0
                              ? Math.abs((model.askEdited - model.askDisplay)/model.askEdited) : 0;
                return bidDiff > 0.04 || askDiff > 0.04;
            }
            readonly property string qtyStr: (model.qty === '1' || model.qty === 1 || !model.qty ? "" : `${model.qty} `)
            width: vw.width
            height: dlgroot.isChanged ? 45 : 30

            // Інтерактивна підкладка для виділення поточної валюти та ефекту «зебри»
            Rectangle {
                anchors.fill: parent
                color: vw.currentIndex === index ? "#EFF6FF" : ((index % 2 === 0) ? "#FFFFFF" : "#F9FAFB")

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 1
                    color: "#DCDCDC"   //"silver"// "#F3F4F6" // "green"  //
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
                Text {
                    visible: dlgroot.isWarn
                    font { pointSize: 18; bold: true }
                    // visible: !!model.err
                    color: "tomato"
                    text: "⚠"
                    Layout.alignment: Qt.AlignVCenter

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        ToolTip.delay: 500
                        ToolTip.timeout: 4000
                        ToolTip.visible: containsMouse
                        ToolTip.text: "Перевищення кроку зміни курсу"
                    }
                }
                Item {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 35
                    Layout.fillHeight: true
                    ColumnLayout{
                        anchors.fill: parent
                        spacing: 2
                        Text {
                            Layout.fillWidth: true
                            // Layout.fillHeight: true
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignHCenter
                            visible: !bidedit.visible
                            text: bidDisplay !== 0 ? bidDisplay.toFixed(bidDisplay < 10 ? 3 : 2) : (bidEdited !== 0 ? "0" : "")
                            font {
                                pixelSize: 12
                                strikeout: Number(bidEdited || 0) !== 0 && Math.abs(Number(bidDisplay || 0) - Number(bidEdited || 0)) > root.zero
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignHCenter
                            visible: !bidedit.visible && dlgroot.isChanged
                            text: bidEdited !== 0 ? bidEdited.toFixed(bidEdited < 10 ? 3 : 2) : ""
                            font {
                                pixelSize: 12
                                bold: Number(bidEdited || 0) !== 0 && Math.abs(Number(bidDisplay || 0) - Number(bidEdited || 0)) > root.zero
                            }
                        }
                    }
                    TextField {
                        id: bidedit
                        anchors.fill: parent
                        visible: false
                        selectByMouse: true
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: 12
                        text: bidEdited
                        // Працює надійно під американську локаль чисел з крапкою
                        validator: DoubleValidator { bottom: 0; decimals: 4; notation: "StandardNotation"; locale: "en_US" }
                        onActiveFocusChanged: if (activeFocus) selectAll(); else visible = false;

                        onAccepted: {
                            model.bidEdited = Number(text)
                            visible = false;
                            dlgroot.forceActiveFocus();
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            bidedit.visible = true;
                            bidedit.forceActiveFocus();
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 30
                    Layout.fillHeight: true

                    Text {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter

                        text: `${dlgroot.qtyStr}${model.curchar || "???"}`

                        font {
                            pixelSize: 12
                            bold: dlgroot.isChanged
                        }
                        color: "#111827"

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true

                            // Подвійний клік по валюті автоматично відкриває швидкий чек у Bind.qml
                            onDoubleClicked: vw.newDoc(index)

/*                            ToolTip {
                                id: rateToolTip
                                width: 180
                                visible: parent.containsMouse
                                delay: 600
                                timeout: 4000

                                // text: `Код: ${curid || "—"}\n` +
                                //       `Назва: ${curname || "—"}\n` +
                                //       `Кратність: ${qty || "1"}\n` +
                                //       `Сайт (К/П): ${bid === "" ? "—" : bid} / ${ask === "" ? "—" : ask}\n` +
                                //       `Попередні: ${dfltbid === "" ? "—" : dfltbid} / ${dfltask === "" ? "—" : dfltask}`
                            }*/
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 35
                    Layout.fillHeight: true
                    ColumnLayout{
                        anchors.fill: parent
                        spacing: 2
                        Text {
                            Layout.fillWidth: true
                            // Layout.fillHeight: true
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignHCenter
                            visible: !askedit.visible
                            text: askDisplay !== 0 ? askDisplay.toFixed(askDisplay < 10 ? 3 : 2) : (askEdited !== 0 ? "0" : "")
                            font {
                                pixelSize: 12
                                strikeout: Number(askEdited || 0) !== 0 && Math.abs(Number(askDisplay || 0) - Number(askEdited || 0)) > root.zero
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignHCenter
                            visible: !askedit.visible && dlgroot.isChanged
                            text: askEdited !== 0 ? askEdited.toFixed(askEdited < 10 ? 3 : 2) : ""
                            font {
                                pixelSize: 12
                                bold: Number(askEdited || 0) !== 0 && Math.abs(Number(askDisplay || 0) - Number(askEdited || 0)) > root.zero
                            }
                        }
                    }
                    TextField {
                        id: askedit
                        anchors.fill: parent
                        visible: false
                        selectByMouse: true
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: 12
                        text: askEdited
                        // Працює надійно під американську локаль чисел з крапкою
                        validator: DoubleValidator { bottom: 0; decimals: 4; notation: "StandardNotation"; locale: "en_US" }
                        onActiveFocusChanged: if (activeFocus) selectAll(); else visible = false;

                        onAccepted: {
                            model.askEdited = Number(text)
                            visible = false;
                            dlgroot.forceActiveFocus();
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            askedit.visible = true;
                            askedit.forceActiveFocus();
                        }
                    }
                }

                ToolButton {
                    // Layout.alignment: Qt.AlignVCenter
                    visible: dlgroot.isChanged
                    text: "↩️" // Емодзі чудово працює як текст кнопки
                    font.pixelSize: 16 // Збільшуємо розмір для кращої видимості емодзі
                    hoverEnabled: true

                    ToolTip.visible: hovered
                    ToolTip.text: "Скасувати зміни (Undo)"
                    // font { pointSize: 18; bold: true }
                    // visible: !!model.err
                    // color: "tomato"
                    // text: "⚠"

                    onClicked: {
                        model.bidEdited = model.bidDisplay
                        model.askEdited = model.askDisplay
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

            JS.populateWebRates(vw.model, logView)
        }
    }

    Action {
        id: commitAction
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

/*                function upd(row, amnt, ba = "bid") {
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
                }*/
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
                action: commitAction
            }

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
