import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

// 1. Tạo định dạng tiền tệ dùng chung
final NumberFormat formatCurrency = NumberFormat('#,###', 'vi_VN');

// 2. Tạo widget định dạng input tiền tệ
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Xóa tất cả ký tự không phải số
    String newText = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    // Chuyển đổi thành số
    if (newText.isEmpty) {
      return TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    int value = int.parse(newText);
    String formattedText = formatCurrency.format(value);

    // Đặt lại vị trí con trỏ
    int cursorPosition = formattedText.length;
    if (newValue.selection.start > 0) {
      // Tính toán vị trí con trỏ dựa trên sự thay đổi về độ dài
      int oldLength = oldValue.text.length;
      int newLength = formattedText.length;
      int oldPosition = oldValue.selection.start;

      // Nếu xóa ký tự
      if (oldLength > newLength && oldPosition > 0) {
        cursorPosition = oldPosition - (oldLength - newLength);
      }
      // Nếu thêm ký tự
      else if (newLength > oldLength) {
        cursorPosition = oldPosition + (newLength - oldLength);
      }
      // Giữ nguyên vị trí
      else {
        cursorPosition = oldPosition;
      }

      // Đảm bảo vị trí con trỏ nằm trong phạm vi văn bản
      cursorPosition = cursorPosition.clamp(0, formattedText.length);
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: cursorPosition),
    );
  }
}

// 3. Hàm chuyển đổi từ chuỗi định dạng tiền tệ sang số
double parseFormattedCurrency(String formattedAmount) {
  if (formattedAmount.isEmpty) return 0;
  // Loại bỏ tất cả dấu ngăn cách và ký tự không phải số
  String numericString = formattedAmount.replaceAll(RegExp(r'[^\d]'), '');
  return numericString.isEmpty ? 0 : double.parse(numericString);
}

// 4. Hàm định dạng số thành chuỗi tiền tệ có đơn vị - Đã sửa lỗi
String formatCurrencyWithSymbol(double amount) {
  try {
    // Làm tròn đến số nguyên để tránh lỗi
    int roundedAmount = amount.round();
    // Định dạng số với dấu chấm phân cách hàng nghìn
    String formattedAmount = formatCurrency.format(roundedAmount);
    // Thêm đơn vị tiền tệ
    return '$formattedAmount đ';
  } catch (e) {
    print("Lỗi khi định dạng tiền tệ: $e");
    // Trả về một giá trị mặc định nếu có lỗi
    return '0 đ';
  }
}

// 5. Phiên bản bổ sung hỗ trợ định dạng số âm
String formatCurrencyWithSign(double amount) {
  String sign = amount >= 0 ? "+" : "-";
  return '$sign${formatCurrencyWithSymbol(amount.abs())}';
}