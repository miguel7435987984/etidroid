# Etidroid

Sistema operacional baseado no **Android-x86** com bootanimation customizado.

## Versões Disponíveis
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
sudo apt-get install -y ffmpeg squashfs-tools xorriso p7zip-full e2fsprogs zip curl
```

### Executar a compilação
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
- `etidroid-9.0-r2-k49.iso`
- `etidroid-8.1-r6.iso`
- `etidroid-7.1-r5.iso`
- `etidroid-5.1-rc1.iso`
- `etidroid-4.4-r5.iso`

## GitHub Actions
O repositório possui um workflow automatizado em `.github/workflows/build-release.yml` que compila e publica as releases automaticamente no GitHub para todas as versões suportadas (`4.4`, `5.1`, `7.1`, `8.1`, `9.0`).
