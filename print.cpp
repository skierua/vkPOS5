#include "print.h"
#include <QDir>
#include <QJsonArray>
#include <QPrinter>
#include <QPainter>


Print::Print(QObject *parent)
    : QObject{parent}
{}

QString Print::getAbsoluteReportPath(const QString &subPath) const {
    const QString baseDir = QCoreApplication::applicationDirPath();

    // Створюємо папку report, якщо її ще немає на диску поруч із бінарником
    QDir().mkpath(baseDir + QStringLiteral("/report"));

    return QDir::cleanPath(baseDir + QStringLiteral("/") + subPath);
}

int Print::paintCheck(const QJsonObject &bind, int mode, int isCopy)
{
    QPrinter printer;
/*
    qDebug() << "II: print.cpp/paintCheck bind=" << bind;
    // qDebug() << "II: print.cpp/paintCheck prn=" <<  m_checkPrinter << " mode=" <<  mode << " isCopy=" << isCopy;

    const QJsonArray test_dcmsArray = bind.value(QStringLiteral("dcms")).toArray();
    for (const QJsonValue &v_dcm_val : test_dcmsArray) {
        QJsonObject v_dcm = v_dcm_val.toObject();
        QJsonValue v_item = v_dcm[QStringLiteral("jitem")];

        double am = v_dcm[QStringLiteral("amnt")].toString().toDouble();
        double eq = v_dcm[QStringLiteral("eq")].toString().toDouble();
        double ds = v_dcm[QStringLiteral("dsc")].toString().toDouble();
        double qty = v_item[QStringLiteral("qty")].toDouble();

        QString noteStr = v_dcm[QStringLiteral("note")].toString().trimmed();
        QString inoteStr = noteStr.indexOf(QStringLiteral("#")) < 0 ? QString() : noteStr.right(noteStr.indexOf(QStringLiteral("#")));
        QString dcmType = v_dcm[QStringLiteral("dcm")].toString();
        int mask = v_item[QStringLiteral("mask")].toInt();
        int prec = v_item[QStringLiteral("unitprec")].toInt();

        QString isTrade = dcmType.startsWith("trade:") ? "YES" : "NO";
        QString cleanNote = noteStr.left(noteStr.indexOf(QStringLiteral("#")));
        QString iidStr = (mask == 2) ? (QStringLiteral(" #") + v_dcm[QStringLiteral("crn")].toString()) : QString();
        QString priceStr = QStringLiteral("0.00");
        if (am != 0.0) {
            priceStr = QString::number(qty * (eq + ds) / am, 'f', 2);
        }

        QString qtySuffix = (qty == 1.0) ? QString() : QStringLiteral("/%1").arg(qty);
        QString icharStr = v_item[QStringLiteral("itemchar")].toString();
        // qDebug() << "v_item: " << v_item ;
        qDebug() << am << eq << ds << qty << noteStr << inoteStr << dcmType << mask << prec
                 << isTrade << cleanNote << iidStr << priceStr << qtySuffix << icharStr;
    }
    double _totalEq = bind.value(QStringLiteral("eq")).toString().toDouble();
    double _totalDsc = bind.value(QStringLiteral("dsc")).toString().toDouble();
    double _totalAmount = bind.value(QStringLiteral("amnt")).toString().toDouble();
    qDebug() << _totalEq << _totalDsc << _totalAmount ;
    qDebug() << "II: print.cpp/paintCheck FINISH";


    return 1;
*/
    if (mode) {
        // Друк на фізичний термопринтер каси
        printer.setPrinterName(m_checkPrinter);
    } else {
        printer.setOutputFileName(getAbsoluteReportPath(m_checkSubPath));
    }

    QPainter painter;

    if (!painter.begin(&printer)) {
        qWarning("Не вдалося відкрити QPainter. Перевірте права доступу або підключення принтера.");
        return 1;
    }

    int yoffset = 0;
    QString fontFamily = QStringLiteral("Arial");
    int fontStretch = 70;
    int fontSize = 10;

    QFont f = painter.font();
    f.setFamily(fontFamily);
    f.setPointSize(12);
    painter.setFont(f);

    // Завантаження логотипу із папки додатку
    QPixmap pxm(QStringLiteral("./logo.png"));
    if (!pxm.isNull()) {
        painter.drawPixmap(QPointF(0, yoffset), pxm);
        yoffset += 35;
    }

    QString checkTitle = QStringLiteral("Чек")
                         + (m_check == QStringLiteral("check") ? QString() : QStringLiteral(" - попередня"))
                         + (isCopy ? QStringLiteral(" (копія)") : QString());

    painter.drawText(QRect(0, yoffset, 170, 20), Qt::AlignHCenter | Qt::AlignVCenter, checkTitle);

    f.setPointSize(fontSize);
    f.setStretch(fontStretch);
    painter.setFont(f);

    painter.drawText(QRect(0, yoffset += 20, 170, 14), tr("Name") + QStringLiteral(": ") + m_termCode);
    painter.drawText(QRect(0, yoffset += 14, 170, 14), tr("Address") + QStringLiteral(": ") + m_termAddress);

    // Шапка таблиці чека
    painter.drawText(QRect(0, yoffset += 16, 140, 14), tr("Артикул"));
    painter.drawText(QRect(0, yoffset += 14, 35, 14), Qt::AlignHCenter, tr("К-сть"));
    painter.drawText(QRect(35, yoffset, 45, 14), Qt::AlignHCenter, tr("Ціна"));
    painter.drawText(QRect(80, yoffset, 55, 14), Qt::AlignHCenter, tr("Сума"));
    painter.drawText(QRect(135, yoffset, 35, 14), Qt::AlignHCenter, tr("Знж"));

    yoffset += 16;

    // ОПТИМІЗАЦІЯ QT6: Витягуємо масив один раз (захист від накладних витрат пам'яті)
    const QJsonArray dcmsArray = bind.value(QStringLiteral("dcms")).toArray();

    for (const QJsonValue &v_dcm_val : dcmsArray) {
        QJsonObject v_dcm = v_dcm_val.toObject();
        QJsonValue v_item = v_dcm[QStringLiteral("jitem")];

        double am = v_dcm[QStringLiteral("amnt")].toString().toDouble();
        double eq = v_dcm[QStringLiteral("eq")].toString().toDouble();
        double ds = v_dcm[QStringLiteral("dsc")].toString().toDouble();
        double qty = v_item[QStringLiteral("qty")].toDouble();

        QString noteStr = v_dcm[QStringLiteral("note")].toString().trimmed();
        QString inoteStr = noteStr.indexOf(QStringLiteral("#")) < 0 ? QString() : noteStr.right(noteStr.indexOf(QStringLiteral("#")));
        QString dcmType = v_dcm[QStringLiteral("dcm")].toString();
        int mask = v_item[QStringLiteral("mask")].toInt();
        int prec = v_item[QStringLiteral("unitprec")].toInt();

        if (dcmType.startsWith("trade:")) {
            QString cleanNote = noteStr.left(noteStr.indexOf(QStringLiteral("#")));
            QString iidStr = (mask == 2) ? (QStringLiteral(" #") + v_dcm[QStringLiteral("crn")].toString()) : QString();

            painter.drawText(QRect(0, yoffset, 160, 14), (am > 0 ? QStringLiteral("+ ") : QStringLiteral("- ")) + cleanNote + iidStr);
            yoffset += 14;

            painter.drawText(QRect(0, yoffset, 35, 14), Qt::AlignRight, QLocale::system().toString(qAbs(am), 'f', prec));

            // ЗАХИСТ ВІД ДІЛЕННЯ НА НУЛЬ: Якщо am == 0, ставимо ціну 0.00
            QString priceStr = QStringLiteral("0.00");
            if (am != 0.0) {
                priceStr = QString::number(qty * (eq) / am, 'f', 2);
                // priceStr = QString::number(qty * (eq + ds) / am, 'f', 2);
            }

            QString qtySuffix = (qty == 1.0) ? QString() : QStringLiteral("/%1").arg(qty);
            painter.drawText(QRect(35, yoffset, 45, 14), Qt::AlignRight, priceStr + qtySuffix);

            painter.drawText(QRect(80, yoffset, 55, 14), Qt::AlignRight, QLocale::system().toString(qAbs(eq), 'f', 2));
            painter.drawText(QRect(135, yoffset, 35, 14), Qt::AlignRight, QLocale::system().toString(qAbs(ds), 'f', 2));

            if (noteStr.contains(QStringLiteral("#"))) {
                painter.drawText(QRect(0, yoffset += 14, 150, 14), inoteStr.mid(inoteStr.indexOf(QStringLiteral("#")) + 1));
            }
        } else {
            // Касові ордери (Внесення / Вилучення)
            QString icharStr = v_item[QStringLiteral("itemchar")].toString();
            QString iidStr = (mask == 2) ? (QStringLiteral(" #") + v_dcm[QStringLiteral("crn")].toString()) : QString();

            painter.drawText(QRect(0, yoffset, 160, 14), (am > 0 ? QStringLiteral("+Отр ") : QStringLiteral("-Вид ")) + icharStr + inoteStr + iidStr);
            yoffset += 14;

            painter.drawText(QRect(0, yoffset, 55, 14), Qt::AlignRight, QLocale::system().toString(qAbs(am), 'f', prec));
            painter.drawText(QRect(60, yoffset, 110, 14), noteStr);
        }

        yoffset += 16;
    }

    // Підсумковий блок чека
    painter.drawText(QRect(0, yoffset, 170, 12), QStringLiteral("--------------------------------------------------------------------------"));
    painter.drawText(QRect(0, yoffset += 14, 60, 14), tr("Всього:"));

    double totalEq = bind.value(QStringLiteral("eq")).toString().toDouble();
    double totalDsc = bind.value(QStringLiteral("dsc")).toString().toDouble();
    double totalAmount = bind.value(QStringLiteral("amnt")).toString().toDouble();

    painter.drawText(QRect(55, yoffset, 80, 14), Qt::AlignRight, QLocale::system().toString(qAbs(totalEq), 'f', 2));
    painter.drawText(QRect(135, yoffset, 35, 14), Qt::AlignRight, QLocale::system().toString(qAbs(totalEq), 'f', 2));

    painter.drawText(QRect(0, yoffset += 8, 170, 12), QStringLiteral("--------------------------------------------------------------------------"));

    f.setPointSize(11);
    f.setStretch(100);
    painter.setFont(f);

    painter.drawText(QRect(0, yoffset += 10, 50, 30), Qt::AlignLeft | Qt::AlignVCenter, ((totalEq + totalDsc) < 0 ? QStringLiteral("+") : QStringLiteral("-")) + tr("Сума"));

    f.setBold(true);
    f.setPointSize((qAbs(totalEq + totalDsc) < 1000000.0) ? 14 : 13);
    painter.setFont(f);

    painter.drawText(QRect(50, yoffset, 120, 30), Qt::AlignRight | Qt::AlignVCenter, QLocale::system().toString(qAbs(totalEq + totalDsc), 'f', 2));

    f.setBold(false);
    f.setStretch(fontStretch);
    f.setPointSize(fontSize);
    painter.setFont(f);

    painter.drawText(QRect(0, yoffset += 25, 75, 14), (totalAmount >= 0 ? QStringLiteral("+") : QStringLiteral("-")) + tr(" Готівка:"));
    painter.drawText(QRect(80, yoffset, 90, 14), Qt::AlignRight, QLocale::system().toString(qAbs(totalAmount), 'f', 2));

    // Підвал чека (Метадані)
    painter.drawText(QRect(0, yoffset += 25, 100, 14), tr("Id:") + bind.value(QStringLiteral("id")).toString().rightJustified(6, '0'));
    painter.drawText(QRect(0, yoffset += 14, 150, 14), tr("TermId: ") + m_termCode + QStringLiteral(" ( ") + m_termUser + QStringLiteral(" )"));
    painter.drawText(QRect(0, yoffset += 14, 150, 14), tr("Time: ") + bind.value(QStringLiteral("dcmtime")).toString().left(16));

    f.setPointSize(12);
    painter.setFont(f);
    painter.drawText(QRect(0, yoffset += 18, 150, 20), Qt::AlignHCenter, tr("Дякуємо за співпрацю !"));

    painter.end();
    return 0;
}

int Print::saveOrder(const QJsonObject &bind)
{
    QLocale locale = QLocale::system();
    QPrinter printer;

    printer.setOutputFileName(getAbsoluteReportPath(m_orderSubPath));

    QPainter painter;
    if (!painter.begin(&printer)) {
        // Лог помилки тепер використовує безпечний метод збірки шляху
        qDebug() << QStringLiteral("Print::saveOrder err: ") << getAbsoluteReportPath(m_orderSubPath);
        qWarning("Не вдалося відкрити QPainter для запису накладної. Перевірте права доступу папки.");
        return 1;
    }

    QPen pen;
    pen.setWidthF(1.5);
    painter.setPen(pen);

    double price = 0;
    int lmrg = 50;     // лівий відступ
    int xofs = lmrg;
    int yoffset = 20;
    int ylt = 0;       // y лівого верхнього кута таблиці
    int tblw = 680;    // загальна ширина таблиці
    int tbrlh = 20;    // висота рядка

    int wid = 24;
    int war = 50;
    int wam = 40;
    int wun = 30;
    int wpr = 60;
    int weq = 80;
    int wsps = 4;       // інтервал між колонками
    int wnm = tblw - wid - war - wun - wam - wpr - weq - 6 * wsps;

    QString fontFamily = QStringLiteral("Arial");
    int fontSize = 10;

    QFont f = painter.font();
    f.setFamily(fontFamily);
    f.setPointSize(12);
    f.setBold(true);
    painter.setFont(f);

    painter.drawText(QRect(xofs, yoffset, tblw, 20), Qt::AlignHCenter | Qt::AlignVCenter,
                     QStringLiteral("Видаткова накладна №___________ від __________________"));

    yoffset += 30;
    f.setPointSize(fontSize);
    f.setBold(false);
    painter.setFont(f);

    // Блок контрагентів
    painter.drawText(QRect(xofs, yoffset, 2 * war, 14), QStringLiteral("Постачальник:")); yoffset += 14;
    painter.drawLine(xofs + 2 * war, yoffset, xofs + tblw, yoffset); yoffset += 25;
    painter.drawLine(xofs + 2 * war, yoffset, xofs + tblw, yoffset); yoffset += 18;

    painter.drawText(QRect(xofs, yoffset, 2 * war, 14), QStringLiteral("Покупець: ")); yoffset += 14;
    painter.drawLine(xofs + 2 * war, yoffset, xofs + tblw, yoffset); yoffset += 25;
    painter.drawLine(xofs + 2 * war, yoffset, xofs + tblw, yoffset); yoffset += 25;

    ylt = yoffset;

    // Шапка таблиці накладної
    painter.drawText(QRect(xofs, yoffset, wid, 24), Qt::AlignHCenter | Qt::AlignVCenter, QStringLiteral("No")); xofs += wid + wsps;
    painter.drawText(QRect(xofs, yoffset, war, 24), Qt::AlignHCenter | Qt::AlignVCenter, QStringLiteral("Арт")); xofs += war + wsps;
    painter.drawText(QRect(xofs, yoffset, wnm, 24), Qt::AlignVCenter, QStringLiteral("Назва")); xofs += wnm + wsps;
    painter.drawText(QRect(xofs, yoffset, wam, 24), Qt::AlignHCenter | Qt::AlignVCenter, QStringLiteral("К-сть")); xofs += wam + wsps;
    painter.drawText(QRect(xofs, yoffset, wun, 24), Qt::AlignHCenter | Qt::AlignVCenter, QStringLiteral("Од")); xofs += wun + wsps;
    painter.drawText(QRect(xofs, yoffset, wpr, 24), Qt::AlignHCenter | Qt::AlignVCenter, QStringLiteral("Ціна")); xofs += wpr + wsps;
    painter.drawText(QRect(xofs, yoffset, weq, 24), Qt::AlignHCenter | Qt::AlignVCenter, QStringLiteral("Сума"));

    yoffset += 24;
    xofs = lmrg;

    pen.setWidthF(2);
    painter.setPen(pen);
    painter.drawLine(xofs, yoffset, xofs + tblw, yoffset);

    pen.setWidthF(1);
    painter.setPen(pen);
    yoffset += 4;

    // ОПТИМІЗАЦІЯ QT6: Витягуємо масив документів один раз (економія RAM)
    const QJsonArray dcmsArray = bind.value(QStringLiteral("dcms")).toArray();
    int i = 0;

    for (const QJsonValue &v_dcm_val : dcmsArray) {
        QJsonObject v_dcm = v_dcm_val.toObject();

        double amount_val = v_dcm[QStringLiteral("amount")].toString().toDouble();
        double eq_val = v_dcm[QStringLiteral("eq")].toString().toDouble();
        int prec_val = v_dcm[QStringLiteral("prec")].toString().toInt();

        price = 0.0;
        if (amount_val != 0.0) {
            price = eq_val / amount_val;
        }

        painter.drawText(QRect(xofs, yoffset, wid, tbrlh), Qt::AlignRight | Qt::AlignVCenter, QString::number(i + 1)); xofs += wid + wsps;
        painter.drawText(QRect(xofs, yoffset, war, tbrlh), Qt::AlignHCenter | Qt::AlignVCenter, v_dcm[QStringLiteral("iid")].toString()); xofs += war + wsps;
        painter.drawText(QRect(xofs, yoffset, wnm, tbrlh), Qt::AlignVCenter, v_dcm[QStringLiteral("ichar")].toString()); xofs += wnm + wsps;
        painter.drawText(QRect(xofs, yoffset, wam, tbrlh), Qt::AlignRight | Qt::AlignVCenter, locale.toString(amount_val, 'f', prec_val)); xofs += wam + wsps;
        painter.drawText(QRect(xofs, yoffset, wun, tbrlh), Qt::AlignHCenter | Qt::AlignVCenter, v_dcm[QStringLiteral("uchar")].toString()); xofs += wun + wsps;
        painter.drawText(QRect(xofs, yoffset, wpr, tbrlh), Qt::AlignRight | Qt::AlignVCenter, locale.toString(price, 'f', price < 10 ? 3 : (price < 100 ? 2 : 1))); xofs += wpr + wsps;
        painter.drawText(QRect(xofs, yoffset, weq, tbrlh), Qt::AlignRight | Qt::AlignVCenter, locale.toString(eq_val, 'f', 2));

        xofs = lmrg;
        yoffset += tbrlh + 2;
        painter.drawLine(xofs, yoffset, xofs + tblw + wsps, yoffset);

        i++;
    }

    // Малювання вертикальних ліній сітки накладної
    pen.setWidthF(2);
    painter.setPen(pen);
    painter.drawRect(xofs, ylt, tblw + wsps, yoffset - ylt); xofs += wid + wsps / 2;
    painter.drawLine(xofs, ylt, xofs, yoffset); xofs += war + wsps;
    painter.drawLine(xofs, ylt, xofs, yoffset); xofs += wnm + wsps;
    painter.drawLine(xofs, ylt, xofs, yoffset); xofs += wam + wsps;
    painter.drawLine(xofs, ylt, xofs, yoffset); xofs += wun + wsps;
    painter.drawLine(xofs, ylt, xofs, yoffset); xofs += wpr + wsps;
    painter.drawLine(xofs, ylt, xofs, yoffset);

    // Нижній блок підсумків
    xofs = lmrg + tblw - 250;
    pen.setWidthF(1.5);
    painter.setPen(pen);
    f.setPointSize(12);
    f.setStretch(100);
    painter.setFont(f);

    painter.drawText(QRect(xofs, yoffset, 70, 30), Qt::AlignLeft | Qt::AlignVCenter, tr("Разом:")); xofs += 102;

    f.setBold(true);
    f.setPointSize(14);
    painter.setFont(f);

    double bindEq = bind.value(QStringLiteral("eq")).toDouble();
    painter.drawText(QRect(xofs, yoffset, 140, 30), Qt::AlignRight | Qt::AlignVCenter, locale.toString(qAbs(bindEq), 'f', 2));

    f.setBold(false);
    xofs = lmrg;
    f.setPointSize(12);
    painter.setFont(f);
    yoffset += 30;

    painter.drawText(QRect(xofs, yoffset, tblw, 24),
                     tr("Всього найменувань %1 на суму %2 грн.")
                         .arg(QString::number(dcmsArray.size()), locale.toString(qAbs(bindEq), 'f', 2)));

    yoffset += 45;
    painter.drawLine(xofs, yoffset, xofs + tblw, yoffset);

    yoffset += 30;
    f.setPointSize(fontSize);
    painter.setFont(f);

    // Підписи сторін
    painter.drawText(QRect(xofs, yoffset, tblw / 2, 18), tr("Відвантажив(ла):__________________________"));
    painter.drawText(QRect(xofs + tblw / 2, yoffset, tblw / 2, 18), tr("Отримав(ла):_______________________________"));

    painter.end();
    return 0;
}

// qDebug()<<"Print::printCheck STARTED id="
//          << " cash=" << bind.value("amount")
//          << " dcms len=" << (bind.value("dcms").toArray()).size()
//          << " dcms t=" << (bind.value("dcms")[0]["inote"])
//          << " dcms=" << bind.value("dcms");  //.toVariantMap();
// QString msg = QString("Print::printCheck STARTED id=0 filePath=%1\n").arg(filePath);
//    QString v_term = QString("");   //q.value(2).toString().left(16);

/**
 * @brief Print::printCheck
 * @param bind
 * @param mode 1-print, 0-file
 * @param isCopy 0|1
 * @return
 */
int Print::paintCheck_old(const QJsonObject & bind, int mode, int isCopy)
{
    QPrinter printer;

    if (mode){ printer.setPrinterName(m_checkPrinter); }
    else { printer.setOutputFileName(QCoreApplication::applicationDirPath() + "/report/lastcheck.pdf"); }

    QPainter painter;

    if (! painter.begin(&printer)) { // failed to open painter
        qWarning("failed to open file, is it writable?");
        return 1;
    }
    int yoffset = 0;
    //    painter.drawText(0, 0, "0123456789012345678901234567890123456789");
    QString fontFamily = "Arial";
    //    int fontStretch = 62;
    int fontStretch = 70;
    int fontSize = 10;
    QFont f = painter.font();
    f.setFamily(fontFamily);
    f.setPointSize(12);
    painter.setFont(f);
    //    painter.drawText(0, yoffset+=20, "0123456789012345678901234567890123456789");
    QPixmap pxm = QPixmap(QString("./logo.png"));
    if (!pxm.isNull()){
        painter.drawPixmap(QPointF(0,yoffset),pxm);
        yoffset+=35;    // yoffset+= pxm.height();
    }
    painter.drawText(QRect(0,yoffset,170,20), Qt::AlignHCenter | Qt::AlignVCenter, QString("Чек%1%2")
                                                                                          .arg((m_check == "check" ? "" : (" - попередня")),(isCopy ? "" : ("(copy)"))));
    f.setPointSize(fontSize);
    f.setStretch(fontStretch);
    painter.setFont(f);
    painter.drawText(QRect(0, yoffset+=20,170,14),tr("Name")+": " + m_termCode);
    //    qDebug()<< "PriceDriver::printCheck market="<< m_termCode << QTextCodec::codecForLocale()->name();
    painter.drawText(QRect(0, yoffset+=14,170,14),tr("Address")+": " + m_termAddress);

    painter.drawText(QRect(0, yoffset+=16,140,14), tr("Артикул"));
    painter.drawText(QRect(0, yoffset+=14,35,14), Qt::AlignHCenter, tr("К-сть"));
    painter.drawText(QRect(35, yoffset,45,14), Qt::AlignHCenter, tr("Ціна"));
    painter.drawText(QRect(80, yoffset,55,14), Qt::AlignHCenter, tr("Сума"));
    painter.drawText(QRect(135, yoffset,35,14), Qt::AlignHCenter, tr("Знж"));

    yoffset += 16;
    QJsonValue v_dcm;
    // QJsonValue t;
    double am, eq, ds;
    for(int i=0; i < (bind.value("dcms").toArray()).size(); ++i){
        v_dcm = bind.value("dcms")[i];
        // t = v_dcm["amount"];
        am = v_dcm["amount"].toString().toDouble();
        eq = v_dcm["eq"].toString().toDouble();
        ds = v_dcm["dsc"].toString().toDouble();
        qDebug()<< "#84un print.paintCheck  am="<< am <<" eq="<<eq<<" ds="<<ds;
        if ((v_dcm["dcmtype"] == "trade:sell") || (v_dcm["dcmtype"] == "trade:buy")) {
            painter.drawText(QRect(0, yoffset,160,14), ((am > 0 ? QString("+ ") : QString("- "))
                                                          + v_dcm["note"].toString().left(v_dcm["note"].toString().indexOf("#"))
                                                          //                                                        + m_hash.get(v_dcms.at(i),qArticleName).toString()
                                                          + (v_dcm["mask"].toString().toInt()==2?(" #"+ v_dcm["iid"].toString()):"")));
            yoffset += 14;
            painter.drawText(QRect(0, yoffset,35,14), Qt::AlignRight,
                             QLocale::system().toString(qAbs(am),'f', v_dcm["prec"].toString().toInt()));
            painter.drawText(QRect(35, yoffset,45,14), Qt::AlignRight,
                             QString::number(v_dcm["qty"].toString().toDouble()
                                                 * (eq + ds)/am,'f',2) +
                                 (v_dcm["qty"].toString().toDouble() == 1
                                      ? QString("") : QString("/%1").arg(v_dcm["qty"].toString())));
            painter.drawText(QRect(80, yoffset,55,14), Qt::AlignRight, QLocale::system().toString(qAbs(eq), 'f',2));
            painter.drawText(QRect(135, yoffset,35,14), Qt::AlignRight, QLocale::system().toString(qAbs(ds), 'f',2));
            if (v_dcm["note"].toString().indexOf("#") != -1) {
                painter.drawText(QRect(0, yoffset+=14,150,14), v_dcm["inote"].toString().mid(v_dcm["inote"].toString().indexOf("#")+1));
            }
            //            if (m_hash.get(v_dcms.at(i), qWarranty).toInt() != 0) {
            //                painter.drawText(QRect(0, yoffset+=14,150,14),tr("Гарантія до: ") + QDate::currentDate().addDays(m_hash.get(v_dcms.at(i), qWarranty).toInt()-1).toString(Qt::ISODate));    //QDateTime::currentDateTime().toString(Qt::ISODate)
            //            }
        } else {
            painter.drawText(QRect(0, yoffset,160,14), ((am > 0 ? QString("+Отр ") : QString("-Вид "))
                                                          + v_dcm["ichar"].toString()
                                                          + v_dcm["inote"].toString()
                                                          //                                                        + m_hash.get(v_dcms.at(i),qArticleName).toString()
                                                          + (v_dcm["mask"].toString().toInt()==2?(" #"+v_dcm["iid"].toString()):"")));
            yoffset += 14;
            painter.drawText(QRect(0, yoffset,55,14), Qt::AlignRight,
                             QLocale::system().toString(qAbs(am),'f', v_dcm["prec"].toString().toInt()));
            painter.drawText(QRect(60, yoffset,110,14), v_dcm["note"].toString());
        }

        yoffset+=16;
    }
    painter.drawText(QRect(0, yoffset,170,12),"--------------------------------------------------------------------------" );
    painter.drawText(QRect(0, yoffset+=14,60,14), tr("Всього:"));
    painter.drawText(QRect(55, yoffset,80,14), Qt::AlignRight, QLocale::system().toString(qAbs(bind.value("eq").toDouble()), 'f',2));
    painter.drawText(QRect(135, yoffset,35,14), Qt::AlignRight, QLocale::system().toString(qAbs(bind.value("eq").toDouble()), 'f',2));
    painter.drawText(QRect(0, yoffset+=8,170,12),"--------------------------------------------------------------------------" );

    f.setPointSize(11);
    f.setStretch(100);
    painter.setFont(f);
    painter.drawText(QRect(0, yoffset+=10,50,30), Qt::AlignLeft | Qt::AlignVCenter, ((bind.value("eq").toDouble() + bind.value("dsc").toDouble())<0?"+":"-") + tr("Сума"));  // до оплати, до виплати
    f.setBold(true);
    f.setPointSize((qAbs(bind.value("eq").toDouble() + bind.value("dsc").toDouble())<1000000)?14:13);
    painter.setFont(f);
    painter.drawText(QRect(50, yoffset,120,30), Qt::AlignRight | Qt::AlignVCenter, QLocale::system().toString(qAbs(bind.value("eq").toDouble() + bind.value("dsc").toDouble()), 'f',2));
    f.setBold(false);
    f.setStretch(fontStretch);
    f.setPointSize(fontSize);
    painter.setFont(f);
    painter.drawText(QRect(0, yoffset+=25,75,14), (bind.value("amount").toDouble() >= 0?"+":"-") + tr(" Готівка:"));
    painter.drawText(QRect(80, yoffset,90,14), Qt::AlignRight, QLocale::system().toString(qAbs(bind.value("amount").toDouble()), 'f',2));


    f.setPointSize(fontSize);
    painter.setFont(f);
    painter.drawText(QRect(0, yoffset+=25,100,14),tr("Id:") + bind.value("id").toString().rightJustified(6,'0'));
    painter.drawText(QRect(0, yoffset+=14,150,14),tr("TermId: ") + m_termCode +" ( " + m_termUser + " )");
    painter.drawText(QRect(0, yoffset+=14,150,14),tr("Time: ") + bind.value("dcmtime").toString().left(16));
    f.setPointSize(12);
    painter.setFont(f);
    painter.drawText(QRect(0, yoffset+=18,150,20), Qt::AlignHCenter, tr("Дякуємо за співпрацю !"));


    painter.end();

    return 0;
}



// qDebug()<<"Print::printOrder STARTED id="
//          << " cash=" << bind.value("amount")
//          << " dcms len=" << (bind.value("dcms").toArray()).size()
//          // << " dcms t=" << (bind.value("dcms")[0]["inote"])
//          << " dcms=" << bind.value("dcms");  //.toVariantMap();

int Print::saveOrder_old(const QJsonObject & bind)
{
    QLocale locale = QLocale::system();

    QPrinter printer;

    // printer.setOutputFileName(QCoreApplication::applicationDirPath() + "/" + m_orderFile);
    printer.setOutputFileName("report/order.pdf");

    QPainter painter;
    if (! painter.begin(&printer)) { // failed to open painter
        QString err = "Print::saveOrder err " + QCoreApplication::applicationDirPath() + "/report/order.pdf";
        qDebug() << err;
        qWarning("failed to open file, is it writable?");
        return 1;
    }

    QPen pen;
    pen.setWidthF(1.5);
    painter.setPen(pen);
    double price = 0;
    int lmrg=50;     // left margin
    int xofs = lmrg;
    int yoffset = 20;
    int ylt =0;     // y left top
    //        int prb =0;     // point right bottom
    int tblw = 680; // table width
    int tbrlh = 20;  // table row heigh
    int wid = 24;
    int war = 50;
    int wam = 40;
    int wun = 30;
    int wpr = 60;
    int weq = 80;
    int wsps = 4;       // spacing
    int wnm = tblw - wid - war - wun - wam - wpr - weq - 6*wsps;
    //    painter.drawText(0, 0, "0123456789012345678901234567890123456789");
    QString fontFamily = "Arial";
    //    int fontStretch = 62;
    //        int fontStretch = 70;
    int fontSize = 10;

    QFont f = painter.font();
    f.setFamily(fontFamily);
    f.setPointSize(12);
    f.setBold(true);
    painter.setFont(f);
    painter.drawText(QRect(xofs,yoffset,tblw,20), Qt::AlignHCenter | Qt::AlignVCenter, QString("Видаткова накладна №___________ від __________________"));
    //        painter.drawText(QRect(xofs,yoffset,tblw,20), Qt::AlignHCenter | Qt::AlignVCenter, QString("Видаткова накладна № %1 від %2").arg(dcmid,v_time.left(10)));
    yoffset+=30;
    f.setPointSize(fontSize);
    f.setBold(false);
    //        f.setStretch(fontStretch);
    painter.setFont(f);
    painter.drawText(QRect(xofs, yoffset,2*war,14),"Постачальник:"); yoffset+=14;
    painter.drawLine(xofs+2*war,yoffset,xofs+tblw,yoffset); yoffset+=25;
    painter.drawLine(xofs+2*war,yoffset,xofs+tblw,yoffset); yoffset+=18;
    painter.drawText(QRect(xofs, yoffset,2*war,14),"Покупець: "); yoffset+=14;
    painter.drawLine(xofs+2*war,yoffset,xofs+tblw,yoffset); yoffset+=25;
    painter.drawLine(xofs+2*war,yoffset,xofs+tblw,yoffset); yoffset+=25;
    ylt = yoffset;
    painter.drawText(QRect(xofs, yoffset,wid,24), Qt::AlignHCenter|Qt::AlignVCenter,"No");xofs+=wid+wsps;
    painter.drawText(QRect(xofs, yoffset,war,24), Qt::AlignHCenter|Qt::AlignVCenter,"Арт");xofs+=war+wsps;
    painter.drawText(QRect(xofs, yoffset,wnm,24), Qt::AlignHCenter|Qt::AlignVCenter,"Назва");xofs+=wnm+wsps;
    painter.drawText(QRect(xofs, yoffset,wam,24), Qt::AlignHCenter|Qt::AlignVCenter,"К-сть");xofs+=wam+wsps;
    painter.drawText(QRect(xofs, yoffset,wun,24), Qt::AlignHCenter|Qt::AlignVCenter,"Од");xofs+=wun+wsps;
    painter.drawText(QRect(xofs, yoffset,wpr,24), Qt::AlignHCenter|Qt::AlignVCenter,"Ціна");xofs+=wpr+wsps;
    painter.drawText(QRect(xofs, yoffset,weq,24), Qt::AlignHCenter|Qt::AlignVCenter,"Сума");
    //    painter.drawText(QRect(130, yoffset,25,14), tr("Зниж"));
    yoffset += 24;
    xofs =lmrg;
    pen.setWidthF(2);
    painter.setPen(pen);
    painter.drawLine(xofs,yoffset,xofs+tblw,yoffset);
    pen.setWidthF(1);
    painter.setPen(pen);
    yoffset += 4;
    // int i=0;


    QJsonValue v_dcm;
    for(int i=0; i < (bind.value("dcms").toArray()).size(); ++i){
        v_dcm = bind.value("dcms")[i];
        price = v_dcm["eq"].toString().toDouble()/v_dcm["amount"].toString().toDouble();
        painter.drawText(QRect(xofs, yoffset,wid,tbrlh),Qt::AlignRight|Qt::AlignVCenter,QString::number(i+1));xofs+=wid+wsps;
        painter.drawText(QRect(xofs, yoffset,war,tbrlh), Qt::AlignHCenter|Qt::AlignVCenter,v_dcm["iid"].toString());xofs+=war+wsps;
        painter.drawText(QRect(xofs, yoffset,wnm,tbrlh),Qt::AlignVCenter,v_dcm["ichar"].toString());xofs+=wnm+wsps;
        painter.drawText(QRect(xofs, yoffset,wam,tbrlh), Qt::AlignRight|Qt::AlignVCenter,locale.toString(v_dcm["amount"].toString().toDouble(),'f',v_dcm["prec"].toString().toInt()));xofs+=wam+wsps;
        painter.drawText(QRect(xofs, yoffset,wun,tbrlh),Qt::AlignHCenter|Qt::AlignVCenter,v_dcm["uchar"].toString());xofs+=wun+wsps;
        painter.drawText(QRect(xofs, yoffset,wpr,tbrlh), Qt::AlignRight|Qt::AlignVCenter,locale.toString(price,'f',price<10?3:(price<100?2:1)));xofs+=wpr+wsps;
        painter.drawText(QRect(xofs, yoffset,weq,tbrlh), Qt::AlignRight|Qt::AlignVCenter,locale.toString(v_dcm["eq"].toString().toDouble(),'f',2));

        xofs = lmrg;
        yoffset+=tbrlh+2;
        painter.drawLine(xofs,yoffset,xofs+tblw+wsps,yoffset);

    }

    pen.setWidthF(2);
    painter.setPen(pen);
    painter.drawRect(xofs,ylt,tblw+wsps,yoffset-ylt);xofs+=wid+wsps/2;
    painter.drawLine(xofs,ylt,xofs,yoffset);xofs+=war+wsps;
    painter.drawLine(xofs,ylt,xofs,yoffset);xofs+=wnm+wsps;
    painter.drawLine(xofs,ylt,xofs,yoffset);xofs+=wam+wsps;
    painter.drawLine(xofs,ylt,xofs,yoffset);xofs+=wun+wsps;
    painter.drawLine(xofs,ylt,xofs,yoffset);xofs+=wpr+wsps;
    painter.drawLine(xofs,ylt,xofs,yoffset);
    //        yoffset+=tbrlh+5;
    xofs= lmrg+tblw-250;
    pen.setWidthF(1.5);
    painter.setPen(pen);
    f.setPointSize(12);
    f.setStretch(100);
    painter.setFont(f);
    painter.drawText(QRect(xofs, yoffset,70,30), Qt::AlignLeft | Qt::AlignVCenter, (tr("Разом:"))); xofs+=102;
    f.setBold(true);
    f.setPointSize(14);
    painter.setFont(f);
    painter.drawText(QRect(xofs, yoffset,140,30), Qt::AlignRight | Qt::AlignVCenter, QLocale::system().toString(qAbs(bind.value("eq").toDouble()), 'f',2));
    f.setBold(false);
    //        f.setStretch(fontStretch);

    xofs = lmrg;
    f.setPointSize(12);
    painter.setFont(f);
    yoffset+=30;
    painter.drawText(QRect(xofs, yoffset,xofs+tblw,24),tr("Всього найменувань %1 на суму %2 грн.").arg(QString::number((bind.value("dcms").toArray()).size()),QLocale::system().toString(qAbs(bind.value("eq").toDouble()), 'f',2)));
    yoffset+=45;
    painter.drawLine(xofs,yoffset,xofs+tblw,yoffset);
    yoffset+=30;
    f.setPointSize(fontSize);
    painter.setFont(f);

    painter.drawText(QRect(xofs, yoffset,tblw/2,18),tr("Відвантажив(ла):__________________________"));
    painter.drawText(QRect(xofs+tblw/2, yoffset,tblw/2,18),tr("Отримав(ла):_______________________________"));

    painter.end();

    return 0;
}
