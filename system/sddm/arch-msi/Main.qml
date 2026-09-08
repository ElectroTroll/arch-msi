// Main.qml — greeter de SDDM a juego con hyprlock (arch-msi)
//
// ESTRUCTURA aquí; COLORES, FUENTES Y MÉTRICAS en theme.conf, que es un
// ARTEFACTO que genera matugen. Es el mismo reparto que hyprlock.conf: este
// archivo se versiona y no cambia al cambiar el fondo de pantalla.
//
// SDDM expone las claves de theme.conf al QML como `config.<clave>`, así que no
// hace falta generar el QML entero (a diferencia de Waybar, donde GTK CSS no
// tiene variables).
//
// ⚠️ TODAS LAS MEDIDAS SON PROPORCIONALES a la altura de la pantalla, no
// píxeles fijos. hyprlock dibuja en píxeles LÓGICOS (escala 1.6 en este panel,
// 1600x1000) mientras que el greeter va en FÍSICOS (2560x1600): copiar el 160
// del reloj daría un texto mucho menor de lo esperado. Los valores de
// theme.conf se leen como fracción de esos 1000 px lógicos.
//
// ⚠️⚠️ ESTE TEMA HABLA Qt5 Y SOLO USA `QtQuick`. Dos motivos, los dos
// comprobados en el journal tras el primer arranque con el tema puesto:
//
//   1. El paquete `sddm` trae DOS binarios —`sddm-greeter` (Qt5) y
//      `sddm-greeter-qt6`— y el daemon lanza el de Qt5:
//      "Starting X11 session: /usr/bin/sddm-greeter". No hay opción para
//      cambiarlo: /usr/lib/sddm/sddm.conf.d/default.conf no expone ninguna.
//      Qt5 exige la VERSIÓN en cada import y, sin ella, aborta con "Library
//      import requires a version" y SDDM cae al tema empotrado.
//
//   2. `QtQuick.Controls` NO ESTÁ INSTALADO para Qt5 en este equipo: solo hay
//      qt5-base, qt5-declarative, qt5-translations y qt5-wayland, y
//      /usr/lib/qt/qml/QtQuick/ no contiene Controls. Con él el greeter
//      enseñaba en rojo 'module "QtQuick.Controls" is not installed'. Se podría
//      instalar qt5-quickcontrols2 (8,9 MB), pero no hace falta: el campo de
//      contraseña se hace con `TextInput`, que es QtQuick puro.
//
// O sea que aquí NO se pueden usar `TextField`, `Button` ni nada de Controls, ni
// `QtQuick.Effects` (que es exclusivo de Qt6). Si algún día se toca esto,
// probarlo con `sddm-greeter --test-mode`, NUNCA con `sddm-greeter-qt6`: el de
// Qt6 acepta cosas que el greeter real rechaza, y fue justo lo que enmascaró
// estos dos fallos hasta el primer arranque de verdad.

import QtQuick 2.15

Rectangle {
    id: root
    color: config.colorBg

    // Base de proporción: los tamaños de hyprlock están en píxeles lógicos
    // sobre un panel de 1000 de alto, así que se convierten a fracción.
    readonly property real u: root.height / 1000

    // --- Fondo ---------------------------------------------------------------
    // El fondo de pantalla del escritorio, YA desenfocado y oscurecido: la
    // imagen se procesa al instalar el tema (`greeter-apply.sh`, con
    // ImageMagick) y aquí solo se dibuja.
    //
    // Aparte de que QtQuick.Effects no existe en Qt5, desenfocar en el QML daba
    // otro problema: con MultiEffect la imagen solo cubría 1600x1000 de una
    // ventana de 2560x1600, porque resuelve la textura en píxeles lógicos y la
    // pinta sin escalar por el devicePixelRatio.
    //
    // La imagen la copia el instalador DENTRO del tema porque el usuario `sddm`
    // no puede leer /home/elok, que es drwx------.
    Image {
        id: fondo
        anchors.fill: parent
        source: config.background
        fillMode: Image.PreserveAspectCrop
        asynchronous: false
    }

    // --- Reloj ---------------------------------------------------------------
    // Blanco puro y no el colorFg del tema, igual que en hyprlock: se dibuja
    // sobre una FOTO, no sobre una superficie del tema.
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        y: config.clockOffset * root.u
        color: config.colorClock
        font.family: config.fontClock
        // El peso va aparte: Qt no resuelve "JetBrainsMono NF ExtraBold" como
        // familia (fontconfig sí, y por eso hyprlock lo aplica bien). Ver
        // [greeter].clock_weight en tokens.toml.
        font.weight: parseInt(config.fontClockWeight)
        font.pixelSize: config.clockSize * root.u
        text: Qt.formatTime(horaActual.ahora, "HH:mm")
    }

    QtObject {
        id: horaActual
        property var ahora: new Date()
    }

    // Un timer de 1 s solo para la hora. hyprlock resuelve $TIME por su cuenta;
    // aquí hay que llevarla a mano, pero es un tick de reloj, no un proceso.
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: horaActual.ahora = new Date()
    }

    // --- Usuario y contraseña ------------------------------------------------
    // El usuario es el último que entró. No hay selector: este equipo tiene una
    // sola cuenta, y `userModel.lastUser` la da hecha.
    readonly property string usuario: userModel.lastUser

    Column {
        anchors.centerIn: parent
        spacing: config.nameGap * root.u
        width: root.width * (parseFloat(config.inputWidth) / 100)

        // El nombre comparte tipografía con el reloj —familia y peso—, no con
        // el campo de contraseña: los dos se dibujan sobre la foto y forman el
        // mismo bloque, mientras que el campo es un control.
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            color: config.colorClock
            font.family: config.fontClock
            font.weight: parseInt(config.fontClockWeight)
            font.pixelSize: 26 * root.u
            text: root.usuario
        }

        // El campo, a mano: marco de Rectangle + TextInput dentro. Es lo que
        // haría un TextField de Controls, que aquí no existe. Interior
        // transparente y solo contorno, como el input-field de hyprlock
        // (inner_color = rgba(0,0,0,0.0)).
        Rectangle {
            id: marco
            width: parent.width
            height: parseFloat(config.inputHeight) / 100 * root.height
            color: "transparent"
            radius: config.radius * root.u
            border.width: config.border * root.u
            // Los tres estados del campo, con los mismos colores que hyprlock:
            // acento en reposo, verde comprobando, rojo al fallar.
            border.color: estado.color

            TextInput {
                id: campoClave
                anchors.fill: parent
                anchors.leftMargin: 12 * root.u
                anchors.rightMargin: 12 * root.u
                echoMode: TextInput.Password
                focus: true
                horizontalAlignment: TextInput.AlignHCenter
                verticalAlignment: TextInput.AlignVCenter
                color: config.colorFg
                font.family: config.fontFamily
                font.pixelSize: 20 * root.u
                // Los círculos de JetBrainsMono salen pegados a este tamaño y
                // se leen como una mancha en vez de como caracteres contables.
                font.letterSpacing: config.passwordSpacing * root.u
                selectByMouse: true
                clip: true

                onAccepted: entrar()

                // El marcador de posición también a mano: `placeholderText` es
                // de Controls. Se oculta en cuanto hay texto.
                Text {
                    anchors.centerIn: parent
                    visible: campoClave.text.length === 0
                    color: config.colorMuted
                    font.family: config.fontFamily
                    font.pixelSize: 20 * root.u
                    text: estado.mensaje
                }
            }
        }
    }

    QtObject {
        id: estado
        property string mensaje: config.txtPlaceholder
        property color color: config.colorAccent
    }

    function entrar() {
        estado.mensaje = config.txtVerifying;
        estado.color = config.colorOk;
        sddm.login(root.usuario, campoClave.text, sessionModel.lastIndex);
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            estado.mensaje = config.txtFail;
            estado.color = config.colorCrit;
            campoClave.text = "";
            campoClave.forceActiveFocus();
        }
    }

    // --- Apagado -------------------------------------------------------------
    // Discretos, en la esquina. Se pulsan SIN contraseña, igual que en cualquier
    // greeter: es lo esperado aquí, al revés que en hyprlock (donde se
    // retiraron justamente porque el equipo ya está desbloqueado por alguien).
    Row {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 24 * root.u
        spacing: 18 * root.u

        // ⚠️ LOS ICONOS VAN COMO ESCAPES \uXXXX, no como el glifo literal.
        // Escritos a pelo se perdieron —quedaron cadenas VACÍAS— en una de las
        // reescrituras del archivo, y el resultado fue que los tres botones
        // desaparecían de la pantalla sin un solo error en el log: no es que
        // fallaran, es que no tenían nada que dibujar. Con el escape sobreviven
        // a cualquier copia. Son nf-fa-power_off, nf-fa-refresh y nf-fa-moon_o,
        // los tres comprobados en JetBrainsMono Nerd Font.
        //
        // El modelo, además, no lee `sddm.can*`: esas consultas se hacen en el
        // delegate a través de `puedeHacer()`, para que el modelo no dependa de
        // que `sddm` esté resuelto al construirse el componente.
        Repeater {
            model: [
                { icono: "\uF011", accion: "poweroff" },
                { icono: "\uF021", accion: "reboot"   },
                { icono: "\uF186", accion: "suspend"  }
            ]

            // MouseArea y no TapHandler/HoverHandler: los dos existen en Qt5.15,
            // pero MouseArea es el camino de toda la vida y no depende de la
            // versión mínima del import.
            delegate: Text {
                // `puede` es false en --test-mode (no hay logind detrás), así
                // que al probar el tema los botones se ven igual: lo que se
                // atenúa es la opacidad, no la visibilidad. En el greeter real
                // sí llegan a true.
                opacity: root.puedeHacer(modelData.accion) ? 1.0 : 0.45
                text: modelData.icono
                color: raton.containsMouse ? config.colorAccent : config.colorMuted
                font.family: config.fontFamily
                font.pixelSize: 26 * root.u

                MouseArea {
                    id: raton
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        if (modelData.accion === "poweroff") sddm.powerOff();
                        else if (modelData.accion === "reboot") sddm.reboot();
                        else sddm.suspend();
                    }
                }
            }
        }
    }

    // `typeof` y no una comprobación normal: si `sddm` no existe todavía,
    // leerlo directamente lanza ReferenceError y rompe el binding.
    function puedeHacer(accion) {
        if (typeof sddm === "undefined") return false;
        if (accion === "poweroff") return sddm.canPowerOff;
        if (accion === "reboot")   return sddm.canReboot;
        return sddm.canSuspend;
    }

    Component.onCompleted: campoClave.forceActiveFocus()
}
