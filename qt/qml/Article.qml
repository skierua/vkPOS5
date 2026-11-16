import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "js/article.js" as JS;
import "js/common.js" as Lib;

Item {
    id: root
    width: 1200
    height: 700
    // title: qsTr("📦 Ієрархічний Довідник Артикулів")
    property string title: "📦 Каталог товарів"
    property string codeid: "article"
    // modality: Qt.WindowModal

    property var dbDriver: null
    onDbDriverChanged: {
        root.isProcessing = true;
        JS.preload(dbDriver, foldersModel)
        .catch( (msg) => vkEvent('error',msg) )
        .finally(() => root.isProcessing = false );
    }
    property bool isProcessing: false
    property string currentFolderId: "" // Поточна вибрана папка ("" - корінь)
        onCurrentFolderIdChanged: {
            root.isProcessing = true;
            // articlesView.currentIndex = -1;
            JS.refreshArticlesList(dbDriver, articlesModel, currentFolderId)
            .catch( (msg) => vkEvent('error',msg) )
            .finally(() => root.isProcessing = false )
        }

    // Об'єкт для редагування, ініціалізований за структурою dummyItem
    property var editingItem: null

    // Список дій контекстного меню
    property list<Action> vkContextActions: [
        addNewAction,
        addNewCopyAction,
    ]

    signal vkEvent(string id, var param)

    function textForMenu() { return root.title; }

    // Component.onCompleted: preLoad();

    Action {
        id: addNewAction
        // enabled: !editingItem
        text: "+ Новий артикул"
        onTriggered: {
            root.editingItem = JS.newArticle(currentFolderId);
        }
    }

    Action {
        id: addNewCopyAction
        enabled: !!editingItem && !editingItem.folder
        text: "+ Копіювати в новий артикул"
        onTriggered: {
            const dummy = Object.assign({}, editingItem);
            root.editingItem = JS.newArticle(currentFolderId, dummy);
        }
    }
    Action {
        id: addNewFolderAction
        // enabled: !editingItem
        text: "+ Новий каталог"
        onTriggered: {
            root.editingItem = JS.newFolder(currentFolderId);
        }
    }

    Component {
        id: folderViewHighlight

        Rectangle {
            width: foldersView.width
            height: 32
            color: "#e3f2fd" // Ніжний пастельно-блакитний колір Material Active
            radius: 6

            y: (foldersView.currentItem !== null && typeof foldersView.currentItem !== "undefined") ? foldersView.currentItem.y : 0

            Behavior on y {
                SpringAnimation {
                    spring: 3
                    damping: 0.3
                }
            }
        }
    }

    Component {
        id: folderViewDlg
        FocusScope {
            id: rootFolderDlg
            required property string name
            required property int deep
            required property int index

            width: rootFolderDlg.ListView.view ? rootFolderDlg.ListView.view.width : 400
            height: 28 // Фіксована висота для усунення Binding loop

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (rootFolderDlg.ListView.view) {
                        rootFolderDlg.ListView.view.currentIndex = index;
                    }
                }
            }
            Item {
                anchors.fill: parent
                clip: true
                Label{
                    anchors.verticalCenter: parent.verticalCenter
                    text: "  ".repeat(deep) + "📁 " + name
                }
            }
        }
    }

    Component {
        id: highlightComponent

        Rectangle {
            width: articlesView.width
            height: 44
            color: "#e3f2fd" // Ніжний пастельно-блакитний колір Material Active
            radius: 6

            y: (articlesView.currentItem !== null && typeof articlesView.currentItem !== "undefined") ? articlesView.currentItem.y : 0

            Behavior on y {
                SpringAnimation {
                    spring: 3
                    damping: 0.3
                }
            }
        }
    }

    Component {
        id: atclViewDlg
        FocusScope {
            id: rootAtclDlg
            required property int index
            required property string pid
            required property bool folder
            required property string itemchar
            required property string id
            required property string scancode
            required property string unitchar

            width: rootAtclDlg.ListView.view ? rootAtclDlg.ListView.view.width : 400
            height: 40

            Timer {
                id: clickTimer
                interval: Qt.styleHints.mouseDoubleClickInterval
                onTriggered: {
                    if (!!rootAtclDlg.ListView.view) {
                        rootAtclDlg.ListView.view.currentIndex = index;
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    clickTimer.restart();
                }
                onDoubleClicked: {
                    clickTimer.stop();
                    if (!folder) return;
                    // rootAtclDlg.ListView.view.currentIndex = -1;
                    // console.info("II:#w6e5 Article.qml START onDoubleClicked", root.isProcessing)
                    if (!!rootAtclDlg.ListView.view.setCrntFolderId
                            && typeof rootAtclDlg.ListView.view.setCrntFolderId === 'function') {
                        rootAtclDlg.ListView.view.setCrntFolderId(id)
                    }
                }
            }

            Item {
                id: container
                anchors{fill: parent; margins: 5}
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Label { text: (!folder ? '' : '📁 ') +  itemchar; /*font.bold: true;*/ elide: Text.ElideRight }
                    Label { text: `[${id}] Штрихкод: ${scancode || '—'} | Од: ${unitchar}`; font.pixelSize: 11; color: "#666" }
                }
            }
        }
    }

    // ----------------------------------------------------
    // СТРУКТУРА ЕКРАНУ (Layout)
    // ----------------------------------------------------
    ListModel { id: foldersModel }
    ListModel { id: articlesModel }
    ListModel { id: comboFoldersModel }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        // ЛІВА ПАНЕЛЬ: Дерево/Список папок
        ColumnLayout {
            Layout.preferredWidth: 250
            Layout.maximumWidth: 300
            // Layout.implicitWidth: 250
            // Layout.maximumWidth: 250
            Layout.fillHeight: true

            Label { text: qsTr("🗂️ Категорії:"); font.bold: true }

            Frame {
                Layout.fillWidth: true; Layout.fillHeight: true
                ListView {
                    id: foldersView
                    anchors.fill: parent
                    model: foldersModel
                    clip: true
                    delegate: folderViewDlg
 /*                   delegate: ItemDelegate {
                        readonly property string deepVal: "  ".repeat(model.deep || 0)
                        width: foldersView.width
                        highlighted: root.currentFolderId === model.id
                        text: deepVal + "📁 " + model.name
                        onClicked: {
                            foldersView.currentIndex = index
                            root.currentFolderId = model.id;
                            root.editingItem = null; // закриваємо редагування при зміні папки
                        }
                    } */

                    highlight: folderViewHighlight
                    highlightFollowsCurrentItem: false
                    focus: true
                    onCurrentIndexChanged: {
                        if (currentIndex < 0){
                            root.currentFolderId = ''
                        } else {
                            root.currentFolderId = model.get(currentIndex).id;
                        }
                        root.editingItem = null; // закриваємо редагування при зміні папки
                    }
                }
            }
        }

        // ЦЕНТРАЛЬНА ПАНЕЛЬ: Список товарів у вибраній папці
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Label {
                readonly property var folderObj: JS.getProductPathInfo(root.currentFolderId)
                text: qsTr("📦 ") + folderObj.pathname
                // font.bold: true
                color: "#4CAF50"
            }

            Frame {
                Layout.fillWidth: true; Layout.fillHeight: true
                background: Rectangle { border.color: "#ccc" }

                ListView {
                    id: articlesView
                    anchors.fill: parent
                    model: articlesModel
                    clip: true

                    highlight: highlightComponent
                    highlightFollowsCurrentItem: false
                    // focus: true

                    delegate: atclViewDlg
/*                    delegate: ItemDelegate {
                        width: articlesView.width
                        height: 40
                        // highlighted: root.editingItem && root.editingItem.id === model.id

                        contentItem: RowLayout {
                            anchors.fill: parent
                            anchors.margins: 5
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                Label { text: (!model.folder ? '' : '📁 ') +  model.itemchar;  elide: Text.ElideRight }
                                Label { text: `[${model.id}] Штрихкод: ${model.scancode || '—'} | Од: ${model.unitchar}`; font.pixelSize: 11; color: "#666" }
                            }
                            // Label { text: parseInt(model.qty).toFixed(model.unitprec) + " " + model.unitchar; font.bold: true; Layout.preferredWidth: 80; horizontalAlignment: Text.AlignRight }
                        }
                        Timer {
                            id: clickTimer
                            interval: Qt.styleHints.mouseDoubleClickInterval
                            onTriggered: {
                                // This runs ONLY after the double-click window expires safely
                                // console.log("Single click action for item:", index);
                                articlesView.currentIndex = index; // Handle selection here safely
                                const pathInfo = JS.getProductPathInfo(model.pid);
                                root.editingItem = Object.assign({}, model, {pathid: pathInfo.pathid, pathname: pathInfo.pathname})
                                // console.info("II:#w6e5 Article.qml START onClicked", Lib.safeStringify(editingItem))
                            }
                        }
                        onClicked: {
                            // console.info("II:#w6e5 Article.qml START onClicked")
                            clickTimer.restart();

                            // Заповнюємо інтерфейс форми
                            txtChar.text = model.itemchar;
                            txtName.text = model.itemname;
                            txtNote.text = model.itemnote;
                            scanView.model = !model.scancode ? [] : model.scancode.split(',')
                            edUnit.unitId = model.unitid;
                            edParent.pid = model.pid
                            txtTaxChar.text = model.taxchar;
                            txtTaxPrc.text = model.taxprc;
                            txtUktzed.text = model.uktzed;
                        }
                        onDoubleClicked: {
                            clickTimer.stop();
                            if (!model.folder) return;
                            editingItem = null;
                            // console.info("II:#w6e5 Article.qml START onDoubleClicked", root.isProcessing)
                            root.currentFolderId = model.id;
                        }
                    } */

                    ScrollIndicator.vertical: ScrollIndicator { }

                    onCurrentIndexChanged: {
                        if (currentIndex < 0) {
                            root.editingItem = null;
                            return;
                        }

                        const crnt = model.get(currentIndex);
                        const pathInfo = JS.getProductPathInfo(crnt.pid);
                        txtChar.text = crnt.itemchar;
                        txtName.text = crnt.itemname;
                        txtNote.text = crnt.itemnote;
                        scanView.model = !crnt.scancode ? [] : crnt.scancode.split(',')
                        edUnit.unitId = crnt.unitid;
                        edParent.pid = crnt.pid
                        txtTaxChar.text = crnt.taxchar;
                        txtTaxPrc.text = crnt.taxprc;
                        txtUktzed.text = crnt.uktzed;
                        root.editingItem = Object.assign({}, crnt, {pathid: pathInfo.pathid, pathname: pathInfo.pathname})
                    }

                    onCountChanged: articlesView.currentIndex = -1;


                    function setCrntFolderId(id){
                        root.currentFolderId = id;
                    }
                }
            }
        }

        // ПРАВА ПАНЕЛЬ: Велика форма редагування за структурою dummyItem
        ScrollView {
            id: editItemGroup
            Layout.preferredWidth: 460  //380
            Layout.fillHeight: true
            clip: true
            visible: root.editingItem !== null
            contentWidth: availableWidth
            contentHeight: layoutColumn.implicitHeight + 20 // +20 для нижнього відступу

            // Фон можна задати напряму через background, щоб не плодити зайві Rectangle
            background: Rectangle {
                color: "#f3f4f6"
            }

            ColumnLayout {
                id: layoutColumn
                width: editItemGroup.availableWidth - 16
                anchors{ horizontalCenter: parent.horizontalCenter;}
                spacing: 10

                Label {
                    text: root.editingItem ? `📝 Редагування ID: ${root.editingItem.id}` : ""
                    font.bold: true; font.pixelSize: 15; color: "#2196F3"
                }

                Label {
                    text: root.editingItem ? `📍 Шлях: ${root.editingItem.pathname}` : ""
                    font.pixelSize: 11; color: "#777"; wrapMode: Text.Wrap; Layout.fillWidth: true
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: layoutMainColumn.implicitHeight + 32
                    color: "#ffffff"
                    radius: 12
                    border.color: "#e5e7eb"
                    border.width: 1
                    ColumnLayout {
                        id: layoutMainColumn
                        anchors{fill: parent; margins: 8}
                        spacing: 8
                        Label{ text: "Основні параметри"; font{bold:false; pixelSize:16 } }
                        UITextField{
                            id: txtChar;
                            Layout.fillWidth: true;
                            title: "Артикул / Коротка назва:"
                        }
                        UITextField{
                            id: txtName;
                            Layout.fillWidth: true;
                            title: "Повна назва артикулу:"
                        }
                        UITextField{
                            id: txtNote;
                            Layout.fillWidth: true;
                            title: "Опис / Примітка внутрішня:"
                        }
                        ColumnLayout{
                            Label{text:"Штрихкод :"; font.pixelSize: 11; font.bold: true; color: "#6b7280"}
                            RowLayout {
                                Layout.fillWidth: true
                                // Layout.preferredHeight: 44
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 6

                                UIBtn{
                                    // id:
                                    Layout.preferredHeight: 24
                                    Layout.preferredWidth: 24
                                    palette: "green"
                                    text: "+";
                                    onClicked: scancodePopup.open();
                                }

                                ListView {
                                    id: scanView
                                    Layout.preferredHeight: 24
                                    Layout.fillWidth: true
                                    orientation: ListView.Horizontal
                                    spacing: 4
                                    model: []
                                    delegate: Rectangle {
                                        required property string modelData
                                        required property int index

                                        width: scanLabel.implicitWidth + 12
                                        height: scanLabel.implicitHeight + 12
                                        radius: 4
                                        // anchors.verticalCenter: parent.verticalCenter
                                        color: "#f5f5f5"
                                        border.color: "#e0e0e0"
                                        border.width: 1

                                        Label {
                                            id: scanLabel
                                            anchors.centerIn: parent
                                            font.pixelSize: 12
                                            font.bold: true
                                            font.family: "monospace" // Числа однакової ширини виглядають акуратніше

                                            color: "#616161"
                                            text: modelData //`${modelData.amnt > 0 ? "+" : ""}${Number(modelData.amnt || 0).toLocaleString(Qt.locale(), 'f', 0)} ${modelData.itemchar}`
                                        }
                                        MouseArea{
                                            anchors.fill: parent
                                            onClicked: {
                                                // console.info("II:#09o Article.qml", index);
                                                scancodePopup.idx = index;
                                                scancodePopup.open();
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        RowLayout{
                            Layout.fillWidth: true
                            spacing: 8
                            ColumnLayout {
                                Layout.fillWidth: true
                                Label{ text: "Одиниці виміру"; }
                                UIBtn{
                                    id:edUnit
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 44
                                    property string unitId: ''  // editingItem?.unitid || ''
                                    readonly property var unitObj: JS.getUnit(unitId)
                                    toolTip: "Одиниця виміру"
                                    text: `[${unitObj.id}] / ${unitObj.uchar} / ${unitObj.uname}`
                                    onClicked: {
                                        selectPopup.jsdata = JS.unitPopupList();
                                        selectPopup.open();
                                    }
                                }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                Label { text: "📁 Поточне розташування:"; } //font.bold: true; font.pixelSize: 11
                                UIBtn{
                                    id:edParent
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 44
                                    property string pid: '' //editingItem?.pid || ''
                                    readonly property var folderObj: JS.getProductPathInfo(pid)
                                    toolTip: "Каталог розміщення"
                                    text: folderObj.name
                                    onClicked: {
                                        selectPopup.jsdata = JS.pathPopupList();
                                        selectPopup.open();
                                    }
                                }
                            }
                        }

                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: layoutTAXColumn.implicitHeight + 32
                    color: "#ffffff"
                    radius: 12
                    border.color: "#e5e7eb"
                    border.width: 1
                    ColumnLayout {
                        id: layoutTAXColumn
                        anchors{fill: parent; margins: 8}
                        spacing: 8
                        Label{ text: "Податковий та державний облік"; font{bold:false; pixelSize:16 } }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            UITextField{
                                id: txtTaxChar;
                                Layout.fillWidth: true
                                title: "Група ПДВ:"
                            }
                            UITextField{
                                id: txtTaxPrc;
                                Layout.fillWidth: true
                                title: "Ставка ПДВ (%):"
                            }
                            UITextField{
                                id: txtUktzed;
                                Layout.fillWidth: true
                                title: "Код УКТЗЕД:"
                            }
                        }
                    }
                }
                // GroupBox {
                //     title: "Одиниці виміру та Примітки"
                //     Layout.fillWidth: true
                    // ColumnLayout {
                    //     Layout.fillWidth: true
                    //     // anchors.fill: parent;
                    //     spacing: 8

                    // }
                // }
                RowLayout {
                    Layout.fillWidth: true; spacing: 10; anchors.margins: 8;
                    UIBtn{
                        Layout.preferredHeight: 44
                        Layout.fillWidth: true;
                        // palette: enabled ? "pink" : ""
                        text: "Скасувати";
                        onClicked: articlesView.currentIndex = -1;  //root.editingItem = null
                    }
                    UIBtn {
                        Layout.fillWidth: true;
                        Layout.preferredHeight: 44
                        highlighted: true;
                        palette: enabled ? "blue" : ""
                        text: "💾 Зберегти";
                        onClicked: {
                            const uiBridge = {
                                id: editingItem.id,
                                itemmask: 4,
                                scancode: scanView.model.join(','),
                            };
                            if (!editingItem.id || txtChar.text !== String(editingItem.itemchar || '')) uiBridge.itemchar = txtChar.text.trim();
                            if (!editingItem.id || txtName.text !== String(editingItem.itemname || '')) uiBridge.itemname = txtName.text.trim();
                            if (!editingItem.id || txtNote.text !== String(editingItem.itemnote || '')) uiBridge.itemnote = txtNote.text.trim();
                            if (!editingItem.id || edUnit.unitId !== String(editingItem.unitid || '')) uiBridge.defunit = edUnit.unitId;
                            if (!editingItem.id || edParent.pid !== String(editingItem.pid || '')) uiBridge.parentid = edParent.pid;
                            if (!editingItem.id || txtUktzed.text !== String(editingItem.uktzed || '')) uiBridge.uktzed = txtUktzed.text.trim();
                            if (!editingItem.id || txtTaxChar.text !== String(editingItem.taxchar || '')) uiBridge.taxchar = txtTaxChar.text.trim();
                            if (!editingItem.id || txtTaxPrc.text !== String(editingItem.taxprc || '')) uiBridge.taxprc = txtTaxPrc.text.trim();

                            if (!!editingItem.id) {
                                root.isProcessing = true;
                                JS.updItem(root.dbDriver, uiBridge)
                                    .then((itemId) => {
                                        vkEvent('info',`#${itemId} успішно оновлено`)
                                        root.editingItem = null;
                                        articlesView.currentIndex = -1;
                                        return JS.refreshArticlesList(root.dbDriver, articlesModel, currentFolderId);
                                    })
                                    .catch( (msg) => vkEvent('error',msg) )
                                    .finally(() => root.isProcessing = false );
                            } else {
                                root.isProcessing = true;
                                JS.insItem(root.dbDriver, uiBridge)
                                    .then((itemId) => {
                                        vkEvent('info',`#${itemId} успішно додано`)
                                        root.editingItem = null;
                                        // articlesView.currentIndex = -1;
                                        return JS.refreshArticlesList(root.dbDriver, articlesModel, currentFolderId);
                                    })
                                .catch( (msg) => vkEvent('error',msg) )
                                .finally(() => root.isProcessing = false );
                            }

                        }
                    }

                }
                Item { height: 20 } // Відступ знизу
            }
        }
    }
    // Блокувальник інтерфейсу під час транзакцій
    Rectangle {
        anchors.fill: parent; color: "#60ffffff"; visible: root.isProcessing
        BusyIndicator { anchors.centerIn: parent; running: root.isProcessing }
    MouseArea { anchors.fill: parent }
    }
    // Системний логер для повідомлень про ПДВ чи успішні інсерти
/*    ColumnLayout {
        id: logView
        anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: 10
        visible: statusLabel.text !== ""
        function error(msg) { statusLabel.text = "❌ " + msg; statusColor.color = "#FFEBEE"; timer.restart(); }
        function warn(msg) { statusLabel.text = "⚠️ " + msg; statusColor.color = "#FFF3E0"; timer.restart(); }
        function info(msg) { statusLabel.text = "🧾 " + msg; statusColor.color = "#E8F5E9"; timer.restart(); }
        Rectangle {
            id: statusColor; Layout.fillWidth: true; height: 30; radius: 4; border.color: "#ccc"
            Label { id: statusLabel; anchors.centerIn: parent; font.pixelSize: 11 }
        }
        Timer { id: timer; interval: 3500; onTriggered: statusLabel.text = "" }
    } */

    UIPopupSelect{
        id: selectPopup
        // width: 360
        height: editItemGroup.height * 0.85
        x: (root.width - width) / 2
        y: (root.height - height) / 2 // Центруємо також по вертикалі
        onSelected: (code, id) => {
            if (code==="unit"){
                edUnit.unitId = id;
            } else if (code === "path") {
                edParent.pid = id
            } else {
                vkEvent('warn', "[Article] selectPopup bad code, nothing to do")
            }
            selectPopup.close()

        }
    }

    Popup {
        id: scancodePopup
        property int idx: -1
        focus: true

        onOpened: {
            pupScanTxt.forceActiveFocus();
            if (typeof pupScanTxt.selectAll === "function") {
                pupScanTxt.selectAll();
            }
        }
        onIdxChanged: {
            if (scancodePopup.idx < 0) pupScanTxt.text = ''
            else pupScanTxt.text = scanView.model[idx]
        }

        // onClosed: if (typeof quitTimer !== "undefined")  quitTimer.start();
        Component.onCompleted: pupScanTxt.forceActiveFocus()
        // Центруємо вікно на екрані каси
        width: 380
        height: 240
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2

        modal: true
        dim: true
        closePolicy:  Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            color: "#ffffff"
            radius: 12
            border.color: "#e5e7eb"
            border.width: 1
            // Легка преміальна тінь
            Rectangle { anchors.fill: parent; anchors.margins: -2; color: "transparent"; border.color: "#0a000000"; border.width: 2; radius: 14; z: -1 }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 14
            Label { text: "Штрихкод"; font.pixelSize: 24 }
            UITextField{
                id: pupScanTxt;
                Layout.fillWidth: true;
                title: "Штрихкод товару:"
                // focus: true
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Layout.preferredHeight: 40

                UIBtn{
                    id: pupCancelBtn
                    Layout.fillWidth: true
                    Layout.preferredHeight: 44
                    text: "Скасувати";
                    onClicked: scancodePopup.close()
                }

                UIBtn{
                    id: pupDeleteBtn
                    Layout.fillWidth: true
                    Layout.preferredHeight: 44
                    palette: 'pink'
                    enabled: !(scancodePopup.idx < 0)
                    text: "❌ Видалити";
                    onClicked: {
                        // console.info("II:#524d Article.qml count", scanView.count, scanView.model.length);
                        if (scancodePopup.idx >= 0 && scancodePopup.idx < scanView.count){
                            scanView.model.splice(scancodePopup.idx,1)
                            // console.info("II:#524d Article.qml count", scanView.count, scanView.model.length);
                        }
                        if (scancodePopup.idx < 0) pupScanTxt.text = '';
                        else scancodePopup.idx = -1;

                        scancodePopup.close();
                    }
                }

                UIBtn{
                    id: pupConfirmBtn
                    Layout.fillWidth: true
                    Layout.preferredHeight: 44
                    palette: enabled ? "blue" : ""
                    text: scancodePopup.idx < 0 ? "💾 Додати" : "💾 Змінити";
                    onClicked: {
                        const scanVal = pupScanTxt.text.trim();
                        if (scancodePopup.idx < 0){
                            if (!!scanVal)  scanView.model.push(scanVal);
                        } else {
                            if (!!scanVal) scanView.model.splice(scancodePopup.idx,1,scanVal);
                            else scanView.model.splice(scancodePopup.idx,1);
                        }
                        if (scancodePopup.idx < 0) pupScanTxt.text = '';
                        else scancodePopup.idx = -1;

                        scancodePopup.close();
                    }
                }
            }
        }
    }

}
