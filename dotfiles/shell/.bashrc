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
