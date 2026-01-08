/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {setGlobalOptions} = require("firebase-functions");
const {onRequest} = require("firebase-functions/v2/https");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

// Initialize Firebase Admin
admin.initializeApp();

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.
setGlobalOptions({ maxInstances: 10 });

// Cloud Function to send FCM push notifications when a new notification is created
exports.sendPushNotification = onDocumentCreated(
  "notifications/{notificationId}",
  async (event) => {
    const notificationData = event.data.data();
    const notificationId = event.params.notificationId;

    logger.info(`New notification created: ${notificationId}`, {
      userId: notificationData.userId,
      title: notificationData.title,
      type: notificationData.type,
    });

    try {
      // Get user's FCM token
      const userDoc = await admin
        .firestore()
        .collection("users")
        .doc(notificationData.userId)
        .get();

      if (!userDoc.exists) {
        logger.warn(`User not found: ${notificationData.userId}`);
        return;
      }

      const userData = userDoc.data();
      const fcmToken = userData.fcmToken;

      if (!fcmToken) {
        logger.warn(
          `No FCM token for user: ${notificationData.userId}. Notification stored but push not sent.`
        );
        return;
      }

      // Prepare FCM message
      const message = {
        token: fcmToken,
        notification: {
          title: notificationData.title,
          body: notificationData.body,
        },
        data: {
          type: notificationData.type || "",
          notificationId: notificationId,
          ...notificationData.data,
        },
        android: {
          priority: "high",
          notification: {
            sound: "default",
            channelId: "kids_car_notifications",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
      };

      // Send FCM message
      const response = await admin.messaging().send(message);
      logger.info(`Successfully sent push notification: ${response}`, {
        userId: notificationData.userId,
        notificationId: notificationId,
      });
    } catch (error) {
      logger.error(`Error sending push notification: ${error}`, {
        userId: notificationData.userId,
        notificationId: notificationId,
        error: error.message,
      });
    }
  }
);
