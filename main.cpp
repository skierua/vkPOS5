// #include <QGuiApplication>
#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QQmlContext>
#include <QLocale>
#include <QDir>

#include <QDebug>

#include "dbdriver4.h"
#include "print.h"

int main(int argc, char *argv[])
{
    // QGuiApplication app(argc, argv);
    QApplication app(argc, argv);

    // QQuickStyle::setStyle("Basic");
    QQuickStyle::setStyle("Fusion");

    QCoreApplication::setOrganizationName("vksoft");
    // QCoreApplication::setApplicationName("TEST-vkPOS3");
    QCoreApplication::setApplicationName("vkPOS3");
    QCoreApplication::setApplicationVersion(QStringLiteral(APP_VERSION));

    // Форматування чисел за українським стандартом
    QLocale::setDefault(QLocale(QLocale::Ukrainian, QLocale::Ukraine));

    QQmlApplicationEngine engine;

    // engine.rootContext()->setContextProperty(QStringLiteral("Db"), DbDriver4::instance());
    // engine.rootContext()->setContextProperty(QStringLiteral("Prn"), Print::instance());
    // Шлях до папки бінарника для QML (якщо ще потрібен там)
    engine.rootContext()->setContextProperty("applicationDirPath",
                                             QDir::toNativeSeparators(QCoreApplication::applicationDirPath()));
    engine.rootContext()->setContextProperty(QStringLiteral("applicationVersion"), QStringLiteral(APP_VERSION));
    // qDebug() << "1 main.cpp APP_VERSION=" << APP_VERSION;
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed,
                     &app, []() { QCoreApplication::exit(-1); },
                     Qt::QueuedConnection);

    // Завантажуємо модуль — Qt сам створить екземпляри Prn та Db за потреби!
    engine.loadFromModule("vkPOS5", "Main");

    return app.exec();
}


