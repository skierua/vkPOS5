#include <QGuiApplication>
#include <QQmlApplicationEngine>
// #include <QQmlEngine>
#include <QDebug>
#include <QQuickView>
#include <QQmlContext>

// #include "dbdriver3.h"
#include "dbdriver4.h"
#include "print.h"

/**
 * @brief main
 * @param argc
 * @param argv --kant|--shop
 * @return
 */
int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    QCoreApplication::setOrganizationName("vksoft");
    // QCoreApplication::setApplicationName("TEST-vkPOS3");
    QCoreApplication::setApplicationName("vkPOS5");

   // QCoreApplication::setOrganizationName("vksoftme");
   // QCoreApplication::setApplicationName("vkcheck3");

    QScopedPointer<Print> libPrint(new Print);
    qmlRegisterSingletonInstance<Print>("com.print", 1, 0, "Prn", libPrint.get());
    // qmlRegisterType<Singleton>("com.singleton", 1, 0, "Db");
    QScopedPointer<DbDriver4> singletonprocessor(new DbDriver4);
    qmlRegisterSingletonInstance("com.singleton.dbdriver4", 1, 0, "Db", singletonprocessor.get());

    // qDebug() << "argc=" << argc << " 0="<< argv[1];
//    qDebug() << "1 main.cpp pwd=" << QDir::current();
    /*
    if (QSettings().value("program/pwd","").toString().isEmpty()){
        QDir::setCurrent("/");
    } else {
        QDir::setCurrent(QSettings().value("program/pwd","~/snap/TESTvksoft").toString());
    }
    */
//    QDir::setCurrent("~/snap/TESTvksoft");
//    qDebug() << "2 main.cpp pwd=" << QDir::current();

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("applicationDirPath", QCoreApplication::applicationDirPath());
    // const QUrl url(u"qrc:/vkPOS5/qt/qml/Main.qml"_qs);
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed,
        &app, []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    // engine.load(url);
    // qDebug() << "main.cpp localStorage path=" << engine.offlineStoragePath();
    // if (argc > 0 && QString::fromLatin1(argv[1]) == "-shop"){
    //     engine.load("qrc:/vkPOS5/qt/qml/MainShop.qml");
    // } else {
    //     engine.load("qrc:/vkPOS5/qt/qml/MainKant.qml");
    // }
   engine.load("qrc:/vkPOS5/qt/qml/Main.qml");
   // engine.loadFromModule("vkPOS5", "Main");

//    QObject::connect(&engine, SIGNAL(vkEvent),engine.load(url));


   // QQuickView view;
   // view.setSource(QUrl::fromLocalFile("Main.qml"));
   // // view.setSource(url);
   // view.show();
   // QObject *obj = view.rootObject();

    return app.exec();
}
