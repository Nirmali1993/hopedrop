const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

// ✅ Trigger when new blood request is created
exports.notifyDonors = functions.firestore
    .document("blood_requests/{requestId}")
    .onCreate(async (snap, context) => {
      const request = snap.data();
      const bloodType = request.bloodType;
      const hospital = request.hospital;
      const location = request.location;

      console.log(`🩸 New blood request for ${bloodType} at ${hospital}`);

      try {
        // Find all available donors with matching blood type
        const donorsSnapshot = await admin.firestore()
            .collection("users")
            .where("role", "==", "donor")
            .where("bloodType", "==", bloodType)
            .where("isAvailable", "==", true)
            .get();

        console.log(`Found ${donorsSnapshot.size} matching donors`);

        const notifications = [];

        donorsSnapshot.forEach((doc) => {
          const donor = doc.data();
          const token = donor.fcmToken;

          if (token) {
            const message = {
              token: token,
              notification: {
                title: `🩸 Urgent Blood Needed! (${bloodType})`,
                body: `${hospital} · ${location} needs ${bloodType} donors`,
              },
              android: {
                priority: "high",
                notification: {
                  channelId: "high_importance_channel",
                  priority: "high",
                  defaultSound: true,
                },
              },
            };
            notifications.push(admin.messaging().send(message));
            console.log(`✅ Sending to donor: ${donor.name}`);
          }
        });

        // Send all notifications
        const results = await Promise.all(notifications);
        console.log(`✅ Sent ${results.length} notifications!`);
        return null;
      } catch (error) {
        console.error("❌ Error sending notifications:", error);
        return null;
      }
    });