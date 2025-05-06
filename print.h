#ifndef PRINT_H
#define PRINT_H

#include <QObject>
#include <QQmlEngine>
#include <QJsonArray>
#include <QJsonObject>
#include <QPrinter>
#include <QPainter>

class Print : public QObject
{
    Q_OBJECT
    QML_ELEMENT

public:
    explicit Print(QObject *parent = nullptr);

    Q_INVOKABLE int printCheck(const QJsonObject &bind) { return paintCheck(bind, 1, 0);}
    Q_INVOKABLE int saveCheck(const QJsonObject &bind) { return paintCheck(bind, 0, 0);}
    Q_INVOKABLE int printCheckCopy(const QJsonObject &bind) { return paintCheck(bind, 1, 1);}
    Q_INVOKABLE int saveCheckCopy(const QJsonObject &bind) { return paintCheck(bind, 0, 1);}

    Q_INVOKABLE int saveOrder(const QJsonObject &bind);

    Q_INVOKABLE void setTerm(const QString &v) { m_termCode = v; }
    Q_INVOKABLE void setAddress(const QString & v) { m_termAddress = v; }
    Q_INVOKABLE void setUser(const QString & v) { m_termUser = v; }
    Q_INVOKABLE void setCheck(const QString & v) { m_check = v; }

private:
    QString m_termCode{"TEST"};

    QString m_termAddress{""};

    QString m_termUser{""};

    QString m_check{"check"};

    QLatin1StringView m_checkPrinter{"POSPrn"};

    QLatin1StringView m_checkFile{"report/lastcheck.pdf"};

    QLatin1StringView m_orderFile{"report/order.pdf"};

    int paintCheck(const QJsonObject &bind, int mode =1, int copy =0);

signals:
};

#endif // PRINT_H
