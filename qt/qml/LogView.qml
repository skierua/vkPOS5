import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// 16-error | 4-warning | 1-info
ListView {
    id: root

    property int level: 21
    property int outdated: 60
    property bool debug: false

    spacing: 6
    clip: true
    verticalLayoutDirection: ListView.BottomToTop

    add: Transition {
        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 250; easing.type: Easing.OutQuad }
        NumberAnimation { property: "scale"; from: 0.95; to: 1; duration: 200; easing.type: Easing.OutQuad }
    }

    remove: Transition {
        NumberAnimation { property: "opacity"; to: 0; duration: 200 }
        NumberAnimation { property: "scale"; to: 0.95; duration: 200 }
    }

    Timer {
        id: lifeTimer
        interval: 5000
        repeat: true
        running: root.count > 0
        onTriggered: delOutdated()
    }

    function info(vstr){ append2(vstr, 1, 5); }
    function warn(vstr){ append2(vstr, 4, 10); }
    function error(vstr){ append2(vstr, 16); }

    // ttl in seconds
    function append2(vstr, vid = 1, ttl = root.outdated) {
        const numericId = Number(vid);
        const ttlVal = (Number(ttl) || root.outdated) * 1000;
        const now = new Date().getTime();
        const expireAt = now + ttlVal; // +30 секунд
        if (!!(numericId & level)) {
            root.model.append({
                "msgId": numericId,
                "str": vstr,
                "expired": expireAt
            });
            if (root.debug) console.log(numericId + ": " + vstr);
        }
    }

    // old / deprecated
    function append(vstr, vid = 2, ) {
        console.log("WW: LogView.qml/append DEPRECATED, use append2 instead")
        const code = Number(vid || 2)
        let newCode = 1;
        if (code === 1) newCode = 4;
        else if (code === 0) newCode = 16;
        append2(vstr, newCode);
    }

    function delOutdated() {
        const currentTime = new Date().getTime();

        for (let r = root.count - 1; r >= 0; --r) {
            let item = root.model.get(r);
            if (!item || !item.expired || (currentTime > item.expired)) {
                root.model.remove(r, 1);
            }
        }
    }

    function getLogColors(msgId) {
        switch(msgId) {
            case 16:
                return { bg: "#FDE8E8", border: "#F8B4B4", text: "#9B1C1C", label: "ПОМИЛКА" };
            case 4:
                return { bg: "#FEF08A", border: "#FDE047", text: "#713F12", label: "УВАГА" };
            case 1:
                return { bg: "#EBF5FF", border: "#E1EFFE", text: "#1E429F", label: "ІНФО" };
            default:
                return { bg: "#F9FAFB", border: "#E5E7EB", text: "#374151", label: "ЛОГ" };
        }
    }

    delegate: Item {
        id: delegateItem
        width: root.width
        height: Math.max(34, logCard.implicitHeight + 8)

        readonly property var colors: root.getLogColors(msgId)

        Rectangle {
            id: logCard
            implicitHeight: cardLayout.implicitHeight
            anchors {
                fill: parent
                leftMargin: 8
                rightMargin: 8
            }
            radius: 6
            color: delegateItem.colors.bg
            border {
                width: 1
                color: delegateItem.colors.border
            }

            RowLayout {
                    id: cardLayout // ✅ Додано id для посилання на координати колонок
                    anchors {
                    fill: parent
                    leftMargin: 10
                    rightMargin: 6 // Зменшено відступ справа, щоб кнопка хрестика стояла акуратно
                    topMargin: 4
                    bottomMargin: 4
                }
                spacing: 8

                // Бейдж типу повідомлення
                Rectangle {
                    Layout.alignment: Qt.AlignTop | Qt.AlignLeft
                    Layout.topMargin: 2
                    width: 65
                    height: 16
                    radius: 4
                    color: delegateItem.colors.text

                    Text {
                        anchors.centerIn: parent
                        text: delegateItem.colors.label
                        color: "#FFFFFF"
                        font {
                            pixelSize: 9
                            bold: true
                        }
                    }
                }

                // Головний текст повідомлення
                Text {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    text: str
                    color: delegateItem.colors.text
                    wrapMode: Text.Wrap
                    font {
                        pixelSize: 12
                        bold: msgId === 0
                    }
                }

                // ✅ НОВА КНОПКА: Примусове закриття одного повідомлення касиром
                ToolButton {
                    id: closeButton // ✅ Додано id кнопки
                    Layout.alignment: Qt.AlignTop | Qt.AlignRight
                    Layout.preferredWidth: 20
                    Layout.preferredHeight: 30
                    flat: true // Робимо кнопку прозорою без сірої рамки


                    // Налаштовуємо колір хрестика під колір тексту поточної картки
                    contentItem: Text {
                        // text: parent.text
                        // font: parent.font
                        color: delegateItem.colors.text
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        // Стильний тонкий хрестик
                        text: "✕"
                        font {
                            pixelSize: 12
                            bold: true
                        }
                    }

                    onClicked: {
                        // console.log("LogView clicked")
                        root.model.remove(index, 1);
                    }
                }
            }
        }

        MouseArea {
            width: logCard.width - closeButton.width
            anchors {
                            top: parent.top
                            bottom: parent.bottom
                            left: parent.left
                            // Права межа притиснута до лівого краю кнопки хрестика всередині лейауту
                            // right: cardLayout.left + closeButton.x
                        }   hoverEnabled: true
            // Обмежуємо область дії ToolTip, щоб вона не перекривала кнопку хрестика
            preventStealing: true
            ToolTip.delay: 800
            ToolTip.timeout: 4000
            ToolTip.visible: containsMouse
            ToolTip.text: str
        }
    }

    model: ListModel {}
}
/*
  [{
  "id": int // 1-error|5-warning|10-info
  "str": string
  "tm": string
}]
  */



