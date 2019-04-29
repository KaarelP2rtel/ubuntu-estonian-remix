#!/bin/bash -e
#
#debug options
set -x
PS4='Line ${LINENO}: '
#logfile=makeRemix_64bit.log 
#exec > $logfile 2>&1
#
# Ubuntu - Estonian Remix ISO
#
# based on Finnish remix http://bazaar.launchpad.net/~timo-jyrinki/ubuntu-fi-remix/main/files
#
# License CC-BY-SA 3.0: http://creativecommons.org/licenses/by-sa/3.0/
#locale
export LC_ALL=C.UTF-8

#local apt-cacher-ng url



#what release we're working on -> defined below automatically after defining necessary variables
#export RELEASE="xenial"

# workaround for restricted extras into script extra.sh below: uncomment appropriate one. PART 1 of 2
## UNITY
export desktop_name=UNITY
## MATE
#export desktop_name=MATE
## GNOME
#export desktop_name=GNOME
## KDE
#export desktop_name=KDE
## LXDE
#export desktop_name=LXDE
## XFCE
#export desktop_name=XFCE
## Edubuntu
#export desktop_name=EDU
## Ubuntu Studio
#export desktop_name=STUDIO

#input ISO file
#export ISO_FILE="ubuntu-16.04.3-desktop-amd64.iso"
#
# ISO download in Estonia
# http://ftp.aso.ee/ubuntu-releases/
#


export $(cat config/main.conf | grep -v "#")

# Make sure absolute paths are used. Some commands 
# do not like relative paths.
OUTPUT_DIR=$(realpath "$OUTPUT_DIR")
ISO_DIR=$(realpath "$ISO_DIR")
WORKING_DIR=$(realpath "$WORKING_DIR")

#name for Estonian Speller file in current directory
export ESTONIAN_SPELLER="oofslinget-addon-estobuntu_4.1-0_all.deb"


# Make sure only root can run our script
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

cmd=(dialog --radiolist "Select ISO file" 22 76  16)
options=()
for file in $(echo "$ISO_DIR"/*.iso); do
  options+=($(basename "$file"))
  options+=("")
  options+=("off")
done
export ISO_FILE_NAME=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
clear
export ISO_FILE="$ISO_DIR/$ISO_FILE_NAME"
export VERSION="$( echo $ISO_FILE_NAME | grep amd64 | cut -d'-' -f2)"

if [ -z "$ISO_FILE_NAME" ]; then
  echo No input ISO file.
  exit
fi






#IMAGE NAME as it appears in ISO file (file <iso_image>)

if [[ "$ISO_FILE" == *"amd64"* ]]; then
  export ARCH="amd64"
elif [[ "$ISO_FILE" == *"x86"* ]]; then
  export ARCH="x86"
fi


#export IMAGE_NAME="$(ls $ISO_DIR | grep amd64 | cut -d'-' -f1)-estonian-remix-$(ls $ISO_DIR | grep amd64 | cut -d'-' -f2)-$desktop_name-64bit"
#echo "$IMAGE_NAME"
export IMAGE_NAME="ubuntu-estonian-remix-${VERSION}-${ARCH}"
#export IMAGE_NAME="Ubuntu Estonian Remix 16.04.3 LTS 64-bit"
#output ISO file
export OUTPUT_FILE="${IMAGE_NAME}.iso"

#visible name of the new disk in file explorer (max 32char)
export NEWIMAGE_NAME="$(ls $ISO_DIR | grep amd64 | cut -d'-' -f1)-remix-$(ls $ISO_DIR | grep amd64 | cut -d'-' -f2)-lts-64bit"
#export NEWIMAGE_NAME="Ubuntu Remix 16.04.3 LTS 64-bit"
echo "$NEWIMAGE_NAME"
 







if [[ "$VERSION" == *"14.04"* ]]; then
  export RELEASE="trusty"
elif [[ "$VERSION" == *"16.04"* ]]; then
  export RELEASE="xenial"
elif [[ "$VERSION" == *"16.10"* ]]; then
  export RELEASE="yakkety"
elif [[ "$VERSION" == *"17.04"* ]]; then
  export RELEASE="zesty"
elif [[ "$VERSION" == *"17.10"* ]]; then
  export RELEASE="artful"
elif [[ "$VERSION" == *"18.04"* ]]; then
 export RELEASE="bionic"
else
  echo "Check release manually and fix in script." && exit 1
fi


dialog --title "Ubuntu - Estonian CD remix creation" --msgbox "\nUsing following input ISO file: $ISO_FILE\n\noutput will be: $output_file" 22 76

#Confirm pacakge sets, that will be added
cmd=(dialog --separate-output --checklist "Package sets to be installed:" 22 76 16)
options=()
for file in $(echo config/apt/added/*.conf); do
  options+=($(basename "$file"))
  first_line=$(head -n 1 "$file") 
  description=("${first_line[@]:1}")
  options+=("$description")
  options+=("on")
done

add_apt_sets=($("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty))
clear
echo "$add_apt_sets"

#Confirm package sets to be removed
cmd=(dialog --separate-output --checklist "Package sets to be removed:" 22 76 16)
options=()
for file in $(echo config/apt/removed/*.conf); do
  options+=($(basename "$file"))
  first_line=$(head -n 1 "$file") 
  description=("${first_line[@]:1}")
  options+=("$description")
  options+=("on")
done

removed_apt_sets=($("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty))
clear
echo "$removed_apt_sets"

cmd=(dialog --separate-output --checklist "Select remix options:" 22 76 16)
options=(ID "Install Estonian ID Software" on    # any option can be set to default to "on"
         EST "Filosoft speller for LibreOffice and Estonian langpacks" on
         LO "Newest LibreOffice software" on
         REPLACE "Replace desktop system (remove Unity) - select in next step" off
	 EXTRA "Video players, codecs, Iridium and Brave Browser, for kids etc" off)
choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
clear
for choice in $choices
do
    case $choice in
        ID)
            ID=1
            ;;
        LO)
            LO=1
            ;;
        EST)
            EST=1
            ;;
        REPLACE)
            REPLACE=1
            ;;
        EXTRA)
            EXTRA=1
            ;;
    esac
done

if [[ $REPLACE ]]
then
#lubuntu-desktop ubuntu-mate-desktop kubuntu-desktop xubuntu-desktop ubuntu-gnome-desktop edubuntu-desktop-gnome ubuntustudio-desktop
 cmd=(dialog --radiolist "select desktop system" 22 76  16)
 options=(DEFAULT "Do not change, leave default (Unity)" on
	  MATE "Mate desktop" off
          GNOME "Gnome desktop" off
          KDE "KDE system" off
          LXDE "LXDE desktop" off
          XFCE "Xfce system" off
          EDU "Edubuntu gnome" off
          STUDIO "Ubuntu studio set" off)
 choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
 clear
 case $choice in
	MATE)
	  desktop_system="ubuntu-mate-desktop"
	  ;;
	GNOME)
	  desktop_system="ubuntu-gnome-desktop"
	  ;;
	KDE)
	  desktop_system="kubuntu-desktop"
	  ;;
	LXDE)
	  desktop_system="lubuntu-desktop"
	  ;;
	XFCE)
	  desktop_system="xubuntu-desktop"
	  ;;
	EDU)
	  desktop_system="edubuntu-desktop-gnome"
	  ;;
	STUDIO)
	  desktop_system="ubuntustudio-desktop"
	  ;;
	*)
	  desktop_system=""
          REPLACE=0
	  ;;
  esac
 export desktop_system
fi

#-------
# Unpack ISO and prepare for modification
#-------


echo "removing old directories"
rm -rf "$WORKING_DIR"
echo Extracting image
ISO_MOUNT_POINT="$WORKING_DIR/mnt/iso"
FS_MOUNT_POINT="$WORKING_DIR/mnt/fs"
EXTRACT_CD_DIR="$WORKING_DIR/extract-cd"
EDIT_DIR="$WORKING_DIR/edit"

mkdir -p $ISO_MOUNT_POINT $FS_MOUNT_POINT $EXTRACT_CD_DIR $WORKING_DIR

mount -o loop "${ISO_FILE}" "$ISO_MOUNT_POINT"

rsync --exclude=/casper/filesystem.squashfs -a $ISO_MOUNT_POINT/ $EXTRACT_CD_DIR
echo Extracting liveFS
mount -t squashfs -o loop "$ISO_MOUNT_POINT/casper/filesystem.squashfs" "$FS_MOUNT_POINT"

cp -a "$FS_MOUNT_POINT/" "$EDIT_DIR"

# NOTE: LiveCDCustomization wiki page uses another method nowadays
# sudo unsquashfs mnt/casper/filesystem.squashfs
# sudo mv squashfs-root edit
# I've not noticed difference in the end result, cp seems faster

#cp splash.pcx extract-cd/isolinux/splash.pcx

#--------
#Image modifing scripts
#--------
cp -r scripts/* $EDIT_DIR/tmp/

#--------
#Call modify scripts as selected
#--------

chmod +x "$EDIT_DIR"/tmp/*.sh

chroot "$EDIT_DIR" ./tmp/prepare.sh
echo "$removed_apt_sets"
echo "$add_apt_sets"


for set in "$add_apt_sets"; do
  add_apt_packages+=($(cat "config/apt/added/$set" | grep -v "#" | xargs))
done
echo "$add_apt_packages"

for set in "$removed_apt_sets"; do
  removed_apt_packages+=($(cat "config/apt/removed/$set" | grep -v "#" | xargs))
done
echo "$removed_apt_packages"

# Purge selected packages
# Done one by one because apt purge fails if any package is missing.
for package in ${removed_apt_packages[@]}; do
  chroot "$EDIT_DIR" apt-get purge --yes "$package"
done

#Install selected packages
echo $add_apt_packages
chroot "$EDIT_DIR" apt-get install --yes ${add_apt_packages[@]}
# Install included deb files
# cp config/deb/* "$EDIT_DIR/tmp" || true
# for deb in $(echo config/deb/*.deb ); do
#   chroot "$EDIT_DIR" dpkg --install "/tmp/$(basename $deb)"
# done
# exit 42


if [[ -n "$PROXY_URL" ]]
then
   echo "Acquire::http { Proxy \"${PROXY_URL}\"; };" >> "$EDIT_DIR/etc/apt/apt.conf.d/00proxy"
   echo "Acquire::https { Proxy \"${PROXY_URL}\"; };" >> "$EDIT_DIR/etc/apt/apt.conf.d/00proxy"
fi

if [[ $ID ]]
then
  chroot "$EDIT_DIR" ./tmp/install-open-eid.sh
fi

if [[ $LO ]]
then
  chroot "$EDIT_DIR" ./tmp/libreoffice.sh
fi

if [[ $REPLACE ]]
then
  chroot "$EDIT_DIR" ./tmp/replace.sh
fi

if [[ $EXTRA ]]
then
  chroot "$EDIT_DIR" ./tmp/extra.sh
fi




#if [ "$desktop_name" = "MATE" ]; then
#  chroot edit ./tmp/caja-qdigidoc.sh
#fi
#
# current error messages:
# ./tmp/caja-qdigidoc.sh: line 4: edit/tmp/caja-qdigidoc.py: No such file or directory
# cp: cannot stat 'edit/tmp/caja-qdigidoc.py': No such file or directory

chroot "$EDIT_DIR" ./tmp/cleanup.sh

#---------
#Construct new ISO file, modifiyng some locales, etc
#---------

# setting default language
# 16.04 LTS: seems broken (for legacy boot mode), no known solution. English is still the default.

#cd gfxboot-theme-ubuntu-0.20.1
#cd po
#ln -sf et.po et_EE.po
#cd ..
#make DEFAULT_LANG="et_EE"
#cd ..
#echo et > extract-cd/isolinux/lang
#cp -af gfxboot-theme-ubuntu-0.20.1/boot/* extract-cd/isolinux/
#sed -i "/default_keymap = {/a \'et\': \'et\'," edit/usr/lib/ubiquity/ubiquity/misc.py


# Re-creation of "manifest" file
chmod +w "$EXTRACT_CD_DIR/casper/filesystem.manifest"
chroot "$EDIT_DIR" dpkg-query -W --showformat='${Package} ${Version}\n' > "$EXTRACT_CD_DIR/casper/filesystem.manifest"
#
# Pack the filesystem
rm -f "$EXTRACT_CD_DIR/casper/filesystem.squashfs"
mksquashfs "$EDIT_DIR" "$EXTRACT_CD_DIR/casper/filesystem.squashfs"
# Create the disk image itself
sed -i -e "s/$IMAGE_NAME/$NEWIMAGE_NAME/" "$EXTRACT_CD_DIR/README.diskdefines"
sed -i -e "s/$IMAGE_NAME/$NEWIMAGE_NAME/" "$EXTRACT_CD_DIR/.disk/info"

cd "$EXTRACT_CD_DIR"
# Localizing the UEFI boot
sed -i '6i    loadfont /boot/grub/fonts/unicode.pf2' boot/grub/grub.cfg
sed -i '7i    set locale_dir=$prefix/locale' boot/grub/grub.cfg
#sed -i '8i    set lang=et_EE' boot/grub/grub.cfg
sed -i '9i    insmod gettext' boot/grub/grub.cfg
#sed -i 's%splash%splash debian-installer/locale=et_EE keyboard-configuration/layoutcode=et console-setup/layoutcode=et%' boot/grub/grub.cfg
sed -i 's/Try Ubuntu without installing/Proovi ilma paigaldamiseta/' boot/grub/grub.cfg
sed -i 's/Install Ubuntu/Paigalda Ubuntu/' boot/grub/grub.cfg
sed -i 's/OEM install (for manufacturers)/OEM-paigaldus (arvutitootjatele)/' boot/grub/grub.cfg
sed -i 's/Check disc for defects/Kontrolli kettavigu/' boot/grub/grub.cfg

#This is not a good solution, it mixes keyboard setting completely - set language form install splash
#sed -i 's%splash%splash debian-installer/locale=et_EE.UTF-8 keyboard-configuration/layoutcode=et console-setup/layoutcode=et%' boot/grub/loopback.cfg
#sed -i 's%splash%splash debian-installer/locale=et_EE.UTF-8 keyboard-configuration/layoutcode=et console-setup/layoutcode=et%' isolinux/txt.cfg
#sed -i 's/Try Ubuntu without installing/Proovi ilma paigaldamiseta/' boot/grub/loopback.cfg
#sed -i 's/Try Ubuntu without installing/Proovi ilma paigaldamiseta/' isolinux/txt.cfg
#sed -i 's/Install Ubuntu/Paigalda Ubuntu/' boot/grub/loopback.cfg
#sed -i 's/Install Ubuntu/Paigalda Ubuntu/' isolinux/txt.cfg

mkdir -p boot/grub/locale/
mkdir -p boot/grub/fonts/

#cp -a /boot/grub/locale/et.mo boot/grub/locale/
cp -a /boot/grub/fonts/unicode.pf2 boot/grub/fonts/

#help users with selecting some Estonian locales
echo "d-i debian-installer/locale string et_EE.UTF-8" >> preseed/ubuntu.seed
echo "d-i keyboard-configuration/xkb-keymap select et" >> preseed/ubuntu.seed
echo "d-i keyboard-configuration/layout string \"Estonian\"" >> preseed/ubuntu.seed
echo "d-i keymap select et" >> preseed/ubuntu.seed
rm -f md5sum.txt
(find -type f -print0 | xargs -0 md5sum | grep -v isolinux/boot.cat | tee md5sum.txt)
#mv -f ../md5sum.txt ./
# If the following is not done, causes an error in the boot menu disk check option
sed -i -e '/isolinux/d' md5sum.txt
# Different volume name than the IMAGE_NAME above.$output_file_name.$output_file_extension
# 16.04 LTS$output_file_name.$output_file_extension
genisoimage -r -V "$NEWIMAGE_NAME" -cache-inodes -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -eltorito-alt-boot -e boot/grub/efi.img -no-emul-boot -o ${OUTPUT_DIR}/${OUTPUT_FILE} .

cd ..
isohybrid --uefi "${OUTPUT_DIR}/${OUTPUT_FILE}"

# Clean up working directory
umount "$FS_MOUNT_POINT" || true
umount "$ISO_MOUNT_POINT" || true
umount -l "$EDIT_DIR/sys" || true
umount -l "$EDIT_DIR/proc" || true
umount -l "$EDIT_DIR/dev" || true
rm -rf "$EDIT_DIR"/ "$EXTRACT_CD_DIR"/ mnt/ squashfs/

# Generate SHA256SUM checksum
cd $OUTPUT_DIR
sha256sum $OUTPUT_FILE > $IMAGE_NAME.sha256
cd -

echo
echo Generated ISO file:
echo ${OUTPUT_FILE}
echo
echo Generated SHA256 checksum:
echo ${OUTPUT_DIR}/${IMAGE_NAME}.sha256
echo
echo ALL DONE!
echo
