# Etidroid

Sistema operacional baseado no **Android-x86** com bootanimation customizado.

## Versões Disponíveis
- **Etidroid 13.0 (Android 13 x86_64)**: Base Bliss OS 16 (Android 13 Tiramisu, 64-bit, EROFS/SAR, UEFI/MBR)
- **Etidroid 12.0 (Android 12 x86_64)**: Base Android-Generic a12_r27 (64-bit, System-as-Root, GRUB2, UEFI/MBR)
- **Etidroid 11.0 (Android 11 x86_64)**: Base Android-Generic 11.0 (64-bit, System-as-Root, UEFI/MBR)
- **Etidroid 10.0 (Android 10 x86_64)**: Base Android-x86_64 10.0 (64-bit, System-as-Root, UEFI/MBR)
- **Etidroid 9.0-r2-k49 (Pie x86_64, Kernel 4.9)**: Base Android-x86_64 9.0-r2-k49 (64-bit, UEFI/MBR, ideal para VMware/VirtualBox)
- **Etidroid 8.1-r6 (Oreo x86_64)**: Base Android-x86_64 8.1-r6 (64-bit, UEFI/MBR)
- **Etidroid 7.1-r5 (Nougat x86_64)**: Base Android-x86_64 7.1-r5 (64-bit, UEFI/MBR)
- **Etidroid 5.1-rc1 (Lollipop)**: Base Android-x86 5.1-rc1 (32-bit)
- **Etidroid 4.4-r5 (KitKat)**: Base Android-x86 4.4-r5 (32-bit)

## Recursos
- Bootanimation customizado em 1280x720 24fps
- Wallpaper padrão Etidroid em 1080p integrado ao sistema
- Suporte a boot híbrido (BIOS MBR e UEFI GPT)
- Identificação do produto ajustada para Etidroid

## Como compilar localmente

### Pré-requisitos
No Ubuntu/Debian:
```bash
sudo apt-get update
sudo apt-get install -y ffmpeg squashfs-tools xorriso p7zip-full e2fsprogs zip curl erofs-utils
```

### Executar a compilação
Para compilar Etidroid 13.0 (64-bit):
```bash
./build.sh 13.0
```

Para compilar Etidroid 12.0 (64-bit):
```bash
./build.sh 12.0
```

Para compilar Etidroid 11.0 (64-bit):
```bash
./build.sh 11.0
```

Para compilar Etidroid 10.0 (64-bit):
```bash
./build.sh 10.0
```

Para compilar Etidroid 9.0-r2-k49 (64-bit):
```bash
./build.sh 9.0
```

Para compilar Etidroid 8.1-r6 (64-bit):
```bash
./build.sh 8.1
```

Para compilar Etidroid 7.1-r5 (64-bit):
```bash
./build.sh 7.1
```

Para compilar Etidroid 5.1-rc1:
```bash
./build.sh 5.1
```

Para compilar Etidroid 4.4-r5:
```bash
./build.sh 4.4
```

A ISO será gerada no diretório raiz:
- `etidroid-13.0.iso`
- `etidroid-12.0.iso`
- `etidroid-11.0.iso`
- `etidroid-10.0.iso`
- `etidroid-9.0-r2-k49.iso`
- `etidroid-8.1-r6.iso`
- `etidroid-7.1-r5.iso`
- `etidroid-5.1-rc1.iso`
- `etidroid-4.4-r5.iso`

## GitHub Actions
O repositório possui um workflow automatizado em `.github/workflows/build-release.yml` que compila e publica as releases automaticamente no GitHub para todas as versões suportadas (`4.4`, `5.1`, `7.1`, `8.1`, `9.0`, `10.0`, `11.0`, `12.0`, `13.0`).
