#include "print.h"

Print::Print(QObject *parent)
    : QObject{parent}
{}

/**
 * @brief Print::printCheck
 * @param bind
 * @param mode 1-print, 0-file
 * @param isCopy 0|1
 * @return
 */
int Print::paintCheck(const QJsonObject & bind, int mode, int isCopy)
{
    // qDebug()<<"Print::printCheck STARTED id="
    //          << " cash=" << bind.value("amount")
    //          << " dcms len=" << (bind.value("dcms").toArray()).size()
    //          << " dcms t=" << (bind.value("dcms")[0]["inote"])
    //          << " dcms=" << bind.value("dcms");  //.toVariantMap();
    // QString msg = QString("Print::printCheck STARTED id=0 filePath=%1\n").arg(filePath);
    //    QString v_term = QString("");   //q.value(2).toString().left(16);
    QPrinter printer;

    if (mode){ printer.setPrinterName(m_checkPrinter); }
        else { printer.setOutputFileName(m_checkFile); }

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
    painter.drawText(QRect(0, yoffset+=14,150,14),tr("Time: ") + bind.value("dcmtime").toString().left(16));    //QDateTime::currentDateTime().toString(Qt::ISODate)
    f.setPointSize(12);
    painter.setFont(f);
    painter.drawText(QRect(0, yoffset+=18,150,20), Qt::AlignHCenter, tr("Дякуємо за співпрацю !"));


    painter.end();

    return 0;
}



int Print::saveOrder(const QJsonObject & bind)
{
    // qDebug()<<"Print::printOrder STARTED id="
    //          << " cash=" << bind.value("amount")
    //          << " dcms len=" << (bind.value("dcms").toArray()).size()
    //          // << " dcms t=" << (bind.value("dcms")[0]["inote"])
    //          << " dcms=" << bind.value("dcms");  //.toVariantMap();
    QLocale locale = QLocale::system();

    QPrinter printer;

    printer.setOutputFileName(m_orderFile);

    QPainter painter;
    if (! painter.begin(&printer)) { // failed to open painter
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
    int wnm = tblw-wid-war-wun-wam-wpr-weq-6*wsps;
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
