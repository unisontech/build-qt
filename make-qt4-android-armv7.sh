#!/bin/bash

# 1. mkdir ~/devel/qt4
# 2. pushd ~/devel/qt4
# 3. ~/devel/build-qt/make-qt4-android.sh
# 4. drink beer

SOURCE_FORMAT="tar"
UNTAR_KEYS="xf"
QT_BRANCH="beta2"
QT_VERSION="4.8.2"
QT_SOURCE_DIR="src"
QT_SOURCE_PKG="$PWD/qt-necessitas-$QT_BRANCH.${SOURCE_FORMAT}"
QT_LIB_PKG="qt-android-$QT_VERSION-armv7.tar.gz"
QT_INSTALL_DIR=$PWD
CPU_CORES_COUNT=$(expr $(sysctl -A 2>&1 |grep 'hw\.ncpu:' |sed "s/^hw\.ncpu: \([0-9]*\)/\1/") + 1)

fail()
{
	echo "-- Qt $QT_VERSION build failed"
	popd
	exit 1
}

download_source()
{
	if [[ $1 == "-f" || ! -f $QT_SOURCE_PKG ]] ; then
		echo "-- Downloading Qt $QT_VERSION sources"
		git archive -v --format=${SOURCE_FORMAT} -o${QT_SOURCE_PKG} --remote=git://anongit.kde.org/android-qt.git ${QT_BRANCH} || fail
	fi
}

unpack_source()
{
	echo "-- Unpacking Qt $QT_VERSION sources"
        rm -rf src
	mkdir -p src
	pushd src
	echo "tar -xzpf $QT_SOURCE_PKG"
	tar -${UNTAR_KEYS} $QT_SOURCE_PKG || download_source -f && tar -${UNTAR_KEYS} $QT_SOURCE_PKG || fail
	popd
}

patch_source()
{
	# Extracting
	rm -rf ${QT_BUILD_DIR}
	tar xjf ${QT_SOURCES_PKG}

	PATCHES_DIR=patches/android
	# Add STL support (-lgnustl_static, -DQT_NO_STL_WCHAR - Android NDK doesn't support std::wstring)
	#patch -d $QT_BUILD_DIR -p1 < patches-android/android-lighthouse-unison.patch
	#FIXME: Create a patch
	cp $PATCHES_DIR/qmake-r8b.conf android-lighthouse/mkspecs/android-g++/qmake.conf

	patch -d $QT_BUILD_DIR -p1 < $PATCHES_DIR/idogadaev-ios-corelib-patches.patch
	patch -d $QT_BUILD_DIR -p1 < $PATCHES_DIR/idogadaev-ios-gui-patches.patch
	patch -d $QT_BUILD_DIR -p1 < $PATCHES_DIR/androidconfigbuild.sh.patch
	patch -d $QT_BUILD_DIR -p1 < $PATCHES_DIR/disable-android-plugins.patch

}

build_source()
{
	# Build and install
	DEBUG=0
	ANDROID_API_LEVEL=8
	NDK_TOOLCHAIN_VERSION=4.6
	echo "Building Qt..."
	# Options:
	# -q 1 - Configure qt and compile qt
	# -d 1 - Build debug qt
	# -x 1 - Use exceptions
	# -l 9 - Android API 9 (2.3) / API 8 (2.2)
	# -h 0 - Build static version of qt
	# -k 1 - Install Qt
	# -i <folder> - Install Qt to <folder>
	# -v 4.4.3. - NDK toolchain version
	android/androidconfigbuild.sh -n $ANDROID_NDK -q 1 -d $DEBUG -x 1 -l $ANDROID_API_LEVEL -h 0 -k 1 -i $QT_INSTALL_DIR -v $NDK_TOOLCHAIN_VERSION || fail

	echo "-- Stopping crazy disk usage"
	rm -rf $QT_INSTALL_DIR/doc/html
	rm -rf $QT_INSTALL_DIR/doc/src

}

pack_artifact()
{
	if [ ! -d artifact ] ; then
		mkdir artifact
	fi
	tar -czf artifact/$QT_LIB_PKG ../${QT_INSTALL_DIR##*/}/bin ../${QT_INSTALL_DIR##*/}/lib ../${QT_INSTALL_DIR##*/}/include ../${QT_INSTALL_DIR##*/}/plugins || fail
}

main()
{
	download_source
	unpack_source
	patch_source

	pushd $QT_INSTALL_DIR/src
	build_source
	popd

	pack_artifact

	echo "-- Qt $QT_VERSION has been successfully built"
	exit 0
}

main
