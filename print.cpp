#include "print.h"
#include <QDir>
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

int Print::paintCheck(const QVariantMap &bind, int mode, int isCopy){
    QLocale locale = QLocale::system();
    QPrinter printer;
    QString reportPath = getAbsoluteReportPath(m_checkSubPath);
    // qDebug() << "II: print.cpp/paintCheck printerName=" << m_checkPrinter;
    if (mode) {
        // Друк на фізичний термопринтер каси
        printer.setPrinterName(m_checkPrinter);
    } else {
        printer.setOutputFileName(reportPath);
    }

    QPainter painter;

    if (!painter.begin(&printer)) {
        if (mode) {
            QString pn = printer.printerName();
            m_lastError = QString("Помилка QPainter для друку чеку. Принтер: %1")
                              .arg(pn.isEmpty() ? "N/A" : pn);
        } else {
            QString fn = printer.outputFileName();
            m_lastError = QString("Помилка QPainter для запису чеку. Каталог: %1")
                              .arg(fn.isEmpty() ? "N/A" : fn);
        }
        // const QString strErr = "Не вдалося відкрити QPainter. Перевірте права доступу або підключення принтера.";
        qWarning() << m_lastError;

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
    const QVariantList dcmsArray = bind.value(QStringLiteral("dcms")).toList();
    // int i = 0;
    for (const QVariant &v_dcm_val : dcmsArray) {
        QVariantMap v_dcm = v_dcm_val.toMap();
        // QVariantMap v_item = v_dcm.value(QStringLiteral("jitem")).toMap();
        if (v_dcm.isEmpty()) continue;

        double am = abs(v_dcm.value(QStringLiteral("amount")).toDouble());
        double eq = abs(v_dcm.value(QStringLiteral("eq")).toDouble());
        double ds = abs(v_dcm.value(QStringLiteral("dsc")).toDouble());
        int qty = v_dcm.value(QStringLiteral("qty"), 1).toInt();
        int mask = v_dcm.value(QStringLiteral("mask"), 0).toInt();
        int prec = v_dcm.value(QStringLiteral("prec"), 2).toInt(); // 2 — дефолтна точність, якщо prec відсутній
        QString noteStr = v_dcm.value(QStringLiteral("note")).toString().trimmed();
        QString crnStr = v_dcm.value(QStringLiteral("iid"), "").toString().trimmed();
        QString inoteStr = noteStr.indexOf(QStringLiteral("#")) < 0 ? QString() : noteStr.right(noteStr.indexOf(QStringLiteral("#")));
        QString dcmType = v_dcm.value(QStringLiteral("dcmtype")).toString();

        if (dcmType.startsWith("trade:")) {
            QString cleanNote = noteStr.left(noteStr.indexOf(QStringLiteral("#")));
            QString iidStr = (mask == 2) ? (QStringLiteral(" #") + crnStr) : QString();

            painter.drawText(QRect(0, yoffset, 160, 14), (am > 0 ? QStringLiteral("+ ") : QStringLiteral("- ")) + cleanNote + iidStr);
            yoffset += 14;

            painter.drawText(QRect(0, yoffset, 35, 14), Qt::AlignRight, locale.toString(qAbs(am), 'f', prec));

            // ЗАХИСТ ВІД ДІЛЕННЯ НА НУЛЬ: Якщо am == 0, ставимо ціну 0.00
            QString priceStr = QStringLiteral("0.00");
            if (am != 0.0) {
                priceStr = QString::number(qty * (eq) / am, 'f', 2);
                // priceStr = QString::number(qty * (eq + ds) / am, 'f', 2);
            }

            QString qtySuffix = (qty == 1) ? QString() : QStringLiteral("/%1").arg(qty);
            painter.drawText(QRect(35, yoffset, 45, 14), Qt::AlignRight, priceStr + qtySuffix);

            painter.drawText(QRect(80, yoffset, 55, 14), Qt::AlignRight, locale.toString(qAbs(eq), 'f', 2));
            painter.drawText(QRect(135, yoffset, 35, 14), Qt::AlignRight, locale.toString(qAbs(ds), 'f', 2));

            if (noteStr.contains(QStringLiteral("#"))) {
                painter.drawText(QRect(0, yoffset += 14, 150, 14), inoteStr.mid(inoteStr.indexOf(QStringLiteral("#")) + 1));
            }
        } else {
            // Касові ордери (Внесення / Вилучення)
            QString icharStr = v_dcm.value(QStringLiteral("ichar"), "N/A").toString();
            QString iidStr = (mask == 2) ? (QStringLiteral(" #") + crnStr) : QString();

            painter.drawText(QRect(0, yoffset, 160, 14), (am > 0 ? QStringLiteral("+Отр ") : QStringLiteral("-Вид ")) + icharStr + inoteStr + iidStr);
            yoffset += 14;

            painter.drawText(QRect(0, yoffset, 55, 14), Qt::AlignRight, locale.toString(qAbs(am), 'f', prec));
            painter.drawText(QRect(60, yoffset, 110, 14), noteStr);
        }

        yoffset += 16;
    }

    // Підсумковий блок чека
    painter.drawText(QRect(0, yoffset, 170, 12), QStringLiteral("--------------------------------------------------------------------------"));
    painter.drawText(QRect(0, yoffset += 14, 60, 14), tr("Всього:"));

    double totalEq = bind.value(QStringLiteral("eq")).toString().toDouble();
    double totalDsc = bind.value(QStringLiteral("dsc")).toString().toDouble();
    double totalAmount = bind.value(QStringLiteral("amount")).toString().toDouble();

    painter.drawText(QRect(55, yoffset, 80, 14), Qt::AlignRight, locale.toString(qAbs(totalEq), 'f', 2));
    painter.drawText(QRect(135, yoffset, 35, 14), Qt::AlignRight, locale.toString(qAbs(totalEq), 'f', 2));

    painter.drawText(QRect(0, yoffset += 8, 170, 12), QStringLiteral("--------------------------------------------------------------------------"));

    f.setPointSize(11);
    f.setStretch(100);
    painter.setFont(f);

    painter.drawText(QRect(0, yoffset += 10, 50, 30), Qt::AlignLeft | Qt::AlignVCenter, ((totalEq + totalDsc) < 0 ? QStringLiteral("+") : QStringLiteral("-")) + tr("Сума"));

    f.setBold(true);
    f.setPointSize((qAbs(totalEq + totalDsc) < 1000000.0) ? 14 : 13);
    painter.setFont(f);

    painter.drawText(QRect(50, yoffset, 120, 30), Qt::AlignRight | Qt::AlignVCenter, locale.toString(qAbs(totalEq + totalDsc), 'f', 2));

    f.setBold(false);
    f.setStretch(fontStretch);
    f.setPointSize(fontSize);
    painter.setFont(f);

    painter.drawText(QRect(0, yoffset += 25, 75, 14), (totalAmount >= 0 ? QStringLiteral("+") : QStringLiteral("-")) + tr(" Готівка:"));
    painter.drawText(QRect(80, yoffset, 90, 14), Qt::AlignRight, locale.toString(qAbs(totalAmount), 'f', 2));

    // Підвал чека (Метадані)
    painter.drawText(QRect(0, yoffset += 25, 100, 14), tr("Id:") + bind.value(QStringLiteral("id")).toString().rightJustified(6, '0'));
    painter.drawText(QRect(0, yoffset += 14, 150, 14), tr("TermId: ") + m_termCode + QStringLiteral(" ( ") + m_termUser + QStringLiteral(" )"));
    painter.drawText(QRect(0, yoffset += 14, 150, 14), tr("Time: ") + bind.value(QStringLiteral("dcmtime")).toString().left(16));

    f.setPointSize(12);
    painter.setFont(f);
    painter.drawText(QRect(0, yoffset += 18, 150, 20), Qt::AlignHCenter, tr("Дякуємо за співпрацю !"));

    painter.end();
    m_lastError = "";
    return 0;
}

int Print::saveOrder(const QVariantMap &bind)
{
    QLocale locale = QLocale::system();
    QPrinter printer;

    // Отримуємо абсолютний шлях до файлу звіту
    QString reportPath = getAbsoluteReportPath(m_orderSubPath);
    printer.setOutputFileName(reportPath);

    QPainter painter;
    if (!painter.begin(&printer)) {
        // Лог помилки тепер використовує безпечний метод збірки шляху
        m_lastError = QString("Не вдалося відкрити QPainter для запису накладної. Перевірте права доступу папки: %1")
                          .arg(getAbsoluteReportPath(m_orderSubPath));
        // qDebug() << QStringLiteral("Print::saveOrder err: ") << getAbsoluteReportPath(m_orderSubPath);
        qWarning() << m_lastError;;
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

    const QVariantList dcmsArray = bind.value(QStringLiteral("dcms")).toList();
    int i = 0;
    for (const QVariant &v_dcm_val : dcmsArray) {
        QVariantMap v_dcm = v_dcm_val.toMap();
        QVariantMap v_item = v_dcm.value(QStringLiteral("jitem")).toMap();
        if (v_dcm.isEmpty()) continue;

        double am = abs(v_dcm.value(QStringLiteral("amount")).toDouble());
        double eq = abs(v_dcm.value(QStringLiteral("eq")).toDouble());
        int qty = v_dcm.value(QStringLiteral("qty"), 1).toInt();
        int prec = v_dcm.value(QStringLiteral("prec"), 2).toInt(); // 2 — дефолтна точність, якщо prec відсутній
        QString iidStr = v_dcm.value(QStringLiteral("iid"), "").toString().trimmed();
        QString icharStr = v_dcm.value(QStringLiteral("ichar"), "n/a").toString().trimmed();
        QString ucharStr = v_dcm.value(QStringLiteral("uchar"), "").toString().trimmed();

        QString priceStr = QStringLiteral("0.00");
        if (am != 0.0) {
            price = qty * (eq) / am;
            priceStr = locale.toString(price, 'f', price < 10 ? 3 : (price < 100 ? 2 : 1));
            if (qty != 1) { priceStr += QStringLiteral("/%1").arg(qty); }
        }

        painter.drawText(QRect(xofs, yoffset, wid, tbrlh), Qt::AlignRight | Qt::AlignVCenter,
                         QString::number(i + 1)); xofs += wid + wsps;
        painter.drawText(QRect(xofs, yoffset, war, tbrlh), Qt::AlignHCenter | Qt::AlignVCenter,
                         iidStr); xofs += war + wsps;
        painter.drawText(QRect(xofs, yoffset, wnm, tbrlh), Qt::AlignVCenter,
                         icharStr); xofs += wnm + wsps;
        painter.drawText(QRect(xofs, yoffset, wam, tbrlh), Qt::AlignRight | Qt::AlignVCenter,
                         locale.toString(am, 'f', prec)); xofs += wam + wsps;
        painter.drawText(QRect(xofs, yoffset, wun, tbrlh), Qt::AlignHCenter | Qt::AlignVCenter,
                         ucharStr); xofs += wun + wsps;
        painter.drawText(QRect(xofs, yoffset, wpr, tbrlh), Qt::AlignRight | Qt::AlignVCenter,
                         priceStr); xofs += wpr + wsps;
        painter.drawText(QRect(xofs, yoffset, weq, tbrlh), Qt::AlignRight | Qt::AlignVCenter,
                         locale.toString(eq, 'f', 2));

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

/* // old version
int Print::paintCheck(const QVariantMap &bind, int mode, int isCopy){
    QLocale locale = QLocale::system();
    QPrinter printer;
    QString reportPath = getAbsoluteReportPath(m_checkSubPath);
    // qDebug() << "II: print.cpp/paintCheck printerName=" << m_checkPrinter;
    if (mode) {
        // Друк на фізичний термопринтер каси
        printer.setPrinterName(m_checkPrinter);
    } else {
        printer.setOutputFileName(reportPath);
    }

    QPainter painter;

    if (!painter.begin(&printer)) {
        if (mode) {
            m_lastError = QString("Помилка QPainter для друку чеку. Принтер: %1")
                              .arg(printer.printerName());
        } else {
            m_lastError = QString("Помилка QPainter для запису чеку. Каталог: %1")
                              .arg(printer.outputFileName());
        }
        // const QString strErr = "Не вдалося відкрити QPainter. Перевірте права доступу або підключення принтера.";
        qWarning() << m_lastError;

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
    const QVariantList dcmsArray = bind.value(QStringLiteral("dcms")).toList();
    int i = 0;
    for (const QVariant &v_dcm_val : dcmsArray) {
        QVariantMap v_dcm = v_dcm_val.toMap();
        QVariantMap v_item = v_dcm.value(QStringLiteral("jitem")).toMap();
        if (v_dcm.isEmpty()) continue;

        double am = abs(v_dcm.value(QStringLiteral("amnt")).toDouble());
        double eq = abs(v_dcm.value(QStringLiteral("eq")).toDouble());
        double ds = abs(v_dcm.value(QStringLiteral("dsc")).toDouble());
        int qty = v_item.value(QStringLiteral("qty"), 1).toInt();
        int mask = v_item.value(QStringLiteral("mask"), 0).toInt();
        int prec = v_item.value(QStringLiteral("unitprec"), 2).toInt(); // 2 — дефолтна точність, якщо prec відсутній
        QString noteStr = v_dcm.value(QStringLiteral("note")).toString().trimmed();
        QString crnStr = v_dcm[QStringLiteral("crn")].toString().trimmed();
        QString inoteStr = noteStr.indexOf(QStringLiteral("#")) < 0 ? QString() : noteStr.right(noteStr.indexOf(QStringLiteral("#")));
        QString dcmType = v_dcm.value(QStringLiteral("dcm")).toString();

        if (dcmType.startsWith("trade:")) {
            QString cleanNote = noteStr.left(noteStr.indexOf(QStringLiteral("#")));
            QString iidStr = (mask == 2) ? (QStringLiteral(" #") + crnStr) : QString();

            painter.drawText(QRect(0, yoffset, 160, 14), (am > 0 ? QStringLiteral("+ ") : QStringLiteral("- ")) + cleanNote + iidStr);
            yoffset += 14;

            painter.drawText(QRect(0, yoffset, 35, 14), Qt::AlignRight, locale.toString(qAbs(am), 'f', prec));

            // ЗАХИСТ ВІД ДІЛЕННЯ НА НУЛЬ: Якщо am == 0, ставимо ціну 0.00
            QString priceStr = QStringLiteral("0.00");
            if (am != 0.0) {
                priceStr = QString::number(qty * (eq) / am, 'f', 2);
                // priceStr = QString::number(qty * (eq + ds) / am, 'f', 2);
            }

            QString qtySuffix = (qty == 1.0) ? QString() : QStringLiteral("/%1").arg(qty);
            painter.drawText(QRect(35, yoffset, 45, 14), Qt::AlignRight, priceStr + qtySuffix);

            painter.drawText(QRect(80, yoffset, 55, 14), Qt::AlignRight, locale.toString(qAbs(eq), 'f', 2));
            painter.drawText(QRect(135, yoffset, 35, 14), Qt::AlignRight, locale.toString(qAbs(ds), 'f', 2));

            if (noteStr.contains(QStringLiteral("#"))) {
                painter.drawText(QRect(0, yoffset += 14, 150, 14), inoteStr.mid(inoteStr.indexOf(QStringLiteral("#")) + 1));
            }
        } else {
            // Касові ордери (Внесення / Вилучення)
            QString icharStr = v_item.value(QStringLiteral("itemchar"), "N/A").toString();
            QString iidStr = (mask == 2) ? (QStringLiteral(" #") + crnStr) : QString();

            painter.drawText(QRect(0, yoffset, 160, 14), (am > 0 ? QStringLiteral("+Отр ") : QStringLiteral("-Вид ")) + icharStr + inoteStr + iidStr);
            yoffset += 14;

            painter.drawText(QRect(0, yoffset, 55, 14), Qt::AlignRight, locale.toString(qAbs(am), 'f', prec));
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

    painter.drawText(QRect(55, yoffset, 80, 14), Qt::AlignRight, locale.toString(qAbs(totalEq), 'f', 2));
    painter.drawText(QRect(135, yoffset, 35, 14), Qt::AlignRight, locale.toString(qAbs(totalEq), 'f', 2));

    painter.drawText(QRect(0, yoffset += 8, 170, 12), QStringLiteral("--------------------------------------------------------------------------"));

    f.setPointSize(11);
    f.setStretch(100);
    painter.setFont(f);

    painter.drawText(QRect(0, yoffset += 10, 50, 30), Qt::AlignLeft | Qt::AlignVCenter, ((totalEq + totalDsc) < 0 ? QStringLiteral("+") : QStringLiteral("-")) + tr("Сума"));

    f.setBold(true);
    f.setPointSize((qAbs(totalEq + totalDsc) < 1000000.0) ? 14 : 13);
    painter.setFont(f);

    painter.drawText(QRect(50, yoffset, 120, 30), Qt::AlignRight | Qt::AlignVCenter, locale.toString(qAbs(totalEq + totalDsc), 'f', 2));

    f.setBold(false);
    f.setStretch(fontStretch);
    f.setPointSize(fontSize);
    painter.setFont(f);

    painter.drawText(QRect(0, yoffset += 25, 75, 14), (totalAmount >= 0 ? QStringLiteral("+") : QStringLiteral("-")) + tr(" Готівка:"));
    painter.drawText(QRect(80, yoffset, 90, 14), Qt::AlignRight, locale.toString(qAbs(totalAmount), 'f', 2));

    // Підвал чека (Метадані)
    painter.drawText(QRect(0, yoffset += 25, 100, 14), tr("Id:") + bind.value(QStringLiteral("id")).toString().rightJustified(6, '0'));
    painter.drawText(QRect(0, yoffset += 14, 150, 14), tr("TermId: ") + m_termCode + QStringLiteral(" ( ") + m_termUser + QStringLiteral(" )"));
    painter.drawText(QRect(0, yoffset += 14, 150, 14), tr("Time: ") + bind.value(QStringLiteral("dcmtime")).toString().left(16));

    f.setPointSize(12);
    painter.setFont(f);
    painter.drawText(QRect(0, yoffset += 18, 150, 20), Qt::AlignHCenter, tr("Дякуємо за співпрацю !"));

    painter.end();
    m_lastError = "";
    return 0;
}
*/

/* //old version
 *
int Print::saveOrder(const QVariantMap &bind)
{
    QLocale locale = QLocale::system();
    QPrinter printer;

    // Отримуємо абсолютний шлях до файлу звіту
    QString reportPath = getAbsoluteReportPath(m_orderSubPath);
    printer.setOutputFileName(reportPath);

    QPainter painter;
    if (!painter.begin(&printer)) {
        // Лог помилки тепер використовує безпечний метод збірки шляху
        m_lastError = QString("Не вдалося відкрити QPainter для запису накладної. Перевірте права доступу папки: %1")
                          .arg(getAbsoluteReportPath(m_orderSubPath));
        // qDebug() << QStringLiteral("Print::saveOrder err: ") << getAbsoluteReportPath(m_orderSubPath);
        qWarning() << m_lastError;;
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

    const QVariantList dcmsArray = bind.value(QStringLiteral("dcms")).toList();
    int i = 0;
    for (const QVariant &v_dcm_val : dcmsArray) {
        QVariantMap v_dcm = v_dcm_val.toMap();
        QVariantMap v_item = v_dcm.value(QStringLiteral("jitem")).toMap();
        if (v_dcm.isEmpty()) continue;

        double am = abs(v_dcm.value(QStringLiteral("amnt")).toDouble());
        double eq = abs(v_dcm.value(QStringLiteral("eq")).toDouble());
        int qty = v_item.value(QStringLiteral("qty"), 1).toInt();
        int prec = v_item.value(QStringLiteral("unitprec"), 2).toInt(); // 2 — дефолтна точність, якщо prec відсутній

        QString priceStr = QStringLiteral("0.00");
        if (am != 0.0) {
            price = qty * (eq) / am;
            priceStr = locale.toString(price, 'f', price < 10 ? 3 : (price < 100 ? 2 : 1));
            if (qty != 1) { priceStr += QStringLiteral("/%1").arg(qty); }
        }

        painter.drawText(QRect(xofs, yoffset, wid, tbrlh), Qt::AlignRight | Qt::AlignVCenter,
                         QString::number(i + 1)); xofs += wid + wsps;
        painter.drawText(QRect(xofs, yoffset, war, tbrlh), Qt::AlignHCenter | Qt::AlignVCenter,
                         v_item.value(QStringLiteral("id"), "n/a").toString()); xofs += war + wsps;
        painter.drawText(QRect(xofs, yoffset, wnm, tbrlh), Qt::AlignVCenter,
                         v_item.value(QStringLiteral("itemchar"), "n/a").toString()); xofs += wnm + wsps;
        painter.drawText(QRect(xofs, yoffset, wam, tbrlh), Qt::AlignRight | Qt::AlignVCenter,
                         locale.toString(am, 'f', prec)); xofs += wam + wsps;
        painter.drawText(QRect(xofs, yoffset, wun, tbrlh), Qt::AlignHCenter | Qt::AlignVCenter,
                         v_item.value(QStringLiteral("unitchar"), "n/a").toString()); xofs += wun + wsps;
        painter.drawText(QRect(xofs, yoffset, wpr, tbrlh), Qt::AlignRight | Qt::AlignVCenter,
                         priceStr); xofs += wpr + wsps;
        painter.drawText(QRect(xofs, yoffset, weq, tbrlh), Qt::AlignRight | Qt::AlignVCenter,
                         locale.toString(eq, 'f', 2));

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
*/
// qDebug()<<"Print::printCheck STARTED id="
//          << " cash=" << bind.value("amount")
//          << " dcms len=" << (bind.value("dcms").toArray()).size()
//          << " dcms t=" << (bind.value("dcms")[0]["inote"])
//          << " dcms=" << bind.value("dcms");  //.toVariantMap();
// QString msg = QString("Print::printCheck STARTED id=0 filePath=%1\n").arg(filePath);
//    QString v_term = QString("");   //q.value(2).toString().left(16);

