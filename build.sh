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
  11.0|11|11.0-20201218)
    VERSION_TAG="11.0"
    BASE_ISO_NAME="android-x86_64-11.0-20201218.iso"
    BASE_ISO_URL="https://downloads.sourceforge.net/project/android-x86/Release%2011.0/android-x86_64-11.0-20201218.iso"
    OUTPUT_ISO="${SCRIPT_DIR}/etidroid-11.0.iso"
    IS_EFI_DUAL=true
    EFI_LOAD_SIZE=8192
    EXPAND_SIZE="3600M"
    VOL_ID="Etidroid 11.0 (x86_64)"
    ;;
  *)
    echo "Uso: $0 [4.4|5.1|7.1|8.1|9.0|10.0|11.0]"
    exit 1
    ;;
esac

BASE_ISO="${SCRIPT_DIR}/${BASE_ISO_NAME}"

echo "=== Etidroid ISO Build Script (Alvo: $VERSION_TAG) ==="

# 1. Download base ISO if not present
if [ ! -f "$BASE_ISO" ]; then
    if [ -f "/home/miguel/Downloads/${BASE_ISO_NAME}" ]; then
        echo "[+] Copiando $BASE_ISO_NAME de Downloads..."
        cp -l "/home/miguel/Downloads/${BASE_ISO_NAME}" "$BASE_ISO" 2>/dev/null || cp "/home/miguel/Downloads/${BASE_ISO_NAME}" "$BASE_ISO"
    elif [ -n "$BASE_ISO_URL" ]; then
        echo "[+] Baixando $BASE_ISO_NAME..."
        curl -L -o "$BASE_ISO" "$BASE_ISO_URL"
    fi
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
    echo "[+] Injetando script do instalador em install.img..."
    mkdir -p "$WORK_DIR/install-root"
    (cd "$WORK_DIR/install-root" && gzip -dc "$WORK_DIR/iso-root/install.img" | cpio -idmv >/dev/null 2>&1)
    mkdir -p "$WORK_DIR/install-root/scripts"
    cp "${SCRIPT_DIR}/assets/installer/1-install" "$WORK_DIR/install-root/scripts/1-install"
    chmod +x "$WORK_DIR/install-root/scripts/1-install"

    # Criar aliases de terminfo em install.img
    for t in x/xterm x/xterm-256color v/vt100 v/vt220 a/ansi u/unknown d/dumb s/screen; do
        mkdir -p "$WORK_DIR/install-root/lib/terminfo/$(dirname $t)"
        ln -sf ../l/linux "$WORK_DIR/install-root/lib/terminfo/$t" 2>/dev/null || true
    done
    mkdir -p "$WORK_DIR/install-root/usr/share" "$WORK_DIR/install-root/etc"
    ln -sf /lib/terminfo "$WORK_DIR/install-root/usr/share/terminfo" 2>/dev/null || true
    ln -sf /lib/terminfo "$WORK_DIR/install-root/etc/terminfo" 2>/dev/null || true
    if [ -f "$WORK_DIR/install-root/bin/ld-linux.so.2" ]; then
        cp -f "$WORK_DIR/install-root/bin/ld-linux.so.2" "$WORK_DIR/install-root/lib/ld-linux.so.2" 2>/dev/null || true
    fi
    find "$WORK_DIR/install-root/bin" "$WORK_DIR/install-root/sbin" -type f -exec chmod +x {} + 2>/dev/null || true
    chmod -R +x "$WORK_DIR/install-root/grub" 2>/dev/null || true

    (cd "$WORK_DIR/install-root" && find . | cpio -H newc -o 2>/dev/null | gzip -9 > "$WORK_DIR/iso-root/install.img")
fi

if [ -f "$WORK_DIR/iso-root/initrd.img" ] && [ -f "${SCRIPT_DIR}/assets/installer/1-install" ]; then
    echo "[+] Integrando instalador completo e binarios diretamente em initrd.img..."
    mkdir -p "$WORK_DIR/initrd-root"
    (cd "$WORK_DIR/initrd-root" && gzip -dc "$WORK_DIR/iso-root/initrd.img" | cpio -idmv >/dev/null 2>&1)
    if [ -d "$WORK_DIR/install-root" ]; then
        cp -a "$WORK_DIR/install-root/"* "$WORK_DIR/initrd-root/"
    fi
    mkdir -p "$WORK_DIR/initrd-root/scripts"
    cp "${SCRIPT_DIR}/assets/installer/1-install" "$WORK_DIR/initrd-root/scripts/1-install"
    chmod +x "$WORK_DIR/initrd-root/scripts/1-install"

    # Criar aliases de terminfo em initrd.img para compatibilidade com ncurses/dialog
    for t in x/xterm x/xterm-256color v/vt100 v/vt220 a/ansi u/unknown d/dumb s/screen; do
        mkdir -p "$WORK_DIR/initrd-root/lib/terminfo/$(dirname $t)"
        ln -sf ../l/linux "$WORK_DIR/initrd-root/lib/terminfo/$t" 2>/dev/null || true
    done
    mkdir -p "$WORK_DIR/initrd-root/usr/share" "$WORK_DIR/initrd-root/etc"
    ln -sf /lib/terminfo "$WORK_DIR/initrd-root/usr/share/terminfo" 2>/dev/null || true
    ln -sf /lib/terminfo "$WORK_DIR/initrd-root/etc/terminfo" 2>/dev/null || true
    if [ -f "$WORK_DIR/initrd-root/bin/ld-linux.so.2" ]; then
        cp -f "$WORK_DIR/initrd-root/bin/ld-linux.so.2" "$WORK_DIR/initrd-root/lib/ld-linux.so.2" 2>/dev/null || true
    fi

    # Patch /init para garantir exportacao de variaveis de ambiente e leitura correta de cmdline
    if [ -f "$WORK_DIR/initrd-root/init" ]; then
        python3 -c '
path = "'"$WORK_DIR"'/initrd-root/init"
with open(path, "r") as f:
    content = f.read()

# 1. Neutralizar rm /sbin/mke2fs
content = content.replace("rm /sbin/mke2fs", "# rm /sbin/mke2fs")

# 2. Configurar variáveis de ambiente logo após PATH=/...
env_block = """PATH=/sbin:/bin:/system/bin:/system/xbin; export PATH
export LC_ALL=C
export LANG=C
export TERM=linux
export TERMINFO=/lib/terminfo
export TERMINFO_DIRS=/lib/terminfo:/usr/share/terminfo:/etc/terminfo"""

if "export LC_ALL=C" not in content:
    content = content.replace("PATH=/sbin:/bin:/system/bin:/system/xbin; export PATH", env_block)

# 3. No early boot, logo após montar /proc e /sys, ler /proc/cmdline e garantir /dev/tty
early_mount = """\tbusybox mount -t proc proc /proc
\tbusybox mount -t sysfs sys /sys
\tfor c in $(cat /proc/cmdline 2>/dev/null); do
\t    case $c in
\t        INSTALL|INSTALL=*) INSTALL=1; export INSTALL ;;
\t        AUTO_INSTALL|AUTO_INSTALL=*) INSTALL=1; eval export "$c" ;;
\t        DEBUG|DEBUG=*) eval export "$c" ;;
\t    esac
\tdone
\ttest -c /dev/tty || mknod /dev/tty c 5 0"""

if "for c in $(cat /proc/cmdline 2>/dev/null);" not in content:
    content = content.replace("\tbusybox mount -t proc proc /proc\n\tbusybox mount -t sysfs sys /sys", early_mount)

# 4. No exec env HAS_CTTY=Yes setsid cttyhack, repassar todas as variaveis necessarias
content = content.replace(
    "exec env HAS_CTTY=Yes setsid",
    "exec env HAS_CTTY=Yes INSTALL=$INSTALL AUTO_INSTALL=$AUTO_INSTALL DEBUG=$DEBUG LC_ALL=C LANG=C TERM=linux TERMINFO=/lib/terminfo setsid"
)

# 5. Garantir que /src aponte confiavelmente para /mnt/$SRC
content = content.replace("ln -s mnt/$SRC /src", "ln -sf /mnt/$SRC /src 2>/dev/null; ln -sf /mnt/$SRC /android/src 2>/dev/null || true")

# 6. Garantir descompactacao de install.img usando busybox zcat caso zcat falhe
content = content.replace(
    "zcat /src/install.img",
    "(busybox zcat /src/install.img 2>/dev/null || zcat /src/install.img 2>/dev/null || gzip -dc /src/install.img 2>/dev/null)"
)

# 7. Garantir limpeza de LD_LIBRARY_PATH antes de passar controle para Android init
content = content.replace(
    "exec ${SWITCH:-switch_root} /android /init",
    "unset LD_LIBRARY_PATH\nexec ${SWITCH:-switch_root} /android /init"
)

with open(path, "w") as f:
    f.write(content)
'
    fi

    for tool in mke2fs mkfs.ext2 mkfs.ext3 mkfs.ext4 tune2fs fsck e2fsck zcat gzip gunzip dc setsid cttyhack clear; do
        ln -sf busybox "$WORK_DIR/initrd-root/bin/$tool" 2>/dev/null || true
        ln -sf ../bin/busybox "$WORK_DIR/initrd-root/sbin/$tool" 2>/dev/null || true
    done
    find "$WORK_DIR/initrd-root/bin" "$WORK_DIR/initrd-root/sbin" -type f -exec chmod +x {} + 2>/dev/null || true
    chmod -R +x "$WORK_DIR/initrd-root/grub" 2>/dev/null || true
    (cd "$WORK_DIR/initrd-root" && find . | cpio -H newc -o 2>/dev/null | gzip -9 > "$WORK_DIR/iso-root/initrd.img")
    rm -rf "$WORK_DIR/initrd-root" "$WORK_DIR/install-root"
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

    echo "[+] Garantindo compatibilidade de init e hardware HAL para SAR (android_x86)..."
    debugfs -R "dump init.android_x86_64.rc \"$WORK_DIR/init.rc.tmp\"" "$IMG" 2>/dev/null || true
    if [ -f "$WORK_DIR/init.rc.tmp" ]; then
        sed -i 's/setprop status.battery.state Slow/setprop status.battery.state Charged/g' "$WORK_DIR/init.rc.tmp"
        sed -i 's/setprop status.battery.level 5/setprop status.battery.level 10/g' "$WORK_DIR/init.rc.tmp"
        sed -i 's/setprop status.battery.level_raw  50/setprop status.battery.level_raw 100/g' "$WORK_DIR/init.rc.tmp"
        sed -i 's/setprop status.battery.level_scale 9/setprop status.battery.level_scale 10/g' "$WORK_DIR/init.rc.tmp"
        debugfs -w -R "rm init.android_x86.rc" "$IMG" 2>/dev/null || true
        debugfs -w -R "write \"$WORK_DIR/init.rc.tmp\" init.android_x86.rc" "$IMG" 2>/dev/null || true
        debugfs -w -R "sif init.android_x86.rc mode 0100750" "$IMG" 2>/dev/null || true
        debugfs -w -R "rm init.android_x86_64.rc" "$IMG" 2>/dev/null || true
        debugfs -w -R "write \"$WORK_DIR/init.rc.tmp\" init.android_x86_64.rc" "$IMG" 2>/dev/null || true
        debugfs -w -R "sif init.android_x86_64.rc mode 0100750" "$IMG" 2>/dev/null || true
    fi
    debugfs -R "dump fstab.android_x86_64 \"$WORK_DIR/fstab.tmp\"" "$IMG" 2>/dev/null || true
    if [ -f "$WORK_DIR/fstab.tmp" ]; then
        if [ "$VERSION_TAG" = "11.0" ] && ! grep -q "^system[[:space:]]" "$WORK_DIR/fstab.tmp"; then
            sed -i '1i system\t\t/system\t\text4\tro\tdefaults' "$WORK_DIR/fstab.tmp"
            debugfs -w -R "rm fstab.android_x86_64" "$IMG" 2>/dev/null || true
            debugfs -w -R "write \"$WORK_DIR/fstab.tmp\" fstab.android_x86_64" "$IMG" 2>/dev/null || true
            debugfs -w -R "sif fstab.android_x86_64 mode 0100640" "$IMG" 2>/dev/null || true
        fi
        debugfs -w -R "rm fstab.android_x86" "$IMG" 2>/dev/null || true
        debugfs -w -R "write \"$WORK_DIR/fstab.tmp\" fstab.android_x86" "$IMG" 2>/dev/null || true
        debugfs -w -R "sif fstab.android_x86 mode 0100640" "$IMG" 2>/dev/null || true
    fi
    debugfs -R "dump ueventd.android_x86_64.rc \"$WORK_DIR/ueventd.tmp\"" "$IMG" 2>/dev/null || true
    if [ -f "$WORK_DIR/ueventd.tmp" ]; then
        debugfs -w -R "rm ueventd.android_x86.rc" "$IMG" 2>/dev/null || true
        debugfs -w -R "write \"$WORK_DIR/ueventd.tmp\" ueventd.android_x86.rc" "$IMG" 2>/dev/null || true
        debugfs -w -R "sif ueventd.android_x86.rc mode 0100644" "$IMG" 2>/dev/null || true
    fi
    debugfs -R "dump default.prop \"$WORK_DIR/default.prop\"" "$IMG" 2>/dev/null || true
    if [ -f "$WORK_DIR/default.prop" ]; then
        sed -i 's/pm.dexopt.first-boot=quicken/pm.dexopt.first-boot=verify/g' "$WORK_DIR/default.prop"
        sed -i 's/ro.secure=1/ro.secure=0/g' "$WORK_DIR/default.prop"
        sed -i 's/ro.adb.secure=1/ro.adb.secure=0/g' "$WORK_DIR/default.prop"
        if [ "$VERSION_TAG" = "10.0" ]; then
            echo "ro.hardware.gralloc=gbm" >> "$WORK_DIR/default.prop"
            echo "ro.hardware.hwcomposer=drm" >> "$WORK_DIR/default.prop"
        fi
        echo "service.adb.tcp.port=5555" >> "$WORK_DIR/default.prop"
        debugfs -w -R "rm default.prop" "$IMG" 2>/dev/null || true
        debugfs -w -R "write \"$WORK_DIR/default.prop\" default.prop" "$IMG" 2>/dev/null || true
        debugfs -w -R "sif default.prop mode 0100600" "$IMG" 2>/dev/null || true
    fi

    echo "[+] Injetando simulador de bateria e supressão de cursor em init.sh..."
    INIT_SH_PATH="system/etc/init.sh"
    debugfs -R "dump $INIT_SH_PATH \"$WORK_DIR/init.sh.tmp\"" "$IMG" 2>/dev/null || debugfs -R "dump etc/init.sh \"$WORK_DIR/init.sh.tmp\"" "$IMG" 2>/dev/null || true
    if [ -f "$WORK_DIR/init.sh.tmp" ]; then
        python3 -c '
path = "'"$WORK_DIR"'/init.sh.tmp"
with open(path, "r") as f:
    c = f.read()

mock = """\techo 0 > /sys/class/graphics/fbcon/cursor_blink 2>/dev/null || true
\techo -en "\\033[?25l" > /dev/tty0 2>/dev/null || true
\tif [ ! -d /sys/class/power_supply/BAT0 -a ! -d /sys/class/power_supply/battery ]; then
\t\tmount -t tmpfs -o mode=0755,context=u:object_r:sysfs:s0 tmpfs /sys/class/power_supply 2>/dev/null || mount -t tmpfs -o mode=0755 tmpfs /sys/class/power_supply
\t\tmkdir -p /sys/class/power_supply/AC /sys/class/power_supply/BAT0
\t\techo "Mains" > /sys/class/power_supply/AC/type
\t\techo "1" > /sys/class/power_supply/AC/online
\t\techo "Battery" > /sys/class/power_supply/BAT0/type
\t\techo "Full" > /sys/class/power_supply/BAT0/status
\t\techo "Good" > /sys/class/power_supply/BAT0/health
\t\techo "1" > /sys/class/power_supply/BAT0/present
\t\techo "100" > /sys/class/power_supply/BAT0/capacity
\t\techo "4200000" > /sys/class/power_supply/BAT0/voltage_now
\t\techo "250" > /sys/class/power_supply/BAT0/temp
\t\techo "Li-ion" > /sys/class/power_supply/BAT0/technology
\t\tchmod -R 755 /sys/class/power_supply
\t\tchmod 644 /sys/class/power_supply/AC/* /sys/class/power_supply/BAT0/* 2>/dev/null || true
\tfi
"""
target = "function do_init()\\n{\\n"
if target in c and "power_supply/BAT0" not in c:
    c = c.replace(target, target + mock)
    with open(path, "w") as f:
        f.write(c)
'
        debugfs -w -R "rm $INIT_SH_PATH" "$IMG" 2>/dev/null || true
        debugfs -w -R "write \"$WORK_DIR/init.sh.tmp\" $INIT_SH_PATH" "$IMG" 2>/dev/null || true
        debugfs -w -R "sif $INIT_SH_PATH mode 0100755" "$IMG" 2>/dev/null || true
        debugfs -w -R "ea_set $INIT_SH_PATH security.selinux u:object_r:system_file:s0\\000" "$IMG" 2>/dev/null || true
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

# Injetar patches gráficos de compatibilidade (Mesa Gallium e HWC)
PATCH_DIR=""
if [ -d "${SCRIPT_DIR}/patches/${VERSION_TAG}" ]; then
    PATCH_DIR="${SCRIPT_DIR}/patches/${VERSION_TAG}"
elif [ "$VERSION_TAG" = "10.0" ] && [ -d "${SCRIPT_DIR}/patches" ]; then
    PATCH_DIR="${SCRIPT_DIR}/patches"
fi

if [ -n "$PATCH_DIR" ]; then
    echo "[+] Injetando patches gráficos de $PATCH_DIR..."
    if [ -f "${PATCH_DIR}/gralloc.gbm.so" ]; then
        debugfs -w -R "rm system/vendor/lib64/hw/gralloc.gbm.so" "$IMG" 2>/dev/null || true
        debugfs -w -R "write \"${PATCH_DIR}/gralloc.gbm.so\" system/vendor/lib64/hw/gralloc.gbm.so" "$IMG" 2>/dev/null || true
        debugfs -w -R "sif system/vendor/lib64/hw/gralloc.gbm.so mode 0100644" "$IMG" 2>/dev/null || true
        debugfs -w -R "sif system/vendor/lib64/hw/gralloc.gbm.so uid 0" "$IMG" 2>/dev/null || true
        debugfs -w -R "sif system/vendor/lib64/hw/gralloc.gbm.so gid 0" "$IMG" 2>/dev/null || true
        debugfs -w -R "ea_set system/vendor/lib64/hw/gralloc.gbm.so security.selinux u:object_r:vendor_file:s0\000" "$IMG" 2>/dev/null || true
    fi
    if [ -f "${PATCH_DIR}/libGLES_mesa_patched.so" ]; then
        debugfs -w -R "rm system/vendor/lib64/egl/libGLES_mesa.so" "$IMG" 2>/dev/null || true
        debugfs -w -R "write \"${PATCH_DIR}/libGLES_mesa_patched.so\" system/vendor/lib64/egl/libGLES_mesa.so" "$IMG" 2>/dev/null || true
        debugfs -w -R "sif system/vendor/lib64/egl/libGLES_mesa.so mode 0100644" "$IMG" 2>/dev/null || true
        debugfs -w -R "sif system/vendor/lib64/egl/libGLES_mesa.so uid 0" "$IMG" 2>/dev/null || true
        debugfs -w -R "sif system/vendor/lib64/egl/libGLES_mesa.so gid 0" "$IMG" 2>/dev/null || true
        debugfs -w -R "ea_set system/vendor/lib64/egl/libGLES_mesa.so security.selinux u:object_r:vendor_file:s0\000" "$IMG" 2>/dev/null || true
    fi
    if [ -f "${PATCH_DIR}/libGLES_mesa_32_patched.so" ]; then
        debugfs -w -R "rm system/vendor/lib/egl/libGLES_mesa.so" "$IMG" 2>/dev/null || true
        debugfs -w -R "write \"${PATCH_DIR}/libGLES_mesa_32_patched.so\" system/vendor/lib/egl/libGLES_mesa.so" "$IMG" 2>/dev/null || true
        debugfs -w -R "sif system/vendor/lib/egl/libGLES_mesa.so mode 0100644" "$IMG" 2>/dev/null || true
        debugfs -w -R "sif system/vendor/lib/egl/libGLES_mesa.so uid 0" "$IMG" 2>/dev/null || true
        debugfs -w -R "sif system/vendor/lib/egl/libGLES_mesa.so gid 0" "$IMG" 2>/dev/null || true
        debugfs -w -R "ea_set system/vendor/lib/egl/libGLES_mesa.so security.selinux u:object_r:vendor_file:s0\000" "$IMG" 2>/dev/null || true
    fi
    if [ -f "${PATCH_DIR}/libhwc2onfbadapter_patched.so" ]; then
        debugfs -w -R "rm system/vendor/lib64/libhwc2onfbadapter.so" "$IMG" 2>/dev/null || true
        debugfs -w -R "write \"${PATCH_DIR}/libhwc2onfbadapter_patched.so\" system/vendor/lib64/libhwc2onfbadapter.so" "$IMG" 2>/dev/null || true
        debugfs -w -R "sif system/vendor/lib64/libhwc2onfbadapter.so mode 0100644" "$IMG" 2>/dev/null || true
        debugfs -w -R "sif system/vendor/lib64/libhwc2onfbadapter.so uid 0" "$IMG" 2>/dev/null || true
        debugfs -w -R "sif system/vendor/lib64/libhwc2onfbadapter.so gid 0" "$IMG" 2>/dev/null || true
        debugfs -w -R "ea_set system/vendor/lib64/libhwc2onfbadapter.so security.selinux u:object_r:vendor_file:s0\000" "$IMG" 2>/dev/null || true
    fi
    if [ -f "${PATCH_DIR}/libhwc2onfbadapter_32_patched.so" ]; then
        debugfs -w -R "rm system/vendor/lib/libhwc2onfbadapter.so" "$IMG" 2>/dev/null || true
        debugfs -w -R "write \"${PATCH_DIR}/libhwc2onfbadapter_32_patched.so\" system/vendor/lib/libhwc2onfbadapter.so" "$IMG" 2>/dev/null || true
        debugfs -w -R "sif system/vendor/lib/libhwc2onfbadapter.so mode 0100644" "$IMG" 2>/dev/null || true
        debugfs -w -R "sif system/vendor/lib/libhwc2onfbadapter.so uid 0" "$IMG" 2>/dev/null || true
        debugfs -w -R "sif system/vendor/lib/libhwc2onfbadapter.so gid 0" "$IMG" 2>/dev/null || true
        debugfs -w -R "ea_set system/vendor/lib/libhwc2onfbadapter.so security.selinux u:object_r:vendor_file:s0\000" "$IMG" 2>/dev/null || true
    fi
fi

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
    sed -i 's/append initrd=\/initrd\.img root=\/dev\/ram0 quiet SRC= DATA=/append initrd=\/initrd.img root=\/dev\/ram0 quiet androidboot.hardware=android_x86 vt.global_cursor_default=0 androidboot.selinux=permissive SRC= DATA=/g' "$WORK_DIR/iso-root/isolinux/isolinux.cfg"
    python3 -c '
import re
path = "'"$WORK_DIR"'/iso-root/isolinux/isolinux.cfg"
try:
    with open(path, "r") as f:
        c = f.read()
    c = re.sub(r"timeout \d+", "timeout 50", c)
    m = re.search(r"\n(label install\n\tmenu label [^\n]+\n\tkernel [^\n]+\n\tappend [^\n]+)", c)
    if m:
        inst = m.group(1)
        inst = re.sub(r"append [^\n]+", "append initrd=/initrd.img root=/dev/ram0 androidboot.hardware=android_x86 INSTALL=1\n\tmenu default", inst)
        c = c.replace(m.group(0), "")
        c = re.sub(r"(label livem\n\tmenu label [^\n]+\n\tkernel [^\n]+\n\tappend [^\n]+)", inst + r"\n\n\1", c)
        with open(path, "w") as f:
            f.write(c)
except Exception:
    pass
'
fi
if [ -f "$WORK_DIR/iso-root/boot/grub/grub.cfg" ]; then
    sed -i 's/Android-x86/Etidroid/g' "$WORK_DIR/iso-root/boot/grub/grub.cfg"
    sed -i 's/set timeout=.*/set timeout=5\nset default=0/g' "$WORK_DIR/iso-root/boot/grub/grub.cfg"
fi
if [ -f "$WORK_DIR/iso-root/efi/boot/grub.cfg" ]; then
    sed -i 's/Android-x86/Etidroid/g' "$WORK_DIR/iso-root/efi/boot/grub.cfg"
    sed -i "s/Etidroid VER/Etidroid $VERSION_TAG/g" "$WORK_DIR/iso-root/efi/boot/grub.cfg"
    sed -i 's/CMDLINE/androidboot.hardware=android_x86 vt.global_cursor_default=0 androidboot.selinux=permissive/g' "$WORK_DIR/iso-root/efi/boot/grub.cfg"
    sed -i 's/set timeout=.*/set timeout=5\nset default=0/g' "$WORK_DIR/iso-root/efi/boot/grub.cfg"
fi
if [ -f "$WORK_DIR/iso-root/efi/boot/android.cfg" ]; then
    sed -i 's/Android-x86/Etidroid/g' "$WORK_DIR/iso-root/efi/boot/android.cfg"
    sed -i 's/if \[ -s ($android)$kdir\/install\.img \]; then/if true; then/g' "$WORK_DIR/iso-root/efi/boot/android.cfg"
    sed -i '1i set default=0\nset timeout=5' "$WORK_DIR/iso-root/efi/boot/android.cfg"
    sed -i 's/add_entry "\$live" quiet$/add_entry "$live" quiet androidboot.hardware=android_x86 vt.global_cursor_default=0 androidboot.selinux=permissive/g' "$WORK_DIR/iso-root/efi/boot/android.cfg"
    sed -i '/add_entry "\$live"/i \
\
menuentry "Installation - Install Etidroid to harddisk" --class android-x86 {\
	savedefault\
	set root=$android\
	if [ ! -e $kdir/kernel ]; then\
		search --no-floppy --set root -f $kdir/kernel\
	fi\
	linux $kdir/kernel root=/dev/ram0 $src androidboot.hardware=android_x86 INSTALL=1\
	initrd $kdir/initrd.img\
}\
' "$WORK_DIR/iso-root/efi/boot/android.cfg"
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
