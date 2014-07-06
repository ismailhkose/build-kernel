#!/bin/bash

#    Copyright (C) 2014  Charles Fryett (BlueEther)
#    
#    blueether@fryett.net
#
#    Copyleft (C) 2013  Louis Teboul (a.k.a Androguide)
#
#    admin@pimpmyrom.org  || louisteboul@gmail.com
#    http://pimpmyrom.org || http://androguide.fr
#    71 quai Clémenceau, 69300 Caluire-et-Cuire, FRANCE.
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License along
#    with this program; if not, write to the Free Software Foundation, Inc.,
#    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.


######################################################################
## Example: ./build-kernel.sh -d togari -f f2fs -j9 -k bp -w        ##
######################################################################
CYAN="\\033[1;36m"
GREEN="\\033[1;32m"
YELLOW="\\E[33;44m"
RED="\\033[1;31m"
RESET="\\e[0m"
DEVICE="togari"
THREADS="9"
FS="ext4"
KERNEL="bp"
DT2W=0
LOCAL=0
DATE=`date +%Y%m%d_%H%M`
BUILD_DIR="../carbon/"
HOME_DIR=`pwd`
KERNEL_NAME=""

set -e

while getopts d:f:k:j:whl option
do
        case "${option}"
        in
                d) DEVICE=${OPTARG};;
                f) FS=${OPTARG};;
                k) KERNEL=${OPTARG};;
                w) DT2W=1;;
                l) LOCAL=1;;
                h)
		  echo "Usage: ./build-kernel.sh [OPTIONS]"
		  echo "  -d   Device to build for (default=togari)"
		  echo "  -f   File system to use, either ext4 or f2fs (default=ext4)"
		  echo "  -k   Kernel to build, cm/bp/dt2w_cm/dt2w_bp (default=bp)"
		  echo "  -h   Show this help"
		  echo "  -l   Sync local only"
		  echo "  -w   Enable DT2W"
		  exit 1
		;;
                j) THREADS=$OPTARG;;
        esac
done

# Prind Build Options
echo -n -e "${GREEN}Building for ${YELLOW}${DEVICE}${RESET}${GREEN}...${RESET}\n"
echo -n -e "${GREEN}    with ${YELLOW}${KERNEL}${RESET}${GREEN} kernel...${RESET}\n"
if (($DT2W == 1 ))
  then
    echo -n -e "${GREEN}    with dt2w ${YELLOW}enabled${RESET}${GREEN}...${RESET}\n"
  else
    echo -n -e "${GREEN}    with dt2w ${YELLOW}disabled${RESET}${GREEN}...${RESET}\n"
  fi
echo -n -e "${GREEN}    with the ${YELLOW}${FS}${RESET}${GREEN} file-system...${RESET}\n\n"
echo -n -e "${GREEN}Building with ${YELLOW}${THREADS}${RESET}${GREEN} CPU threads ${RESET}\n"
if (( $LOCAL == 1 ))
then
    echo -n -e "${GREEN}    and ${YELLOW}local sync only.${RESET}\n"
else
    echo -n -e "${GREEN}    and ${YELLOW}full sync.${RESET}\n"
fi

#cd to build dir
cd $BUILD_DIR

#set up kermel
mv -f .repo/local_manifests/kernel.xml .repo/local_manifests/kernel.xml.bk
if [[ $KERNEL == "bp" || $KERNEL == "BluePimp" ]]
then 
    cp -f $HOME_DIR/kernel.xml.bp .repo/local_manifests/kernel.xml
    KERNEL_NAME="BluePimp"
elif [[ $KERNEL == "dt2w_bp" || $KERNEL == "BluePimp-dt2w" ]]
then
    cp -f $HOME_DIR/kernel.xml.dt2w_bp .repo/local_manifests/kernel.xml
    KERNEL_NAME="BluePimp-dt2w"
elif [[ $KERNEL == "cm" || $KERNEL == "cm-11.0" ]]
then
    cp -f $HOME_DIR/kernel.xml.cm .repo/local_manifests/kernel.xml
    KERNEL_NAME="CM-11.0"
elif [[ $KERNEL == "dt2w_cm" || $KERNEL == "dt2w_cm-11.0" || $KERNEL == "dt2w" ]]
then
    cp -f $HOME_DIR/kernel.xml.dt2w_cm .repo/local_manifests/kernel.xml
    KERNEL_NAME="CM-11.0-dt2w"
fi

if (( $LOCAL == 1 ))
then
  repo sync -j$THREADS -l
else
  repo sync -j$THREADS 
fi

# Use the right fstab depending on the file-system selection
fstab="device/sony/rhine-common/rootdir/fstab.qcom"
mv -f $fstab $fstab.bk
cp -f $HOME_DIR/fstab.qcom.${FS} $fstab

# Use the right fstab depending on the file-system selection
# if (( $DEVICE=="togari" && $DT2W==1 ))
#   then
#     ts="android_kernel_sony_msm8974/drivers/input/touchscreen/max1187x.c"
#     mv -f "$ts" "$ts.bk"
#     cp -f "$HOME_DIR/max1187x.c.dt2w $ts"
#   elseif (( $DEVICE=="togari" ))
#     ts="android_kernel_sony_msm8974/drivers/input/touchscreen/max1187x.c"
#     mv -f "$ts" "$ts.bk"
#     cp -f "$HOME_DIR/max1187x.c.orig $ts"
# fi



# Build the kernel
. build/envsetup.sh
lunch carbon_${DEVICE}-userdebug
make bootimage -j${THREADS}

# Add boot.img and wlan.ko to the flashable zip
mkdir -p $HOME_DIR/tmp-dir/system/lib/modules
cp -f out/target/product/${DEVICE}/boot.img $HOME_DIR/tmp-dir/boot.img
#cp -rfv out/target/product/${DEVICE}/system/lib/* $HOME_DIR/tmp-dir/system/lib/
cp -rfv out/target/product/${DEVICE}/system/lib/modules/* $HOME_DIR/tmp-dir/system/lib/modules/
cp -f $HOME_DIR/placeholder.zip $HOME_DIR/tmp-dir/placeholder.zip
cd $HOME_DIR/tmp-dir
zip -u placeholder.zip boot.img
zip -ur placeholder.zip system/lib/
#zip -uv placeholder.zip system/lib/modules/
cd ../

mv -f tmp-dir/placeholder.zip ${DEVICE}-$KERNEL_NAME-${FS}-${DATE}.zip

# Clean-up
rm -rf $HOME_DIR/tmp-dir
#cd to build dir
cd $BUILD_DIR
mv -f $fstab.bk $fstab
#mv -f .repo/local_manifests/kernel.xml.bk .repo/local_manifests/kernel.xml
cd $HOME_DIR



echo -n -e "${GREEN}Made flashable package:${RESET} ${YELLOW}${DEVICE}-$KERNEL_NAME-${FS}-${DATE}.zip${RESET}\n"
echo -n -e "${GREEN}MD5: `md5sum ${DEVICE}-$KERNEL_NAME-${FS}-${DATE}.zip`${RESET}\n"

