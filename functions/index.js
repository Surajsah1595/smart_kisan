const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.sendNotification = functions.firestore
    .document('users/{userId}/notifications/{notifId}')
    .onCreate(async (snap, context) => {
      const notif = snap.data();
      const userId = context.params.userId;
      
      const userDoc = await admin.firestore().collection('users').doc(userId).get();
      const token = userDoc.data()?.fcmToken;
      
      if (!token) return null;
      
      const payload = {
        notification: {
          title: notif.title || 'Smart Kisan',
          body: notif.message || notif.body || '',
        },
      };
      
      return admin.messaging().sendToDevice(token, payload);
    });
