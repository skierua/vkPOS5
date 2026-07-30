import QtQuick
import QtQuick.Controls
// import QtQuick.Controls.Fusion
import QtQuick.Layouts
import "js/bind.js" as JS


Item {
    id: root
//    width: 480; height: 480
    property string title: "ЧЕК"
    property string codeid: "bind"
    property var dbDriver                 // DataBase driver

    property alias bindModel: bindView.model
    property alias selectClientAction: selectClientAction
    property alias startBindAction: startBindAction

    property list<Action> vkContextActions: [
        uahToAcntAction,
        curToAcntAction,
    ]

    property list<Action> vkBatchActions: [
        actionRsltToProfit,
    ]

    property int dfltAmnt: 1

    property real totalPmnt: 0
    property real totalEq: 0
    property real totalDsc: 0
    property real totalBns: 0

    property int crntAmnt
    property var crntAcnt: null
    property var crntClient: null   //{'id':'', 'name':'', "bonusTotal": 0, "bonusAcnt":''};

    onVisibleChanged: if (visible && typeof newRowAction !== "undefined") newRowAction.trigger();


    signal vkEvent(string id, var param)

    states: [
        State {
            name: ""
            PropertyChanges { target: root; title: "ЧЕК" }
            PropertyChanges { target: dscbnsColumn; visible: true }
            PropertyChanges { target: rateColumn; visible: false }
            PropertyChanges { target: actionRsltToProfit; enabled: false }
        },
        State {
            name: "facture"
            PropertyChanges { target: root; title: "ФАКТУРА" }
            PropertyChanges { target: dscbnsColumn; visible: true }
            PropertyChanges { target: rateColumn; visible: true }
            PropertyChanges { target: actionRsltToProfit; enabled: false }
        },
        State {
            name: "folder"
            PropertyChanges { target: root; title: "Внутрішні операції" }
            PropertyChanges { target: dscbnsColumn; visible: false }
            PropertyChanges { target: rateColumn; visible: false }
            PropertyChanges { target: actionRsltToProfit; enabled: true }
        },
        State {
            name: "taxcheck"
            PropertyChanges { target: root; title: "ФІСКАЛЬНИЙ" }
            PropertyChanges { target: dscbnsColumn; visible: false }
            PropertyChanges { target: rateColumn; visible: false }
            PropertyChanges { target: actionRsltToProfit; enabled: false }
    }
        ]

    function textForMenu() { return `${root.title} (${root.totalPmnt}грн/${bindModel.count})`; }

    Action {
        id: tranAutoPrn
        property int code: 2        // print code
        icon.name: "save"
        icon.source: "qrc:/icon/save.svg"
        onTriggered: root.executeTransaction(2)
        // onTriggered: tranAction.trigger(tranAutoPrn)
    }

    Action {
        id: tranForcePrn
        property int code: 1        // print code
        icon.name: "save"
        icon.source: "qrc:/icon/save.svg"
        onTriggered: root.executeTransaction(1)
        // onTriggered: tranAction.trigger(tranForcePrn)
    }

    Action {
        id: tranNoPrn
        property int code: 0        // print code
        icon.name: "save"
        icon.source: "qrc:/icon/save.svg"
        onTriggered: root.executeTransaction(0)
        // onTriggered: tranAction.trigger(tranNoPrn)
    }

    function executeTransaction(printCode) {
        const uiBridge = {
            vkEvent: (type, msg) => { root.vkEvent(type, msg); },
            startNewRow: () => { newRowAction.trigger(); },
            startBind: () => { startBindAction.trigger(); },
            state: root.state,
            clid: root.crntClient?.id || "",
        };
        JS.handleTranAction(dbDriver, bindModel, printCode, uiBridge);
    }

    Action {
        id: uahToAcntAction
        enabled: Number(root.crntAcnt?.trade ?? 0) === 0 && (Number(root.crntAcnt?.mask ?? 0)&1) === 1
        text: "ГРН на рахунок"
        onTriggered: {
            JS.handleDomToAcnt(dbDriver, bindModel, crntAcnt, -1 * root.totalPmnt);
            // bindModel.addDcm(dbDriver, "", crntAcnt, -1 * root.totalPmnt);
            // bindView.restart();
            newRowAction.trigger();
        }
    }

    Action {
        id: curToAcntAction
        enabled: Number(root.crntAcnt?.trade ?? 0) === 0 && (Number(root.crntAcnt?.mask ?? 0)&2) === 2
        text: "ВАЛЮТА на рахунок"
        onTriggered: {
            // console.log(`II: Bind.qml#8e7 acnt=${JSON.stringify(root.crntAcnt)}`)
            JS.handleCrnToAcnt(dbDriver, totalCurrencyView.model, bindModel, crntAcnt);
            // bindView.restart();
            newRowAction.trigger();
        }
    }

    Action {
        id: drawerAction
        icon.source: "qrc:/icon/drawer.svg"
        onTriggered: {vkEvent("openDrawer", "")}
        // onTriggered: drawer2Right.open()
    }

    Action {
        id: selectClientAction
        onTriggered: JS.handleSelectClientAction( dbDriver, selectPopup );
    }

    Action {
        id: selectAcntAction
        text: crntAcnt?.note || crntAcnt?.name || ""
        onTriggered: {
            const uiBridge = {
                clid: root.crntClient?.id || "",
            };
           JS.handleSelectAcntAction( dbDriver, selectPopup, uiBridge );
       }
    }

    Action {
        id: resetAcntAction
        text: "⌫"
        onTriggered: {
            root.crntAcnt = JS.getAcnt(dbDriver);
            newRowAction.trigger();
        }
    }

    Action {
        id: newRowAction
        onTriggered: {
            root.crntAmnt = root.dfltAmnt
            const total = bindModel ? bindModel.total() : null;
            root.totalPmnt = total?.pmnt ?? 0;
            root.totalEq = total?.eq ?? 0;
            root.totalDsc = total?.dsc ?? 0;
            root.totalBns = total?.bns ?? 0;
            totalCurrencyView.model = JS.crnTotalList(bindModel)
            if (typeof fldMainInput !== "undefined") {
                fldMainInput.text = '';
                fldMainInput.forceActiveFocus();
            }
        }
    }

    Action {
        id: startBindAction
        onTriggered: {
            const uiBridge = {
                // startNewRow: () => { newRowAction.trigger(); },
                setDfltClient: () => { root.crntClient = null; },
                setAcnt: (v) => { root.crntAcnt = v; },
                // state: root.state
            };
            JS.handleStartBindAction(dbDriver, bindModel, uiBridge)
            newRowAction.trigger();
        }
    }

    Action {
        id: actionRsltToProfit
        enabled: root.state === "folder"
        text: "Збалансувати TRADE"
        onTriggered: {
            const uiBridge = {
                vkEvent: function(type, msg) { root.vkEvent(type, msg); }
            };
            JS.handleRsltToProfit(dbDriver, bindModel, uiBridge);
        }
    }

    // addDocum(dbDriver, "", crntAcnt?.acntno || "", root.crntAmnt);
    function newDcm(atclid, amnt){
        const uiBridge = {
            atclid: atclid || "",
            acnt: root.crntAcnt || null,
            amnt: amnt || root.crntAmnt,
            state: String(root.state || "check")
        };
        const ok = JS.handleNewDcm(root.dbDriver, bindModel, uiBridge)
        // console.log(`Bind.qml#d7j4 state=${root.state}  uiBridge=${uiBridge.state} ${ok} `)
        // const ok = bindModel.addDcm(root.dbDriver, atclid, acntno, amnt, price)
        if (!ok) {
            vkEvent("error", bindModel.lastError);
            return;
        }
        // console.log("bindView.model")
        // for (let r =0; r < bindView.model.count; ++r) console.warn(`8sjn#Bind.qml ${JSON.stringify(bindView.model.get(r))}`)
        bindView.currentIndex = 0
        bindView.forceActiveFocus()
    }

    function newRefused(dcm){
        // console.log(`Bind#js8/newRefused ${JSON.stringify(dcm)}`)
        if (root.state !== ""
                || !dcm) {

            vkEvent("error", "Document can't be refused.");
            return;
        }

        const ok = JS.handleNewRefuse(root.dbDriver, bindModel, dcm)
        // console.log(`Bind#js8/newRefused ok=[${ok}]`)
        if (!ok) {
            vkEvent("error", bindModel.lastError);
            return;
        }
        newRowAction.trigger();
    }

    function setCrntClient(clnt){
        root.crntClient = (!!clnt ? clnt : null);
        newRowAction.trigger();
        vkEvent("clientChanged", clnt)
    }



    Component {
        id: dlg0

        FocusScope {
            id: dlgRoot

            readonly property string test: 'for testing'
            readonly property bool isAmntEditable: (model.retfor || "") === ""
            readonly property bool isTrade: Number(model.dacnt?.trade ?? 0) === 1
            readonly property bool isPriceEditable: isTrade && isAmntEditable && (model.jprice?.offer || 0) === 0

            // Звертаємося до властивостей ListView через вбудований ListView.view контекст
            width: dlgRoot.ListView.view ? dlgRoot.ListView.view.width : 400;
            height: 44 // Трохи збільшимо висоту рядка для кращого тач-UX

            Rectangle {
                anchors.fill: parent
                radius: 6
                // Гарне підсвічування обраного рядка товару
                color: dlgRoot.ListView.view && dlgRoot.ListView.view.currentIndex === index ? "#EFF6FF" : ((index % 2 === 0) ? "#FFFFFF" : "#F9FAFB")
                border.width: 1
                border.color: dlgRoot.ListView.view && dlgRoot.ListView.view.currentIndex === index ? "#BFDBFE" : "#F3F4F6"

                RowLayout {
                    id: mainLayout
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 6
                    clip: true

                    // 1. Бейдж помилки (якщо РРО або база повернули err)
                    Text {
                        font { pointSize: 18; bold: true }
                        visible: !!model.err
                        color: "tomato"
                        text: "⚠"
                        Layout.alignment: Qt.AlignVCenter

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            ToolTip.delay: 500
                            ToolTip.timeout: 4000
                            ToolTip.visible: containsMouse
                            ToolTip.text: model.err || ""
                        }
                    }

                    // 2. Знак операції (+ / -)
                    Text {
                        id: fldSgn
                        Layout.preferredWidth: 20
                        Layout.fillHeight: true
                        font.pointSize: 16
                        font.bold: true
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                        color: model.dsign < 0 ? "#d32f2f" : "#2e7d32"
                        text: model.dsign < 0 ? '−' : '＋'
                    }

                    // 3. Блок Назви Товару / Нотатки та супровідних тегів
                    Item {
                        id: noteContainer
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 1
                            clip: true
                            Layout.alignment: Qt.AlignVCenter

                            Text {
                                text: model.dnote || "Без назви"
                                font.pointSize: 11
                                font.bold: true
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                            Text {
                                readonly property string dtag: (model.jprice?.offer ?? 0) ? "#АКЦІЯ!" : ((model.jprice?.dsc ?? 0) ? "#ЗНИЖКА!" : "")
                                text: `#${model.darticle?.id || ""} ${dlgRoot.isTrade ? "" : ` [${model.dacnt?.acntno || ""}/${model.dacnt?.note || ""}]`} ${dtag}`
                                color: (model.jprice?.offer ?? 0) ? "#e65100" : 'dimgray' // Акція підсвічується помаранчевим
                                font.pointSize: 9
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: !dlgRoot.isTrade
                            onClicked: {
                                fldNoteEdit.text = model.dnote || "";
                                fldNoteEdit.visible = true;
                                fldNoteEdit.forceActiveFocus();
                            }
                        }

                        TextField {
                            id: fldNoteEdit
                            anchors.fill: parent
                            visible: false
                            selectByMouse: true
                            font.pixelSize: 12
                            onActiveFocusChanged: if (activeFocus) selectAll(); else visible = false
                            onAccepted: {
                                let cleanText = text.replace(/\\/g, "/");
                                if (dlgRoot.ListView.view && dlgRoot.ListView.view.model) {
                                    if (typeof dlgRoot.ListView.view.model.setProperty === "function") {
                                        dlgRoot.ListView.view.model.setProperty(index, "dnote", cleanText);
                                    } else {
                                        model.dnote = cleanText; // fallback
                                    }
                                    dlgRoot.ListView.view.restart();
                                }
                                visible = false;
                            }
                        }
                    }

                    // 4. Блок КІЛЬКОСТІ та ЦІНИ товара
                    Item {
                        id: amntPriceContainer
                        Layout.preferredWidth: 160
                        Layout.fillHeight: true

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 0
                            Layout.alignment: Qt.AlignVCenter

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                // Відображення кількості (з урахуванням точності одиниці виміру)
                                Text {
                                    id: fldAmnt
                                    Layout.fillWidth: true
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    text: Number(model.damnt || 0).toLocaleString(Qt.locale(), 'f', Number(model.darticle?.unitprec ?? 0))
                                    font.pointSize: 12
                                    font.bold: true
                                    color: "#212121"
                                    elide: Text.ElideLeft

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            if (dlgRoot.isAmntEditable && dlgRoot.ListView.view) {
                                                dlgRoot.ListView.view.currentIndex = index;
                                                fldAmntEdit.visible = true;
                                                fldAmntEdit.forceActiveFocus();
                                                // Тут логіка активації fldAmntEdit, якщо воно оголошено нижче в /* ... TextEdit fields ... */
                                            }
                                        }
                                    }
                                }

                                // Відображення ціни за одиницю
                                Text {
                                    id: fldPrice
                                    readonly property int pricePrecision: {
                                        const vv = Number(model.jprice?.offer || model.jprice?.price || 0);
                                        return Math.abs((vv * 100) - Math.round(vv * 100)) > 0.0001 ? 4 : 2;
                                    }
                                    Layout.fillWidth: true
                                    visible: dlgRoot.isTrade
                                    font.pointSize: 11
                                    color: (model.jprice?.offer ?? 0) ? "#e65100" : "#424242"
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    text: Number(model.jprice?.offer || model.jprice?.price || 0).toFixed(pricePrecision)

                                    MouseArea {
                                        anchors.fill: parent
                                        enabled: !(model.jprice?.offer || model.jprice?.dsc || 0)
                                        onClicked: {
                                            if (dlgRoot.isPriceEditable && dlgRoot.ListView.view) {
                                                dlgRoot.ListView.view.currentIndex = index;
                                                fldPriceEdit.text = jprice?.offer || jprice?.price
                                                fldPriceEdit.visible = true;
                                                fldPriceEdit.forceActiveFocus();
                                            }
                                        }
                                    }
                                }
                            }

                            // Локальний підрядковий блок для знижок/еквівалентів на рівні позиції
                            RowLayout {
                                Layout.fillWidth: true
                                visible: dlgRoot.isTrade

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 4
                                    Layout.topMargin: 2 // Невеличкий відступ від верхнього рядка ціни

                                    // 1. Еквівалент суми в іноземній валюті
                                    Text {
                                        id: fldRowEq
                                        Layout.fillWidth: true
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter

                                        // Безпечно форматуємо число з бази даних
                                        text: Math.abs((model.moneyEq ?? 0)/ (dlgRoot.ListView.view.model.rate ?? 1)).toLocaleString(Qt.locale(), 'f', 2)
                                        font.pointSize: 9
                                        color: 'dimgray'

                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: {
                                                // Перевіряємо можливість редагування та наявність віджета введення
                                                if (dlgRoot.isAmntEditable && dlgRoot.ListView.view) {
                                                    dlgRoot.ListView.view.currentIndex = index;

                                                    // Безпечний виклик поля редагування еквівалента (якщо воно оголошене в делегаті)
                                                    if (typeof fldEqEdit !== "undefined") {
                                                        fldEqEdit.text = Math.abs(model.moneyEq ?? 0).toFixed(2);
                                                        fldEqEdit.visible = true;
                                                        fldEqEdit.forceActiveFocus();
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    // 2. Індивідуальна знижка на позицію товару
                                    Text {
                                        id: fldRowDsc // ✅ ВИПРАВЛЕНО ID (не конфліктує з головним екраном)
                                        Layout.fillWidth: true // ✅ ВИПРАВЛЕНО: Layout сам порівну поділить простір
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter

                                        // Форматування тексту знижки
                                        text: (model.moneyDsc || 0) !== 0 ? Math.abs((model.moneyDsc)/ (dlgRoot.ListView.view.model.rate ?? 1)).toFixed(2) : 'знижка'
                                        font.pointSize: 9
                                        // Текст стає блідим, якщо знижка відсутня
                                        color: (model.moneyDsc ?? 0) !== 0 ? '#d32f2f' : 'lightgray' // Червонуватий відтінок, якщо знижка є
                                    }

                                    // 3. Нараховані чи списані бонуси на позицію товару
                                    Text {
                                        id: fldRowBns // ✅ ВИПРАВЛЕНО ID
                                        Layout.fillWidth: true
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter

                                        // Форматування тексту бонусів
                                        text: (model.moneyBns ?? 0) !== 0 ? Math.abs(model.moneyBns).toFixed(2) : 'бонус'
                                        font.pointSize: 9
                                        color: (model.moneyBns ?? 0) !== 0 ? '#ff8f00' : 'lightgray' // Теплий золотий колір для бонусів
                                    }
                                }
                            }
                        }

                        // --- 1. Поле швидкого редагування кількості ---
                        TextField {
                            id: fldAmntEdit
                            anchors.fill: parent
                            // visible: false // ✅ ВИПРАВЛЕНО: Керуємо видимістю явно через функції, а не через activeFocus
                            focus: true
                            visible: dlgRoot.ListView.view.currentIndex === index;
                            selectByMouse: true
                            horizontalAlignment: Text.AlignHCenter
                            font.pixelSize: 18
                            font.bold: true
                            color: "#1565c0" // Виділяємо колір введення кількості синім

                            // Динамічний валідатор на основі точності товару з бази даних (ваговий/штучний)
                            validator: DoubleValidator {
                                bottom: 0
                                decimals: model.darticle ? Number(model.darticle.unitprec ?? 2) : 2
                                notation: "StandardNotation"
                                locale: "en_US"
                            }

                            onActiveFocusChanged: {
                                if (activeFocus) {
                                    // При відкритті підтягуємо свіже значення кількості
                                    text = Number(model.damnt || 0).toFixed(model.darticle ? Number(model.darticle.unitprec ?? 2) : 2);
                                    selectAll();
                                } else {
                                    // Захист: якщо касир просто клікнув в інше місце, ховаємо поле безпечно
                                    visible = false;
                                }
                            }

                            onEditingFinished: {
                                if (!visible) return; // Захист від подвійного спрацювання в Qt 6

                                const inputVal = Number(text);
                                if (inputVal !== 0 && dlgRoot.ListView.view && dlgRoot.ListView.view.model) {
                                    const currentModel = dlgRoot.ListView.view.model;

                                    if (typeof currentModel.setProperty === "function") {
                                        currentModel.setProperty(index, "damnt", inputVal);
                                    } else {
                                        model.damnt = inputVal;
                                    }

                                    currentModel.setDcmTradeData(index);
                                    dlgRoot.ListView.view.restart();
                                }
                                visible = false;
                                if (dlgRoot.isTrade && (Number(model.jprice?.offer || model.jprice?.price || 0) === 0)) {
                                    fldPriceEdit.visible = true;
                                    fldPriceEdit.forceActiveFocus();
                                } else fldMainInput.forceActiveFocus(); // Повертаємо фокус на головний сканер
                            }
                            onAccepted: visible = false
                        }

                        // --- 2. Поле редагування ціни (із суфіксом кратності пакування) ---
                        TextField {
                            id: fldPriceEdit
                            anchors.fill: parent
                            visible: false
                            selectByMouse: true
                            font.pixelSize: 15
                            color: "#212121"
                            leftPadding: 10
                            rightPadding: suffix.visible ? 65 : 10 // ✅ ВИПРАВЛЕНО: Фіксований безпечний відступ для суфікса
                            verticalAlignment: TextInput.AlignVCenter
                            placeholderText: "Ціна, курс ..."

                            readonly property int pqty: model.jprice?.qty || (model.darticle ? Number(model.darticle.qty ?? 1) : 1)

                            validator: DoubleValidator { bottom: 0; decimals: 4; notation: "StandardNotation"; locale: "en_US" }

                            onActiveFocusChanged: {
                                if (activeFocus) selectAll();
                                else visible = false;
                            }

                            onEditingFinished: {
                                if (!visible) return;

                                const inputVal = Number(text);
                                if (inputVal !== 0 && model.jprice && dlgRoot.ListView.view && dlgRoot.ListView.view.model) {
                                    // Оновлюємо внутрішні фінансові об'єкти
                                    let priceObj = model.jprice;
                                    priceObj.price = inputVal;
                                    if (!priceObj.qty) priceObj.qty = fldPriceEdit.pqty;

                                    model.jprice = priceObj; // Перезаписуємо об'єкт для тригеру оновлення QML

                                    dlgRoot.ListView.view.model.setDcmTradeData(index);
                                    dlgRoot.ListView.view.restart();
                                }
                                visible = false;
                                fldMainInput.forceActiveFocus();
                            }
                            onAccepted: visible = false

                            // Текст кратності пакування (наприклад: x 12), притиснутий праворуч зсередини поля ціни
                            Text {
                                id: suffix
                                text: fldPriceEdit.pqty > 1 ? `x${fldPriceEdit.pqty.toFixed(0)}` : ""
                                visible: text !== ""
                                anchors {
                                    right: parent.right
                                    rightMargin: 8
                                    verticalCenter: parent.verticalCenter
                                }
                                font { pixelSize: 12; weight: Font.Medium }
                                color: "#e65100" // Акцентний помаранчевий колір для оптових пакувань
                            }
                        }

                        // --- 3. Поле зворотного розрахунку кількості через валютну суму ---
                        TextField {
                            id: fldEqEdit
                            anchors.fill: parent
                            visible: false
                            selectByMouse: true
                            horizontalAlignment: Text.AlignHCenter
                            font.pixelSize: 16
                            validator: DoubleValidator { bottom: 0; decimals: 2; notation: "StandardNotation"; locale: "en_US" }

                            onActiveFocusChanged: {
                                if (activeFocus) selectAll();
                                else visible = false;
                            }

                            onEditingFinished: {
                                if (!visible) return;

                                const inputVal = Number(text);
                                if (inputVal !== 0 && dlgRoot.ListView.view && dlgRoot.ListView.view.model) {
                                    const currentModel = dlgRoot.ListView.view.model;

                                    // Формула зворотного перерахунку кількості на основі фінансової суми
                                    const priceEach = Number(model.jprice?.offer || model.jprice?.price || 1);
                                    const packQty = Number(model.jprice?.qty || 1);
                                    const calculatedAmount = (inputVal * packQty) / priceEach;

                                    // Безпечний запис нової кількості в модель
                                    if (typeof currentModel.setProperty === "function") {
                                        currentModel.setProperty(index, "damnt", calculatedAmount);
                                    } else {
                                        model.damnt = calculatedAmount;
                                    }

                                    currentModel.setDcmTradeData(index);
                                    dlgRoot.ListView.view.restart();
                                }
                                visible = false;
                                fldMainInput.forceActiveFocus();
                            }
                            onAccepted: visible = false
                        }
                    }
                    // ✅ Цей блок стає в самий фінал вашого FocusScope { id: dlgRoot }

                    // 5. Кнопка швидкого видалення позиції з чека
                    ToolButton {
                        id: btnDeleteRow
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        Layout.alignment: Qt.AlignVCenter

                        background: Rectangle {
                            color: btnDeleteRow.pressed ? "#ffcbd2" : (btnDeleteRow.hovered ? "#ffebee" : "transparent")
                            radius: 4
                        }

                        contentItem: Text {
                            text: "✕"
                            font.pixelSize: 12
                            font.bold: true
                            color: btnDeleteRow.hovered ? "#d32f2f" : "#757575"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        onClicked: {
                            if (dlgRoot.ListView.view && dlgRoot.ListView.view.model){
                                dlgRoot.ListView.view.model.remove(index);
                                dlgRoot.ListView.view.restart();
                            }
                        }
                    }
                }
            }
        }
    }



    ColumnLayout{
        anchors{fill: parent; margins: 5}

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 46
            Layout.maximumHeight: 46
            // anchors{leftMargin: 16; rightMargin: 16;}
            spacing: 16

            // 1. Кнопка управління знаком кількості (+ / -)
            Button {
                id: btnAmnt
                Layout.preferredWidth: 48
                Layout.preferredHeight: 48
                Layout.alignment: Qt.AlignVCenter

                background: Rectangle {
                    color: root.crntAmnt < 0 ? "#ffebee" : "#e3f2fd" // Ніжно-червоний або ніжно-синій фон
                    // color: btnAmnt.pressed ? "#1b5e20" : (btnAmnt.hovered ? "#2e7d32" : "#4caf50")
                    radius: 6
                    // Легка внутрішня тінь для об'єму
                    border.color: root.crntAmnt < 0 ? "#b71c1c" : "#0d47a1"
                    border.width: 1
                }

                // Стилізуємо іконку або текст всередині кнопки проведення
                contentItem: Text {
                    text: Number(root.crntAmnt) < 0 ? '−' : '＋'
                    font.pixelSize: 32
                    font.bold: true
                    color: root.crntAmnt < 0 ? "#b71c1c" : "#0d47a1" // Глибокий фінансовий колір
                    // color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: {
                    root.crntAmnt = -1 * Number(root.crntAmnt);
                    fldMainInput.forceActiveFocus();
                }
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "white"
                radius: 6
                border.color: fldMainInput.activeFocus ? "#0288d1" : "#bdbdbd"
                border.width: fldMainInput.activeFocus ? 2 : 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 4
                    spacing: 4

                    TextField {
                        id: fldMainInput
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        focus: true
                        selectByMouse: true
                        font.pixelSize: 16
                        placeholderText: "Штрихкод, код товару або команда (*)..."

                        // Прибираємо стандартну рамку TextField, бо контейнером є Rectangle
                        background: null

                        onAccepted: {
                            let cleanText = text.trim();
                            if (cleanText === "") return;

                            // Обробка гарячих команд швидкого друку транзакцій
                            if (cleanText === '*') {
                                tranAutoPrn.trigger();
                                return;
                            } else if (cleanText === '*8') {
                                tranForcePrn.trigger();
                                return;
                            } else if (cleanText === '*9') {
                                tranNoPrn.trigger();
                                return;
                            }

                            let signChanged = false;
                            while (cleanText.length > 0 && (cleanText[0] === '+' || cleanText[0] === '-')) {
                                if (cleanText[0] === '+') {
                                    root.crntAmnt = Math.abs(root.crntAmnt);
                                } else if (cleanText[0] === '-') {
                                    root.crntAmnt = -Math.abs(root.crntAmnt);
                                }
                                cleanText = cleanText.substring(1).trim();
                                signChanged = true;
                            }

                            // Якщо ввели ТІЛЬКИ знак без тексту — повертаємо фокус і не пускаємо далі
                            if (cleanText === "" && signChanged) {
                                text = "";
                                return;
                            }

                            // Обробка чистого результату введення
                            if (cleanText === "" && (Number(root.crntAcnt?.mask ?? 0) & 1) === 1) {
                                root.newDcm();
                            } else if (cleanText !== "") {
                                const uiBridge = {
                                    vkEvent: (type, msg) => { root.vkEvent(type, msg); },
                                    setAcnt: (v) => { root.crntAcnt = v; },
                                    setClient: (v) => { setCrntClient(v) },
                                    startNewRow: () => { newRowAction.trigger(); },
                                    mask: root.crntAcnt?.mask || 0,
                                    createDocum: (v) => { root.newDcm(v); },
                                };
                                JS.handleFind(dbDriver, cleanText, selectPopup, uiBridge);
                            } else {
                                root.vkEvent("warning", "Недоступна операція або відсутній код");
                            }
                        }
                    }

                    Button {
                        id: btnGrnShortcut
                        Layout.preferredWidth: 50
                        Layout.preferredHeight: 32
                        Layout.alignment: Qt.AlignVCenter
                        visible: (Number(root.crntAcnt?.mask ?? 0) & 1) === 1 // Перевірка фіскальної маски

                        background: Rectangle {
                            color: btnGrnShortcut.pressed ? "#e0e0e0" : "#f5f5f5"
                            radius: 4
                            border.color: "#e0e0e0"
                        }

                        text: 'ГРН'
                        font.pixelSize: 12
                        font.bold: true
                        onClicked: root.newDcm();
                    }
                }
            }

            // 3. Блок вибору та скидання рахунків (Рахунок / Бонуси)
            RowLayout {
                Layout.fillHeight: true
                spacing: 6

                Button {
                    id: btnCreditAcnt
                    Layout.fillHeight: true
                    Layout.preferredWidth: Math.max(100, implicitWidth) // Захист від занадто вузької кнопки
                    font.pixelSize: 14
                    action: selectAcntAction
                    background: Rectangle {
                        color: btnCreditAcnt.pressed ? "#cfd8dc" : (btnCreditAcnt.hovered ? "#e2e8f0" : "#eceff1")
                        radius: 6
                        border{color: "#b0bec5"; width: 1}
                    }
                }

                Button {
                    id: btnCreditAcntReset
                    Layout.preferredWidth: 40
                    Layout.fillHeight: true
                    font.pixelSize: 16
                    visible: (root.crntAcnt?.acntno || "").substring(0, 2) !== '35'
                    action: resetAcntAction
                    background: Rectangle {
                        color: btnCreditAcntReset.pressed ? "#cfd8dc" : (btnCreditAcntReset.hovered ? "#e2e8f0" : "#eceff1")
                        radius: 6
                        border{color: "#b0bec5"; width: 1}
                    }
                }
            }
        }



        Rectangle{   // bindItem
            id: viewArea
            Layout.minimumWidth: 400
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip:true

            ListView{
                id: bindView
                anchors.fill: parent
                spacing: 2
                // model: ListModel{ }
                model: ModelBind{}

                delegate: dlg0

                function restart(){
                    currentIndex = -1;
                    newRowAction.trigger();
                }
            }
        }
        Rectangle {
            id: statusBarArea
            Layout.fillWidth: true
            Layout.preferredHeight: 28
            Layout.maximumHeight: 28

            // Сучасний світлий мінімалістичний фон з тонкою лінією зверху
            color: "#f8f9fa"
            Rectangle {
                anchors.top: parent.top
                width: parent.width
                height: 1
                color: "#e0e0e0"
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 10

                // 1. ЛІВА ЧАСТИНА: Список балансу валют (тепер вони обгорнуті в гарні мікро-плашки)
                Row {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 6

                    Repeater {
                        id: totalCurrencyView
                        model: [] // Передається масив типу [{amnt: 100, itemchar: '$'}, {amnt: -20, itemchar: '€'}]

                        // Кожна валюта — це охайний кольоровий бейдж
                        Rectangle {
                            required property var modelData

                            // Автоматично вираховуємо ширину залежно від довжини тексту всередині
                            width: currencyLabel.implicitWidth + 12
                            height: 18
                            radius: 4
                            anchors.verticalCenter: parent.verticalCenter

                            // М'який фон залежно від знаку (плюс/мінус/нуль)
                            color: modelData.amnt > 0 ? "#e3f2fd" : (modelData.amnt < 0 ? "#ffebee" : "#f5f5f5")
                            border.color: modelData.amnt > 0 ? "#bbdefb" : (modelData.amnt < 0 ? "#ffcdd2" : "#e0e0e0")
                            border.width: 1

                            Label {
                                id: currencyLabel
                                anchors.centerIn: parent
                                font.pixelSize: 10
                                font.bold: true
                                font.family: "monospace" // Числа однакової ширини виглядають акуратніше

                                // Контрастний глибокий колір тексту
                                color: modelData.amnt > 0 ? "#1565c0" : (modelData.amnt < 0 ? "#c62828" : "#616161")
                                text: `${modelData.amnt > 0 ? "+" : ""}${Number(modelData.amnt || 0).toLocaleString(Qt.locale(), 'f', 0)} ${modelData.itemchar}`
                            }
                        }
                    }
                }

                // 2. ПРАВА ЧАСТИНА: Лічильник кількості унікальних позицій (товарів) у чеку
                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: itemsCountRow.implicitWidth + 12
                    Layout.preferredHeight: 18
                    color: "#eceff1" // Нейтральний сіро-блакитний колір
                    radius: 4
                    border.color: "#b0bec5"
                    border.width: 1

                    RowLayout {
                        id: itemsCountRow
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            text: "📦 Позицій:"
                            font.pixelSize: 10
                            color: "#455a64"
                        }

                        Text {
                            text: String(bindView.count)
                            font.pixelSize: 11
                            font.bold: true
                            color: "#37474f"
                        }
                    }
                }
            }
        }



        Rectangle {
            id: totalArea
            Layout.preferredHeight: 64 // Збільшимо висоту для кращого UX на сенсорних екранах
            Layout.maximumHeight: 64
            Layout.fillWidth: true

            // ✨ Сучасний м'який фон із контрастною верхньою межею
            color: "#f8f9fa"
            Rectangle {
                anchors.top: parent.top
                width: parent.width
                height: 1
                color: "#e0e0e0" // Тонка лінія-роздільник між списком товарів та підсумком
            }

            RowLayout {
                id: totalAreaLayout
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 16

                // 1. ✨ КНОПКА ТРАНЗАКЦІЇ (Велика, акцентна, закруглена)
                Button {
                    id: btnTran
                    Layout.preferredWidth: 48
                    Layout.preferredHeight: 48
                    Layout.alignment: Qt.AlignVCenter
                    action: tranAutoPrn

                    background: Rectangle {
                        color: btnTran.pressed ? "#1b5e20" : (btnTran.hovered ? "#2e7d32" : "#4caf50")
                        radius: 8
                        // Легка внутрішня тінь для об'єму
                        border.color: btnTran.pressed ? "#1b5e20" : "#43a047"
                        border.width: 1
                    }

                    // Стилізуємо іконку або текст всередині кнопки проведення
                    contentItem: Text {
                        text: "✔"
                        font.pixelSize: 20
                        font.bold: true
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                // 2. ✨ КОНТРАСТНЕ ТАБЛО ДО СПЛАТИ (Стиль електронного чека)
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    Layout.alignment: Qt.AlignVCenter
                    color: root.totalPmnt < 0 ? "#ffebee" : "#e3f2fd" // Ніжно-червоний або ніжно-синій фон
                    radius: 8
                    border.color: root.totalPmnt < 0 ? "#ffcdd2" : "#bbdefb"
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14

                        Label {
                            text: "РАЗОМ:"
                            font.pixelSize: 12
                            font.bold: true
                            color: root.totalPmnt < 0 ? "#c62828" : "#1565c0"
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Label {
                            id: lblTotalSum
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignRight
                            verticalAlignment: Text.AlignVCenter
                            color: root.totalPmnt < 0 ? "#b71c1c" : "#0d47a1" // Глибокий фінансовий колір
                            text: (root.totalPmnt < 0 ? "- " : "")
                                  + Math.abs(root.totalPmnt / (bindModel?.rate ?? 1)).toLocaleString(Qt.locale(), 'f', 2)
                                  + (bindModel.rate === 1 ? " грн" : " 💱")
                            // text: (root.totalPmnt < 0 ? "- " : "") + Math.abs(root.totalPmnt).toLocaleString(Qt.locale(), 'f', 2) + " грн"
                            font.pixelSize: 24
                            font.bold: true
                        }
                    }
                }

                // 3. ✨ БЛОК ЗНИЖОК, БОНУСІВ ТА КУРСІВ (Картковий стиль з іконками)
                RowLayout {
                    id: dbrArea
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 12

                    // Стовпчик Знижок та Бонусів
                    ColumnLayout {
                        id: dscbnsColumn
                        spacing: 4

                        // Блок Знижки
                        Item {
                            Layout.preferredWidth: 120
                            Layout.preferredHeight: 22

                            Rectangle {
                                id: dscBadge
                                anchors.fill: parent
                                radius: 4
                                color: fldDscEdit.visible ? "#ffffff" : (fldMainInput.activeFocus ? "transparent" : "#f1f3f4")
                                border.color: fldDscEdit.visible ? "#0288d1" : "transparent"
                                border.width: 1

                                Label {
                                    id: fldDsc
                                    anchors.fill: parent
                                    anchors.leftMargin: 6
                                    verticalAlignment: Text.AlignVCenter
                                    visible: !fldDscEdit.visible
                                    readonly property string dscMoneyString: root.totalDsc === 0 ? '' : `(-${Math.abs(root.totalDsc).toFixed(2)})`
                                    text: `🏷 Знижка: ${(100 * bindModel.crntDsc).toFixed(1)}% ${dscMoneyString}`
                                    font.pixelSize: 11
                                    color: "#424242"

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: {
                                            fldDscEdit.text = (100 * Math.abs(bindModel.crntDsc)).toFixed(1);
                                            fldDscEdit.visible = true;
                                            fldDscEdit.forceActiveFocus();
                                        }
                                    }
                                }

                                TextField {
                                    id: fldDscEdit
                                    anchors.fill: parent
                                    anchors.leftMargin: 4
                                    visible: false
                                    selectByMouse: true
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: "#0288d1"
                                    background: null // Прибираємо стандартне біле поле
                                    validator: DoubleValidator { bottom: 0; top: 100; decimals: 1; notation: "StandardNotation"; locale: "en_US" }
                                    onActiveFocusChanged: if (activeFocus) selectAll();
                                    onEditingFinished: {
                                        bindModel.setBindDsc(Number(text) / 100);
                                        visible = false;
                                        newRowAction.trigger();
                                    }
                                    onAccepted: visible = false
                                }
                            }
                        }

                        // Блок Бонусів
                        Item {
                            Layout.preferredWidth: 120
                            Layout.preferredHeight: 22

                            Rectangle {
                                id: bnsBadge
                                anchors.fill: parent
                                radius: 4
                                // Якщо клієнта немає — плашка стає напівпрозорою (disabled стиль)
                                property bool  hasClient: !!root.crntClient && String(root.crntClient.id ?? "") !== ""
                                color: fldBnsEdit.visible ? "#ffffff" : (hasClient ? "#fff8e1" : "#f1f3f4")
                                border.color: fldBnsEdit.visible ? "#ffb300" : "transparent"
                                border.width: 1
                                opacity: hasClient ? 1.0 : 0.5

                                Label {
                                    id: fldBns
                                    anchors.fill: parent
                                    anchors.leftMargin: 6
                                    verticalAlignment: Text.AlignVCenter
                                    visible: !fldBnsEdit.visible
                                    readonly property string bnsMoneyString: root.totalBns === 0 ? '' : `(${Math.abs(root.totalBns).toFixed(2)})`
                                    text: `⭐ Бонуси: ${(100 * bindModel.crntBns).toFixed(1)}% ${bnsMoneyString}`
                                    font.pixelSize: 11
                                    color: "#5d4037"

                                    MouseArea {
                                        anchors.fill: parent
                                        enabled: !!root.crntClient && String(root.crntClient.id ?? "") !== ""
                                        onClicked: {
                                            fldBnsEdit.text = (100 * Math.abs(bindModel.crntBns)).toFixed(1);
                                            fldBnsEdit.visible = true;
                                            fldBnsEdit.forceActiveFocus();
                                        }
                                    }
                                }

                                TextField {
                                    id: fldBnsEdit
                                    anchors.fill: parent
                                    anchors.leftMargin: 4
                                    visible: false
                                    selectByMouse: true
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: "#ff8f00"
                                    background: null
                                    validator: DoubleValidator { bottom: 0; top: 100; decimals: 1; notation: "StandardNotation"; locale: "en_US" }
                                    onActiveFocusChanged: if (activeFocus) selectAll();
                                    onEditingFinished: {
                                        bindModel.setBindBns(Number(text) / 100);
                                        visible = false;
                                        newRowAction.trigger();
                                    }
                                    onAccepted: visible = false
                                }
                            }
                        }
                    }
                    // Блок Курсу
                    ColumnLayout {
                        id: rateColumn
                        visible: false
                        spacing: 4
                        Item {
                            Layout.preferredWidth: 120
                            Layout.preferredHeight: 22
                            Rectangle {
                                id: fldRate
                                anchors.fill: parent
                                radius: 4
                                color: fldRateEdit.visible ? "#ffffff" : "#efebe9"
                                border.color: fldRateEdit.visible ? "#7e57c2" : "transparent"
                                border.width: 1
                                Label {
                                    id: fldRateLabel
                                    anchors.fill: parent
                                    anchors.leftMargin: 6
                                    verticalAlignment: Text.AlignVCenter
                                    visible: !fldRateEdit.visible
                                    text: `💱 Курс: ${Number(bindModel.rate).toFixed(2)}`
                                    font.pixelSize: 11
                                    color: "#4e342e"
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            fldRateEdit.text = String(bindModel.rate);
                                            fldRateEdit.visible = true;
                                            fldRateEdit.forceActiveFocus();
                                        }
                                    }
                                }
                                TextField {
                                    id: fldRateEdit
                                    anchors.fill: parent
                                    anchors.leftMargin: 4
                                    visible: false
                                    selectByMouse: true
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: "#5e35b1"
                                    background: null
                                    validator: DoubleValidator { bottom: 0; decimals: 4; notation: "StandardNotation"; locale: "en_US" }
                                    onActiveFocusChanged: if (activeFocus) selectAll();
                                    onEditingFinished: {
                                        bindModel.setRate(text);
                                        visible = false;
                                        newRowAction.trigger();
                                    }
                                    onAccepted: visible = false
                                }
                            }
                        }
                        // Еквівалент у валюті
                        Label {
                            Layout.preferredWidth: 120
                            Layout.preferredHeight: 22
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignRight
                            anchors.rightMargin: 4
                            color: "#78909c"
                            font.pixelSize: 11
                            font.bold: true
                            text: bindModel.rate === 1 ? '' : `₴ ${((root.totalEq + root.totalDsc)/* / bindModel.rate*/).toFixed(2)}`
                        }
                    }
                }
                // 4. ✨ КНОПКА ГРОШОВОЇ СКРИНЬКИ (Стильна, сіра)
                Button {
                    id: btnDrawer
                    Layout.preferredWidth: 48
                    Layout.preferredHeight: 48
                    Layout.alignment: Qt.AlignVCenter
                    action: drawerAction
                    background: Rectangle {
                        color: btnDrawer.pressed ? "#cfd8dc" : (btnDrawer.hovered ? "#e2e8f0" : "#eceff1")
                        radius: 8
                        border.color: "#b0bec5"
                        border.width: 1
                    }
                    contentItem: Text {
                        text: "⌂" // Або іконка скриньки
                        font.pixelSize: 22
                        color: "#455a64"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }
    }

    Popup{
        id: selectPopup
        property var jsdata: [] // [{id, name, fullname, code, sect}]
        width: 360
        height: root.height * 0.85
        x: (root.width - width) / 2
        y: (root.height - height) / 2 // Центруємо також по вертикалі
        // width:300
        // height: root.height*0.8
        // x: (root.width-width)/2
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
                selectPopupFilter.text = "";
                selectPopupView.vpopulate("");
                selectPopupFilter.forceActiveFocus();
            }
        }
        // onVisibleChanged: if(!visible){selectPopupFilter.text='';
        //                   } else {
        //                       selectPopupView.vpopulate(selectPopupFilter.text);
        //                       selectPopupFilter.forceActiveFocus();
        //
    //  }
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12 // Внутрішні відступи самого попапу
            spacing: 12
            /*RowLayout {
                Layout.fillWidth: true

                Label {
                    text: selectPopup.currentMode === "client" ? "👤 Вибір клієнта" :
                          selectPopup.currentMode === "acntno" ? "💳 Вибір рахунку" : "📦 Вибір товару"
                    font.pixelSize: 16
                    font.bold: true
                    color: "#212121"
                    Layout.fillWidth: true
                }

                ToolButton {
                    text: "✕"
                    font.pixelSize: 14
                    font.bold: true
                    onClicked: selectPopup.close()
                    background: Rectangle { color: "transparent" }
                }
            }*/
            ListView{
                    id: selectPopupView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    currentIndex: -1
                    spacing: 4

                    model: ListModel {}
                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                        anchors.right: selectPopupView.right
                        contentItem: Rectangle {
                            implicitWidth: 6
                            radius: 3
                            color: parent.pressed ? "#757575" : "#bdbdbd"
                        }
                    }
                    delegate: Rectangle{
                        id: rowDelegate
                          width: selectPopupView.width - 8 // Залишаємо місце для скроллбару
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
                                if (entityCode==="client"){                  // client
                                    root.crntAcnt = JS.getAcnt(dbDriver)    // set default account
                                    const clnt = JS.getClient(dbDriver, entityId);
                                    root.crntClient = clnt;
                                    setCrntClient(clnt);
                                    // console.log(`w82j$Bind.qml HERE 1111`)
                                    // newRowAction.trigger();
                                } else if (entityCode === "acntno") {        // acntno
                                    root.crntAcnt = JS.getAcnt(dbDriver, entityId)
                                    newRowAction.trigger();
                                } else if (entityCode==="article") {        // acntno
                                    newDcm(entityId);
                                } else {
                                    vkEvent("warning", "[Bind] selectPopup bad code, nothing to do")
                                }
                                selectPopup.close()
                            }
                        }
                    }
                    section.property: "sect"
                    section.criteria: ViewSection.FullString
                    section.delegate: Item {
                        width: selectPopupView.width
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
                        const dataArray = selectPopup.jsdata;
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

            Rectangle {
                 Layout.fillWidth: true
                 height: 40
                 color: "#f5f5f5"
                 radius: 8
                 border.color: selectPopupFilter.activeFocus ? "#0288d1" : "#e0e0e0"
                 border.width: selectPopupFilter.activeFocus ? 2 : 1

                 RowLayout {
                     anchors.fill: parent
                     anchors.leftMargin: 8
                     anchors.rightMargin: 4
                     spacing: 6

                     // Іконка пошуку (символьна для простоти, можна замінити на SVG)
                     Label {
                         text: "🔍"
                         font.pixelSize: 14
                         color: "#9e9e9e"
                     }

                     TextField {
                         id: selectPopupFilter
                         Layout.fillWidth: true
                         placeholderText: 'Пошук за назвою, ID чи штрихкодом...'
                         font.pixelSize: 13
                         selectByMouse: true

                         // Прибираємо стандартний фон TextField, бо ми намалювали свій гарний Rectangle
                         background: null

                         onTextChanged: selectPopupView.vpopulate(text)
                         onAccepted: selectPopupView.vpopulate(text)
                     }

                     // Кнопка швидкого очищення фільтра
                     ToolButton {
                         text: "✕"
                         visible: selectPopupFilter.text !== ""
                         Layout.preferredWidth: 28
                         Layout.preferredHeight: 28
                         onClicked: selectPopupFilter.text = ""
                         background: Rectangle { color: "transparent" }
                     }
                 }
            }




        }

//         TextField{
//             id: selectPopupFilter
//             height: 26
//             width: 80
// //            font.pixelSize: 8
//             anchors{right:parent.right;bottom:parent.bottom}
//             selectByMouse: true
//             placeholderText: 'фільтр'
// //            color: text==''?'lightgray':'black'
//             onAccepted: selectPopupView.vpopulate(text)
//         }

    }


    // Component.onCompleted: {
    //     startBindAction.trigger();
    // }
}
