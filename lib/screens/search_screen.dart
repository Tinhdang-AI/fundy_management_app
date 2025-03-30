import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/screens/expense_screen.dart';
import '../services/database_service.dart';
import '../models/expense_model.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<ExpenseModel> _searchResults = [];
  bool _isSearching = false;
  bool _showExpenses = true; // Toggle between expenses and income
  final DatabaseService _databaseService = DatabaseService();

  double _expenseTotal = 0;
  double _incomeTotal = 0;
  double _netTotal = 0;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_searchController.text.isNotEmpty) {
      _performSearch(_searchController.text);
    } else {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _calculateTotals();
      });
    }
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isSearching = true;
    });

    try {
      List<ExpenseModel> results = await _databaseService.searchExpensesByNote(query);
      setState(() {
        _searchResults = results;
        _isSearching = false;
        _calculateTotals();
      });
    } catch (e) {
      print("Error searching: $e");
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _calculateTotals() {
    double expenses = 0;
    double income = 0;

    for (var item in _searchResults) {
      if (item.isExpense) {
        expenses += item.amount;
      } else {
        income += item.amount;
      }
    }

    setState(() {
      _expenseTotal = expenses;
      _incomeTotal = income;
      _netTotal = income - expenses;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.orange),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Tìm kiếm',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildSearchField(),
          _buildSummarySection(),
          _buildToggleButtons(),
          _isSearching
              ? Expanded(
            child: Center(
              child: CircularProgressIndicator(color: Colors.orange),
            ),
          )
              : Expanded(
            child: _searchResults.isEmpty && _searchController.text.isEmpty
                ? Center(
              child: Text(
                'Nhập từ khóa để tìm kiếm giao dịch',
                style: TextStyle(color: Colors.grey),
              ),
            )
                : _searchResults.isEmpty
                ? Center(
              child: Text(
                'Không tìm thấy kết quả',
                style: TextStyle(color: Colors.grey),
              ),
            )
                : _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Tìm kiếm ghi chú...',
          prefixIcon: Icon(Icons.search, color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildSummaryItem('Chi tiêu', '${NumberFormat('#,###').format(_expenseTotal)}đ', Colors.blue.shade100),
          _buildSummaryItem('Thu nhập', '${NumberFormat('#,###').format(_incomeTotal)}đ', Colors.pink.shade100),
          _buildSummaryItem(
              'Chênh lệch',
              '${_netTotal >= 0 ? '' : '-'}${NumberFormat('#,###').format(_netTotal.abs())}đ',
              _netTotal >= 0 ? Colors.green.shade100 : Colors.red.shade100
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String title, String amount, Color backgroundColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 12),
          ),
          Text(
            amount,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButtons() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _showExpenses = true;
              });
            },
            child: Container(
              height: 40,
              color: _showExpenses ? Colors.orange : Colors.grey.shade200,
              alignment: Alignment.center,
              child: Text(
                'Tiền chi',
                style: TextStyle(
                  color: _showExpenses ? Colors.white : Colors.black,
                  fontWeight: _showExpenses ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _showExpenses = false;
              });
            },
            child: Container(
              height: 40,
              color: !_showExpenses ? Colors.orange : Colors.grey.shade200,
              alignment: Alignment.center,
              child: Text(
                'Tiền thu',
                style: TextStyle(
                  color: !_showExpenses ? Colors.white : Colors.black,
                  fontWeight: !_showExpenses ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    // Filter by expense or income based on toggle
    List<ExpenseModel> filteredResults = _searchResults
        .where((item) => item.isExpense == _showExpenses)
        .toList();

    if (filteredResults.isEmpty) {
      return Center(
        child: Text(
          'Không có ${_showExpenses ? 'khoản chi' : 'khoản thu'} nào phù hợp',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: filteredResults.length,
      itemBuilder: (context, index) {
        final item = filteredResults[index];
        return Container(
          margin: EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                IconData(int.parse(item.categoryIcon), fontFamily: 'MaterialIcons'),
                color: item.isExpense ? Colors.red : Colors.green,
              ),
            ),
            title: Text(
              item.category,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.note),
                Text(DateFormat('dd/MM/yyyy').format(item.date)),
              ],
            ),
            trailing: Text(
              '${NumberFormat('#,###').format(item.amount)} VND',
              style: TextStyle(
                color: item.isExpense ? Colors.red : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}