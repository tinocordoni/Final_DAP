# Mi biblioteca

Aplicación de Flutter basada en [Dap-StateManagers](https://github.com/tinocordoni/Dap-StateManagers). Usa Firebase Authentication para las cuentas, Cloud Firestore para guardar los libros y Riverpod para manejar la sesión, el listado y las operaciones de alta, baja y modificación.

## Ejecutar

La app está configurada para el proyecto Firebase **Final DAP** (`final-dap`). Se necesita Flutter con Dart 3.11.4 o posterior. En Android se admite Android 7 o posterior. Para compilar en iOS se necesita macOS con Xcode e iOS 15 o posterior.

```sh
flutter pub get
flutter run
```

Para probar en Chrome, usá `flutter run -d chrome`. El registro crea una cuenta en Firebase. Si usabas la versión de Supabase, registrate de nuevo. Los libros de esa versión siguen en su base original.

## Comprobar la consigna

1. En **Crear cuenta**, ingresá nombre, email, contraseña y confirmación. Probá dejar campos vacíos, ingresar un email inválido o usar dos contraseñas distintas. Al registrarte, el listado muestra tu nombre, guardado en el perfil de Firebase Auth.
2. Agregá un libro con título, autor, año, descripción y una URL HTTPS directa a la portada. Revisá que aparezca una sola vez con su título, autor y portada. Abrí el detalle para ver todos los datos y el ID de Firestore.
3. Editá el libro desde el detalle. Verificá que el detalle y el listado reflejen el cambio y que el ID sea el mismo.
4. Cerrá y reabrí la app después del alta y de la edición. Comprobá que se restauren la sesión y los datos guardados.
5. Eliminá el libro desde el detalle. Reabrí la app y comprobá que siga ausente.
6. Cerrá sesión. Probá ingresar con una contraseña incorrecta y luego con la correcta. Cada cuenta tiene su propia biblioteca.

```sh
flutter analyze
flutter test
```

## Configurar otro proyecto de Firebase

1. En la consola de Firebase, habilitá **Correo electrónico/contraseña** en Authentication y creá la base predeterminada de Cloud Firestore en modo de producción.
2. Configurá FlutterFire para generar las opciones de las plataformas elegidas. El identificador de Android es `ar.edu.ort.final_dap` y el de iOS es `ar.edu.ort.finalDap`.

```sh
flutterfire configure --project=TU_PROYECTO --platforms=android,ios,web
firebase deploy --only firestore:rules --project TU_PROYECTO
```

Para desarrollo local, iniciá los emuladores con `firebase emulators:start --only auth,firestore --project demo-final-dap` y ejecutá la app con `flutter run --dart-define=USE_FIREBASE_EMULATORS=true`. En Chrome, agregá `-d chrome`.

- [Configurar Firebase en Flutter](https://firebase.google.com/docs/flutter/setup)
- [Emuladores de Firebase](https://firebase.google.com/docs/emulator-suite)

## Dónde cambiar el código

| Archivo | Qué contiene |
| --- | --- |
| `lib/main.dart` y `lib/firebase_options.dart` | Inicio de Firebase, opciones por plataforma y tema visual. |
| `lib/router.dart` | Pantallas disponibles según la sesión. |
| `lib/providers/auth_provider.dart` | Estado de sesión, registro, ingreso y cierre de sesión. El nombre se guarda en `displayName` de Firebase Auth. |
| `lib/models/book.dart` | Campos del libro y conversión a documentos de Firestore. |
| `lib/providers/book_provider.dart` | Listado en tiempo real y operaciones de alta, edición y baja. |
| `lib/screens/` | Formularios, listado y detalle. |
| `firestore.rules` | Cada usuario autenticado solo puede acceder a sus propios documentos en `users/{uid}/books/{bookId}`. |
