' ============================================================================
' StreamDeck DIY - lanzador silencioso para Windows
' ============================================================================
' Arranca streamdeck_mixer.py SIN que aparezca ninguna ventana de consola.
'
' Se lanza solo al iniciar sesion a traves del acceso directo que hay en:
'   Win+R  ->  shell:startup  ->  "StreamDeck Mixer"
'
' Para probarlo a mano, haz doble clic en este archivo: no veras nada, pero el
' proceso pythonw.exe quedara corriendo de fondo (Administrador de tareas).
' ============================================================================

Dim shell, fso, carpeta, script, pythonw

Set shell = CreateObject("WScript.Shell")
Set fso   = CreateObject("Scripting.FileSystemObject")

' Carpeta donde esta este .vbs, para no depender del directorio de trabajo.
carpeta = fso.GetParentFolderName(WScript.ScriptFullName)
script  = carpeta & "\streamdeck_mixer.py"

' Ruta real del Python instalado (version de la Microsoft Store).
' pythonw.exe es Python sin ventana de consola.
' Si algun dia reinstalas Python en otro sitio, cambia esta linea; si la ruta
' no existe se recurre al PATH, que suele bastar.
pythonw = "C:\Users\adria\AppData\Local\Microsoft\WindowsApps\PythonSoftwareFoundation.Python.3.12_qbz5n2kfra8p0\pythonw.exe"
If Not fso.FileExists(pythonw) Then pythonw = "pythonw.exe"

If Not fso.FileExists(script) Then
    MsgBox "No encuentro streamdeck_mixer.py en:" & vbCrLf & script, 16, "StreamDeck DIY"
    WScript.Quit 1
End If

' 0 = ventana oculta.  False = no esperar a que termine.
shell.Run """" & pythonw & """ """ & script & """", 0, False
