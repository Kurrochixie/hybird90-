const {onRequest} = require("firebase-functions/v2/https");
const {onCall} = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const {GoogleGenerativeAI} = require("@google/generative-ai");

admin.initializeApp();

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

exports.askGemini = onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "GET, POST");
  res.set("Access-Control-Allow-Headers", "Content-Type");

  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  if (!req.body || !req.body.prompt) {
    return res.status(400).send("Error: No prompt provided.");
  }

  const {prompt} = req.body;

  try {
    const model = genAI.getGenerativeModel({model: "gemini-pro"});
    const result = await model.generateContent(prompt);
    const response = await result.response;
    const text = response.text();

    res.status(200).send({response: text});
  } catch (error) {
    console.error("Error calling Gemini API:", error);
    res.status(500).send("Error: Could not get a response from the AI.");
  }
});

// FCM Notification Function for Fire Alarm Events
exports.sendFireAlarmNotification = onCall(async (req) => {
  const {eventType, status, user, projectName, panelType} = req.data;
  
  if (!eventType || !status || !user) {
    throw new Error("Missing required parameters: eventType, status, user");
  }

  try {
    // Create notification payload based on event type
    let title, body, data;
    
    switch (eventType) {
      case 'DRILL':
        title = '🚨 FIRE DRILL ALERT';
        body = `Drill mode ${status.toUpperCase()} by ${user}`;
        data = {
          type: 'fire_alarm_event',
          eventType: 'DRILL',
          status: status,
          user: user,
          priority: 'high',
          sound: status === 'ON' ? 'drill_alarm.mp3' : 'default'
        };
        break;
        
      case 'SYSTEM RESET':
        title = '🔄 SYSTEM RESET';
        body = `Fire alarm system reset by ${user}`;
        data = {
          type: 'fire_alarm_event',
          eventType: 'SYSTEM_RESET',
          status: 'COMPLETED',
          user: user,
          priority: 'high',
          sound: 'system_reset.mp3'
        };
        break;
        
      case 'SILENCE':
        title = '🔇 ALARM SILENCED';
        body = `Fire alarm ${status.toUpperCase()} by ${user}`;
        data = {
          type: 'fire_alarm_event',
          eventType: 'SILENCE',
          status: status,
          user: user,
          priority: 'medium',
          sound: 'silence_alarm.mp3'
        };
        break;
        
      case 'ACKNOWLEDGE':
        title = '✅ ALARM ACKNOWLEDGED';
        body = `Fire alarm ${status.toUpperCase()} by ${user}`;
        data = {
          type: 'fire_alarm_event',
          eventType: 'ACKNOWLEDGE',
          status: status,
          user: user,
          priority: 'medium',
          sound: 'acknowledge.mp3'
        };
        break;
        
      case 'ALARM':
        title = '🚨 FIRE ALARM';
        body = `Fire alarm ${status.toUpperCase()}${user ? ` by ${user}` : ''}`;
        data = {
          type: 'fire_alarm_event',
          eventType: 'ALARM',
          status: status,
          user: user || 'System',
          priority: 'high',
          sound: 'fire_alarm.mp3'
        };
        break;
        
      case 'TROUBLE':
        title = '⚠️ SYSTEM TROUBLE';
        body = `System trouble ${status.toUpperCase()}${user ? ` by ${user}` : ''}`;
        data = {
          type: 'fire_alarm_event',
          eventType: 'TROUBLE',
          status: status,
          user: user || 'System',
          priority: 'medium',
          sound: 'trouble_alarm.mp3'
        };
        break;
        
      default:
        title = '📢 Fire Alarm System';
        body = `${eventType}: ${status.toUpperCase()}${user ? ` by ${user}` : ''}`;
        data = {
          type: 'fire_alarm_event',
          eventType: eventType,
          status: status,
          user: user || 'System',
          priority: 'normal'
        };
    }

    // Add project info to data
    data.projectName = projectName || 'Unknown Project';
    data.panelType = panelType || 'Unknown Panel';
    data.timestamp = new Date().toISOString();

    // Create message payload
    const message = {
      topic: 'fire_alarm_events',
      notification: {
        title: title,
        body: body,
        imageUrl: 'https://firebasestorage.googleapis.com/v0/b/testing1do.appspot.com/o/fire_alarm_icon.png?alt=media'
      },
      data: data,
      android: {
        priority: data.priority === 'high' ? 'high' : 'normal',
        notification: {
          sound: data.sound,
          priority: data.priority === 'high' ? 'high' : 'default',
          channelId: 'fire_alarm_channel',
          icon: 'ic_notification',
          color: '#FF0000',
          vibrateTimings: data.priority === 'high' ? 
            ['0s', '0.5s', '0.5s', '0.5s'] : ['0s', '0.3s', '0.3s']
        }
      },
      apns: {
        payload: {
          aps: {
            sound: data.sound,
            badge: 1,
            category: 'FIRE_ALARM_EVENT',
            'mutable-content': 1
          }
        }
      }
    };

    // Send the message
    const response = await admin.messaging().send(message);
    
    console.log(`Notification sent successfully for ${eventType}:`, response);
    
    // Log the notification to Firestore (with error handling)
    try {
      await admin.firestore().collection('notification_logs').add({
        eventType: eventType,
        status: status,
        user: user,
        projectName: projectName,
        panelType: panelType,
        title: title,
        body: body,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        messageId: response
      });
    } catch (firestoreError) {
      console.warn('Failed to log to Firestore (API might be disabled):', firestoreError.message);
      // Continue without failing the main function
    }

    return { 
      success: true, 
      messageId: response,
      message: `Notification sent for ${eventType}: ${status}`
    };

  } catch (error) {
    console.error('Error sending fire alarm notification:', error);
    throw new Error(`Failed to send notification: ${error.message}`);
  }
});

// Function to subscribe users to fire alarm events topic
exports.subscribeToFireAlarmEvents = onCall(async (req) => {
  const {token} = req.data;
  
  if (!token) {
    throw new Error("FCM token is required");
  }

  try {
    const response = await admin.messaging().subscribeToTopic([token], 'fire_alarm_events');
    
    console.log('Subscription response:', response);
    
    return { 
      success: true, 
      message: 'Successfully subscribed to fire alarm events',
      failures: response.failures
    };
  } catch (error) {
    console.error('Error subscribing to topic:', error);
    throw new Error(`Failed to subscribe: ${error.message}`);
  }
});

// Function to unsubscribe users from fire alarm events topic
exports.unsubscribeFromFireAlarmEvents = onCall(async (req) => {
  const {token} = req.data;
  
  if (!token) {
    throw new Error("FCM token is required");
  }

  try {
    const response = await admin.messaging().unsubscribeFromTopic([token], 'fire_alarm_events');
    
    console.log('Unsubscription response:', response);
    
    return { 
      success: true, 
      message: 'Successfully unsubscribed from fire alarm events',
      failures: response.failures
    };
  } catch (error) {
    console.error('Error unsubscribing from topic:', error);
    throw new Error(`Failed to unsubscribe: ${error.message}`);
  }
});
