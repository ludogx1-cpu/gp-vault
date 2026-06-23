import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../src/theme_provider.dart';
import '../widgets/widgets.dart';

class BlogPage extends StatelessWidget {
  const BlogPage({super.key});

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
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Golden Paw Blog",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // StreamBuilder to fetch posts from Firestore dynamically
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('blog_posts')
                          .orderBy('created_at', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text('Error loading blog posts: \${snapshot.error}',
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

                        return ListView.builder(
                          itemCount: posts.length,
                          itemBuilder: (context, index) {
                            final post = posts[index].data() as Map<String, dynamic>;
                            final content = post['content'] ?? '';
                            
                            return BlogPostWidget(
                              content: content,
                              isDark: isDark,
                              titleColor: titleColor,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class BlogPostWidget extends StatelessWidget {
  final String content;
  final bool isDark;
  final Color titleColor;

  const BlogPostWidget({
    super.key,
    required this.content,
    required this.isDark,
    required this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white70 : Colors.black87;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? themeProvider.darkGreyBoxColor : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isDark ? themeProvider.darkGreyBorder : Colors.grey.shade300,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: MarkdownBody(
        data: content,
        selectable: true,
        styleSheet: MarkdownStyleSheet(
          h2: TextStyle(color: titleColor, fontWeight: FontWeight.bold, fontSize: 24, height: 1.5),
          h3: TextStyle(color: titleColor, fontWeight: FontWeight.bold, fontSize: 20, height: 1.5),
          p: TextStyle(color: textColor, fontSize: 16, height: 1.6),
          listBullet: TextStyle(color: textColor, fontSize: 16, height: 1.6),
          strong: TextStyle(color: titleColor, fontWeight: FontWeight.bold),
          a: const TextStyle(color: Colors.amber, decoration: TextDecoration.underline),
        ),
        onTapLink: (text, href, title) {
          if (href != null) {
            launchUrl(Uri.parse(href));
          }
        },
      ),
    );
  }
}
