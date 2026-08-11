cmake_minimum_required(VERSION 3.24)

project(vkPOS5
    VERSION 3.8
    LANGUAGES CXX)


set(CMAKE_CXX_STANDARD 17) # Суворий стандарт C++ для Qt6
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set_property(GLOBAL PROPERTY USE_FOLDERS ON)

if(APPLE)
    # Змушуємо лінкер ігнорувати застарілі фреймворки, які Qt намагається підтягнути
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Wl,-undefined,dynamic_lookup")
    set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -Wl,-undefined,dynamic_lookup")
endif()

find_package(Qt6 REQUIRED COMPONENTS Core)
find_package(Qt6 REQUIRED COMPONENTS QuickControls2)
find_package(Qt6 REQUIRED COMPONENTS Quick)
find_package(Qt6 REQUIRED COMPONENTS Sql)
find_package(Qt6 REQUIRED COMPONENTS Widgets) # Потрібен для стабільного функціонування PrintSupport
find_package(Qt6 REQUIRED COMPONENTS PrintSupport)
# find_package(Qt${QT_VERSION_MAJOR} REQUIRED COMPONENTS QuickControls2)
# find_package(Qt${QT_VERSION_MAJOR} EQUIRED COMPONENTS Quick)
# find_package(Qt${QT_VERSION_MAJOR} REQUIRED COMPONENTS Sql)
# find_package(Qt${QT_VERSION_MAJOR} REQUIRED COMPONENTS PrintSupport)

# Виправляємо баг Qt з відсутнім AGL на нових macOS
# if(APPLE)
#     message(STATUS "macOS-specific QML and sources. Remove framework AGL TARGET=${TARGET}")
#     if(TARGET Qt6::Gui)
#         get_target_property(GUI_LINKS Qt6::Gui INTERFACE_LINK_LIBRARIES)
#         message(STATUS "macOS-specific QML and sources. GUI_LINKS=${GUI_LINKS}")
#         if(GUI_LINKS)
#             string(REPLACE "-framework AGL" "" GUI_LINKS "${GUI_LINKS}")
#             set_target_properties(Qt6::Gui PROPERTIES INTERFACE_LINK_LIBRARIES "${GUI_LINKS}")
#         endif()
#     endif()
# endif()

qt_standard_project_setup()

set(CPP_FILES
    dbdriver4.cpp dbdriver4.h
    print.cpp print.h
)

set(JS_FILES
    qt/qml/js/v147/config.js
    # qt/lib.js
    # qt/libTAX.js
    qt/qml/js/libREST.js
    qt/qml/js/main.js
    qt/qml/js/CashDesk.js
    qt/qml/js/v147/sqlAcnt.js
    qt/qml/js/v147/sqlBind.js
    qt/qml/js/v147/sqlClient.js
    qt/qml/js/v147/sqlItem.js
    qt/qml/js/v147/dbMigration.js
    qt/qml/js/v147/sqlPrice.js
    qt/qml/js/v147/sqlRepo.js
    qt/qml/js/v147/sqlShift.js
    qt/qml/js/v147/sqlTran.js
    qt/qml/js/bind.js
    qt/qml/js/drawer.js
    qt/qml/js/shift.js
    qt/qml/js/rate.js
)

set(DB_FILES
    data/db.sqlite
    data/vkPOS5_init.sql
    data/vkPOS5.sql
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
    VERSION ${PROJECT_VERSION}
    RESOURCE_PREFIX "/qt/qml" # Явно вказуємо стандартний префікс Qt6
       QML_FILES
        qt/qml/Main.qml
        qt/qml/AppSettings.qml
        qt/qml/Bind.qml
        qt/qml/Balance.qml
        qt/qml/Client.qml
        qt/qml/DcmView.qml
        qt/qml/DrawerItem.qml
        qt/qml/LogView.qml
        qt/qml/ModelBind.qml
        qt/qml/ModelDbDcms.qml
        qt/qml/Rate.qml
        qt/qml/Shift.qml
        qt/qml/Stat.qml
        qt/qml/WizardCash.qml
        qt/qml/TaxService.qml
        qt/qml/ModelBalance.qml
        ${JS_FILES}
    SOURCES
        ${CPP_FILES}
        QML_FILES qt/qml/js/v147/sqlBalance.js
)

qt_add_resources(appvkPOS5 "app_res"
    PREFIX "/"
    FILES
        ${ICON_FILES}
        ${DB_FILES}
        README.md
        .gitignore
        TODO.txt
)

# set_directory_properties(PROPERTIES FOLDER "data_test")
# qt_add_resources(appvkPOS5
#     data/db.sqlite
# )

target_compile_definitions(appvkPOS5 PRIVATE
    APP_VERSION="${PROJECT_VERSION}"
)

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
    PRIVATE Qt6::Widgets
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
