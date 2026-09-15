#!/usr/bin/env bash
#
# Selector de símbolos que no están en el teclado: griegas, operadores
# matemáticos, conjuntos, flechas y sub/superíndices. Abre un menú de rofi,
# se busca escribiendo (en castellano o por el nombre LaTeX) y el símbolo
# elegido se escribe en la ventana que estuviera enfocada. Funciona como
# usuario normal (sin sudo).
#
# Uso: simbolos            abre el menú
#      simbolos --lista    vuelca el catálogo por stdout (para comprobarlo)
#
# POR QUÉ UN MENÚ Y NO UNA DISTRIBUCIÓN GRIEGA NI UNA TECLA COMPOSE. Las otras
# dos vías obligan a recordar una pulsación distinta por símbolo; aquí se busca
# por NOMBRE, que es lo que uno tiene en la cabeza al escribir apuntes ("no sé
# qué tecla es la delta, pero sé que se llama delta"). Además Super+Espacio ya
# rota entre es y us, y meter una tercera distribución en esa rotación se
# vuelve incómodo (ver kb-layout.sh).
#
# CÓMO LLEGA EL SÍMBOLO A LA VENTANA. Hay dos caminos y se usan los dos:
#
#   1. wtype  — teclea el carácter en la ventana enfocada, como si lo hubieras
#               pulsado. Es lo cómodo. NO viene instalado por defecto en este
#               equipo; si falta, el script no se rompe, solo se queda en (2).
#   2. wl-copy — deja el símbolo en el portapapeles para pegarlo con Ctrl+V.
#
# Se copia SIEMPRE, aunque wtype funcione: cuesta nada y sirve de red si la
# aplicación de turno ignora el teclado virtual.
#
# ⚠️ EL `sleep` NO ES DECORATIVO. rofi es una capa de Wayland que toma el foco
# del teclado mientras está abierta. Al cerrarse, Hyprland devuelve el foco a la
# ventana anterior, pero eso ocurre de forma ASÍNCRONA: si wtype dispara en el
# mismo instante, el carácter puede salir por el limbo entre las dos ventanas y
# perderse. La pausa deja que el foco aterrice antes de teclear.
#
# EL CATÁLOGO LLEVA ALIAS SIN TILDES A PROPÓSITO. rofi filtra por subcadena y no
# normaliza acentos: quien escribe "variacion" con prisa no encontraría una
# entrada que solo dijera "variación". Por eso cada nombre acentuado va también
# en su forma pelada, y de paso está el nombre LaTeX (\Delta), que es como se
# llama al símbolo cuando se viene de escribir fórmulas.

set -Eeuo pipefail

# Formato de cada línea: SÍMBOLO, dos espacios, y los términos de búsqueda.
# Lo que se extrae es el primer campo, así que el símbolo no puede llevar
# espacios (ninguno los lleva).
catalogo() {
cat <<'CATALOGO'
Δ  Delta mayúscula · variación · variacion · incremento · \Delta
δ  delta minúscula · \delta
γ  gamma · rayos gamma · \gamma
α  alfa · alpha · \alpha
β  beta · \beta
ε  épsilon · epsilon · \varepsilon
ζ  dseta · zeta griega · \zeta
η  eta · rendimiento · \eta
θ  theta · ángulo · angulo · \theta
λ  lambda · longitud de onda · \lambda
μ  mu · micro · coeficiente de rozamiento · \mu
ν  nu · frecuencia · \nu
ξ  xi · \xi
π  pi · \pi
ρ  rho · densidad · \rho
σ  sigma · desviación típica · desviacion tipica · \sigma
τ  tau · par de torsión · par de torsion · \tau
φ  fi · phi · fase · \varphi
χ  ji · chi · \chi
ψ  psi · función de onda · funcion de onda · \psi
ω  omega · velocidad angular · \omega
Γ  Gamma mayúscula · \Gamma
Θ  Theta mayúscula · \Theta
Λ  Lambda mayúscula · \Lambda
Ξ  Xi mayúscula · \Xi
Π  Pi mayúscula · productorio · \Pi
Σ  Sigma mayúscula · sumatorio · suma · \Sigma
Φ  Fi mayúscula · flujo · \Phi
Ψ  Psi mayúscula · \Psi
Ω  Omega mayúscula · ohmio · resistencia · \Omega
±  más menos · mas menos · \pm
∓  menos más · menos mas · \mp
×  por · producto · multiplicación · multiplicacion · \times
÷  entre · división · division · \div
·  punto · producto escalar · \cdot
≈  aproximadamente · casi igual · \approx
≠  distinto · no igual · \neq
≡  idéntico · identico · equivale · \equiv
≤  menor o igual · \leq
≥  mayor o igual · \geq
≪  mucho menor · \ll
≫  mucho mayor · \gg
∝  proporcional a · \propto
∞  infinito · \infty
√  raíz cuadrada · raiz cuadrada · \sqrt
∛  raíz cúbica · raiz cubica · \sqrt[3]
∑  sumatorio · suma · \sum
∏  productorio · \prod
∫  integral · \int
∮  integral cerrada · circulación · circulacion · \oint
∂  derivada parcial · parcial · \partial
∇  nabla · gradiente · \nabla
°  grado · grados · \circ
′  prima · minuto de arco · \prime
″  segunda · segundo de arco
‰  por mil · \permil
∈  pertenece a · \in
∉  no pertenece · \notin
⊂  subconjunto · contenido en · \subset
⊆  subconjunto o igual · \subseteq
∪  unión · union · \cup
∩  intersección · interseccion · \cap
∅  conjunto vacío · conjunto vacio · \emptyset
∀  para todo · cuantificador universal · \forall
∃  existe · cuantificador existencial · \exists
¬  negación · negacion · no lógico · no logico · \neg
∧  y lógico · y logico · conjunción · conjuncion · \land
∨  o lógico · o logico · disyunción · disyuncion · \lor
ℝ  reales · números reales · numeros reales · \mathbb{R}
ℕ  naturales · números naturales · numeros naturales · \mathbb{N}
ℤ  enteros · números enteros · numeros enteros · \mathbb{Z}
ℚ  racionales · números racionales · numeros racionales · \mathbb{Q}
ℂ  complejos · números complejos · numeros complejos · \mathbb{C}
→  flecha derecha · tiende a · da lugar a · \rightarrow
←  flecha izquierda · \leftarrow
↔  doble flecha · \leftrightarrow
⇒  implica · entonces · \Rightarrow
⇔  si y solo si · equivale · \Leftrightarrow
∥  paralelo a · \parallel
⊥  perpendicular a · \perp
∠  ángulo · angulo · \angle
△  triángulo · triangulo · \triangle
…  puntos suspensivos · elipsis · \dots
⟨  bra · ángulo izquierdo · angulo izquierdo · \langle
⟩  ket · ángulo derecho · angulo derecho · \rangle
₀  subíndice 0 · subindice 0
₁  subíndice 1 · subindice 1
₂  subíndice 2 · subindice 2
₃  subíndice 3 · subindice 3
ₙ  subíndice n · subindice n
⁰  superíndice 0 · superindice 0
¹  superíndice 1 · superindice 1
²  superíndice 2 · superindice 2 · al cuadrado
³  superíndice 3 · superindice 3 · al cubo
ⁿ  superíndice n · superindice n
⁻  superíndice menos · superindice menos · exponente negativo
CATALOGO
}

case "${1:-}" in
    --lista|-l)
        catalogo
        exit 0
        ;;
    -h|--help)
        sed -n '2,9p' "$0"
        exit 0
        ;;
esac

# `|| true` porque salir con Esc devuelve un código distinto de cero y `set -e`
# mataría el script ahí mismo, que es justo lo que NO queremos: cancelar el
# menú no es un error.
elegido="$(catalogo | rofi -dmenu -i -p "Símbolo" -matching normal || true)"

[ -n "$elegido" ] || exit 0

# Primer campo = el símbolo; el resto de la línea son términos de búsqueda.
simbolo="${elegido%% *}"

# -n para no añadir el salto de línea que printf pondría por defecto: si no, se
# pegaría el símbolo Y un retorno de carro.
printf '%s' "$simbolo" | wl-copy -n 2>/dev/null || true

if command -v wtype >/dev/null 2>&1; then
    sleep 0.15   # que el foco vuelva antes de teclear; ver cabecera
    wtype -- "$simbolo"
else
    notify-send -a "Símbolos" -u low \
        -h "string:x-dunst-stack-tag:simbolos" \
        "$simbolo  copiado" "Pega con Ctrl+V · instala wtype para escribirlo directo" \
        2>/dev/null || true
fi
