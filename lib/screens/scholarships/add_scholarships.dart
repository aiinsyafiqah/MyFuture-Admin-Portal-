import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

const Color kPrimaryColor = Colors.blue;

class AddScholarshipPage extends StatefulWidget {
  // Terima data scholarship jika nak EDIT (Boleh jadi null kalau ADD baru)
  final DocumentSnapshot? scholarshipToEdit;

  const AddScholarshipPage({super.key, this.scholarshipToEdit});

  @override
  State<AddScholarshipPage> createState() => _AddScholarshipPageState();
}

class _AddScholarshipPageState extends State<AddScholarshipPage> {
  // Controllers
  final TextEditingController titleController = TextEditingController();
  final TextEditingController providerController = TextEditingController();
  final TextEditingController linkController = TextEditingController();
  
  // State Variables
  DateTime? selectedDeadline;
  String? selectedCategory; 
  String? selectedSPMResult;
  bool isEditing = false; // Penanda adakah kita tengah edit

  // List Options
  final List<String> categoryOptions = [
    'Full Scholarship',
    'Convertible Loan', // PBU
    'Education Loan',
    'Bursary',
    'Partial Scholarship'
  ];

  final List<String> spmResultOptions = [
    'Straight A+ (Semua A+)',
    'Minimum 9A',
    'Minimum 7A',
    'Minimum 5A',
    'Credit in all subjects',
    'Pass all subjects (Lulus Semua)',
    'No Specific Requirement',
  ];

  @override
  void initState() {
    super.initState();
    // CHECK: Adakah user hantar data untuk edit?
    if (widget.scholarshipToEdit != null) {
      isEditing = true;
      final data = widget.scholarshipToEdit!.data() as Map<String, dynamic>;

      // Isi semula borang dengan data lama
      titleController.text = data['title'] ?? '';
      providerController.text = data['provider'] ?? '';
      linkController.text = data['link'] ?? '';
      
      // Pastikan value dropdown wujud dalam list, kalau tak error
      if (categoryOptions.contains(data['category'])) {
        selectedCategory = data['category'];
      }
      if (spmResultOptions.contains(data['spm_result'])) {
        selectedSPMResult = data['spm_result'];
      }

      // Handle Deadline (kalau ada)
      if (data['deadline'] != null) {
        selectedDeadline = (data['deadline'] as Timestamp).toDate();
      }
    }
  }

  // --- DATE PICKER ---
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDeadline ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => selectedDeadline = picked);
    }
  }

  // --- SAVE / UPDATE FUNCTION ---
  Future<void> saveScholarship() async {
    // Validation asas
    if (titleController.text.isEmpty || 
        providerController.text.isEmpty || 
        selectedCategory == null ||  
        selectedSPMResult == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in title, provider, category & result!")),
      );
      return;
    }

    try {
      showDialog(context: context, builder: (c) => const Center(child: CircularProgressIndicator()));

      // Data Map
      Map<String, dynamic> dataMap = {
        'title': titleController.text.trim(),
        'provider': providerController.text.trim(),
        'category': selectedCategory, 
        'spm_result': selectedSPMResult, 
        'link': linkController.text.trim(),
        // Deadline boleh null (Optional)
        'deadline': selectedDeadline != null ? Timestamp.fromDate(selectedDeadline!) : null,
      };

      if (isEditing) {
        // --- LOGIC UPDATE ---
        // Kita tak kacau 'createdAt' atau 'image_url' (kecuali kita ada fungsi upload baru)
        await FirebaseFirestore.instance
            .collection('scholarships')
            .doc(widget.scholarshipToEdit!.id) // Guna ID lama
            .update(dataMap);
      } else {
        // --- LOGIC ADD NEW ---
        // Tambah field extra untuk item baru
        dataMap['createdAt'] = FieldValue.serverTimestamp();
        dataMap['image_url'] = ''; // Default kosong
        
        await FirebaseFirestore.instance.collection('scholarships').add(dataMap);
      }

      if (mounted) {
        Navigator.pop(context); // Close loading
        Navigator.pop(context); // Close page
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? "Updated Successfully!" : "Added Successfully!"), 
            backgroundColor: Colors.green
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Tukar tajuk ikut mode
        title: Text(isEditing ? "Edit Scholarship" : "Add New Scholarship"),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField("Scholarship Title", titleController, Icons.school),
            const SizedBox(height: 15),
            _buildTextField("Provider (e.g. JPA, MARA)", providerController, Icons.business),
            const SizedBox(height: 15),

            // Dropdown Category
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: InputDecoration(
                labelText: "Type of Scholarship",
                prefixIcon: const Icon(Icons.category),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: categoryOptions.map((String category) {
                return DropdownMenuItem<String>(value: category, child: Text(category));
              }).toList(),
              onChanged: (newValue) => setState(() => selectedCategory = newValue),
            ),

            const SizedBox(height: 15),

            // Dropdown SPM Result
            DropdownButtonFormField<String>(
              value: selectedSPMResult,
              decoration: InputDecoration(
                labelText: "Min. SPM Result Requirement",
                prefixIcon: const Icon(Icons.grade),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: spmResultOptions.map((String result) {
                return DropdownMenuItem<String>(value: result, child: Text(result));
              }).toList(),
              onChanged: (newValue) => setState(() => selectedSPMResult = newValue),
            ),

            const SizedBox(height: 15),
            _buildTextField("Website Link", linkController, Icons.link),

            const SizedBox(height: 25),

            // Date Picker (Optional Label added)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Deadline (Optional)", style: TextStyle(fontWeight: FontWeight.bold)),
                if (selectedDeadline != null)
                  TextButton(
                    onPressed: () => setState(() => selectedDeadline = null),
                    child: const Text("Clear Date", style: TextStyle(color: Colors.red)),
                  )
              ],
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                leading: const Icon(Icons.calendar_today, color: kPrimaryColor),
                title: Text(
                  selectedDeadline == null 
                      ? "Select Deadline (Or leave blank for Open)" 
                      : DateFormat('dd MMM yyyy').format(selectedDeadline!),
                  style: TextStyle(
                    color: selectedDeadline == null ? Colors.grey : Colors.black,
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _selectDate(context),
              ),
            ),

            const SizedBox(height: 40),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: saveScholarship,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  isEditing ? "Update Scholarship" : "Publish Scholarship", 
                  style: const TextStyle(fontSize: 16, color: Colors.white)
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}