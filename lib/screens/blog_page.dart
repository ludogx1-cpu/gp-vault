import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../src/theme_provider.dart';
import '../widgets/global_app_bar.dart';
import '../widgets/page_with_footer.dart';

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
                    const SizedBox(height: 10),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 15,
                      children: [
                        TextButton(onPressed: () {}, child: const Text("All Posts", style: TextStyle(color: Colors.amber))),
                        TextButton(onPressed: () {}, child: const Text("News", style: TextStyle(color: Colors.amber))),
                        TextButton(onPressed: () {}, child: const Text("Updates", style: TextStyle(color: Colors.amber))),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // StreamBuilder to fetch posts from Firestore dynamically
                    StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('blog_posts')
                            .orderBy('created_at', descending: true)
                            .limit(8)
                            .snapshots(),
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

                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 350,
                              childAspectRatio: 1.5,
                              crossAxisSpacing: 20,
                              mainAxisSpacing: 20,
                            ),
                            itemCount: posts.length,
                            itemBuilder: (context, index) {
                              final post = posts[index].data() as Map<String, dynamic>;
                              final content = post['content'] ?? '';
                              final topic = post['topic'] ?? 'Untitled Article';
                              final createdAt = post['created_at'];
                              
                              String dateStr = '';
                              if (createdAt != null && createdAt is Timestamp) {
                                final dt = createdAt.toDate();
                                dateStr = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
                              }

                              return InkWell(
                                onTap: () => _showArticleDialog(context, content, isDark, titleColor),
                                borderRadius: BorderRadius.circular(15),
                                child: Container(
                                  padding: const EdgeInsets.all(15),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.black26 : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(color: Colors.amber, width: 0.5),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        topic,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: titleColor,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const Spacer(),
                                      if (dateStr.isNotEmpty)
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
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
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
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
