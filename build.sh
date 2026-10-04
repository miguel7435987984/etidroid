#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="${SCRIPT_DIR}/build_tmp"
OUTPUT_ISO="${SCRIPT_DIR}/etidroid-4.4-r5.iso"
BASE_ISO="${SCRIPT_DIR}/android-x86-4.4-r5.iso"
VIDEO_INPUT="${SCRIPT_DIR}/assets/bootanimation.mp4"

BASE_ISO_URL="https://downloads.sourceforge.net/project/android-x86/Release%204.4/android-x86-4.4-r5.iso"

echo "=== Etidroid ISO Build Script ==="

# 1. Download base ISO if not present
if [ ! -f "$BASE_ISO" ]; then
    echo "[+] Baixando Android-x86 4.4-r5 base ISO..."
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
unsquashfs -d "$WORK_DIR/sfs-root" "$WORK_DIR/iso-root/system.sfs"

IMG="$WORK_DIR/sfs-root/system.img"
echo "[+] Redimensionando system.img..."
truncate -s 1250M "$IMG"
e2fsck -f -y "$IMG" || true
resize2fs "$IMG"

echo "[+] Extraindo e ajustando build.prop..."
debugfs -R "dump build.prop $WORK_DIR/build.prop" "$IMG"
sed -i 's/ro.product.model=Generic Android-x86/ro.product.model=Etidroid/g' "$WORK_DIR/build.prop"
sed -i 's/ro.product.brand=Android-x86/ro.product.brand=Etidroid/g' "$WORK_DIR/build.prop"
sed -i 's/ro.build.display.id=.*/ro.build.display.id=Etidroid 4.4-r5/g' "$WORK_DIR/build.prop"

echo "[+] Injetando arquivos no system.img via debugfs..."
debugfs -w -R "rm media/bootanimation.zip" "$IMG" 2>/dev/null || true
debugfs -w -R "write $WORK_DIR/bootanimation.zip media/bootanimation.zip" "$IMG"
debugfs -w -R "sif media/bootanimation.zip mode 0100644" "$IMG"
debugfs -w -R "sif media/bootanimation.zip uid 0" "$IMG"
debugfs -w -R "sif media/bootanimation.zip gid 0" "$IMG"
debugfs -w -R "ea_set media/bootanimation.zip security.selinux u:object_r:system_file:s0\000" "$IMG"

debugfs -w -R "rm build.prop" "$IMG"
debugfs -w -R "write $WORK_DIR/build.prop build.prop" "$IMG"
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
echo "[+] Atualizando menus isolinux e grub..."
sed -i 's/Android-x86/Etidroid/g' "$WORK_DIR/iso-root/isolinux/isolinux.cfg"
sed -i 's/Android-x86/Etidroid/g' "$WORK_DIR/iso-root/boot/grub/grub.cfg"

# 7. Gerar ISO bootavel hibrida com xorriso
echo "[+] Gerando ISO final $OUTPUT_ISO com xorriso..."
xorriso -as mkisofs \
  -V 'Etidroid LiveCD' \
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
  -boot-load-size 6144 \
  -isohybrid-gpt-basdat \
  -o "$OUTPUT_ISO" \
  "$WORK_DIR/iso-root"

rm -rf "$WORK_DIR"
echo "=== Sucesso! ISO gerada: $OUTPUT_ISO ==="
