import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../src/theme_provider.dart';
import '../widgets/trustpilot_widget.dart';
import '../widgets/newsletter_subscribe_widget.dart';
import '../widgets/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:gp_faucet/src/brand_colors.dart';

class LandingPage extends StatefulWidget {
  final void Function(BuildContext, bool) onAuthTrigger;

  const LandingPage({super.key, required this.onAuthTrigger});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  bool get _isDark => themeProvider.isDarkMode;
  Color get _text => _isDark ? Colors.white : Colors.black87;
  Color get _soft => _isDark ? Colors.white70 : Colors.black54;
  Color get _card => _isDark ? themeProvider.darkGreyBoxColor : Colors.white;

  void _signUp() => widget.onAuthTrigger(context, false);
  void _logIn() => widget.onAuthTrigger(context, true);
  void _browseBookOfDog() => context.go('/book-of-dog');

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 700;

    return AppScaffold(
      showSidebar: false,
      backgroundColor: Colors.transparent,
      appBar: GlobalAppBar(
        showMenuIcon: false,
        centerTitle: false,
        showWallet: false,
        actions: [
          if (!isMobile)
            TextButton(
              onPressed: _browseBookOfDog,
              child: Text('BOOK OF DOG',
                  style: TextStyle(color: gpChromeText(context), fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          if (isMobile)
            IconButton(
              onPressed: _logIn,
              tooltip: 'Log in',
              icon: Icon(Icons.login, color: gpChromeText(context)),
            )
          else
            TextButton(
              onPressed: _logIn,
              child: Text('LOG IN',
                  style: TextStyle(color: gpChromeText(context), fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 4 : 12, vertical: 8),
            child: FilledButton(
              onPressed: _signUp,
              style: FilledButton.styleFrom(
                backgroundColor: kGold,
                foregroundColor: Colors.black,
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 20),
              ),
              child: Text('SIGN UP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 13 : 15)),
            ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: themeProvider,
        builder: (context, _) => Stack(
          children: [
            PageWithFooter(
              child: Column(
                children: [
                  if (kIsWeb) const SizedBox(height: 70),
                  _hero(isMobile),
                  _section(_growStrip(isMobile)),
                  _section(_howItWorks(isMobile)),
                  _section(_freshFromBookOfDog(isMobile)),
                  _section(_gpawsTeaser(isMobile)),
                  _section(_trust(isMobile)),
                  _section(_moreFromGoldenPaw(isMobile)),
                  _section(_faq()),
                  const SizedBox(height: 20),
                  _buildAboutStudiosSection(context),
                  const SizedBox(height: 50),
                  const NewsletterSubscribeWidget(),
                  const SizedBox(height: 40),
                  const PwaInstallWidget(),
                  SizedBox(height: isMobile ? 120 : 80),
                ],
              ),
            ),
            // Phones: a slim sign-up bar that stays at the bottom while scrolling.
            if (isMobile)
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: SafeArea(
                  top: false,
                  child: Material(
                    elevation: 10,
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(30),
                    child: FilledButton.icon(
                      onPressed: _signUp,
                      style: FilledButton.styleFrom(
                        backgroundColor: kGold,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      icon: const Icon(Icons.pets),
                      label: const Text('Adopt your Shiba (free)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _section(Widget child) => Padding(
        padding: const EdgeInsets.only(top: 70),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: child),
          ),
        ),
      );

  Widget _heading(String title, String subtitle) => Column(
        children: [
          Text(title,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  fontVariations: const [FontVariation('wght', 700)],
                  color: _text)),
          const SizedBox(height: 8),
          Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: _soft, height: 1.4)),
          const SizedBox(height: 28),
        ],
      );

  // 1. Hero: dog-first headline, two ways in, the Shiba and its kennel.
  Widget _hero(bool isMobile) {
    final text = Column(
      crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: kGold.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kGold.withValues(alpha: 0.5)),
          ),
          child: Text('🐾  Free virtual pet game · Made in the UK',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _isDark ? kGold : kGold.shade800)),
        ),
        const SizedBox(height: 18),
        Text(
          'Raise your own Shiba.\nShare your real dog.',
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: isMobile ? 36 : 54,
            height: 1.1,
            fontWeight: FontWeight.w800,
            fontVariations: const [FontVariation('wght', 800)],
            color: _text,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Adopt a pup, watch it grow from a sleepy baby to a wise old dog, and join a friendly community of dog lovers in The Book Of Dog.',
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
          style: TextStyle(fontSize: isMobile ? 16 : 19, color: _soft, height: 1.5),
        ),
        const SizedBox(height: 28),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: isMobile ? WrapAlignment.center : WrapAlignment.start,
          children: [
            FilledButton.icon(
              onPressed: _signUp,
              style: FilledButton.styleFrom(
                backgroundColor: kGold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                elevation: 8,
                shadowColor: kGold.withValues(alpha: 0.5),
              ),
              icon: const Icon(Icons.pets),
              label: const Text('Adopt your Shiba (free)', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ),
            OutlinedButton.icon(
              onPressed: _browseBookOfDog,
              style: OutlinedButton.styleFrom(
                foregroundColor: _text,
                side: const BorderSide(color: kGold, width: 1.5),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              icon: const Icon(Icons.menu_book_outlined, color: kGold),
              label: const Text('Browse The Book Of Dog', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text('Sign up in seconds with Google or email. No card, no deposits.',
            textAlign: isMobile ? TextAlign.center : TextAlign.left,
            style: TextStyle(fontSize: 13, color: _soft)),
      ],
    );

    final visual = SizedBox(
      height: isMobile ? 240 : 380,
      child: Stack(
        alignment: Alignment.bottomCenter,
        // The Shiba is placed a little below the box so it stands in front of the kennel;
        // don't clip its paws.
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            bottom: 0,
            height: isMobile ? 190 : 300,
            // Same kennel art as the game, without the food dispenser and bone,
            // so the Shiba can stand in front of it.
            child: Image.asset('assets/kennel_landing.png', fit: BoxFit.contain),
          ),
          // The Shiba artwork has ~9% empty space under its paws, so it's offset down
          // to stand on the ground in front of the kennel, and kept well under the
          // kennel's height so the pair looks in proportion.
          Positioned(
            right: isMobile ? 44 : 24,
            bottom: isMobile ? -22 : -34,
            height: isMobile ? 120 : 188,
            child: Image.asset('assets/shiba_young_adult_v2.png', fit: BoxFit.contain),
          ),
        ],
      ),
    );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1080),
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, isMobile ? 20 : 50, 20, 0),
          child: isMobile
              ? Column(children: [text, const SizedBox(height: 30), SizedBox(width: 340, child: visual)])
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(flex: 11, child: text),
                    const SizedBox(width: 30),
                    Expanded(flex: 9, child: visual),
                  ],
                ),
        ),
      ),
    );
  }

  // 2. Watch them grow: the 8 life stages.
  Widget _growStrip(bool isMobile) {
    const stages = [
      ('Baby', 'shiba_baby'),
      ('Toddler', 'shiba_toddler'),
      ('Puppy', 'shiba_puppy'),
      ('Child', 'shiba_child'),
      ('Teen', 'shiba_teen'),
      ('Young adult', 'shiba_young_adult'),
      ('Adult', 'shiba_adult'),
      ('Old dog', 'old_dog'),
    ];
    final tiles = [
      for (final (label, file) in stages)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: isMobile ? 90 : 112,
                height: isMobile ? 90 : 112,
                child: Image.asset('assets/${file}_v2.png', fit: BoxFit.contain),
              ),
              const SizedBox(height: 6),
              Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: _isDark ? kGold : kGold.shade800)),
            ],
          ),
        ),
    ];
    return Column(
      children: [
        _heading('Watch them grow', 'Your Shiba grows up through 8 life stages, from a sleepy baby to a wise old dog.'),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(mainAxisSize: MainAxisSize.min, children: tiles),
        ),
      ],
    );
  }

  // 3. How it works: 3 gold steps.
  Widget _howItWorks(bool isMobile) {
    const steps = [
      (Icons.favorite, '1. Adopt your pup', 'Sign up free, choose a name, and meet your baby Shiba.'),
      (Icons.sports_tennis, '2. Care and play', 'Feed, play fetch, go on walks, collect collars and watch it grow.'),
      (Icons.photo_camera_outlined, '3. Share and collect', 'Post your real dog in The Book Of Dog and collect GPAWS loyalty points.'),
    ];
    return Column(
      children: [
        _heading('How it works', 'Three simple steps. No deposits, nothing to pay.'),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 20,
          runSpacing: 20,
          children: [
            for (final (icon, title, body) in steps)
              Container(
                width: isMobile ? double.infinity : 320,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: kGold.withValues(alpha: 0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: kGold.withValues(alpha: 0.18),
                      child: Icon(icon, color: kGold),
                    ),
                    const SizedBox(height: 14),
                    Text(title,
                        style: TextStyle(
                            fontFamily: 'Outfit', fontSize: 20, fontWeight: FontWeight.w700, color: _text)),
                    const SizedBox(height: 6),
                    Text(body, style: TextStyle(fontSize: 15, color: _soft, height: 1.4)),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  // 4. Fresh from The Book Of Dog: the latest real dog photos (public).
  Widget _freshFromBookOfDog(bool isMobile) {
    final query = FirebaseFirestore.instance
        .collection('dogbook_posts')
        .where('hidden', isEqualTo: false)
        .orderBy('created_at', descending: true)
        .limit(24);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snap) {
        final withPhotos = (snap.data?.docs ?? const [])
            .where((d) => (d.data()['image_url'] ?? '').toString().isNotEmpty)
            .take(isMobile ? 4 : 6)
            .toList();
        if (withPhotos.isEmpty) return const SizedBox.shrink();
        final size = isMobile ? 150.0 : 160.0;
        return Column(
          children: [
            _heading('Fresh from The Book Of Dog', 'Real dogs shared by real dog lovers. Come and say hello.'),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final d in withPhotos)
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => context.go('/book-of-dog/post/${d.id}'),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        width: size,
                        height: size,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              d.data()['image_url'].toString(),
                              fit: BoxFit.cover,
                              webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                              errorBuilder: (c, e, s) => const ColoredBox(color: Colors.black12),
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(10, 16, 10, 8),
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [Colors.transparent, Colors.black87],
                                  ),
                                ),
                                child: Text(
                                  (d.data()['dog_name'] ?? '').toString(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            TextButton.icon(
              onPressed: _browseBookOfDog,
              icon: const Icon(Icons.arrow_forward, color: kGold),
              label: Text('See more dogs', style: TextStyle(color: _isDark ? kGold : kGold.shade800, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // 5. GPAWS teaser.
  Widget _gpawsTeaser(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [kGold.shade600, kGold.shade800]),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: kGold.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: Flex(
        direction: isMobile ? Axis.vertical : Axis.horizontal,
        children: [
          // Dark badge behind the gold paw so it stands out on the gold banner.
          Container(
            width: 112,
            height: 112,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1508),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.85), width: 3),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 4))],
            ),
            child: Image.asset('assets/gpaw.png', width: 74, height: 74),
          ),
          SizedBox(width: isMobile ? 0 : 24, height: isMobile ? 16 : 0),
          Flexible(
            child: Column(
              crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
              children: [
                Text('Spot the golden paws',
                    textAlign: isMobile ? TextAlign.center : TextAlign.left,
                    style: const TextStyle(
                        fontFamily: 'Outfit', fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 8),
                Text(
                  'Golden paws peek out around Golden Paw while you play. Tap them to collect GPAWS, our loyalty points for being part of the pack. Your Shiba might even dig one up!',
                  textAlign: isMobile ? TextAlign.center : TextAlign.left,
                  style: const TextStyle(fontSize: 16, color: Colors.white, height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 6. Trust: reviews and four simple promises.
  Widget _trust(bool isMobile) {
    const promises = [
      (Icons.money_off, 'Free to play', 'No card, no deposits, nothing to buy.'),
      (Icons.verified_user_outlined, 'Private', 'We never sell your data. Cookies only if you agree.'),
      (Icons.shield_outlined, 'Safe and kind', 'Dogs only, with reporting and moderation.'),
      (Icons.flag_outlined, 'Made in the UK', 'By a small, dog-mad team who read every message.'),
    ];
    return Column(
      children: [
        _heading('Loved by dog lovers', 'A small, friendly community, and growing.'),
        const TrustpilotWidget(),
        const SizedBox(height: 26),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final (icon, title, body) in promises)
              SizedBox(
                width: isMobile ? double.infinity : 240,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, color: kGold, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _text)),
                          const SizedBox(height: 2),
                          Text(body, style: TextStyle(fontSize: 14, color: _soft, height: 1.35)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  // More from Golden Paw: website pages that open in the browser.
  Widget _moreFromGoldenPaw(bool isMobile) {
    const extras = [
      (Icons.health_and_safety, 'Dog Care Guide', 'Feeding, walks, grooming, foods to avoid and when to call the vet.', 'https://goldenpaw.dog/dog-care/', 'Read the guide'),
      (Icons.storefront, 'Golden Paw Shop', 'Printable dog-care planner, Dog Walk Bingo and kits for dog businesses.', 'https://goldenpaw.dog/shop/', 'Visit the shop'),
      (Icons.movie_filter, 'Animation Tool', 'Our free tool that turns videos into game animations. It brings the Shiba to life.', 'https://goldenpaw.dog/studios/animation/', 'Try it free'),
    ];
    return Column(
      children: [
        _heading('More from Golden Paw', 'Free guides and handy downloads for dog lovers.'),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final (icon, title, body, url, cta) in extras)
              SizedBox(
                width: isMobile ? double.infinity : 320,
                child: Material(
                  color: _card,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: kGold.withValues(alpha: 0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(icon, color: kGold, size: 30),
                          const SizedBox(height: 10),
                          Text(title,
                              style: TextStyle(
                                  fontFamily: 'Outfit', fontSize: 20, fontWeight: FontWeight.w700, color: _text)),
                          const SizedBox(height: 6),
                          Text(body, style: TextStyle(fontSize: 15, color: _soft, height: 1.4)),
                          const SizedBox(height: 12),
                          Text('$cta →',
                              style: const TextStyle(color: kGold, fontWeight: FontWeight.bold, fontSize: 15)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  // 7. FAQ.
  Widget _faq() {
    const faqs = [
      ('Is Golden Paw free?', 'Yes. Signing up, raising your Shiba and using The Book Of Dog are all free. There are no deposits.'),
      ('What are GPAWS?', 'GPAWS are our loyalty points. Golden paws appear around the app (up to 5 an hour) and you tap them to collect. They have no cash value.'),
      ('Do I need to know anything about crypto?', 'No. Golden Paw is a virtual pet game and a dog-lover community first. Some optional extras for players aged 18+ involve small Dogecoin rewards, but they are entertainment, not an investment, and you never need to deposit anything.'),
      ('Who can join?', 'Golden Paw is for adults aged 18 and over.'),
      ('Is my data safe?', 'We only collect what we need to run your account, we never sell your data, and we only use analytics or advertising cookies if you agree. You can ask us to delete your data at any time.'),
    ];
    return Column(
      children: [
        _heading('Questions?', 'The short answers.'),
        Container(
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: kGold.withValues(alpha: 0.4)),
          ),
          child: Column(
            children: [
              for (final (q, a) in faqs)
                Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    iconColor: kGold,
                    collapsedIconColor: kGold,
                    title: Text(q, style: TextStyle(fontWeight: FontWeight.w600, color: _text)),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(a, style: TextStyle(color: _soft, height: 1.45)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        FilledButton.icon(
          onPressed: _signUp,
          style: FilledButton.styleFrom(
            backgroundColor: kGold,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          icon: const Icon(Icons.pets),
          label: const Text('Adopt your Shiba (free)', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildAboutStudiosSection(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return ListenableBuilder(
      listenable: themeProvider,
      builder: (context, _) {
        final isDark = themeProvider.isDarkMode;
        final textColor = isDark ? Colors.white70 : Colors.black87;
        final subtextColor = isDark ? Colors.white60 : Colors.black54;

        return Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 880),
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: EdgeInsets.all(isMobile ? 24 : 36),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141926) : kGold.shade50.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDark ? kGold.withValues(alpha: 0.3) : kGold.shade300,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: kGold.withValues(alpha: isDark ? 0.08 : 0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: kGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: kGold.withValues(alpha: 0.4)),
                ),
                child: const Text(
                  "✦ ABOUT US ✦",
                  style: TextStyle(
                    color: kGold,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Who's behind Golden Paw?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isMobile ? 24 : 30,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Golden Paw is made by Golden Paw Studios, a small independent studio in the UK. We're dog lovers who make games, printables and websites.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isMobile ? 15 : 17,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Golden Paw started as a fun way to raise a virtual Shiba and collect small rewards along the way. It's free to play, with no deposits and no catches.\n\nWe're a real, small team, and we read every message and review you send. If something isn't right or you have an idea, tell us on our support page or email goldenpaw.dogeadmin@gmail.com.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isMobile ? 13 : 14,
                  color: subtextColor,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 10,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kGold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                      elevation: 4,
                    ),
                    onPressed: () => launchUrl(
                      Uri.parse('https://goldenpaw.dog/studios'),
                      mode: LaunchMode.externalApplication,
                    ),
                    icon: const Icon(Icons.public, size: 18),
                    label: const Text(
                      "Golden Paw Studios ↗",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? Colors.white : Colors.black87,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                      side: BorderSide(color: kGold.withValues(alpha: 0.6)),
                    ),
                    onPressed: () => launchUrl(
                      Uri.parse('https://goldenpaw.dog/articles/'),
                      mode: LaunchMode.externalApplication,
                    ),
                    icon: const Icon(Icons.article_outlined, size: 16, color: kGold),
                    label: const Text("Articles"),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? Colors.white : Colors.black87,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                      side: BorderSide(color: kGold.withValues(alpha: 0.6)),
                    ),
                    onPressed: () => launchUrl(
                      Uri.parse('https://goldenpaw.dog/support/'),
                      mode: LaunchMode.externalApplication,
                    ),
                    icon: const Icon(Icons.support_agent, size: 16, color: kGold),
                    label: const Text("Help & support"),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? Colors.white : Colors.black87,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                      side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade400),
                    ),
                    onPressed: () => launchUrl(
                      Uri.parse('https://x.com/ludogx101'),
                      mode: LaunchMode.externalApplication,
                    ),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text("X (@ludogx101)"),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? Colors.white : Colors.black87,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                      side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade400),
                    ),
                    onPressed: () => launchUrl(
                      Uri.parse('https://www.instagram.com/goldenpawdoge'),
                      mode: LaunchMode.externalApplication,
                    ),
                    icon: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        gradient: const RadialGradient(
                          center: Alignment(-0.8, 0.8),
                          radius: 1.2,
                          colors: [
                            Color(0xFFFFDC80),
                            Color(0xFFF77737),
                            Color(0xFFFD1D1D),
                            Color(0xFFE1306C),
                            Color(0xFF833AB4),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Center(
                        child: Icon(Icons.camera_alt, size: 12, color: Colors.white),
                      ),
                    ),
                    label: const Text("Instagram"),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? Colors.white : Colors.black87,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                      side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade400),
                    ),
                    onPressed: () => launchUrl(
                      Uri.parse('https://www.tiktok.com/@goldenpawstudios'),
                      mode: LaunchMode.externalApplication,
                    ),
                    icon: const Icon(Icons.tiktok, size: 16),
                    label: const Text("TikTok"),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? Colors.white : Colors.black87,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                      side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade400),
                    ),
                    onPressed: () => launchUrl(
                      Uri.parse('https://www.facebook.com/GoldenPawDogeHub'),
                      mode: LaunchMode.externalApplication,
                    ),
                    icon: const Icon(Icons.facebook, size: 16, color: Colors.blue),
                    label: const Text("Facebook"),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

