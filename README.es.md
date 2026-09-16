# Solución para Vectorworks 2024/2025/2026 que no inicia en macOS 27

[Read in English](README.md)

Solución comunitaria, no oficial y reversible para un fallo de inicio de Vectorworks en Macs Apple Silicon con macOS 27. En el caso confirmado de Vectorworks 2025, `Support.vwlibrary` no podía cargar porque dependía de la ruta ausente `/usr/lib/libiodbc.2.dylib`.

Creada por **Wagner R. Ponce — ANIFONIX**.

> [!IMPORTANT]
> Este proyecto no está afiliado, respaldado ni soportado por Vectorworks, Inc., Nemetschek, Apple o Homebrew. Modifica un componente firmado de Vectorworks. Revisa el código, conserva una copia de seguridad y úsalo bajo tu propia responsabilidad.

## Empieza aquí — guía fácil paso a paso

No necesitas entender la información técnica del final. Sigue estos pasos en orden.

### 1. Comprueba si esta solución es para ti

Necesitas un **Mac Apple Silicon (M1, M2, M3 o posterior), macOS 27 y Vectorworks ya instalado** en su carpeta habitual de Aplicaciones. Esta solución es para el error de inicio **“Error al cargar la biblioteca de compatibilidad.”** En inglés: **“Failure loading Support library.”** El script comprueba si aparece la dependencia específica; el mensaje de la ventana por sí solo no confirma que este parche sea adecuado.

**2025 Update 8: probado. 2024 y 2026: experimentales y no comprobados.** Es una solución no oficial que modifica un componente de Vectorworks y crea una copia de seguridad. No instala Vectorworks ni arregla cualquier tipo de cierre inesperado.

### 2. Descarga el script

Pulsa [Descargar el script](https://github.com/wkrodrig/vectorworks-2025-2026-wont-launch-macos27-fix/raw/refs/heads/main/Fix-Vectorworks-iODBC.command). Guárdalo en **Descargas**, conservando el nombre exacto `Fix-Vectorworks-iODBC.command`. Si el navegador muestra el código como texto, usa su opción de guardar para guardar el archivo con ese nombre, sin añadir `.txt`. No necesitas descargar todo el repositorio.

### 3. Abre Terminal y comprueba la descarga

Cierra Vectorworks. Pulsa **Command + Espacio**, escribe **Terminal** y pulsa **Enter**. Copia estas dos líneas en Terminal y pulsa Enter:

```bash
cd "$HOME/Downloads"
shasum -a 256 Fix-Vectorworks-iODBC.command
```

La cadena larga debe coincidir exactamente con esta (es normal que después aparezca el nombre del archivo):

```text
f4a450a3de2f8878b8f437a6eeaa3dc6694df583620a53031f6d3adcc72dc37b
```

**Si no coincide, detente. No ejecutes ese archivo.** Si aparece `No such file or directory`, comprueba que esté en Descargas y tenga el nombre exacto indicado arriba.

### 4. Ejecuta el script comprobado

Copia esta línea en la misma ventana de Terminal y pulsa Enter:

```bash
/bin/bash "$HOME/Downloads/Fix-Vectorworks-iODBC.command"
```

Este método desde Terminal no requiere abrir el archivo con doble clic ni darle permisos de ejecución. No desactives SIP ni Gatekeeper. Ejecutar un script también ejecuta código: revísalo antes de usarlo.

### 5. Responde las preguntas y espera

- Si tienes varias versiones de Vectorworks, escribe el año que quieres reparar y pulsa Enter.
- Lee cada pregunta. Escribe `y` y pulsa Enter solamente si estás de acuerdo. Homebrew es una herramienta para instalar la biblioteca que falta; si no está instalado, el script pide permiso antes de instalarlo.
- Si pide la contraseña de administrador del Mac, escríbela y pulsa Enter. **No aparecen puntos ni letras mientras escribes; es normal.**
- Mantén Terminal abierto y la conexión a Internet mientras termina la instalación y reparación. Si hace falta instalar herramientas de desarrollo, sigue el aviso de macOS y vuelve a ejecutar el script cuando termine esa instalación.

Al terminar, el script normalmente abre Vectorworks. Si se detiene con un error, no modifiques la aplicación manualmente ni pruebes comandos ajenos a esta guía. Puede significar que esta solución no aplica a tu caso. Si indica que ya está parcheado, no necesitas aplicar el cambio otra vez.

### Opcional: deshacer la reparación

Cierra Vectorworks, abre Terminal y ejecuta este comando. Sustituye `2025` por `2024` o `2026` si esa fue la versión reparada:

```bash
/bin/bash "$HOME/Downloads/Fix-Vectorworks-iODBC.command" --rollback --version 2025
```

Restaura la copia más reciente creada por el script para esa versión; puede volver el error de inicio original. No desinstala Homebrew ni su biblioteca.

---

## Información técnica — lectura opcional

El resto de esta página explica la compatibilidad, muestra los errores y describe las opciones avanzadas y el funcionamiento del parche. **No necesitas ejecutar los comandos de abajo para el uso normal.**

## Compatibilidad

| Versión | Estado | Observación |
|---|---|---|
| Vectorworks 2024 | Experimental, no comprobada | No se ha confirmado una reparación exitosa. Solo aplica si Support contiene código arm64 y la dependencia exacta de iODBC ausente. |
| Vectorworks 2025 Update 8 | Probada | Funcionó en un Mac Apple Silicon con macOS 27.0. |
| Vectorworks 2026 | Experimental | Se ha reportado un error similar, pero esta reparación todavía no ha sido probada de forma independiente en 2026. |

El script se niega a modificar cualquier versión si no encuentra exactamente:

```text
/usr/lib/libiodbc.2.dylib
```

## Síntomas

Vectorworks se cierra durante el inicio y puede mostrar un mensaje localizado indicando que no pudo cargar su biblioteca de compatibilidad o Support.

### Ejemplos del diálogo de error

La captura en inglés muestra el texto de Vectorworks **“Failure loading Support library.”** Es un ejemplo visual independiente, no la captura de la prueba confirmada en macOS 27.

![Diálogo de Vectorworks que dice Failure loading Support library](assets/screenshots/vectorworks-support-library-error-en.webp)

La siguiente captura en español corresponde al diálogo observado en el caso confirmado: **“Error al cargar la biblioteca de compatibilidad.”**

![Diálogo de Vectorworks que dice Error al cargar la biblioteca de compatibilidad](assets/screenshots/vectorworks-compatibility-library-error-es.webp)

Al ejecutarlo mediante LLDB apareció explícitamente:

```text
Error loading .../Plug-ins/Support.vwlibrary/Contents/MacOS/Support
Library not loaded: /usr/lib/libiodbc.2.dylib
Reason: tried: '/usr/lib/libiodbc.2.dylib' (no such file), ...
```

No utilices esta solución para una caída distinta o para otra biblioteca ausente.

## Qué hace

- Exige macOS 27 y un Mac Apple Silicon ejecutándose nativamente como `arm64`.
- Detecta Vectorworks 2024, 2025 o 2026 dentro de `/Applications`.
- Permite seleccionar la versión si hay varias instaladas.
- Advierte que la compatibilidad con 2024 y 2026 es experimental y pide confirmación adicional.
- Comprueba Homebrew y pide permiso antes de instalarlo.
- Instala `libiodbc` mediante Homebrew cuando hace falta.
- Verifica arquitectura arm64 y compatibilidad ABI 4.0.0.
- Guarda el ejecutable `Support` y la firma original fuera del bundle.
- Cambia la dependencia a `/opt/homebrew/opt/libiodbc/lib/libiodbc.2.dylib`.
- Firma ad hoc y verifica el ejecutable y `Support.vwlibrary`.
- Detecta instalaciones ya parcheadas.
- Incluye verificación, listado de copias y restauración.

No desactiva SIP ni crea o modifica archivos dentro de `/usr/lib`.

## Requisitos

- Mac Apple Silicon
- macOS 27
- Vectorworks 2024, 2025 o 2026 instalado en su ubicación predeterminada
- Acceso de administrador
- Internet si es necesario instalar Homebrew o `libiodbc`

## Uso

Descarga `Fix-Vectorworks-iODBC.command`, abre Terminal en la carpeta y ejecuta:

```bash
chmod +x Fix-Vectorworks-iODBC.command
./Fix-Vectorworks-iODBC.command
```

Después podrás abrirlo con doble clic. Si macOS bloquea la primera apertura, haz Control-clic, selecciona **Abrir** y confirma.

### Si macOS dice que el archivo no se puede abrir

Los archivos descargados de Internet pueden recibir el atributo `com.apple.quarantine` de Apple. Primero verifica el script descargado mediante el checksum publicado en este repositorio y después elimina ese atributo únicamente de este archivo:

```bash
cd "$HOME/Downloads"
shasum -a 256 Fix-Vectorworks-iODBC.command
xattr -d com.apple.quarantine Fix-Vectorworks-iODBC.command
chmod +x Fix-Vectorworks-iODBC.command
./Fix-Vectorworks-iODBC.command
```

Para el script actual, el SHA-256 esperado es:

```text
f4a450a3de2f8878b8f437a6eeaa3dc6694df583620a53031f6d3adcc72dc37b
```

Si `xattr` muestra `No such xattr`, el archivo no está en cuarentena; continúa con `chmod` y ejecútalo. No uses `xattr -cr` sobre `/Applications`, la carpeta Descargas ni ningún directorio amplio. Elimina la cuarentena solamente del script que hayas verificado.

Seleccionar una versión explícitamente:

```bash
./Fix-Vectorworks-iODBC.command --version 2025
./Fix-Vectorworks-iODBC.command --version 2026
```

Vectorworks 2024 (experimental y no comprobado):

```bash
./Fix-Vectorworks-iODBC.command --version 2024
./Fix-Vectorworks-iODBC.command --verify --version 2024
./Fix-Vectorworks-iODBC.command --rollback --version 2024
```

Diagnóstico previo de Vectorworks 2024:

```bash
otool -L "/Applications/Vectorworks 2024/Plug-ins/Support.vwlibrary/Contents/MacOS/Support" | grep -i iodbc
lipo -archs "/Applications/Vectorworks 2024/Plug-ins/Support.vwlibrary/Contents/MacOS/Support"
```

Verificar sin cambiar nada:

```bash
./Fix-Vectorworks-iODBC.command --verify --version 2025
```

Restaurar la copia más reciente:

```bash
./Fix-Vectorworks-iODBC.command --rollback --version 2025
```

Mostrar todas las opciones:

```bash
./Fix-Vectorworks-iODBC.command --help
```

## Copias de seguridad

Se guardan fuera de Vectorworks:

```text
~/Library/Application Support/Vectorworks 2024 iODBC Fix/backups
~/Library/Application Support/Vectorworks 2025 iODBC Fix/backups
~/Library/Application Support/Vectorworks 2026 iODBC Fix/backups
```

Cada copia contiene el ejecutable original, su checksum SHA-256, metadatos y la firma exterior original cuando está disponible.

## Limitaciones

- La modificación invalida la firma del proveedor y requiere una firma ad hoc.
- Una actualización, reparación o reinstalación de Vectorworks puede sobrescribir el parche.
- La compatibilidad con Vectorworks 2024 y 2026 es experimental y no comprobada hasta verificar reparación, inicio, firma y rollback en instalaciones reales. Añadir una opción de versión no confirma compatibilidad general con macOS 27 ni soluciona otras bibliotecas ausentes.
- La solución definitiva debe ser una actualización oficial de Vectorworks para macOS 27.

## Privacidad

No compartas tu número de serie de Vectorworks, Crash Reporter Key, Incident Identifier, contraseñas, tokens ni otra información personal.

## Autor

**Wagner R. Ponce**  
**ANIFONIX**

## Agradecimientos

Gracias a [@lahmadinia](https://github.com/lahmadinia) por identificar el problema de detección de la dependencia en binarios universales causado por la interacción entre `grep -q` y `set -o pipefail`.

## Licencia

Disponible bajo la [Licencia MIT](LICENSE).
