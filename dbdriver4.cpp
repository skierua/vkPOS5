#include "dbdriver4.h"

#include <QSqlQuery>
#include <QSqlRecord>
#include <QSqlError>
#include <QVariantMap>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>

// #include <QVariantList>

#include <QDebug>

DbDriver4::DbDriver4(QObject *parent)
    : QObject(parent)
{
    // ✅ ВИПРАВЛЕНО БАГ З'ЄДНАННЯ: Використовуємо дефолтне з'єднання за замовчуванням (без параметра "st").
    // Це золотий стандарт Qt6 для локальних SQLite баз. Тепер витоки дескрипторів повністю закриті.
    m_db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"));
}
/*
DbDriver4::DbDriver4(QObject *parent) : QObject(parent) {
    // ...
    // qDebug()<<"DbDriver4 constructor started";
    m_db = QSqlDatabase::addDatabase("QSQLITE", "st");

}
*/

bool DbDriver4::openConnection()
{
    // Лічильник посилань: відкриваємо фізичну базу тільки для першого вхідного виклику
    if (++m_cc == 1) {
        if (!m_db.open()) {
            // ✅ ВИПРАВЛЕНО: Актуалізовано ім'я класу (DbDriver4 замість DbDriver3) та оптимізовано виділення пам'яті
            m_lastError = QStringLiteral("EE:DbDriver4::openConnection database ERROR OPEN...\nName: %1 (Type: %2)\n%3")
                              .arg(m_db.databaseName(), m_db.driverName(), m_db.lastError().text());

            qDebug() << m_lastError;
            m_cc = 0; // Скидаємо лічильник назад у нуль
            return false;
        } else {
            // Вмикаємо контроль зовнішніх ключів для збереження цілісності зв'язків
            // m_db.exec(QStringLiteral("PRAGMA foreign_keys = ON;"));

            // // Вмикаємо сучасний режим журналу WAL. Він дозволяє касі одночасно
            // // швидко писати чеки в базу і не блокувати QML-компоненти, які в цей же момент читають баланси.
            // m_db.exec(QStringLiteral("PRAGMA journal_mode = WAL;"));

            // // Знижуємо синхронізацію до NORMAL (у режимі WAL це на 100% безпечно від збоїв живлення,
            // // але прискорює роботу SQLite на SSD накопичувачах у рази)
            // m_db.exec(QStringLiteral("PRAGMA synchronous = NORMAL;"));
        }
    }
    return true;
}

void DbDriver4::closeConnection()
{
    if (--m_cc <= 0) {
        m_db.close();
        m_cc = 0; // Захист від випадкових від'ємних значень лічильника
    }
}

bool DbDriver4::setDbParameter(const QString & name, const QString & type, const QString & conn)
{
    // qDebug() << "DbDriver4::setDbParameter name=" << name;
    // m_status = StDataLoading;
    // m_hash.removePrefix();
    // m_conn = conn;
    // m_db.close();
    // m_cc = 0;
    // if (!m_conn.isEmpty() && (type != "QSQLITE")){
    //     m_db = QSqlDatabase::addDatabase(type, m_conn);
    // }
    Q_UNUSED(type); // Пригнічуємо попередження компилятора про невикористані змінні з легасі-коду
    Q_UNUSED(conn);

    // Задаємо абсолютний шлях до файлу бази даних
    m_db.setDatabaseName(name);
    bool ok = false;
    if (openConnection()) {
        ok = true;
        QSqlQuery ("PRAGMA foreign_keys = ON;", m_db);
        // QSqlQuery q(QStringLiteral("SELECT branchname, branchname2, branchaddres, dbversion, domcur, domchar, domname FROM settings"), m_db);
        // if (!q.lastError().isValid()) {
        //     if (q.next()) {
        //         // Витягуємо версію бази даних із 3-го індексу (стовпчик dbversion)
        //         m_dbVersion = q.value(3).toString();

        //         // Для налагодження можна розкоментувати або вивести у msg лог:
        //         // qDebug() << "Ініціалізація каси успішна. Версія БД:" << m_dbVersion;
        //     }
        // } else {
        //     m_lastError = q.lastError().text();
        //     qDebug() << QStringLiteral("Помилка читання таблиці settings:") << m_lastError;
        //     emit error(m_lastError);
        //     emit vkEvent(QStringLiteral("error"), m_lastError);
        // }

        // m_hash.loadSqlData(m_db, "select acnt.acntno||'/'||coalesce(item,''), id, coalesce(eqid,0), coalesce(rsltid,0) from acnt left join acntrade on(id=pkey)",
        //                    QString(" acnt.acntno = '%1' or acnt.acntno = '%2' ").arg(m_cashDfltAcnt, m_tradeDfltAcnt), "acnt/", false);

        closeConnection();
        // QSettings().setValue("database/last_db_name", name);
        // QSettings().setValue("database/last_db_driver", type);
        // m_status = StOk;
    } else {
        qDebug() << QStringLiteral("Не вдалося відкрити базу даних при налаштуванні параметрів:") << name;
    }

    // emit driverStatusChanged(m_status);
    return ok;
}

bool DbDriver4::closeShift(const QString &shftid)
{
    m_lastError.clear();

    if (!openConnection()) {
        return false;
    }

    bool commitstatus = true;
    QString qerror;

    m_db.transaction();

    // 1. Очищаємо незавершені («зомбі») або скасовані документи
    QSqlQuery q(QStringLiteral("DELETE FROM docum WHERE dcmstate = 0 OR dcmstate = 8;"), m_db);
    if (q.lastError().isValid()) {
        commitstatus = false;
        qerror += QStringLiteral("\n[Zombie Delete Error]: ") + q.lastError().text();
    }

    // 2. Очищаємо старий архів рахунків (старше 6 місяців)
    if (commitstatus) {
        QString vstr = QStringLiteral("DELETE FROM strgacnt WHERE shftid = 0 OR shftid = %1 "
                                      "OR (shftid < (SELECT max(id) FROM shift WHERE shftdate <= date('now', '-6 month')));")
                           .arg(shftid);
        q = QSqlQuery(vstr, m_db);
        if (q.lastError().isValid()) {
            commitstatus = false;
            qerror += QStringLiteral("\n[Archive Account Clear Error]: ") + q.lastError().text();
        }
    }

    // 3. Очищаємо архів документів поточної зміни, якщо він перезаписується
    if (commitstatus) {
        QString vstr = QStringLiteral("DELETE FROM strgdocum WHERE shftid = 0 OR shftid = %1;").arg(shftid);
        q = QSqlQuery(vstr, m_db);
        if (q.lastError().isValid()) {
            commitstatus = false;
            qerror += QStringLiteral("\n[Archive Document Clear Error]: ") + q.lastError().text();
        }
    }

    // 4. Очищаємо стару історію змін курсів
    // if (commitstatus) {
    //     q = QSqlQuery(QStringLiteral("DELETE FROM strgprice WHERE pricetime <= date('now', '-6 month');"), m_db);
    //     if (q.lastError().isValid()) {
    //         commitstatus = false;
    //         qerror += QStringLiteral("\n[Price Clear Error]: ") + q.lastError().text();
    //     }
    // }

    // 5. Очищаємо старі зв'язки транзакцій документів
    if (commitstatus) {
        q = QSqlQuery(QStringLiteral("DELETE FROM strgtran WHERE dcmid <= (SELECT max(dcmid) FROM strgdocum WHERE dcmtime < date('now', '-6 month'));"), m_db);
        if (q.lastError().isValid()) {
            commitstatus = false;
            qerror += QStringLiteral("\n[Transaction Clear Error]: ") + q.lastError().text();
        }
    }

    // 6. АРХІВАЦІЯ: Переносимо поточний стан рахунків в історію
    if (commitstatus) {
        q = QSqlQuery(QStringLiteral("INSERT INTO strgacnt (shftid, acntid, acntno, item, beginamnt, turndbt, turncdt) "
                                     "SELECT %1, id, acntno, item, beginamnt, turndbt, turncdt "
                                     "FROM acnt WHERE turndbt != 0 OR turncdt != 0;").arg(shftid), m_db);
        if (q.lastError().isValid()) {
            commitstatus = false;
            qerror += QStringLiteral("\n[Account Archive Error]: ") + q.lastError().text();
        }
    }

    // 7. АРХІВАЦІЯ: Переносимо успішні документи зміни в історію (dcmstate 1 або 4)
    if (commitstatus) {
        q = QSqlQuery(QStringLiteral("INSERT INTO strgdocum (dcmid, shftid, dcmtype, dcmno, item, acntdbt, acntcdt, amount, eqamount, discount, bonus, client, parentid, dcmstate, dcmnote, dcmtime, dcmaker, retfor) "
                                    "SELECT id, %1, dcmtype, dcmno, item, acntdbt, acntcdt, amount, eqamount, discount, bonus, client, parentid, dcmstate, dcmnote, dcmtime, dcmaker, retfor "
                                     "FROM docum WHERE dcmstate = 1 OR dcmstate = 4;").arg(shftid), m_db);
        if (q.lastError().isValid()) {
            commitstatus = false;
            qerror += QStringLiteral("\n[Document Archive Error]: ") + q.lastError().text();
        }
    }

    // 8. АРХІВАЦІЯ: Переносимо валютні проводки чеків в історію
    if (commitstatus) {
        q = QSqlQuery(QStringLiteral("INSERT INTO strgtran (dcmid, amount, dbtid, cdtid) SELECT dcmid, amount, dbtid, cdtid FROM documtran;"), m_db);
        if (q.lastError().isValid()) {
            commitstatus = false;
            qerror += QStringLiteral("\n[Documtran Archive Error]: ") + q.lastError().text();
        }
    }
// qDebug() << "DbDriver4::closeShift 555 commitstatus=[" << commitstatus << "]";
    // 9. БУХГАЛТЕРСЬКИЙ ПЕРЕРАХУНОК: Закриваємо залишки рахунків на новий день (Сальдо)
    if (commitstatus) {
        q = QSqlQuery(QStringLiteral("UPDATE acnt SET beginamnt = beginamnt + turndbt - turncdt;"), m_db);
        if (q.lastError().isValid()) {
            commitstatus = false;
            qerror += QStringLiteral("\n[Account Roll Forward Error]: ") + q.lastError().text();
        }
    }

    // 10. ОЧИЩЕННЯ РОБОЧИХ ТАБЛИЦЬ: Видаляємо проводки поточної зміни
    if (commitstatus) {
        q = QSqlQuery(QStringLiteral("DELETE FROM documtran;"), m_db);
        if (q.lastError().isValid()) {
            commitstatus = false;
            qerror += QStringLiteral("\n[Documtran Clear Error]: ") + q.lastError().text();
        }
    }

    // 11. Видаляємо закриті документи з робочої таблиці (вони вже в архіві strgdocum)
    if (commitstatus) {
        q = QSqlQuery(QStringLiteral("DELETE FROM docum WHERE dcmstate = 1 OR dcmstate = 4;"), m_db);
        if (q.lastError().isValid()) {
            commitstatus = false;
            qerror += QStringLiteral("\n[Docum Clear Error]: ") + q.lastError().text();
        }
    }

    // 12. Обнуляємо поточні обороти рахунків для нового робочого дня
    if (commitstatus) {
        q = QSqlQuery(QStringLiteral("UPDATE acnt SET turndbt = 0, turncdt = 0;"), m_db);
        if (q.lastError().isValid()) {
            commitstatus = false;
            qerror += QStringLiteral("\n[Account Reset Error]: ") + q.lastError().text();
        }
    }

    // 13. ФІКСАЦІЯ ЧАСУ: Записуємо дату закриття зміни в ISO форматі під Qt6
    if (commitstatus) {
// !!! QString isoDateTime = QDateTime::currentDateTime().toString(Qt::DateFormat::ISODate); !!!
        QString isoDateTime = QDateTime::currentDateTimeUtc().toString(Qt::DateFormat::ISODate);
        q = QSqlQuery(QStringLiteral("UPDATE shift SET shftend = '%1' WHERE id = %2 ;").arg(isoDateTime, shftid), m_db);
        // q = QSqlQuery(QStringLiteral("UPDATE shift SET shftend = '%1' WHERE id = %2 ;").arg(isoDateTime).arg(shftid), m_db);
        if (q.lastError().isValid()) {
            commitstatus = false;
            qerror += QStringLiteral("\n[Shift Update Time Error]: ") + q.lastError().text();
        }
    }

    // --- ФІНАЛІЗАЦІЯ ТРАНЗАКЦІЇ ---
    if (commitstatus) {
        // Якщо ВСІ 13 кроків пройшли успішно — фіксуємо зміни на диск SSD
        m_db.commit();
        qDebug() << "Зміну успішно закрито. ID зміни:" << shftid;
    } else {
        // Якщо стався бодай ОДИН збій — повністю скасовуємо все закриття. Каса залишиться у безпеці.
        m_db.rollback();
        m_lastError = QStringLiteral("EE:DbDriver4::closeShift Closing error\n") + qerror;
        qDebug() << m_lastError;
        emit error(m_lastError);
        emit vkEvent(QStringLiteral("error"), m_lastError);
    }

    closeConnection();
    return commitstatus;
}
/*
bool DbDriver4::closeShift(const QString &shftid)
{
    QSqlQuery q = QSqlQuery(m_db);
    QString vstr = QString();
    m_lastError = "";
    // QString closeDate = QString();
    if (!openConnection()) {
        return false;
    }
    //    q = QSqlQuery(QString("delete from docum where dcmstate = 0;"), m_db);
    q = QSqlQuery(QString("delete from docum where dcmstate = 0 or dcmstate = 8;"), m_db);
    if (!q.isActive()) {
        m_lastError = tr("Zombie deleting error");
        qDebug() << "EE:DbDriver3::closeShift Zombie deleting error sqlerror="<<q.lastError();
        return false;
    }
    // int newId = 0;
    bool commitstatus = true;
    QString qerror = QString();

    // revaluation2();

    m_db.transaction();


    // save current shift to storage

    // erase storage
    vstr = QString("delete from strgacnt where shftid = 0 or shftid = %1 or (shftid < (select max(id) from shift where shftdate <= date('now', '-6 month')));").arg(shftid);
    q = QSqlQuery(vstr, m_db);
    if (!q.isActive()) {
        commitstatus = false;
        qerror += "\n#1 " + q.lastError().text() + "{"+vstr+"}";
    }
    //    qDebug("Dbdrv::shiftClose 20");
    //    q = QSqlQuery(QString("delete from docum where dcmstate = 0;")); // ???
    vstr = QString("delete from strgdocum where shftid = 0 or shftid = %1;").arg(shftid);
    q = QSqlQuery(vstr, m_db);
    if (!q.isActive()) {
        commitstatus = false;
        qerror += "\n#2 " + q.lastError().text() + "{"+vstr+"}";
        //        qDebug()<< "DriverDB::shiftClose 25 q=" << q.lastQuery();
    }

    vstr = QString("delete from strgprice where pricetime <= date('now', '-6 month');");
    q = QSqlQuery(vstr, m_db);
    if (!q.isActive()) {
        commitstatus = false;
        qerror += "\n#2 " + q.lastError().text() + "{"+vstr+"}";
    }

    vstr = QString("delete from strgtran where dcmid <= (select max(dcmid) from strgdocum where dcmtime < date('now', '-6 month'));");
    q = QSqlQuery(vstr, m_db);
    if (!q.isActive()) {
        commitstatus = false;
        qerror += "\n#2 " + q.lastError().text() + "{"+vstr+"}";
    }


    q = QSqlQuery(QString("insert into strgacnt "
                          "select %1, id, acntno, item, beginamnt, turndbt, turncdt "
                          "from acnt where turndbt !=0 or turncdt !=0;").arg(shftid), m_db);
    if (!q.isActive()) {
        commitstatus = false;
        qerror += "\n" + q.lastError().text();
    }

    q = QSqlQuery(QString("insert into strgdocum select id, %1, dcmtype, dcmno, item, acntdbt, acntcdt, amount, eqamount, "
                          "discount, bonus, client, parentid, dcmstate, dcmnote, dcmtime, dcmaker, retfor "
                          "from docum where dcmstate = 1 or dcmstate = 4;").arg(shftid), m_db);        //.arg(POSDcmModel::DCMSTTRAN).arg(POSDcmModel::DCMSTDEL)

    if (!q.isActive()) {
        commitstatus = false;
        qerror += "\n" + q.lastError().text();
    }

    q = QSqlQuery(QString("insert into strgtran select dcmid, amount, dbtid, cdtid from documtran"), m_db);

    if (!q.isActive()) {
        commitstatus = false;
        qerror += "\n" + q.lastError().text();
    }

    // update account
    q = QSqlQuery(QString("update acnt set beginamnt = beginamnt + turndbt - turncdt;"), m_db);
    if (!q.isActive()) {
        commitstatus = false;
        qerror += "\n" + q.lastError().text();
    }

    q = QSqlQuery(QString("delete from documtran;"), m_db);
    if (!q.isActive()) {
        commitstatus = false;
        qerror += "\n" + q.lastError().text();
    }

    q = QSqlQuery(QString("delete from docum where dcmstate = 1 or dcmstate = 4;"), m_db);        //.arg(POSDcmModel::DCMSTTRAN).arg(POSDcmModel::DCMSTDEL)
    if (!q.isActive()) {
        commitstatus = false;
        qerror += "\n" + q.lastError().text();
    }

    // reset account
    q = QSqlQuery(QString("update acnt set turndbt = 0, turncdt = 0;"), m_db);
    if (!q.isActive()) {
        commitstatus = false;
        qerror += "\n" + q.lastError().text();
    }

    q = QSqlQuery(QString("update shift set  shftend = '%1' where id = %2 ;")
                      .arg(QDateTime::currentDateTime().toString(Qt::ISODate))
                      .arg(shftid), m_db);

    if (!q.isActive()) {
        commitstatus = false;
        qerror += "\n" + q.lastError().text();
    }




    if (commitstatus) {
        m_db.commit();
        //        QMessageBox::information(this, tr("vkPOS info"), tr("Shift successfully closed"), QMessageBox::Ok);
        //        emit shiftClosed();
    } else {
        m_db.rollback();
        m_lastError = "EE:DbDriver3::closeShift Closing error\n"+qerror;
        qDebug()<<m_lastError;
        emit error(m_lastError);
    }

    closeConnection();

    return commitstatus;
}
*/

int DbDriver4::dbInsert(const QString &sql)
{
    int id = 0;

    if (openConnection()) {
        QSqlQuery q(sql, m_db);

        if (!q.lastError().isValid()) {
            // Витягуємо ID щойно створеного запису в SQLite
            id = q.lastInsertId().toInt();
        } else {
            m_lastError = QStringLiteral("EE:DbDriver4::dbInsert query ERROR\n%1\n%2")
                              .arg(q.lastQuery(), q.lastError().text());

            qDebug() << m_lastError;

            // Синхронно оповіщаємо систему про збій генерації ID
            emit error(m_lastError);
            emit vkEvent(QStringLiteral("error"), m_lastError);
        }

        closeConnection();
    }

    return id;
}

int DbDriver4::dbInsert(const QString &sql, const QVariantList &params)
{
    int id = 0;

    if (!openConnection()) {
        return id;
    }

    QSqlQuery q(m_db);

    // 1. Попередньо готуємо запит
    if (!q.prepare(sql)) {
        m_lastError = QStringLiteral("EE:DbDriver4::dbInsert prepare ERROR\n%1\n%2")
        .arg(sql, q.lastError().text());
        qDebug() << m_lastError;
        emit error(m_lastError);
        emit vkEvent(QStringLiteral("error"), m_lastError);
        closeConnection();
        return id;
    }

    // 2. Безпечно прив'язуємо параметри
    for (const QVariant &param : params) {
        q.addBindValue(param);
    }

    // 3. Виконуємо запит
    if (q.exec()) {
        // Витягуємо ID щойно створеного запису в SQLite
        id = q.lastInsertId().toInt();
    } else {
        m_lastError = QStringLiteral("EE:DbDriver4::dbInsert exec ERROR\n%1\n%2")
        .arg(q.lastQuery(), q.lastError().text());
        qDebug() << m_lastError;

        emit error(m_lastError);
        emit vkEvent(QStringLiteral("error"), m_lastError);
    }
    qDebug() << "dbdriver #8w7 id=[" << id << "]";
    closeConnection();
    return id;
}

bool DbDriver4::dbUpdate(const QString &sql)
{
    bool res = false;

    if (openConnection()) {
        QSqlQuery q(sql, m_db);

        // qDebug()<< "8eq6#dbdriver4/dbUpdate sql="<< sql;
        if (!q.lastError().isValid()) {
            res = true;
        } else {
            m_lastError = QStringLiteral("EE:DbDriver4::dbUpdate query ERROR\n%1\n%2")
                              .arg(q.lastError().text(), q.lastQuery());

            qDebug() << m_lastError;

            // Синхронно оповіщаємо всі рівні каси про збій запиту
            emit error(m_lastError);
            emit vkEvent(QStringLiteral("error"), m_lastError);
        }

        closeConnection();
    }
    // qDebug()<< "s5g#dbdriver4/dbUpdate res="<< res;

    return res;
}

bool DbDriver4::dbUpdate(const QString &sql, const QVariantMap &params){
    if (!openConnection()) return false;
    bool ok = false;
    QSqlQuery q(m_db);
    if (!q.prepare(sql)) {
        m_lastError = QStringLiteral("EE:DbDriver4::dbInsert prepare ERROR\n%1\n%2")
        .arg(sql, q.lastError().text());
        qDebug() << m_lastError;
        emit error(m_lastError);
        emit vkEvent(QStringLiteral("error"), m_lastError);
        closeConnection();
        return ok;
    }

    // Автоматично прив'язуємо всі параметри з JS-об'єкта
    for (const QVariant &param : params) {
        // qDebug()<< "r343#dbdriver4/dbUpdate param="<< param;
        q.addBindValue(param);
    }
    // QVariantMap::const_iterator i = params.constBegin();
    // while (i != params.constEnd()) {
    //     q.bindValue(i.key(), i.value());
    //     ++i;
    // }

    ok = q.exec();
    if (!ok) {
        m_lastError = q.lastError().text();
        qDebug() << m_lastError;
        emit error(m_lastError);
        emit vkEvent(QStringLiteral("error"), m_lastError);
    }

    closeConnection();
    // const QVariantList list = q.boundValues();
    // for (qsizetype i = 0; i < list.size(); ++i)
    //     qDebug() << i << ":" << list.at(i).toString();
    // qDebug()<< "499#dbdriver4/dbUpdate ok="<< ok;
    // qDebug()<< "r343#dbdriver4/dbUpdate sql="<< q.lastQuery();
    return ok;
}

bool DbDriver4::dbUpdateParams(const QString &sql, const QVariantMap &params){
    qDebug() << "WW: DEPRECATED dbdriver4/dbUpdateParams";
    return dbUpdate(sql, params);
}

bool DbDriver4::dbDelete(const QString &sql)
{
    bool res = false;

    if (openConnection()) {
        QSqlQuery q(sql, m_db);

        // ✅ ВИПРАВЛЕНО: В Qt6 безпека фінансових транзакцій вимагає перевірки валідності останньої помилки драйвера,
        // замість поверхневого q.isActive()
        if (!q.lastError().isValid()) {
            res = true;

            // Опціонально для аудиту каси: можна перевірити, скільки саме рядків було видалено
            // int affectedRows = q.numRowsAffected();
            // if (affectedRows == 0) { ... }
        } else {
            // ✅ ВИПРАВЛЕНО: Актуалізовано назву класу в логах (DbDriver4) та прибрано витоки пам'яті
            m_lastError = QStringLiteral("EE:DbDriver4::dbDelete query ERROR\n%1\n%2")
                              .arg(q.lastError().text(), q.lastQuery());

            qDebug() << m_lastError;

            // Сигналізуємо всі рівні додатку про критичну помилку SQLite3
            emit error(m_lastError);
            emit vkEvent(QStringLiteral("error"), m_lastError);
        }

        closeConnection();
    }

    return res;
}

QVariantMap DbDriver4::dbSelectRow(const QString &sql){
    QVariantMap ret;

    if (!openConnection()) {
        ret.insert(QStringLiteral("errid"), -1);
        ret.insert(QStringLiteral("errname"), QStringLiteral("Connection failed"));
        return ret;
    }

    // Використовуємо пустий конструктор для повного контролю над виконанням
    QSqlQuery q(m_db);

    if (q.exec(sql)) {
        if (q.next()) {
            // Спочатку витягуємо дані з бази
            const QSqlRecord recordSchema = q.record();
            const int fieldCount = recordSchema.count();

            for (int i = 0; i < fieldCount; ++i) {
                ret.insert(recordSchema.fieldName(i), q.value(i));
            }

            ret.insert(QStringLiteral("errid"), 0);
            ret.insert(QStringLiteral("errname"), QString());
        } else {
            ret.insert(QStringLiteral("errid"), 1);
            ret.insert(QStringLiteral("errname"), QStringLiteral("Empty row"));
        }
    } else {
        // Запит синтаксично або логічно завалився
        m_lastError = q.lastError().text();

        // Перетворюємо тип помилки на int безпечно
        ret.insert(QStringLiteral("errid"), static_cast<int>(q.lastError().type()));
        ret.insert(QStringLiteral("errname"), m_lastError);

        emit error(m_lastError);
        emit vkEvent(QStringLiteral("error"), m_lastError);
    }

    closeConnection();
    return ret;
}

// with parameters
QVariantMap DbDriver4::dbSelectRow(const QString &sql, const QVariantList &params){
    QVariantMap ret;

    if (!openConnection()) {
        ret.insert(QStringLiteral("errid"), -1);
        ret.insert(QStringLiteral("errname"), QStringLiteral("Connection failed"));
        return ret;
    }

    QSqlQuery q(m_db);

    // 1. Попередньо компілюємо SQL-запит (захист від ін'єкцій)
    if (!q.prepare(sql)) {
        m_lastError = q.lastError().text();
        ret.insert(QStringLiteral("errid"), static_cast<int>(q.lastError().type()));
        ret.insert(QStringLiteral("errname"), m_lastError);
        closeConnection();
        return ret;
    }

    // 2. Безпечно підставляємо всі параметри з JS-масиву замість знаків "?"
    for (const QVariant &param : params) {
        q.addBindValue(param);
    }

    // 3. Виконуємо запит без передачі рядка в exec()
    if (q.exec()) {
        if (q.next()) {
            const QSqlRecord recordSchema = q.record();
            const int fieldCount = recordSchema.count();

            for (int i = 0; i < fieldCount; ++i) {
                ret.insert(recordSchema.fieldName(i), q.value(i));
            }

            ret.insert(QStringLiteral("errid"), 0);
            ret.insert(QStringLiteral("errname"), QString());
        } else {
            ret.insert(QStringLiteral("errid"), 1);
            ret.insert(QStringLiteral("errname"), QStringLiteral("Empty row"));
        }
    } else {
        m_lastError = q.lastError().text();

        ret.insert(QStringLiteral("errid"), static_cast<int>(q.lastError().type()));
        ret.insert(QStringLiteral("errname"), m_lastError);

        emit error(m_lastError);
        emit vkEvent(QStringLiteral("error"), m_lastError);
    }

    closeConnection();
    return ret;
}

/*
QVariantMap DbDriver4::dbSelectRow(const QString & sql)
{
    //    qDebug()<<"DbDriver3::getJSONRowFromSQL "<<"sql="<<sql;
    QVariantMap ret;
    if (openConnection()) {
        QSqlQuery q = QSqlQuery(sql,m_db);
        if (q.next()) {
            ret.insert("errid", 0);
            ret.insert("errname", "");
            for (int i =0; i < q.record().count(); ++i ) {
                ret.insert(q.record().fieldName(i), q.value(i));
            }
        } else {
            ret.insert("errid", 1);
            ret.insert("errname", "Empty row");
        }
        closeConnection();
    } else {
        ret.insert("errid", -1);
        ret.insert("errname", "Connection failed");
    }
    return ret;
}
*/

QVariantList DbDriver4::dbSelectRowsJSON(const QString &sql, const QString &filter)
{
    QVariantList resultList;
    const QString lowerFilter = filter.toLower();
    // qDebug() << "903y#DbDriver4::dbSelectRowsJSON sql=" << sql << " filter=" << filter;

    if (openConnection()) {
        QSqlQuery q(sql, m_db);

        if (!q.lastError().isValid()) {
            // qDebug() << "652fg#DbDriver4::dbSelectRowsJSON QUERY Ok";
            const QSqlRecord recordSchema = q.record();
            const int fieldCount = recordSchema.count();

            while (q.next()) {
                // qDebug() << "652fg#DbDriver4::dbSelectRowsJSON ROW Ok";
                bool rowMatchesFilter = filter.isEmpty();
                QVariantMap rowMap;

                // Збираємо поля рядка у QVariantMap
                for (int i = 0; i < fieldCount; ++i) {
                    QString fieldName = recordSchema.fieldName(i);
                    QVariant fieldValue = q.value(i);

                    rowMap.insert(fieldName, fieldValue);

                    if (!rowMatchesFilter && fieldValue.toString().toLower().contains(lowerFilter)) {
                        rowMatchesFilter = true;
                    }
                }

                // Додаємо в масив, якщо пройшов фільтр (тільки один раз!)
                if (rowMatchesFilter) {
                    resultList.append(rowMap);
                }
            }
        } else {
            m_lastError = q.lastError().text();
            emit error(m_lastError);
            emit vkEvent(QStringLiteral("error"), m_lastError);
        }
        closeConnection();
    } else {
        emit error(QStringLiteral("DB connection error."));
        emit vkEvent(QStringLiteral("error"), m_lastError);
    }
    // if (!resultList.count()){
    //     qDebug() << "436#DbDriver4::dbSelectRowsJSON FINISH len=" << resultList.count() << " "  << sql;
    //     // qWarning() << "37n#DbDriver4::dbSelectRowsJSON " << sql;
    // }
    // qDebug() << "903y#DbDriver4::dbSelectRowsJSON FINISH resultList=" << resultList;

    return resultList; // QML автоматично побачить це як чистий масив []
}

QString DbDriver4::dbSelectRows(const QString &sql, const QString &filter)
{
    int errId = 0;
    QString errText;
    int rowCount = 0;

    QJsonArray jsonRowsArray; // Нативний масив під JSON рядки []
    const QString lowerFilter = filter.toLower(); // Обчислюємо регістр один раз для всього запиту

    if (openConnection()) {
        QSqlQuery q(sql, m_db);

        if (!q.lastError().isValid()) {
            const QSqlRecord recordSchema = q.record();
            const int fieldCount = recordSchema.count();

            while (q.next()) {
                bool rowMatchesFilter = filter.isEmpty();
                QJsonObject jsonRow;

                // 1. Збираємо дані рядка в JSON об'єкт і паралельно перевіряємо фільтр
                for (int i = 0; i < fieldCount; ++i) {
                    QString fieldName = recordSchema.fieldName(i);
                    QVariant fieldValue = q.value(i);

                    // Додаємо в об'єкт (Qt6 сам розбереться з типами: числа, рядки, NULL)
                    jsonRow.insert(fieldName, QJsonValue::fromVariant(fieldValue));

                    // Якщо фільтр задано, перевіряємо, чи містить поточне поле шуканий текст
                    if (!rowMatchesFilter && fieldValue.toString().toLower().contains(lowerFilter)) {
                        rowMatchesFilter = true;
                    }
                }

                // 2. ✅ ВИПРАВЛЕНО БАГ ДУБЛЮВАННЯ: Додаємо рядок до масиву ТІЛЬКИ ОДИН РАЗ,
                // якщо він пройшов критерій фільтрації
                if (rowMatchesFilter) {
                    jsonRowsArray.append(jsonRow);
                    ++rowCount;
                }
            }
        } else {
            errId = static_cast<int>(q.lastError().type());
            errText = q.lastError().text();
        }
        closeConnection();
    } else {
        errId = 1;
        errText = QStringLiteral("DB connection error.");
    }

    // 3. Формуємо підсумкову фінансову структуру відповіді
    QJsonObject resultRoot;
    resultRoot.insert(QStringLiteral("errorId"), errId);
    resultRoot.insert(QStringLiteral("errorText"), errText);
    resultRoot.insert(QStringLiteral("rowCount"), rowCount);
    resultRoot.insert(QStringLiteral("rows"), jsonRowsArray);

    // Конвертуємо зібране дерево у компактний JSON-рядок без зайвих пробілів
    QJsonDocument doc(resultRoot);
    return QString::fromUtf8(doc.toJson(QJsonDocument::Compact));
}

/*
QString DbDriver4::dbSelectRows(const QString & sql, const QString & filter)
{
    // qDebug()<<"DbDriver4::dbSelectRows \n"<<sql;
    QString str = "";
    QString row = "";
    int errId = 0;
    QString errText = "";
    int rowCount = 0;
    //    QString errStr = "";
    if (openConnection()) {
        QSqlQuery q = QSqlQuery(sql,m_db);
        int r =0; int i =0;
        if (!q.lastError().isValid()){
            while (q.next()) {
                ++rowCount;
                row = "";
                for (r =0; r < q.record().count(); ++r ) {
                    if (filter.isEmpty()
                        || q.value(r).toString().toLower().contains(filter.toLower())){
                        for (i =0; i < q.record().count(); ++i ) {
                            row += (row.isEmpty()?"":",")+QString("\"%1\":\"%2\"")
                                                                    .arg(q.record().fieldName(i),
                                                                    q.value(i).toString().replace(QChar::Tabulation, QChar::Space).replace(QChar::LineFeed, QChar::Space).replace(QChar::CarriageReturn, QChar::Space).replace("\\", "/").replace("\"", "'"));
                        }
                        str += (str.isEmpty()?"{":",\n{") + row + "}";
                        break;
                    }

                }
            }

        } else {
            errId = q.lastError().type();
            errText = q.lastError().text();

        }
        closeConnection();
    } else {
        errId = 1;
        errText = "DB connection error.";
    }
    str = str.trimmed();
    return QString("{\"errorId\":%1,\"errorText\":\"%2\",\"rowCount\":%3,\"rows\":[%4]}").arg(errId).arg(errText).arg(rowCount).arg(str);

}
*/

/**
 * @brief DbDriver3::acntId
 * @param bal
 * @param article
 * @param col: 1-account id, 2- account eq id, 3-account result id
 * @param openIfMissing
 * @return
 */
/*int DbDriver4::acntId(const QString & acnt, const QString & article, int col, bool openIfMissing)
{
    enum EAcntQuery { qAcntNo, qAcntBal, qAcntName, qAcntMask, qAcntTrade, qAcntClnt };
    // qDebug()<<"DbDriver3::acntId STARTED "<< " acnt="<<acnt<< " article="<<article<< " col="<<col<< " openIfMissing="<<openIfMissing;
    QString akey = QString("acnt/%1/%2").arg(acnt).arg(article);
    if (m_hash.contains(akey)) {return m_hash.get(akey,col).toInt();}
    if (!openConnection()) {
        return 0;
    }

    load("acnt/",
         "select acnt.acntno||'/'||coalesce(item,''), id, coalesce(eqid,0), coalesce(rsltid,0) from acnt left join acntrade on(id=pkey)",
         QString(" acnt.acntno = '%1' and item %2").arg(acnt).arg(article.isEmpty() ? QString("is null") : QString("= '%1'").arg(article))
         );
    if (m_hash.contains(akey)) {
        // qDebug()<<"DbDriver3::acntId STARTED "<< " acnt="<<acnt<< " article="<<article<< " col="<<col<< " openIfMissing="<<openIfMissing<< " id="<<m_hash.get(akey,col).toInt();;
        return m_hash.get(akey,col).toInt();
    }
    // open new acnt
    int res = 0;
    QString qerror= QString("EE:DbDriver3::acntId acnt=%1 article=%2 col=%3 openIfMissing=%4").arg(acnt, article).arg(col).arg(openIfMissing?"1":"0");
    QString balAcntPrefix = "balAcnt/";
    // qDebug()<<"DbDriver3::acntId OPEN "<< " acnt="<<acnt<< " article="<<article<< " col="<<col<< " openIfMissing="<<openIfMissing;
    // qDebug()<<"DbDriver3::acntId OPEN "<< " m_balAcntPrefix+acnt="<<balAcntPrefix+acnt;
    if ((col == 1) && (openIfMissing)) {

        load(balAcntPrefix,
             QString("select acntno, coalesce(balname, ''), coalesce(acntnote,balname,'N/A'), mask, coalesce(balname.trade,0), coalesce(client,'') from acntbal left join balname on (substr(acntno,1,2)=bal) "),
             QString("acntno = '%1'").arg(acnt));
        QSqlQuery q = QSqlQuery(m_db);
        if (m_hash.contains(balAcntPrefix+acnt)) {
            if (m_hash.get(balAcntPrefix+acnt, qAcntTrade).toInt()) {  // is trade account
                q = QSqlQuery(QString("insert into acntrade (pkey, acntno, article) values ((select max(id)+1 from acnt), '%1', '%2')")
                                  .arg(acnt).arg(article), m_db);
                //                qDebug("inserted trade");
            } else {
                q = QSqlQuery(QString("insert into acnt (acntno, item) values ('%1', %2)")
                                  .arg(acnt).arg(article.isEmpty() ? QString("null") : QString("'%1'").arg(article)), m_db);
                //                qDebug("inserted NOT trade");
            }
            if (!q.isActive()) {
                qerror +=QString("\n%1\n%2").arg(q.lastQuery()).arg(q.lastError().text());
            }

        } else {
            qerror +=QString("\nbal account missing balacnt=(%1)").arg(balAcntPrefix+acnt);
        }

    }
    //    qDebug("VkCheckEditor::acntId BEFORE");
    //    m_hash.printHash4test("acnt/");
    load("acnt/",
         "select acnt.acntno||'/'||coalesce(item,''), id, coalesce(eqid,0), coalesce(rsltid,0) from acnt left join acntrade on(id=pkey)",
         QString(" acnt.acntno = '%1' and item %2").arg(acnt).arg(article.isEmpty() ? QString("is null") : QString("= '%1'").arg(article))
         );
    closeConnection();
    //    qDebug("VkCheckEditor::acntId AFTER");
    //    m_hash.printHash4test("acnt/");
    res = m_hash.get(akey,col).toInt();
    if (!res) {
        m_lastError = qerror;
        qDebug()<<m_lastError;
        //        emit error(m_lastError);
    }
    return res;
} */
