# SADERH Móvil

App gubernamental de gestión de campo para la Secretaría de Agricultura y Desarrollo Rural de Hidalgo.

## Requisitos

- Flutter ^3.41.0
- Dart ^3.11.0
- Android SDK 35 (min SDK 26)

## Configuración

### URL del servidor

La app usa por defecto:
https://campo-api-app-campo-saas.up.railway.app

Para cambiarla, ve a **Perfil > Cambiar URL del servidor**.

### Variables de entorno

No se requieren variables de entorno. La URL se configura desde la pantalla de conexión al primer inicio.

## Compilar APK release

```bash
flutter build apk --release
```

El APK se genera en `build/app/outputs/flutter-apk/app-release.apk`.

## Estructura del proyecto

```
lib/
├── main.dart                    # Entry point
├── app.dart                     # Widget raíz MaterialApp.router
├── router.dart                  # GoRouter con guards de auth
├── core/
│   ├── theme/                   # Colores y tema
│   ├── api/                     # ApiService, DioClient, endpoints
│   ├── auth/                    # AuthProvider, SecureStorage
│   ├── offline/                 # HiveService (cola offline cifrada), SyncService
│   └── storage/                 # LocalBackup (carpeta SADERH/Bitacoras)
├── features/
│   ├── splash/                  # SplashScreen con animaciones
│   ├── onboarding/              # Onboarding de 4 slides
│   ├── permissions/             # Solicitud de permisos
│   ├── auth/                    # ConnectionScreen y LoginScreen
│   ├── dashboard/               # Dashboard con lista de actividades
│   ├── bitacora/                # Flujo de creación de bitácora (4 pasos)
│   └── profile/                 # Perfil del técnico
└── shared/
    ├── widgets/                 # Componentes reutilizables
    └── models/                  # Modelos de datos
```

## Seguridad

- JWT almacenado en flutter_secure_storage
- Cola offline cifrada con HiveAesCipher (AES-256)
- FLAG_SECURE activado (bloquea capturas de pantalla)
- Sin tráfico HTTP (usesCleartextTraffic=false)
- Auto-logout por inactividad (15 min)

## Funcionalidades offline

1. Las bitácoras se guardan localmente si no hay conexión
2. Las fotos se almacenan en SADERH/Bitacoras/ como respaldo
3. Sincronización automática cuando hay conexión
4. Badge "Sin conexión" visible en el dashboard

## Permisos requeridos

- Cámara (fotos de evidencia)
- Ubicación (geolocalización de visitas)
- Almacenamiento (respaldo local de fotos)
- Estado de red (detección offline/online)
- Notificaciones (opcional)
- Biometría (opcional - acceso rápido)
