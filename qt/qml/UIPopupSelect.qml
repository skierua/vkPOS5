import QtQuick
import QtQuick.Controls
import QtQuick.Layouts


Popup{
    id: rootItem
    property var jsdata: [] // [{id, name, fullname, scancode?, code, sect}]
    signal selected(string code, string id, string name)
    width: 360
    height: 360 //root.height * 0.85
    // x: (root.width - width) / 2
    // y: (root.height - height) / 2 // Центруємо також по вертикалі
    // width:300
    // height: root.height*0.8
    modal: true
    dim: true // Додає гарне затемнення заднього плану
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    background: Rectangle {
        color: "#ffffff"
        radius: 12
        border.color: "#e0e0e0"
        border.width: 1

        // Імітація легкої тіні (Drop Shadow)
        Rectangle {
            anchors.fill: parent
            anchors.margins: -2
            color: "transparent"
            border.color: "#0a000000"
            border.width: 2
            radius: 14
            z: -1
        }
    }
    onVisibleChanged: {
        if (visible) {
            filter.text = "";
            vw.vpopulate("");
            filter.forceActiveFocus();
        }
    }
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12 // Внутрішні відступи самого попапу
        spacing: 12
        /*RowLayout {
            Layout.fillWidth: true

            Label {
                text: rootItem.currentMode === "client" ? "👤 Вибір клієнта" :
                      rootItem.currentMode === "acntno" ? "💳 Вибір рахунку" : "📦 Вибір товару"
                font.pixelSize: 16
                font.bold: true
                color: "#212121"
                Layout.fillWidth: true
            }

            ToolButton {
                text: "✕"
                font.pixelSize: 14
                font.bold: true
                onClicked: rootItem.close()
                background: Rectangle { color: "transparent" }
            }
        }*/
        ListView{
                id: vw
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                currentIndex: -1
                spacing: 4

                model: ListModel {}
                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    anchors.right: vw.right
                    contentItem: Rectangle {
                        implicitWidth: 6
                        radius: 3
                        color: parent.pressed ? "#757575" : "#bdbdbd"
                    }
                }
                delegate: Rectangle{
                    id: rowDelegate
                      width: vw.width - 8 // Залишаємо місце для скроллбару
                      height: 40
                      radius: 8

                      // Інтерактивна зміна кольору при наведенні або натисканні
                      color: mouseArea.pressed ? "#e1f5fe" : (mouseArea.containsMouse ? "#f5f5f5" : "#ffffff")
                      border.color: mouseArea.containsMouse ? "#b3e5fc" : "#f0f0f0"
                      border.width: 1

                      Item {
                          anchors.fill: parent
                          anchors.margins: 4

                          // Назва (Головний текст)
                          Label {
                              id: nameLabel
                              text: model.name || ""
                              font.bold: true
                              font.pixelSize: 14
                              color: "#212121"
                              anchors.top: parent.top
                              anchors.left: parent.left
                              anchors.right: parent.right
                              elide: Text.ElideRight
                          }

                          // ID / Код
                          Label {
                              id: idLabel
                              text: "ID: " + model.id
                              color: "#757575"
                              font.pixelSize: 11
                              font.family: "monospace" // Моноширинний для кодів виглядає акуратніше
                              anchors.bottom: parent.bottom
                              anchors.left: parent.left
                          }

                          // Повна назва / Опис
                          Label {
                              text: model.fullname || ""
                              color: "#9e9e9e"
                              font.pixelSize: 11
                              anchors.bottom: parent.bottom
                              anchors.left: idLabel.right
                              anchors.leftMargin: 12
                              anchors.right: parent.right
                              elide: Text.ElideRight
                          }
                      }
                    MouseArea{
                        id: mouseArea
                        anchors.fill: parent
                        onClicked: {
                            const entityId = model.id;
                            const entityCode = model.code;
                            const entityName = model.name;
                            rootItem.selected(entityCode, entityId, entityName)
                            rootItem.close()
                        }
                    }
                }
                section.property: "sect"
                section.criteria: ViewSection.FullString
                section.delegate: Item {
                    width: vw.width
                    height: 32

                    Label {
                        text: section ? section.toUpperCase() : "" // Категорії у верхньому регістрі
                        font.bold: true
                        font.pixelSize: 11
                        font.letterSpacing: 1 // Гарний розряджений текст
                        color: "#0288d1" // Акцентний синій колір
                        anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
                    }
                }
                function vpopulate(vfilter) {
                    model.clear();
                    const dataArray = rootItem.jsdata;
                    if (!Array.isArray(dataArray)) return;

                    const searchStr = String(vfilter || "").toLowerCase().trim();

                    for (let i = 0; i < dataArray.length; i++) {
                        const item = dataArray[i];
                        if (!item) continue;

                        // Якщо фільтр порожній — додаємо всі елементи
                        if (searchStr === "") {
                            model.append(item);
                            continue;
                        }

                        // Безпечне приведення фінансових полів до рядків для захисту від crash
                        const itemId = String(item.id || "").toLowerCase();
                        const itemName = String(item.name || "").toLowerCase();
                        const itemFullname = String(item.fullname || "").toLowerCase();
                        const itemScan = String(item.scancode || "").toLowerCase();

                        if (itemId.includes(searchStr) ||
                            itemName.includes(searchStr) ||
                            itemFullname.includes(searchStr) ||
                            itemScan.includes(searchStr)) {

                            model.append(item);
                        }
                    }
                }
            }

        UIFindEdit{
            id: filter
            Layout.fillWidth: true
            placeholderText: 'Пошук за назвою, ID чи штрихкодом...'
            fillWidth: true
            expanded: true
            onTextChanged: vw.vpopulate(text)
            onAccepted: vw.vpopulate(text)
        }
    }


}
