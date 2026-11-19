import 'package:flutter/material.dart';

import '../../widgets/widgets.dart';
import 'package:gp_faucet/src/brand_colors.dart';

/// The house rules for The Book Of Dog, and how reporting works.
class BookOfDogRulesPage extends StatelessWidget {
  const BookOfDogRulesPage({super.key});

  static const _rules = <(String, String)>[
    ('Dogs only', 'Share photos of dogs. Your own dog is best. People can be in the photo, but the dog is the star.'),
    ('Be kind', 'No insults, bullying, hate or threats, in posts or comments.'),
    ('Keep it safe', 'Nothing violent, sexual, cruel to animals, or illegal. No photos of children without a parent or guardian agreeing.'),
    ('Keep private things private', "Don't share addresses, phone numbers or anything that shows where someone lives. We remove location data from photos automatically."),
    ('No selling or spam', 'No links, adverts, crypto promotions or puppy sales.'),
    ('Only share what you may share', 'Only post photos you took or have permission to use.'),
  ];

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: const GlobalAppBar(showBackArrow: true),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Row(
                children: [
                  Icon(Icons.pets, color: kGold, size: 28),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text('Book Of Dog rules',
                        style: TextStyle(fontFamily: 'Outfit', fontSize: 24, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'The Book Of Dog is a friendly place for dog lovers aged 18 and over. '
                'To keep it that way:',
                style: TextStyle(fontSize: 15, height: 1.4),
              ),
              const SizedBox(height: 12),
              for (final (title, body) in _rules)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.check_circle_outline, color: kGold),
                  title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(body, style: const TextStyle(height: 1.35)),
                ),
              const SizedBox(height: 16),
              const Text('If you see something wrong',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text(
                'Tap ⋮ on any post or comment and choose Report. We review every report. '
                'If three different people report something, it is hidden straight away until we have looked at it.\n\n'
                'You can also choose "Hide posts from…" to stop seeing someone. They are not told.\n\n'
                'We remove anything that breaks these rules, and accounts that break them can be stopped from posting. '
                'To ask about a decision or report something urgent, email goldenpaw.dogeadmin@gmail.com.',
                style: TextStyle(fontSize: 15, height: 1.4),
              ),
              const SizedBox(height: 16),
              const Text('Your posts',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text(
                'Anyone can see posts in The Book Of Dog, including people who are not signed in. '
                'You can delete your own posts and comments at any time from the ⋮ menu.',
                style: TextStyle(fontSize: 15, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
