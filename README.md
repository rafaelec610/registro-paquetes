# Registro de Paquetes – Flutter + Firebase

Sistema integral para el registro, entrega, devolución y control administrativo de paquetes, desarrollado en Flutter y respaldado por Firebase, con soporte para aplicación móvil y panel web administrativo.

## 🚀 Funcionalidades principales

### 📱 Aplicación móvil
- 🔐 Autenticación de usuarios (Firebase Auth)
- 📥 Entrada de paquetes mediante escaneo de código de barras
- 📤 Entrega de paquetes
  - Registro de fecha y hora
  - Identificación del rol/usuario que realizó la entrega
  - Evidencia fotográfica de entrega
- 🔁 Devolución de paquetes
  - Registro de fecha, hora y rol que realizó la devolución
- 📊 Cuadre diario de operaciones
- 🔔 Notificaciones push (Firebase Cloud Messaging)
### 🖥️ Panel web administrativo
- 📋 Visualización de todos los paquetes (histórico completo)
- 🔍 Filtros por fecha, estado y usuario
- 📈 Control administrativo centralizado
- 📊 Tabla de paquetes en tiempo real (Firestore)
### 🧱 Arquitectura
- Frontend: Flutter (Mobile + Web)
- Backend: Firebase
  - Firestore (base de datos)
  - Firebase Auth
  - Firebase Cloud Messaging (FCM)
  - Firebase Functions (Node.js)
- Persistencia local: Hive
- Escaneo de códigos: mobile_scanner

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
