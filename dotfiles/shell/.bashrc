#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '


# --- fastfetch ---------------------------------------------------------------
# MISMO LOGO SIEMPRE, cambia solo la disposición.
#
# fastfetch no adapta su salida al tamaño de la terminal: emite las líneas
# enteras y deja que el terminal las parta, y con el logo a la izquierda eso
# destroza el dibujo. El ancho necesario es distinto según dónde vaya el logo:
#
#     al lado  →  38 (dibujo) + 56 (texto) = 96 columnas mínimas  [medido]
#     arriba   →  max(38, 56)              = 56 columnas mínimas
#
# La config generada usa "top", que cabe en cualquier ventana. Esta función
# recupera la disposición horizontal cuando hay sitio de sobra: a pantalla
# completa este panel da ~181 columnas y a media pantalla ~90, así que el umbral
# de 100 separa limpiamente los dos casos con margen.
fastfetch() {
    local cols=${COLUMNS:-$(tput cols 2>/dev/null || echo 80)}
    if [ "$cols" -ge 100 ]; then
        command fastfetch --logo-position left --logo-padding-right 3 "$@"
    else
        command fastfetch "$@"
    fi
}


# --- Editor ------------------------------------------------------------------
# ARREGLA UN FALLO REAL, no es una preferencia. `EDITOR` estaba sin definir, y
# el opener de texto de yazi es `${EDITOR:-vi} %s`: caía a `vi`, que en este
# equipo NO EXISTE —comprobado, ningún paquete lo provee; solo está `vim`—, así
# que abrir un archivo de texto desde yazi fallaba. Definirlo aquí lo arregla de
# raíz y de paso sirve a git, `systemctl edit` y cualquier otro programa que
# respete la variable.
export EDITOR=vim


# --- yazi --------------------------------------------------------------------
# DEJA LA SHELL EN EL DIRECTORIO DONDE ESTABAS AL SALIR, que es lo que convierte
# a yazi en una herramienta de navegación y no solo en un visor.
#
# La función es necesaria porque un proceso hijo NO puede cambiar el directorio
# de su padre: yazi escribe el suyo en un archivo temporal (`--cwd-file`) y el
# `cd` lo hace la shell, aquí.
#
# Con `y` se cambia de directorio; invocando `yazi` a secas NO, que es la vía de
# escape si alguna vez estorba. Y dentro del programa la distinción sigue
# existiendo: `q` guarda el directorio y `Q` sale sin guardarlo.
#
# Sin rutas fijas: `mktemp` respeta TMPDIR y el archivo se borra siempre, salga
# yazi como salga.
y() {
    local tmp cwd
    tmp="$(mktemp -t "yazi-cwd.XXXXXX")" || return 1
    yazi "$@" --cwd-file="$tmp"
    IFS= read -r -d '' cwd < "$tmp"
    [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
    rm -f -- "$tmp"
}
