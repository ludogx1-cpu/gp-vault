import '../widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../src/theme_provider.dart';
import '../widgets/global_app_bar.dart';
import '../widgets/page_with_footer.dart';
import '../widgets/newsletter_subscribe_widget.dart';
import '../widgets/widgets.dart';

class BlogPage extends StatefulWidget {
  const BlogPage({super.key});

  @override
  State<BlogPage> createState() => _BlogPageState();
}

class _BlogPageState extends State<BlogPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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

  void _showSubmissionDialog(BuildContext context, String category) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final isDark = themeProvider.isDarkMode;
    final titleColor = isDark ? Colors.white : Colors.black87;

    showDialog(
      context: context,
      builder: (context) {
        bool isSubmitting = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: isDark ? themeProvider.darkGreyBoxColor : Colors.white,
              title: Text("Submit to ${category == 'user_post' ? 'User Posts' : 'Suggestions'}", style: TextStyle(color: titleColor)),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 600,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleController,
                        style: TextStyle(color: titleColor),
                        decoration: InputDecoration(
                          labelText: "Title",
                          labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: contentController,
                        style: TextStyle(color: titleColor),
                        maxLines: 8,
                        decoration: InputDecoration(
                          labelText: "Content (Markdown supported)",
                          labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                          alignLabelWithHint: true,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Note: Your submission will be reviewed by an admin before it goes live.",
                        style: TextStyle(color: Colors.amber.shade700, fontSize: 12),
                      )
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (titleController.text.trim().isEmpty || contentController.text.trim().isEmpty) return;
                          setState(() => isSubmitting = true);
                          try {
                            await FirebaseFirestore.instance.collection('blog_posts').add({
                              'topic': titleController.text.trim(),
                              'content': contentController.text.trim(),
                              'category': category,
                              'approved': false,
                              'likedBy': [],
                              'dislikedBy': [],
                              'created_at': FieldValue.serverTimestamp(),
                            });
                            if (context.mounted) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Submitted for review!")),
                              );
                            }
                          } catch (e) {
                            setState(() => isSubmitting = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                  child: isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("SUBMIT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          }
        );
      },
    );
  }

  Future<void> _toggleVote(String docId, String type, List currentList, List oppositeList, String collection) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("You must be logged in to vote.")));
      return;
    }
    
    final uid = user.uid;
    final docRef = FirebaseFirestore.instance.collection(collection).doc(docId);

    if (type == 'like') {
      if (currentList.contains(uid)) {
        await docRef.update({'likedBy': FieldValue.arrayRemove([uid])});
      } else {
        await docRef.update({
          'likedBy': FieldValue.arrayUnion([uid]),
          'dislikedBy': FieldValue.arrayRemove([uid])
        });
      }
    } else {
      if (currentList.contains(uid)) {
        await docRef.update({'dislikedBy': FieldValue.arrayRemove([uid])});
      } else {
        await docRef.update({
          'dislikedBy': FieldValue.arrayUnion([uid]),
          'likedBy': FieldValue.arrayRemove([uid])
        });
      }
    }
  }

  Widget _buildPostsList(bool isDark, Color titleColor, String collection, {String? categoryFilter, bool requiresApproval = false, String orderByField = 'created_at'}) {
    Query query = FirebaseFirestore.instance.collection(collection).orderBy(orderByField, descending: true);
    
    if (categoryFilter != null) {
      query = query.where('category', isEqualTo: categoryFilter);
    }
    if (requiresApproval) {
      query = query.where('approved', isEqualTo: true);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.amber));
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error loading posts. (Indexes may be building)', style: TextStyle(color: titleColor)));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text('No posts found in this section yet.',
                style: TextStyle(color: titleColor, fontSize: 18)),
          );
        }

        final posts = snapshot.data!.docs;

        return ListView.separated(
          padding: const EdgeInsets.all(15),
          physics: const BouncingScrollPhysics(),
          itemCount: posts.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final doc = posts[index];
            final post = doc.data() as Map<String, dynamic>;
            final content = post['content'] ?? (post['message'] ?? '');
            final topic = post['topic'] ?? (post['title'] ?? 'Untitled');
            final externalUrl = post['external_url'];
            final createdAt = post[orderByField];
            
            final likedBy = List<String>.from(post['likedBy'] ?? []);
            final dislikedBy = List<String>.from(post['dislikedBy'] ?? []);
            
            final user = FirebaseAuth.instance.currentUser;
            final uid = user?.uid;

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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            topic,
                            style: TextStyle(
                              color: titleColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (dateStr.isNotEmpty) ...[
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 12, color: Colors.amber),
                                const SizedBox(width: 5),
                                Text(
                                  dateStr,
                                  style: TextStyle(
                                    color: isDark ? Colors.white54 : Colors.black54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Votes
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(uid != null && likedBy.contains(uid) ? Icons.thumb_up : Icons.thumb_up_alt_outlined, 
                            color: uid != null && likedBy.contains(uid) ? Colors.green : Colors.grey, size: 18),
                          onPressed: () => _toggleVote(doc.id, 'like', likedBy, dislikedBy, collection),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 4),
                        Text("${likedBy.length}", style: TextStyle(color: titleColor, fontSize: 14)),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: Icon(uid != null && dislikedBy.contains(uid) ? Icons.thumb_down : Icons.thumb_down_alt_outlined, 
                            color: uid != null && dislikedBy.contains(uid) ? Colors.red : Colors.grey, size: 18),
                          onPressed: () => _toggleVote(doc.id, 'dislike', dislikedBy, likedBy, collection),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 4),
                        Text("${dislikedBy.length}", style: TextStyle(color: titleColor, fontSize: 14)),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
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
                      "Golden Paw Community & Blog",
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
                    TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      labelColor: Colors.amber,
                      unselectedLabelColor: isDark ? Colors.white54 : Colors.black54,
                      indicatorColor: Colors.amber,
                      tabs: const [
                        Tab(text: "Daily Blogs"),
                        Tab(text: "Newsletters"),
                        Tab(text: "Updates Board"),
                        Tab(text: "User Posts"),
                        Tab(text: "Suggestions"),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Container(
                      height: 500, // Fixed height to allow scrolling within the box
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black12 : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                      ),
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildPostsList(isDark, titleColor, 'blog_posts', categoryFilter: 'daily_blog', requiresApproval: true),
                          _buildPostsList(isDark, titleColor, 'blog_posts', categoryFilter: 'newsletter', requiresApproval: true),
                          _buildPostsList(isDark, titleColor, 'updates', orderByField: 'timestamp'), // Pulls directly from updates collection
                          Stack(
                            children: [
                              _buildPostsList(isDark, titleColor, 'blog_posts', categoryFilter: 'user_post', requiresApproval: true),
                              Positioned(
                                bottom: 15,
                                right: 15,
                                child: FloatingActionButton.extended(
                                  onPressed: () => _showSubmissionDialog(context, 'user_post'),
                                  backgroundColor: Colors.amber,
                                  icon: const Icon(Icons.edit, color: Colors.white),
                                  label: const Text("Write a Post", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              )
                            ],
                          ),
                          Stack(
                            children: [
                              _buildPostsList(isDark, titleColor, 'blog_posts', categoryFilter: 'suggestion', requiresApproval: true),
                              Positioned(
                                bottom: 15,
                                right: 15,
                                child: FloatingActionButton.extended(
                                  onPressed: () => _showSubmissionDialog(context, 'suggestion'),
                                  backgroundColor: Colors.amber,
                                  icon: const Icon(Icons.lightbulb, color: Colors.white),
                                  label: const Text("Submit Suggestion", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Bitcotasks300x100AdWidget(),
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

