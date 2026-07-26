import QtCore as QtCore
import QtQuick
import QtQuick.Controls
// import QtQuick.Controls.Fusion   // best
// import QtQuick.Controls.Basic
// import QtQuick.Controls.Material
//import QtQuick.Controls.Universal
import QtQuick.Layouts

import vkPOS5
import "js/main.js" as JS

ApplicationWindow {
    id: root
    visible: true
    title: qsTr("vkPOS5 #%1").arg(applicationVersion)
    width: 640
    height: 480

    property string dbname: ''

    onDbnameChanged: {
        closeChildWindow();
        if (!dbname || dbname === "") return;

        console.log("[Main] Зміна файлу бази даних на: " + dbname);

        const uiBridge = {
            dbname: dbname,                          // Передаємо актуальне ім'я файлу бази
            winShift: () => { winShiftAction.trigger(); },
            setRateOnline: (v) => { rateLoader.isRESTConnected = !!v; },
            setTaxAction: (v) => { bindTaxAction.enabled = !!v; },
            setFooter: (v) => { footerLeftLabel.text = v; }
        };

        // Запуск C++/JS обробника підключення бази
        const success = JS.handleDbNameChanged(Db, Prn, compContainer, logView, uiBridge);

        if (!success) {
            if (typeof logView !== "undefined") {
                logView.error("Критична помилка підключення бази даних");
            }
            if (typeof quitTimer !== "undefined") {
                quitTimer.start();
            }
            return;
        }

        if (typeof bindCheckAction !== "undefined") {
            bindCheckAction.trigger();
        }
    }

    QtCore.Settings {
        category: "program"
        property alias width: root.width
        property alias height: root.height
    }

    function dbg(str, code ="") {
        console.log( `[Main.qml]#${code} ${str}`);
    }

    function closeChildWindow(){
        dcmViewLoader.active = false
        clientLoader.active = false
        cashWizardLoader.active = false
        taxServiceLoader.active = false
        // statLoader.active = false
        rateLoader.active = false
    }

    function setClientFromBind(cl){
        // dbg(JSON.stringify(compContainer.currentItem.crntClient), "s53tt")
            btnClient.clName = cl?.name || null
            btnClient.clBonus = cl?.bonusBalance || 0
    }
    header: ToolBar {
        id: appToolBar
        implicitHeight: headerLayout.implicitHeight + 10 // додаємо невеликий падінг для повітряності

        background: Rectangle {
            color: "#F9FAFB" // Світлий пастельний фон (Tailwind Gray 50)
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: "#E5E7EB" // Тонка роздільна лінія знизу (Gray 200)
            }
        }

        RowLayout {
            id: headerLayout
            anchors {
                fill: parent
                leftMargin: 8
                rightMargin: 8
            }
            spacing: 12

            // Головне бургер-меню (☰)
            ToolButton {
                id: mainMenuButton
                flat: true
                text: "☰"
                icon.name: "format-list-bulleted"
                icon.width: 18
                icon.height: 18
                onClicked: naviMenu.popup()

                Menu {
                    id: naviMenu
                    title: qsTr("Головне меню")

                    // Додаємо невеликі падінги для красивого сучасного вигляду
                    topPadding: 4
                    bottomPadding: 4

                    // ---------------------------------------------------------------------
                    // СЕКЦІЯ 1: Операційна діяльність (Додавання вкладок у SwipeView)
                    // ---------------------------------------------------------------------
                    MenuItem {
                        action: bindCheckAction
                        icon.source: "qrc:/icon/add.svg" // Використовуємо ваші іконки з CMake
                        icon.width: 14
                        icon.height: 14
                        onTriggered: naviMenu.close()
                    }
                    MenuItem {
                        action: bindInnerAction
                        icon.source: "qrc:/icon/add.svg"
                        icon.width: 14
                        icon.height: 14
                        onTriggered: naviMenu.close()
                    }
                    MenuItem {
                        action: bindTaxAction
                        icon.source: "qrc:/icon/add.svg"
                        icon.width: 14
                        icon.height: 14
                        onTriggered: naviMenu.close()
                    }
                    MenuItem {
                        action: bindFactureAction
                        icon.source: "qrc:/icon/add.svg"
                        icon.width: 14
                        icon.height: 14
                        onTriggered: naviMenu.close()
                    }

                    MenuSeparator { topPadding: 2; bottomPadding: 2 }

                    // ---------------------------------------------------------------------
                    // СЕКЦІЯ 2: Звіти та Вікна аналітики (Нові дочірні вікна)
                    // ---------------------------------------------------------------------
                    MenuItem {
                        action: winDcmsAction
                        // icon.source: "qrc:/icon/filter.svg"
                        onTriggered: naviMenu.close()
                    }
                    MenuItem {
                        action: winBalanceAction
                        // icon.source: "qrc:/icon/account.svg"
                        onTriggered: naviMenu.close()
                    }
                    MenuItem {
                        action: winClientAction
                        // icon.source: "qrc:/icon/find.svg"
                        onTriggered: naviMenu.close()
                    }
                    MenuItem {
                        action: winRateAction
                        // icon.source: "qrc:/icon/reload.svg"
                        onTriggered: naviMenu.close()
                    }
                    MenuItem {
                        action: winShiftAction
                        // icon.source: "qrc:/icon/drawer.svg"
                        onTriggered: naviMenu.close()
                    }

                    MenuSeparator { topPadding: 2; bottomPadding: 2 }

                    // ---------------------------------------------------------------------
                    // СЕКЦІЯ 3: Сервісне підменю
                    // ---------------------------------------------------------------------
                    Menu {
                        id: serviceMenu
                        title: qsTr("Сервіс")

                        MenuItem {
                            action: winCashWizardAction
                            onTriggered: naviMenu.close()
                        }
                        MenuSeparator { topPadding: 1; bottomPadding: 1 }

                        // MenuItem {
                        //     action: winTaxServiceAction
                        //     onTriggered: naviMenu.close()
                        // }
                        MenuItem {
                            action: changeDBAction // Виклик вашого Popup.open()
                            // icon.source: "qrc:/icon/undo.svg"
                            onTriggered: naviMenu.close()
                        }
                        MenuSeparator { topPadding: 1; bottomPadding: 1 }

                        // Налаштування програми як вкладка у SwipeView
                        // Переконайтеся, що actionSetting додає вкладку
                        MenuItem {
                            action: actionSetting
                            // icon.source: "qrc:/icon/close.svg"
                            onTriggered: naviMenu.close()
                        }
                    }
                    // MenuItem {
                    //     action: testAction
                    //     onTriggered: naviMenu.close()
                    // }

                    MenuSeparator { topPadding: 2; bottomPadding: 2 }

                    // ---------------------------------------------------------------------
                    // СЕКЦІЯ 4: Вихід із програми (Таймер)
                    // ---------------------------------------------------------------------
                    MenuItem {
                        text: qsTr("Вийти")
                        icon.source: "qrc:/icon/close.svg"

                        // Виділимо червоним кольором текст виходу, щоб касир не натиснув його випадково
                        contentItem: Text {
                            text: parent.text
                            font: parent.font
                            color: "#9B1C1C" // Пастельний червоний колір виходу
                            verticalAlignment: Text.AlignVCenter
                            leftPadding: 24 // Залишаємо відступ під іконку
                        }

                        onTriggered: {
                            naviMenu.close();
                            quitTimer.start();
                        }
                    }
                }
            }
            // Заголовок поточної вкладки каси
            Label {
                id: headerTitle
                Layout.fillWidth: true
                elide: Label.ElideRight
                horizontalAlignment: Qt.AlignLeft
                verticalAlignment: Qt.AlignVCenter
                font {
                    pixelSize: 16
                    bold: true
                }
                color: "#1F2937"
            }

            // =========================================================================
            // КЛІЄНТСЬКИЙ БЛОК (Стильна картка-капсула)
            // =========================================================================
            Rectangle {
                id: btnClient

                // Властивості даних, які прокидаються з QML
                property var clName: null    //"Оберіть клієнта..."
                property real clBonus: 0

                Layout.preferredWidth: clientRowLayout.implicitWidth
                Layout.preferredHeight: 34

                // Дизайн капсули
                radius: 17 // половина висоти для ідеального заокруглення
                color: clName ? "#F3F4F6" : "#EBF5FF" // М'який синій колір, якщо клієнта обрано
                border {
                    width: 1
                    color: clName ? "#D1D5DB" : "#BFDBFE"
                }

                RowLayout {
                    id: clientRowLayout
                    anchors.fill: parent
                    spacing: 4

                    // Кнопка інформації клієнта
                    ToolButton {
                        Layout.preferredHeight: 32
                        flat: true
                        text: btnClient.clName ? btnClient.clName : "Оберіть клієнта..."
                        icon.source: "qrc:/icon/account.svg"
                        icon.width: 16
                        icon.height: 16

                        font {
                            pixelSize: 12
                            bold: btnClient.clName
                        }

                        onClicked: {
                            const codeid = compContainer.currentItem.codeid;
                            if (codeid === "bind") {
                                compContainer.currentItem.selectClientAction.trigger()
                            }
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: 16
                        color: btnClient.clName ? "#93C5FD" : "#D1D5DB"
                    }

                    Label {
                        Layout.preferredHeight: 32
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                        Layout.leftMargin: 4
                        Layout.rightMargin: 4

                        text: btnClient.clBonus ? btnClient.clBonus + " 🪙" : "" // 🪙Додано емодзі монети
                        color: btnClient.clName ? "#1E429F" : "#6B7280"
                        font {
                            pixelSize: 12
                            bold: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            onDoubleClicked:
                                compContainer.currentItem.newDcm("",
                              compContainer.currentItem?.crntClient.bonusAcnt ?? "",
                              0 - compContainer.currentItem?.crntClient.bonusTotal ?? 0)
                        }
                    }

                    // Кнопка скидання/очищення клієнта
                    ToolButton {
                        Layout.preferredWidth: 26
                        Layout.preferredHeight: 32
                        flat: true

                        icon.source: "qrc:/icon/close.svg"
                        icon.width: 10
                        icon.height: 10

                        // Показуємо хрестик тільки якщо якийсь клієнт реально обраний
                        visible: btnClient.clName

                        onClicked: {
                            if (compContainer.currentItem) {
                                compContainer.currentItem.crntClient = null;
                            }
                        }
                    }
                }
            }

            // Контекстне додаткове меню (⋮)
            ToolButton {
                id: contextMenu_toolbtn
                flat: true
                text: "⋮"
                font.pixelSize: 16
                onClicked: contextMenu.popup()

                Menu {
                    id: batchMenu
                    title: "Додатково"
                }

                Menu {
                    id: contextMenu
                    y: parent.height
                    onVisibleChanged: {
                        // dbg("contextMenu_toolbtn vsbl="+ visible, "#72js")
                        let i =0
                        if (visible){
                            if (compContainer.currentItem.vkContextActions !== undefined){
                                  for (i =0; i < compContainer.currentItem.vkContextActions.length; ++i){
                                      contextMenu.addAction(compContainer.currentItem.vkContextActions[i])
                                  }
                            }
                            if (compContainer.currentItem.vkBatchActions !== undefined){
                                for (i =0; i < compContainer.currentItem.vkBatchActions.length; ++i){
                                    batchMenu.addAction(compContainer.currentItem.vkBatchActions[i])
                                }
                                contextMenu.addMenu(batchMenu)
                            }

                            contextMenu.addItem( Qt.createQmlObject('import QtQuick.Controls; MenuSeparator {}',
                                                                                          contextMenu.contentItem,
                                                                                          "dynamicSeparator") )
                            for (i =0; i < compContainer.count; ++i) {
                                contextMenu.addItem(containerBindAction.createObject(parent,
                                                                                {
                                                                                    index: i,
                                                                                    title: compContainer.contentChildren[i].textForMenu(),
                                                                                    // isDynamic: true
                                                                                }))

                            }
                        } else {
                            // (Очищення) BatchMenu
                            // Екшени, додані через addAction, не створювалися динамічно, тому їх просто прибираємо
                            for (i = batchMenu.count - 1; i >= 0; --i) {
                                batchMenu.removeItem(batchMenu.itemAt(i));
                            }

                            // Не просто removeItem, а примусовий .destroy()
                            for (i = contextMenu.count - 1; i >= 0; --i) {
                                let item = contextMenu.itemAt(i);
                                contextMenu.removeItem(item);

                                // Якщо цей пункт був створений динамічно через createObject або createQmlObject,
                                // знищуємо його, повністю звільняючи оперативну пам'ять терміналу
                                if (item) {
                                    // Перевіряємо кастомний маркер 'isDynamic', який додамо при створенні.
                                    if (item.isDynamic === true && typeof item.destroy === "function") {
                                        item.destroy();
                                    }
                                }
                            }
                        }

                    }
                }
            }
        }
    }


    onClosing: close =>
    {
        closeChildWindow()
    }

    footer: Rectangle{
        width: parent.width
        height: 25  //childrenRect.height
        color: 'lightgray'
        Item{
            anchors{ fill: parent; leftMargin: 10; rightMargin: 10;}
            Label {
                id: footerLeftLabel
                anchors{/*centerIn: parent;*/ verticalCenter: parent.verticalCenter }
            }
        }


    }

    Component {
        id: containerBindAction

        MenuItem {
            id: root
            property string title
            property int index
            property bool isDynamic: true

            contentItem: RowLayout {
                anchors { fill: parent; leftMargin: 10 }

                Label {
                    Layout.fillWidth: true
                    font.bold: root.index === compContainer.currentIndex
                    clip: true
                    elide: Label.ElideRight
                    text: root.title
                }
                ToolButton {
                    Layout.preferredHeight: 20
                    Layout.preferredWidth: 20
                    flat: true
                    text: "✕"
                    font.pixelSize: 14
                    visible: root.index > 0 // не можна видалити першу вкладку

                    onClicked: {
                        if (root.index > 0 && root.index < compContainer.count) {
                            JS.handleCloseTab(root.index, compContainer);
                            contextMenu.close();
                        }
                    }
                }
            }

            // Якщо клікнули просто по тексту меню (не по хрестику) — перемикаємо вкладку
            onTriggered: {
                if (root.index < compContainer.count) {
                    compContainer.currentIndex = root.index;
                }
            }
        }
    }

    Action {
        id: testAction
        text: "TEST"
        // checkable: true
        // checked: testLoader.active
//        icon.name: "edit-copy"
//        shortcut: StandardKey.Copy
        onTriggered: {
            popupCloseShift.open()
            // testLoader.active = checked;
            // const a = LibItem.getItemById(Db, "200023")
            // const a = LibItem.getItemById(Db, "")
            // LibItem.fillFolderCache(Db)
        }
    }

    Timer{
        id: quitTimer
        interval: 1000
        repeat: false
        running: false
        onTriggered: {
            closeChildWindow()
            Qt.quit()
        }
    }

    Action {
        id: bindCheckAction
        text: "Новий Чек"        //qsTr("Check")
        onTriggered: {
            const uiBridge = {
                drawer: () => { drawer2Right.open(); },
                setClientFromBind: (clnt) => { setClientFromBind(clnt || null); },
                state: "",
            }
            const comp = Qt.createComponent("Bind.qml");
            console.info(`Main.qml/bindCheckAction status=${comp.status}`)
            if (comp.status === Component.Ready) {
                JS.handleAddBindTab(Db, Prn, comp, logView, compContainer, uiBridge);
                compContainer.currentItem.startBindAction.trigger();
            }
                else console.error(`Main.qml/bindCheckAction status=${comp.errorString()}`)
        }
    }

    Action {
        id: bindFactureAction
        text: "Нова Фактура"
        onTriggered: {
            const uiBridge = {
                drawer: () => { drawer2Right.open(); },
                setClientFromBind: (clnt) => { setClientFromBind(clnt || null); },
                state: "facture",
            }
            const comp = Qt.createComponent("Bind.qml");
            if (comp.status === Component.Ready) {
                JS.handleAddBindTab(Db, Prn, comp, logView, compContainer, uiBridge);
                compContainer.currentItem.startBindAction.trigger();
            }
        }
    }

    Action {
        id: bindTaxAction
        text: "Новий ФІСК.Чек"
        enabled: false
        onTriggered: {
            const uiBridge = {
                drawer: () => { drawer2Right.open(); },
                setClientFromBind: (clnt) => { setClientFromBind(clnt || null); },
                state: "taxcheck",
            }
            const comp = Qt.createComponent("Bind.qml");
            if (comp.status === Component.Ready) {
                JS.handleAddBindTab(Db, Prn, comp, logView, compContainer, uiBridge);
                compContainer.currentItem.startBindAction.trigger();
            }
        }
    }

    Action {
        id: bindInnerAction
        text: "Новий ВНУТРІШНІ"
        onTriggered: {
            const uiBridge = {
                drawer: () => { drawer2Right.open(); },
                setClientFromBind: (clnt) => { setClientFromBind(clnt || null); },
                state: "folder",
            }
            const comp = Qt.createComponent("Bind.qml");
            if (comp.status === Component.Ready) {
                JS.handleAddBindTab(Db, Prn, comp, logView, compContainer, uiBridge);
                compContainer.currentItem.startBindAction.trigger();
            }
        }
    }

    Action {
        id: winDcmsAction
        text: "Архів документів"
        onTriggered: {
            if (dcmViewLoader.active) {
                if (dcmViewLoader.item) dcmViewLoader.item.raise();
            } else dcmViewLoader.active = true;
        }
    }

    Action {
        id: winBalanceAction
        text: qsTr("Залишки")
        onTriggered: {
            // Якщо вікно вже відкрите — фокусуємо його, якщо ні — завантажуємо в пам'ять
            if (balanceLoader.active) {
                if (balanceLoader.item) balanceLoader.item.raise();
            } else balanceLoader.active = true;
        }
    }

    Action {
        id: winClientAction
        text: "Клієнти"
        onTriggered: {
            if (clientLoader.active) {
                if (clientLoader.item) clientLoader.item.raise();
            } else clientLoader.active = true;
        }
    }

    Action {
        id: actionSetting
        text: qsTr("Settings")
        onTriggered: {
            closeChildWindow()

            for (let i =0; i < compContainer.count; ++i ) {
                if (compContainer.contentChildren[i].codeid === "settings") {
                    compContainer.currentIndex = i
                    return
                }
            }
            const component = Qt.createComponent("AppSettings.qml");
            if (component.status === Component.Ready) {
                const newObj = component.createObject(compContainer, { dbDriver: Db })
                newObj.vkEvent.connect( (id, param) => {
                    if (id === 'info') {
                        logView.info(`[Settings] ${param ?? "Unknown info"}`, 1, 5)
                    } else if (id === 'warning') {
                        logView.warn(`[Settings] ${param ?? "Unknown warning"}`, 4, 10)
                    } else if (id === 'error') {
                        logView.error(`[Settings] ${param ?? "Unknown error"}`, 16)
                    } else {
                        logView.warn("[Settings] Bad event", 1)
                    }
                })
                compContainer.currentIndex = compContainer.count - 1;

            } else {
                logView.error("Помилка завантаження AppSettings.qml:" + component.errorString(), 0 );
            }


        }
    }
    Action {
        id: winShiftAction
        text: qsTr("Зміна")

        onTriggered: {
            if (!winShiftLoader.active) {
                winShiftLoader.active = true;
            } else if (winShiftLoader.item) {
                winShiftLoader.item.raise();
                winShiftLoader.item.requestActivate();
            }
        }
    }

    Action {
        id: winCashWizardAction
        text: "Звірка каси"
        onTriggered: {
            if (cashWizardLoader.active) {
                if (cashWizardLoader.item) cashWizardLoader.item.raise();
            } else cashWizardLoader.active = true;
        }
    }

/*    Action {
        id: winStatAction
        enabled: false
        checkable: true
        checked: statLoader.active
        text: "Статистика"
        onTriggered: { statLoader.active = checked; }
    }*/

    Action {
        id: winRateAction
        text: qsTr("Курси валют")
        // icon.source: "qrc:/icon/reload.svg"

        onTriggered: {
            // Якщо екран ще не завантажено — вмикаємо лоадер.
            // Якщо він уже висить у фоні — примусово виводимо вікно курсів на передній план.
            if (!rateLoader.active) {
                rateLoader.active = true;
            } else if (rateLoader.item) {
                rateLoader.item.raise();
                rateLoader.item.requestActivate(); // Фокусуємо вікно в Qt6
            }
        }
    }

    Action {
        id: winTaxServiceAction
        enabled: false
        checkable: true
        checked: taxServiceLoader.active
        text: "ПРРО/касовий"
        onTriggered: { taxServiceLoader.active = checked; }
    }

    Action {
        id: changeDBAction
        enabled: false
        text: "Змінити БД ["+root.dbname.substring(dbname.lastIndexOf('/')+1)+"]"
        onTriggered: {
            // selectPopup.code = "database"
            selectPopup.jsdata = null
            const source = Db.dirEntryList(`${applicationDirPath}/data/`,'*.sqlite', 2,0)
            const list = source
            .map(v => {
                     return {
                         "id": `${applicationDirPath}/data/${v}`,
                         "name": v,
                         "fullname": "",
                        "code": "database",
                         "sect": qsTr("Доступні БД")
                      };
                })
            selectPopup.jsdata = list
            selectPopup.open()
        }
    }

    Loader {
        id: winShiftLoader
        active: false
        source: "Shift.qml"

        onLoaded: {
            if (typeof closeChildWindow === "function") {
                closeChildWindow();
            }
            item.dbDriver = Db;
            item.title = qsTr("%1 (Зміна)").arg(root.title);

            item.show();            // Робить вікно видимим на рівні графічного сервера ОС
            item.raise();           // Примусово піднімає його на найвищий візуальний шар екрана
            item.requestActivate(); // Передає фокус миші та клавіатури касира прямо всередині вікна зміни
        }

        Connections {
            target: winShiftLoader.status === Loader.Ready ? winShiftLoader.item : null

            function onClosing() {
                winShiftLoader.active = false;
                // console.log(`Main.qml/winShiftLoader#8dj onClosing popupCloseShift.opened=${popupCloseShift.opened}`)
                if (!popupCloseShift.opened) {
                    JS.handleShiftWinClose(Db, quitTimer);
                }
            }

            function onVkEvent(id, param) {
                if (id === "bindTransacted"){
                    // console.log(`Main.qml/onVkEvent bind=${JSON.stringify(param)}`)
                    if (!!param) JS.uploadBind(param, logView);
                } else if (id === "balanceChanged"){
                    JS.uploadBalance(Db, "upd", logView);
                } else if (id === "shiftClosed"){
                    // console.log("Main.qml/winShiftLoader#36y onVkEvent/shiftClosed")
                    logView.info("Зміну ЗАКРИТО");
                    // root.visible = false;
                    if (bindTaxAction.enabled || false) {
                        // console.log(`Main.qml/onVkEvent popupCloseShift.open()`)
                        popupCloseShift.open()
                    } else {
                        if (typeof quitTimer !== "undefined")  quitTimer.start();
                    }

                } else if (id === "info"){
                    logView.info(`${param ?? "Unknown info"}`);
                } else if (id === "warning"){
                    logView.warn(`${param ?? "Unknown warning"}`);
                } else if (id === "error"){
                    logView.error(`${param ?? "Unknown error"}`);
                }
            }
        }
    }

    Loader{
        id: dcmViewLoader
        active: false
        source: 'DcmView.qml'
        onLoaded: {
            item.title = `${root.title}(Documents)`;
            item.dbDriver = Db;
            item.prnDriver = Prn;
            item.show();
        }

        Connections {
            target: dcmViewLoader.status === Loader.Ready ? dcmViewLoader.item : null
            function onClosing() {
                dcmViewLoader.active = false
            }
            function onVkEvent(id, param) {
                const res = compContainer.currentItem.newRefused(param)
            }
        }
    }

    Loader {
        id: balanceLoader
        active: false
        source: "Balance.qml"

        onLoaded: {
            item.dbDriver = Db;
            item.title = qsTr("%1 (Залишки)").arg(root.title);
            item.show();
        }

        Connections {
            target: balanceLoader.status === Loader.Ready ? balanceLoader.item : null

            function onClosing() {
                balanceLoader.active = false;
            }
        }
    }

    Loader{
        id: testLoader
        active: false
        source: 'Balance.qml'
        onActiveChanged: if (active) {
                            item.dbDriver = Db
                            item.visible = true
                            item.title = String("%1(%2)").arg(root.title).arg("Balance")
                         }
        Connections {
            target: testLoader.item
            function onClosing() { testLoader.active = false ; }
        }
    }

    Loader{
        id: cashWizardLoader
        active: false
        source: 'WizardCash.qml'
        onLoaded: {
            item.visible = true
            item.title = String("%1(%2)").arg(root.title).arg("Cash wizard")
            item.db = Db
            item.show();
        }
        Connections {
            target: cashWizardLoader.item
            function onClosing() { cashWizardLoader.active = false ; }
        }
    }

/*    Loader{
        id: statLoader
        active: false
        source: 'Stat.qml'
        onActiveChanged: if (active) {
                             item.visible = true
                             item.title = String("%1(%2)").arg(root.title).arg("Stat")
                             item.cshr = root.crntShift.cshr
                             item.dbDriver = Db
                         }
        Connections {
            target: statLoader.item
            function onClosing() { statLoader.active = false; }
        }
    } */

    Loader {
        id: rateLoader
        property bool isRESTConnected: false
        active: false
        source: "Rate.qml"

        onLoaded: {
            item.dbDriver = Db;
            item.online = rateLoader.isRESTConnected;

            item.title = qsTr("%1 (Курси валют)").arg(root.title);

            // TODO rewrite without the callback
            // Безпечний інжект колбека створення документа (фіксуємо compContainer за його id)
            item.funcCreateDcm = function(atclid) {
                if (compContainer.currentItem && typeof compContainer.currentItem.newDcm === "function") {
                    compContainer.currentItem.newDcm(atclid);
                } else {
                    logView.append("Помилка: Активна вкладка не підтримує швидке створення чека!", 1);
                }
            };

            item.show();
        }

        Connections {
            target: rateLoader.status === Loader.Ready ? rateLoader.item : null

            function onClosing() {
                rateLoader.active = false;
            }
        }
    }

    Loader{
        id: clientLoader
        active: false
        source: 'Client.qml'
        onLoaded: {
            item.title = String("%1(%2)").arg(root.title).arg("clients")
            item.db = Db
            item.show();
            item.raise();
            item.requestActivate();
        }
        // onActiveChanged: if (active) { }
        Connections {
            target: clientLoader.status === Loader.Ready ? clientLoader.item : null
            function onClosing() { clientLoader.active = false; }
        }
    }

    Loader{
        id: taxServiceLoader
        active: false
        source: 'TaxService.qml'
        onActiveChanged: if (active) {
                             item.visible = true
                             item.title = String("%1(%2)").arg(root.title).arg("Tax service")
                         }
        Connections {
            target: taxServiceLoader.item

            function onClosing() { taxServiceLoader.active = false; }

        }
    }

    // is using for select Database file only
    Popup{
        id: selectPopup
        property string code :""   // client|database|acntno|(1|2|4 article)
        property var jsdata     // JSON value: id, name, fullname, scancode, mask, sect
        width:300
        height: root.height*0.8
        x: (root.width-width)/2
        modal: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        ListView{
            id: selectPopupView
            anchors.fill: parent
            currentIndex: -1
            clip: true
            spacing: 0
            ScrollBar.vertical: ScrollBar{
                parent: selectPopupView.parent
                anchors.top: selectPopupView.top
                anchors.left: selectPopupView.right
                anchors.bottom: selectPopupView.bottom
            }
            model: ListModel{}
            delegate: Rectangle{
                width:selectPopupView.width
                height:childrenRect.height
                color: index%2==0 ? 'white' : 'whitesmoke'  // Qt.darker('white',0.5)
                ColumnLayout{
                    spacing: 0
                    Label{text:name}
                    RowLayout{
                        Label{text:id; color:'gray'}
                        Label{text:fullname; color:'gray'}
                    }
                }

                MouseArea{
                    anchors.fill: parent
                    onClicked: {
                        if (code === "database") {        // database
                            root.dbname = id
                        } else {
                            logView.append("[Main] selectPopup bad code, nothing to do", 1)
                        }
                        selectPopup.close()
                    }
                }
            }
            section.property: "sect"
            section.criteria: ViewSection.FullString
            section.delegate: Rectangle{
                width: selectPopupView.width
                height: 30  //*/childrenRect.height*1.2
                color: "silver"
                Label{
                    font.pixelSize: 12;
                    text:'  '+section;
                    anchors{verticalCenter: parent.verticalCenter}
                }
            }
            function vpopulate(vfilter) {
                model.clear()
                for (var r =0; r < selectPopup.jsdata?.length ?? 0; ++r){
                    if (vfilter === undefined || vfilter === ''
                            || ~(selectPopup.jsdata[r].id.indexOf(vfilter))
                            || ~(selectPopup.jsdata[r].name.toLowerCase()).indexOf(String(vfilter).toLowerCase())
                            || ~(selectPopup.jsdata[r].fullname.toLowerCase()).indexOf(String(vfilter).toLowerCase())
                            || (selectPopup.jsdata[r].scancode !== undefined && ~(selectPopup.jsdata[r].scancode).indexOf(String(vfilter)))
                            ){
                        model.append(selectPopup.jsdata[r])
                    }
                }
            }
        }
        TextField{
            id: selectPopupFilter
            height: 26
            width: 80
//            font.pixelSize: 8
            anchors{right:parent.right;bottom:parent.bottom}
            selectByMouse: true
            placeholderText: 'фільтр'
//            color: text==''?'lightgray':'black'
            onAccepted: selectPopupView.vpopulate(text)
        }
        onVisibleChanged: if(!visible){selectPopupFilter.text=''; selectPopup.code = ""} else {selectPopupView.vpopulate(selectPopupFilter.text); selectPopupFilter.forceActiveFocus();}

    }

    Popup {
        id: popupCloseShift

        onClosed: if (typeof quitTimer !== "undefined")  quitTimer.start();
        // Центруємо вікно на екрані каси
        width: 380
        height: 240
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2

        modal: true
        dim: true
        closePolicy: Popup.NoAutoClose // Забороняємо закривати кліком повз, касир має свідомо обрати дію

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

            RowLayout {
                spacing: 10
                Label { text: "⚠️"; font.pixelSize: 24 }
                ColumnLayout {
                    spacing: 2
                    Label { text: "Закриття касової зміни"; font.pixelSize: 16; font.bold: true; color: "#1f2937" }
                    Label { text: "Увага! Буде виконано Z-Звіт для ДПС України."; font.pixelSize: 12; color: "#6b7280" }
                }
            }

/*                Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "#f9fafb"
                radius: 8
                border.color: "#e5e7eb"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 4
                    Label { text: "• Автоматичне службове вилучення готівки"; font.pixelSize: 11; color: "#4b5563" }
                    Label { text: "• Обнулення оперативних підсумків каси"; font.pixelSize: 11; color: "#4b5563" }
                    Label { text: "• Відправка фіскального пакету на шлюз ДПС"; font.pixelSize: 11; color: "#4b5563" }
                }
            } */

            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Layout.preferredHeight: 40

                // Кнопка скасування (Повернутися в інтерфейс)
                Button {
                    id: btnCancelShiftClose
                    text: "Пропустити"
                    Layout.fillWidth: true
                    // Layout.fillHeight: true

                    background: Rectangle {
                        color: btnCancelShiftClose.pressed ? "#e5e7eb" : (btnCancelShiftClose.hovered ? "#f3f4f6" : "#ffffff")
                        radius: 6
                        border.color: "#d1d5db"
                    }
                    onClicked:  popupCloseShift.close()
                }

                // Головна червона кнопка: Виконати Z-Звіт
                Button {
                    id: btnConfirmZReport
                    text: "🔒 Закрити зміну (Z)"
                    font.bold: true
                    Layout.fillWidth: true
                    // Layout.fillHeight: true

                    background: Rectangle {
                        color: btnConfirmZReport.pressed ? "#b71c1c" : (btnConfirmZReport.hovered ? "#c62828" : "#d32f2f")
                        radius: 6
                    }
                    contentItem: Text {
                        text: parent.text; font: parent.font; color: "white"
                        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: {
                        btnConfirmZReport.enabled = false; // Блокуємо від подвійних кліків
                        if (JS.handleZReport(logView)) popupCloseShift.close();
                                else popupCloseShift.close();
                        // console.log("[РРО] Ініціалізація фінального закриття зміни...");

                        // // Крок 1: Пінгуємо сервер ДПС через  Callback-метод, перевіряючи мережу
                        // TAX.connect((success, errorMsg) => {
                        //     if (!success) {
                        //         root.vkEvent("error", "ДПС сервер недоступний: " + String(errorMsg) + ". Z-звіт відхилено задля безпеки!");
                        //         btnConfirmZReport.enabled = true;
                        //         return;
                        //     }

                        //     // Крок 2: Викликаємо бізнес-функцію повного фіскального закриття зміни
                        //     // Передаємо DbDriver та Prn (Принтер) з вашого Main.qml
                        //     root.executeZReportProcedure();
                        // });
                    }
                }
            }
        }
    }

    Drawer {
        id: drawer2Right

        // Адаптивна ширина: на вузьких екранах займає 80%, на широких — фіксовано 400px
        width: parent.width < 500 ? parent.width * 0.8 : 400
        height: parent.height
        edge: Qt.RightEdge

        modal: true             // Блокує кліки по основному екрану чека, поки відкрито меню
        dim: true               // М'яко затемнює задній план (екран Bind.qml)
        focus: true             // Дозволяє закривати Drawer по клавіші Escape
        // interactive: false      // 🚫 Забороняє випадкове відкриття свайпом пальця при прокрутці товарів

        // Ефекти плавного відкриття (опціонально для красивого інтерфейсу)
        enter: Transition { NumberAnimation { property: "position"; duration: 250; easing.type: Easing.OutCubic } }
        exit: Transition { NumberAnimation { property: "position"; duration: 200; easing.type: Easing.InCubic } }

        // Події відкриття/закриття
        onOpened: {
            // Передаємо активний фокус на перший елемент всередині меню
            drawer2RightItem.forceActiveFocus();
        }
        onClosed: {
            if (typeof fldMainInput !== "undefined") {
                fldMainInput.forceActiveFocus();
            }
        }

        DrawerItem {
            id: drawer2RightItem
            dbDriver: Db
            anchors.fill: parent

            // можна додати сигнал закриття, якщо всередині DrawerItem є кнопка "Назад/Закрити"
            // onCancelClicked: drawer2Right.close()
        }
    }

    Item{
        anchors.fill: parent

        SwipeView {
            id: compContainer

            anchors.fill: parent

            onCurrentIndexChanged: {
                if (currentIndex < 0) return;
                // console.log(`w98j#Main currentIndex=${currentIndex}`)
                headerTitle.text = currentItem.title
                if (currentItem.codeid === "bind"){
                    setClientFromBind(currentItem.crntClient)
                    btnClient.visible = true;
                } else {
                    btnClient.visible = false;
                }


                compContainer.currentItem.forceActiveFocus()
                // dbg("currentIndex=" + currentIndex
                //             ,"63gb")
            }

        }
        PageIndicator {
            id: indicator
            visible: compContainer.count > 1
            count: compContainer.count
            currentIndex: compContainer.currentIndex

            anchors{
                bottom: parent.bottom;
                horizontalCenter: parent.horizontalCenter;
                // bottomMargin: 70
            }
        }

    }


    LogView {
        id: logView

        // Фіксуємо ширину плаваючих карток, щоб вони виглядали як Snackbars
        width: parent.width < 400 ? parent.width - 16 : 360

        // Динамічна висота: росте вгору залежно від кількості активних повідомлень (макс. 4 рядки)
        height: Math.min(count * 45, parent.height * 0.4)

        // Максимальний пріоритет шару — лежить поверх SwipeView та футера
        z: 999

        anchors {
            // Притискаємо стек до правого нижнього кута (класика для сповіщень)
            bottom: parent.bottom
            right: parent.right

            // Робимо відступи від країв екрана каси, щоб картки «висіли» в повітрі
            // margins{right: 10; bottom:50}
            bottomMargin: 70 // Трохи вище вашого футера Rectangle
            rightMargin: 10
        }

        // Вимикаємо інтерактивний скрол мишкою, бо це тепер просто контейнер карток
        interactive: false
        debug: true
    }

    Component.onCompleted: {
        // logView.append("this is INFO message")
        // logView.append("this is WARNING message",1)
        // logView.append("this is ERROR message",0)
        // let p = "f26r"    //"s5k9";
        // console.log("#387y psw = " + p + " b64: " + Qt.btoa( p));
        // console.log(`Main.qml#8wur user=[${root.restuser}] psw=[${root.restpassword}] `);
        // console.log(`Main.qml#s582 Null=${Component.Null}
        //             Redy=${Component.Ready}
        //             Loading=${Component.Loading}
        //             Error=${Component.Error}
        //             `);
        // pathToDb = "./data/"
        // pathToDb = applicationDirPath + "/data/"
//         var dbList = Db.dirEntryList(pathToDb,'*.sqlite', 2,0)
// //            console.log('main db list='+dbList)
        // Завантаження локальної SQLite бази даних
        const source = Db.dirEntryList(`${applicationDirPath}/data/`,'*.sqlite', 2,0)
        const dbList = source
        .map(v => {
                 return {
                     "id": `${applicationDirPath}/data/${v}`,
                     "name": v,
                     "fullname": "",
                    "code": "database",
                     "sect": qsTr("Доступні БД")
                  };
            })

        if (dbList.length === 1) {
            root.dbname = dbList[0].id;
            logView.append("Базу даних ініціалізовано успішно: " + root.dbname, 2);
        } else if (dbList.length > 1) {
            if (typeof changeDBAction !== "undefined") {
                changeDBAction.enabled = true;
                changeDBAction.trigger();
            }
        } else {
            // Якщо папка data порожня або файл пошкоджено
            logView.append("Критична помилка: Локальна база даних sqlite недоступна!", 0);
        }

    }

}
