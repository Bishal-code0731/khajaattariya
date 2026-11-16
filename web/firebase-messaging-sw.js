importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyA0K9Eq845WU-udwrz1D7GGLdJjrE1wS7I',
  appId: '1:1085770935101:web:53aebd821371ef7e853354',
  messagingSenderId: '1085770935101',
  projectId: 'khajaattariya-app',
  authDomain: 'khajaattariya-app.firebaseapp.com',
  storageBucket: 'khajaattariya-app.firebasestorage.app',
});

firebase.messaging();