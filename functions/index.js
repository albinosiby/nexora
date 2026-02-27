const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

/**
 * Sends a push notification when a new message is received in RTDB
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

    // Get sender's details for the notification
    const senderDoc = await admin.firestore().collection("users").doc(senderId).get();
    const senderData = senderDoc.data();
    const senderName = senderData ? senderData.name : "Nexora User";

    // Send to each recipient
    const promises = recipientIds.map(async (uid) => {
      // Get recipient's FCM token from Firestore
      const userDoc = await admin.firestore().collection("users").doc(uid).get();
      const userData = userDoc.data();

      if (userData && userData.fcmToken) {
        const payload = {
          notification: {
            title: senderName,
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
 * Sends a push notification for any new document in the "notifications" collection.
 * This handles connection requests, acceptances, likes, etc.
 */
exports.onNotificationCreated = functions.firestore
  .document("notifications/{notificationId}")
  .onCreate(async (snapshot, context) => {
    const notification = snapshot.data();
    const recipientId = notification.recipientId;

    if (!recipientId) return null;

    // Get recipient's FCM token
    const userDoc = await admin.firestore().collection("users").doc(recipientId).get();
    const userData = userDoc.data();

    if (userData && userData.fcmToken) {
      const payload = {
        notification: {
          title: notification.userName || "Nexora",
          body: notification.message,
          clickAction: "FLUTTER_NOTIFICATION_CLICK",
        },
        data: {
          notificationId: context.params.notificationId,
          type: notification.type,
          userId: notification.userId,
        },
      };

      return admin.messaging().sendToDevice(userData.fcmToken, payload);
    }
    return null;
  });
