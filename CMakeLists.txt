cmake_minimum_required(VERSION 3.24)

project(vkPOS5
    VERSION 2.22
    LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)
set_property(GLOBAL PROPERTY USE_FOLDERS ON)

# find_package(Qt6 6.9 REQUIRED COMPONENTS QuickControls2)
# find_package(Qt6 6.9 REQUIRED COMPONENTS Quick)
# find_package(Qt6 6.9 REQUIRED COMPONENTS Sql)
# find_package(Qt6 6.9 REQUIRED COMPONENTS PrintSupport)
find_package(Qt6 REQUIRED COMPONENTS Core)
find_package(Qt6 REQUIRED COMPONENTS QuickControls2)
find_package(Qt6 REQUIRED COMPONENTS Quick)
find_package(Qt6 REQUIRED COMPONENTS Sql)
find_package(Qt6 REQUIRED COMPONENTS PrintSupport)
# find_package(Qt${QT_VERSION_MAJOR} REQUIRED COMPONENTS QuickControls2)
# find_package(Qt${QT_VERSION_MAJOR} EQUIRED COMPONENTS Quick)
# find_package(Qt${QT_VERSION_MAJOR} REQUIRED COMPONENTS Sql)
# find_package(Qt${QT_VERSION_MAJOR} REQUIRED COMPONENTS PrintSupport)

qt_standard_project_setup()

set(CPP_FILES
    dbdriver4.cpp dbdriver4.h
    print.cpp print.h
)

set(JS_FILES
    qt/lib.js
    qt/libREST.js
    qt/libTAX.js
    qt/qml/js/v146/sqlAcnt.js
    qt/qml/js/v146/sqlItem.js
    qt/qml/js/v146/sqlPrice.js

)

set(DB_FILES
    data/db.sqlite
)

set(REPORT_FILES
)

set(ICON_FILES
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


qt_add_executable(appvkPOS5
    main.cpp
)


qt_add_qml_module(appvkPOS5
    URI vkPOS5
    # VERSION 2.20
    QML_FILES
        qt/qml/Main.qml
        # qt/qml/MainKant.qml
        # qt/qml/MainShop.qml
        qt/qml/Bind.qml
        qt/qml/Balance.qml
        qt/qml/Client.qml
        qt/qml/DcmView.qml
        qt/qml/DrawerItem.qml
        qt/qml/LogView.qml
        qt/qml/ModelBind.qml
        qt/qml/ModelDbDcms.qml
        qt/qml/ModelDrawer.qml
        qt/qml/ModelRates.qml
        qt/qml/Rate.qml
        qt/qml/Shift.qml
        qt/qml/Settings.qml
        qt/qml/Stat.qml
        qt/qml/WizardCash.qml
        qt/qml/TaxService.qml
        qt/qml/ModelBalance.qml
        ${JS_FILES}
    SOURCES
        ${CPP_FILES}
    RESOURCES
        # ${DB_FILES}
        # data/vkPOS5-init.sql
        # data/vkPOS5.sql
        # README.md
        # TODO.txt
)


#  !!! added by me
#set(CMAKE_AUTORCC ON)
#qt_add_resources(appvkPOS5 "app_data"
#    PREFIX "/"
#    FILES
#        data/vk_me.sqlite
#    )

qt_add_resources(appvkPOS5 "app_res"
    PREFIX "/"
    FILES
        ${ICON_FILES}
        ${DB_FILES}
        data/vkPOS5-init.sql
        data/vkPOS5.sql
        README.md
        .gitignore
        TODO.txt
)

# set_directory_properties(PROPERTIES FOLDER "data_test")
# qt_add_resources(appvkPOS5
#     data/db.sqlite
# )

# set_directory_properties(PROPERTIES FOLDER "")

set_target_properties(appvkPOS5 PROPERTIES
    MACOSX_BUNDLE_GUI_IDENTIFIER vkcheck3.vksoft.com
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    RESOURCE "report/${REPORT_FILES}"
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appvkPOS5
    # PRIVATE Qt${QT_VERSION_MAJOR}::Core
    PRIVATE Qt${QT_VERSION_MAJOR}::QuickControls2
    PRIVATE Qt${QT_VERSION_MAJOR}::Quick
    PRIVATE Qt${QT_VERSION_MAJOR}::Sql
    PRIVATE Qt${QT_VERSION_MAJOR}::PrintSupport)

install(TARGETS appvkPOS5
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

if(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
    message(STATUS "macOS-specific QML and sources. Project: ${PROJECT_NAME} v.${PROJECT_VERSION}")
    # message(STATUS "macOS-specific QML and sources. Folder: ${CMAKE_BINARY_DIR}")
    # macOS-specific files
    set_source_files_properties(${DB_FILES} PROPERTIES MACOSX_PACKAGE_LOCATION "MacOS/data")
    # set_source_files_properties(${REPORT_FILES} PROPERTIES MACOSX_PACKAGE_LOCATION "MacOS/report")
    # file(MAKE_DIRECTORY MACOSX_PACKAGE_LOCATION "MacOS/report")

elseif(CMAKE_SYSTEM_NAME STREQUAL "Windows")
    message(STATUS "Windows-specific QML and sources.")

elseif(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    message(STATUS "Linux-specific QML and sources.")
else()
    message(FATAL_ERROR "Unsupported OS. No kernelproxy.h defined for ${CMAKE_SYSTEM_NAME}.")
endif()
