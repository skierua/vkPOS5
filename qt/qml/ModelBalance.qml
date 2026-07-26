import QtQuick

import "js/v147/sqlItem.js" as LibItem
import "js/v147/sqlAcnt.js" as LibAcnt
import "js/v147/sqlPrice.js" as LibPrice

ListModel {
    id: root

    // ✅ ВИПРАВЛЕНО КРИТИЧНИЙ БАГ QT6: Перейменовано 'data' на 'rawData',
    // щоб уникнути конфлікту із зарезервованим системним словом C++ у ListModel
    property var rawData: []
    property int pageCapacity: 40
    property list<int> pager: []
    property var sectTotal: [] // Суми для секцій кас

    // Оновлена функція логування через сучасні шаблонні рядки JS
    function dbg(str, code = "") {
        console.log(`[ModelBalance.qml]#${code} ${str}`);
    }

    // Безпечна валідація фільтра (Захищена від null значень у SQLite базі)
    function isAllowed(item, flt) {
        if (!item) return false;
        if (!flt || flt === "") return true;

        const filterLower = flt.toLowerCase();

        // ✅ ОПТИМІЗАЦІЯ: Нативний метод .includes() та оператор ?. захищають від падіння додатка
        const scancodeStr = String(item.scancode || "").toLowerCase();
        const charStr = String(item.itemchar || "").toLowerCase();
        const nameStr = String(item.itemname || "").toLowerCase();
        const noteStr = String(item.itemnote || "").toLowerCase();

        return (item.id === flt
                || scancodeStr.includes(filterLower)
                || charStr.includes(filterLower)
                || nameStr.includes(filterLower)
                || noteStr.includes(filterLower));
    }

    // Головна функція калькуляції та завантаження залишків
    function load(db, bal = "300", order = "id", flt = "") {
        root.clear();
        if (!db || bal.length < 2) return;

        let tmp = [];
        let r =0;
        const acntBalance = LibAcnt.balBalance(db, bal) || [];

        // console.log(`ModelBalance length=${acntBalance.length}`)
        for (r = 0; r < acntBalance.length; ++r) {
            let crntItem = LibItem.getItemById(db, acntBalance[r].itemid);

            // Якщо валюта не відповідає фільтру пошуку — пропускаємо її
            if (!isAllowed(crntItem, flt)) continue;

            let row = acntBalance[r];
            row.item = crntItem ? crntItem : LibItem.dummyItem();

            // Визначаємо критерій групування для секцій
            row.bind = (order === "id") ? String(acntBalance[r].balname || "") : String(row.item.pathname || "");

            // Витягуємо курс обміну з бази
            const pr = LibPrice.sell(db, acntBalance[r].itemid) || { "price": 0, "qtty": 1 };
            const denominator = Number(pr.qtty || 1) === 0 ? 1 : Number(pr.qtty);
            const prval = Number(pr.price || 0) / denominator;

            row.price = prval;

            // ✅ ВИПРАВЛЕНО БАГ СОРТУВАННЯ "COST": Розраховуємо та зберігаємо точний фінансовий еквівалент!
            row.eq = prval * Number(acntBalance[r].total || 0);

            tmp.push(row);
        }

        // --- БЛОК СУЧАСНОГО СОРТУВАННЯ (ES6 Стрілочні функції) ---
        if (order === "id") {
            tmp.sort((a, b) => (String(a.item?.id || "") < String(b.item?.id || "")) ? -1 : 1);
        } else if (order === "name") {
            tmp.sort((a, b) => {
                const pathComp = String(a.item?.pathname || "").localeCompare(String(b.item?.pathname || ""));
                if (pathComp !== 0) return pathComp;
                return String(a.item?.itemchar || "").localeCompare(String(b.item?.itemchar || ""));
            });
        } else if (order === "cost") {
            // ✅ ТЕПЕР ПРАЦЮЄ НАДІЙНО: Сортування за вартістю еквівалента (від більшого до меншого)
            tmp.sort((a, b) => {
                const pathComp = String(a.item?.pathname || "").localeCompare(String(b.item?.pathname || ""));
                if (pathComp !== 0) return pathComp;
                return b.eq - a.eq; // Швидке математичне сортування чисел
            });
        } else if (order === "datein") {
            tmp.sort((a, b) => {
                const pathComp = String(a.item?.pathname || "").localeCompare(String(b.item?.pathname || ""));
                if (pathComp !== 0) return pathComp;
                return (a.intm < b.intm) ? 1 : -1;
            });
        } else if (order === "dateout") {
            tmp.sort((a, b) => {
                const pathComp = String(a.item?.pathname || "").localeCompare(String(b.item?.pathname || ""));
                if (pathComp !== 0) return pathComp;
                return (a.outm < b.outm) ? 1 : -1;
            });
        }

        // --- ШВИДКИЙ РОЗРАХУНОК ПІДСУМКІВ ПО СЕКЦІЯХ (КАСАХ) ---
        let tmpTotal = [];
        let sect = "";
        let tot = 0;

        for (r = 0; r < tmp.length; ++r) {
            if (sect === tmp[r].bind) {
                tot += Number(tmp[r].price * Number(tmp[r].total || 0));
            } else {
                if (sect !== "") {
                    tmpTotal.push({ "path": sect, "total": tot });
                }
                sect = tmp[r].bind;
                tot = Number(tmp[r].price * Number(tmp[r].total || 0));
            }
        }
        if (sect !== "") {
            tmpTotal.push({ "path": sect, "total": tot });
        }

        root.sectTotal = tmpTotal;
        root.rawData = tmp; // Фіксуємо чистий відсортований масив

        // Рендеримо першу сторінку пагінації на екран
        populate(1);
    }

    // Оптимізована посторінкова пагінація логів касира
    function populate(page = 1) {
        root.clear();
        if (!root.rawData || root.rawData.length === 0) return;

        let pageNum = Number(page);
        let startIndex = (pageNum < 2) ? 0 : (pageNum - 1) * root.pageCapacity;
        let endIndex = pageNum * root.pageCapacity;

        for (let offset = startIndex; offset < root.rawData.length && offset < endIndex; ++offset) {
            root.append(root.rawData[offset]);
        }
    }

    // Нативний метод отримання підсумку каси для секцій екрана Balance.qml
    function getTotal(id) {
        if (!root.sectTotal || !Array.isArray(root.sectTotal)) return 0;
        const sect = root.sectTotal.find((v) => v.path === id);
        return sect !== undefined ? sect.total : 0;
    }
}
