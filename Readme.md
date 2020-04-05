# Toolchains

This repository provides a makefile that is for originally for
building cross-toolchains with binutils and the GNU compiler
toolchain, including gcc and g++; originally for RISC-V.

The process of building these can be complex.

## binutils

Binutils is very simple and rarely causes issues. This requires a
download step (we wget a particular version of a binutils tar file for
stability), a configure step with the appropriate options (target,
source, destination, etc), then make to compile and install.

## gcc

Gcc is not too tricky - it requires a download, which we do here with
a wget of a tarfile, and that requires a further fetch of some
'prerequisites' which the build process requires to be stable for the
version of gcc. After the download a configure with the appropriate
options (target, source, what to build, etc) can be performed.

To make and install gcc is then a make and a make install. However,
some compiler chains will require a C run-time to operate, and that
includes gcc with thread capability and g++. This makes the process
much trickier, and requires newlib or a Linux runtime library.

Avoiding these can be done by installing *just* gcc and compiling it
without thread support

## newlib

To add a run-time library requires source for that, which must be
compiled with a cross-compiler gcc. The source used in this repository
is newlib, which seems to be quite stable (on annual releases it
seems).

Before newlib can be built, then, requires gcc. We also git clone from
https://github.com/riscv/riscv-newlib.git the stable version of
newlib, just the tip of the branch, as its download.

Then newlib can be built by configuring it, and making it. Of course
it requires the new gcc cross-compiler to be on the PATH in this
process.

## gcc, g++ with runtime library

The final step for the GNU compiler toolchain is to build and install
the languages required with the run-time library.

This is best done in a clean build directory, with a new
configuration, enabling thread support if required. Then a complete
make and install can be done; this does not require the PATH to
include the cross-compiling gcc, as it rebuild this from scratch.

# Makefile variables

## DATA_DIR - default of './temp_data'

DATA_DIR is a path to a directory (which need not exist, it will be
created) to place temporary download and build directories.

## INSTALL_DIR - default of './install'

INSTALL_DIR indicates where to install the tools that are built

## TARGET - default of riscv32-unknown-elf

TARGET is the tuple to build; it is used for the build configurations,
and for each build directory.

The build for each target is performed in a different temporary
directory, so this Makefile may be used to build many targets
independently, downloading the source only once.

## GCC_CONFIG_OPTIONS  - default of "--enable-languages=c,c++ --with-abi=ilp32 --with-arch=rv32imc"

## BINUTILS_CONFIG_OPTIONS - defaul of "--disable-gold --enable-plugins --disable-werror --disable-gdb --disable-sim --disable-libdecnumber --disable-readline"

# Makefile targets

## make download

Downloads all the required files including GCC prerequisites, and
unpacks them

## make configure_<tool>

Configures the tool. Note that anything except binutils configure
requires binutils to be installed - and newlib configure requires the
gcc to be installed.

## make compile_<tool>

Runs make for the tool; this will build *only* the tool itself.

## make install_<tool>

Runs make install for the tool.

## make clean_<tool>

Removes the temporary build directory for the tool (but not the
download files)

## make undo_<stage>_<tool>

Removes the make stampfile for the stage and tool; the use for this is
generally in conjunction with a make clean_<tool> to redo a tool
build, when debugging the build system.



