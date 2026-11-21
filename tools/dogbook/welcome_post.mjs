// Adds the Book Of Dog welcome post (run once by the "Book Of Dog welcome
// post" workflow). Safe to run again: it does nothing if the post exists.
// Needs FIREBASE_SA (service-account JSON) in the environment.
import crypto from 'node:crypto';
import { readFile } from 'node:fs/promises';
import admin from 'firebase-admin';
import sharp from 'sharp';

const PROJECT = 'golden-paw-database';
const BUCKET = `${PROJECT}.firebasestorage.app`;
const ADMIN_UID = 'P8iffVqbUgetAVA4MdHVZ1CfvUv1'; // so the admin can edit or delete it in the app

admin.initializeApp({
  credential: admin.credential.cert(JSON.parse(process.env.FIREBASE_SA)),
  storageBucket: BUCKET,
});
const db = admin.firestore();
const ref = db.collection('dogbook_posts').doc('welcome');

// The Golden Paw Shiba on a soft cream square. Bump IMAGE_VERSION when the
// art changes; running the workflow again then swaps the picture in place
// (likes and comments are kept).
const IMAGE_VERSION = 2;
const path = `dogbook/welcome-v${IMAGE_VERSION}.jpg`;

async function uploadImage() {
  const shiba = await readFile(new URL('../../assets/shiba_adult_v2.png', import.meta.url));
  const dog = await sharp(shiba).resize(900, 900, { fit: 'inside' }).toBuffer();
  const jpeg = await sharp({ create: { width: 1080, height: 1080, channels: 3, background: '#f3ede2' } })
    .composite([{ input: dog, gravity: 'center' }])
    .jpeg({ quality: 88, mozjpeg: true })
    .toBuffer();
  const token = crypto.randomUUID();
  await admin.storage().bucket().file(path).save(jpeg, {
    resumable: false,
    contentType: 'image/jpeg',
    metadata: { cacheControl: 'public, max-age=31536000', metadata: { firebaseStorageDownloadTokens: token } },
  });
  return `https://firebasestorage.googleapis.com/v0/b/${BUCKET}/o/${encodeURIComponent(path)}?alt=media&token=${token}`;
}

const existing = await ref.get();
if (existing.exists) {
  const old = existing.data();
  if (old.image_path === path) {
    console.log('Welcome post is up to date; nothing to do.');
    process.exit(0);
  }
  const imageUrl = await uploadImage();
  await ref.update({ image_url: imageUrl, image_path: path });
  if (old.image_path) await admin.storage().bucket().file(old.image_path).delete({ ignoreNotFound: true });
  console.log('Welcome post picture updated.');
  process.exit(0);
}

const imageUrl = await uploadImage();
await ref.set({
  uid: ADMIN_UID,
  author_name: 'Golden Paw',
  dog_name: 'Goldie',
  caption: "Welcome to The Book Of Dog! 🐾 I'm Goldie, the Golden Paw Shiba. "
    + 'Share a photo of your dog and tell us their name. Dogs only, be kind, and have fun!',
  image_url: imageUrl,
  image_path: path,
  created_at: admin.firestore.FieldValue.serverTimestamp(),
  like_count: 0,
  comment_count: 0,
  report_count: 0,
  hidden: false,
});
console.log('Welcome post created.');
