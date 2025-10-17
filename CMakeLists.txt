cmake_minimum_required(VERSION 3.24)

project(vkPOS5 VERSION 5.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

# find_package(Qt6 6.9 REQUIRED COMPONENTS QuickControls2)
# find_package(Qt6 6.9 REQUIRED COMPONENTS Quick)
# find_package(Qt6 6.9 REQUIRED COMPONENTS Sql)
# find_package(Qt6 6.9 REQUIRED COMPONENTS PrintSupport)
find_package(Qt6 REQUIRED COMPONENTS QuickControls2)
find_package(Qt6 REQUIRED COMPONENTS Quick)
find_package(Qt6 REQUIRED COMPONENTS Sql)
find_package(Qt6 REQUIRED COMPONENTS PrintSupport)
# find_package(Qt${QT_VERSION_MAJOR} REQUIRED COMPONENTS QuickControls2)
# find_package(Qt${QT_VERSION_MAJOR} 6.9 REQUIRED COMPONENTS Quick)
# find_package(Qt${QT_VERSION_MAJOR} REQUIRED COMPONENTS Sql)
# find_package(Qt${QT_VERSION_MAJOR} REQUIRED COMPONENTS PrintSupport)

qt_standard_project_setup()

qt_add_executable(appvkPOS5
    main.cpp
    dbdriver4.cpp
    print.cpp
)


qt_add_qml_module(appvkPOS5
    URI vkPOS5
    VERSION 2.0
    QML_FILES qt/qml/Main.qml
        qt/qml/MainKant.qml
        qt/qml/MainShop.qml
        qt/qml/Bind.qml
        qt/qml/Client.qml
        qt/qml/DcmView.qml
        qt/qml/DrawerItem.qml
        qt/qml/Login.qml
        qt/qml/Settings.qml
        qt/qml/Shift.qml
        qt/qml/TaxService.qml
        qt/qml/WizardCash.qml
        qt/qml/Stat.qml
        qt/qml/Rate.qml
        qt/lib.js
        qt/libREST.js
        RESOURCES README.md .gitignore
        QML_FILES qt/qml/ModelRates.qml
        QML_FILES qt/qml/LogView.qml
        # SOURCES print.h print.cpp
        # SOURCES singleton.h singleton.cpp
        # libSettings.js
#        RESOURCES data/vk_me.sqlite
)

#  !!! added by me
#set(CMAKE_AUTORCC ON)
#qt_add_resources(appvkPOS5 "app_data"
#    PREFIX "/"
#    FILES
#        data/vk_me.sqlite
#    )

qt_add_resources(appvkPOS5 "app_icons"
    PREFIX "/"
    FILES
        icon/account.svg
        icon/add.svg
        icon/close.svg
        icon/drawer.svg
        icon/edit-copy.svg
        icon/find.svg
        icon/filter.svg
        icon/reload.svg
        icon/save.svg
        icon/undo.svg
)

set_target_properties(appvkPOS5 PROPERTIES
    MACOSX_BUNDLE_GUI_IDENTIFIER vkcheck3.vksoft.com
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

# target_link_libraries(appvkPOS5
#     PRIVATE Qt6::QuickControls2
#     PRIVATE Qt6::Quick
#     PRIVATE Qt6::Sql
#     PRIVATE Qt6::PrintSupport
# )

target_link_libraries(appvkPOS5
    PRIVATE Qt${QT_VERSION_MAJOR}::QuickControls2
    PRIVATE Qt${QT_VERSION_MAJOR}::Quick
    PRIVATE Qt${QT_VERSION_MAJOR}::Sql
    PRIVATE Qt${QT_VERSION_MAJOR}::PrintSupport)

install(TARGETS appvkPOS5
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
