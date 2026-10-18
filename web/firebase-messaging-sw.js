// 1. Use the compat versions to ensure 'firebase' global is defined
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

// 2. Initialize
firebase.initializeApp({
    apiKey: "AIzaSyBuaBe8GUExCNm_MAqdEA51ohQGeGLCO40",
    authDomain: "nexstream-b070d.firebaseapp.com",
    projectId: "nexstream-b070d",
    storageBucket: "nexstream-b070d.firebasestorage.app",
    messagingSenderId: "124709066369",
    appId: "1:124709066369:android:da92edd716c1dedee59f80"
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
