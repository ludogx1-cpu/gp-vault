// Publishes a newsletter as an approved article (blog_posts, category
// "newsletter"). Run by the "Publish newsletter article" workflow.
// Usage: node add_newsletter.mjs <doc-id> "<title>" <markdown file>
// Running it again with the same doc id updates the text in place.
import { readFile } from 'node:fs/promises';
import admin from 'firebase-admin';

const [docId, title, file] = process.argv.slice(2);
if (!/^[a-z0-9-]{4,60}$/.test(docId || '') || !title || !file) {
  console.error('Usage: node add_newsletter.mjs <doc-id> "<title>" <markdown file>');
  process.exit(1);
}
admin.initializeApp({ credential: admin.credential.cert(JSON.parse(process.env.FIREBASE_SA)) });
const content = (await readFile(file, 'utf8')).trim();
const ref = admin.firestore().collection('blog_posts').doc(docId);
const existing = await ref.get();
if (existing.exists) {
  await ref.update({ topic: title, content });
  console.log('Newsletter article updated.');
} else {
  await ref.set({
    topic: title,
    content,
    category: 'newsletter',
    approved: true,
    likedBy: [],
    dislikedBy: [],
    created_at: admin.firestore.FieldValue.serverTimestamp(),
  });
  console.log('Newsletter article published.');
}
