import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

// --- CONSTANTS FOR STYLE ---
const Color kPrimaryColor = Color(0xFF2E5BFF);
const Color kBgColor = Color(0xFFF7F9FC);
const Color kTextBlack = Color(0xFF1F2933);

class UniversityPage extends StatefulWidget {
  const UniversityPage({super.key});

  @override
  State<UniversityPage> createState() => _UniversityPageState();
}

class _UniversityPageState extends State<UniversityPage> {
  final CollectionReference _uniCollection = FirebaseFirestore.instance.collection('universities');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 193, 203, 235),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 193, 203, 235),
        elevation: 0,
        iconTheme: const IconThemeData(color: kTextBlack),
        title: const Text("Manage Universities", style: TextStyle(color: kTextBlack, fontWeight: FontWeight.bold)),
      ),
      
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: kPrimaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add University", style: TextStyle(color: Colors.white)),
        onPressed: () => _showUniDialog(context, null),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: _uniCollection.orderBy('uni_name').snapshots(), 
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No universities found. Add one!"));
          }

          final docs = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            separatorBuilder: (c, i) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final String docId = docs[index].id;
              
              String name = data['uni_name'] ?? 'Unknown';
              String acronym = data['acronym'] ?? '';
              String logoUrl = data['logo_url'] ?? '';
              
              // Kira berapa link fakulti ada (Optional, untuk display je)
              Map<String, dynamic> links = data['faculty_urls'] ?? {};
              int linkCount = links.length;

              return _UniversityCard(
                name: name,
                acronym: acronym,
                logoUrl: logoUrl,
                linkCount: linkCount, // Pass info ni
                onEdit: () => _showUniDialog(context, docs[index]),
                onDelete: () => _deleteUniversity(docId, name),
              );
            },
          );
        },
      ),
    );
  }

  // --- DIALOG UPGRADED (ADA FACULTY LINK) ---
  void _showUniDialog(BuildContext context, DocumentSnapshot? doc) {
    final bool isEditing = doc != null;
    final data = isEditing ? doc.data() as Map<String, dynamic> : null;

    final nameCtrl = TextEditingController(text: data?['uni_name'] ?? '');
    final acronymCtrl = TextEditingController(text: data?['acronym'] ?? '');
    final generalUrlCtrl = TextEditingController(text: data?['general_url'] ?? '');

    String currentLogoUrl = data?['logo_url'] ?? '';
    bool isUploading = false;

    // --- LOGIC UNTUK LIST FACULTY URLS ---
    // Kita guna List of Controllers untuk handle dynamic fields
    List<Map<String, TextEditingController>> facultyControllers = [];

    if (isEditing && data?['faculty_urls'] != null) {
      Map<String, dynamic> urls = data!['faculty_urls'];
      urls.forEach((key, value) {
        facultyControllers.add({
          'key': TextEditingController(text: key),   // e.g. "Accounting"
          'url': TextEditingController(text: value), // e.g. "https://..."
        });
      });
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            
            // Function upload image (sama macam sebelum ni)
            Future<void> pickAndUploadImage() async {
              final ImagePicker picker = ImagePicker();
              final XFile? image = await picker.pickImage(source: ImageSource.gallery);
              if (image != null) {
                setState(() => isUploading = true);
                try {
                  Uint8List fileBytes = await image.readAsBytes();
                  String fileName = DateTime.now().millisecondsSinceEpoch.toString();
                  Reference ref = FirebaseStorage.instance.ref().child('university_logos/$fileName');
                  await ref.putData(fileBytes);
                  String downloadUrl = await ref.getDownloadURL();
                  setState(() {
                    currentLogoUrl = downloadUrl;
                    isUploading = false;
                  });
                } catch (e) {
                  setState(() => isUploading = false);
                }
              }
            }

            return AlertDialog(
              title: Text(isEditing ? "Edit University" : "Add New University"),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. IMAGE UPLOAD
                      Center(
                        child: GestureDetector(
                          onTap: isUploading ? null : pickAndUploadImage,
                          child: Container(
                            height: 100, width: 100,
                            decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[300]!)),
                            child: isUploading
                                ? const Center(child: CircularProgressIndicator())
                                : currentLogoUrl.isNotEmpty
                                    ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(currentLogoUrl, fit: BoxFit.cover))
                                    : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.camera_alt, color: Colors.grey), Text("Logo", style: TextStyle(fontSize: 10))]),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 2. BASIC INFO
                      TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "University Name", isDense: true, border: OutlineInputBorder())),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: TextField(controller: acronymCtrl, decoration: const InputDecoration(labelText: "Acronym (e.g UM)", isDense: true, border: OutlineInputBorder()))),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(controller: generalUrlCtrl, decoration: const InputDecoration(labelText: "General Website URL", isDense: true, border: OutlineInputBorder())),
                      
                      const Divider(height: 30, thickness: 2),

                      // 3. FACULTY LINKS SECTION (DYNAMIC)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Faculty Links", style: TextStyle(fontWeight: FontWeight.bold)),
                          TextButton.icon(
                            icon: const Icon(Icons.add_circle, size: 16),
                            label: const Text("Add Link"),
                            onPressed: () {
                              setState(() {
                                // Tambah row kosong baru
                                facultyControllers.add({
                                  'key': TextEditingController(),
                                  'url': TextEditingController(),
                                });
                              });
                            },
                          )
                        ],
                      ),
                      
                      // Loop untuk keluarkan textfield bagi setiap fakulti
                      ...facultyControllers.asMap().entries.map((entry) {
                        int index = entry.key;
                        var controllers = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: controllers['key'],
                                  decoration: const InputDecoration(labelText: "Key (e.g Accounting)", isDense: true, border: OutlineInputBorder()),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                flex: 3,
                                child: TextField(
                                  controller: controllers['url'],
                                  decoration: const InputDecoration(labelText: "Faculty URL", isDense: true, border: OutlineInputBorder()),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                onPressed: () {
                                  setState(() {
                                    facultyControllers.removeAt(index);
                                  });
                                },
                              )
                            ],
                          ),
                        );
                      }).toList(),
                      
                      if (facultyControllers.isEmpty)
                         const Text("No specific faculty links added yet.", style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor),
                  onPressed: () async {
                    if (nameCtrl.text.isEmpty) return;
                    if (isUploading) return;

                    // A. Convert List Controller kepada Map untuk Firebase
                    Map<String, String> facultyMap = {};
                    for (var item in facultyControllers) {
                      String key = item['key']!.text.trim();
                      String url = item['url']!.text.trim();
                      if (key.isNotEmpty && url.isNotEmpty) {
                        facultyMap[key] = url;
                      }
                    }

                    // B. Prepare Data
                    final uniData = {
                      'uni_name': nameCtrl.text.trim(),
                      'acronym': acronymCtrl.text.trim().toUpperCase(),
                      'general_url': generalUrlCtrl.text.trim(), // Simpan general url
                      'faculty_urls': facultyMap, // Simpan map link fakulti
                      'logo_url': currentLogoUrl,
                      'updated_at': FieldValue.serverTimestamp(),
                    };

                    // C. Save
                    if (isEditing) {
                      await _uniCollection.doc(doc!.id).update(uniData);
                    } else {
                      await _uniCollection.add(uniData);
                    }

                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text("Save", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteUniversity(String docId, String name) {
    // ... (Sama macam code awak)
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: Text("Delete $name?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              await _uniCollection.doc(docId).delete();
              if (mounted) Navigator.pop(c);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// --- CARD UPGRADED ---
class _UniversityCard extends StatelessWidget {
  final String name;
  final String acronym;
  final String logoUrl;
  final int linkCount; // NEW
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _UniversityCard({
    required this.name,
    required this.acronym,
    required this.logoUrl,
    required this.linkCount,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48, height: 48,
          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey[100]),
          clipBehavior: Clip.antiAlias, 
          child: (logoUrl.isNotEmpty)
              ? Image.network(logoUrl, fit: BoxFit.cover, errorBuilder: (c,e,s) => Center(child: Text(acronym.isNotEmpty ? acronym[0] : "U")))
              : Center(child: Text(acronym.isNotEmpty ? acronym[0] : "U", style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimaryColor))),
        ),
        
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Wrap(
              spacing: 5,
              children: [
                if (acronym.isNotEmpty) 
                  _buildTag(acronym, Colors.blue),
                _buildTag("$linkCount Faculty Links", Colors.green), // Tunjuk ada berapa link
              ],
            )
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.blue), onPressed: onEdit),
            IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: onDelete),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color[50], borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    );
  }
}