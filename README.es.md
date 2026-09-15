# Solución para Vectorworks 2025/2026 que no inicia en macOS 27

[Read in English](README.md)

Solución comunitaria, no oficial y reversible para el error **“Failure loading Support Library”**, que impide iniciar Vectorworks 2025 o 2026 en Macs Apple Silicon con macOS 27. El problema aparece cuando `Support.vwlibrary` depende de la ruta ausente `/usr/lib/libiodbc.2.dylib`.

Creada por **Wagner R. Ponce — ANIFONIX**.

> [!IMPORTANT]
> Este proyecto no está afiliado, respaldado ni soportado por Vectorworks, Inc., Nemetschek, Apple o Homebrew. Modifica un componente firmado de Vectorworks. Revisa el código, conserva una copia de seguridad y úsalo bajo tu propia responsabilidad.

## Compatibilidad

| Versión | Estado | Observación |
|---|---|---|
| Vectorworks 2025 Update 8 | Probada | Funcionó en un Mac Apple Silicon con macOS 27.0. |
| Vectorworks 2026 | Experimental | Se ha reportado un error similar, pero esta reparación todavía no ha sido probada de forma independiente en 2026. |

El script se niega a modificar cualquiera de las dos versiones si no encuentra exactamente:

```text
/usr/lib/libiodbc.2.dylib
```

## Síntomas

Vectorworks se cierra durante el inicio y puede mostrar:

```text
Failure loading Support Library
```

Al ejecutarlo desde Terminal puede aparecer:

```text
Library not loaded: /usr/lib/libiodbc.2.dylib
Referenced from: .../Plug-ins/Support.vwlibrary/Contents/MacOS/Support
```

No utilices esta solución para una caída distinta o para otra biblioteca ausente.

## Qué hace

- Exige macOS 27 y un Mac Apple Silicon ejecutándose nativamente como `arm64`.
- Detecta Vectorworks 2025 o 2026 dentro de `/Applications`.
- Permite seleccionar la versión si ambas están instaladas.
- Advierte que la compatibilidad con 2026 es experimental y pide confirmación adicional.
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
- Vectorworks 2025 o 2026 instalado en su ubicación predeterminada
- Acceso de administrador
- Internet si es necesario instalar Homebrew o `libiodbc`

## Uso

Descarga `Fix-Vectorworks-iODBC.command`, abre Terminal en la carpeta y ejecuta:

```bash
chmod +x Fix-Vectorworks-iODBC.command
./Fix-Vectorworks-iODBC.command
```

Después podrás abrirlo con doble clic. Si macOS bloquea la primera apertura, haz Control-clic, selecciona **Abrir** y confirma.

Seleccionar una versión explícitamente:

```bash
./Fix-Vectorworks-iODBC.command --version 2025
./Fix-Vectorworks-iODBC.command --version 2026
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
~/Library/Application Support/Vectorworks 2025 iODBC Fix/backups
~/Library/Application Support/Vectorworks 2026 iODBC Fix/backups
```

Cada copia contiene el ejecutable original, su checksum SHA-256, metadatos y la firma exterior original cuando está disponible.

## Limitaciones

- La modificación invalida la firma del proveedor y requiere una firma ad hoc.
- Una actualización, reparación o reinstalación de Vectorworks puede sobrescribir el parche.
- La compatibilidad con Vectorworks 2026 seguirá siendo experimental hasta comprobar reparación, inicio, firma y rollback en una instalación real.
- La solución definitiva debe ser una actualización oficial de Vectorworks para macOS 27.

## Cómo reportar resultados

Incluye modelo y procesador del Mac, versión/build de macOS, edición y actualización de Vectorworks, salida de iODBC obtenida con `otool -L`, y resultado de reparación, inicio y rollback.

Nunca publiques tu número de serie de Vectorworks, Crash Reporter Key, Incident Identifier, contraseñas, tokens o información personal.

## Autor

**Wagner R. Ponce**  
**ANIFONIX**

## Licencia

Publicado bajo la [Licencia MIT](LICENSE).
