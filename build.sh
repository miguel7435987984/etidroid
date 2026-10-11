#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="${SCRIPT_DIR}/build_tmp"
TARGET="${1:-4.4}"
VIDEO_INPUT="${SCRIPT_DIR}/assets/bootanimation.mp4"
WALLPAPER_INPUT="${SCRIPT_DIR}/assets/wallpaper.jpg"

case "$TARGET" in
  4.4|4.4-r5)
    VERSION_TAG="4.4-r5"
    BASE_ISO_NAME="android-x86-4.4-r5.iso"
    BASE_ISO_URL="https://downloads.sourceforge.net/project/android-x86/Release%204.4/android-x86-4.4-r5.iso"
    OUTPUT_ISO="${SCRIPT_DIR}/etidroid-4.4-r5.iso"
    IS_EFI_DUAL=true
    EFI_LOAD_SIZE=6144
    EXPAND_SIZE="1250M"
    VOL_ID="Etidroid LiveCD"
    ;;
  5.1|5.1-rc1)
    VERSION_TAG="5.1-rc1"
    BASE_ISO_NAME="android-x86-5.1-rc1.iso"
    BASE_ISO_URL="https://downloads.sourceforge.net/project/android-x86/Release%205.1/android-x86-5.1-rc1.iso"
    OUTPUT_ISO="${SCRIPT_DIR}/etidroid-5.1-rc1.iso"
    IS_EFI_DUAL=false
    EFI_LOAD_SIZE=0
    EXPAND_SIZE="1250M"
    VOL_ID="Etidroid LiveCD"
    ;;
  7.1|7.1-r5)
    VERSION_TAG="7.1-r5"
    BASE_ISO_NAME="android-x86_64-7.1-r5.iso"
    BASE_ISO_URL="https://downloads.sourceforge.net/project/android-x86/Release%207.1/android-x86_64-7.1-r5.iso"
    OUTPUT_ISO="${SCRIPT_DIR}/etidroid-7.1-r5.iso"
    IS_EFI_DUAL=true
    EFI_LOAD_SIZE=8192
    EXPAND_SIZE="2600M"
    VOL_ID="Etidroid 7.1-r5 (x86_64)"
    ;;
  8.1|8.1-r6)
    VERSION_TAG="8.1-r6"
    BASE_ISO_NAME="android-x86_64-8.1-r6.iso"
    BASE_ISO_URL="https://downloads.sourceforge.net/project/android-x86/Release%208.1/android-x86_64-8.1-r6.iso"
    OUTPUT_ISO="${SCRIPT_DIR}/etidroid-8.1-r6.iso"
    IS_EFI_DUAL=true
    EFI_LOAD_SIZE=8192
    EXPAND_SIZE="2600M"
    VOL_ID="Etidroid 8.1-r6 (x86_64)"
    ;;
  9.0|9.0-r2|9.0-k49|9.0-r2-k49)
    VERSION_TAG="9.0-r2-k49"
    BASE_ISO_NAME="android-x86_64-9.0-r2-k49.iso"
    BASE_ISO_URL="https://downloads.sourceforge.net/project/android-x86/Release%209.0/android-x86_64-9.0-r2-k49.iso"
    OUTPUT_ISO="${SCRIPT_DIR}/etidroid-9.0-r2-k49.iso"
    IS_EFI_DUAL=true
    EFI_LOAD_SIZE=8192
    EXPAND_SIZE="2800M"
    VOL_ID="Etidroid 9.0-r2-k49 (x86_64)"
    ;;
  10.0|10|10.0-20200225)
    VERSION_TAG="10.0"
    BASE_ISO_NAME="android-x86_64-10.0-20200225.iso"
    BASE_ISO_URL="https://archive.org/download/androidx86-10-isos/Android%2010%20x64%20%28User%29.iso"
    OUTPUT_ISO="${SCRIPT_DIR}/etidroid-10.0.iso"
    IS_EFI_DUAL=true
    EFI_LOAD_SIZE=8192
    EXPAND_SIZE="3400M"
    VOL_ID="Etidroid 10.0 (x86_64)"
    ;;
  *)
    echo "Uso: $0 [4.4|5.1|7.1|8.1|9.0|10.0]"
    exit 1
    ;;
esac

BASE_ISO="${SCRIPT_DIR}/${BASE_ISO_NAME}"

echo "=== Etidroid ISO Build Script (Alvo: $VERSION_TAG) ==="

# 1. Download base ISO if not present
if [ ! -f "$BASE_ISO" ]; then
    echo "[+] Baixando $BASE_ISO_NAME..."
    curl -L -o "$BASE_ISO" "$BASE_ISO_URL"
fi

rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"

# 2. Gerar bootanimation.zip
echo "[+] Extraindo frames do bootanimation..."
mkdir -p "$WORK_DIR/anim/part0"
ffmpeg -y -i "$VIDEO_INPUT" -vf "fps=24" "$WORK_DIR/anim/part0/%05d.png"

cat << 'EOF' > "$WORK_DIR/anim/desc.txt"
1280 720 24
p 0 0 part0
EOF

echo "[+] Compactando bootanimation.zip (Store)..."
(cd "$WORK_DIR/anim" && zip -r0 "$WORK_DIR/bootanimation.zip" desc.txt part0)

# 3. Extrair arquivos da ISO
echo "[+] Extraindo arquivos da ISO base..."
mkdir -p "$WORK_DIR/iso-root"
7z x -y "$BASE_ISO" -o"$WORK_DIR/iso-root/"
rm -rf "$WORK_DIR/iso-root/[BOOT]"
find "$WORK_DIR/iso-root" -name "TRANS.TBL" -delete

# Garantir script de instalacao completo em install.img e initrd.img
if [ -f "$WORK_DIR/iso-root/install.img" ] && [ -f "${SCRIPT_DIR}/assets/installer/1-install" ]; then
    if ! zcat "$WORK_DIR/iso-root/install.img" | cpio -it 2>/dev/null | grep -q "scripts/1-install"; then
        echo "[+] Injetando script do instalador em install.img..."
        mkdir -p "$WORK_DIR/install-root"
        (cd "$WORK_DIR/install-root" && zcat "$WORK_DIR/iso-root/install.img" | cpio -idmv >/dev/null 2>&1)
        mkdir -p "$WORK_DIR/install-root/scripts"
        cp "${SCRIPT_DIR}/assets/installer/1-install" "$WORK_DIR/install-root/scripts/1-install"
        chmod +x "$WORK_DIR/install-root/scripts/1-install"
        (cd "$WORK_DIR/install-root" && find . | cpio -H newc -o 2>/dev/null | gzip -9 > "$WORK_DIR/iso-root/install.img")
        rm -rf "$WORK_DIR/install-root"
    fi
fi

if [ -f "$WORK_DIR/iso-root/initrd.img" ] && [ -f "${SCRIPT_DIR}/assets/installer/1-install" ]; then
    mkdir -p "$WORK_DIR/initrd-root"
    (cd "$WORK_DIR/initrd-root" && zcat "$WORK_DIR/iso-root/initrd.img" | cpio -idmv >/dev/null 2>&1)
    if [ -f "$WORK_DIR/initrd-root/scripts/1-install" ]; then
        if grep -q "installer is not available" "$WORK_DIR/initrd-root/scripts/1-install"; then
            echo "[+] Atualizando scripts/1-install em initrd.img..."
            cp "${SCRIPT_DIR}/assets/installer/1-install" "$WORK_DIR/initrd-root/scripts/1-install"
            chmod +x "$WORK_DIR/initrd-root/scripts/1-install"
            (cd "$WORK_DIR/initrd-root" && find . | cpio -H newc -o 2>/dev/null | gzip -9 > "$WORK_DIR/iso-root/initrd.img")
        fi
    fi
    rm -rf "$WORK_DIR/initrd-root"
fi

# 4. Extrair e modificar system.img
echo "[+] Descompactando system.sfs..."
mkdir -p "$WORK_DIR/sfs-root"
unsquashfs -no-xattrs -d "$WORK_DIR/sfs-root" "$WORK_DIR/iso-root/system.sfs"

IMG="$WORK_DIR/sfs-root/system.img"
echo "[+] Redimensionando system.img para $EXPAND_SIZE..."
truncate -s "$EXPAND_SIZE" "$IMG"
e2fsck -f -y "$IMG" || true
resize2fs "$IMG"

echo "[+] Verificando estrutura do system.img (SAR vs Legacy)..."
PROP_PATH="build.prop"
IS_SAR=false
if debugfs -R "stat system/build.prop" "$IMG" 2>&1 | grep -q "Inode:"; then
    IS_SAR=true
    PROP_PATH="system/build.prop"
    echo "[+] Detectado layout System-as-Root (SAR). Usando $PROP_PATH."
else
    echo "[+] Detectado layout tradicional (Non-SAR). Usando $PROP_PATH."
fi

echo "[+] Extraindo e ajustando $PROP_PATH..."
debugfs -R "dump $PROP_PATH \"$WORK_DIR/build.prop\"" "$IMG"
sed -i 's/ro.product.model=Generic Android-x86_64/ro.product.model=Etidroid/g' "$WORK_DIR/build.prop"
sed -i 's/ro.product.model=Generic Android-x86/ro.product.model=Etidroid/g' "$WORK_DIR/build.prop"
sed -i 's/ro.product.brand=Android-x86/ro.product.brand=Etidroid/g' "$WORK_DIR/build.prop"
sed -i 's/ro.product.system.brand=Android-x86/ro.product.system.brand=Etidroid/g' "$WORK_DIR/build.prop"
sed -i "s/ro.build.display.id=.*/ro.build.display.id=Etidroid $VERSION_TAG/g" "$WORK_DIR/build.prop"
sed -i '/ro.config.wallpaper/d' "$WORK_DIR/build.prop"
sed -i '/ro.config.lock_wallpaper/d' "$WORK_DIR/build.prop"
echo "ro.config.wallpaper=/system/media/default_wallpaper.jpg" >> "$WORK_DIR/build.prop"
echo "ro.config.lock_wallpaper=/system/media/default_wallpaper.jpg" >> "$WORK_DIR/build.prop"

echo "[+] Injetando arquivos no system.img via debugfs..."
if [ "$IS_SAR" = true ]; then
    debugfs -w -R "mkdir system/media" "$IMG" 2>/dev/null || true
    debugfs -w -R "sif system/media mode 040755" "$IMG" 2>/dev/null || true
    debugfs -w -R "sif system/media uid 0" "$IMG" 2>/dev/null || true
    debugfs -w -R "sif system/media gid 0" "$IMG" 2>/dev/null || true
    debugfs -w -R "ea_set system/media security.selinux u:object_r:system_file:s0\000" "$IMG" 2>/dev/null || true

    for anim_dest in "system/media/bootanimation.zip" "system/product/media/bootanimation.zip"; do
        debugfs -w -R "rm $anim_dest" "$IMG" 2>/dev/null || true
        debugfs -w -R "write \"$WORK_DIR/bootanimation.zip\" $anim_dest" "$IMG" 2>/dev/null || true
        debugfs -w -R "sif $anim_dest mode 0100644" "$IMG" 2>/dev/null || true
        debugfs -w -R "sif $anim_dest uid 0" "$IMG" 2>/dev/null || true
        debugfs -w -R "sif $anim_dest gid 0" "$IMG" 2>/dev/null || true
        debugfs -w -R "ea_set $anim_dest security.selinux u:object_r:system_file:s0\000" "$IMG" 2>/dev/null || true
    done

    if [ -f "$WALLPAPER_INPUT" ]; then
        echo "[+] Injetando wallpaper padrão no system.img (SAR)..."
        for wall_dest in "system/media/default_wallpaper.jpg" "system/product/media/default_wallpaper.jpg" "system/etc/default_wallpaper.jpg"; do
            debugfs -w -R "rm $wall_dest" "$IMG" 2>/dev/null || true
            debugfs -w -R "write \"$WALLPAPER_INPUT\" $wall_dest" "$IMG" 2>/dev/null || true
            debugfs -w -R "sif $wall_dest mode 0100644" "$IMG" 2>/dev/null || true
            debugfs -w -R "sif $wall_dest uid 0" "$IMG" 2>/dev/null || true
            debugfs -w -R "sif $wall_dest gid 0" "$IMG" 2>/dev/null || true
            debugfs -w -R "ea_set $wall_dest security.selinux u:object_r:system_file:s0\000" "$IMG" 2>/dev/null || true
        done
    fi
else
    debugfs -w -R "rm media/bootanimation.zip" "$IMG" 2>/dev/null || true
    debugfs -w -R "write \"$WORK_DIR/bootanimation.zip\" media/bootanimation.zip" "$IMG"
    debugfs -w -R "sif media/bootanimation.zip mode 0100644" "$IMG"
    debugfs -w -R "sif media/bootanimation.zip uid 0" "$IMG"
    debugfs -w -R "sif media/bootanimation.zip gid 0" "$IMG"
    debugfs -w -R "ea_set media/bootanimation.zip security.selinux u:object_r:system_file:s0\000" "$IMG"

    if [ -f "$WALLPAPER_INPUT" ]; then
        echo "[+] Injetando wallpaper padrão no system.img..."
        for wall_dest in "media/default_wallpaper.jpg" "etc/default_wallpaper.jpg"; do
            debugfs -w -R "rm $wall_dest" "$IMG" 2>/dev/null || true
            debugfs -w -R "write \"$WALLPAPER_INPUT\" $wall_dest" "$IMG" 2>/dev/null || true
            debugfs -w -R "sif $wall_dest mode 0100644" "$IMG" 2>/dev/null || true
            debugfs -w -R "sif $wall_dest uid 0" "$IMG" 2>/dev/null || true
            debugfs -w -R "sif $wall_dest gid 0" "$IMG" 2>/dev/null || true
            debugfs -w -R "ea_set $wall_dest security.selinux u:object_r:system_file:s0\000" "$IMG" 2>/dev/null || true
        done
    fi
fi

debugfs -w -R "rm $PROP_PATH" "$IMG"
debugfs -w -R "write \"$WORK_DIR/build.prop\" $PROP_PATH" "$IMG"
debugfs -w -R "sif $PROP_PATH mode 0100644" "$IMG"
debugfs -w -R "sif $PROP_PATH uid 0" "$IMG"
debugfs -w -R "sif $PROP_PATH gid 0" "$IMG"
debugfs -w -R "ea_set $PROP_PATH security.selinux u:object_r:system_file:s0\000" "$IMG"

echo "[+] Otimizando tamanho do system.img..."
e2fsck -f -y "$IMG" || true
resize2fs -M "$IMG"
e2fsck -f -y "$IMG" || true

# 5. Reempacotar system.sfs
echo "[+] Reempacotando system.sfs..."
mksquashfs "$WORK_DIR/sfs-root" "$WORK_DIR/iso-root/system.sfs" -comp gzip -b 128k -noappend

# 6. Atualizar menus de boot
echo "[+] Atualizando menus de boot..."
if [ -f "$WORK_DIR/iso-root/isolinux/isolinux.cfg" ]; then
    sed -i 's/Android-x86/Etidroid/g' "$WORK_DIR/iso-root/isolinux/isolinux.cfg"
fi
if [ -f "$WORK_DIR/iso-root/boot/grub/grub.cfg" ]; then
    sed -i 's/Android-x86/Etidroid/g' "$WORK_DIR/iso-root/boot/grub/grub.cfg"
fi
if [ -f "$WORK_DIR/iso-root/efi/boot/grub.cfg" ]; then
    sed -i 's/Android-x86/Etidroid/g' "$WORK_DIR/iso-root/efi/boot/grub.cfg"
    sed -i "s/Etidroid VER/Etidroid $VERSION_TAG/g" "$WORK_DIR/iso-root/efi/boot/grub.cfg"
    sed -i 's/CMDLINE/androidboot.hardware=android_x86/g' "$WORK_DIR/iso-root/efi/boot/grub.cfg"
fi
if [ -f "$WORK_DIR/iso-root/efi/boot/android.cfg" ]; then
    sed -i 's/Android-x86/Etidroid/g' "$WORK_DIR/iso-root/efi/boot/android.cfg"
    sed -i 's/if \[ -s ($android)$kdir\/install\.img \]; then/if true; then/g' "$WORK_DIR/iso-root/efi/boot/android.cfg"
    sed -i '/add_entry "\$live" quiet/a \add_entry "Installation - Install Etidroid to harddisk" INSTALL=1' "$WORK_DIR/iso-root/efi/boot/android.cfg"
    sed -i '/add_entry "Installation" INSTALL=1/d' "$WORK_DIR/iso-root/efi/boot/android.cfg"
fi

# 7. Gerar ISO bootavel hibrida com xorriso
echo "[+] Gerando ISO final $OUTPUT_ISO com xorriso..."
if [ "$IS_EFI_DUAL" = true ]; then
  xorriso -as mkisofs \
    -V "$VOL_ID" \
    -r -J -l \
    -isohybrid-mbr --interval:local_fs:0s-15s:zero_mbrpt,zero_gpt:"$BASE_ISO" \
    -partition_cyl_align on \
    -partition_offset 0 \
    -partition_hd_cyl 64 \
    -partition_sec_hd 32 \
    --mbr-force-bootable \
    --gpt-iso-not-ro \
    -iso_mbr_part_type 0x00 \
    -c '/isolinux/boot.cat' \
    -b '/isolinux/isolinux.bin' \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    -eltorito-alt-boot \
    -e '/boot/grub/efi.img' \
    -no-emul-boot \
    -boot-load-size "$EFI_LOAD_SIZE" \
    -isohybrid-gpt-basdat \
    -o "$OUTPUT_ISO" \
    "$WORK_DIR/iso-root"
else
  xorriso -as mkisofs \
    -V "$VOL_ID" \
    -r -J -l \
    -isohybrid-mbr --interval:local_fs:0s-15s:zero_mbrpt:"$BASE_ISO" \
    -partition_cyl_align on \
    -partition_offset 0 \
    -partition_hd_cyl 64 \
    -partition_sec_hd 32 \
    --mbr-force-bootable \
    -iso_mbr_part_type 0x17 \
    -c '/isolinux/boot.cat' \
    -b '/isolinux/isolinux.bin' \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    -o "$OUTPUT_ISO" \
    "$WORK_DIR/iso-root"
fi

rm -rf "$WORK_DIR"
echo "=== Sucesso! ISO gerada: $OUTPUT_ISO ==="
