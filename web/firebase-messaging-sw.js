// 1. Use the compat versions to ensure 'firebase' global is defined
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

// 2. Initialize
firebase.initializeApp({
    apiKey: "AIzaSyDlXcV3tPcwtbhQ4YnjBkFJLbo2uKWMsJY",
    authDomain: "nexstream-b070d.firebaseapp.com",
    projectId: "nexstream-b070d",
    storageBucket: "nexstream-b070d.firebasestorage.app",
    messagingSenderId: "124709066369",
    appId: "1:124709066369:web:50a5f47d7f1a80c1e59f80"
});

// 3. Retrieve Messaging
const messaging = firebase.messaging();

// 4. Background handler
messaging.onBackgroundMessage((payload) => {
    console.log('Received background message ', payload);
    const notificationTitle = payload.notification.title;
    const notificationOptions = {
        body: payload.notification.body,
        icon: '/favicon.ico'
    };
    self.registration.showNotification(notificationTitle, notificationOptions);
});
