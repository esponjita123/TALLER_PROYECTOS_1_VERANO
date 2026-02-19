# Configuración de Notificaciones Push

Este documento explica cómo configurar las notificaciones push para la aplicación JobLink.

## 📱 Estado Actual

La aplicación ahora tiene:
- ✅ Notificaciones locales (se muestran dentro de la app)
- ✅ Firebase Cloud Messaging (FCM) configurado
- ✅ Manejo de mensajes en foreground y background
- ✅ Badge de mensajes no leídos

## ⚠️ Limitación Actual

Las **notificaciones push** (que se muestran cuando la app está cerrada) requieren **Firebase Cloud Functions** para enviarlas desde el servidor.

## 🔧 Configuración Completa (Cloud Functions)

Para enviar notificaciones push reales cuando la app está cerrada, necesitas configurar Cloud Functions:

### Paso 1: Instalar Firebase CLI

```bash
npm install -g firebase-tools
```

### Paso 2: Inicializar Cloud Functions

```bash
cd tu-proyecto
firebase login
firebase init functions
```

Selecciona:
- JavaScript o TypeScript
- ESLint: No
- Instalar dependencias: Sí

### Paso 3: Crear la función de notificaciones

Crea el archivo `functions/index.js`:

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// Función que se ejecuta cuando se crea un nuevo mensaje
exports.sendChatNotification = functions.firestore
  .document('wanka_conversations/{conversationId}/messages/{messageId}')
  .onCreate(async (snap, context) => {
    const messageData = snap.data();
    const conversationId = context.params.conversationId;
    
    // Obtener datos de la conversación
    const conversationDoc = await admin.firestore()
      .collection('wanka_conversations')
      .doc(conversationId)
      .get();
    
    if (!conversationDoc.exists) {
      console.log('Conversación no encontrada');
      return null;
    }
    
    const conversation = conversationDoc.data();
    const senderEmail = messageData.senderEmail;
    const receiverEmail = messageData.receiverEmail;
    const senderName = messageData.senderName;
    const messageContent = messageData.content;
    
    // Buscar el token FCM del receptor
    const userDoc = await admin.firestore()
      .collection('wanka_users')
      .doc(receiverEmail)
      .get();
    
    if (!userDoc.exists) {
      console.log('Usuario receptor no encontrado');
      return null;
    }
    
    const fcmToken = userDoc.data().fcmToken;
    
    if (!fcmToken) {
      console.log('Usuario no tiene token FCM');
      return null;
    }
    
    // Crear la notificación
    const payload = {
      notification: {
        title: `💬 ${senderName}`,
        body: messageContent.length > 100 
          ? messageContent.substring(0, 100) + '...' 
          : messageContent,
        sound: 'default',
      },
      data: {
        type: 'chat',
        conversationId: conversationId,
        senderEmail: senderEmail,
        senderName: senderName,
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
    };
    
    // Enviar notificación
    try {
      await admin.messaging().sendToDevice(fcmToken, payload);
      console.log('Notificación enviada a:', receiverEmail);
    } catch (error) {
      console.error('Error al enviar notificación:', error);
    }
    
    return null;
  });
```

### Paso 4: Guardar el token FCM del usuario

Cuando el usuario inicia sesión, guarda su token FCM en Firestore:

```dart
// En tu servicio de autenticación
Future<void> saveUserFCMToken(String email) async {
  final token = await NotificationService.getToken();
  if (token != null) {
    await FirebaseFirestore.instance
        .collection('wanka_users')
        .doc(email)
        .update({'fcmToken': token});
  }
}
```

### Paso 5: Desplegar las funciones

```bash
cd functions
npm install
firebase deploy --only functions
```

## 🧪 Prueba Rápida (Sin Cloud Functions)

Si solo quieres probar las notificaciones locales:

1. Abre la app
2. Ve a Mensajes
3. Abre una conversación
4. Envía un mensaje
5. Deberías ver una notificación local confirmando el envío

## 📋 Resumen de Archivos Modificados

1. **pubspec.yaml** - Agregadas dependencias:
   - `firebase_messaging: ^14.7.0`
   - `flutter_local_notifications: ^16.3.0`

2. **lib/servicios/servicio_notificaciones.dart** - Nuevo servicio

3. **lib/main.dart** - Inicialización de notificaciones

4. **lib/servicios/servicio_chat.dart** - Integración con notificaciones

5. **lib/pantallas/pantalla_chat_detalle.dart** - Listener de mensajes

## 🔮 Próximos Pasos

Para notificaciones push completas:
1. Configurar Cloud Functions
2. Guardar tokens FCM de usuarios
3. Probar con la app cerrada

## ❓ Solución de Problemas

### No llegan notificaciones locales
- Verifica que hayas aceptado los permisos de notificaciones
- Revisa los logs de la consola

### No llegan notificaciones push (app cerrada)
- Necesitas Cloud Functions configuradas
- Verifica que el usuario tenga fcmToken guardado
- Revisa los logs de Firebase Functions

### Error de índices en Firestore
El chat requiere estos índices:
1. `wanka_conversations` → `employerEmail` (asc) + `lastMessageTime` (desc)
2. `wanka_conversations` → `applicantEmail` (asc) + `lastMessageTime` (desc)

Crealos en: Firebase Console → Firestore Database → Indexes
