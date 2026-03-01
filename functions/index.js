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

    if (!message) return null;

    // Get chat metadata to find participants
    const chatSnapshot = await admin.database().ref(`/chats/${chatId}`).once("value");
    const chat = chatSnapshot.val();

    if (!chat || !chat.participantIds) return null;

    // Normalize participantIds (it could be an array or an object)
    let participantIds = [];
    if (Array.isArray(chat.participantIds)) {
      participantIds = chat.participantIds;
    } else if (typeof chat.participantIds === "object") {
      participantIds = Object.values(chat.participantIds);
    } else {
      console.error(`Unexpected participantIds type: ${typeof chat.participantIds}`);
      return null;
    }

    const senderId = message.senderId;
    const recipientIds = participantIds.filter((uid) => uid !== senderId);

    // Get sender's details for the notification
    const senderDoc = await admin.firestore().collection("users").doc(senderId).get();
    const senderData = senderDoc.data();
    const senderName = senderData ? senderData.name : "Nexora User";
    const senderAvatar = senderData ? senderData.avatar : "";

    // Send to each recipient
    const promises = recipientIds.map(async (uid) => {
      // Get recipient's FCM token from Firestore
      const userDoc = await admin.firestore().collection("users").doc(uid).get();
      const userData = userDoc.data();

      // Check if user has notifications enabled
      if (userData && userData.fcmToken && userData.messageNotifications !== false) {
        const messagePayload = {
          token: userData.fcmToken,
          notification: {
            title: senderName,
            body: message.type === "text" ? message.content : `Sent a ${message.type}`,
          },
          data: {
            chatId: chatId,
            senderId: senderId,
            senderName: senderName,
            senderAvatar: senderAvatar,
            type: "chat",
            click_action: "FLUTTER_NOTIFICATION_CLICK",
          },
          android: {
            priority: "high",
            notification: {
              channelId: "high_importance_channel",
              clickAction: "FLUTTER_NOTIFICATION_CLICK",
            },
          },
          apns: {
            payload: {
              aps: {
                contentAvailable: true,
                sound: "default",
              },
            },
          },
        };

        try {
          return await admin.messaging().send(messagePayload);
        } catch (error) {
          console.error(`Error sending message to ${uid}:`, error);
          if (error.code === "messaging/registration-token-not-registered") {
            // Cleanup stale token
            return admin.firestore().collection("users").doc(uid).update({ fcmToken: admin.firestore.FieldValue.delete() });
          }
        }
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
  .document("users/{uid}/notifications/{notificationId}")
  .onCreate(async (snapshot, context) => {
    const notification = snapshot.data();
    if (!notification) return null;

    const recipientId = context.params.uid;

    if (!recipientId) return null;

    // Get recipient's FCM token
    const userDoc = await admin.firestore().collection("users").doc(recipientId).get();
    const userData = userDoc.data();

    // Check if user has notifications enabled
    if (userData && userData.fcmToken && userData.pushNotifications !== false) {
      const messagePayload = {
        token: userData.fcmToken,
        notification: {
          title: notification.userName || "Nexora",
          body: notification.message,
        },
        data: {
          notificationId: context.params.notificationId,
          type: notification.type,
          userId: notification.userId || "",
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        android: {
          priority: "high",
          notification: {
            channelId: "high_importance_channel",
            clickAction: "FLUTTER_NOTIFICATION_CLICK",
          },
        },
        apns: {
          payload: {
            aps: {
              contentAvailable: true,
              sound: "default",
            },
          },
        },
      };

      try {
        return await admin.messaging().send(messagePayload);
      } catch (error) {
        console.error(`Error sending notification to ${recipientId}:`, error);
        if (error.code === "messaging/registration-token-not-registered") {
          return admin.firestore().collection("users").doc(recipientId).update({ fcmToken: admin.firestore.FieldValue.delete() });
        }
      }
    }
    return null;
  });
