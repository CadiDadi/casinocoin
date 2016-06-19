TEMPLATE = app
TARGET = "CasinoCoin-Qt"
VERSION = 3.0.0.0
INCLUDEPATH += src src/json src/qt
QT += core gui network widgets qml quick
DEFINES += QT_GUI BOOST_THREAD_USE_LIB BOOST_SPIRIT_THREADSAFE USE_IPV6 __NO_SYSTEM_INCLUDES
CONFIG += no_include_pwd
CONFIG += thread
CONFIG += c++11

# For OSX Qt5.6 Static, Boost and BerkeleyDB must be compiled from source
#
# Qt5.6 Static
# -----------
# cd Qt56/5.6/Src
# ./configure -debug-and-release -opensource -confirm-license -platform macx-clang -opengl desktop -static -nomake examples -prefix $HOME/Qt56/static/5.6 -I /usr/local/Cellar/openssl/1.0.2h_1/include -L /usr/local/Cellar/openssl/1.0.2h_1/lib -make libs -qt-zlib -qt-pcre -qt-libpng -qt-libjpeg -qt-freetype -no-nis -no-cups
# make -j8
# make install
#
# Berkeley DB 5.1.29
# ----------------
# wget http://download.oracle.com/berkeley-db/db-5.1.29.NC.tar.gz
# tar xvzf db-5.1.29.NC.tar.gz
# cd db-5.1.29.NC/build_unix
# ../dist/configure --enable-cxx --disable-shared --disable-replication --disable-atomicsupport
# make
# sudo make install
#
# Boost 1.60
# -----------
# wget http://sourceforge.net/projects/boost/files/boost/1.60.0/boost_1_60_0.tar.gz
# tar xvzf boost_1_60_0.tar.gz
# cd boost_1_60_0
# ./bootstrap.sh
# ./b2 link=static --with-chrono --with-date_time --with-filesystem --with-program_options --with-system --with-thread --with-serialization
# cd ..
# cp -R boost_1_60_0 /usr/local

BOOST_LIB_SUFFIX =
BOOST_THREAD_LIB_SUFFIX =
BOOST_INCLUDE_PATH=/usr/local/boost_1_60_0
BOOST_LIB_PATH=/usr/local/boost_1_60_0/stage/lib
BDB_INCLUDE_PATH=/usr/local/BerkeleyDB.5.1/include
BDB_LIB_PATH=/usr/local/BerkeleyDB.5.1/lib
BDB_LIB_SUFFIX = -5.1
OPENSSL_INCLUDE_PATH=/usr/local/Cellar/openssl/1.0.2h_1/include
OPENSSL_LIB_PATH=/usr/local/Cellar/openssl/1.0.2h_1/lib
MINIUPNPC_INCLUDE_PATH=/usr/local/opt/miniupnpc/include
MINIUPNPC_LIB_PATH=/usr/local/opt/miniupnpc/lib
QRENCODE_INCLUDE_PATH=/usr/local/opt/qrencode/include
QRENCODE_LIB_PATH=/usr/local/opt/qrencode/lib

OBJECTS_DIR = build
MOC_DIR = build
UI_DIR = build

# Mac: compile for version (10.9, 64-bit)
#QMAKE_CXXFLAGS += -mmacosx-version-min=10.7 -arch x86_64 -isysroot $HOME/MacOSX-SDKs/MacOSX10.11.sdk
#QMAKE_CFLAGS += -mmacosx-version-min=10.7 -arch x86_64 -isysroot $HOME/MacOSX-SDKs/MacOSX10.11.sdk
#QMAKE_OBJECTIVE_CFLAGS += -mmacosx-version-min=10.7 -arch x86_64 -isysroot $HOME/MacOSX-SDKs/MacOSX10.11.sdk
QMAKE_MACOSX_DEPLOYMENT_TARGET = 10.7
#QMAKE_CXXFLAGS += -stdlib=libstdc++ -DBOOST_HAS_INT128=1

# for extra security against potential buffer overflows: enable GCCs Stack Smashing Protection
QMAKE_CXXFLAGS *= -fstack-protector-all
QMAKE_LFLAGS *= -fstack-protector-all -headerpad_max_install_names
# for extra security (see: https://wiki.debian.org/Hardening): this flag is GCC compiler-specific
QMAKE_CXXFLAGS *= -D_FORTIFY_SOURCE=2

# use: qmake "USE_QRCODE=1"
# libqrencode (http://fukuchi.org/works/qrencode/index.en.html) must be installed for support
contains(USE_QRCODE, 1) {
    message(Building with QRCode support)
    DEFINES += USE_QRCODE
    #LIBS += -lqrencode
    LIBS += -lqrencode $$join(QRENCODE_LIB_PATH,,-L,)    
}

# use: qmake "USE_UPNP=1" ( enabled by default; default)
#  or: qmake "USE_UPNP=0" (disabled by default)
#  or: qmake "USE_UPNP=-" (not supported)
# miniupnpc (http://miniupnp.free.fr/files/) must be installed for support
contains(USE_UPNP, -) {
    message(Building without UPNP support)
} else {
    message(Building with UPNP support)
    count(USE_UPNP, 0) {
        USE_UPNP=1
    }
    DEFINES += USE_UPNP=$$USE_UPNP STATICLIB
    INCLUDEPATH += $$MINIUPNPC_INCLUDE_PATH
    LIBS += $$join(MINIUPNPC_LIB_PATH,,-L,) -lminiupnpc
}

# use: qmake "USE_DBUS=1"
contains(USE_DBUS, 1) {
    message(Building with DBUS (Freedesktop notifications) support)
    DEFINES += USE_DBUS
    QT += dbus
}

# use: qmake "USE_IPV6=1" ( enabled by default; default)
#  or: qmake "USE_IPV6=0" (disabled by default)
#  or: qmake "USE_IPV6=-" (not supported)
contains(USE_IPV6, -) {
    message(Building without IPv6 support)
} else {
    count(USE_IPV6, 0) {
        USE_IPV6=1
    }
    DEFINES += USE_IPV6=$$USE_IPV6
}

contains(BITCOIN_NEED_QT_PLUGINS, 1) {
    DEFINES += BITCOIN_NEED_QT_PLUGINS
    QTPLUGIN += qcncodecs qjpcodecs qtwcodecs qkrcodecs qtaccessiblewidgets
}

INCLUDEPATH += src/leveldb/include src/leveldb/helpers
LIBS += $$PWD/src/leveldb/libleveldb.a $$PWD/src/leveldb/libmemenv.a
# we use QMAKE_CXXFLAGS_RELEASE even without RELEASE=1 because we use RELEASE to indicate linking preferences not -O preferences
genleveldb.commands = cd $$PWD/src/leveldb && CC=$$QMAKE_CC CXX=$$QMAKE_CXX $(MAKE) OPT=\"$$QMAKE_CXXFLAGS $$QMAKE_CXXFLAGS_RELEASE\" libleveldb.a libmemenv.a
genleveldb.target = $$PWD/src/leveldb/libleveldb.a
genleveldb.depends = FORCE
PRE_TARGETDEPS += $$PWD/src/leveldb/libleveldb.a
QMAKE_EXTRA_TARGETS += genleveldb
# Gross ugly hack that depends on qmake internals, unfortunately there is no other way to do it.
QMAKE_CLEAN += $$PWD/src/leveldb/libleveldb.a; cd $$PWD/src/leveldb ; $(MAKE) clean

# regenerate src/build.h
contains(USE_BUILD_INFO, 1) {
    genbuild.depends = FORCE
    genbuild.commands = cd $$PWD; /bin/sh share/genbuild.sh $$OUT_PWD/build/build.h
    genbuild.target = $$OUT_PWD/build/build.h
    PRE_TARGETDEPS += $$OUT_PWD/build/build.h
    QMAKE_EXTRA_TARGETS += genbuild
    DEFINES += HAVE_BUILD_INFO
}

QMAKE_CXXFLAGS_WARN_ON = -fdiagnostics-show-option -Wall -Wextra -Wformat -Wformat-security -Wno-unused-parameter -Wno-strict-aliasing -Wstack-protector -Wno-unused-local-typedefs

##### Start Project Files #####

DEPENDPATH += src src/json src/qt
HEADERS += src/qt/bitcoingui.h \
    src/qt/transactiontablemodel.h \
    src/qt/addresstablemodel.h \
    src/qt/optionsdialog.h \
    src/qt/sendcoinsdialog.h \
    src/qt/coincontroldialog.h \
    src/qt/coincontroltreewidget.h \
    src/qt/addressbookpage.h \
    src/qt/signverifymessagedialog.h \
    src/qt/aboutdialog.h \
    src/qt/editaddressdialog.h \
    src/qt/bitcoinaddressvalidator.h \
    src/alert.h \
    src/addrman.h \
    src/base58.h \
    src/bignum.h \
    src/checkpoints.h \
    src/coincontrol.h \
    src/compat.h \
    src/sync.h \
    src/util.h \
    src/hash.h \
    src/uint256.h \
    src/serialize.h \
    src/main.h \
    src/net.h \
    src/key.h \
    src/db.h \
    src/walletdb.h \
    src/script.h \
    src/init.h \
    src/bloom.h \
    src/mruset.h \
    src/checkqueue.h \
    src/json/json_spirit_writer_template.h \
    src/json/json_spirit_writer.h \
    src/json/json_spirit_value.h \
    src/json/json_spirit_utils.h \
    src/json/json_spirit_stream_reader.h \
    src/json/json_spirit_reader_template.h \
    src/json/json_spirit_reader.h \
    src/json/json_spirit_error_position.h \
    src/json/json_spirit.h \
    src/qt/clientmodel.h \
    src/qt/guiutil.h \
    src/qt/transactionrecord.h \
    src/qt/guiconstants.h \
    src/qt/optionsmodel.h \
    src/qt/monitoreddatamapper.h \
    src/qt/transactiondesc.h \
    src/qt/transactiondescdialog.h \
    src/qt/bitcoinamountfield.h \
    src/wallet.h \
    src/keystore.h \
    src/qt/transactionfilterproxy.h \
    src/qt/transactionview.h \
    src/qt/walletmodel.h \
    src/qt/walletview.h \
    src/qt/walletstack.h \
    src/qt/walletframe.h \
    src/bitcoinrpc.h \
    src/qt/overviewpage.h \
    src/qt/csvmodelwriter.h \
    src/crypter.h \
    src/qt/sendcoinsentry.h \
    src/qt/qvalidatedlineedit.h \
    src/qt/bitcoinunits.h \
    src/qt/qvaluecombobox.h \
    src/qt/askpassphrasedialog.h \
    src/protocol.h \
    src/qt/notificator.h \
    src/qt/paymentserver.h \
    src/allocators.h \
    src/ui_interface.h \
    src/qt/rpcconsole.h \
    src/scrypt.h \
    src/version.h \
    src/netbase.h \
    src/clientversion.h \
    src/txdb.h \
    src/leveldb.h \
    src/threadsafety.h \
    src/limitedmap.h \
    src/qt/macnotificationhandler.h \
    src/qt/splashscreen.h \
    src/qt/CSCPublicAPI/casinocoinwebapi.h \
    src/qt/CSCPublicAPI/casinocoinwebapiparser.h \
    src/qt/CSCPublicAPI/jsonactivepromotionsparser.h \
    src/qt/CSCPublicAPI/jsonactiveexchangesparser.h \
    src/qt/CSCPublicAPI/jsonsingleactivepromotion.h \
    src/qt/CSCPublicAPI/jsonsingleactiveexchange.h \
    src/qt/qtquick_controls/cpp/guibannercontrol.h \
    src/qt/qtquick_controls/cpp/guibannerlistview.h \
    src/qt/qtquick_controls/cpp/guibannerwidget.h \
    src/qt/qtquick_controls/cpp/listiteminterface.h \
    src/qt/qtquick_controls/cpp/qmlbannerlistitem.h \
    src/qt/qtquick_controls/cpp/qmlbannerlistmodel.h \
    src/qt/qtquick_controls/cpp/qmlimageprovider.h \
    src/qt/qtquick_controls/cpp/qmllistitem.h \
    src/qt/qtquick_controls/cpp/qmllistmodel.h \
    src/qt/qtquick_controls/cpp/qmlmenutoolbarmodel.h \
    src/qt/qtquick_controls/cpp/qmlmenutoolbaritem.h \
    src/qt/qtquick_controls/cpp/guimenutoolbarwidget.h \
    src/qt/qtquick_controls/cpp/guimenutoolbarlistview.h \
    src/qt/qtquick_controls/cpp/guimenutoolbarcontrol.h \
    src/qt/gui20_skin.h \
    src/qt/cscfusionstyle.h \
    src/qt/pryptopage.h \
    src/qt/currencies.h \
    src/qt/CSCPublicAPI/jsoncoininfoparser.h \
    src/qt/infopage.h \
    src/qt/qtquick_controls/cpp/guiexchangeswidget.h \
    src/qt/qtquick_controls/cpp/qmlexchangeslistmodel.h \
    src/qt/qtquick_controls/cpp/qmlexchangeslistitem.h \
    src/qt/qtquick_controls/cpp/guiexchangeslistview.h \
    src/qt/qtquick_controls/cpp/guiexchangescontrol.h \
    src/qt/twitter/twitterwidget.h

SOURCES += src/qt/bitcoin.cpp \
    src/qt/bitcoingui.cpp \
    src/qt/transactiontablemodel.cpp \
    src/qt/addresstablemodel.cpp \
    src/qt/optionsdialog.cpp \
    src/qt/sendcoinsdialog.cpp \
    src/qt/coincontroldialog.cpp \
    src/qt/coincontroltreewidget.cpp \
    src/qt/addressbookpage.cpp \
    src/qt/signverifymessagedialog.cpp \
    src/qt/aboutdialog.cpp \
    src/qt/editaddressdialog.cpp \
    src/qt/bitcoinaddressvalidator.cpp \
    src/alert.cpp \
    src/version.cpp \
    src/sync.cpp \
    src/util.cpp \
    src/hash.cpp \
    src/netbase.cpp \
    src/key.cpp \
    src/script.cpp \
    src/main.cpp \
    src/init.cpp \
    src/net.cpp \
    src/bloom.cpp \
    src/checkpoints.cpp \
    src/addrman.cpp \
    src/db.cpp \
    src/walletdb.cpp \
    src/qt/clientmodel.cpp \
    src/qt/guiutil.cpp \
    src/qt/transactionrecord.cpp \
    src/qt/optionsmodel.cpp \
    src/qt/monitoreddatamapper.cpp \
    src/qt/transactiondesc.cpp \
    src/qt/transactiondescdialog.cpp \
    src/qt/bitcoinstrings.cpp \
    src/qt/bitcoinamountfield.cpp \
    src/wallet.cpp \
    src/keystore.cpp \
    src/qt/transactionfilterproxy.cpp \
    src/qt/transactionview.cpp \
    src/qt/walletmodel.cpp \
    src/qt/walletview.cpp \
    src/qt/walletstack.cpp \
    src/qt/walletframe.cpp \
    src/bitcoinrpc.cpp \
    src/rpcdump.cpp \
    src/rpcnet.cpp \
    src/rpcmining.cpp \
    src/rpcwallet.cpp \
    src/rpcblockchain.cpp \
    src/rpcrawtransaction.cpp \
    src/qt/overviewpage.cpp \
    src/qt/csvmodelwriter.cpp \
    src/crypter.cpp \
    src/qt/sendcoinsentry.cpp \
    src/qt/qvalidatedlineedit.cpp \
    src/qt/bitcoinunits.cpp \
    src/qt/qvaluecombobox.cpp \
    src/qt/askpassphrasedialog.cpp \
    src/protocol.cpp \
    src/qt/notificator.cpp \
    src/qt/paymentserver.cpp \
    src/qt/rpcconsole.cpp \
    src/scrypt.cpp \
    src/noui.cpp \
    src/leveldb.cpp \
    src/txdb.cpp \
    src/qt/splashscreen.cpp \
    src/qt/CSCPublicAPI/casinocoinwebapi.cpp \
    src/qt/CSCPublicAPI/casinocoinwebapiparser.cpp \
    src/qt/CSCPublicAPI/jsonactivepromotionsparser.cpp \
    src/qt/CSCPublicAPI/jsonactiveexchangesparser.cpp \
    src/qt/CSCPublicAPI/jsonsingleactivepromotion.cpp \
    src/qt/CSCPublicAPI/jsonsingleactiveexchange.cpp \
    src/qt/qtquick_controls/cpp/guibannercontrol.cpp \
    src/qt/qtquick_controls/cpp/guibannerlistview.cpp \
    src/qt/qtquick_controls/cpp/guibannerwidget.cpp \
    src/qt/qtquick_controls/cpp/qmlbannerlistitem.cpp \
    src/qt/qtquick_controls/cpp/qmlbannerlistmodel.cpp \
    src/qt/qtquick_controls/cpp/qmlimageprovider.cpp \
    src/qt/qtquick_controls/cpp/qmllistitem.cpp \
    src/qt/qtquick_controls/cpp/qmllistmodel.cpp \
    src/qt/qtquick_controls/cpp/qmlmenutoolbarmodel.cpp \
    src/qt/qtquick_controls/cpp/qmlmenutoolbaritem.cpp \
    src/qt/qtquick_controls/cpp/guimenutoolbarwidget.cpp \
    src/qt/qtquick_controls/cpp/guimenutoolbarlistview.cpp \
    src/qt/qtquick_controls/cpp/guimenutoolbarcontrol.cpp \
    src/qt/gui20_skin.cpp \
    src/qt/cscfusionstyle.cpp \
    src/qt/pryptopage.cpp \
    src/qt/currencies.cpp \
    src/qt/CSCPublicAPI/jsoncoininfoparser.cpp \
    src/qt/infopage.cpp \
    src/qt/qtquick_controls/cpp/guiexchangeswidget.cpp \
    src/qt/qtquick_controls/cpp/qmlexchangeslistmodel.cpp \
    src/qt/qtquick_controls/cpp/qmlexchangeslistitem.cpp \
    src/qt/qtquick_controls/cpp/guiexchangeslistview.cpp \
    src/qt/qtquick_controls/cpp/guiexchangescontrol.cpp \
    src/qt/twitter/twitterwidget.cpp

RESOURCES += src/qt/bitcoin.qrc

FORMS += src/qt/forms/sendcoinsdialog.ui \
    src/qt/forms/coincontroldialog.ui \
    src/qt/forms/addressbookpage.ui \
    src/qt/forms/signverifymessagedialog.ui \
    src/qt/forms/aboutdialog.ui \
    src/qt/forms/editaddressdialog.ui \
    src/qt/forms/transactiondescdialog.ui \
    src/qt/forms/overviewpage.ui \
    src/qt/forms/sendcoinsentry.ui \
    src/qt/forms/askpassphrasedialog.ui \
    src/qt/forms/rpcconsole.ui \
    src/qt/forms/optionsdialog.ui \
    src/qt/forms/pryptopage.ui \
    src/qt/forms/infopage.ui

OTHER_FILES += README.md \
    doc/*.rst \
    doc/*.txt \
    doc/*.md \
    src/qt/res/bitcoin-qt.rc \
    src/qt/qtquick_controls/qml/QmlGUIBannerControl.qml \
    src/qt/qtquick_controls/qml/QmlGUIBannerListView.qml \
    src/qt/qtquick_controls/qml/QmlGUIBannerWindow.qml \
    src/qt/qtquick_controls/qml/QmlGUIExchangesControl.qml \
    src/qt/qtquick_controls/qml/QmlGUIExchangesListView.qml \
    src/qt/qtquick_controls/qml/QmlGUIExchangesWindow.qml \
    src/qt/qtquick_controls/qml/QmlGUIMenuToolbarWindow.qml \
    src/qt/qtquick_controls/qml/QmlGUIMenuToolbarListView.qml \
    src/qt/qtquick_controls/qml/QmlGUIMenuToolbarControl.qml \
    src/qt/twitter/*.qml

DISTFILES += \
    QmlImports.qml

##### End Project Files #####

contains(USE_QRCODE, 1) {
   HEADERS += src/qt/qrcodedialog.h
   SOURCES += src/qt/qrcodedialog.cpp
   FORMS += src/qt/forms/qrcodedialog.ui
}

contains(USE_SSE2, 1) {
DEFINES += USE_SSE2
gccsse2.input  = SOURCES_SSE2
gccsse2.output = $$PWD/build/${QMAKE_FILE_BASE}.o
gccsse2.commands = $(CXX) -c $(CXXFLAGS) $(INCPATH) -o ${QMAKE_FILE_OUT} ${QMAKE_FILE_NAME} -msse2 -mstackrealign
QMAKE_EXTRA_COMPILERS += gccsse2
SOURCES_SSE2 += src/scrypt-sse2.cpp
}

# Todo: Remove this line when switching to Qt5, as that option was removed
CODECFORTR = UTF-8

# for lrelease/lupdate
# also add new translations to src/qt/bitcoin.qrc under translations/
TRANSLATIONS = $$files(src/qt/locale/bitcoin_*.ts)

isEmpty(QMAKE_LRELEASE) {
#    win32:QMAKE_LRELEASE = $$[QT_INSTALL_BINS]\\lrelease.exe
#    else:QMAKE_LRELEASE = $$[QT_INSTALL_BINS]/lrelease
    QMAKE_LRELEASE = $$[QT_INSTALL_BINS]/lrelease
}
isEmpty(QM_DIR):QM_DIR = $$PWD/src/qt/locale
# automatically build translations, so they can be included in resource file
TSQM.name = lrelease ${QMAKE_FILE_IN}
TSQM.input = TRANSLATIONS
TSQM.output = $$QM_DIR/${QMAKE_FILE_BASE}.qm
TSQM.commands = $$QMAKE_LRELEASE ${QMAKE_FILE_IN} -qm ${QMAKE_FILE_OUT}
TSQM.CONFIG = no_link
QMAKE_EXTRA_COMPILERS += TSQM

HEADERS += src/qt/macdockiconhandler.h src/qt/macnotificationhandler.h
OBJECTIVE_SOURCES += src/qt/macdockiconhandler.mm src/qt/macnotificationhandler.mm
LIBS += -framework Foundation -framework ApplicationServices -framework AppKit -framework CoreServices
DEFINES += MAC_OSX MSG_NOSIGNAL=0
ICON = src/qt/res/icons/casinocoin.icns
#QMAKE_CFLAGS_THREAD += -pthread
#QMAKE_LFLAGS_THREAD += -pthread
#QMAKE_CXXFLAGS_THREAD += -pthread
QMAKE_INFO_PLIST = share/qt/Info.plist

# Set libraries and includes at end, to use platform-defined defaults if not overridden
INCLUDEPATH += $$BOOST_INCLUDE_PATH $$BDB_INCLUDE_PATH $$OPENSSL_INCLUDE_PATH $$QRENCODE_INCLUDE_PATH
LIBS += $$join(BOOST_LIB_PATH,,-L,) $$join(BDB_LIB_PATH,,-L,) $$join(OPENSSL_LIB_PATH,,-L,) $$join(QRENCODE_LIB_PATH,,-L,)
LIBS += -lssl -lcrypto -ldb_cxx$$BDB_LIB_SUFFIX -lpthread
LIBS += -lboost_system$$BOOST_LIB_SUFFIX -lboost_filesystem$$BOOST_LIB_SUFFIX -lboost_program_options$$BOOST_LIB_SUFFIX -lboost_thread$$BOOST_THREAD_LIB_SUFFIX
LIBS += -lboost_chrono$$BOOST_LIB_SUFFIX
LIBS += -dead_strip

system($$QMAKE_LRELEASE -silent $$TRANSLATIONS)