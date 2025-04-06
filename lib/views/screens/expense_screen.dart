import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/expense_viewmodel.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/message_utils.dart';
import '../../views/widgets/app_bottom_navigation_bar.dart';
import '../../views/widgets/custom_date_picker.dart'; // Import widget chọn lịch chung

class ExpenseScreen extends StatefulWidget {
  @override
  _ExpenseScreenState createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  // Controllers
  final TextEditingController noteController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController categoryNameController = TextEditingController();

  // State variables
  int selectedTab = 0; // 0: Expense, 1: Income
  DateTime selectedDate = DateTime.now();
  String selectedCategory = "";
  String selectedCategoryIcon = "";
  IconData? selectedIconForNewCategory;

  @override
  void initState() {
    super.initState();

    // Initialize view model once the widget is inserted into the tree
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final expenseViewModel = Provider.of<ExpenseViewModel>(
          context, listen: false);
      expenseViewModel.loadCategories();
    });
  }

  @override
  void dispose() {
    noteController.dispose();
    amountController.dispose();
    categoryNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Access the ExpenseViewModel
    final expenseViewModel = Provider.of<ExpenseViewModel>(context);

    // Get category lists from view model
    final expenseCategories = expenseViewModel.expenseCategories;
    final incomeCategories = expenseViewModel.incomeCategories;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: _buildToggleTab(),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.black),
            onPressed: () {
              Navigator.pushNamed(context, '/search');
            },
          ),
        ],
      ),
      body: expenseViewModel.isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.orange))
          : Padding(
        padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!expenseViewModel.isEditMode)
            // Sử dụng widget chọn lịch chung
              CustomDatePicker(
                selectedDate: selectedDate,
                onDateChanged: (date) {
                  setState(() {
                    selectedDate = date;
                  });
                },
                backgroundColor: Colors.white,
                textColor: Colors.black,
                showBorder: true,
              ),
            SizedBox(height: 10),
            if (!expenseViewModel.isEditMode) _buildExpenseFields(),
            if (!expenseViewModel.isEditMode) SizedBox(height: 10),
            if (expenseViewModel.isEditMode)
              _buildCategoryEditor(expenseViewModel)
            else
              expenseCategories.isEmpty || incomeCategories.isEmpty
                  ? Center(child: Text("Đang tải danh mục..."))
                  : Expanded(child: _buildCategoryGrid(expenseViewModel)),
            SizedBox(height: 20),
            if (!expenseViewModel.isEditMode) _buildSubmitButton(
                expenseViewModel),
          ],
        ),
      ),
      floatingActionButton: expenseViewModel.isEditMode ? FloatingActionButton(
        backgroundColor: Colors.orange,
        child: Icon(Icons.check, color: Colors.white),
        onPressed: () {
          expenseViewModel.toggleEditMode();
        },
      ) : null,
      bottomNavigationBar: AppBottomNavigationBar(
        currentIndex: 0, // 0 for ExpenseScreen
        onTabSelected: (index) {
          switch (index) {
            case 0:
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/calendar');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/report');
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/more');
              break;
          }
        },
      ),
    );
  }

  Widget _buildToggleTab() {
    return Container(
      height: 36,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTabButton("Tiền chi", 0),
          SizedBox(width: 8),
          _buildTabButton("Tiền thu", 1),
        ],
      ),
    );
  }

  Widget _buildTabButton(String text, int index) {
    bool isSelected = selectedTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedTab = index;
            selectedCategory = "";
            selectedCategoryIcon = "";
          });
        },
        child: Container(
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Color(0xFFFF8B55) : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpenseFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ghi chú
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 70,
                child: Text(
                  "Ghi chú",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: noteController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                        vertical: 8, horizontal: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12),

        // Tiền chi/thu with dynamic currency symbol
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 70,
                child: Text(
                  "Tiền ${selectedTab == 0 ? 'chi' : 'thu'}",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: amountController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.left,
                          style: TextStyle(fontSize: 18),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: "0",
                          ),
                          inputFormatters: [
                            CurrencyInputFormatter(),
                          ],
                        ),
                      ),
                      Text(getCurrentSymbol(), style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryGrid(ExpenseViewModel viewModel) {
    List<Map<String, dynamic>> categories = selectedTab == 0
        ? viewModel.expenseCategories
        : viewModel.incomeCategories;

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        bool isSelected = selectedCategory == categories[index]["label"];
        bool isEditButton = categories[index]["label"] == "Chỉnh sửa";

        return GestureDetector(
          onTap: () {
            if (isEditButton) {
              viewModel.toggleEditMode();
            } else {
              setState(() {
                selectedCategory = categories[index]["label"];
                selectedCategoryIcon =
                    (categories[index]["icon"] as IconData).codePoint
                        .toString();
              });
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: isSelected ? Colors.orange : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  categories[index]["icon"],
                  size: 40,
                  color: isSelected || isEditButton ? Colors.orange : Colors
                      .grey,
                ),
                SizedBox(height: 5),
                Text(
                  categories[index]["label"],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected || isEditButton ? Colors.orange : Colors
                        .black,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryEditor(ExpenseViewModel viewModel) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Chỉnh sửa danh mục ${selectedTab == 0 ? 'Chi tiêu' : 'Thu nhập'}",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),

          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      "Thêm danh mục mới",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16
                      )
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: categoryNameController,
                          decoration: InputDecoration(
                            hintText: "Tên danh mục",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),

                      GestureDetector(
                        onTap: _showIconSelector,
                        child: Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey.shade100,
                          ),
                          child: Center(
                            child: selectedIconForNewCategory != null
                                ? Icon(selectedIconForNewCategory,
                                size: 32,
                                color: Colors.orange)
                                : Icon(Icons.add_circle_outline,
                                size: 32,
                                color: Colors.orange),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),

                      ElevatedButton(
                        onPressed: () => _addNewCategory(viewModel),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 16
                          ),
                        ),
                        child: Text(
                          "Thêm",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 16),

          Text(
              "Danh sách danh mục hiện tại:",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16
              )
          ),

          SizedBox(height: 8),

          Expanded(
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ReorderableListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: selectedTab == 0
                      ? viewModel.expenseCategories.length
                      : viewModel.incomeCategories.length,
                  itemBuilder: (context, index) {
                    final category = selectedTab == 0
                        ? viewModel.expenseCategories[index]
                        : viewModel.incomeCategories[index];

                    bool isEditCategory = category["label"] == "Chỉnh sửa";

                    return ListTile(
                      key: ValueKey(category["label"]),
                      leading: Icon(
                          category["icon"],
                          size: 30,
                          color: isEditCategory ? Colors.grey : Colors.orange
                      ),
                      title: Text(
                        category["label"],
                        style: TextStyle(
                          color: isEditCategory ? Colors.grey : Colors.black,
                        ),
                      ),
                      trailing: isEditCategory
                          ? null
                          : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                                Icons.delete,
                                color: Colors.red
                            ),
                            onPressed: () => _deleteCategory(viewModel, index),
                          ),
                          ReorderableDragStartListener(
                            index: index,
                            child: Icon(
                                Icons.drag_handle,
                                color: Colors.grey
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  onReorder: (int oldIndex, int newIndex) {
                    viewModel.reorderCategory(
                        oldIndex,
                        newIndex,
                        selectedTab == 0
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(ExpenseViewModel viewModel) {
    return Center(
      child: ElevatedButton(
        onPressed: viewModel.isLoading ? null : () => _saveExpense(viewModel),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          padding: EdgeInsets.symmetric(horizontal: 50, vertical: 12),
        ),
        child: viewModel.isLoading
            ? SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : Text(
          "Nhập khoản tiền ${selectedTab == 0 ? 'chi' : 'thu'}",
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }

  // Show icon selector dialog
  void _showIconSelector() {
    final viewModel = Provider.of<ExpenseViewModel>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Chọn icon"),
          backgroundColor: Colors.white,
          content: Container(
            width: double.maxFinite,
            height: 300,
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: viewModel.icons.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedIconForNewCategory = viewModel.icons[index];
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(viewModel.icons[index], size: 30),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Hủy"),
            ),
          ],
        );
      },
    );
  }


// Add a new category
  Future<void> _addNewCategory(ExpenseViewModel viewModel) async {
    if (categoryNameController.text.isEmpty ||
        selectedIconForNewCategory == null) {
      MessageUtils.showErrorMessage(
          context, "Vui lòng nhập tên danh mục và chọn biểu tượng!");
      return;
    }

    final success = await viewModel.addCategory(
        categoryNameController.text.trim(),
        selectedIconForNewCategory!,
        selectedTab == 0 // true for expense, false for income
    );

    if (!success) {
      // Nếu thêm không thành công, hiển thị lỗi từ ViewModel
      if (viewModel.errorMessage != null) {
        MessageUtils.showErrorMessage(context, viewModel.errorMessage!);
      }
    } else {
      setState(() {
        categoryNameController.clear();
        selectedIconForNewCategory = null;
      });
      MessageUtils.showSuccessMessage(
          context, "Đã thêm danh mục mới thành công");
    }
  }

  // Delete a category
  Future<void> _deleteCategory(ExpenseViewModel viewModel, int index) async {
    final confirmed = await MessageUtils.showConfirmationDialog(
      context: context,
      title: "Xác nhận xóa",
      message: "Bạn có chắc chắn muốn xóa danh mục này không?",
      confirmLabel: "Xóa",
      cancelLabel: "Hủy",
    );

    if (confirmed == true) {
      final success = await viewModel.deleteCategory(
          index,
          selectedTab == 0 // true for expense, false for income
      );

      if (success) {
        MessageUtils.showSuccessMessage(context, "Đã xóa danh mục thành công");
      }
    }
  }

  // Save expense
  Future<void> _saveExpense(ExpenseViewModel viewModel) async {
    if (amountController.text.isEmpty || selectedCategory.isEmpty) {
      MessageUtils.showErrorMessage(
          context, "Vui lòng nhập số tiền và chọn danh mục!");
      return;
    }

    double amount = parseFormattedCurrency(amountController.text);
    if (amount <= 0) {
      MessageUtils.showErrorMessage(context, "Số tiền phải lớn hơn 0!");
      return;
    }

    // Convert to storage currency (VND)
    double amountInVND = convertToVND(amount);

    final success = await viewModel.addTransaction(
      note: noteController.text,
      amount: amountInVND,
      category: selectedCategory,
      categoryIcon: selectedCategoryIcon,
      date: selectedDate,
      isExpense: selectedTab == 0,
    );

    if (success) {
      // Reset form
      setState(() {
        noteController.clear();
        amountController.clear();
        selectedCategory = "";
        selectedCategoryIcon = "";
      });

      MessageUtils.showSuccessMessage(
          context,
          selectedTab == 0
              ? "Đã lưu khoản chi thành công!"
              : "Đã lưu khoản thu thành công!"
      );
    }
  }
}