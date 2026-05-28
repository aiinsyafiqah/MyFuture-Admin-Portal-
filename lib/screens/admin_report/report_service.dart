import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ReportService {
  
  static Future<void> generateFullAdminReport() async {
    final pdf = pw.Document();

    // --- 1. LOAD FONT (PENYELESAIAN MASALAH ERROR) ---
    // Kita perlu load font Regular DAN Bold supaya error Helvetica hilang
    final fontRegular = await PdfGoogleFonts.nunitoRegular();
    final fontBold = await PdfGoogleFonts.nunitoBold();

    // 2. TARIK DATA BIASISWA
    final QuerySnapshot scholarshipSnap = await FirebaseFirestore.instance
        .collection('scholarships')
        .orderBy('createdAt', descending: true)
        .get();

    // 3. TARIK DATA PELAJAR
    final QuerySnapshot studentSnap = await FirebaseFirestore.instance
        .collection('users')
         .where('role', isEqualTo: 'student')
         .where('isVerified', isEqualTo: true)
        .get(); 

    // --- 4. LOGIC KIRAAN (DIKEMASKINI) ---
    // Kita guna satu loop sahaja untuk jimat masa dan elak error
    Map<String, int> riasecCounts = {};
    Map<String, int> mbtiCounts = {};

    for (var doc in studentSnap.docs) {
      final data = doc.data() as Map<String, dynamic>;

      // A. KIRA RIASEC (Berdasarkan huruf pertama code)
      String? riasecCode = data['riasec_code'];
      if (riasecCode != null && riasecCode.isNotEmpty) {
        String firstLetter = riasecCode[0].toUpperCase();
        String riasecName = _getRiasecName(firstLetter);

        if (riasecCounts.containsKey(riasecName)) {
          riasecCounts[riasecName] = riasecCounts[riasecName]! + 1;
        } else {
          riasecCounts[riasecName] = 1;
        }
      }

      // B. KIRA MBTI
      String? mbtiResult = data['mbti_type']; // Pastikan nama field betul
      if (mbtiResult != null && mbtiResult.isNotEmpty) {
        String cleanMbti = mbtiResult.trim().toUpperCase();
        
        if (mbtiCounts.containsKey(cleanMbti)) {
          mbtiCounts[cleanMbti] = mbtiCounts[cleanMbti]! + 1;
        } else {
          mbtiCounts[cleanMbti] = 1;
        }
      }
    }

    // --- 5. CARI PEMENANG (HIGHEST) ---
    
    // Cari Highest RIASEC
    String highestRiasec = "No Data";
    if (riasecCounts.isNotEmpty) {
      var sortedRiasec = riasecCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      highestRiasec = sortedRiasec.first.key;
    }

    // Cari Highest MBTI
    String highestMBTI = "No Data";
    if (mbtiCounts.isNotEmpty) {
      var sortedMbti = mbtiCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      highestMBTI = sortedMbti.first.key;
    }

    // --- 6. GENERATE PDF ---
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        // PENTING: Apply font di sini supaya tak guna Helvetica
        theme: pw.ThemeData.withFont(
          base: fontRegular,
          bold: fontBold,
        ),
        build: (pw.Context context) {
          return [
            // HEADER
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("MyFuture Report", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Text(DateFormat('dd MMM yyyy').format(DateTime.now())),
                ],
              ),
            ),
            
            pw.SizedBox(height: 20),

            // PART A
            pw.Text("Part A : Students Analysis", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            pw.SizedBox(height: 10),
            
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatBox("Total Active Students", "${studentSnap.docs.length}", PdfColors.blue100),
                _buildStatBox("Dominant Interest", highestRiasec, PdfColors.green100), 
                _buildStatBox("Dominant MBTI", highestMBTI, PdfColors.purple100), 
              ]
            ),
            pw.SizedBox(height: 20),
            pw.Text("Notes : Data collected from registered student assessments."),

            pw.SizedBox(height: 40),

            // PART B
            pw.Text("Part B: List of Scholarships listed", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.Text("Current Active Scholarships: ${scholarshipSnap.docs.length}"),
            pw.SizedBox(height: 10),

            // TABLE
            pw.Table.fromTextArray(
              context: context,
              border: pw.TableBorder.all(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey),
              cellAlignment: pw.Alignment.centerLeft,
              headers: <String>['No.', 'Scholarships', 'Category', 'Deadline'],
              data: List<List<String>>.generate(
                scholarshipSnap.docs.length,
                (index) {
                  final data = scholarshipSnap.docs[index].data() as Map<String, dynamic>;
                  String deadline = "Open";
                  if (data['deadline'] != null) {
                    deadline = DateFormat('dd/MM/yyyy').format((data['deadline'] as Timestamp).toDate());
                  }
                  return [
                    (index + 1).toString(),
                    data['title'] ?? '-',
                    data['category'] ?? '-',
                    deadline,
                  ];
                },
              ),
            ),
            
            pw.SizedBox(height: 20),
            pw.Footer(
              title: pw.Text("created by MyFuture Administration", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  // Helper Widget
  static pw.Widget _buildStatBox(String label, String value, PdfColor color) {
    return pw.Container(
      width: 100,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(value, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
          pw.SizedBox(height: 4),
          pw.Text(label, style: const pw.TextStyle(fontSize: 10), textAlign: pw.TextAlign.center),
        ],
      ),
    );
  }

  static String _getRiasecName(String char){
    switch (char){
      case 'R': return 'Realistic';
      case 'I': return 'Investigative'; // Typo fixed: Investigate -> Investigative
      case 'A': return 'Artistic';
      case 'S': return 'Social';
      case 'E': return 'Enterprising';
      case 'C': return 'Conventional';
      default: return 'Unknown';
    }
  }
}