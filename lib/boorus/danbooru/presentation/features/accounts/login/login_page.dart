// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_html/style.dart';
import 'package:easy_localization/easy_localization.dart';

// Project imports:
import 'widgets/login_box_widget.dart';

class LoginPage extends StatefulWidget {
  LoginPage({Key key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          elevation: 0.0,
          shadowColor: Colors.transparent,
        ),
        resizeToAvoidBottomInset: false,
        body: Column(
          children: <Widget>[
            Text(
              'login.form.greeting'.tr(),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: Colors.white70,
                fontSize: FontSize.xLarge.size,
              ),
            ),
            Center(
              child: LoginBox(),
            )
          ],
        ),
      ),
    );
  }
}
