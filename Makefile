DATA_DIR     = ./temp_data
INSTALL_DIR  = ./install
TARGET       = riscv32-unknown-elf
GCC_CONFIG_OPTIONS      = --enable-languages=c,c++ --with-abi=ilp32 --with-arch=rv32imc 
BINUTILS_CONFIG_OPTIONS = --disable-gold --enable-plugins --disable-werror --disable-gdb --disable-sim --disable-libdecnumber --disable-readline

TARGET_SUFFIX    = -${TARGET}
DOWNLOAD_DIR     = $(abspath ${DATA_DIR}/download)
MAKEFILE_TARGETS = $(abspath ${DATA_DIR}/make_targets)
INSTALL_PATH     = $(abspath ${INSTALL_DIR})
BUILD_DIR_TS     = $(abspath ${DATA_DIR}/build${TARGET_SUFFIX})
SYSROOT          = ${INSTALL_PATH}/${TARGET}

.PHONY: all download configure compile install

all:
	@echo "Use a target of 'download', 'configure', 'compile' or 'install'"

download: download_binutils download_gcc download_newlib
download_tidy: download_tidy_binutils download_tidy_gcc download_tidy_newlib
configure: configure_binutils configure_gcc
compile: compile_binutils compile_gcc compile_newlib compile_gcc_newlib
install: install_binutils install_gcc install_gcc_newlib

#a Templates for creating makefile variables
# mktgt
# @param $1 stage
# @param $2 reason
define mktgt
MKTGT_$1_$2 := ${MAKEFILE_TARGETS}/$1_$2
.PHONY: $1_$2
$1_$2: $$(MKTGT_$1_$2)
endef

# mktgt_ts
# @param $1 stage
# @param $2 reason
define mktgt_ts
MKTGT_TS_$1_$2 := ${MAKEFILE_TARGETS}/$1_$2${TARGET_SUFFIX}
.PHONY: $1_$2 undo_$1_$2
$1_$2: $$(MKTGT_TS_$1_$2)

undo_$1_$2:
	rm -f $$(MKTGT_TS_$1_$2)

endef

#a Download targets - not target-specific
$(foreach s,binutils_tarfile binutils gcc_tarfile gcc_untar gcc newlib,$(eval $(call mktgt,download,$s)))
$(foreach s,binutils_tarfile binutils gcc_tarfile gcc_untar gcc newlib,$(eval $(call mktgt,download_tidy,$s)))
${DOWNLOAD_DIR}/binutils-2.32.tar.bz2:
	mkdir -p ${DOWNLOAD_DIR}
	cd ${DOWNLOAD_DIR} && ( [ -f binutils-2.32.tar.bz2 ] || wget https://ftp.gnu.org/gnu/binutils/binutils-2.32.tar.bz2 )

${MKTGT_download_binutils_tarfile}: ${DOWNLOAD_DIR}/binutils-2.32.tar.bz2
	mkdir -p ${MAKEFILE_TARGETS}
	touch $@

${MKTGT_download_tidy_binutils_tarfile}:
	rm -f ${DOWNLOAD_DIR}/binutils-2.32.tar.bz2
	touch $@

${MKTGT_download_binutils}: ${MKTGT_download_binutils_tarfile}
	cd ${DOWNLOAD_DIR} && tar xf binutils-2.32.tar.bz2
	touch $@

${MKTGT_download_tidy_binutils}:
	rm -rf ${DOWNLOAD_DIR}/binutils-2.32
	touch $@

download_tidy_binutils: download_tidy_binutils_tarfile

${MKTGT_download_gcc_tarfile}: ${DOWNLOAD_DIR}/gcc-9.1.0.tar.xz
	mkdir -p ${MAKEFILE_TARGETS}
	touch $@

${MKTGT_download_tidy_gcc_tarfile}:
	rm -f ${DOWNLOAD_DIR}/gcc-9.1.0.tar.xz
	touch $@

${DOWNLOAD_DIR}/gcc-9.1.0.tar.xz:
	mkdir -p ${DOWNLOAD_DIR}
	cd ${DOWNLOAD_DIR} && ( [ -f gcc-9.1.0.tar.xz ] || wget https://ftp.gnu.org/gnu/gcc/gcc-9.1.0/gcc-9.1.0.tar.xz )

${MKTGT_download_gcc_untar}: ${MKTGT_download_gcc_tarfile}
	cd ${DOWNLOAD_DIR} && tar xf gcc-9.1.0.tar.xz
	touch $@

${MKTGT_download_tidy_gcc_untar}:
	touch $@

${MKTGT_download_gcc}: ${MKTGT_download_gcc_untar}
	cd ${DOWNLOAD_DIR}/gcc-9.1.0 && ./contrib/download_prerequisites
	touch $@

${MKTGT_download_tidy_gcc}:
	rm -rf ${DOWNLOAD_DIR}/gcc-9.1.0
	touch $@

download_tidy_gcc: download_tidy_gcc_tarfile download_tidy_gcc_untar

${DOWNLOAD_DIR}/riscv-newlib-3.1.0:
	[ -f ${DOWNLOAD_DIR}/riscv-newlib-3.1.0/.git/config ] || git clone --single-branch --depth=1 --branch=riscv-newlib-3.1.0 https://github.com/riscv/riscv-newlib.git ${DOWNLOAD_DIR}/riscv-newlib-3.1.0

${MKTGT_download_newlib}: ${DOWNLOAD_DIR}/riscv-newlib-3.1.0
	mkdir -p ${MAKEFILE_TARGETS}
	touch $@

${MKTGT_download_tidy_newlib}:
	rm -rf ${DOWNLOAD_DIR}/riscv-newlib-3.1.0
	touch $@

#a Binutils targets - target-specific
$(foreach s,clean configure compile install,$(eval $(call mktgt_ts,$s,binutils)))

${MKTGT_TS_clean_binutils}:
	rm -rf ${BUILD_DIR_TS}/binutils

${MKTGT_TS_configure_binutils}: ${MKTGT_download_binutils}
	mkdir -p ${BUILD_DIR_TS}/binutils
	cd ${BUILD_DIR_TS}/binutils && ${DOWNLOAD_DIR}/binutils-2.32/configure --prefix=${INSTALL_PATH} --target=${TARGET} ${BINUTILS_CONFIG_OPTIONS}
	touch $@

${MKTGT_TS_compile_binutils}: ${MKTGT_TS_configure_binutils}
	cd ${BUILD_DIR_TS}/binutils && make all -j10
	touch $@

${MKTGT_TS_install_binutils}: ${MKTGT_TS_compile_binutils}
	cd ${BUILD_DIR_TS}/binutils && make install
	touch $@

#a GCC targets without newlib - target-specific
$(foreach s,clean configure compile install,$(eval $(call mktgt_ts,$s,gcc)))

${MKTGT_TS_clean_gcc}:
	rm -rf ${BUILD_DIR_TS}/gcc_no_newlib

${MKTGT_TS_configure_gcc}: ${MKTGT_download_gcc} ${MKTGT_TS_install_binutils} 
	mkdir -p ${BUILD_DIR_TS}/gcc_no_newlib
	cd ${BUILD_DIR_TS}/gcc_no_newlib && ${DOWNLOAD_DIR}/gcc-9.1.0/configure --target=${TARGET} --prefix=${INSTALL_PATH} --with-sysroot=${SYSROOT} --src=${DOWNLOAD_DIR}/gcc-9.1.0/ \
		${GCC_CONFIG_OPTIONS} \
		--with-system-zlib --with-newlib  \
		--disable-shared --disable-threads --disable-libmudflap --disable-libssp --disable-libquadmath --disable-libgomp --disable-nls --disable-tm-clone-registry --disable-multilib \
		--disable-tls \
		CFLAGS_FOR_TARGET="-O2 -D_POSIX_MODE -mcmodel=medany" CXXFLAGS_FOR_TARGET="-Os -mcmodel=medany"
	touch $@

# have to mkdir $SYSROOT/usr/include as otherwise gcc fails to add the header files - bug in their build probably
${MKTGT_TS_compile_gcc}: ${MKTGT_TS_configure_gcc}
	mkdir -p ${SYSROOT}/usr/include
	cd ${BUILD_DIR_TS}/gcc_no_newlib && make all-gcc -j10
	touch $@

${MKTGT_TS_install_gcc}: ${MKTGT_TS_compile_gcc}
	cd ${BUILD_DIR_TS}/gcc_no_newlib && make install-gcc
	touch $@

#a Newlib targets - target-specific
$(foreach s,clean configure compile install,$(eval $(call mktgt_ts,$s,newlib)))

${MKTGT_TS_clean_newlib}:
	rm -rf ${BUILD_DIR_TS}/newlib

${MKTGT_TS_configure_newlib}: ${MKTGT_download_newlib} ${MKTGT_TS_install_gcc} 
	mkdir -p ${BUILD_DIR_TS}/newlib
	cd ${BUILD_DIR_TS}/newlib && PATH=${INSTALL_PATH}/bin:${PATH} ${DOWNLOAD_DIR}/riscv-newlib-3.1.0/configure --target=${TARGET} --prefix=${INSTALL_PATH} \
		--enable-newlib-io-long-double --enable-newlib-io-long-long --enable-newlib-io-c99-formats --enable-newlib-register-fini \
		CFLAGS_FOR_TARGET="-O2 -D_POSIX_MODE -mcmodel=medany" CXXFLAGS_FOR_TARGET="-Os -mcmodel=medany"
	touch $@

${MKTGT_TS_compile_newlib}: ${MKTGT_TS_configure_newlib}
	cd ${BUILD_DIR_TS}/newlib && PATH=${INSTALL_PATH}/bin:${PATH} make all -j10
	touch $@

${MKTGT_TS_install_newlib}: ${MKTGT_TS_compile_newlib}
	cd ${BUILD_DIR_TS}/newlib && PATH=${INSTALL_PATH}/bin:${PATH} make install
	touch $@

#a GCC targets with newlib - target-specific
$(foreach s,clean configure compile install,$(eval $(call mktgt_ts,$s,gcc_newlib)))

${MKTGT_TS_clean_gcc_newlib}:
	rm -rf ${BUILD_DIR_TS}/gcc_newlib

${MKTGT_TS_configure_gcc_newlib}: ${MKTGT_TS_install_newlib} 
	mkdir -p ${BUILD_DIR_TS}/gcc_newlib
	cd ${BUILD_DIR_TS}/gcc_newlib && ${DOWNLOAD_DIR}/gcc-9.1.0/configure --target=${TARGET} --prefix=${INSTALL_PATH} --with-sysroot=${SYSROOT} --src=${DOWNLOAD_DIR}/gcc-9.1.0/ \
		${GCC_CONFIG_OPTIONS} \
		--with-system-zlib --with-newlib  \
		--disable-shared --disable-threads --disable-libmudflap --disable-libssp --disable-libquadmath --disable-libgomp --disable-nls --disable-tm-clone-registry --disable-multilib \
		--enable-tls \
		--with-native-system-header-dir=/include \
		CFLAGS_FOR_TARGET="-O2 -D_POSIX_MODE -mcmodel=medany" CXXFLAGS_FOR_TARGET="-Os -mcmodel=medany"
	touch $@

${MKTGT_TS_compile_gcc_newlib}: ${MKTGT_TS_configure_gcc_newlib}
	cd ${BUILD_DIR_TS}/gcc_newlib && make all -j10
	touch $@

${MKTGT_TS_install_gcc_newlib}: ${MKTGT_TS_compile_gcc_newlib}
	cd ${BUILD_DIR_TS}/gcc_newlib && make install
	touch $@

#a Cleaning targets
all_clean:
	mkdir -p ${MAKEFILE_TARGETS}
	rm ${MAKEFILE_TARGETS}/*

clean: clean_binutils clean_gcc clean_newlib clean_gcc_newlib

