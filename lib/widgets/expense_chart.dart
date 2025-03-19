import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/expense.dart';

class ExpenseChart extends StatelessWidget {
  final List<Expense> expenses;

  const ExpenseChart({super.key, required this.expenses});

  @override
  Widget build(BuildContext context) {
    final categoryTotals = <ExpenseCategory, double>{};

    for (var expense in expenses) {
      categoryTotals[expense.category] = (categoryTotals[expense.category] ?? 0) + expense.amount;
    }

    return PieChart(
      PieChartData(
        sections: categoryTotals.entries.map((entry) {
          return PieChartSectionData(
            value: entry.value,
            title: entry.key.toString().split('.').last,
            color: Colors.primaries[entry.key.index % Colors.primaries.length],
          );
        }).toList(),
      ),
    );
  }
}
