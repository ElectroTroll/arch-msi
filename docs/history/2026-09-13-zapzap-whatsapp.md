# 2026-09-13 · WhatsApp en el escritorio, y la GPU que le faltaba un driver

Pregunta de partida: *¿hay app de WhatsApp para Arch Linux?* La respuesta corta
es que **no una oficial**, y de ahí salieron dos cosas: la elección entre una
docena de envoltorios de AUR, y un fallo que resultó no ser de la app sino un
hueco de la máquina que llevaba ahí desde el principio.

---

## 1. No hay cliente oficial, solo envoltorios

Meta no publica WhatsApp para Linux. Todo lo que hay en AUR carga
`web.whatsapp.com` dentro de un navegador empotrado (Electron, Qt WebEngine o
Tauri). La búsqueda devolvió más de veinte paquetes; los que tenían tracción:

| Paquete | Base | Votos | Nota |
|---|---|---|---|
| `zapzap` | PyQt6 + WebEngine | 76 | al día (7.4.4) |
| `wasistlos` | GTK (antes `whatsapp-for-linux`) | 66 | marcado desactualizado desde el 2026-08-06 |
| `whatsie-git` | Qt WebEngine | 27 | build desde git |
| `karere` | GTK4/libadwaita | 4 | nativo y moderno, poco probado |

Se eligió **`zapzap`**: encaja con el resto del escritorio Qt (Dolphin,
hyprlock), y es el que mejor mantenimiento lleva. El clásico `wasistlos` estaba
desfasado en el momento de decidir.

Coste real: arrastra `qt6-webengine`, que no estaba instalado — 94 MiB de
descarga, 282 MiB en disco. El paquete de ZapZap en sí es Python puro y se
construye en segundos.

## 2. Los clientes de terminal, y por qué no

Había curiosidad por `whatscli` y compañía. Todos —`whatscli`, `wstui`,
`purple-gowhatsapp`, el puente `mautrix-whatsapp`— usan la librería `whatsmeow`,
que **reimplementa el protocolo binario** y se registra como dispositivo
vinculado, sin navegador de por medio.

Ahí sí hay riesgo. Los Términos de Servicio prohíben explícitamente los clientes
no oficiales, y la documentación del propio puente `mautrix-whatsapp` lleva su
aviso. En la práctica, lo que dispara suspensiones no es «este cliente es raro»
sino el **comportamiento**: volumen alto de mensajes, escribir a números que no
te tienen guardado, muchas conversaciones nuevas de golpe, bloqueos y reportes.
Quien se come los baneos son las granjas de bots montadas sobre whatsmeow, no
quien lee sus chats a ritmo humano.

Pero el riesgo no es cero, el baneo recae sobre el **número de teléfono** —con
el 2FA del banco y el trabajo colgando de él— y no hay cifras públicas con las
que calibrarlo. Descartados.

Los envoltorios web no comparten ese problema: para los servidores de Meta son
WhatsApp Web, un producto suyo.

## 3. El fallo: dos lanzadores y uno que se moría

El paquete instala **`ZapZap` y `ZapZapNoGpu`**. El normal se cerraba a los dos
segundos de abrir. Tres intentos seguidos dejaron tres volcados de núcleo
(16:04:36, 16:04:46, 16:04:58), todos SIGSEGV y todos con la misma pila:

```
#2  raise                                    (libc)
#3  libgallium-26.2.2-arch1.1.so             ← Mesa aborta aquí
#8  libQt6WebEngineCore.so.6
#9  QtWebEngineCore::RenderWidgetHostViewQtDelegateItem::updatePaintNode
#12 QQuickWindowPrivate::syncSceneGraph
```

Muere **pintando** la vista web. No es red, no es WhatsApp, es el camino
gráfico.

### La trampa de diagnóstico: instancia única

El primer intento de reproducirlo desde la terminal salió con `rc=0` y **sin una
sola línea de log**. Motivo: `SingleMainWindow=true` en el `.desktop`, y había
una instancia viva. Lo que estaba abierto y funcionando era el lanzador
**NoGpu**, cosa que se confirmó leyendo `/proc/PID/environ` — llevaba
`QTWEBENGINE_CHROMIUM_FLAGS` con `--disable-gpu --disable-vulkan`.

Sin cerrar la ventana buena no hay reproducción posible.

## 4. La causa, dicha por Qt en voz alta

Con la instancia cerrada y lanzando a mano, la primera línea lo canta:

```
GBM is not supported with the current configuration. Fallback to Vulkan rendering in Chromium.
```

Qt WebEngine no puede usar GBM para compartir búferes, así que **cae a Vulkan**.
Y aquí estaba el hueco:

```
/usr/share/vulkan/icd.d/
└── nvidia_icd.json        ← el ÚNICO driver Vulkan del sistema
```

**`vulkan-intel` no estaba instalado.** La Arc integrada —que es la que pinta el
escritorio, `Mesa Intel(R) Arc(tm) Graphics (MTL)`— no tenía driver Vulkan. El
único ICD que encontraba el cargador era el de la NVIDIA, que además estaba
`active` porque la LG ULTRAGEAR cuelga de ella por HDMI.

El lanzador NoGpu funcionaba porque esquiva exactamente esa ruta.

### Lo que no sirvió

Desactivar solo Vulkan manteniendo la GPU:

```
QTWEBENGINE_CHROMIUM_FLAGS="--disable-vulkan --disable-features=Vulkan,VulkanFromANGLE" zapzap
```

Murió con la pila idéntica. **Es una bandera de Chromium**, y para cuando se
aplica, la capa de Qt WebEngine ya eligió el camino. El mensaje de GBM sale
antes que cualquier cosa que Chromium pueda decidir.

También se descartó que fuera permisos: `/dev/dri/renderD128` y `renderD129`
están a `0666`, accesibles sin pertenecer a `video` ni a `render`.

## 5. El arreglo

```
sudo pacman -S vulkan-intel     # 1:26.2.2-1, misma versión que mesa
```

**No sustituye ningún controlador gráfico**: añade el ICD Vulkan de Mesa para la
Arc, que no existía. La coincidencia exacta de versión con `mesa 1:26.2.2-1`
evita desfases entre componentes.

Antes había un ICD; ahora `vulkaninfo --summary` lista dos GPU:

| | Driver |
|---|---|
| `Intel(R) Arc(tm) Graphics (MTL)` | `DRIVER_ID_INTEL_OPEN_SOURCE_MESA`, Mesa 26.2.2 |
| `NVIDIA GeForce RTX 4060 Laptop GPU` | `DRIVER_ID_NVIDIA_PROPRIETARY`, 615.71.09 |

Y el lanzador normal arranca y se queda.

**Reversión:** `sudo pacman -Rns vulkan-intel` devuelve el sistema al estado
anterior, con ZapZapNoGpu como salida.

## 6. La lección, que no va de WhatsApp

**Esto era un hueco de la máquina.** Un portátil con gráficos Arc y sin driver
Vulkan para ellos: cualquier cosa que pidiera Vulkan sobre la iGPU —Wine/DXVK,
otras apps de Electron o Qt WebEngine— estaba en la misma situación y habría
fallado igual, probablemente con síntomas más confusos.

ZapZap no tenía ningún problema. Solo fue lo primero que pisó el hueco lo
bastante fuerte como para dejar un volcado de núcleo legible.
