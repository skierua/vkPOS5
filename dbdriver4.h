#ifndef DBDRIVER4_H
#define DBDRIVER4_H

#include <QObject>
#include <QDir>
#include <QQmlEngine>
// #include <QMap>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlRecord>
#include <QSqlError>
#include <QVariantMap>

#include <QDebug>

// singletone !!!

class DbDriver4 : public QObject
{
    Q_OBJECT
    QML_SINGLETON
    QML_ELEMENT

public:
    DbDriver4(QObject *parent = nullptr);

    ~DbDriver4() = default;

    Q_INVOKABLE void msg(const QString &m =QString()) const {
        qDebug()<<"DbDriver4 msg started." << m;
    }

    Q_INVOKABLE static QStringList dirEntryList(const QString & path, const QStringList & nameFilters, int typeFilter = QDir::Dirs|QDir::Files,  int sort = QDir::NoSort)
    { return QDir(path).entryList(nameFilters,QDir::Filters(typeFilter),QDir::SortFlags(sort));}

    Q_INVOKABLE void setDbParameter(const QString &name, const QString &type = "QSQLITE", const QString &conn = "");

    Q_INVOKABLE bool closeShift(const QString shftid);

    Q_INVOKABLE int dbInsert(const QString &sql);

    Q_INVOKABLE bool dbUpdate(const QString &sql);

    Q_INVOKABLE bool dbDelete(const QString &sql);

    Q_INVOKABLE QString dbLastError() const { return m_lastError; }

    // temporary transitional
    Q_INVOKABLE QVariantMap getJSONRowFromSQL(const QString & sql) { return dbSelectRow(sql);}

    Q_INVOKABLE QVariantMap dbSelectRow(const QString &sql);

    // temporary transitional
    Q_INVOKABLE QString getJSONRowsFromSQL_2(const QString & sql, const QString &filter= QString()) { return dbSelectRows(sql, filter);}

    Q_INVOKABLE QString dbSelectRows(const QString &sql, const QString &filter =QString());

    // Q_INVOKABLE int acntId(const QString & acnt, const QString & article, int col, bool openIfMissing);

signals:
    void vkEvent(QString eventId, QVariant eventParam);
    void error(QString message);

private:
    // static DbDriver4 * instance;

    // DbDriver4() = default;
    DbDriver4(const DbDriver4&)= delete;
    DbDriver4& operator=(const DbDriver4&)= delete;

    QSqlDatabase m_db;
    // QString m_conn;
    QString m_lastError;
    QString m_driver{"QSQLITE"};

    int m_cc{0};   // connectionCounter;
    // int m_status;   //driver status 0-empty, 1-ok, 2-data loading, 3-error
    QString m_dbVersion;

    bool openConnection();

    void closeConnection();

};
#endif // DBDRIVER4_H
