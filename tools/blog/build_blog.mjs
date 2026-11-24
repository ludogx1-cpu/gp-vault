// Builds Google-friendly static pages for Golden Paw blog posts.
//
// Reads approved "daily_blog" and "newsletter" posts from Firestore
// (collection blog_posts) and writes, inside the Flutter web build:
//   build/web/articles/index.html            list of all articles
//   build/web/articles/<slug>/index.html     one page per article
// and adds the article URLs to build/web/sitemap.xml.
//
// Usage (run by .github/workflows/deploy-hosting.yml):
//   FIREBASE_SA='<service account JSON>' node build_blog.mjs <build/web dir>
//
// The slug rule must match articleSlug() in lib/screens/blog_page.dart.

import fs from 'node:fs';
import path from 'node:path';
import { initializeApp, cert } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { Marked } from 'marked';

// Posts written before this date get a short note that Golden Paw has changed since.
const OLD_POST_CUTOFF = new Date('2026-11-01T00:00:00Z');

const SITE = 'https://goldenpaw.dog';
const OUT = process.argv[2];
if (!OUT || !fs.existsSync(OUT)) {
  console.error('Usage: node build_blog.mjs <build/web dir>');
  process.exit(1);
}
const sa = process.env.FIREBASE_SA;
if (!sa) {
  console.log('FIREBASE_SA not set; skipping blog pages.');
  process.exit(0);
}

function articleSlug(topic, id) {
  let s = String(topic || '').toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '');
  s = s.slice(0, 60).replace(/-+$/g, '');
  if (!s) s = 'post';
  return `${s}-${String(id).slice(0, 8)}`;
}

const esc = (t) => String(t ?? '')
  .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
  .replace(/"/g, '&quot;').replace(/'/g, '&#39;');

// Markdown -> HTML. Raw HTML in posts is shown as text, and links/images
// are limited to safe URL schemes.
const safeUrl = (u) => (/^(https?:|mailto:|\/)/i.test(String(u || '').trim()) ? String(u).trim() : '#');
const marked = new Marked({
  gfm: true,
  renderer: {
    html(token) { return esc(token.text ?? token.raw ?? ''); },
    link(token) {
      const href = safeUrl(token.href);
      const ext = /^https?:/i.test(href) && !href.startsWith(SITE);
      const text = this.parser.parseInline(token.tokens);
      return `<a href="${esc(href)}"${ext ? ' target="_blank" rel="noopener nofollow"' : ''}>${text}</a>`;
    },
    image(token) {
      return `<img src="${esc(safeUrl(token.href))}" alt="${esc(token.text)}" loading="lazy">`;
    },
  },
});

const plain = (md) => String(md || '')
  .replace(/```[\s\S]*?```/g, ' ')
  .replace(/<[^>]*>/g, ' ')
  .replace(/!\[[^\]]*\]\([^)]*\)/g, ' ')
  .replace(/\[([^\]]*)\]\((?:[^()]|\([^)]*\))*\)/g, '$1')
  .replace(/[#>*_`~|-]+/g, ' ')
  .replace(/\s+/g, ' ')
  .trim();

const describe = (md) => {
  const t = plain(md);
  return t.length > 155 ? t.slice(0, 152).replace(/\s+\S*$/, '') + '…' : t;
};

const fmtDate = (d) => d.toLocaleDateString('en-GB', { day: 'numeric', month: 'long', year: 'numeric' });

function shell({ title, description, canonical, body, ogType = 'website', jsonld = '' }) {
  return `<!DOCTYPE html>
<html lang="en-GB">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${esc(title)}</title>
    <meta name="description" content="${esc(description)}">
    <link rel="canonical" href="${esc(canonical)}">
    <link rel="icon" type="image/png" href="/favicon.png?v=4">
    <meta property="og:type" content="${ogType}">
    <meta property="og:site_name" content="Golden Paw">
    <meta property="og:title" content="${esc(title)}">
    <meta property="og:description" content="${esc(description)}">
    <meta property="og:url" content="${esc(canonical)}">
    <meta property="og:image" content="${SITE}/og-image.png">
    <meta name="twitter:card" content="summary_large_image">
    <meta name="twitter:title" content="${esc(title)}">
    <meta name="twitter:description" content="${esc(description)}">
    <meta name="twitter:image" content="${SITE}/og-image.png">
    <link rel="stylesheet" href="/studios/styles.css">
    <style>
      .article-wrap { max-width: 760px; margin: 0 auto; padding: 3rem 6% 4rem; }
      .article-dated { background: var(--surface-2, rgba(212,160,23,.08)); border-left: 3px solid #d4a017; padding: .6rem .9rem; border-radius: 6px; font-size: .92rem; margin: 0 0 1.25rem; }
      .article-meta { color: var(--text-muted); font-size: .92rem; margin-bottom: 1.5rem; }
      .article-wrap h1 { font-family: var(--font-heading); font-size: clamp(2rem, 4.5vw, 2.8rem); line-height: 1.15; color: #FFF; margin-bottom: .75rem; }
      .article-body { color: var(--text-light); font-size: 1.07rem; line-height: 1.8; }
      .article-body h2, .article-body h3 { font-family: var(--font-heading); color: var(--primary-gold); margin: 2rem 0 .75rem; line-height: 1.3; }
      .article-body p, .article-body ul, .article-body ol, .article-body blockquote { margin-bottom: 1.1rem; }
      .article-body ul, .article-body ol { padding-left: 1.4rem; }
      .article-body a { color: var(--primary-gold); }
      .article-body img { max-width: 100%; border-radius: 12px; }
      .article-body blockquote { border-left: 3px solid var(--primary-gold); padding-left: 1rem; color: var(--text-muted); }
      .article-body code { background: rgba(255,255,255,.08); padding: .1rem .35rem; border-radius: 6px; }
      .article-cta { margin-top: 2.5rem; padding: 1.5rem; border: 1px solid var(--glass-border); border-radius: 18px; background: var(--card-bg); text-align: center; }
      .article-cta p { color: var(--text-light); margin-bottom: 1rem; }
      .article-list { list-style: none; max-width: 760px; margin: 0 auto; padding: 0 6% 4rem; }
      .article-list li { background: var(--card-bg); border: 1px solid var(--glass-border); border-radius: 16px; padding: 1.25rem 1.5rem; margin-bottom: 1rem; }
      .article-list a.title { font-family: var(--font-heading); font-size: 1.25rem; color: #FFF; text-decoration: none; }
      .article-list a.title:hover { color: var(--primary-gold); }
      .article-list .date { color: var(--text-muted); font-size: .85rem; margin: .25rem 0 .5rem; }
      .article-list p { color: var(--text-light); font-size: .95rem; }
      @media (max-width: 760px) { .article-wrap { padding: 2rem 16px 3rem; } .article-list { padding: 0 16px 3rem; } .nav-links a:not(.nav-btn) { display: none; } }
    </style>
    ${jsonld}
</head>
<body>
    <nav>
        <a href="/" class="brand">
            <img src="/paw-logo-192.png?v=2" alt="Golden Paw logo" class="brand-icon">
            <span>Golden Paw</span>
        </a>
        <div class="nav-links">
            <a href="/articles/">Articles</a>
            <a href="/shop/">Shop</a>
            <a href="/support/">Help</a>
            <a href="/" class="nav-btn">Play Golden Paw</a>
        </div>
    </nav>
${body}
    <footer>
        <div class="footer-content">
            <p class="copyright">&copy; ${new Date().getFullYear()} Golden Paw Studios. All rights reserved.</p>
            <p class="copyright">18+ only. Golden Paw is entertainment, not an investment. Not financial advice.</p>
            <div class="footer-links">
                <a href="/articles/">All articles</a>
                <a href="/studios/">Studios</a>
                <a href="/privacy/">Privacy Policy</a>
                <a href="/terms/">Terms of Service</a>
            </div>
        </div>
    </footer>
</body>
</html>
`;
}

const app = initializeApp({ credential: cert(JSON.parse(sa)) });
const db = getFirestore(app);

const snap = await db.collection('blog_posts').where('approved', '==', true).get();
const posts = [];
for (const doc of snap.docs) {
  const d = doc.data();
  if (!['daily_blog', 'newsletter'].includes(d.category)) continue;
  if (d.external_url) continue; // lives on another site
  const content = d.content ?? d.message ?? '';
  const topic = d.topic ?? d.title ?? 'Untitled';
  if (!String(content).trim()) continue;
  const created = d.created_at && typeof d.created_at.toDate === 'function' ? d.created_at.toDate() : null;
  posts.push({ id: doc.id, topic, content, category: d.category, created, slug: articleSlug(topic, doc.id) });
}
posts.sort((a, b) => (b.created?.getTime() ?? 0) - (a.created?.getTime() ?? 0));

const base = path.join(OUT, 'articles');
fs.rmSync(base, { recursive: true, force: true });
fs.mkdirSync(base, { recursive: true });

for (const p of posts) {
  const url = `${SITE}/articles/${p.slug}/`;
  const description = describe(p.content) || 'A Golden Paw article.';
  const dateTxt = p.created ? fmtDate(p.created) : '';
  const jsonld = `<script type="application/ld+json">${JSON.stringify({
    '@context': 'https://schema.org',
    '@type': 'BlogPosting',
    headline: p.topic,
    description,
    datePublished: p.created ? p.created.toISOString() : undefined,
    url,
    image: `${SITE}/og-image.png`,
    author: { '@type': 'Organization', name: 'Golden Paw Studios' },
    publisher: { '@type': 'Organization', name: 'Golden Paw Studios', logo: { '@type': 'ImageObject', url: `${SITE}/paw-logo-192.png` } },
  }).replace(/</g, '\\u003c')}</script>`;
  const body = `    <main class="article-wrap">
        <article>
            <h1>${esc(p.topic)}</h1>
            <div class="article-meta">${dateTxt ? `${esc(dateTxt)} · ` : ''}${p.category === 'newsletter' ? 'Newsletter' : 'Golden Paw blog'}</div>
${p.created && p.created < OLD_POST_CUTOFF ? `            <p class="article-dated">Written ${esc(dateTxt)}. Golden Paw has changed since then; for how it works today, see <a href="/about.html">About Golden Paw</a>.</p>
` : ''}            <div class="article-body">
${marked.parse(String(p.content))}
            </div>
        </article>
        <div class="article-cta">
            <p>Raise your own Shiba in Golden Paw, the virtual pet game for dog lovers (18+).</p>
            <a class="btn btn-primary" href="/">Play Golden Paw</a>
            <a class="btn btn-secondary" href="/articles/">More articles</a>
        </div>
    </main>`;
  const dir = path.join(base, p.slug);
  fs.mkdirSync(dir, { recursive: true });
  fs.writeFileSync(path.join(dir, 'index.html'), shell({
    title: `${p.topic} | Golden Paw`,
    description,
    canonical: url,
    body,
    ogType: 'article',
    jsonld,
  }));
}

const listItems = posts.map((p) => `        <li>
            <a class="title" href="/articles/${p.slug}/">${esc(p.topic)}</a>
            ${p.created ? `<div class="date">${esc(fmtDate(p.created))}</div>` : ''}
            <p>${esc(describe(p.content))}</p>
        </li>`).join('\n');
fs.writeFileSync(path.join(base, 'index.html'), shell({
  title: 'Articles | Golden Paw',
  description: 'News, tips and updates from Golden Paw, the virtual pet game for dog lovers.',
  canonical: `${SITE}/articles/`,
  body: `    <header class="hero" style="padding-bottom:1.5rem">
        <div class="hero-badge">✦ GOLDEN PAW BLOG ✦</div>
        <h1>Articles &amp; <span class="gold-gradient">updates</span></h1>
        <p class="hero-subtext">News, tips and updates from the Golden Paw team.</p>
    </header>
    <ul class="article-list">
${listItems || '        <li><p>No articles yet. Check back soon!</p></li>'}
    </ul>`,
}));

// Sitemap: add the articles index and every article.
const sitemap = path.join(OUT, 'sitemap.xml');
if (fs.existsSync(sitemap)) {
  const urls = [`${SITE}/articles/`, ...posts.map((p) => `${SITE}/articles/${p.slug}/`)];
  const entries = urls.map((u, i) => `  <url>\n    <loc>${esc(u)}</loc>\n    <changefreq>${i === 0 ? 'daily' : 'monthly'}</changefreq>\n    <priority>${i === 0 ? '0.7' : '0.6'}</priority>\n  </url>`).join('\n');
  const xml = fs.readFileSync(sitemap, 'utf8').replace('</urlset>', `${entries}\n</urlset>`);
  fs.writeFileSync(sitemap, xml);
}

console.log(`Built ${posts.length} article page(s).`);
