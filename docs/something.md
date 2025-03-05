# Fixing Missing Wireless Drivers and Kernel Modules on Xubuntu

## Introduction

Recently, I encountered an issue where my laptop running Xubuntu lost **wireless connectivity, Bluetooth, and MTP (Media Transfer Protocol) support**. After investigating, I found that the required kernel modules were missing. Since I had no internet access on the affected system, I had to manually recover and install the necessary drivers using a **Live USB**.

This article covers **how I diagnosed and fixed the issue**, including **mounting the existing installation in a live environment, copying necessary files, and manually installing the missing kernel packages**.

---

## Problem Diagnosis

### Symptoms

- **No WiFi adapter detected.**
- Running `modprobe ath10k_pci` returned **"Module not found"**.
- **Bluetooth was not working.**
- **MTP (Android file transfer) was broken.**
- The system was running **kernel 6.8.0-55**, but the **ath10k** drivers were missing.
- **No internet access** to download missing packages.

### Checking for Missing Kernel Modules

First, I checked if the required **ath10k** driver files were present:

```bash
ls /lib/modules/$(uname -r)/kernel/drivers/net/wireless/
```

The directory was **empty**, meaning the wireless drivers were missing.

---

## Solution: Installing Missing Kernel Modules from a Live USB

Since I had no network access, I used a **Live USB** to manually install the missing kernel modules and headers.

### Step 1: Boot into a Xubuntu Live USB

I booted into a **Xubuntu Live USB** and opened a terminal to access the system.

### Step 2: Locate and Mount the Existing Installation

To access the files from my existing installation, I first identified my **root partition** using:

```bash
lsblk
```

Since my system used **LVM**, I listed the available volumes:

```bash
sudo vgscan
sudo lvscan
```

This showed my **root volume** as `/dev/mapper/vgubuntu-root`.

To mount the root filesystem:

```bash
sudo mkdir /mnt/root
sudo mount /dev/mapper/vgubuntu-root /mnt/root
```

Then, I mounted additional system directories to ensure smooth operation:

```bash
sudo mount --bind /dev /mnt/root/dev
sudo mount --bind /proc /mnt/root/proc
sudo mount --bind /sys /mnt/root/sys
sudo mount --bind /run /mnt/root/run
```

### Step 3: Chroot into the Installed System

To make changes as if I were inside the installed OS, I ran:

```bash
sudo chroot /mnt/root
```

Now, I was inside my actual system’s environment, but the missing kernel modules were still an issue.

---

### Step 4: Copy and Install the Required Kernel Packages

I had previously downloaded the following `.deb` files from another machine with internet access:

1. **linux-modules-extra-6.8.0-55-generic**
2. **linux-headers-6.8.0-55**
3. **linux-headers-6.8.0-55-generic**

Since my system was already mounted under `/mnt/root`, I copied these files from my USB to the mounted system:

```bash
cp /media/xubuntu/USB_DRIVE/linux-*.deb /mnt/root/home/user0/
```

Then, inside the chrooted environment, I installed them:

```bash
cd /home/user0
sudo dpkg -i linux-modules-extra-6.8.0-55-generic_6.8.0-55.57_amd64.deb
sudo dpkg -i linux-headers-6.8.0-55_6.8.0-55.57_amd64.deb
sudo dpkg -i linux-headers-6.8.0-55-generic_6.8.0-55.57_amd64.deb
```

### Step 5: Update Initramfs and Grub

After installation, I regenerated the initramfs:

```bash
sudo update-initramfs -u -k all
```

Then, I updated GRUB in case boot settings needed to be refreshed:

```bash
sudo update-grub
```

---

### Step 6: Exit Chroot and Unmount Filesystems

After installing everything, I exited the chroot:

```bash
exit
```

Then, I unmounted all system directories to prevent corruption:

```bash
sudo umount /mnt/root/dev
sudo umount /mnt/root/proc
sudo umount /mnt/root/sys
sudo umount /mnt/root/run
sudo umount /mnt/root
```

---

### Step 7: Reboot and Verify

Finally, I rebooted the system:

```bash
sudo reboot
```

After booting into my main system:

- **WiFi was working** 🎉
- **Bluetooth was detected**
- **MTP worked again for Android file transfer**

---

## Conclusion

The issue was caused by missing **linux-modules-extra** and **linux-headers** for my kernel version. These packages contained critical wireless drivers (**ath10k\_pci**) and other essential networking components.

### Key Takeaways:

✅ **Always match kernel modules and headers to the installed kernel version.**\
✅ **Use **``**, **``**, and **``** to find and mount existing installations from a Live USB.**\
✅ **Chrooting into an existing system allows package installation even when it won’t boot properly.**\
✅ **Install dependencies in the correct order (**``** → **``** → **``**).**

This method can be used to recover missing kernel drivers **without internet access**, ensuring your system remains fully functional. 🚀


