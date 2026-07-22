# arch-msi

Configuración reproducible, versionada y documentada de una instalación de
**Arch Linux** sobre un portátil **MSI Summit E16 AI Studio A1VFTG** en dual boot
con Windows.

El objetivo es que este repositorio sea, gradualmente, la **fuente de verdad**
de la configuración: documentada, modular, auditable y restaurable tras una
reinstalación. La configuración se despliega con **GNU Stow** (enlaces
simbólicos), migrando un componente cada vez y verificando después de cada paso.

## Hardware objetivo

MSI Summit E16 AI Studio A1VFTG · Intel Core Ultra 7 155H · Intel Arc + NVIDIA
RTX 4060 (híbrido) · 16 GB LPDDR5 · NVMe 1 TB · Wi-Fi 7. Detalle completo en
[`docs/hardware.md`](docs/hardware.md).

## Estado del repositorio

En construcción. La documentación de base ya refleja una auditoría no
destructiva completa del sistema real (2026-07-22). La migración de dotfiles a
Stow **está en curso**: Hyprland y shell (`.bashrc`, `.bash_profile`) ya están
migrados y validados. Ver el estado detallado en
[`docs/PROJECT_CONTEXT.md`](docs/PROJECT_CONTEXT.md).

## ⚠️ Advertencia de dual boot

El equipo comparte disco con Windows. La partición **EFI es compartida** y las
particiones de Windows/MSI (`nvme0n1p1`–`p5`) **no deben tocarse**. No formatear,
redimensionar ni reparticionar sin un plan aprobado y copia de seguridad. No
cambiar el bootloader (GRUB) ni la disposición de subvolúmenes Btrfs sin lo
mismo.

## Auditar antes de aplicar

El estado real del equipo tiene prioridad sobre cualquier documento. Antes de
aplicar cambios: inspeccionar, explicar el estado actual, proponer un plan,
mostrar el diff, validar y saber cómo revertir. Los cambios se hacen pequeños,
específicos y reversibles. Ver las reglas operativas en [`CLAUDE.md`](CLAUDE.md)
y [`AGENTS.md`](AGENTS.md).

## Componentes gestionados

| Área          | Estado                                              |
|---------------|-----------------------------------------------------|
| Documentación | `docs/` — contexto, hardware, cronología            |
| Inventarios   | `packages/` — pacman, AUR, npm, servicios           |
| Dotfiles      | `dotfiles/` — Hyprland y shell primero (pendiente)  |
| Scripts       | `scripts/` — utilidades de mantenimiento (futuro)   |

## Restauración (alto nivel)

1. Instalar Arch base con la misma disposición Btrfs (`@`, `@home`) y GRUB.
2. Reinstalar paquetes desde `packages/`.
3. Rehabilitar servicios (ver `packages/services-enabled.txt`).
4. Clonar este repo en `~/Projects/arch-msi` y desplegar dotfiles con Stow,
   componente a componente.
5. Reinstalar herramientas de IA (Codex, Claude Code) como usuario normal.

## Estructura

```
arch-msi/
├── README.md
├── CLAUDE.md          # reglas operativas para Claude Code
├── AGENTS.md          # reglas operativas para Codex (referencia a CLAUDE.md)
├── .gitignore
├── docs/
│   ├── PROJECT_CONTEXT.md
│   ├── hardware.md
│   ├── keybindings.md
│   └── history/chatgpt-arch-installation.md
└── packages/
    ├── pacman-explicit.txt
    ├── aur.txt
    ├── npm-global.txt
    └── services-enabled.txt
```

Los directorios `dotfiles/` y `scripts/` se crearán cuando se migre el primer
componente, no antes (nada de carpetas vacías).
