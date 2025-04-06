import 'package:flutter/material.dart';

class AppBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabSelected;

  const AppBottomNavigationBar({
    Key? key,
    required this.currentIndex,
    required this.onTabSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      selectedItemColor: Colors.orangeAccent,
      unselectedItemColor: Colors.grey,
      backgroundColor: Colors.grey[200],
      onTap: (index) {
        if (index != currentIndex) {
          onTabSelected(index);
        }
      },
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.edit),
          label: "Nhập vào",
          activeIcon: currentIndex == 0
              ? Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            padding: EdgeInsets.all(10),
            child: Icon(Icons.edit, color: Colors.orangeAccent),
          )
              : null,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: "Lịch",
          activeIcon: currentIndex == 1
              ? Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            padding: EdgeInsets.all(10),
            child: Icon(Icons.calendar_today, color: Colors.orangeAccent),
          )
              : null,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.pie_chart),
          label: "Báo cáo",
          activeIcon: currentIndex == 2
              ? Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            padding: EdgeInsets.all(10),
            child: Icon(Icons.pie_chart, color: Colors.orangeAccent),
          )
              : null,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.more_horiz),
          label: "Khác",
          activeIcon: currentIndex == 3
              ? Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            padding: EdgeInsets.all(10),
            child: Icon(Icons.more_horiz, color: Colors.orangeAccent),
          )
              : null,
        ),
      ],
    );
  }
}