import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ymuh_app/theme/app_color.dart';

class TelephoneBar extends StatelessWidget {
  const TelephoneBar({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.PRIMARY_COLOR,
      width: double.infinity,
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SvgPicture.asset('assets/images/ic_telephone.svg'),
          SizedBox(width: 19),
          Text('總機電話專線 : (03)932-5192', style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
