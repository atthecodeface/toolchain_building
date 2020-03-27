DATA_DIR     = .
INSTALL_DIR  = .
BUILD_DIR    = $(abspath ${DATA_DIR}/build)
DOWNLOAD_DIR = $(abspath ${DATA_DIR}/download)
MAKEFILE_TARGETS = $(abspath ${DATA_DIR}/make_targets)
INSTALL_PATH = $(abspath ${INSTALL_DIR})

.PHONY: all download configure compile install

all:
	@echo "Use a target of 'download', 'configure', 'compile' or 'install'"

download: download_binutils download_gcc
configure: configure_binutils configure_gcc
compile: compile_binutils compile_gcc
install: install_binutils install_gcc

.PHONY: download_gcc download_binutils
download_gcc: ${MAKEFILE_TARGETS}/download_gcc_prerequisites
download_binutils: ${MAKEFILE_TARGETS}/download_untar_binutils


.PHONY: configure_gcc configure_binutils
configure_gcc: ${MAKEFILE_TARGETS}/configure_gcc
configure_binutils: ${MAKEFILE_TARGETS}/configure_binutils


.PHONY: compile_gcc compile_binutils
compile_gcc: ${MAKEFILE_TARGETS}/compile_gcc
compile_binutils: ${MAKEFILE_TARGETS}/compile_binutils

.PHONY: install_gcc install_binutils
install_gcc: ${MAKEFILE_TARGETS}/install_gcc
install_binutils: ${MAKEFILE_TARGETS}/install_binutils

${MAKEFILE_TARGETS}/download_gcc:
	mkdir -p ${MAKEFILE_TARGETS}
	mkdir -p ${DOWNLOAD_DIR}
	cd ${DOWNLOAD_DIR} && ( [ -f gcc-9.1.0.tar.xz ] || wget https://ftp.gnu.org/gnu/gcc/gcc-9.1.0/gcc-9.1.0.tar.xz )
	touch ${MAKEFILE_TARGETS}/download_gcc

${MAKEFILE_TARGETS}/download_binutils:
	mkdir -p ${MAKEFILE_TARGETS}
	mkdir -p ${DOWNLOAD_DIR}
	cd ${DOWNLOAD_DIR} && ( [ -f binutils-2.32.tar.bz2 ] || wget https://ftp.gnu.org/gnu/binutils/binutils-2.32.tar.bz2 )
	touch ${MAKEFILE_TARGETS}/download_binutils

${MAKEFILE_TARGETS}/download_untar_gcc: ${MAKEFILE_TARGETS}/download_gcc
	cd ${DOWNLOAD_DIR} && tar xf gcc-9.1.0.tar.xz
	touch ${MAKEFILE_TARGETS}/download_untar_gcc

${MAKEFILE_TARGETS}/download_untar_binutils: ${MAKEFILE_TARGETS}/download_binutils
	cd ${DOWNLOAD_DIR} && tar xf binutils-2.32.tar.bz2
	touch ${MAKEFILE_TARGETS}/download_untar_binutils

${MAKEFILE_TARGETS}/download_gcc_prerequisites: ${MAKEFILE_TARGETS}/download_untar_gcc
	cd ${DOWNLOAD_DIR}/gcc-9.1.0 && ./contrib/download_prerequisites
	touch ${MAKEFILE_TARGETS}/download_gcc_prerequisites

${MAKEFILE_TARGETS}/configure_gcc: ${MAKEFILE_TARGETS}/download_gcc_prerequisites
	mkdir -p ${BUILD_DIR}/gcc
	cd ${BUILD_DIR}/gcc && ${DOWNLOAD_DIR}/gcc-9.1.0/configure --prefix=${INSTALL_PATH} --enable-languages=c --target=riscv32-elf --disable-libssp
	touch ${MAKEFILE_TARGETS}/configure_gcc

${MAKEFILE_TARGETS}/configure_binutils: ${MAKEFILE_TARGETS}/download_untar_binutils
	mkdir -p ${BUILD_DIR}/binutils
	cd ${BUILD_DIR}/binutils && ${DOWNLOAD_DIR}/binutils-2.32/configure --prefix=${INSTALL_PATH} --target=riscv32-elf --disable-gold --enable-plugins
	touch ${MAKEFILE_TARGETS}/configure_binutils

${MAKEFILE_TARGETS}/compile_binutils: ${MAKEFILE_TARGETS}/configure_binutils
	cd ${BUILD_DIR}/binutils && make all -j10
	touch ${MAKEFILE_TARGETS}/compile_binutils

${MAKEFILE_TARGETS}/compile_gcc: ${MAKEFILE_TARGETS}/install_binutils ${MAKEFILE_TARGETS}/configure_gcc
	cd ${BUILD_DIR}/gcc && make all
	touch ${MAKEFILE_TARGETS}/compile_gcc

${MAKEFILE_TARGETS}/install_binutils: ${MAKEFILE_TARGETS}/compile_binutils
	cd ${BUILD_DIR}/binutils && make install
	touch ${MAKEFILE_TARGETS}/install_binutils

${MAKEFILE_TARGETS}/install_gcc: ${MAKEFILE_TARGETS}/compile_gcc
	cd ${BUILD_DIR}/gcc && make install
	touch ${MAKEFILE_TARGETS}/install_gcc

all_clean:
	mkdir -p ${MAKEFILE_TARGETS}
	rm ${MAKEFILE_TARGETS}/*
