@set MSVC_VERSION=2010
@set PLATFORM=win32-msvc%MSVC_VERSION%
@set QT_VERSION=4.8.4
@set QT_SOURCE_DIR=qt-everywhere-opensource-src-%QT_VERSION%
@set QT_SOURCE_PKG=qt-everywhere-opensource-src-%QT_VERSION%.tar.gz
@set QT_LIB_PKG=qt-windows-%QT_VERSION%.tar.gz
@set QT_INSTALL_DIR=%PWD%


@call :setup_environment || @goto end
@call :download_source || @goto end
@call :unpack_source || @goto end

@pushd %QT_INSTALL_DIR%/src
@call :patch_source || @goto end
@call :build_source || @goto end
@popd

@call :pack_artifact

@echo -- Qt %QT_VERSION% has been successfully built
@goto end
@REM -----------------------------------------------------------------------


@REM ---[ Setup Environment ]---
:setup_environment
	@if %MSVC_VERSION% == 2008 (
		@call "%VS90COMNTOOLS%\vsvars32.bat"
	) else (
		@call "%VS100COMNTOOLS%\vsvars32.bat"
	)
	@exit /B 0


@REM ---------------------------------
@REM ---[ Download Sources         ]--
@REM ---[ pls note curl dependency ]--
:download_source
	@if not exist %QT_SOURCE_PKG% (
		@echo -- Downloading Qt %QT_VERSION% sources
		@curl -L http://releases.qt-project.org/qt4/source/%QT_SOURCE_PKG% --O %QT_SOURCE_PKG% || @call :fail
	)
	@exit /B 0


@REM ---------------------------------
@REM ---[ Unpack Sources          ]---
@REM ---[ pls note tar dependency ]---
:unpack_source
	@echo -- Unpacking Qt %QT_VERSION% sources
	@tar -xzf %QT_SOURCE_PKG% || @call :fail
	@mv %QT_SOURCE_DIR% %QT_INSTALL_DIR%/src
	@exit /B 0



@REM -----------------------------------
@REM ---[ Unpack Sources            ]---
@REM ---[ pls note patch dependency ]---
:patch_source
	@patch -p1 < patches/windows/qt_release_pdbs_%MSVC_VERSION%.patch || @call :fail
	@exit /B 0


@REM ---------------------------------
@REM ---[ Build Sources           ]---
:build_source
	@echo -- Configuring Qt %QT_VERSION%
	@configure.exe ^
		-confirm-license ^
		-opensource ^
		-prefix %QT_INSTALL_DIR% ^
		-release ^
		-platform %PLATFORM% ^
		-arch x86 ^
		-static ^
		-fast ^
		-silent ^
		-no-exceptions ^
		-no-stl ^
		-no-qt3support ^
		-no-webkit ^
		-no-audio-backend ^
		-no-multimedia ^
		-no-phonon-backend ^
		-no-phonon ^
		-no-dbus ^
		-no-accessibility ^
		-nomake demos ^
		-nomake examples ^
		-nomake translations ^
		-nomake tools ^
		|| @call :fail

	@echo -- Building Qt %QT_VERSION%
	@nmake || @call :fail

	@echo -- Installing Qt %QT_VERSION%
	@nmake install || @call :fail

	@echo -- Stopping crazy disk usage
	@rm -rf %QT_INSTALL_DIR%/doc/html
	@rm -rf %QT_INSTALL_DIR%/doc/src
	@exit /B 0

@REM ---------------------------------
@REM ---[ Pack Artifact           ]---
:pack_artifact
	@if not exist artifact (
		@mkdir artifact
	)
	@echo -- FIXME: I can't pack artifact yet :(
	@REM @tar -czf artifact/$QT_LIB_PKG ../${QT_INSTALL_DIR##*/}/bin ../${QT_INSTALL_DIR##*/}/lib ../${QT_INSTALL_DIR##*/}/include ../${QT_INSTALL_DIR##*/}/plugins || fail


@REM ---[ Failure ]---
:fail
	@echo -- Qt %QT_VERSION% build failed
	@exit /B 1

:end