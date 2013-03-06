@echo off

@set MSVC_VERSION=2010
@set PLATFORM=win32-msvc%MSVC_VERSION%
@set QT_VERSION=4.8.4
@set QT_SOURCE_DIR=qt-everywhere-opensource-src-%QT_VERSION%
@set QT_SOURCE_PKG=qt-everywhere-opensource-src-%QT_VERSION%.zip
@set QT_LIB_PKG=qt-windows-%QT_VERSION%.tar.bz
@set QT_INSTALL_DIR=%CD%
@set PATCHES_DIR=patches\windows
@set BUILD_TYPE=debug
@set INSTALL_DIR=%CD%
@set _=%CD%

if "%1%"=="release" @set BUILD_TYPE=release
if "%1%"=="debug-and-release" @set BUILD_TYPE=debug-and-release

@if "%2%"=="2008" @set MSVC_VERSION=2008

@call :print_info

call :setup_environment_if_need

if exist %QT_SOURCE_DIR% goto Build

if exist %QT_SOURCE_PKG% goto Unpack

:Download
echo -- Downloading Qt %QT_VERSION% ...
curl -L http://releases.qt-project.org/qt4/source/%QT_SOURCE_PKG% --O %QT_SOURCE_PKG% || goto error

:Unpack
echo -- Unpacking ...
@unzip -qq -o %QT_SOURCE_PKG%

:Patch
echo -- Patching ...
patch --verbose -p0 < %PATCHES_DIR%\qt_release_pdbs_vc9.patch    || goto error
patch --verbose -p0 < %PATCHES_DIR%\qt_release_pdbs_vc10.patch   || goto error
patch --verbose -p0 < %PATCHES_DIR%\qlocalserver.patch           || goto error
patch --verbose -p0 < %PATCHES_DIR%\qlocalsocket.patch           || goto error

:Build
echo -- Building %BUILD_TYPE% build ...
cd %QT_SOURCE_DIR%
mkdir -p %INSTALL_DIR%

::-openssl-linked ^
::-graphicssystem opengl
::-D -I
::-L -l
::-system-proxies
configure ^
	-platform win32-msvc%MSVC_VERSION% ^
	-confirm-license ^
	-%BUILD_TYPE% ^
	-opensource ^
	-static ^
	-mp ^
	^
	-rtti ^
    -mmx ^
	-3dnow ^
	-sse ^
	-sse2 ^
	-fast ^
	-stl ^
	-exceptions ^
	^
	-qt-zlib ^
	-qt-libpng ^
	-qt-libmng ^
	-qt-libjpeg ^
	-declarative ^
	-declarative-debug ^
	-script ^
	-scripttools ^
	^
	-no-libtiff ^
	-no-accessibility ^
    -no-qt3support ^
    -no-dsp ^
	-no-vcproj ^
	-no-incredibuild-xge ^
	-no-ltcg ^
    -no-webkit ^
	-no-openvg ^
	-no-style-cleanlooks ^
    -no-style-cde ^
	-no-dbus ^
    -nomake demos ^
	-nomake examples ^
	-nomake translations ^
	-no-xmlpatterns ^
    -no-multimedia ^
	-no-audio-backend ^
	-no-phonon ^
	-no-phonon-backend ^
	-no-style-motif ^
	-no-s60 ^
    || goto error

nmake || goto error
nmake install || goto error
cd %_%
echo -- QT build done!

:TearDown
@echo -- Stopping crazy disk usage
@rm -rf %QT_INSTALL_DIR%\doc\html
@rm -rf %QT_INSTALL_DIR%\doc\src

:Archive
echo -- Packaging ...
@if not exist %QT_INSTALL_DIR%\artifact (
	@mkdir %QT_INSTALL_DIR%\artifact
)
cd %QT_SOURCE_DIR%
tar -czvf artifact\%QT_LIB_PKG% bin lib include plugins
cd %_%

:Done
echo -- Everything is done! Artifact is in %QT_INSTALL_DIR%\artifact\%QT_LIB_PKG%
exit /B 0


:: --- Helpers

:print_info
	@echo -- Build type is %BUILD_TYPE%
	@echo -- MSVC version: %MSVC_VERSION%
	exit /B 0

:setup_environment_if_need
	@if not "%ENVIRONMENT_DONE%" == "OK" (
		@echo -- Setting up MSVC environment
		@call :setup_environment
		@set ENVIRONMENT_DONE=OK
	)
	@exit /B 0

:setup_environment
	@if %MSVC_VERSION% == 2008 (
		@call "%VS90COMNTOOLS%\vsvars32.bat"
	) else (
		@call "%VS100COMNTOOLS%\vsvars32.bat"
	)
	@exit /B 0

:error
cd %_%
echo -- Qt build FAILED
exit /B 1

:env_error
echo Environment variable OPEN_LIBS is not found
exit /B 1
