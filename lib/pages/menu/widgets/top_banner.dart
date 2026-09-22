import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ymuh_app/theme/app_color.dart';

class TopBanner extends StatelessWidget {
  const TopBanner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: AppColors.hex('#F39800'),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.hex('#CCCCCC'),
            offset: Offset(3, 5), //陰影y軸偏移量
            blurRadius: 3, //陰影模糊程度
            spreadRadius: 1, //陰影擴散程度
          )
        ],
      ),
      margin: EdgeInsets.only(top: 22, left: 25, right: 25),
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          RichText(
            text: TextSpan(
                text: '您好,\n',
                style: TextStyle(fontSize: 15, height: 2, color: Colors.black),
                children: [TextSpan(text: '今日想預約什麼門診呢 !')]),
          ),
          SafeArea(child: SvgPicture.asset('assets/images/menu_top_reserve.svg'))
        ],
      ),
    );
  }
}
