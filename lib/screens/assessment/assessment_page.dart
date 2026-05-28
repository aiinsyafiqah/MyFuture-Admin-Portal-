import 'dart:typed_data';

import 'package:admin_dashboard_myfuture/themes/colors.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class AssessmentPage extends StatefulWidget {
  const AssessmentPage({super.key});

  @override
  State<AssessmentPage> createState() => _AssessmentPageState();
}

class _AssessmentPageState extends State<AssessmentPage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Kita ada 2 jenis kuiz
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 193, 203, 235),
        appBar: AppBar(
          title: const Text("Assessment Management", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor:const Color.fromARGB(255, 193, 203, 235),
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          bottom: const TabBar(
            labelColor: sideColor,
            unselectedLabelColor: textDark,
            indicatorColor: sideColor,
            tabs: [
              Tab(icon: Icon(Icons.psychology), text: "MBTI Questions"),
              Tab(icon: Icon(Icons.work), text: "Career Questions"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            MbtiManagementTab(),
            CareerManagementTab(),
          ],
        ),
      ),
    );
  }
}

// =========================================================
// TAB 1: PENGURUSAN SOALAN MBTI (COMPLEX LOGIC)
// =========================================================

class MbtiManagementTab extends StatefulWidget {
  const MbtiManagementTab({super.key});

  @override
  State<MbtiManagementTab> createState() => _MbtiManagementTabState();
}

class _MbtiManagementTabState extends State<MbtiManagementTab> {
  final CollectionReference mbtiCollection = FirebaseFirestore.instance.collection('quiz_questions');

  // Helper untuk paparkan label direction yang mudah difahami admin
  String getDirectionLabel(String dimension, int direction) {
    if (direction == 1) {
      // Logic: Positive Score (Value)
      if (dimension == 'EI') return "Favour: Extrovert (E)";
      if (dimension == 'SN') return "Favour: Sensing (S)";
      if (dimension == 'TF') return "Favour: Thinking (T)";
      if (dimension == 'JP') return "Favour: Judging (J)";
    } else {
      // Logic: Reverse Score (6 - Value)
      if (dimension == 'EI') return "Favour: Introvert (I)";
      if (dimension == 'SN') return "Favour: Intuition (N)";
      if (dimension == 'TF') return "Favour: Feeling (F)";
      if (dimension == 'JP') return "Favour: Perceiving (P)";
    }
    return "Unknown";
  }

  // --- DIALOG ADD/EDIT MBTI ---
  void _showMbtiDialog(BuildContext context, DocumentSnapshot? doc) {
    final bool isEditing = doc != null;
    final data = isEditing ? doc.data() as Map<String, dynamic> : null;

    final questionCtrl = TextEditingController(text: data?['text'] ?? '');
    
    // Default Values
    String selectedDimension = data?['dimension'] ?? 'EI';
    int selectedDirection = data?['direction'] ?? 1; // 1 = Positive, 0 = Negative

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isEditing ? "Edit MBTI Question" : "Add MBTI Question"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: questionCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: "Question Text", border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 15),
                    
                    // DROPDOWN 1: DIMENSION (EI, SN, TF, JP)
                    DropdownButtonFormField<String>(
                      value: selectedDimension,
                      decoration: const InputDecoration(labelText: "Dichotomy / Dimension", border: OutlineInputBorder()),
                      items: ['EI', 'SN', 'TF', 'JP'].map((dim) {
                        return DropdownMenuItem(value: dim, child: Text(dim));
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedDimension = val!;
                          selectedDirection = 1; // Reset direction bila tukar dimensi
                        });
                      },
                    ),
                    const SizedBox(height: 15),

                    // DROPDOWN 2: DIRECTION (Penentu Formula)
                    // Ini bahagian paling penting untuk formula awak
                    DropdownButtonFormField<int>(
                      value: selectedDirection,
                      decoration: const InputDecoration(labelText: "Scoring Logic", border: OutlineInputBorder()),
                      items: [
                        DropdownMenuItem(
                          value: 1, 
                          child: Text(getDirectionLabel(selectedDimension, 1))
                        ),
                        DropdownMenuItem(
                          value: 0, 
                          child: Text(getDirectionLabel(selectedDimension, 0))
                        ),
                      ],
                      onChanged: (val) => setState(() => selectedDirection = val!),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      selectedDirection == 1 
                      ? "Formula: Score = User Value (1-5)" 
                      : "Formula: Score = 6 - User Value",
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    )
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                // Cari function _showMbtiDialog dalam MbtiManagementTab
                // ...
                ElevatedButton(
                  onPressed: () async {
                    if (questionCtrl.text.isEmpty) return;

                    final newData = {
                      // ⚠️ BETULKAN DI SINI: Tukar 'question_text' jadi 'text'
                      'text': questionCtrl.text.trim(), 
                      'dimension': selectedDimension,
                      'direction': selectedDirection,
                      'index': DateTime.now().millisecondsSinceEpoch,
                    };
                // ...

                    if (isEditing) {
                      await mbtiCollection.doc(doc!.id).update(newData);
                    } else {
                      await mbtiCollection.add(newData);
                    }
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteQuestion(String id) {
    mbtiCollection.doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: () => _showMbtiDialog(context, null),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: mbtiCollection.orderBy('dimension').snapshots(), // Group by dimension
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text("No MBTI questions yet."));

          return ListView.separated(
            padding: const EdgeInsets.all(15),
            itemCount: docs.length,
            separatorBuilder: (c, i) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final String dim = data['dimension'] ?? 'EI';
              final int dir = data['direction'] ?? 1;

              return Card(
                elevation: 2,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue[50],
                    child: Text(dim, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  title: Text(data['text'] ?? 'No text'),
                  subtitle: Text(
                    "Logic: ${getDirectionLabel(dim, dir)}", 
                    style: TextStyle(color: dir == 1 ? Colors.green : Colors.orange),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showMbtiDialog(context, docs[index])),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteQuestion(docs[index].id)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// =========================================================
// TAB 2: PENGURUSAN CAREER (4 SOALAN: GAMBAR & KATEGORI BERBEZA)
// =========================================================

class CareerManagementTab extends StatefulWidget {
  const CareerManagementTab({super.key});

  @override
  State<CareerManagementTab> createState() => _CareerManagementTabState();
}

class _CareerManagementTabState extends State<CareerManagementTab> {
  final CollectionReference careerCollection = FirebaseFirestore.instance.collection('career_questions');
  
  final List<String> riasecFullNames = [
    'Realistic', 'Investigative', 'Artistic', 
    'Social', 'Enterprising', 'Conventional'
  ];

  String _getCategoryFullName(String letter) {
    switch (letter) {
      case 'R': return 'Realistic';
      case 'I': return 'Investigative';
      case 'A': return 'Artistic';
      case 'S': return 'Social';
      case 'E': return 'Enterprising';
      case 'C': return 'Conventional';
      default: return 'Realistic';
    }
  }

  // Helper untuk dapatkan huruf dari nama penuh
  String _getLetterFromFullName(String fullName) {
    if (fullName.isEmpty) return 'R';
    return fullName[0]; // Ambil huruf pertama (R, I, A...)
  }

  Future<String> _uploadImageToStorage(Uint8List fileBytes, int index) async {
    // Tambah index pada nama file supaya tak bertindih kalau upload serentak
    String fileName = "${DateTime.now().millisecondsSinceEpoch}_$index";
    Reference ref = FirebaseStorage.instance.ref().child('career_images/$fileName');
    await ref.putData(fileBytes);
    return await ref.getDownloadURL();
  }

  // Fungsi pilih gambar (Specific Index)
  Future<void> _pickImage(int index, List<Uint8List?> imageList, StateSetter setStateDialog) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      var f = await image.readAsBytes();
      setStateDialog(() {
        imageList[index] = f; // Simpan gambar dalam list ikut nombor soalan
      });
    }
  }

  void _showCareerDialog(BuildContext context, DocumentSnapshot? doc) {
    final bool isEditing = doc != null;
    final data = isEditing ? doc.data() as Map<String, dynamic> : null;

    // --- SETUP LIST UNTUK 4 ITEM (ADD) ATAU 1 ITEM (EDIT) ---
    int itemCount = isEditing ? 1 : 4;

    // 1. Text Controllers
    final List<TextEditingController> controllers = isEditing 
        ? [TextEditingController(text: data?['question_text'] ?? '')]
        : List.generate(4, (index) => TextEditingController());

    // 2. Categories (Default: Realistic)
    final List<String> selectedCategories = isEditing
        ? [_getCategoryFullName(data?['category'] ?? 'R')]
        : List.generate(4, (index) => 'Realistic');

    // 3. Images (Bytes untuk upload baru)
    final List<Uint8List?> newImageBytes = List.filled(itemCount, null);

    // 4. Existing Image URLs (Untuk display gambar lama)
    final List<String> existingUrls = isEditing
        ? [data?['image_url'] ?? '']
        : List.filled(4, '');

    bool isUploading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(isEditing ? "Edit Question" : "Add Batch (4 Different Types)"),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // --- LOOPING UI ---
                      // Kalau Add, dia buat 4 kotak. Kalau Edit, dia buat 1 kotak.
                      for (int i = 0; i < itemCount; i++)
                        Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.grey.shade50,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(isEditing ? "Edit Details" : "Question #${i + 1}", 
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                              const SizedBox(height: 10),

                              // A. IMAGE PICKER (INDIVIDU)
                              GestureDetector(
                                onTap: () => _pickImage(i, newImageBytes, setStateDialog),
                                child: Container(
                                  height: 100, width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: newImageBytes[i] != null
                                      ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.memory(newImageBytes[i]!, fit: BoxFit.cover))
                                      : (existingUrls[i].isNotEmpty
                                          ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(existingUrls[i], fit: BoxFit.cover))
                                          : const Center(child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [Icon(Icons.add_a_photo, color: Colors.grey), Text("Photo", style: TextStyle(fontSize: 10, color: Colors.grey))],
                                            ))),
                                ),
                              ),
                              const SizedBox(height: 10),

                              // B. DROPDOWN CATEGORY (INDIVIDU)
                              DropdownButtonFormField<String>(
                                value: selectedCategories[i],
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: "Category", 
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  border: OutlineInputBorder()
                                ),
                                items: riasecFullNames.map((cat) {
                                  return DropdownMenuItem(value: cat, child: Text(cat, style: const TextStyle(fontSize: 14)));
                                }).toList(),
                                onChanged: (val) {
                                  setStateDialog(() {
                                    selectedCategories[i] = val!;
                                  });
                                },
                              ),
                              const SizedBox(height: 10),

                              // C. TEXT FIELD (INDIVIDU)
                              TextField(
                                controller: controllers[i],
                                maxLines: 2,
                                decoration: const InputDecoration(labelText: "Question Text", border: OutlineInputBorder()),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: isUploading ? null : () => Navigator.pop(context), child: const Text("Cancel")),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                  onPressed: isUploading ? null : () async {
                    
                    // VALIDATION: Check semua kotak text diisi
                    bool allFilled = true;
                    for (var c in controllers) {
                      if (c.text.trim().isEmpty) allFilled = false;
                    }

                    if (!allFilled) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please fill in text for ALL questions!"))
                      );
                      return;
                    }

                    setStateDialog(() => isUploading = true);

                    // --- SAVE PROCESS ---
                    WriteBatch batch = FirebaseFirestore.instance.batch();

                    for (int i = 0; i < itemCount; i++) {
                      // 1. Handle Image Upload
                      String finalImageUrl = existingUrls[i];
                      if (newImageBytes[i] != null) {
                        finalImageUrl = await _uploadImageToStorage(newImageBytes[i]!, i);
                      }

                      // 2. Get Data
                      String text = controllers[i].text.trim();
                      String categoryLetter = _getLetterFromFullName(selectedCategories[i]);

                      if (isEditing) {
                        // UPDATE Single Doc
                        await careerCollection.doc(doc!.id).update({
                          'question_text': text,
                          'category': categoryLetter,
                          'image_url': finalImageUrl,
                        });
                      } else {
                        // ADD Batch Doc
                        DocumentReference newRef = careerCollection.doc();
                        batch.set(newRef, {
                          'question_text': text,
                          'category': categoryLetter,
                          'image_url': finalImageUrl,
                          'index': DateTime.now().millisecondsSinceEpoch + i,
                        });
                      }
                    }

                    if (!isEditing) {
                      await batch.commit(); // Hantar 4 soalan serentak
                    }

                    setStateDialog(() => isUploading = false);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: isUploading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                    : Text(isEditing ? "Update" : "Save All 4", style: const TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteQuestion(String id) {
    careerCollection.doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.purple,
        onPressed: () => _showCareerDialog(context, null),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add Batch (4)", style: TextStyle(color: Colors.white)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: careerCollection.orderBy('category').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text("No Career questions yet."));

          return ListView.separated(
            padding: const EdgeInsets.all(15),
            itemCount: docs.length,
            separatorBuilder: (c, i) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              
              final String catLetter = data['category'] ?? 'R';
              final String imageUrl = data['image_url'] ?? '';
              final String catFullName = _getCategoryFullName(catLetter);

              return Card(
                elevation: 2,
                child: ListTile(
                  leading: imageUrl.isNotEmpty
                    ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(imageUrl, width: 50, height: 50, fit: BoxFit.cover))
                    : CircleAvatar(
                        backgroundColor: Colors.purple[50],
                        child: Text(catLetter, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
                      ),
                  title: Text(data['question_text'] ?? 'No text'),
                  subtitle: Text("Category: $catLetter ($catFullName)"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showCareerDialog(context, docs[index])),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteQuestion(docs[index].id)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}