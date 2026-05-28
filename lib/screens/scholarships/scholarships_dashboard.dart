import 'package:admin_dashboard_myfuture/screens/scholarships/add_scholarships.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; 


// --- CONSTANTS ---
const Color kPrimaryColor = Color(0xFF2E5BFF);
const Color kBgColor = Color(0xFFF7F9FC);
const Color kTextBlack = Color(0xFF1F2933);

class ScholarshipPage extends StatefulWidget {
  const ScholarshipPage({super.key});

  @override
  State<ScholarshipPage> createState() => _ScholarshipPageState();
}

class _ScholarshipPageState extends State<ScholarshipPage> {
  final CollectionReference _scholarshipCollection = FirebaseFirestore.instance.collection('scholarships');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 193, 203, 235),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 193, 203, 235),
        elevation: 0,
        iconTheme: const IconThemeData(color: kTextBlack),
        title: const Text("Manage Scholarships", style: TextStyle(color: kTextBlack, fontWeight: FontWeight.bold)),
      ),
      
      // BUTTON ADD: Sekarang link ke page "AddScholarshipPage"
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: kPrimaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add Scholarship", style: TextStyle(color: Colors.white)),
        onPressed: () {
          // Navigasi ke page Add Scholarship yang anda buat tadi
          // Pastikan nama class sama dengan file sebelum ini
          Navigator.push(
            context, 
            MaterialPageRoute(builder: (context) => const AddScholarshipPage()) // <--- ERROR MUNGKIN DISINI JIKA TAK IMPORT
          );
        },
      ),

      // LIST OF SCHOLARSHIPS
      body: StreamBuilder<QuerySnapshot>(
        stream: _scholarshipCollection.orderBy('createdAt', descending: true).snapshots(), 
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No scholarships found. Add one!"));
          }

          final docs = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            separatorBuilder: (c, i) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final String docId = docs[index].id;
              
              // --- MAPPING DATA BARU DI SINI ---
              String title = data['title'] ?? 'Untitled';
              String provider = data['provider'] ?? 'Unknown';
              String imageUrl = data['image_url'] ?? '';
              
              // PANGGIL FIELD BARU
              String category = data['category'] ?? '-';     // e.g. Full Scholarship
              String spmResult = data['spm_result'] ?? '-';  // e.g. Min 9A

              // Handle Date
              String deadlineStr = "No Deadline";
              if (data['deadline'] != null) {
                Timestamp t = data['deadline'];
                deadlineStr = DateFormat('dd MMM yyyy').format(t.toDate());
              }

              return _ScholarshipCard(
                title: title,
                provider: provider,
                category: category,     // <-- Pass data baru
                spmResult: spmResult,   // <-- Pass data baru
                deadline: deadlineStr,
                imageUrl: imageUrl,
                onDelete: () => _deleteScholarship(docId, title),
                onEdit: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => AddScholarshipPage(
                    scholarshipToEdit: docs[index],
                  )));
                },
              );
            },
          );
        },
      ),
    );
  }

  // --- DELETE FUNCTION ---
  void _deleteScholarship(String docId, String title) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: Text("Delete '$title'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              await _scholarshipCollection.doc(docId).delete();
              if (mounted) Navigator.pop(c);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// --- CUSTOM CARD WIDGET ---
class _ScholarshipCard extends StatelessWidget {
  final String title;
  final String provider;
  final String category;    // Ganti amount
  final String spmResult;   // Tambah result
  final String deadline;
  final String imageUrl;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _ScholarshipCard({
    required this.title,
    required this.provider,
    required this.category,
    required this.spmResult,
    required this.deadline,
    required this.imageUrl,
    required this.onDelete,
    required this. onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        
        // 1. GAMBAR
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey[100], 
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias, 
          child: (imageUrl.isNotEmpty)
              ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.school, color: kPrimaryColor)),
                )
              : const Center(child: Icon(Icons.school, color: kPrimaryColor)),
        ),
        
       title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(provider, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black54)),
            const SizedBox(height: 2),
            Text("$category • $spmResult", style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: deadline.contains("Open") ? Colors.blue[50] : Colors.orange[50], // Tukar warna ikut status
                borderRadius: BorderRadius.circular(4)
              ),
              child: Text(
                "Due: $deadline", 
                style: TextStyle(
                  fontSize: 11, 
                  fontWeight: FontWeight.bold, 
                  color: deadline.contains("Open") ? Colors.blue[800] : Colors.orange[800]
                )
              ),
            ),
          ],
        ),

        // 3. EDIT & DELETE BUTTON (BAHAGIAN UTAMA YANG BERUBAH)
        trailing: Row(
          mainAxisSize: MainAxisSize.min, // Penting supaya dia tak makan ruang
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue), // Icon Pensel
              onPressed: onEdit, // Trigger function edit
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red), // Icon Sampah
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}