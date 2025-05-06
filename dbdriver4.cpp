#include "dbdriver4.h"

DbDriver4::DbDriver4(QObject *parent) : QObject(parent) {
    // ...
    // qDebug()<<"DbDriver4 constructor started";
    m_db = QSqlDatabase::addDatabase("QSQLITE", "st");

}


bool DbDriver4::openConnection()
{
       // qDebug()<<"DbDriver4::openConnection m_cc=("<<m_cc<<") m_db.isOpen()="<<m_db.isOpen();
    //    if (!m_cc && m_db.isOpen()) {
    //        ++m_cc;
    //        return true;
    //    }
    if (++m_cc == 1) {
        if (!m_db.open()) {
            //TODO connection error
            m_lastError = QString("EE:DbDriver3::openConnection database ERROR OPEN...\nname:%1(type:%2)\n%3")
                              //                    .arg(m_db.databaseName())
                              //                    .arg(m_db.driverName())
                              .arg(m_db.databaseName(), m_db.driverName(), m_db.lastError().text());
            qDebug()<<m_lastError;
            // emit error(m_lastError);
            m_cc = 0;
            return false;
        } else {
            //            if (m_db.driver() == "QSQLITE") {
            QSqlQuery q = QSqlQuery(QString("PRAGMA foreign_keys = ON;"), m_db);
            //            }
        }
    }
    // qDebug()<<"DbDriver4::openConnection m_cc=("<<m_cc<<") m_db.isOpen()="<<m_db.isOpen();

    //    m_cc = 1;
    return true;
}

void DbDriver4::closeConnection()
{
    if (!--m_cc) { m_db.close(); }
}


void DbDriver4::setDbParameter(const QString & name, const QString & type, const QString & conn)
{
    // m_status = StDataLoading;
    // m_hash.removePrefix();
    // m_conn = conn;
    // m_db.close();
    // m_cc = 0;
    // if (!m_conn.isEmpty() && (type != "QSQLITE")){
    //     m_db = QSqlDatabase::addDatabase(type, m_conn);
    // }

    m_db.setDatabaseName(name);
    if (openConnection()) {
        QSqlQuery q = QSqlQuery(m_db);
        q = QSqlQuery(QString("select branchname, branchname2, branchaddres, dbversion, domcur, domchar, domname from settings"),m_db);
        if (q.next()) {
            //            qDebug()<<"VkCore::open open 60";
            // m_termName = q.value(0).toString();
            //            m_termCode = q.value(1).toString();
            // m_termAddress = q.value(2).toString();
            //            m_domCur = q.value(3).toString();
            m_dbVersion = q.value(3).toString();
        }
        // m_hash.loadSqlData(m_db, "select acnt.acntno||'/'||coalesce(item,''), id, coalesce(eqid,0), coalesce(rsltid,0) from acnt left join acntrade on(id=pkey)",
        //                    QString(" acnt.acntno = '%1' or acnt.acntno = '%2' ").arg(m_cashDfltAcnt, m_tradeDfltAcnt), "acnt/", false);

        closeConnection();
        // QSettings().setValue("database/last_db_name", name);
        // QSettings().setValue("database/last_db_driver", type);
        // m_status = StOk;
    } //else {m_status = StError;}
    // emit driverStatusChanged(m_status);

    //    m_hash.printHash4test("acntPrice/");
}

bool DbDriver4::closeShift(const QString shftid)
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


int DbDriver4::dbInsert(const QString &sql){
    int id = 0;
    if (openConnection()) {
        QSqlQuery q = QSqlQuery(sql,m_db);
        if (q.isActive()) {
            id = q.lastInsertId().toInt();
        } else {
            m_lastError = QString("EE:DbDriver3::dbInsert query ERROR\n%1\n%2")
            .arg(q.lastQuery(), q.lastError().text());
            qDebug()<<m_lastError;
            emit vkEvent("error", m_lastError);
        }

        closeConnection();
    }
    return id;
}


bool DbDriver4::dbUpdate(const QString &sql){
    //    qDebug()<<"DbDriver3::dbUpdate started sql="<<sql;
    bool res = false;
    if (openConnection()) {
        QSqlQuery q = QSqlQuery(sql,m_db);
        if (q.isActive()) {
            res = true;
        } else {
            m_lastError = QString("EE:DbDriver3::dbUpdate query ERROR\n%1\n%2")
            .arg(q.lastError().text(), q.lastQuery());
            qDebug()<<m_lastError;
            emit vkEvent("error", m_lastError);
        }

        closeConnection();
    }
    return res;
}

bool DbDriver4::dbDelete(const QString &sql){
    //    qDebug()<<"DbDriver3::dbDelete started sql="<<sql;
    bool res = false;
    if (openConnection()) {
        QSqlQuery q = QSqlQuery(sql,m_db);
        if (q.isActive()) {
            res = true;
        } else {
            m_lastError = QString("EE:DbDriver3::dbDelete query ERROR\n%1\n%2")
            .arg(q.lastError().text(), q.lastQuery());
            qDebug()<<m_lastError;
            emit vkEvent("error", m_lastError);
        }

        closeConnection();
    }
    return res;
}

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
    //    if (!str.isEmpty()){
    //        str.prepend("[");
    //        str += "]";
    //    } else { str = "\"\"";}
    //    qDebug()<<"DbDriver3::getJSONRowsFromSQL \n"<<str;
    return QString("{\"errorId\":%1,\"errorText\":\"%2\",\"rowCount\":%3,\"rows\":[%4]}").arg(errId).arg(errText).arg(rowCount).arg(str);

}

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
