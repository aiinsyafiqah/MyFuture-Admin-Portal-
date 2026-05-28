import 'package:admin_dashboard_myfuture/screens/admin_report/report_service.dart';
import 'package:admin_dashboard_myfuture/themes/colors.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminReportPage extends StatelessWidget {
  const AdminReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Determine screen width for responsive layout
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 193, 203, 235),
      appBar: AppBar(
        title: const Text('Analytics & Reports', 
        style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: const Color.fromARGB(255, 193, 203, 235),
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: ElevatedButton.icon(
              onPressed: () {
                // Panggil service PDF yang kita buat tadi
                ReportService.generateFullAdminReport();
              },
              icon: const Icon(Icons.download, size: 18),
              label: const Text("Download Report"),
              style: ElevatedButton.styleFrom(
                backgroundColor: sideColor, 
                foregroundColor: Colors.white,
              ),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Student Psychographics", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54)),
            const SizedBox(height: 16),
            
            // --- SECTION 1: LIVE CHARTS (Connects to 'users') ---
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                // DATA PROCESSING LOGIC
                  int invCount = 0, artCount = 0, socCount = 0, entCount = 0, conCount = 0, reaCount = 0;
                  Map<String, int> mbtiCounts = {};

                  for (var doc in snapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    
                    // 1. Count RIASEC
                    // Your DB field is 'riasec_code' (e.g., "ARI")
                    String? code = data['riasec_code']; 

                    if (code != null && code.isNotEmpty) {
                      // We only look at the first letter (The Dominant Type)
                      String dominantType = code[0]; 

                      if (dominantType == 'I') invCount++;
                      else if (dominantType == 'A') artCount++;
                      else if (dominantType == 'S') socCount++;
                      else if (dominantType == 'E') entCount++;
                      else if (dominantType == 'C') conCount++;
                      else if (dominantType == 'R') reaCount++;
                    }

                  // 2. Count MBTI
                  // Make sure your database field is exactly 'mbti_result'
                  String? mbti = data['mbti_type']; 
                  if (mbti != null && mbti.isNotEmpty) {
                    mbtiCounts[mbti] = (mbtiCounts[mbti] ?? 0) + 1;
                  }
                }

                return Flex(
                  direction: isDesktop ? Axis.horizontal : Axis.vertical,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pass the calculated counters to the Pie Chart
                    Expanded(
                      flex: isDesktop ? 1 : 0,
                      child: _ChartCard(
                        title: "RIASEC Distribution",
                        child: SizedBox(
                          height: 200,
                          child: _RiasecPieChart(
                            inv: invCount, 
                            art: artCount, 
                            soc: socCount, 
                            ent: entCount, 
                            rea: reaCount, 
                            con: conCount),
                        ),
                      ),
                    ),
                    SizedBox(width: isDesktop ? 24 : 0, height: isDesktop ? 0 : 24),
                    
                    // Pass the calculated map to the Bar Chart
                    Expanded(
                      flex: isDesktop ? 2 : 0,
                      child: _ChartCard(
                        title: "MBTI Overview",
                        child: SizedBox(
                          height: 200,
                          child: _MbtiBarChart(data: mbtiCounts),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 32),

            // --- SECTION 2: LIVE TOP CAREERS TABLE (Connects to 'careers') ---
            const Text("Top Career Interests", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54)),
            const SizedBox(height: 16),
            
            StreamBuilder<QuerySnapshot>(
              // Query: Get careers, order by 'view_count' descending, take top 5
              stream: FirebaseFirestore.instance
                  .collection('career_lists')
                  .orderBy('view_count', descending: true)
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                 if (snapshot.hasError) return const Text("Error loading careers");
                 if (!snapshot.hasData) return const LinearProgressIndicator();

                 final careers = snapshot.data!.docs;

                 return Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(Colors.grey[100]),
                      columns: const [
                        DataColumn(label: Text('Rank', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Career Name', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Views', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      // Map the Firestore documents to DataRows
                      rows: List.generate(careers.length, (index) {
                        final data = careers[index].data() as Map<String, dynamic>;
                        return DataRow(cells: [
                          DataCell(Text('#${index + 1}')),
                          DataCell(Text(data['id'] ?? 'Unknown')), // Ensure 'name' exists in DB
                          DataCell(Text((data['view_count'] ?? 0).toString())), // Ensure 'view_count' exists
                        ]);
                      }),
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}

// --- SUB-WIDGETS (UPDATED TO ACCEPT DATA) ---

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _ChartCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _RiasecPieChart extends StatelessWidget {
  final int inv, art, soc, ent, rea, con;
  // Constructor now accepts actual counts
  const _RiasecPieChart({required this.inv, required this.art, required this.soc, required this.ent, required this.rea, required this.con});

  @override
  Widget build(BuildContext context) {
    // Prevent crash if all are 0
    if (inv + art + soc + ent + rea + con == 0) return const Center(child: Text("No Data Yet"));

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: [
          PieChartSectionData(color: Colors.blue, value: inv.toDouble(), title: 'Realistic ($rea)', radius: 50, titleStyle: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
          PieChartSectionData(color: Colors.blue, value: inv.toDouble(), title: 'Investigate ($inv)', radius: 50, titleStyle: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
          PieChartSectionData(color: Colors.red, value: art.toDouble(), title: 'Artistic ($art)', radius: 50, titleStyle: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
          PieChartSectionData(color: Colors.green, value: soc.toDouble(), title: 'Social ($soc)', radius: 50, titleStyle: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
          PieChartSectionData(color: Colors.orange, value: ent.toDouble(), title: 'Enterprise ($ent)', radius: 50, titleStyle: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _MbtiBarChart extends StatelessWidget {
  final Map<String, int> data;
  const _MbtiBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const Center(child: Text("No MBTI Data"));

    // 1. Sort data to find top 5 types
    var sortedKeys = data.keys.toList()..sort((a, b) => data[b]!.compareTo(data[a]!));
    if (sortedKeys.length > 5) sortedKeys = sortedKeys.sublist(0, 5);

    // 2. Calculate Max Y for styling
    double maxY = (data.values.isNotEmpty 
        ? data.values.reduce((a, b) => a > b ? a : b) 
        : 10).toDouble();
    maxY = maxY + (maxY * 0.2); // Add buffer space

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => Colors.blueGrey,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              String mbtiType = sortedKeys[group.x.toInt()];
              return BarTooltipItem(
                '$mbtiType\n',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                children: <TextSpan>[
                  TextSpan(
                    text: (rod.toY.toInt()).toString(),
                    style: const TextStyle(color: Colors.yellow),
                  ),
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          
          // --- X-AXIS (BOTTOM) ---
          bottomTitles: AxisTitles(
            axisNameWidget: const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text("MBTI Type", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            axisNameSize: 30,
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              // Note: We removed SideTitleWidget here to stop the error
              getTitlesWidget: (double value, TitleMeta meta) {
                if (value.toInt() >= sortedKeys.length) return const SizedBox.shrink();
                
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0), // Add simple padding instead
                  child: Text(
                    sortedKeys[value.toInt()], 
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)
                  ),
                );
              },
            ),
          ),

          // --- Y-AXIS (LEFT) ---
          leftTitles: AxisTitles(
            axisNameWidget: const Text("Student Count", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            axisNameSize: 30,
            sideTitles: const SideTitles(showTitles: false),
          ),

          // --- COUNT LABELS (TOP) ---
          topTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              // Note: We removed SideTitleWidget here to stop the error
              getTitlesWidget: (double value, TitleMeta meta) {
                int index = value.toInt();
                if (index >= sortedKeys.length) return const SizedBox.shrink();
                
                String key = sortedKeys[index];
                int count = data[key] ?? 0;

                return Center(
                  child: Text(
                    count.toString(), 
                    style: const TextStyle(
                      color: Colors.purple, 
                      fontWeight: FontWeight.bold, 
                      fontSize: 12
                    ),
                  ),
                );
              },
            ),
          ),
          
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(
          show: true,
          border: const Border(
            bottom: BorderSide(color: Colors.black12, width: 1),
            left: BorderSide(color: Colors.black12, width: 1),
          ),
        ),
        barGroups: List.generate(sortedKeys.length, (index) {
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: data[sortedKeys[index]]!.toDouble(),
                color: Colors.purple.shade300,
                width: 22,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}