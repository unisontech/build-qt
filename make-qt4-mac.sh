#!/bin/bash

# 1. mkdir ~/devel/qt4
# 2. pushd ~/devel/qt4
# 3. ~/devel/build-qt/make-qt4-mac.sh
# 4. drink beer

QT_VERSION="4.8.4"
QT_SOURCE_DIR="qt-everywhere-opensource-src-$QT_VERSION"
QT_SOURCE_PKG="qt-everywhere-opensource-src-$QT_VERSION.tar.gz"
QT_LIB_PKG="qt-mac-$QT_VERSION.tar.gz"
QT_INSTALL_DIR=$PWD/qt
CPU_CORES_COUNT=$(expr $(sysctl -A 2>&1 |grep 'hw\.ncpu:' |sed "s/^hw\.ncpu: \([0-9]*\)/\1/") + 1)

fail()
{
	echo "-- Qt $QT_VERSION build failed"
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
	# FIX for clang
	sed -i "" -e "s/::TabletProximityRec/TabletProximityRec/g" $QT_INSTALL_DIR/src/gui/kernel/qt_cocoa_helpers_mac_p.h
}

build_source()
{
	echo "-- Configuring Qt $QT_VERSION"
	./configure \
		-confirm-license \
		-opensource \
		-prefix $QT_INSTALL_DIR \
		-release \
		-platform unsupported/macx-clang \
		-arch x86_64 \
		-static \
		-fast \
		-silent \
		-no-exceptions \
		-no-stl \
		-no-qt3support \
		-no-webkit \
		-no-audio-backend \
		-no-multimedia \
		-no-phonon-backend \
		-no-phonon \
		-no-dbus \
		-no-accessibility \
		-nomake demos \
		-nomake examples \
		-nomake translations \
		-nomake tools \
		|| fail

	echo "-- Building Qt $QT_VERSION"
	make -j$CPU_CORES_COUNT sub-src || fail

	echo "-- Installing Qt $QT_VERSION"
	make install || fail

	find $QT_INSTALL_DIR/mkspecs/macx-* -name Info.plist.app -print0 | xargs -0 sed -i "" 's/com.yourcompany./com.unison./g' || fail

	# qt_menu.nib is mandatory for mac
	mkdir -p $QT_INSTALL_DIR/lib/Resources
	cp -R src/gui/mac/qt_menu.nib $QT_INSTALL_DIR/lib/Resources || fail

	echo "-- Stopping crazy disk usage"
	rm -rf $QT_INSTALL_DIR/doc/html
	rm -rf $QT_INSTALL_DIR/doc/src
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

	pushd $QT_INSTALL_DIR
	build_source
	popd
	
	pack_artifact

	echo "-- Qt $QT_VERSION has been successfully built"
	exit 0
}

main
