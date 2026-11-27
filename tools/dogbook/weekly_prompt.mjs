// Zen's weekly prompt for The Book Of Dog.
// Run every Monday by the "Book Of Dog weekly prompt" workflow. It:
//   1. reports how last week's prompt went (posts and different owners), and
//   2. posts this week's prompt from Zen, the Golden Paw Shiba.
// Safe to run again in the same week: it won't post twice.
// Needs FIREBASE_SA (service-account JSON). With DRY_RUN=1 it only writes the
// picture to ./preview/ and prints the post, without touching the database.
import crypto from 'node:crypto';
import { readFile, mkdir, writeFile } from 'node:fs/promises';
import sharp from 'sharp';

const PROJECT = 'golden-paw-database';
const BUCKET = `${PROJECT}.firebasestorage.app`;
const ADMIN_UID = 'P8iffVqbUgetAVA4MdHVZ1CfvUv1'; // the admin can edit or delete it in the app
const DRY_RUN = process.env.DRY_RUN === '1';

// One prompt a week, in this order, then round again. Short and photo-friendly.
export const PROMPTS = [
  'Show us the most ridiculous place your dog has fallen asleep.',
  "What's your dog's favourite toy? Show us how well-loved it is.",
  'Muddy paws! Share your messiest walk photo.',
  'Puppy picture vs now. Show us how much they have grown.',
  'The guilty face. Show us your dog after mischief.',
  "Best seat in the house: where does your dog always sit?",
  'Show us your dog doing their best trick.',
  'Ears up! Share your dog listening very carefully.',
  'Walk buddies: share a photo from your favourite walk.',
  'Bath time. Brave, or not so brave?',
  'Zoomies! Share a photo of your dog mid-run.',
  'Snack face. Show us the look they give you at dinner time.',
];
const START = Date.UTC(2026, 10, 23); // Monday 23 November 2026: prompt 1

/** Monday (UTC) of the week containing `when`. */
export function mondayOf(when) {
  const d = new Date(Date.UTC(when.getUTCFullYear(), when.getUTCMonth(), when.getUTCDate()));
  const back = (d.getUTCDay() + 6) % 7;
  d.setUTCDate(d.getUTCDate() - back);
  return d;
}

export function promptFor(monday) {
  const weeks = Math.round((monday.getTime() - START) / (7 * 864e5));
  const n = ((weeks % PROMPTS.length) + PROMPTS.length) % PROMPTS.length;
  return { number: n + 1, text: PROMPTS[n], week: weeks + 1 };
}

const esc = s => s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/'/g, '&#39;');

function wrap(text, max) {
  const lines = [];
  let line = '';
  for (const word of text.split(' ')) {
    if ((line + ' ' + word).trim().length > max) { lines.push(line); line = word; } else line = (line + ' ' + word).trim();
  }
  if (line) lines.push(line);
  return lines;
}

/** A 1080×1080 card: the prompt in large type, with Zen in the corner. */
export async function promptCard(text) {
  const shiba = await readFile(new URL('../../assets/shiba_young_adult_v2.png', import.meta.url));
  const dog = await sharp(shiba).resize(470, 470, { fit: 'inside' }).toBuffer();
  const lines = wrap(text, 22);
  const size = lines.length > 4 ? 56 : 64;
  const lineH = Math.round(size * 1.22);
  const top = 250;
  const tspans = lines.map((l, i) => `<tspan x="80" y="${top + i * lineH}">${esc(l)}</tspan>`).join('');
  const svg = `<svg width="1080" height="1080" xmlns="http://www.w3.org/2000/svg">
    <rect width="1080" height="1080" fill="#f3ede2"/>
    <rect x="40" y="40" width="1000" height="1000" rx="48" fill="none" stroke="#c99a1e" stroke-width="6"/>
    <text x="80" y="150" font-family="DejaVu Sans, Arial, sans-serif" font-size="40" font-weight="bold" fill="#b8860b">ZEN'S WEEKLY CHALLENGE</text>
    <text font-family="DejaVu Sans, Arial, sans-serif" font-size="${size}" font-weight="bold" fill="#2b2213">${tspans}</text>
    <text x="80" y="990" font-family="DejaVu Sans, Arial, sans-serif" font-size="30" fill="#6b5a3a">The Book Of Dog · goldenpaw.dog</text>
  </svg>`;
  return sharp(Buffer.from(svg))
    .composite([{ input: dog, left: 1080 - 470 - 60, top: 1080 - 470 - 70 }])
    .jpeg({ quality: 88, mozjpeg: true })
    .toBuffer();
}

export function captionFor(prompt) {
  return `📸 Zen's challenge this week: ${prompt.text}\n\n`
    + 'Join in by sharing your own post in The Book Of Dog, and say hello to everyone else who does. '
    + 'A new challenge arrives every Monday. 🐾';
}

async function main() {
  const monday = mondayOf(new Date());
  const prompt = promptFor(monday);
  const id = `zen-prompt-${monday.toISOString().slice(0, 10)}`;
  const caption = captionFor(prompt);
  const jpeg = await promptCard(prompt.text);

  if (DRY_RUN) {
    await mkdir('preview', { recursive: true });
    await writeFile(`preview/${id}.jpg`, jpeg);
    console.log(`[dry run] ${id} (prompt ${prompt.number}, week ${prompt.week})\n${caption}`);
    return;
  }

  const { default: admin } = await import('firebase-admin');
  admin.initializeApp({ credential: admin.credential.cert(JSON.parse(process.env.FIREBASE_SA)), storageBucket: BUCKET });
  const db = admin.firestore();
  const posts = db.collection('dogbook_posts');

  // 1. How did last week go? Posts from players (not Golden Paw) since last Monday.
  const lastMonday = new Date(monday.getTime() - 7 * 864e5);
  const weekBefore = new Date(monday.getTime() - 14 * 864e5);
  const since = async (from, to) => {
    const snap = await posts.where('created_at', '>=', from).where('created_at', '<', to).get();
    const people = new Set();
    let count = 0;
    snap.forEach(d => { const p = d.data(); if (p.uid && p.uid !== ADMIN_UID) { count++; people.add(p.uid); } });
    return { count, people };
  };
  const last = await since(lastMonday, monday);
  const before = await since(weekBefore, lastMonday);
  const returning = [...last.people].filter(u => before.people.has(u)).length;
  const report = `Last week: ${last.count} posts from ${last.people.size} owners `
    + `(${returning} also posted the week before). Week before: ${before.count} posts from ${before.people.size} owners.`;
  console.log(report);
  await db.collection('dogbook_prompt_stats').doc(lastMonday.toISOString().slice(0, 10)).set({
    week_start: lastMonday, posts: last.count, owners: last.people.size, returning_owners: returning, recorded_at: new Date(),
  }, { merge: true });
  if (process.env.GITHUB_STEP_SUMMARY) {
    const { appendFile } = await import('node:fs/promises');
    await appendFile(process.env.GITHUB_STEP_SUMMARY, `### Book Of Dog\n${report}\n\nThis week: prompt ${prompt.number}, "${prompt.text}"\n`);
  }

  // 2. This week's prompt (once only).
  const ref = posts.doc(id);
  if ((await ref.get()).exists) { console.log(`${id} is already posted; nothing to do.`); return; }
  const path = `dogbook/${id}.jpg`;
  const token = crypto.randomUUID();
  await admin.storage().bucket().file(path).save(jpeg, {
    resumable: false,
    contentType: 'image/jpeg',
    metadata: { cacheControl: 'public, max-age=31536000', metadata: { firebaseStorageDownloadTokens: token } },
  });
  const url = `https://firebasestorage.googleapis.com/v0/b/${BUCKET}/o/${encodeURIComponent(path)}?alt=media&token=${token}`;
  await ref.set({
    uid: ADMIN_UID,
    author_name: 'Golden Paw',
    dog_id: '',
    dog_name: 'Zen',
    dog_photo_url: '',
    caption,
    images: [{ url, path }],
    image_url: url,
    image_path: path,
    like_count: 0,
    comment_count: 0,
    share_count: 0,
    report_count: 0,
    hidden: false,
    prompt: true,
    prompt_number: prompt.number,
    created_at: admin.firestore.FieldValue.serverTimestamp(),
  });
  console.log(`Posted ${id}: ${prompt.text}`);
}

if (import.meta.url === `file://${process.argv[1]}`) await main();
