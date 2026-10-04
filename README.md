# Etidroid

Sistema operacional baseado no **Android-x86** com bootanimation customizado.

## Versões Disponíveis
- **Etidroid 5.1-rc1 (Lollipop)**: Base Android-x86 5.1-rc1
- **Etidroid 4.4-r5 (KitKat)**: Base Android-x86 4.4-r5

## Recursos
- Bootanimation customizado em 1280x720 24fps
- Suporte a boot híbrido (BIOS MBR e UEFI)
- Identificação do produto ajustada para Etidroid

## Como compilar localmente

### Pré-requisitos
No Ubuntu/Debian:
```bash
sudo apt-get update
sudo apt-get install -y ffmpeg squashfs-tools xorriso p7zip-full e2fsprogs zip curl
```

### Executar a compilação
Para compilar Etidroid 5.1-rc1:
```bash
./build.sh 5.1
```

Para compilar Etidroid 4.4-r5:
```bash
./build.sh 4.4
```

A ISO será gerada no diretório raiz: `etidroid-5.1-rc1.iso` ou `etidroid-4.4-r5.iso`.

## GitHub Actions
O repositório possui um workflow automatizado em `.github/workflows/build-release.yml` que constrói e publica as releases automaticamente no GitHub.
