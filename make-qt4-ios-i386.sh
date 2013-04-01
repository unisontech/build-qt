#!/bin/bash

# copied from mac version

QT_VERSION="4.8.4"
IOS_SDK_VERSION="6.1"
QT_SOURCE_DIR="qt-everywhere-opensource-src-$QT_VERSION"
QT_SOURCE_PKG="qt-everywhere-opensource-src-$QT_VERSION.tar.gz"
QT_LIB_PKG="qt-ios-$QT_VERSION-i386.tar.gz"
QT_INSTALL_DIR=$PWD/qt-i386
CPU_CORES_COUNT=$(expr $(sysctl -A 2>&1 |grep 'hw\.ncpu:' |sed "s/^hw\.ncpu: \([0-9]*\)/\1/") + 1)

fail()
{
	echo "-- Qt $QT_VERSION for i386 build failed"
	popd
	exit 1
}

download_source()
{
	if [ ! -f $QT_SOURCE_PKG ] ; then
		echo "-- Downloading Qt $QT_VERSION sources"
		curl -L http://releases.qt-project.org/qt4/source/$QT_SOURCE_PKG --O $QT_SOURCE_PKG || fail
	fi
}

unpack_source()
{
	echo "-- Unpacking Qt $QT_VERSION sources"
	tar -xzf $QT_SOURCE_PKG || fail
	mv $QT_SOURCE_DIR $QT_INSTALL_DIR
}

unpack_openssl()
{
	echo "-- Unpacking openssl sources for i386"
	rm -rf ./openssl
	mkdir ./openssl
	tar -xzf openssl-ios-i386.tar.gz -C ./openssl || fail
}

patch_source()
{
	echo "-- Patching Qt for i386"
	PATCHES_DIR=patches/ios

	patch -d ${QT_INSTALL_DIR}/config.tests/unix -p0 < ${PATCHES_DIR}/config.tests/unix/endian_test.patch || fail
	patch -d ${QT_INSTALL_DIR}/mkspecs/unsupported/macx-iossimulator-g++ -p0 < ${PATCHES_DIR}/mkspecs/unsupported/macx-iossimulator-g++/qmake_conf.patch || fail
}

build_source()
{
	pushd $QT_INSTALL_DIR

	SSL_DIR=$QT_INSTALL_DIR/../openssl/ios-i386

	XCODE_ROOT=`xcode-select --print-path`

	echo "-- Configuring Qt $QT_VERSION for i386"
	./configure \
	-verbose \
	-confirm-license \
	-opensource \
	-prefix $QT_INSTALL_DIR \
	-release \
	-xplatform unsupported/macx-iossimulator-g++ \
	-arch i386 \
	-static \
	-fast \
	-no-exceptions \
	-no-stl \
	-no-qt3support \
	-no-webkit \
	-no-scripttools \
	-openssl \
	-openssl-linked \
	-no-sql-odbc \
	-no-cups \
	-no-iconv \
	-no-audio-backend \
	-no-multimedia \
	-no-phonon-backend \
	-no-svg \
	-no-phonon \
	-no-dbus \
	-no-gui \
	-no-declarative \
	-no-neon \
	-opengl es2 \
	-no-accessibility \
	-qpa \
	-nomake demos \
	-nomake examples \
	-nomake translations \
	-nomake tools \
	-I ${SSL_DIR}/include \
	-L ${SSL_DIR}/lib \
	-I ${XCODE_ROOT}/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator${IOS_SDK_VERSION}.sdk/System/Library/Frameworks/Security.framework/Headers \
	|| fail

	echo "-- Building Qt $QT_VERSION for i386"
	make -j$CPU_CORES_COUNT sub-src || fail

	echo "-- Installing Qt $QT_VERSION for i386"
	make install || fail

	echo "-- Stopping crazy disk usage"
	rm -rf $QT_INSTALL_DIR/doc/html
	rm -rf $QT_INSTALL_DIR/doc/src

	popd
}

pack_artifact()
{
	if [ ! -d artifact ] ; then
		mkdir artifact
	fi
	tar -czf artifact/$QT_LIB_PKG ${QT_INSTALL_DIR##*/}/bin ${QT_INSTALL_DIR##*/}/lib ${QT_INSTALL_DIR##*/}/include ${QT_INSTALL_DIR##*/}/plugins || fail
}

main()
{
	download_source
	unpack_source
	unpack_openssl
	patch_source
	build_source
	pack_artifact

	echo "-- Qt $QT_VERSION for i386 has been successfully built"
	exit 0
}

main
