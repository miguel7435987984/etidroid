# Etidroid

Sistema operacional baseado no **Android-x86 4.4-r5 (KitKat)** com bootanimation customizado.

## Recursos
- Base: Android-x86 4.4-r5
- Bootanimation customizado em 1280x720 24fps
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
```bash
./build.sh
```

A ISO será gerada no diretório raiz: `etidroid-4.4-r5.iso`.

## GitHub Actions
O repositório possui um workflow automatizado em `.github/workflows/build-release.yml` que:
1. Constrói a ISO em ambiente limpo do Ubuntu.
2. Gera os checksums SHA256 e MD5.
3. Publica automaticamente uma Release com os arquivos para download.

Para disparar manualmente:
Vá na aba **Actions** > **Build and Release Etidroid ISO** > **Run workflow**.
