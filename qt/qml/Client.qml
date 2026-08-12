import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Controls

import "js/v147/sqlClient.js" as JS

Window {
    id: clientManageWindow
    width: 320 // Трохи збільшимо ширину (з 240 до 320) для комфортного тач-введення
    height: 500
    visible: true
    // title: qsTr("Керування клієнтами каси")

    property var dbDriver                 // Драйвер бази даних (C++)

    onDbDriverChanged: {
        console.log(`Client.qml dbDriver=${dbDriver} dataModel=${dataModel}`)
        if (dbDriver && dataModel && typeof dataModel.load === "function") {
            dataModel.load();
        }
    }

    // Дія відкриття віконного блоку створення клієнта
    Action {
        id: actionNew
        text: "Новий клієнт"
        onTriggered: {
            rectNewClient.visible = !rectNewClient.visible;
            if (rectNewClient.visible) {
                edName.forceActiveFocus();
            }
        }
    }

    Component {
        id: dlg

        FocusScope {
            id: dlgRoot

            width: dlgRoot.ListView.view ? dlgRoot.ListView.view.width : 320
            height: 56 // Збільшуємо висоту для комфортного тачу

            // Картка-підкладка для клієнта
            Rectangle {
                id: dlgRect
                anchors.fill: parent
                anchors.margins: 2
                radius: 8

                color: index === dlgRoot.ListView.view.currentIndex ? "#e3f2fd" : "#ffffff"
                border.color: index === dlgRoot.ListView.view.currentIndex ? "#0288d1" : "#e5e7eb"
                border.width: 1

                MouseArea {
                    anchors.fill: parent
                    z: -1
                    onClicked: {
                        if (dlgRoot.ListView.view) {
                            dlgRoot.ListView.view.currentIndex = index;
                        }
                    }
                }

                // Контейнер вмісту рядка
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 2

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 20

                        // Текстове відображення імені
                        Label {
                            id: lblChar
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            text: model.name || "Без імені"
                            font.bold: true
                            font.pixelSize: 13
                            color: "#1f2937"
                            elide: Text.ElideRight
                            visible: !editName.visible

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    dlgRoot.ListView.view.currentIndex = index;
                                    editName.text = model.name || "";
                                    editName.visible = true;
                                    editName.forceActiveFocus();
                                }
                            }
                        }

                        // Інлайновий інпут імені
                        TextField {
                            id: editName
                            anchors.fill: parent
                            visible: false
                            selectByMouse: true
                            font.pixelSize: 12
                            font.bold: true
                            color: "#0288d1"
                            background: Rectangle { color: "#ffffff"; border.color: "#0288d1"; radius: 4 }
                            onActiveFocusChanged: if (activeFocus) selectAll(); else visible = false
                            onAccepted: {
                                if (text.trim() !== "") {
                                    model.name = text.trim();
                                    dlgRoot.ListView.view.model.update(dbDriver, index);
                                }
                                visible = false;
                            }
                            Keys.onEscapePressed: visible = false
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        // Системний бейдж ID клієнта
                        Label {
                            text: `id:${model.id}`
                            font.pixelSize: 10
                            font.family: "monospace"
                            color: "#6b7280"
                            Layout.alignment: Qt.AlignVCenter
                        }

                        // Блок ТЕЛЕФОНУ
                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 18
                            Layout.alignment: Qt.AlignVCenter

                            Label {
                                id: lblPhone
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                font.pixelSize: 11
                                elide: Text.ElideRight
                                visible: !editPhone.visible

                                text: (model.phone || "") === "" ? "📞 телефон" : "📞 " + model.phone
                                color: (model.phone || "") === "" ? "#9ca3af" : "#37474f"

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        dlgRoot.ListView.view.currentIndex = index;
                                        editPhone.text = model.phone || "";
                                        editPhone.visible = true;
                                        editPhone.forceActiveFocus();
                                    }
                                }
                            }

                            TextField {
                                id: editPhone
                                anchors.fill: parent
                                visible: false
                                selectByMouse: true
                                font.pixelSize: 11
                                color: "#0288d1"
                                background: Rectangle { color: "#ffffff"; border.color: "#0288d1"; radius: 4 }
                                onActiveFocusChanged: if (activeFocus) selectAll(); else visible = false
                                onAccepted: {
                                    model.phone = text.trim();
                                    dlgRoot.ListView.view.model.update(dbDriver, index);
                                    visible = false;
                                }
                                Keys.onEscapePressed: visible = false
                            }
                        }

                        // Блок ПРИМІТКИ
                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 18
                            Layout.alignment: Qt.AlignVCenter

                            Label {
                                id: lblNote
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                font.pixelSize: 11
                                elide: Text.ElideRight
                                visible: !editNote.visible

                                text: (model.clnote || "") === "" ? "📝 примітка" : "📝 " + model.clnote
                                color: (model.clnote || "") === "" ? "#9ca3af" : "#37474f"

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        dlgRoot.ListView.view.currentIndex = index;
                                        editNote.text = model.clnote || "";
                                        editNote.visible = true;
                                        editNote.forceActiveFocus();
                                    }
                                }
                            }

                            TextField {
                                id: editNote
                                anchors.fill: parent
                                visible: false
                                selectByMouse: true
                                font.pixelSize: 11
                                color: "#0288d1"
                                background: Rectangle { color: "#ffffff"; border.color: "#0288d1"; radius: 4 }
                                onActiveFocusChanged: if (activeFocus) selectAll(); else visible = false
                                onAccepted: {
                                    model.clnote = text.trim();
                                    dlgRoot.ListView.view.model.update(dbDriver, index);
                                    visible = false;
                                }
                                Keys.onEscapePressed: visible = false
                            }
                        }
                    }
                }
            }
        }
    }

    ListModel {
        id: dataModel

        property var rawCachedClients: []

        function load() {
            clear();
            if (!clientManageWindow.dbDriver) return;

            const source = JS.dbClient(clientManageWindow.dbDriver) || [];
            // Безпечне сортування за ПІБ
            // console.info(`II: Client.qml/load source=${JSON.stringify(source)}`)
            source.sort((a, b) => (a.name || "").localeCompare(b.name || ""));

            dataModel.rawCachedClients = source;
            populate(findEdit.text);
        }

        function isAllowed(rowIdx, flt) {
            const cache = dataModel.rawCachedClients;
            if (!cache || !cache[rowIdx]) return false;

            const filterLower = String(flt).toLowerCase().trim();
            const nameStr = String(cache[rowIdx].name || "").toLowerCase();
            const noteStr = String(cache[rowIdx].clnote || "").toLowerCase();
            const phoneStr = String(cache[rowIdx].phone || "").toLowerCase();
            const idStr = String(cache[rowIdx].id || "").toLowerCase();

            return (idStr === filterLower
                    || nameStr.includes(filterLower)
                    || noteStr.includes(filterLower)
                    || phoneStr.includes(filterLower));
        }

        function populate(flt = "") {
            clear();
            const cache = dataModel.rawCachedClients;
            // if (!Array.isArray(cache)) return;

            const cleanFilter = String(flt || "").trim();

            if (cleanFilter === "") {
                for (let i = 0; i < cache.length; ++i) {
                    append(cache[i]);
                }
            } else {
                for (let r = 0; r < cache.length; ++r) {
                    if (isAllowed(r, cleanFilter)) {
                        append(cache[r]);
                    }
                }
            }
        }

        function addNew(dbDriver, clientName, clientPhone = "", clientNote = "") {
            if (!dbDriver || !clientName || clientName.trim() === "") return;

            JS.ins(dbDriver, clientName.trim(), clientPhone.trim(), clientNote.trim());

            load();
            rectNewClient.visible = false;
            edName.text = ""; edPhone.text = ""; edNote.text = "";
        }

        function update(dbDriver, row) {
            if (!dbDriver || row < 0 || row >= count) return;
            JS.upd(dbDriver, get(row).id, get(row).name, get(row).phone, get(row).clnote);
            load();
        }
    }

    Page {
        id: mainPage
        anchors.fill: parent

        header: ToolBar {
            background: Rectangle { color: "#f8f9fa"; border.color: "#e0e0e0"; border.width: 1 }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 6; anchors.rightMargin: 6
                spacing: 6

                ToolButton {
                    id: btnFindToggle
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 36
                    icon.source: "qrc:/icon/find.svg"
                    onClicked: findEdit.visible = !findEdit.visible
                }

                // Рядок живого швидкого пошуку
                // Rectangle {
                //     id: findEditWrapper
                //     Layout.fillWidth: true
                //     Layout.preferredHeight: 32
                //     color: "white"
                //     radius: 4
                //     border.color: findEdit.activeFocus ? "#0288d1" : "#bdbdbd"
                //     visible: findEdit.visible    || dataModel.count > 0

                    TextField {
                        id: findEdit
                        Layout.fillWidth: true
                        Layout.preferredHeight: 32
                        // anchors.fill: parent
                        // leftPadding: 8
                        selectByMouse: true
                        visible: false
                        placeholderText: "Пошук клієнта..."
                        // background: null
                        background: Rectangle {
                            radius: 6
                            color: parent.activeFocus ? "#FFFFFF" : "#F9FAFB"
                            border { width: 1; color: parent.activeFocus ? "#0288d1" : "#bdbdbd" }
                            // border { width: 1; color: parent.activeFocus ? "#3B82F6" : "#D1D5DB" }
                        }

                        onVisibleChanged: {
                            if (visible) forceActiveFocus();
                            else text = '';
                        }
                        // Живий пошук при кожному введенні літери
                        onTextChanged: dataModel.populate(text)
                        onAccepted: dataModel.populate(text)
                    }
                // }

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32
                }

                ToolButton {
                    text: "⋮"
                    font.pixelSize: 16
                    font.bold: true
                    onClicked: toolMenu.open()

                    Menu {
                        id: toolMenu
                        y: parent.height
                        MenuItem { action: actionNew }
                    }
                }
            }
        }

        // 📝 ТІЛО СТОРІНКИ: Блок введення та список
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 10

            // ✨ СУЧАСНА КАРТКА ДЛЯ СТВОРЕННЯ НОВОГО КЛІЄНТА (rectNewClient)
            Rectangle {
                id: rectNewClient
                Layout.fillWidth: true
                Layout.preferredHeight: rectNewClient.visible ? newClientColumn.implicitHeight + 16 : 0
                visible: false
                color: "#ffffff"
                radius: 8
                border.color: "#0288d1"
                border.width: 1
                clip: true

                ColumnLayout {
                    id: newClientColumn
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8

                    Label { text: "👤 Додати нову картку клієнта"; font.bold: true; color: "#0288d1"; font.pixelSize: 12 }

                    // Форма введення ПІБ
                    RowLayout {
                        spacing: 8
                        Label { text: "ПІБ:"; font.bold: true; Layout.preferredWidth: 50; font.pixelSize: 11 }
                        Rectangle {
                            Layout.fillWidth: true; height: 32; color: "#f9fafb"; radius: 4; border.color: edName.activeFocus ? "#0288d1" : "#bdbdbd"
                            TextField { id: edName; anchors.fill: parent; leftPadding: 6; font.pixelSize: 12; background: null; placeholderText: "Прізвище, Ім'я..." }
                        }
                    }

                    // Форма введення телефону
                    RowLayout {
                        spacing: 8
                        Label { text: "Тел:"; font.bold: true; Layout.preferredWidth: 50; font.pixelSize: 11 }
                        Rectangle {
                            Layout.fillWidth: true; height: 32; color: "#f9fafb"; radius: 4; border.color: edPhone.activeFocus ? "#0288d1" : "#bdbdbd"
                            // ✅ ВИПРАВЛЕНО: id поля виправлено на edPhone (ліквідовано ReferenceError краш)
                            TextField { id: edPhone; anchors.fill: parent; leftPadding: 6; font.pixelSize: 12; background: null; placeholderText: "+380..." }
                        }
                    }

                    // Форма введення нотаток
                    RowLayout {
                        spacing: 8
                        Label { text: "Опис:"; font.bold: true; Layout.preferredWidth: 50; font.pixelSize: 11 }
                        Rectangle {
                            Layout.fillWidth: true; height: 32; color: "#f9fafb"; radius: 4; border.color: edNote.activeFocus ? "#0288d1" : "#bdbdbd"
                            TextField { id: edNote; anchors.fill: parent; leftPadding: 6; font.pixelSize: 12; background: null; placeholderText: "Тип дисконту, VIP, тощо..." }
                        }
                    }

                    // Кнопки управління формою
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 4
                        spacing: 8

                        Button {
                            text: "💾 Зберегти"
                            Layout.fillWidth: true
                            Layout.preferredHeight: 34
                            font.bold: true
                            // ✅ ВИПРАВЛЕНО: Передаємо edPhone.text замість неіснуючого dPhone
                            onClicked: dataModel.addNew(clientManageWindow.dbDriver, edName.text, edPhone.text, edNote.text)
                        }
                        Button {
                            text: "Скасувати"
                            Layout.fillWidth: true
                            Layout.preferredHeight: 34
                            onClicked: rectNewClient.visible = false
                        }
                    }
                }
            }
            // 3. СПИСОК КЛІЄНТІВ
            ListView {
                id: vw
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 2
                clip: true
                focus: true
                model: dataModel
                delegate: dlg
                // Гарний кастомний скроллбар
                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }
            }
        }
    }
}


