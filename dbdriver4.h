#ifndef DBDRIVER4_H
#define DBDRIVER4_H

#include <QObject>
#include <QDir>
#include <QQmlEngine>
#include <QSqlDatabase>
#include <QVariantMap>
#include <QVariantList>
#include <QStringList>

class DbDriver4 : public QObject
{
    Q_OBJECT
    QML_NAMED_ELEMENT(Db)
    QML_SINGLETON

public:
    explicit DbDriver4(QObject *parent = nullptr);
    ~DbDriver4() override = default;

    // Конструктори копіювання видаляємо через modern C++ style
    DbDriver4(const DbDriver4&) = delete;
    DbDriver4& operator=(const DbDriver4&) = delete;
    DbDriver4(DbDriver4&&) = delete;
    DbDriver4& operator=(DbDriver4&&) = delete;

    Q_INVOKABLE bool dbTransaction() { return m_db.transaction(); }
    Q_INVOKABLE bool dbCommit() { return m_db.commit(); }
    Q_INVOKABLE bool dbRollback() { return m_db.rollback(); }
    // Q_INVOKABLE void msg(const QString &m = QString()) const {
    //     qDebug() << "DbDriver4 моніторинг діяльності: " << m;
    // }

    // Утиліта для читання директорій, адаптована під прапорці Qt6
    Q_INVOKABLE static QStringList dirEntryList(const QString &path, const QStringList &nameFilters,
                                                int typeFilter = QDir::Dirs | QDir::Files,
                                                int sort = QDir::NoSort) {
        return QDir(path).entryList(nameFilters, QDir::Filters(typeFilter), QDir::SortFlags(sort));
    }

    Q_INVOKABLE bool setDbParameter(const QString &name, const QString &type = QStringLiteral("QSQLITE"), const QString &conn = QString());

    // Чисті бізнес-методи каси (Ідеальний підхід: QML каже ЩО зробити, а C++ знає ЯК зробити це безпечно)
    Q_INVOKABLE bool closeShift(const QString &shftid);

    // Безпечні методи для виконання сирих SQL, якщо вони критично потрібні для старих JS файлів
    // Старий метод (для зворотної сумісності)
    Q_INVOKABLE int dbInsert(const QString &sql);
    // НОВИЙ МЕТОД з підтримкою параметрів
    Q_INVOKABLE int dbInsert(const QString &sql, const QVariantList &params);

    Q_INVOKABLE bool dbUpdate(const QString &sql);
    Q_INVOKABLE bool dbUpdate(const QString &sql, const QVariantMap &params);
    // deprecated
    Q_INVOKABLE bool dbUpdateParams(const QString &sql, const QVariantMap &params);

    Q_INVOKABLE bool dbDelete(const QString &sql);

    Q_INVOKABLE QString dbLastError() const { return m_lastError; }

    // Старий метод (залишається для сумісності)
    Q_INVOKABLE QVariantMap dbSelectRow(const QString &sql);
    // НОВИЙ МЕТОД з підтримкою параметрів
    Q_INVOKABLE QVariantMap dbSelectRow(const QString &sql, const QVariantList &params);
    Q_INVOKABLE QVariantMap getJSONRowFromSQL(const QString &sql) { return dbSelectRow(sql); } // Транзитний fallback

    // ✅ ОПТИМІЗАЦІЯ QT6: Замість повернення важкого рядка JSON (QString),
    // ми повертаємо QVariantList. Рушій QML бачить його відразу як готовий масив JS-об'єктів [].
    // Це прискорить роботу таблиць каси у десятки разів і зменшить навантаження на процесор!
    Q_INVOKABLE QString dbSelectRows(const QString &sql, const QString &filter = QString());
    Q_INVOKABLE QString getJSONRowsFromSQL_2(const QString &sql, const QString &filter = QString())
         { return dbSelectRows(sql, filter); }
    Q_INVOKABLE QVariantList dbSelectRowsJSON(const QString &sql, const QString &filter = QString());

signals:
    void vkEvent(QString eventId, QVariant eventParam);
    void error(QString message);

private:
    QSqlDatabase m_db;
    QString m_lastError;
    QString m_driver{QStringLiteral("QSQLITE")};
    int m_cc{0}; // Лічильник активних підключень (connectionCounter)
    // QString m_dbVersion;

    bool openConnection();
    void closeConnection();
};

#endif // DBDRIVER4_H
