const admin = require('firebase-admin');
const serviceAccount = require('../../service-account.json');
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
}
const db = admin.firestore();
db.collection('blog_posts').orderBy('created_at', 'desc').limit(5).get().then(snap => {
  snap.forEach(doc => {
    console.log('ID:', doc.id);
    const data = doc.data();
    console.log('TOPIC:', data.topic || data.title);
    console.log('CONTENT LENGTH:', (data.content || data.message || '').length);
    console.log('CONTENT:', (data.content || data.message || '').substring(0, 100));
  });
}).catch(console.error);
