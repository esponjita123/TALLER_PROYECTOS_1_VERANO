import 'package:cloud_firestore/cloud_firestore.dart';
import '../modelos/modelo_chat.dart';
import 'servicio_notificaciones.dart';

/// Servicio para manejar el chat entre empleadores y postulantes
class ChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Flag para evitar notificaciones duplicadas
  static final Set<String> _notifiedMessageIds = {};

  /// Crea o obtiene una conversación existente
  static Future<ChatConversation> createOrGetConversation({
    required String jobId,
    required String jobTitle,
    required String employerEmail,
    required String employerName,
    required String applicantEmail,
    required String applicantName,
  }) async {
    try {
      // Buscar si ya existe una conversación
      final query = await _firestore
          .collection('wanka_conversations')
          .where('jobId', isEqualTo: jobId)
          .where('applicantEmail', isEqualTo: applicantEmail)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final data = query.docs.first.data();
        data['id'] = query.docs.first.id;
        return ChatConversation.fromJson(data);
      }

      // Crear nueva conversación
      final conversation = ChatConversation(
        jobId: jobId,
        jobTitle: jobTitle,
        employerEmail: employerEmail,
        employerName: employerName,
        applicantEmail: applicantEmail,
        applicantName: applicantName,
        unreadCount: 0,
      );

      final docRef = await _firestore
          .collection('wanka_conversations')
          .add(conversation.toJson());

      conversation.id = docRef.id;
      print('✅ Conversación creada: ${docRef.id}');
      return conversation;
    } catch (e) {
      print('❌ Error al crear conversación: $e');
      rethrow;
    }
  }

  /// Envía un mensaje
  static Future<void> sendMessage({
    required String conversationId,
    required ChatMessage message,
    String? conversationTitle,
  }) async {
    try {
      // Guardar mensaje
      final messageRef = await _firestore
          .collection('wanka_conversations')
          .doc(conversationId)
          .collection('messages')
          .add(message.toJson());

      // Actualizar último mensaje en la conversación
      await _firestore
          .collection('wanka_conversations')
          .doc(conversationId)
          .update({
        'lastMessage': message.content,
        'lastMessageTime': message.timestamp.toIso8601String(),
        'unreadCount': FieldValue.increment(1),
      });

      // Mostrar notificación local al enviar (para confirmación visual)
      await NotificationService.showNotification(
        title: 'Mensaje enviado',
        body: 'A ${message.receiverEmail}',
        payload: {
          'type': 'chat',
          'conversationId': conversationId,
          'messageId': messageRef.id,
        },
      );

      print('✅ Mensaje enviado y notificación mostrada');
    } catch (e) {
      print('❌ Error al enviar mensaje: $e');
      rethrow;
    }
  }

  /// Escucha mensajes nuevos y muestra notificaciones
  static void listenForNewMessages({
    required String conversationId,
    required String currentUserEmail,
    required String conversationTitle,
  }) {
    _firestore
        .collection('wanka_conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isEmpty) return;

      final doc = snapshot.docs.first;
      final messageId = doc.id;
      
      // Evitar notificaciones duplicadas
      if (_notifiedMessageIds.contains(messageId)) return;
      
      final data = doc.data();
      final senderEmail = data['senderEmail'] as String? ?? '';
      final senderName = data['senderName'] as String? ?? 'Alguien';
      final content = data['content'] as String? ?? '';

      // Solo notificar si el mensaje es de OTRO usuario (no del actual)
      if (senderEmail != currentUserEmail) {
        _notifiedMessageIds.add(messageId);
        
        // Limitar tamaño del set para evitar memory leaks
        if (_notifiedMessageIds.length > 100) {
          _notifiedMessageIds.clear();
        }

        NotificationService.showNotification(
          title: '💬 $senderName',
          body: content.length > 50 ? '${content.substring(0, 50)}...' : content,
          payload: {
            'type': 'chat',
            'conversationId': conversationId,
            'senderEmail': senderEmail,
            'senderName': senderName,
          },
        );
        
        print('🔔 Notificación mostrada para mensaje de $senderName');
      }
    });
  }

  /// Obtiene el stream de mensajes de una conversación
  static Stream<List<ChatMessage>> getMessagesStream(String conversationId) {
    return _firestore
        .collection('wanka_conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ChatMessage.fromJson(data);
      }).toList();
    });
  }

  /// Obtiene las conversaciones de un usuario (versión simple sin índices)
  static Stream<List<ChatConversation>> getUserConversations(String userEmail) async* {
    try {
      // Usar snapshots para tiempo real sin orderBy
      final employerStream = _firestore
          .collection('wanka_conversations')
          .where('employerEmail', isEqualTo: userEmail)
          .snapshots();
      
      final applicantStream = _firestore
          .collection('wanka_conversations')
          .where('applicantEmail', isEqualTo: userEmail)
          .snapshots();
      
      // Combinar ambos streams
      await for (final employerSnap in employerStream) {
        final applicantSnap = await _firestore
            .collection('wanka_conversations')
            .where('applicantEmail', isEqualTo: userEmail)
            .get();
        
        final allDocs = [...employerSnap.docs, ...applicantSnap.docs];
        
        // Eliminar duplicados
        final uniqueDocs = <String, QueryDocumentSnapshot>{};
        for (var doc in allDocs) {
          uniqueDocs[doc.id] = doc;
        }
        
        // Convertir a objetos
        final conversations = uniqueDocs.values.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return ChatConversation.fromJson(data);
        }).toList();
        
        // Ordenar en memoria
        conversations.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
        
        yield conversations;
      }
    } catch (e) {
      print('❌ Error al obtener conversaciones: $e');
      yield [];
    }
  }

  /// Marca mensajes como leídos
  static Future<void> markAsRead(String conversationId) async {
    try {
      await _firestore
          .collection('wanka_conversations')
          .doc(conversationId)
          .update({'unreadCount': 0});
    } catch (e) {
      print('Error al marcar como leído: $e');
    }
  }

  /// Obtiene el conteo de mensajes no leídos para un usuario (versión simple)
  static Stream<int> getUnreadCount(String userEmail) async* {
    try {
      // Obtener todas las conversaciones donde participa el usuario
      final employerStream = _firestore
          .collection('wanka_conversations')
          .where('employerEmail', isEqualTo: userEmail)
          .snapshots();
      
      await for (final employerSnap in employerStream) {
        final applicantSnap = await _firestore
            .collection('wanka_conversations')
            .where('applicantEmail', isEqualTo: userEmail)
            .get();
        
        final allDocs = [...employerSnap.docs, ...applicantSnap.docs];
        
        // Sumar unreadCount manualmente
        int total = 0;
        for (var doc in allDocs) {
          final data = doc.data();
          final count = data['unreadCount'] as int? ?? 0;
          if (count > 0) {
            total += count;
          }
        }
        
        yield total;
      }
    } catch (e) {
      print('❌ Error al obtener conteo: $e');
      yield 0;
    }
  }
}
