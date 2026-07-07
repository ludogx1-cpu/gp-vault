import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../src/theme_provider.dart';
import '../widgets/global_app_bar.dart';
import '../widgets/page_with_footer.dart';
import '../widgets/newsletter_subscribe_widget.dart';

class BlogPage extends StatelessWidget {
  const BlogPage({super.key});

  void _showArticleDialog(BuildContext context, String content, bool isDark, Color titleColor) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: isDark ? themeProvider.darkGreyBoxColor : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Container(
            width: 800, // Max width for reading
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: Icon(Icons.close, color: titleColor),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: MarkdownBody(
                      data: content,
                      selectable: true,
                      styleSheet: MarkdownStyleSheet(
                        h2: TextStyle(color: titleColor, fontWeight: FontWeight.bold, fontSize: 24, height: 1.5),
                        h3: TextStyle(color: titleColor, fontWeight: FontWeight.bold, fontSize: 20, height: 1.5),
                        p: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 16, height: 1.6),
                        listBullet: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 16, height: 1.6),
                        strong: TextStyle(color: titleColor, fontWeight: FontWeight.bold),
                        a: const TextStyle(color: Colors.amber, decoration: TextDecoration.underline),
                      ),
                      onTapLink: (text, href, title) {
                        if (href != null) {
                          launchUrl(Uri.parse(href));
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GlobalAppBar(showBackArrow: true),
      body: PageWithFooter(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ListenableBuilder(
            listenable: themeProvider,
            builder: (context, _) {
              final isDark = themeProvider.isDarkMode;
              final titleColor = isDark ? Colors.white : Colors.black87;
              
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? themeProvider.darkGreyBoxColor : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? themeProvider.darkGreyBorder : Colors.grey.shade300,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      "Golden Paw Blog",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const NewsletterSubscribeWidget(),
                    const SizedBox(height: 30),
                    // StreamBuilder to fetch posts from Firestore dynamically
                    StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('blog_posts')
                            .orderBy('created_at', descending: true)
                            .snapshots(), // Removed limit(8) so they can all load and scroll
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator(color: Colors.amber));
                          }

                          if (snapshot.hasError) {
                            return Center(
                              child: Text('Error loading blog posts: ${snapshot.error}',
                                  style: TextStyle(color: titleColor)),
                            );
                          }

                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return Center(
                              child: Text('No blog posts found yet.',
                                  style: TextStyle(color: titleColor, fontSize: 18)),
                            );
                          }

                          final posts = snapshot.data!.docs;

                          return Container(
                            height: 500, // Fixed height to allow scrolling within the box
                            decoration: BoxDecoration(
                              color: isDark ? Colors.black12 : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                            ),
                            child: ListView.separated(
                              padding: const EdgeInsets.all(15),
                              physics: const BouncingScrollPhysics(),
                              itemCount: posts.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final post = posts[index].data() as Map<String, dynamic>;
                                final content = post['content'] ?? '';
                                final topic = post['topic'] ?? 'Untitled Article';
                                final externalUrl = post['external_url'];
                                final createdAt = post['created_at'];
                                
                                String dateStr = '';
                                if (createdAt != null && createdAt is Timestamp) {
                                  final dt = createdAt.toDate();
                                  dateStr = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
                                }

                                return InkWell(
                                  onTap: () {
                                    if (externalUrl != null && externalUrl.toString().isNotEmpty) {
                                      launchUrl(Uri.parse(externalUrl.toString()));
                                    } else {
                                      _showArticleDialog(context, content, isDark, titleColor);
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.black26 : Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.amber, width: 0.5),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            topic,
                                            style: TextStyle(
                                              color: titleColor,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (dateStr.isNotEmpty) ...[
                                          const SizedBox(width: 15),
                                          const Icon(Icons.calendar_today, size: 14, color: Colors.amber),
                                          const SizedBox(width: 5),
                                          Text(
                                            dateStr,
                                            style: TextStyle(
                                              color: isDark ? Colors.white54 : Colors.black54,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
