import 'package:admin_dashboard_myfuture/themes/colors.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CareerManage extends StatefulWidget {
  const CareerManage({super.key});

  @override
  State<CareerManage> createState() => _CareerManageState();
}

class _CareerManageState extends State<CareerManage> {
  final CollectionReference careersCollection = FirebaseFirestore.instance.collection('career_lists');
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchTerm = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search field
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Search careers by name or faculty key',
              suffixIcon: _searchTerm.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() {
                        _searchCtrl.clear();
                        _searchTerm = '';
                      }),
                    )
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              isDense: true,
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (val) => setState(() => _searchTerm = val),
          ),
        ),

        // Stream + filtered list
        StreamBuilder<QuerySnapshot>(
          stream: careersCollection.snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final docs = snapshot.data!.docs;

            final query = _searchTerm.trim().toLowerCase();
            final filtered = query.isEmpty
                ? docs
                : docs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    final String name = (data['id'] as String?) ?? '';
                    final String facultyKey = (data['faculty_key'] as String?) ?? '';
                    return name.toLowerCase().contains(query) || facultyKey.toLowerCase().contains(query);
                  }).toList();

            if (filtered.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: Text('No careers found.')),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final data = filtered[index].data() as Map<String, dynamic>;
                final String docId = filtered[index].id;

                String name = data['id'] ?? docId;
                String salary = data['salary'] ?? 'N/A';

                // Papar Key ni supaya awak senang check data betul ke tak
                String facultyKey = data['faculty_key'] ?? '-';

                List<dynamic> pathways = data['pathways'] ?? [];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(child: Text(name.isNotEmpty ? name[0] : "?")),
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Salary: $salary"),
                        // Tunjuk key ni penting untuk awak demo kat supervisor
                        Text("Faculty Mapping Key: $facultyKey", style: TextStyle(fontSize: 12, color: Colors.blue[800], fontWeight: FontWeight.w600)),
                        Text("${pathways.length} Pathways Defined"),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, color: cardPink),
                      onPressed: () => showCareerDialog(context, filtered[index]),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

// --- PUBLIC FUNCTIONS ---

Future<void> showCareerDialog(BuildContext context, DocumentSnapshot? doc) async {
  final CollectionReference careersCollection = FirebaseFirestore.instance.collection('career_lists');
  
  // 1. FETCH UNIVERSITIES
  List<String> availableUnis = [];
  try {
    QuerySnapshot uniSnapshot = await FirebaseFirestore.instance.collection('universities').get();
    availableUnis = uniSnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      // Ambil acronym (UM, UiTM)
      return (data['acronym'] as String?) ?? doc.id; 
    }).toList();
  } catch (e) {
    print("Error fetching universities: $e");
    availableUnis = ['UTHM', 'UM', 'USM', 'UKM']; 
  }

  if (!context.mounted) return;

  final bool isEditing = doc != null;
  final Map<String, dynamic>? data = isEditing ? doc.data() as Map<String, dynamic> : null;

  final TextEditingController nameCtrl = TextEditingController(text: data?['id'] ?? '');
  final TextEditingController descCtrl = TextEditingController(text: data?['job_desc'] ?? '');
  final TextEditingController salaryCtrl = TextEditingController(text: data?['salary'] ?? '');
  
  // --- INI FEATURE BARU UNTUK SUPERVISOR AWAK ---
  // Kita simpan "Keyword" (contoh: Accounting) kat sini.
  final TextEditingController facultyKeyCtrl = TextEditingController(text: data?['faculty_key'] ?? '');
  
  List<Map<String, dynamic>> localPathways = [];
  if (data != null && data['pathways'] != null) {
    localPathways = List<Map<String, dynamic>>.from(
      (data['pathways'] as List).map((item) => Map<String, dynamic>.from(item))
    );
  }

  String selectedRiasec = data?['riasec_tag'] ?? 'Realistic';
  List<String> selectedUnis = [];
  if (data?['related_unis'] != null) {
    selectedUnis = List<String>.from(data?['related_unis']);
  }

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(isEditing ? "Edit Career" : "Add New Career"),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Career Name (ID)")),
                    const SizedBox(height: 10),
                    
                    TextField(
                      controller: salaryCtrl, 
                      decoration: const InputDecoration(labelText: "Average Salary (e.g. RM 3,000 - RM 5,000)")
                    ),
                    const SizedBox(height: 10),

                    // --- INPUT BARU: FACULTY KEY ---
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200)
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("🔥 University Faculty Mapping", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blue)),
                          const SizedBox(height: 5),
                          TextField(
                            controller: facultyKeyCtrl, 
                            decoration: const InputDecoration(
                              labelText: "Faculty Key (e.g. Accounting)",
                              hintText: "Type the key name used in University DB",
                              border: OutlineInputBorder(),
                              isDense: true,
                              fillColor: Colors.white,
                              filled: true,
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            "Note: If student clicks UM, app will find 'Accounting' link inside UM database.",
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),

                    TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: "Job Description")),
                    const SizedBox(height: 20),

                    // --- BAHAGIAN PATHWAYS ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Pathways", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        TextButton.icon(
                          icon: const Icon(Icons.add_road),
                          label: const Text("Add Path"),
                          onPressed: () async {
                            final newPath = await _showPathwayEditor(context, null);
                            if (newPath != null) {
                              setState(() => localPathways.add(newPath));
                            }
                          },
                        )
                      ],
                    ),
                    Container(
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                      height: 150,
                      child: localPathways.isEmpty 
                        ? const Center(child: Text("No pathways added yet."))
                        : ListView.separated(
                            itemCount: localPathways.length,
                            separatorBuilder: (c, i) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final path = localPathways[index];
                              
                              String mbtiDisplay = path['recommended_mbti'] == 'S' ? 'Sensing' : (path['recommended_mbti'] == 'N' ? 'Intuitive' : path['recommended_mbti']);
                              int stepsCount = (path['steps'] as List?)?.length ?? 0;
                              
                              return ListTile(
                                dense: true,
                                title: Text(path['title'] ?? "No Title", style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(path['reason'] ?? "No Description", maxLines: 1, overflow: TextOverflow.ellipsis),
                                    Text("Duration: ${path['duration']} • MBTI: $mbtiDisplay • Steps: $stepsCount", style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 16, color: Colors.blue),
                                      onPressed: () async {
                                        final updatedPath = await _showPathwayEditor(context, path);
                                        if (updatedPath != null) {
                                          setState(() => localPathways[index] = updatedPath);
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                                      onPressed: () => setState(() => localPathways.removeAt(index)),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                    ),
                    const SizedBox(height: 20),

                    // --- RIASEC & UNIVERSITIES ---
                     DropdownButtonFormField<String>(
                      value: selectedRiasec,
                      decoration: const InputDecoration(labelText: "Overall RIASEC Tag"),
                      items: ['Realistic', 'Investigative', 'Artistic', 'Social', 'Enterprising', 'Conventional']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (val) => setState(() => selectedRiasec = val!),
                    ),
                    const SizedBox(height: 10),
                    
                    const Text("Related Universities", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 5),
                    availableUnis.isEmpty 
                    ? const Text("Loading universities...", style: TextStyle(color: Colors.grey))
                    : Wrap(
                      spacing: 8,
                      children: availableUnis.map((uni) {
                        return FilterChip(
                          label: Text(uni),
                          selected: selectedUnis.contains(uni),
                          onSelected: (selected) {
                            setState(() => selected ? selectedUnis.add(uni) : selectedUnis.remove(uni));
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.isEmpty) return;
                  final careerData = {
                    'id': nameCtrl.text,
                    'salary': salaryCtrl.text, 
                    'job_desc': descCtrl.text,
                    
                    // --- SAVE DATA PENTING SINI ---
                    'faculty_key': facultyKeyCtrl.text.trim(), 

                    'pathways': localPathways,
                    'riasec_tag': selectedRiasec,
                    'related_unis': selectedUnis,
                    'view_count': isEditing ? (data?['view_count'] ?? 0) : 0,
                  };

                  if (isEditing) {
                    await careersCollection.doc(doc!.id).set(careerData, SetOptions(merge: true));
                  } else {
                    await careersCollection.doc(nameCtrl.text).set(careerData);
                  }
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text("Save All"),
              ),
            ],
          );
        },
      );
    },
  );
}

// Function Pathway Editor
// Function Pathway Editor (Dikemaskini untuk SPM Default)
Future<Map<String, dynamic>?> _showPathwayEditor(BuildContext context, Map<String, dynamic>? existingPath) {
  final TextEditingController titleCtrl = TextEditingController(text: existingPath?['title'] ?? '');
  final TextEditingController reasonCtrl = TextEditingController(text: existingPath?['reason'] ?? '');
  final TextEditingController durationCtrl = TextEditingController(text: existingPath?['duration'] ?? '');
  String selectedMbti = existingPath?['recommended_mbti'] ?? 'S';
  
  List<Map<String, dynamic>> localSteps = [];
  
  if (existingPath != null && existingPath['steps'] != null) {
    // Jika edit laluan sedia ada, ambil langkah-langkah yang ada
    localSteps = List<Map<String, dynamic>>.from(
      (existingPath['steps'] as List).map((e) => Map<String, dynamic>.from(e))
    );
  } else {
    // Jika buat laluan baru, AUTOMATIK tambah SPM sebagai langkah pertama
    localSteps.add({
      'title': 'SPM',
      'desc': 'Sijil Pelajaran Malaysia',
      'time': '', // SPM tak perlu masa spesifik dalam konteks flow ini biasanya
    });
  }

  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text("Edit Educational Pathway"),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleCtrl, 
                      decoration: const InputDecoration(labelText: "Pathway Title (e.g. Degree Route)", border: OutlineInputBorder())
                    ),
                    const SizedBox(height: 10),

                    TextField(controller: reasonCtrl, maxLines: 2, decoration: const InputDecoration(labelText: "Reason / Description", border: OutlineInputBorder())),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: durationCtrl, decoration: const InputDecoration(labelText: "Total Duration"))),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: ['S', 'N'].contains(selectedMbti) ? selectedMbti : 'S',
                            decoration: const InputDecoration(labelText: "Rec. MBTI"),
                            items: [
                              const DropdownMenuItem(value: 'S', child: Text("Sensing")),
                              const DropdownMenuItem(value: 'N', child: Text("Intuitive")),
                            ],
                            onChanged: (val) => setState(() => selectedMbti = val!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Steps", style: TextStyle(fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: Colors.green),
                          // Tambah step baru kosong bila butang add ditekan
                          onPressed: () => setState(() => localSteps.add({'title': '', 'desc': '', 'time': ''})),
                        )
                      ],
                    ),
                    ...localSteps.asMap().entries.map((entry) {
                      int idx = entry.key;
                      Map<String, dynamic> step = entry.value;
                      
                      // Check kalau ini step pertama (SPM)
                      bool isFirstStep = idx == 0;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: isFirstStep ? Colors.orange[50] : Colors.grey[50], // Highlight sikit SPM
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: step['title'], 
                                      // Jika SPM, jadikan readOnly supaya tak terubah tajuk (optional)
                                      readOnly: isFirstStep, 
                                      decoration: const InputDecoration(labelText: "Title (e.g. SPM)"), 
                                      onChanged: (val) => step['title'] = val
                                    )
                                  ),
                                  // Jangan bagi delete SPM (index 0)
                                  if (!isFirstStep) 
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle, color: Colors.red, size: 20), 
                                      onPressed: () => setState(() => localSteps.removeAt(idx))
                                    )
                                ],
                              ),
                              Row(
                                children: [
                                  // Jika SPM, kita hide atau disable field Time
                                  if (!isFirstStep)
                                    Expanded(
                                      flex: 1,
                                      child: TextFormField(
                                        initialValue: step['time'], 
                                        decoration: const InputDecoration(labelText: "Time (e.g 2.5 Years)"), 
                                        onChanged: (val) => step['time'] = val
                                      )
                                    ),
                                  if (!isFirstStep) const SizedBox(width: 10),
                                  
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      initialValue: step['desc'], 
                                      decoration: const InputDecoration(labelText: "Description"), 
                                      onChanged: (val) => step['desc'] = val
                                    )
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList()
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Discard")),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, {
                  'title': titleCtrl.text,
                  'reason': reasonCtrl.text, 
                  'duration': durationCtrl.text, 
                  'recommended_mbti': selectedMbti, 
                  'steps': localSteps
                }),
                child: const Text("Save Pathway"),
              ),
            ],
          );
        },
      );
    },
  );
}