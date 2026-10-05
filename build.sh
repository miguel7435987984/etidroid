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
  *)
    echo "Uso: $0 [4.4|5.1|7.1|8.1]"
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

# 4. Extrair e modificar system.img
echo "[+] Descompactando system.sfs..."
mkdir -p "$WORK_DIR/sfs-root"
unsquashfs -no-xattrs -d "$WORK_DIR/sfs-root" "$WORK_DIR/iso-root/system.sfs"

IMG="$WORK_DIR/sfs-root/system.img"
echo "[+] Redimensionando system.img para $EXPAND_SIZE..."
truncate -s "$EXPAND_SIZE" "$IMG"
e2fsck -f -y "$IMG" || true
resize2fs "$IMG"

echo "[+] Extraindo e ajustando build.prop..."
debugfs -R "dump build.prop \"$WORK_DIR/build.prop\"" "$IMG"
sed -i 's/ro.product.model=Generic Android-x86_64/ro.product.model=Etidroid/g' "$WORK_DIR/build.prop"
sed -i 's/ro.product.model=Generic Android-x86/ro.product.model=Etidroid/g' "$WORK_DIR/build.prop"
sed -i 's/ro.product.brand=Android-x86/ro.product.brand=Etidroid/g' "$WORK_DIR/build.prop"
sed -i "s/ro.build.display.id=.*/ro.build.display.id=Etidroid $VERSION_TAG/g" "$WORK_DIR/build.prop"
sed -i '/ro.config.wallpaper/d' "$WORK_DIR/build.prop"
sed -i '/ro.config.lock_wallpaper/d' "$WORK_DIR/build.prop"
echo "ro.config.wallpaper=/system/media/default_wallpaper.jpg" >> "$WORK_DIR/build.prop"
echo "ro.config.lock_wallpaper=/system/media/default_wallpaper.jpg" >> "$WORK_DIR/build.prop"

echo "[+] Injetando arquivos no system.img via debugfs..."
debugfs -w -R "rm media/bootanimation.zip" "$IMG" 2>/dev/null || true
debugfs -w -R "write \"$WORK_DIR/bootanimation.zip\" media/bootanimation.zip" "$IMG"
debugfs -w -R "sif media/bootanimation.zip mode 0100644" "$IMG"
debugfs -w -R "sif media/bootanimation.zip uid 0" "$IMG"
debugfs -w -R "sif media/bootanimation.zip gid 0" "$IMG"
debugfs -w -R "ea_set media/bootanimation.zip security.selinux u:object_r:system_file:s0\000" "$IMG"

if [ -f "$WALLPAPER_INPUT" ]; then
    echo "[+] Injetando wallpaper padrão no system.img..."
    debugfs -w -R "rm media/default_wallpaper.jpg" "$IMG" 2>/dev/null || true
    debugfs -w -R "write \"$WALLPAPER_INPUT\" media/default_wallpaper.jpg" "$IMG"
    debugfs -w -R "sif media/default_wallpaper.jpg mode 0100644" "$IMG"
    debugfs -w -R "sif media/default_wallpaper.jpg uid 0" "$IMG"
    debugfs -w -R "sif media/default_wallpaper.jpg gid 0" "$IMG"
    debugfs -w -R "ea_set media/default_wallpaper.jpg security.selinux u:object_r:system_file:s0\000" "$IMG"

    debugfs -w -R "rm etc/default_wallpaper.jpg" "$IMG" 2>/dev/null || true
    debugfs -w -R "write \"$WALLPAPER_INPUT\" etc/default_wallpaper.jpg" "$IMG"
    debugfs -w -R "sif etc/default_wallpaper.jpg mode 0100644" "$IMG"
    debugfs -w -R "sif etc/default_wallpaper.jpg uid 0" "$IMG"
    debugfs -w -R "sif etc/default_wallpaper.jpg gid 0" "$IMG"
    debugfs -w -R "ea_set etc/default_wallpaper.jpg security.selinux u:object_r:system_file:s0\000" "$IMG"
fi

debugfs -w -R "rm build.prop" "$IMG"
debugfs -w -R "write \"$WORK_DIR/build.prop\" build.prop" "$IMG"
debugfs -w -R "sif build.prop mode 0100644" "$IMG"
debugfs -w -R "sif build.prop uid 0" "$IMG"
debugfs -w -R "sif build.prop gid 0" "$IMG"
debugfs -w -R "ea_set build.prop security.selinux u:object_r:system_file:s0\000" "$IMG"

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
