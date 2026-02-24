const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

/**
 * Sends a notification when a new message is received in RTDB
 */
exports.notifyNewMessage = functions.database.ref("/messages/{chatId}/{messageId}")
    .onCreate(async (snapshot, context) => {
      const message = snapshot.val();
      const chatId = context.params.chatId;

      // Get chat metadata to find participants
      const chatSnapshot = await admin.database().ref(`/chats/${chatId}`).once("value");
      const chat = chatSnapshot.val();

      if (!chat || !chat.participantIds) return null;

      const senderId = message.senderId;
      const recipientIds = chat.participantIds.filter((uid) => uid !== senderId);

      // Send to each recipient
      const promises = recipientIds.map(async (uid) => {
        // Get recipient's FCM token from Firestore
        const userDoc = await admin.firestore().collection("users").doc(uid).get();
        const userData = userDoc.data();

        if (userData && userData.fcmToken) {
          const payload = {
            notification: {
              title: userData.name || "New Message",
              body: message.type === "text" ? message.content : `Sent a ${message.type}`,
              clickAction: "FLUTTER_NOTIFICATION_CLICK",
            },
            data: {
              chatId: chatId,
              senderId: senderId,
              type: "chat",
            },
          };

          return admin.messaging().sendToDevice(userData.fcmToken, payload);
        }
        return null;
      });

      return Promise.all(promises);
    });

/**
 * Sends a notification when a new connection request is created in Firestore
 */
exports.notifyConnectionRequest = functions.firestore
    .document("connection_requests/{requestId}")
    .onCreate(async (snapshot, context) => {
      const request = snapshot.data();
      const toId = request.toId;
      const fromName = request.fromName || "Someone";

      // Get recipient's FCM token
      const userDoc = await admin.firestore().collection("users").doc(toId).get();
      const userData = userDoc.data();

      if (userData && userData.fcmToken) {
        const payload = {
          notification: {
            title: "New Connection Request",
            body: `${fromName} wants to connect with you!`,
            clickAction: "FLUTTER_NOTIFICATION_CLICK",
          },
          data: {
            fromId: request.fromId,
            type: "connection",
          },
        };

        return admin.messaging().sendToDevice(userData.fcmToken, payload);
      }
      return null;
    });
