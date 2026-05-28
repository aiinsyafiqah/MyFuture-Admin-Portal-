import 'package:admin_dashboard_myfuture/screens/admin_report/report.dart';
import 'package:admin_dashboard_myfuture/screens/career/manageCareer.dart';
import 'package:admin_dashboard_myfuture/screens/manage_users/manage_users.dart';
import 'package:admin_dashboard_myfuture/screens/scholarships/scholarships_dashboard.dart';
import 'package:admin_dashboard_myfuture/themes/colors.dart';
import 'package:flutter/material.dart';
import 'package:admin_dashboard_myfuture/screens/edit_profile/edit_profile_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Add this for date formatting if needed

// Define modern colors locally or in your theme file
const Color kPrimaryColor = Color(0xFF2E5BFF); // Intelly Blue
const Color kBgColor = Color(0xFFF7F9FC);      // Light Grey/Blue Background
const Color kTextBlack = Color(0xFF1F2933);
const Color kTextGrey = Color(0xFF7B8794);

class AdminHomepage extends StatelessWidget {
  const AdminHomepage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 193, 203, 235),
      drawer: _buildDrawer(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    SizedBox(width: 8),
                    Text(
                      "Have a good day, Ain!",
                      style: TextStyle(
                        fontSize: 24, 
                        fontWeight: FontWeight.bold,
                        color: kTextBlack,
                      ),
                    ),
                  ],
                ),
                
                // Right Side Actions
                Row(
                  children: [
                    // Notifications with expired scholarships badge (robust client-side check)
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('scholarships').snapshots(),
                      builder: (context, snapshot) {
                        final now = DateTime.now();
                        List<QueryDocumentSnapshot> expiredDocs = [];

                        if (snapshot.hasData) {
                          final docs = snapshot.data!.docs;
                          expiredDocs = docs.where((d) {
                            final data = d.data() as Map<String, dynamic>;
                            final dl = data['deadline'];
                            if (dl == null) return false;
                            try {
                              if (dl is Timestamp) return dl.toDate().isBefore(now);
                              if (dl is int) return DateTime.fromMillisecondsSinceEpoch(dl).isBefore(now);
                              if (dl is String) {
                                final parsed = DateTime.tryParse(dl);
                                if (parsed != null) return parsed.isBefore(now);
                                final asInt = int.tryParse(dl);
                                if (asInt != null) return DateTime.fromMillisecondsSinceEpoch(asInt).isBefore(now);
                              }
                            } catch (_) {}
                            return false;
                          }).toList();
                        }

                        final expiredCount = expiredDocs.length;

                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.notifications_none_rounded, color: kTextBlack),
                              onPressed: () => _showExpiredScholarshipsDialog(context, expiredDocs, errorMsg: snapshot.hasError ? snapshot.error.toString() : null),
                            ),

                            // Show small warning if stream has error
                            if (snapshot.hasError)
                              Positioned(
                                right: 0,
                                top: -2,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(color: Colors.orange, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1)),
                                  child: const Center(child: Text('!', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                                ),
                              ),

                            if (expiredCount > 0)
                              Positioned(
                                right: 4,
                                top: -2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
                                  child: Text(expiredCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                              )
                          ],
                        );
                      },
                    ),

                    const SizedBox(width: 8),
                    // Profile avatar updates live from FirebaseAuth user profile
                    StreamBuilder<User?>(
                      stream: FirebaseAuth.instance.userChanges(),
                      builder: (context, userSnap) {
                        final user = userSnap.data;
                        final photo = user?.photoURL;

                        return GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfilePage())),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 5)],
                            ),
                            child: CircleAvatar(
                              backgroundColor: Colors.white,
                              radius: 18,
                              backgroundImage: photo != null ? NetworkImage(photo) : null,
                              child: photo == null ? const Icon(Icons.person, size: 22, color: kTextGrey) : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                )
              ],
            ),
            const SizedBox(height: 24),
            // ----------------------------------------
            const Text(
              "Overview",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kTextBlack,
                letterSpacing: -0.5,),
            ),
            const SizedBox(height: 16),

            // --- SECTION 1: LIVE STATS GRID ---
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 3.3,
              children: [
                _FirestoreStatCard(
                  collectionName: 'users',
                  title: "Total Students",
                  icon: Icons.people_alt_rounded,
                  accentColor: const Color(0xFF2E5BFF),
                  customQuery: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'student'),// Blue
                ),
                _FirestoreStatCard(
                  collectionName: 'career_lists',
                  title: "Active Careers",
                  icon: Icons.work_rounded,
                  accentColor: Color(0xFF00C48C), // Green
                ),
                _FirestoreStatCard(
                  collectionName: 'scholarships',
                  title: "Scholarships",
                  icon: Icons.monetization_on_rounded,
                  accentColor: Color(0xFFFFC542), // Orange/Yellow
                ),
                _FirestoreStatCard(
                  collectionName: 'universities',
                  title: "Universities",
                  icon: Icons.school_rounded,
                  accentColor: Color(0xFFFF3D71), // Pink/Red
                ),
              ],
            ),

            const SizedBox(height: 32),
            
            // --- SECTION 2: STUDENT REGISTRATION LIST (NEW) ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Recent Registrations",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextBlack),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to full user list if you have one
                    Navigator.push(context, MaterialPageRoute(builder: (c) => const ManageUsersPage()));
                  },
                  child: const Text("View All", style: TextStyle(color: kPrimaryColor)),
                )
              ],
            ),
            const SizedBox(height: 10),
        
            // User List Container
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: StreamBuilder<QuerySnapshot>(
                // TIPS: Tambah .orderBy('createdAt', descending: true) jika anda ada field tarikh
                // supaya user paling baru daftar duduk paling atas.
                stream: FirebaseFirestore.instance.collection('users').limit(5).snapshots(), 
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Center(child: Text("No students registered yet.")),
                    );
                  }

                  final users = snapshot.data!.docs;

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: users.length,
                    separatorBuilder: (c, i) => Divider(height: 1, color: Colors.grey[100]),
                    itemBuilder: (context, index) {
                      final userData = users[index].data() as Map<String, dynamic>;
                      String email = userData['email'] ?? '';

                      // Skip Admin
                      if (email == 'admin123@gmail.com') {
                        return const SizedBox.shrink(); 
                      }

                      String name = userData['name'] ?? 'Unknown User';
                      
                      // --- LOGIC CHECK VERIFIED ---
                      // Pastikan dalam Firestore field dia 'isVerified' (boolean)
                      bool isVerified = userData['isVerified'] ?? false; 

                      // Set Warna & Text berdasarkan status
                      Color statusColor = isVerified ? const Color(0xFF00C48C) : const Color(0xFFFF3D71); // Hijau vs Merah
                      Color statusBg = isVerified ? const Color(0xFF00C48C).withOpacity(0.1) : const Color(0xFFFF3D71).withOpacity(0.1);
                      String statusLabel = isVerified ? "Verified" : "Unverified";
                      IconData statusIcon = isVerified ? Icons.verified_rounded : Icons.pending_actions_rounded;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: CircleAvatar(
                          backgroundColor: kPrimaryColor.withOpacity(0.1),
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : "?",
                            style: const TextStyle(
                              color: kPrimaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text(email, style: const TextStyle(fontSize: 12, color: kTextGrey)),
                        
                        // --- VISUAL STATUS DI SEBELAH KANAN ---
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: statusColor.withOpacity(0.2))
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon, size: 14, color: statusColor),
                              const SizedBox(width: 6),
                              Text(
                                statusLabel,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- DRAWER (Unchanged) ---
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
            ),
            currentAccountPicture: Container(
              decoration: BoxDecoration(
                color: kPrimaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.admin_panel_settings, color: kPrimaryColor, size: 30),
            ),
            accountName: const Text("Administrator", style: TextStyle(color: kTextBlack, fontWeight: FontWeight.bold)),
            accountEmail: const Text("admin@myfuture.com", style: TextStyle(color: kTextGrey)),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              children: [
                _drawerItem(Icons.dashboard_rounded, "Dashboard", context, isActive: true),
                _drawerItem(Icons.people_outline_rounded, "Manage Users", context),
                _drawerItem(Icons.work_outline_rounded, "Careers & Pathways", context),
                _drawerItem(Icons.school_outlined, "Universities", context),
                const Divider(height: 30, thickness: 1, indent: 20, endIndent: 20),
                _drawerItem(Icons.psychology_outlined, "Assessments", context),
                _drawerItem(Icons.analytics_outlined, "Reports", context),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text("Logout", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
            onTap: () {},
          )
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, BuildContext context, {VoidCallback? onTap, bool isActive = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: isActive ? BoxDecoration(
        color: kPrimaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ) : null,
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        dense: true,
        leading: Icon(icon, color: isActive ? kPrimaryColor : kTextGrey, size: 22),
        title: Text(title, style: TextStyle(
          fontWeight: isActive ? FontWeight.bold : FontWeight.w500, 
          fontSize: 14,
          color: isActive ? kPrimaryColor : kTextBlack,
        )),
        onTap: onTap ?? () => Navigator.pop(context),
      ),
    );
  }
}

// --- STAT CARD (Unchanged) ---
class _FirestoreStatCard extends StatelessWidget {
  final String collectionName;
  final String title;
  final IconData icon;
  final Color accentColor;
  final Query? customQuery;

  const _FirestoreStatCard({
    required this.collectionName,
    required this.title,
    required this.icon,
    required this.accentColor,
    this.customQuery,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: (customQuery ?? FirebaseFirestore.instance.collection(collectionName)).snapshots(),
      builder: (context, snapshot) {
        String countText = "..."; 
        if (snapshot.hasData) {
          countText = snapshot.data!.docs.length.toString();
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: kTextGrey,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 16, color: accentColor),
                  ),
                ],
              ),
              Text(
                countText,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: kTextBlack,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Show dialog listing expired scholarships with delete actions
void _showExpiredScholarshipsDialog(BuildContext context, List<QueryDocumentSnapshot> expiredDocs, {String? errorMsg}) {
  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Text('❗️Reminder : Expired Scholarships ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red
              ),),
            ),
            
            content: SizedBox(
              width: double.maxFinite,
              child: errorMsg != null
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Error fetching scholarships: $errorMsg', style: const TextStyle(color: Colors.orange)),
                        const SizedBox(height: 12),
                        expiredDocs.isEmpty
                          ? const Text('No expired scholarships.')
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: expiredDocs.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final doc = expiredDocs[index];
                                final data = doc.data() as Map<String, dynamic>;
                                String title = data['title'] ?? 'Untitled';
                                String deadlineStr = 'No Deadline';
                                final dl = data['deadline'];
                                if (dl != null) {
                                  try {
                                    DateTime d = DateTime.now();
                                    if (dl is Timestamp) d = dl.toDate();
                                    else if (dl is int) d = DateTime.fromMillisecondsSinceEpoch(dl);
                                    else if (dl is String) {
                                      d = DateTime.tryParse(dl) ?? DateTime.fromMillisecondsSinceEpoch(int.parse(dl));
                                    }
                                    deadlineStr = DateFormat('dd MMM yyyy').format(d);
                                  } catch (_) {}
                                }

                                return ListTile(
                                  title: Text(title),
                                  subtitle: Text('Due: $deadlineStr'),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () async {
                                      await FirebaseFirestore.instance.collection('scholarships').doc(doc.id).delete();
                                      setState(() => expiredDocs.removeAt(index));
                                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Deleted $title')));
                                    },
                                  ),
                                );
                              },
                            ),
                      ],
                    )
                  : expiredDocs.isEmpty
                      ? const Text('No expired scholarships.')
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: expiredDocs.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final doc = expiredDocs[index];
                            final data = doc.data() as Map<String, dynamic>;
                            String title = data['title'] ?? 'Untitled';
                            String deadlineStr = 'No Deadline';
                            final dl = data['deadline'];
                            if (dl != null) {
                              try {
                                DateTime d = DateTime.now();
                                if (dl is Timestamp) d = dl.toDate();
                                else if (dl is int) d = DateTime.fromMillisecondsSinceEpoch(dl);
                                else if (dl is String) {
                                  d = DateTime.tryParse(dl) ?? DateTime.fromMillisecondsSinceEpoch(int.parse(dl));
                                }
                                deadlineStr = DateFormat('dd MMM yyyy').format(d);
                              } catch (_) {}
                            }

                            return ListTile(
                              title: Text(title),
                              subtitle: Text('Due: $deadlineStr'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  await FirebaseFirestore.instance.collection('scholarships').doc(doc.id).delete();
                                  setState(() => expiredDocs.removeAt(index));
                                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Deleted $title')));
                                },
                              ),
                            );
                          },
                        ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
              TextButton(
                onPressed: () async {
                  // Bulk delete
                  final copy = List<QueryDocumentSnapshot>.from(expiredDocs);
                  for (final d in copy) {
                    await FirebaseFirestore.instance.collection('scholarships').doc(d.id).delete();
                  }
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Delete All', style: TextStyle(color: Colors.red)),
              ),
            ],
          );
        },
      );
    },
  );
}