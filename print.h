#ifndef PRINT_H
#define PRINT_H

#include <QObject>
#include <QCoreApplication>
#include <QQmlEngine>
#include <QJsonObject>

class Print : public QObject
{
    Q_OBJECT
    // QML_ELEMENT
    QML_NAMED_ELEMENT(Prn)
    QML_SINGLETON

public:
    explicit Print(QObject *parent = nullptr);
    ~Print() override = default; // Хороша практика для Qt6 синглтонів

    // Конструктори копіювання видаляємо через modern C++ style
    Print(const Print&) = delete;
    Print& operator=(const Print&) = delete;
    Print(Print&&) = delete;
    Print& operator=(Print&&) = delete;

    Q_INVOKABLE int printCheck(const QJsonObject &bind) { return paintCheck(bind, 1, 0);}
    Q_INVOKABLE int saveCheck(const QJsonObject &bind) { return paintCheck(bind, 0, 0);}
    Q_INVOKABLE int printCheckCopy(const QJsonObject &bind) { return paintCheck(bind, 1, 1);}
    Q_INVOKABLE int saveCheckCopy(const QJsonObject &bind) { return paintCheck(bind, 0, 1);}

    Q_INVOKABLE int saveOrder(const QJsonObject &bind);

    Q_INVOKABLE void setTerm(const QString &v) { m_termCode = v; }
    Q_INVOKABLE void setAddress(const QString & v) { m_termAddress = v; }
    Q_INVOKABLE void setUser(const QString & v) { m_termUser = v; }
    Q_INVOKABLE void setCheck(const QString & v) { m_check = v; }
    Q_INVOKABLE void setPrinterName(const QString &v) { m_checkPrinter = v; } // Додано сетер для зміни принтера з налаштувань QML

private:
    QString m_termCode{"TEST"};

    QString m_termAddress{""};

    QString m_termUser{""};

    QString m_check{"check"};

    QString m_checkPrinter{"POSPrn"};

    // QLatin1StringView m_checkFile{ "report/lastcheck.pdf"};

    // QLatin1StringView m_orderFile{"report/order.pdf"};

    // Статичні суфікси шляхів (будуть збиратися в абсолютні шляхи всередині .cpp файлу)
    const QString m_checkSubPath{"report/lastcheck.pdf"};
    const QString m_orderSubPath{"report/order.pdf"};

    int saveOrder_old(const QJsonObject &bind);

    // Головна функція рендеру (макетування) чека
    int paintCheck(const QJsonObject &bind, int mode = 1, int copy = 0);
    int paintCheck_old(const QJsonObject &bind, int mode = 1, int copy = 0);

    // Повертає абсолютний безпечний шлях до файлу звіту у папці додатку
    QString getAbsoluteReportPath(const QString &subPath) const;

signals:
};

#endif // PRINT_H
