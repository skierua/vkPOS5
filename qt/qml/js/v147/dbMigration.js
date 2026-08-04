.pragma library


/**
 * Головна функція ініціалізації та оновлення структури бази даних SQLite
 * @param {Object} db - C++ драйвер бази даних
 */
function initDatabase(db) {
    if (!db) return;

    // 1. Зчитуємо поточну системну версію заголовка файлу
    let currentVersion = 0;
    const versionResult = db.dbSelectRowsJSON("PRAGMA user_version;");

    if (/*Array.isArray(versionResult) && */versionResult.length > 0) {
        currentVersion = Number(versionResult[0].user_version || 0);
    }

    console.log("[Migration] Поточна системна версія бази даних: " + currentVersion);

    // --- КРОК 1: Базова ініціалізація (Якщо база абсолютно нова: v0 -> v1) ---
    if (currentVersion < 1) {
        console.log("[Migration] Створення базових таблиць каси...");

        // Таблиця кратності пакувань (з нашого найпершого кроку)
        // db.dbSelectRowsJSON("CREATE TABLE IF NOT EXISTS articlepriceqty (" +
        //                     "pkey TEXT PRIMARY KEY, " +
        //                     "qty REAL DEFAULT 1.0);");

        // // Системна таблиця конфігурацій (куди Conf.setVal пише JSON)
        // db.dbSelectRowsJSON("CREATE TABLE IF NOT EXISTS sys_config (" +
        //                     "key TEXT PRIMARY KEY, " +
        //                     "val TEXT);"); // val зберігатиме JSON-рядки

        // currentVersion = 1;
        // db.dbSelectRowsJSON("PRAGMA user_version = 1;");
    }

    // --- КРОК 2: Додавання нових фінансових модулів (v1 -> v147) ---
    // Якщо ви додаєте велике оновлення з налаштуваннями REST, РРО та Рахунків:
    if (currentVersion < 147) {
        console.log("[Migration] Оновлення структури до версії 147 (Додавання шлюзів REST та РРО)...");
        to_v147(db);
        console.log("[Migration] Структуру бази даних успішно оновлено до версії 147!");
    }
}

function to_v147(db){
    try {
        // Тимчасово вимикаємо зовнішні ключі для безпечної перебудови зв'язків таблиць
        db.dbSelectRowsJSON("PRAGMA foreign_keys = OFF;");

        // Відкриваємо фінансову транзакцію безпеки
        db.dbSelectRowsJSON("BEGIN TRANSACTION;");

        // -----------------------------------------------------------------------------
        // МОДЕРНІЗАЦІЯ ТАБЛИЦІ КЛІЄНТІВ (client -> UTC)
        // -----------------------------------------------------------------------------
        console.log("[Migration] Перебудова таблиці клієнтів (client)...");
        db.dbSelectRowsJSON("CREATE TABLE IF NOT EXISTS tmpclient (pkey text, clchar text, phone text, clnote text, inptime text);");
        db.dbSelectRowsJSON("INSERT INTO tmpclient SELECT pkey, clchar, phone, clnote, inptime FROM client;");
        db.dbSelectRowsJSON("DROP TABLE IF EXISTS client;");

        db.dbSelectRowsJSON("CREATE TABLE client (" +
                            "  pkey text primary key, " +
                            "  clchar text unique, " +
                            "  phone text, " +
                            "  clnote text, " +
                            "  inptime text not null default ( strftime('%Y-%m-%dT%H:%M:%SZ', 'now') )" +
                            ");");

        // Безпечно конвертуємо час у UTC (-3 години), ігноруючи null значення
        db.dbSelectRowsJSON("INSERT INTO client " +
                            "SELECT pkey, clchar, phone, clnote, " +
                            "CASE WHEN inptime IS NOT NULL THEN strftime('%Y-%m-%dT%H:%M:%SZ', inptime, '-3 hours') ELSE strftime('%Y-%m-%dT%H:%M:%SZ', 'now') END " +
                            "FROM tmpclient;");
        db.dbSelectRowsJSON("DROP TABLE IF EXISTS tmpclient;");


        // -----------------------------------------------------------------------------
        // МОДЕРНІЗАЦІЯ ТАБЛИЦІ ЦІН (price -> Зовнішні зв'язки та UTC)
        // -----------------------------------------------------------------------------
        console.log("[Migration] Перебудова таблиці цін (price)...");
        db.dbSelectRowsJSON("CREATE TABLE IF NOT EXISTS tmpprice (id integer, item text, prbidask integer, qtty numeric, price numeric, pricetime text, prtype text, diff numeric);");
        db.dbSelectRowsJSON("INSERT INTO tmpprice SELECT id, item, prbidask, qtty, price, pricetime, prtype, diff FROM price;");
        db.dbSelectRowsJSON("DROP TABLE IF EXISTS price;");

        db.dbSelectRowsJSON("CREATE TABLE price (" +
                            "    id integer primary key, " +
                            "    item text not null references item (pkey) on update cascade on delete restrict, " +
                            "    prbidask integer check ((prbidask = 1) or (prbidask = -1)), " +
                            "    qtty numeric default 1 check (qtty >=0), " +
                            "    price numeric not null default 0 check (price >= 0), " +
                            "    pricetime text default ( strftime('%Y-%m-%dT%H:%M:%SZ', 'now') ), " +
                            "    prtype text, " +
                            "    diff numeric default 0" +
                            ");");

        db.dbSelectRowsJSON("INSERT INTO price " +
                            "SELECT id, item, prbidask, qtty, price, " +
                            "CASE WHEN pricetime IS NOT NULL THEN strftime('%Y-%m-%dT%H:%M:%SZ', pricetime, '-3 hours') ELSE strftime('%Y-%m-%dT%H:%M:%SZ', 'now') END, " +
                            "prtype, diff " +
                            "FROM tmpprice;");
        db.dbSelectRowsJSON("DROP TABLE IF EXISTS tmpprice;");

        // -----------------------------------------------------------------------------
        // 3. МОДЕРНІЗАЦІЯ ГОЛОВНОЇ ТАБЛИЦІ ДОКУМЕНТІВ (docum -> UTC та autoincrement)
        // -----------------------------------------------------------------------------
        console.log("[Migration] Перебудова головної таблиці документів (docum)...");
        db.dbSelectRowsJSON("CREATE TABLE IF NOT EXISTS tmpdocum (id integer, dcmtype text, dcmno text, item text, acntdbt text, acntcdt text, amount numeric, eqamount numeric, discount numeric, bonus numeric, client text, parentid integer, dcmstate integer, dcmnote text, dcmtime text, dcmaker text, retfor integer);");
        db.dbSelectRowsJSON("INSERT INTO tmpdocum SELECT id, dcmtype, dcmno, item, acntdbt, acntcdt, amount, eqamount, discount, bonus, client, parentid, dcmstate, dcmnote, dcmtime, dcmaker, retfor FROM docum;");
        db.dbSelectRowsJSON("DROP TABLE IF EXISTS docum;");

        db.dbSelectRowsJSON("CREATE TABLE docum (" +
                            "  id integer primary key autoincrement, " +
                            "  dcmtype text references dcmtype (pkey) on update cascade on delete restrict, " +
                            "  dcmno text, " +
                            "  item text references item (pkey) on update cascade on delete restrict, " +
                            "  acntdbt text, " +
                            "  acntcdt text, " +
                            "  amount numeric, " +
                            "  eqamount numeric, " +
                            "  discount numeric, " +
                            "  bonus numeric, " +
                            "  client text, " +
                            "  parentid integer, " +
                            "  dcmstate integer not null default 0, " +
                            "  dcmnote text, " +
                            "  dcmtime text not null default ( strftime('%Y-%m-%dT%H:%M:%SZ', 'now') ), " +
                            "  dcmaker text, " +
                            "  retfor integer" +
                            ");");

        // Переносимо історію з безпечним зсувом часу до UTC стандарту.
        // Обов'язково зберігаємо первинні ID (для autoincrement) та захищаємо від порожніх дат.
        db.dbSelectRowsJSON("INSERT INTO docum (id, dcmtype, dcmno, item, acntdbt, acntcdt, amount, eqamount, discount, bonus, client, parentid, dcmstate, dcmnote, dcmtime, dcmaker, retfor) " +
                            "SELECT id, dcmtype, dcmno, item, acntdbt, acntcdt, amount, eqamount, discount, bonus, client, parentid, dcmstate, dcmnote, " +
                            "CASE WHEN dcmtime IS NOT NULL AND dcmtime !== '' THEN strftime('%Y-%m-%dT%H:%M:%SZ', dcmtime, '-3 hours') ELSE strftime('%Y-%m-%dT%H:%M:%SZ', 'now') END, " +
                            "dcmaker, retfor " +
                            "FROM tmpdocum;");
        db.dbSelectRowsJSON("DROP TABLE IF EXISTS tmpdocum;");

        db.dbSelectRowsJSON("DELETE FROM sqlite_sequence WHERE name = 'docum';");
        db.dbSelectRowsJSON("INSERT INTO sqlite_sequence (name, seq) VALUES ('docum', (SELECT COALESCE(MAX(dcmid), 0) + 1 FROM strgdocum));");

        // -----------------------------------------------------------------------------
        // МОДЕРНІЗАЦІЯ ТАБЛИЦІ ЗНИЖОК ТОВАРІВ (selldsc -> UTC)
        // -----------------------------------------------------------------------------
        console.log("[Migration] Перебудова таблиці знижок товарів (selldsc)...");
        db.dbSelectRowsJSON("CREATE TABLE IF NOT EXISTS tmpselldsc (article text, price numeric, pricetime text);");
        db.dbSelectRowsJSON("INSERT INTO tmpselldsc SELECT article, price, pricetime FROM selldsc;");
        db.dbSelectRowsJSON("DROP TABLE IF EXISTS selldsc;");

        db.dbSelectRowsJSON("CREATE TABLE selldsc (" +
                            "    article text primary key references item (pkey) on update cascade on delete restrict, " +
                            "    price numeric not null default 0, " +
                            "    pricetime text default ( strftime('%Y-%m-%dT%H:%M:%SZ', 'now') )" +
                            ");");

        db.dbSelectRowsJSON("INSERT INTO selldsc " +
                            "SELECT article, price, " +
                            "CASE WHEN pricetime IS NOT NULL AND pricetime !== '' THEN strftime('%Y-%m-%dT%H:%M:%SZ', pricetime, '-3 hours') ELSE strftime('%Y-%m-%dT%H:%M:%SZ', 'now') END " +
                            "FROM tmpselldsc;");
        db.dbSelectRowsJSON("DROP TABLE IF EXISTS tmpselldsc;");


        // -----------------------------------------------------------------------------
        // МОДЕРНІЗАЦІЯ ТАБЛИЦІ ПРОПОЗИЦІЙ (selloffer -> UTC)
        // -----------------------------------------------------------------------------
        console.log("[Migration] Перебудова таблиці пропозицій (selloffer)...");
        db.dbSelectRowsJSON("CREATE TABLE IF NOT EXISTS tmpselloffer (article text, qtty numeric, price numeric, pricetime text);");
        db.dbSelectRowsJSON("INSERT INTO tmpselloffer SELECT article, qtty, price, pricetime FROM selloffer;");
        db.dbSelectRowsJSON("DROP TABLE IF EXISTS selloffer;");

        db.dbSelectRowsJSON("CREATE TABLE selloffer (" +
                            "    article text primary key references item (pkey) on update cascade on delete restrict, " +
                            "    qtty numeric default 1 check (qtty >=0), " +
                            "    price numeric not null default 0 check (price >=0), " +
                            "    pricetime text default ( strftime('%Y-%m-%dT%H:%M:%SZ', 'now') )" +
                            ");");

        db.dbSelectRowsJSON("INSERT INTO selloffer " +
                            "SELECT article, qtty, price, " +
                            "CASE WHEN pricetime IS NOT NULL AND pricetime !== '' THEN strftime('%Y-%m-%dT%H:%M:%SZ', pricetime, '-3 hours') ELSE strftime('%Y-%m-%dT%H:%M:%SZ', 'now') END " +
                            "FROM tmpselloffer;");
        db.dbSelectRowsJSON("DROP TABLE IF EXISTS tmpselloffer;");


        // -----------------------------------------------------------------------------
        // ПЕРЕСТВОРЕННЯ ТРИГЕРІВ АВТОМАТИЧНИХ ПРОВОДОК (Оптимізація під UTC)
        // -----------------------------------------------------------------------------
        console.log("[Migration] Перестворення системних тригерів проводок (acnt updates)...");
        db.dbSelectRowsJSON("DROP TRIGGER IF EXISTS t_documtran_ai1;");
        db.dbSelectRowsJSON("DROP TRIGGER IF EXISTS t_documtran_ai2;");

        db.dbSelectRowsJSON("CREATE TRIGGER t_documtran_ai1 after insert on documtran when new.amount>0 " +
                            "begin " +
                            "  update acnt set turndbt = turndbt + new.amount, dbtupd = strftime('%Y-%m-%dT%H:%M:%SZ', 'now') where id = new.dbtid; " +
                            "  update acnt set turncdt = turncdt + new.amount, cdtupd = strftime('%Y-%m-%dT%H:%M:%SZ', 'now') where id = new.cdtid; " +
                            "end;");

        db.dbSelectRowsJSON("CREATE TRIGGER t_documtran_ai2 after insert on documtran when new.amount<0 " +
                            "begin " +
                            "  update acnt set turncdt = turncdt - new.amount, cdtupd = strftime('%Y-%m-%dT%H:%M:%SZ', 'now') where id = new.dbtid; " +
                            "  update acnt set turndbt = turndbt - new.amount, dbtupd = strftime('%Y-%m-%dT%H:%M:%SZ', 'now') where id = new.cdtid; " +
                            "end;");


        // -----------------------------------------------------------------------------
        // РЕЄСТРАЦІЯ НОВОГО ТИПУ ДОКУМЕНТА (taxcheck - Фіскальний чек ПРРО)
        // -----------------------------------------------------------------------------
        console.log("[Migration] Реєстрація фіскального типу документа (taxcheck) у dcmtype...");
        db.dbSelectRowsJSON("INSERT OR IGNORE INTO 'dcmtype' ('pkey', 'dctpchar', 'dctpname', 'tranable') " +
                            "VALUES ('taxcheck', 'TAX:ЧЕК', NULL, 0);");

        // -----------------------------------------------------------------------------
        // СТВОРЕННЯ ТА НАПОВНЕННЯ НОВОЇ СИСТЕМНОЇ ТАБЛИЦІ КОНФІГУРАЦІЙ (conf)
        // -----------------------------------------------------------------------------
        console.log("[Migration] Створення та міграція системних конфігурацій (conf)...");
        db.dbSelectRowsJSON("CREATE TABLE IF NOT EXISTS 'conf' (" +
                            "    'key' TEXT PRIMARY KEY NOT NULL, " +
                            "    'val' TEXT" +
                            ") WITHOUT ROWID;");
        console.log("[Migration] Table conf created!");

        // Наповнюємо базовими JSON-конфігами для терміналу, гривні, REST та TAX шлюзів
        db.dbSelectRowsJSON("INSERT OR IGNORE INTO 'conf' ('key', 'val') VALUES " +
                            "('term', '{\"id\": \"TEST\", \"name\": \"test terminal\", \"amnt_sign\": \"-1\", \"pos_printer\": \"\", \"auto_print\": \"\", \"print_dcm\": \"\"}'), " +
                            "('domestic', '{\"id\": \"980\", \"chid\": \"UAH\", \"name\": \"українська гривня\"}'), " +
                            "('rest', '{\"host\": \"http://test.kantorfk.com\", \"api\": \"/api/v5\", \"user\": \"\", \"psw\": \"\"}'), " +
                            "('tax', '{\"host\": \"*https://test.cashdesk.com.ua\", \"api\": \"/api/v2\", \"cash\":\"\", \"token\":\"\"}');");
        console.log("[Migration] Table conf updated!");

        // Мігруємо старі рахунки (acnts) із застарілої таблиці settings
        // Перевіряємо, чи існує стара таблиця settings в базі перед вичитуванням
        const checkSettings = db.dbSelectRowsJSON("SELECT name FROM sqlite_master WHERE type='table' AND name='settings';");
        if (/*Array.isArray(checkSettings) && */checkSettings.length > 0) {
            db.dbSelectRowsJSON("INSERT OR IGNORE INTO 'conf' ('key', 'val') VALUES ('acntlist', (SELECT acnts FROM settings LIMIT 1));");
            db.dbSelectRowsJSON("DROP TABLE IF EXISTS settings;");
            console.log("[Migration] Дані старого плану рахунків успішно перенесені в таблицю 'conf'.");
        }

        // Фіксуємо транзакцію в заголовок файлу
        db.dbSelectRowsJSON("COMMIT;");

        // Піднімаємо версію в заголовку SQLite до 147
        db.dbSelectRowsJSON("PRAGMA user_version = 147;");
        console.log("[Migration] Базу даних успішно модернізовано до версії 147");
    } catch (error) {
        console.error("[Migration] Критична помилка міграції: " + String(error));
        db.dbSelectRowsJSON("ROLLBACK;");
    } finally {
        // Обов'язково повертаємо контроль цілісності зв'язків назад
        db.dbSelectRowsJSON("PRAGMA foreign_keys = ON;");
    }

}
