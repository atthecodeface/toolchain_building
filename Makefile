DATA_DIR     = .
INSTALL_DIR  = .
TARGET       = riscv32-unknown-elf
GCC_CONFIG_OPTIONS      = --with-abi=ilp32  --with-arch=rv32imc --enable-languages=c --disable-libssp 
BINUTILS_CONFIG_OPTIONS = --disable-gold --enable-plugins --disable-werror --disable-gdb --disable-sim --disable-libdecnumber --disable-readline


TARGET_SUFFIX    = -${TARGET}
DOWNLOAD_DIR     = $(abspath ${DATA_DIR}/download)
MAKEFILE_TARGETS = $(abspath ${DATA_DIR}/make_targets)
INSTALL_PATH     = $(abspath ${INSTALL_DIR})
BUILD_DIR_TS     = $(abspath ${DATA_DIR}/build${TARGET_SUFFIX})

.PHONY: all download configure compile install

all:
	@echo "Use a target of 'download', 'configure', 'compile' or 'install'"

download: download_binutils download_gcc
configure: configure_binutils configure_gcc
compile: compile_binutils compile_gcc
install: install_binutils install_gcc

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
.PHONY: $1_$2
$1_$2: $$(MKTGT_TS_$1_$2)
endef

#a Download targets - not target-specific
$(foreach s,binutils_tarfile binutils gcc_tarfile gcc_untar gcc,$(eval $(call mktgt,download,$s)))
${MKTGT_download_gcc_tarfile}: ${DOWNLOAD_DIR}/gcc-9.1.0.tar.xz
	mkdir -p ${MAKEFILE_TARGETS}
	touch $@

${DOWNLOAD_DIR}/gcc-9.1.0.tar.xz:
	mkdir -p ${DOWNLOAD_DIR}
	cd ${DOWNLOAD_DIR} && ( [ -f gcc-9.1.0.tar.xz ] || wget https://ftp.gnu.org/gnu/gcc/gcc-9.1.0/gcc-9.1.0.tar.xz )

${MKTGT_download_gcc_untar}: ${MKTGT_download_gcc_tarfile}
	cd ${DOWNLOAD_DIR} && tar xf gcc-9.1.0.tar.xz
	touch $@

${MKTGT_download_gcc}: ${MKTGT_download_gcc_untar}
	cd ${DOWNLOAD_DIR}/gcc-9.1.0 && ./contrib/download_prerequisites
	touch $@

${DOWNLOAD_DIR}/binutils-2.32.tar.bz2:
	mkdir -p ${DOWNLOAD_DIR}
	cd ${DOWNLOAD_DIR} && ( [ -f binutils-2.32.tar.bz2 ] || wget https://ftp.gnu.org/gnu/binutils/binutils-2.32.tar.bz2 )

${MKTGT_download_binutils_tarfile}: ${DOWNLOAD_DIR}/binutils-2.32.tar.bz2
	mkdir -p ${MAKEFILE_TARGETS}
	touch $@

${MKTGT_download_binutils}: ${MKTGT_download_binutils_tarfile}
	cd ${DOWNLOAD_DIR} && tar xf binutils-2.32.tar.bz2
	touch $@

#a Configure targets - target-specific
$(foreach s,binutils gcc,$(eval $(call mktgt_ts,configure,$s)))

${MKTGT_TS_configure_binutils}: ${MKTGT_download_binutils}
	mkdir -p ${BUILD_DIR_TS}/binutils
	cd ${BUILD_DIR_TS}/binutils && ${DOWNLOAD_DIR}/binutils-2.32/configure --prefix=${INSTALL_PATH} --target=${TARGET} ${BINUTILS_CONFIG_OPTIONS}
	touch $@

${MKTGT_TS_configure_gcc}: ${MKTGT_download_gcc} ${MKTGT_TS_install_binutils} 
	mkdir -p ${BUILD_DIR_TS}/gcc
	cd ${BUILD_DIR_TS}/gcc && ${DOWNLOAD_DIR}/gcc-9.1.0/configure --prefix=${INSTALL_PATH} --target=${TARGET} ${GCC_CONFIG_OPTIONS}
	touch $@

#a Compile targets - target-specific
$(foreach s,binutils gcc,$(eval $(call mktgt_ts,compile,$s)))

${MKTGT_TS_compile_binutils}: ${MKTGT_TS_configure_binutils}
	cd ${BUILD_DIR_TS}/binutils && make all -j10
	touch $@

${MKTGT_TS_compile_gcc}: ${MKTGT_TS_configure_gcc}
	cd ${BUILD_DIR_TS}/gcc && make all -j10
	touch $@

#a Install targets - target-specific
$(foreach s,binutils gcc,$(eval $(call mktgt_ts,install,$s)))

${MKTGT_TS_install_binutils}: ${MKTGT_TS_compile_binutils}
	cd ${BUILD_DIR_TS}/binutils && make install
	touch $@

${MKTGT_TS_install_gcc}: ${MKTGT_TS_compile_gcc}
	cd ${BUILD_DIR_TS}/gcc && make install
	touch $@

#a Cleaning targets
all_clean:
	mkdir -p ${MAKEFILE_TARGETS}
	rm ${MAKEFILE_TARGETS}/*
