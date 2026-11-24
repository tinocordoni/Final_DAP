# Mi biblioteca

Aplicación de Flutter basada en [Dap-StateManagers](https://github.com/tinocordoni/Dap-StateManagers). Usa Supabase Auth para registrar usuarios y restaurar sesiones, PostgreSQL para guardar los libros y Riverpod para actualizar la interfaz. Cada libro tiene título, autor, año de publicación, descripción, portada y UUID.

## Ejecutar la app

Se necesita Flutter con Dart 3.11.4 o posterior. En Android usá un dispositivo o emulador con Android 7 o superior. Para iOS se necesita macOS con Xcode y un dispositivo o simulador con iOS 15 o superior.

La app ya está configurada para el proyecto Supabase **Final_DAP**. Desde la raíz del repositorio, ejecutá:

```sh
flutter pub get
flutter run
```

Para probar en Chrome, usá `flutter run -d chrome`.

## Configurar otro proyecto Supabase

1. Creá el proyecto y abrí **SQL Editor**. Ejecutá una vez `supabase/migrations/20261124000000_create_books.sql`. Crea la tabla `books`, la agrega a la publicación de Realtime y configura Row Level Security (RLS) para que cada cuenta acceda a sus propios libros.
2. En **Authentication**, verificá que el proveedor **Email** esté habilitado. Si usás confirmación de email, agregá `ar.edu.ort.finaldap://auth-callback/` a **URL Configuration → Redirect URLs**. Para web, agregá también la URL que usás para servir la app, por ejemplo `http://localhost:3000/`. Si mantenés la confirmación activada y vas a registrar correos externos al equipo, configurá un servicio SMTP propio.
3. En **Connect**, copiá la URL del proyecto y su clave publicable (`sb_publishable_…`). Copiá `supabase.example.json` a `supabase.local.json` y completá `SUPABASE_URL` y `SUPABASE_PUBLISHABLE_KEY`. La clave publicable identifica la app. Las políticas RLS controlan el acceso a las filas.
4. Ejecutá `flutter run --dart-define-from-file=supabase.local.json` para iniciar con ese otro proyecto.

- [Inicio rápido con Supabase y Flutter](https://supabase.com/docs/guides/getting-started/quickstarts/flutter)
- [Enlaces de confirmación móvil](https://supabase.com/docs/guides/auth/native-mobile-deep-linking)

## Comprobar el flujo

1. Creá una cuenta con nombre, email y dos contraseñas iguales. Si el proyecto pide confirmación, usá el enlace del email antes de ingresar.
2. Agregá un libro y volvé a abrir la app para verificar que se restauren la sesión y el listado. Como portada podés usar `https://covers.openlibrary.org/b/isbn/9780307474728-L.jpg`.
3. Editá el título desde el detalle y guardá. El detalle y el listado deberían mostrar el cambio con el mismo ID.
4. Eliminá el libro desde el detalle. Cerrá la app y volvé a abrirla para comprobar que sigue ausente.
5. Cerrá sesión y probá el ingreso con una contraseña incorrecta y luego con la correcta.

```sh
flutter analyze
flutter test
```

## Dónde cambiar el código

| Archivo | Qué contiene |
| --- | --- |
| `lib/main.dart` | Configuración de Supabase y tema visual. |
| `lib/router.dart` | Pantallas disponibles según la sesión. |
| `lib/models/book.dart` | Campos del libro y conversión a filas de PostgreSQL. |
| `lib/providers/auth_provider.dart` | Sesión, registro e ingreso. El perfil guarda el nombre en `display_name`. |
| `lib/providers/book_provider.dart` | Consulta de libros, cambios de Realtime y ABM. |
| `lib/screens/` | Formularios, listado y detalle. |
| `supabase/migrations/` | Esquema de PostgreSQL y permisos por fila. |
