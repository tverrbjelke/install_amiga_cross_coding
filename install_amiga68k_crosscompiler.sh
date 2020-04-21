#!/usr/bin/env bash
# Script installs amiga cross compiling toolchain into users home.
# focues on target platform: amiga 68000 Kickstart/WB 1.3 and 2.x/3.x
# tested for debian stretch and debian buster on amd64
# installing vbcc 0.9g + current version of vasm, vlink
# -- tverrbjelke@gmx.de at 21th April 2020
#
# make use and change as you like

USAGE="\
Usage
-----
$0 <RESOURCES_PATH> [BINARY_PATH] 
 
 - RESOURCES_PATH is a temporary folder to download and unpack stuff

 - BINARY_PATH is where all is copied and patched, 
   and where the system environment shall points to. 

   defaults to \${HOME}/.local/bin/
   
 - finally all needed export calls are gathered into RESOURCES_PATH/set_environment.sh
   You just may source it at startup.

inspired by (Cross Development for the Amiga with VBCC Wei-ju Wu (2016))[https://www.youtube.com/watch?v=vFV0oEyY92I]
see also http://sun.hasenbraten.de/vbcc/ and related tools.

Toolchain
---------
vbcc, C-Compiler ISO/IEC 9899:1989 and a subset of the new standard ISO/IEC 9899:1999 (C99)
vlink (linker)
vasm (assembler)
Maybe you also need Amiga System headers and resources
https://www.haage-partner.de/download/AmigaOS/NDK39.lha

You already set up an (FS-UAE?) emulator with shared volume
where the build binaries are put and executed inside emulation.

"   
_CWD=$(pwd)

if [[ "$#" < "1" ]]
then 
    echo "$USAGE"
    exit 1
fi

###########################
# Configure this:
###########################

# Resources path is a temporary playe to download and unpack stuff
RESOURCES_PATH=$1
# Here the toolchain will get copied to.
# make sure we have absolute path and it exists.
if [[ -z $2 ]]
then
    BINARY_PATH="${HOME}/.local/bin/"
else
    BINARY_PATH=$2
fi
BINARY_PATH=$(mkdir -p ${BINARY_PATH} && cd ${BINARY_PATH} && pwd)
echo "using BINARY_PATH=${BINARY_PATH}"

DOWNLOAD_PATH="${RESOURCES_PATH}/download/vbcc_tools"
if [[ ! -d "${DOWNLOAD_PATH:+$DOWNLOAD_PATH/}" ]]
then
    mkdir -p "${DOWNLOAD_PATH}"
fi
DOWNLOAD_PATH=$(cd ${DOWNLOAD_PATH} && pwd)
echo "using DOWNLOAD_PATH=${DOWNLOAD_PATH}"

FOR_TARGET_1_3="TRUE" # please here just either of one

# you may add  for WB2.x/3.x target platform, too
DOWNLOAD_ARCHIVES="\
http://phoenix.owl.de/tags/vbcc0_9g.tar.gz \
http://phoenix.owl.de/vbcc/2019-10-04/vbcc_target_m68k-kick13.lha \
http://phoenix.owl.de/vbcc/2019-10-04/vbcc_target_m68k-amigaos.lha \
http://phoenix.owl.de/vbcc/2019-10-04/vbcc_unix_config.tar.gz \
http://phoenix.owl.de/vbcc/docs/vbcc.pdf \
http://sun.hasenbraten.de/vlink/release/vlink.tar.gz \
http://sun.hasenbraten.de/vlink/release/vlink.pdf \
http://sun.hasenbraten.de/vasm/release/vasm.tar.gz \
http://sun.hasenbraten.de/vasm/release/vasm.pdf \
https://www.haage-partner.de/download/AmigaOS/NDK39.lha "

# prerequisites
PREREQ="build-essential wget lhasa"
NEED_INSTALL=""
for PACKAGE in ${PREREQ}
do
    is_installed=$(dpkg-query -W -f='${Status}' ${PACKAGE} | grep "ok installed")
    if [[ ! $is_installed ]]
    then
	echo $PACKAGE needs installation
	NEED_INSTALL="$NEED_INSTALL ${PACKAGE}"
	# sudo apt install ${PACKAGE}
    fi
done

if [[ ! -z ${NEED_INSTALL} ]]
then
    echo "need (at least, please re-check if something is mising) to install packages ${NEED_INSTALL}"
    echo sudo apt install ${NEED_INSTALL}
    sudo apt install ${NEED_INSTALL}
fi
   

################################################
echo "Fetching files from this this web archives: ${DOWNLOAD_ARCHIVES}"
cd "${DOWNLOAD_PATH}"

# here we have the situation that we fetch the "recent release" version
# and store it without specific version information.
# With new release versions coming,
# we cannot see this by just checking for already existing local files -
# they might belong to an older version.
# so it might be better to actually delete all existing files first.
# best solution wouldbe to actually store as the version-named files.
# @todo ask frank to change target file names for releases on his website
# to be saved as proper version-named file.
for URL in ${DOWNLOAD_ARCHIVES}
do
    f=$(basename "${URL}")
    if [[ ! -f "${f}" ]]
    then
	# echo "fetching file <${f}> from url <${URL}>"
	wget "$URL" -O "${f}"
    else
	echo "file <${f}> already downloaded, maybe check your local versions against <${URL}>"
    fi
done
	 
# expect all files now ready...

#####################
# vbcc
mkdir -p "${BINARY_PATH}/amiga_sdk/vbcc" # installation directory

# vbcc_tools
cd "${DOWNLOAD_PATH}"
tar -xf vbcc0_9fP1.tar.gz
cd vbcc
mkdir -p bin
echo "A lot of questions which you all want to be the default"
echo "#######################################################"
make TARGET=m68k

echo cp -r "${DOWNLOAD_PATH}/vbcc/bin" "${BINARY_PATH}/amiga_sdk/vbcc"
cp -r "${DOWNLOAD_PATH}/vbcc/bin" "${BINARY_PATH}/amiga_sdk/vbcc"

# include and lib of target platform
# which can be 1.3 or 2.x/3.x (as I understand: "only either one", but thats not certain)
cd "${DOWNLOAD_PATH}" #only want the *specific* files (not all) in target dir
if [[ ${FOR_TARGET_1_3} == "TRUE" ]]
then 
    lha x vbcc_target_m68k-kick13.lha # for 1.3
    cp -r vbcc_target_m68k-kick13/* "${BINARY_PATH}/amiga_sdk/vbcc"
          
else
    lha x vbcc_target_m68k-amigaos.lha #for 2.x/3.x
    cp -r vbcc_target_m68k-amigaos/* "${BINARY_PATH}/amiga_sdk/vbcc"
fi

echo "Apply service patches (already in source tarball)"
cd "${BINARY_PATH}/amiga_sdk/vbcc"
echo  "... none"

echo "Apply target configuration file for unix (PATH style NOT amigados style)"
cd "${BINARY_PATH}/amiga_sdk/vbcc"
tar -xf "${DOWNLOAD_PATH}/vbcc_unix_config.tar.gz"

# add vbcc to path
VBCC_tmp="${BINARY_PATH}/amiga_sdk/vbcc"
if [[ -z "${VBCC}" ]] 
then
    echo "export VBCC=${VBCC_tmp}"
    export VBCC=${VBCC_tmp}
else
    if [[ "${VBCC}" == "${VBCC_tmp}" ]]
    then 
        echo "${VBCC_tmp} was already exported properly, nothing to do."
    else
        echo "Warning, overwriting a *different* old definition of ${VBCC} with new definition ${VBCC_tmp}"
        echo "export VBCC=${VBCC_tmp}"
        export VBCC="${VBCC_tmp}"
    fi
fi
# to path:
if [[ -z "$(echo ${PATH} | grep ${VBCC}/bin)" ]] 
then 
    export PATH=${VBCC/bin}:${PATH}
fi

#####################
# vasm

cd "${DOWNLOAD_PATH}"
tar -xf vasm.tar.gz
cd vasm
# desired target is native (emulated 68000)
# desired syntax of assembly is "motorola style"
# needs vbcc in PATH
make CPU=m68k SYNTAX=mot
cp vasmm68k_mot vobjdump ${VBCC}/bin/

#####################
# vlink
cd "${DOWNLOAD_PATH}"
tar -xf vlink.tar.gz
cd vlink
mkdir -p objects
make # needs vbcc in PATH
cp vlink ${VBCC}/bin/


#####################
# NDK3.9 resources
# ${NDK_INC} points to the C-header files for amigaos development
# The assembler includes are in ${NDK_INC}/../include_i 
# todo find a better place for this NDK
cd "${BINARY_PATH}/amiga_sdk/"
lha x "${DOWNLOAD_PATH}/NDK39.lha"

NDK_INC_tmp="${BINARY_PATH}/amiga_sdk/NDK_3.9/Include/include_h"
export NDK_INC=$( cd "${NDK_INC_tmp}" && pwd -P )

# manually integrate into login procedure:
ENV_PATCH=${BINARY_PATH}/set_vbcc_environment.sh
rm -f ${ENV_PATCH}
echo "add this to your .bashrc .profile or whatnot:"
echo "or just "
echo "source ${ENV_PATCH}"
rm -f ${ENV_PATCH}
echo "VBCC_tmp=\"${BINARY_PATH}/amiga_sdk/vbcc\""|tee -a ${ENV_PATCH}
echo 'if [[ -z "${VBCC}" ]]' |tee -a ${ENV_PATCH}
echo 'then'|tee -a ${ENV_PATCH}
echo '    echo "export VBCC=${VBCC_tmp}"'|tee -a ${ENV_PATCH}
echo '    export VBCC=${VBCC_tmp}'|tee -a ${ENV_PATCH}
echo 'else'|tee -a ${ENV_PATCH}
echo '    if [[ "${VBCC}" == "${VBCC_tmp}" ]]'|tee -a ${ENV_PATCH}
echo '    then' |tee -a ${ENV_PATCH} 
echo '        echo "${VBCC_tmp} was already exported properly, nothing to do."'|tee -a ${ENV_PATCH}
echo '    else'|tee -a ${ENV_PATCH}
echo '        echo "Warning, overwriting a *different* old definition of ${VBCC} with new definition ${VBCC_tmp}"'|tee -a ${ENV_PATCH}
echo '        echo "export VBCC=${VBCC_tmp}"'|tee -a ${ENV_PATCH}
echo '        export VBCC="${VBCC_tmp}"'|tee -a ${ENV_PATCH}
echo '    fi'|tee -a ${ENV_PATCH}
echo 'fi'|tee -a ${ENV_PATCH}
echo '# to path:'|tee -a ${ENV_PATCH}
echo 'if [[ -z "$(echo ${PATH} | grep ${VBCC})" ]]'|tee -a ${ENV_PATCH}
echo 'then'|tee -a ${ENV_PATCH}
echo '    export PATH=${VBCC}/bin:${PATH}'|tee -a ${ENV_PATCH}
echo 'fi'|tee -a ${ENV_PATCH}

echo |tee -a ${ENV_PATCH}
echo "export NDK_INC=\"${NDK_INC}\""| tee -a ${ENV_PATCH}
chmod u+x ${ENV_PATCH}
