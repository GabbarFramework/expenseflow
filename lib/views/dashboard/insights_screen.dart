import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ✅ Firestore import
import '../../services/expense_service.dart';
import '../../models/expense.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  _InsightsScreenState createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  List<Expense> _expenses = [];
  bool _isLoading = true;
  Map<String, double> _categoryTotals = {};
  Map<String, double> _monthlyTotals = {};

  final Map<String, Color> categoryColors = {
    'food': Colors.red,
    'transport': Colors.blue,
    'bills': Colors.orange,
    'entertainment': Colors.purple,
    'shopping': Colors.pink,
    'health': Colors.teal,
    'education': Colors.yellow,
    'other': Colors.green,
  };

  @override
  void initState() {
    super.initState();
    _fetchExpenses(); // ✅ Fetch data only once
    testFirestoreConnection(); // ✅ Test Firestore connection
  }

  Future<void> _fetchExpenses() async {
    try {
      print("Fetching expenses...");
      List<Expense> expenses = await ExpenseService().getExpenses();
      print("Fetched ${expenses.length} expenses.");

      if (!mounted) return;

      Map<String, double> categoryTotals = {};
      Map<String, Map<String, double>> monthlyCategoryTotals = {}; // ✅ Store multiple categories per month
      Map<String, double> newMonthlyTotals = {}; // ✅ Flat map for chart

      for (var expense in expenses) {
        String categoryKey = expense.category.toString().split('.').last;
        if (categoryKey.isEmpty || !categoryColors.containsKey(categoryKey)) {
          categoryKey = "other"; // ✅ Default category
        }

        print("Expense: ${expense.id}, Category: $categoryKey, Amount: ${expense.amount}");

        categoryTotals[categoryKey] = (categoryTotals[categoryKey] ?? 0) + expense.amount;

        String monthKey = "${expense.date.year}-${expense.date.month}";

        if (!monthlyCategoryTotals.containsKey(monthKey)) {
          monthlyCategoryTotals[monthKey] = {};
        }

        monthlyCategoryTotals[monthKey]![categoryKey] =
            (monthlyCategoryTotals[monthKey]![categoryKey] ?? 0) + expense.amount;
      }

      // ✅ Convert nested map to flat map (Sum category totals for each month)
      monthlyCategoryTotals.forEach((month, categories) {
        double totalForMonth = categories.values.fold(0.0, (sum, amount) => sum + amount);
        newMonthlyTotals[month] = totalForMonth;
      });

      print("Computed Monthly Totals: $monthlyCategoryTotals");
      print("Flattened Monthly Totals: $newMonthlyTotals"); // ✅ Debugging output

      if (mounted) {
        setState(() {
          _expenses = expenses;
          _categoryTotals = categoryTotals;
          _monthlyTotals = newMonthlyTotals; // ✅ Assign correctly
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching expenses: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteExpense(String id) async {
    await ExpenseService().deleteExpense(id);
    _fetchExpenses(); // ✅ Refresh after deletion
  }

  /// ✅ Define testFirestoreConnection function
  Future<void> testFirestoreConnection() async {
    try {
      var snapshot =
          await FirebaseFirestore.instance.collection('expenses').limit(1).get();
      print("Firestore test successful: ${snapshot.docs.length} docs found.");
    } catch (e) {
      print("Firestore Error: $e");
    }
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Delete Expense"),
          content: Text("Are you sure you want to delete this expense?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                _deleteExpense(id);
                Navigator.of(context).pop();
              },
              child: Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Expense Insights')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator()) // ✅ Show loading state
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 10),
                    Text("Category-wise Expenses",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    _buildPieChart(),
                    SizedBox(height: 20),
                    Text("Monthly Expense Trend",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    _buildBarChart(),
                    SizedBox(height: 20),
                    Text("Recent Expenses",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    _buildExpenseList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPieChart() {
    return SizedBox(
      height: 250,
      child: PieChart(
        PieChartData(
          sections: _categoryTotals.entries.map((entry) {
            return PieChartSectionData(
              value: entry.value,
              title: entry.key, // ✅ Full category name
              color: categoryColors[entry.key] ?? Colors.blue,
              radius: 60,
              titleStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    if (_monthlyTotals.isEmpty) {
      return Center(child: Text("No monthly data available."));
    }

    List<String> months = _monthlyTotals.keys.toList();
    months.sort(); // Ensure months are ordered correctly

    print("Chart Data: $_monthlyTotals");

    return SizedBox(
      height: 250,
      child: BarChart(
        BarChartData(
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  int index = value.toInt();
                  if (index >= 0 && index < months.length) {
                    return Text(
                      months[index], // ✅ Show actual month-year label
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    );
                  }
                  return Text(""); // Handle out-of-range indexes
                },
              ),
            ),
          ),
          barGroups: months.asMap().entries.map((entry) {
            int index = entry.key;
            String month = entry.value;

            return BarChartGroupData(
              x: index, // ✅ Use index for positioning
              barRods: [
                BarChartRodData(
                  toY: _monthlyTotals[month] ?? 0,
                  color: Colors.blue,
                  width: 10, // ✅ Adjust bar width
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }


  Widget _buildExpenseList() {
    return _expenses.isEmpty
        ? Center(child: Text("No expenses found.")) // ✅ Handle empty state
        : ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(), // ✅ Prevent double scroll
            itemCount: _expenses.length,
            itemBuilder: (context, index) {
              final expense = _expenses[index];
              return Card(
                child: ListTile(
                  title: Text(expense.category.toString().split('.').last), // ✅ Fix category display
                  subtitle: Text("\$${expense.amount.toStringAsFixed(2)}"),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmDelete(expense.id),
                  ),
                ),
              );
            },
          );
  }
}
