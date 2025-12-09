#!/bin/bash

CHROOTS="/usr/local/chroots"
ROOTFS_DIR="$HOME/chroot-rootfs"
mkdir -p "$CHROOTS" "$ROOTFS_DIR"

pause() { read -p "Press Enter to continue..." dummy; }

banner() {
    clear
    echo "======================================"
    echo "       CHROME OS CHROOT MANAGER      "
    echo "======================================"
    echo
}

choose_rootfs_for_create() {
    local CHROOT_NAME="$1"
    while true; do
        banner
        echo "Creating chroot: $CHROOT_NAME"
        echo
        echo "Select rootfs source:"
        echo "1) Debian 12 (Bookworm)"
        echo "2) Ubuntu 22.04 (Jammy)"
        echo "3) Alpine Linux (Smallest)"
        echo "4) Arch Linux Bootstrap"
        echo "5) Custom URL"
        echo "6) Local File"
        echo "7) Cancel"
        read -p "Choice: " OPT

        case "$OPT" in
            1)
                NAME="debian-12.tar.gz"
                URL="https://deb.debian.org/debian/dists/bookworm/main/installer-amd64/current/images/netboot/debian-installer/amd64/rootfs.gz"
                break
                ;;
            2)
                NAME="ubuntu-22.04.tar.gz"
                URL="https://partner-images.canonical.com/core/jammy/current/ubuntu-jammy-core-cloudimg-amd64-root.tar.gz"
                break
                ;;
            3)
                NAME="alpine.tar.gz"
                URL="https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/x86_64/alpine-minirootfs-latest-x86_64.tar.gz"
                break
                ;;
            4)
                NAME="arch-bootstrap.tar.gz"
                URL="https://archive.archlinux.org/iso/latest/archlinux-bootstrap-x86_64.tar.gz"
                break
                ;;
            5)
                read -p "Enter custom rootfs URL: " URL
                NAME="custom-rootfs.tar.gz"
                break
                ;;
            6)
                read -p "Enter local file path: " FILE
                if [ ! -f "$FILE" ]; then
                    echo "File not found!"
                    pause
                    continue
                fi
                echo "$FILE"
                return 0
                ;;
            7) return 1 ;;
            *) echo "Invalid option"; pause ;;
        esac
    done

    DEST="$ROOTFS_DIR/$NAME"
    if [ ! -f "$DEST" ]; then
        echo "[+] Downloading rootfs..."
        wget -O "$DEST" "$URL"
        if [ $? -ne 0 ]; then
            echo "Download failed!"
            pause
            return 1
        fi
    fi

    echo "$DEST"
}

create_chroot() {
    banner
    read -p "Enter name for new chroot: " CHROOT_NAME
    [ -z "$CHROOT_NAME" ] && { echo "Chroot name cannot be empty!"; pause; return; }

    ROOTFS_FILE=$(choose_rootfs_for_create "$CHROOT_NAME")
    [ -z "$ROOTFS_FILE" ] && { echo "No rootfs selected. Creation canceled."; pause; return; }

    DEST="$CHROOTS/$CHROOT_NAME"
    sudo mkdir -p "$DEST"
    echo "[+] Extracting rootfs..."
    sudo tar -xpf "$ROOTFS_FILE" -C "$DEST"
    echo "[+] Chroot '$CHROOT_NAME' created successfully!"
    pause
}

open_chroot() {
    read -p "Enter chroot name to open: " NAME
    DEST="$CHROOTS/$NAME"
    [ ! -d "$DEST" ] && { echo "Chroot not found!"; pause; return; }

    echo "[+] Mounting filesystems..."
    sudo mount --bind /dev "$DEST/dev"
    sudo mount --bind /sys "$DEST/sys"
    sudo mount --bind /proc "$DEST/proc"

    echo "[+] Entering chroot '$NAME'. Type 'exit' to leave."
    sudo chroot "$DEST" /bin/bash

    echo "[+] Unmounting..."
    sudo umount "$DEST/proc" 2>/dev/null
    sudo umount "$DEST/sys" 2>/dev/null
    sudo umount "$DEST/dev" 2>/dev/null
    pause
}

rename_chroot() {
    read -p "Enter current chroot name: " OLD
    [ ! -d "$CHROOTS/$OLD" ] && { echo "Chroot not found"; pause; return; }
    read -p "Enter new chroot name: " NEW
    sudo mv "$CHROOTS/$OLD" "$CHROOTS/$NEW"
    echo "Renamed $OLD → $NEW"
    pause
}

delete_chroot() {
    read -p "Enter chroot name to delete: " NAME
    DEST="$CHROOTS/$NAME"
    [ ! -d "$DEST" ] && { echo "Chroot not found"; pause; return; }

    read -p "Confirm delete '$NAME'? (y/N): " CONFIRM
    [ "$CONFIRM" != "y" ] && return

    sudo umount "$DEST/proc" 2>/dev/null
    sudo umount "$DEST/sys" 2>/dev/null
    sudo umount "$DEST/dev" 2>/dev/null
    sudo rm -rf "$DEST"
    echo "Deleted '$NAME'"
    pause
}

main_menu() {
    while true; do
        banner
        echo "1. Create Chroot"
        echo "2. Open Chroot"
        echo "3. Rename Chroot"
        echo "4. Delete Chroot"
        echo "5. Exit"
        echo
        read -p "Choose an option: " CHOICE

        case "$CHOICE" in
            1) create_chroot ;;
            2) open_chroot ;;
            3) rename_chroot ;;
            4) delete_chroot ;;
            5) exit 0 ;;
            *) echo "Invalid choice"; pause ;;
        esac
    done
}

main_menu
