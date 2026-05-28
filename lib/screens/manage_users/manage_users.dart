import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart'; 

class ManageUsersPage extends StatefulWidget {
  const ManageUsersPage({super.key});

  @override
  State<ManageUsersPage> createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  String _searchQuery = "";
  String _selectedFilter = "All"; 

  // --- LOGIC HANTAR EMAIL REMINDER ---
  Future<void> _sendVerificationReminder(String email, String name) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': 'Action Required: Verify your MyFuture Account',
        'body': 'Hi $name,\n\nWe noticed your account is still pending verification. Please verify your email to access all features.\n\nThank you,\nMyFuture Admin'
      },
    );

    try {
      if (!await launchUrl(emailLaunchUri)) {
        throw 'Could not launch';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open email app. Please verify manually.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text("Manage Students", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // --- BAHAGIAN 1: SEARCH & FILTER ---
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: "Search by email or name...",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                  ),
                  onChanged: (val) {
                    setState(() => _searchQuery = val.toLowerCase());
                  },
                ),
                const SizedBox(height: 15),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip("All"),
                      _buildFilterChip("Active"),
                      _buildFilterChip("Pending"),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // --- BAHAGIAN 2: USER LIST ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // ⚠️ PEMBETULAN 1: Buang .orderBy di sini supaya user lama tak hilang
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                // Ambil semua dokumen
                List<QueryDocumentSnapshot> docs = snapshot.data!.docs;
                
                // --- FILTERING LOGIC ---
                final filteredDocs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  String email = (data['email'] ?? '').toLowerCase();
                  String name = (data['name'] ?? '').toLowerCase();
                  
                  // 1. Skip Admin
                  if (email.contains('admin')) return false;

                  // 2. Search Logic
                  bool matchesSearch = email.contains(_searchQuery) || name.contains(_searchQuery);
                  if (!matchesSearch) return false;

                  // 3. Status Logic
                  // ⚠️ PEMBETULAN 2: Kita standardize. Kalau tiada field, anggap FALSE (Pending)
                  bool isVerified = data['isVerified'] ?? false; 
                  
                  // 4. Apply Filter Tab
                  if (_selectedFilter == "Active") return isVerified;
                  if (_selectedFilter == "Pending") return !isVerified;

                  return true; 
                }).toList();

                // ⚠️ PEMBETULAN 3: Sorting Manual (Coding)
                // Kita sort di sini supaya user yang tiada tarikh tetap muncul (di bawah)
                filteredDocs.sort((a, b) {
                  var dataA = a.data() as Map<String, dynamic>;
                  var dataB = b.data() as Map<String, dynamic>;
                  
                  // Kalau tiada tarikh, letak tarikh lama (0)
                  Timestamp timeA = dataA['created_at'] ?? Timestamp.fromMillisecondsSinceEpoch(0);
                  Timestamp timeB = dataB['created_at'] ?? Timestamp.fromMillisecondsSinceEpoch(0);
                  
                  // Descending (Terbaru di atas)
                  return timeB.compareTo(timeA);
                });

                if (filteredDocs.isEmpty) {
                  return const Center(child: Text("No students found matching criteria."));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredDocs.length,
                  separatorBuilder: (c, i) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final data = filteredDocs[index].data() as Map<String, dynamic>;
                    
                    String name = data['name'] ?? 'Unknown';
                    String email = data['email'] ?? '-';
                    
                    // Logic Data Selamat
                    bool isVerified = data['isVerified'] ?? false;
                    Timestamp? createdAt = data['created_at']; // Boleh jadi null
                    
                    // Logic Visual Status
                    Color statusColor = isVerified ? const Color(0xFF00C48C) : const Color(0xFFFF3D71);
                    Color statusBg = isVerified ? const Color(0xFF00C48C).withOpacity(0.1) : const Color(0xFFFF3D71).withOpacity(0.1);
                    String statusText = isVerified ? "Active" : "Pending";

                    // Logic: Notify Button (Jika Pending > 7 hari ATAU User lama tiada tarikh)
                    bool showNotifyBtn = false;
                    if (!isVerified) {
                      if (createdAt == null) {
                         // Kalau user lama (tiada tarikh) dan tak verified, memang kena notify
                         showNotifyBtn = true;
                      } else {
                         // Kalau user baru, check kalau dah lebih 7 hari
                         final daysSinceReg = DateTime.now().difference(createdAt.toDate()).inDays;
                         if (daysSinceReg > 7) showNotifyBtn = true;
                      }
                    }

                    // Format Date String
                    String dateString = createdAt != null 
                        ? DateFormat('dd MMM yyyy').format(createdAt.toDate()) 
                        : "Old Account";

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: isVerified ? Colors.green[50] : Colors.red[50],
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : "?",
                            style: TextStyle(fontWeight: FontWeight.bold, color: statusColor),
                          ),
                        ),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(email),
                            const SizedBox(height: 4),
                            Text(
                              "Registered: $dateString",
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          ],
                        ),
                        trailing: showNotifyBtn
                            ? ElevatedButton.icon(
                                onPressed: () => _sendVerificationReminder(email, name),
                                icon: const Icon(Icons.mail, size: 14),
                                label: const Text("Remind"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  foregroundColor: Colors.white,
                                  textStyle: const TextStyle(fontSize: 12),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                ),
                              )
                            : Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusBg,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: statusColor.withOpacity(0.2))
                                ),
                                child: Text(
                                  statusText,
                                  style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.bold,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    bool isSelected = _selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (bool selected) {
          setState(() => _selectedFilter = label);
        },
        selectedColor: Colors.blue[100],
        checkmarkColor: Colors.blue,
        labelStyle: TextStyle(
          color: isSelected ? Colors.blue[900] : Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}