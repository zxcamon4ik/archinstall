#!/usr/bin/env bash

EFI_GRET="~Please select boot/efi partition (example /dev/sda1)"
echo "-----------------------------------------------------------"
echo "$EFI_GRET"

lsblk

echo "-----------------------------------------------------------"
read EFI
echo "-----------------------------------------------------------"
echo "~Please select swap partition (example /dev/sda2)"
echo "-----------------------------------------------------------"

lsblk

echo "-----------------------------------------------------------"
read SWAP
echo "-----------------------------------------------------------"

echo "~Please select / root partition (example /dev/sda3)"
echo "-----------------------------------------------------------"

lsblk
echo "-----------------------------------------------------------"
read ROOT
echo "-----------------------------------------------------------"
echo "~Please select home partition (example /dev/sda4)"
echo "-----------------------------------------------------------"

lsblk

echo "-----------------------------------------------------------" 
read HOME
echo "-----------------------------------------------------------"

echo "~Please enter your username"
echo "-----------------------------------------------------------" 
read USER
echo "-----------------------------------------------------------"

echo "~Please enter your name"
echo "-----------------------------------------------------------" 
read NAME
echo "-----------------------------------------------------------"

echo "~Please enter user password"
echo "-----------------------------------------------------------" 
read PASSWD
echo "-----------------------------------------------------------"

echo -e "\nMounting disk partitions...\n"

existing_fs=$(blkid -s TYPE -o value "$EFI")
if [[ "$existing_fs" != "vfat" ]]; then
	mkfs.vfat -F32 "$EFI"
fi

mkfs.ext4 "${ROOT}"
mkfs.ext4 "${HOME}"

mount "${ROOT}" /mnt

ROOT_UUID=$(blkid -s UUID -o value "$ROOT")
mount --mkdir "${EFI}" /mnt/boot/efi
mount --mkdir "${HOME}" /mnt/home

echo "-----------------------------------------------------------"
echo "- - - - - - - - - INSTALLING ARCH LINUX- - - - - - - - - -"
echo "-----------------------------------------------------------"

genfstab -U /mnt >> /mnt/etc/fstab

cat <<ZXCEND > /mnt/next.sh
#!/usr/bin/env bash

useradd -m $USER
usermod -c "${NAME}" $USER
usermod -aG wheel,storage,power,video $USER
echo "$USER:$PASSWD" | chpasswd

sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

ln -sf /usr/share/zoneinfo/Europe/Bratislava /etc/localtime 
hwclock --systohc

echo "archlinux" > /etc/hostname

pacman -S mesa-utils nvidia nvidia-utils nvidia-settings opencl-nvidia nvidia-prime pipewire pipewire-alsa pipewire-pulse --noconfirm --needed

systemctl enable pipewire pipewire-pulse 

echo "-----------------------------------------------------------"
echo "- - - - - - - - - Bootloader installation - - - - - - - - -"
echo "-----------------------------------------------------------"

pacman -S grub efibootmgr --noconfirm --needed
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id="Linux Boot Manager" --modules="normal test efi_gop efi_uga search echo linux all_video gfxterm_menu gfxterm loadenv configfile"
grub-mkconfig -o /boot/grub/grub.cfg

echo "-----------------------------------------------------------"
echo "- - - - - - - - - Install Complete, you can reboot now"
echo "-----------------------------------------------------------"

ZXCEND

chmod +x /mnt/next.sh
arch-chroot /mnt /next.sh
