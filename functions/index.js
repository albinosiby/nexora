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
    console.log(`New message in ${chatId}: ${context.params.messageId}`);

    if (!message) return null;

    // Special handling for community chat (optional tracking)
    if (chatId === "community") {
      console.log("Community chat message detected. Skipping standard notifications.");
      return null;
    }

    // Get chat metadata to find participants
    const chatSnapshot = await admin.database().ref(`/chats/${chatId}`).once("value");
    const chat = chatSnapshot.val();

    if (!chat) {
      console.log(`Chat ${chatId} not found in metadata.`);
      return null;
    }

    if (!chat.participantIds) {
      console.log(`No participantIds found for chat ${chatId}.`);
      return null;
    }

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
    console.log(`Sending message notifications to ${recipientIds.length} recipients: ${recipientIds.join(", ")}`);

    // Get sender's details for the notification
    const senderDoc = await admin.firestore().collection("users").doc(senderId).get();
    const senderData = senderDoc.data();
    const senderName = senderData ? (senderData.username || senderData.name) : "Nexora User";
    const senderAvatar = senderData ? senderData.avatar : "";

    // Send to each recipient
    const promises = recipientIds.map(async (uid) => {
      // Get recipient's FCM token from Firestore
      const userDoc = await admin.firestore().collection("users").doc(uid).get();
      const userData = userDoc.data();

      if (!userData) {
        console.log(`UserData not found for recipient ${uid}`);
        return null;
      }

      if (!userData.fcmToken) {
        console.log(`FCM token missing for recipient ${uid}`);
        return null;
      }

      // Check if user has notifications enabled
      if (userData.messageNotifications === false) {
        console.log(`Notifications disabled for user ${uid}`);
        return null;
      }

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
        const response = await admin.messaging().send(messagePayload);
        console.log(`Successfully sent message to ${uid}: ${response}`);
        return response;
      } catch (error) {
        console.error(`Error sending message to ${uid}:`, error);
        if (error.code === "messaging/registration-token-not-registered") {
          console.log(`Cleaning up stale token for ${uid}`);
          return admin.firestore().collection("users").doc(uid).update({ fcmToken: admin.firestore.FieldValue.delete() });
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
    const recipientId = context.params.uid;
    console.log(`New notification document for ${recipientId}: ${context.params.notificationId}`);

    if (!notification) return null;

    // Get recipient's FCM token
    const userDoc = await admin.firestore().collection("users").doc(recipientId).get();
    const userData = userDoc.data();

    if (!userData) {
      console.log(`Recipient ${recipientId} data not found.`);
      return null;
    }

    if (!userData.fcmToken) {
      console.log(`FCM token missing for recipient ${recipientId}`);
      return null;
    }

    // Check if user has notifications enabled
    if (userData.pushNotifications === false) {
      console.log(`Push notifications disabled for user ${recipientId}`);
      return null;
    }

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
        targetId: notification.targetId || "",
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
      const response = await admin.messaging().send(messagePayload);
      console.log(`Successfully sent notification to ${recipientId}: ${response}`);
      return response;
    } catch (error) {
      console.error(`Error sending notification to ${recipientId}:`, error);
      if (error.code === "messaging/registration-token-not-registered") {
        console.log(`Cleaning up stale token for ${recipientId}`);
        return admin.firestore().collection("users").doc(recipientId).update({ fcmToken: admin.firestore.FieldValue.delete() });
      }
    }
    return null;
  });
