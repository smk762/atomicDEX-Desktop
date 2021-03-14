include(DEX_NEW_LIB)

# Core target
DEX_NEW_LIB(core STATIC
        PUBLIC_DEPS
        cpprestsdk::cpprest Qt::Core Qt::Quick Qt::Svg Qt::Charts Qt::WebEngine Qt::WebEngineCore Qt::WebEngineWidgets
        Qt::Widgets nlohmann_json::nlohmann_json antara_qrcode spdlog::spdlog antara::world reproc++
        unofficial-btc::bitcoin ${PROJECT_NAME}::apis ${PROJECT_NAME}::pages komodo-date::date komodo-taskflow::taskflow
        Boost::random Boost::filesystem komodo-sodium::sodium antara::app::net
        PUBLIC_DEFS
        $<$<OR:$<CONFIG:Debug>,$<CONFIG:RelWithDebInfo>>:QT_QML_DEBUG> $<$<PLATFORM_ID:Windows>:HAS_REMOTE_API>
        $<$<PLATFORM_ID:Windows>:AUTO_DOWNLOAD> DEX_NAME="${DEX_DISPLAY_NAME}" DEX_WEBSITE_URL="${DEX_WEBSITE}"
        DEX_SUPPORT_URL="${DEX_SUPPORT_PAGE}" DEX_DISCORD_URL="${DEX_DISCORD}" DEX_TWITTER_URL="${DEX_TWITTER}"
        PRIVATE_DEFS
        ENTT_API_EXPORT)
target_precompile_headers(${PROJECT_NAME}_core PUBLIC core/atomicdex/pch.hpp)
if (APPLE)
    set_source_files_properties(core/atomicdex/platform/osx/manager.mm PROPERTIES SKIP_PRECOMPILE_HEADERS ON)
endif ()
if (DISABLE_GEOBLOCKING)
    message(STATUS "Disabling Geoblocking for dev purpose")
    target_compile_definitions(${PROJECT_NAME}_core PUBLIC -DDISABLE_GEOBLOCKING)
endif ()

# Apis target
DEX_NEW_LIB(apis STATIC
        PRIVATE_DEPS nlohmann_json::nlohmann_json ${PROJECT_NAME}::core)

# Models target
DEX_NEW_LIB(models STATIC
        PRIVATE_DEPS Qt::Core EnTT::EnTT antara::world ${PROJECT_NAME}::core ${PROJECT_NAME}::pages ${PROJECT_NAME}::apis)

# Pages target
DEX_NEW_LIB(pages STATIC
        PUBLIC_DEPS Qt::Core ${PROJECT_NAME}::models PRIVATE_DEPS ${PROJECT_NAME}::core)


# Translation files
set_directory_properties(PROPERTIES CLEAN_NO_CUSTOM TRUE)
set(TS_FILES
        ${CMAKE_SOURCE_DIR}/atomic_defi_design/assets/languages/atomic_defi_en.ts
        ${CMAKE_SOURCE_DIR}/atomic_defi_design/assets/languages/atomic_defi_fr.ts
        ${CMAKE_SOURCE_DIR}/atomic_defi_design/assets/languages/atomic_defi_tr.ts
        ${CMAKE_SOURCE_DIR}/atomic_defi_design/assets/languages/atomic_defi_ru.ts)
set_source_files_properties(${TS_FILES} PROPERTIES OUTPUT_LOCATION ${CMAKE_SOURCE_DIR}/atomic_defi_design/assets/languages)
qt5_create_translation(QM_FILES
        ${PROJECT_SOURCE_DIR}/atomic_defi_design/qml
        ${TS_FILES}
        OPTIONS -source-language en_US -no-obsolete)
message(STATUS "QM FILES -> ${QM_FILES}")
message(STATUS "TS FILES -> ${TS_FILES}")

# Main executable
add_executable(${PROJECT_NAME}
        #MACOSX_BUNDLE
        #${ICON}

        app/app.cpp
        app/main.cpp

        ${CMAKE_SOURCE_DIR}/cmake/install/windows/dex.rc

        ##! QRC
        ${CMAKE_SOURCE_DIR}/qml.qrc

        ##! Linguistic
        ${QM_FILES}
        ${TS_FILES})
target_link_libraries(${PROJECT_NAME} PRIVATE ${PROJECT_NAME}::core ${PROJECT_NAME}::pages ${PROJECT_NAME}::models Qaterial)
target_compile_definitions(${PROJECT_NAME} PRIVATE ENTT_API_IMPORT)
if (NOT WITH_BUILDSYSTEM_V2)
    set_target_properties(${PROJECT_NAME}
            PROPERTIES
            RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin/")
endif ()

# Testing executable
add_executable(${PROJECT_NAME}_tests MACOSX_BUNDLE ${ICON}
        tests/atomic.dex.tests.cpp
        tests/atomic.dex.wallet.config.tests.cpp
        tests/atomic.dex.provider.cex.prices.tests.cpp
        tests/atomic.dex.qt.utilities.tests.cpp

        ##! API
        tests/api/coingecko/coingecko.tests.cpp
        tests/api/mm2/mm2.rpc.trade.preimage.tests.cpp
        tests/api/mm2/mm2.fraction.tests.cpp

        ##! Utilities
        tests/utilities/qt.utilities.tests.cpp
        tests/utilities/global.utilities.tests.cpp

        ##! Managers
        tests/managers/addressbook.manager.tests.cpp

        ##! Models
        tests/models/qt.addressbook.contact.model.tests.cpp

        tests/atomic.dex.provider.cex.prices.api.tests.cpp)
target_link_libraries(${PROJECT_NAME}_tests
        PUBLIC
        ${PROJECT_NAME}::core ${PROJECT_NAME}::models ${PROJECT_NAME}::pages
        doctest::doctest)
set_target_properties(${PROJECT_NAME}_tests
        PROPERTIES
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin/")

# Main executable installation related
if (LINUX)
    get_target_property(exe_runtime_directory_at ${PROJECT_NAME} RUNTIME_OUTPUT_DIRECTORY)
    set(output_dir_at "${exe_runtime_directory_at}/AntaraAtomicDexAppDir")

    magic_game_app_image_generation("${CMAKE_SOURCE_DIR}/cmake/install/linux"
            "dex.desktop"
            "dex.appdata.xml"
            "dex-logo-64.png"
            ${PROJECT_NAME}
            AntaraAtomicDexAppDir
            ${CMAKE_SOURCE_DIR}/assets)

    magic_game_app_image_generation("${CMAKE_SOURCE_DIR}/cmake/install/linux"
            "dex.desktop"
            "dex.appdata.xml"
            "dex-logo-64.png"
            ${PROJECT_NAME}_tests
            AntaraAtomicDexTestsAppDir
            ${CMAKE_SOURCE_DIR}/assets)

    set(from_dir "${CMAKE_SOURCE_DIR}/cmake/install/linux")
    set(desktop_file "dex.desktop")
    set(appdata_file "dex.appdata.xml")
    set(app_icon "dex-logo-64.png")
    message(STATUS "${output_dir_at}")
    configure_file(${from_dir}/${desktop_file} ${output_dir_at}/usr/share/applications/${desktop_file} COPYONLY)
    configure_file(${from_dir}/${appdata_file} ${output_dir_at}/usr/share/metainfo/${appdata_file} COPYONLY)
    configure_file(${from_dir}/${app_icon} ${output_dir_at}/usr/share/icons/hicolor/64x64/apps/${app_icon} COPYONLY)
    configure_file(${from_dir}/${app_icon} ${output_dir_at}/usr/share/icons/default/64x64/apps/${app_icon} COPYONLY)
    include(${CMAKE_SOURCE_DIR}/cmake/install/linux/dex_install.cmake)
endif ()

if (WIN32)
    add_compile_definitions(_CRT_SECURE_NO_WARNINGS)
    file(COPY ${CMAKE_SOURCE_DIR}/assets DESTINATION ${CMAKE_BINARY_DIR}/bin/)
    configure_file(${CMAKE_SOURCE_DIR}/wally/wally.dll ${CMAKE_BINARY_DIR}/bin/ COPYONLY)
    if (CMAKE_BUILD_TYPE MATCHES Release)
        message(STATUS "disabling console")
        target_compile_definitions(${PROJECT_NAME} PRIVATE WINDOWS_RELEASE_MAIN)
        target_compile_options(${PROJECT_NAME} PRIVATE -Wno-deprecated-declarations)
        target_link_options(${PROJECT_NAME} PUBLIC --for-linker -subsystem:windows)
    endif ()
    set(WINDEPLOYQT_PATH "")
    if (CONAN_ENABLED)
        set(WINDEPLOYQT_PATH ${CONAN_QT_ROOT}/bin/windeployqt.exe)
    else ()
        set(WINDEPLOYQT_PATH $ENV{QT_INSTALL_CMAKE_PATH}/bin/windeployqt.exe)
    endif ()

    if (EXISTS ${WINDEPLOYQT_PATH})
        message(STATUS "windeployqt path is -> ${WINDEPLOYQT_PATH}")
    else ()
        message(FATAL_ERROR "Didn't find windeployqt ${WINDEPLOYQT_PATH}")
    endif ()
    add_custom_command(TARGET ${PROJECT_NAME} PRE_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_directory
            ${CMAKE_SOURCE_DIR}/ci_tools_atomic_dex/windows_misc $<TARGET_FILE_DIR:${PROJECT_NAME}>)
    message(STATUS "${WINDEPLOYQT_PATH} ${CMAKE_BINARY_DIR}/bin/${PROJECT_NAME}.exe --qmldir ${CMAKE_SOURCE_DIR}/atomic_defi_design/qml")
    add_custom_command(TARGET ${PROJECT_NAME}
            POST_BUILD
            COMMAND ${WINDEPLOYQT_PATH} ${CMAKE_BINARY_DIR}/bin/${PROJECT_NAME}.exe --qmldir ${CMAKE_SOURCE_DIR}/atomic_defi_design/qml
            )
    include(${CMAKE_SOURCE_DIR}/cmake/install/windows/dex_install.cmake)
endif ()

if (APPLE)
    if (CMAKE_GENERATOR STREQUAL "Xcode")
        message(STATUS "Copy to Xcode binary directory")
        file(COPY ${CMAKE_SOURCE_DIR}/assets DESTINATION ${CMAKE_BINARY_DIR}/bin/${CMAKE_BUILD_TYPE}/${PROJECT_NAME}.app/Contents/Resources)
        file(COPY ${CMAKE_SOURCE_DIR}/assets DESTINATION ${CMAKE_BINARY_DIR}/bin/${CMAKE_BUILD_TYPE}/${PROJECT_NAME}_tests.app/Contents/Resources)
    else ()
        file(COPY ${CMAKE_SOURCE_DIR}/assets DESTINATION ${CMAKE_BINARY_DIR}/bin/${PROJECT_NAME}.app/Contents/Resources)
        file(COPY ${CMAKE_SOURCE_DIR}/assets DESTINATION ${CMAKE_BINARY_DIR}/bin/${PROJECT_NAME}_tests.app/Contents/Resources)
    endif ()
    if (WITH_BUILDSYSTEM_V2)
        message(STATUS "Using QAterial OSX Helpers")

        set(QTMACCMAKE_REPOSITORY "https://github.com/OlivierLDff/QtMacCMake.git" CACHE STRING "QtMacCMake repository, can be a local URL")
        set(QTMACCMAKE_TAG "main" CACHE STRING "QtMacCMake git tag")

        FetchContent_Declare(
                QtMacCMake
                GIT_REPOSITORY ${QTMACCMAKE_REPOSITORY}
                GIT_TAG ${QTMACCMAKE_TAG}
        )

        FetchContent_MakeAvailable(QtMacCMake)

        if (${CMAKE_SYSTEM_NAME} STREQUAL "Darwin")
            message(STATUS "->>> ${PROJECT_SOURCE_DIR}/cmake/install/macos/Assets.xcassets")
            add_qt_mac_app(${PROJECT_NAME}
                    NAME ${DEX_PROJECT_NAME}
                    BUNDLE_IDENTIFIER "com.komodoplatform.atomicdex"
                    LONG_VERSION ${PROJECT_VERSION}
                    COPYRIGHT "Copyright Komodoplatform 2017-2021"
                    APPLICATION_CATEGORY_TYPE "public.app-category.finance"
                    QML_DIR ${PROJECT_SOURCE_DIR}/atomic_defi_design/qml
                    RESOURCES
                    "${PROJECT_SOURCE_DIR}/cmake/install/macos/Assets.xcassets"
                    CUSTOM_ENTITLEMENTS "${PROJECT_SOURCE_DIR}/cmake/install/macos/dex.entitlements"
                    DMG
                    PKG
                    # PKG_UPLOAD_SYMBOLS
                    VERBOSE
                    VERBOSE_LEVEL 3
                    )

        endif ()
    else ()
        include(${CMAKE_SOURCE_DIR}/cmake/install/macos/dex_install.cmake)
    endif ()
endif ()