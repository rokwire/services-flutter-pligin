/*
 * Copyright 2020 Board of Trustees of the University of Illinois.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Onboarding.dart';
import 'package:illinois/ui/widgets/RoundedButton.dart';
import 'package:illinois/ui/widgets/SwipeDetector.dart';
import 'package:illinois/ui/onboarding/OnboardingBackButton.dart';
import 'package:illinois/service/Styles.dart';

class OnboardingPrivacyStatementPanel extends StatelessWidget with OnboardingPanel {

  final Map<String, dynamic> onboardingContext;
  OnboardingPrivacyStatementPanel({this.onboardingContext});

  @override
  Widget build(BuildContext context) {
    String titleText = Localization().getStringEx('panel.onboarding.privacy.label.title', 'We care about your privacy');
    String descriptionText = Localization().getStringEx('panel.onboarding.privacy.label.description', 'We only ask for personal information when we can use it to enhance your experience by enabling more features.');
    return Scaffold(
        backgroundColor: Styles().colors.background,
        body: SwipeDetector(
            onSwipeLeft: () => _goNext(context),
            onSwipeRight: () => _goBack(context),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Stack(children: <Widget>[
                  Image.asset(
                    "images/privacy-header.png",
                    fit: BoxFit.fitWidth,
                    width: MediaQuery
                        .of(context)
                        .size
                        .width,
                    excludeFromSemantics: true,
                  ),
                  OnboardingBackButton(
                      padding: const EdgeInsets.only(left: 10, top: 30, right: 20, bottom: 20),
                      onTap:() {
                        Analytics.instance.logSelect(target: "Back");
                        _goBack(context);
                      }),
                ],),
                Semantics(
                  label: titleText,
                  hint: Localization().getStringEx('panel.onboarding.privacy.label.title.hint', ''),
                  excludeSemantics: true,
                  child: Padding(
                      padding: EdgeInsets.only(
                          left: 40, right: 40, top: 21, bottom: 12),
                      child: Align(
                        alignment: Alignment.center,
                        child: Text(
                          titleText,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontFamily: Styles().fontFamilies.bold,
                              fontSize: 32,
                              color: Styles().colors.fillColorPrimary),
                        ),
                      )),
                ),
                Semantics(
                    label: descriptionText,
                    excludeSemantics: true,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Align(
                          alignment: Alignment.topCenter,
                          child: Text(
                            descriptionText,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontFamily: Styles().fontFamilies.regular,
                                fontSize: 20,
                                color: Styles().colors.fillColorPrimary),
                          )),
                    )),
                Expanded(child: Container(),),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.only(
                            bottom: 24),
                        child: RoundedButton(
                          label: Localization().getStringEx('panel.onboarding.privacy.button.continue.title', 'Set your privacy level'),
                          hint: Localization().getStringEx('panel.onboarding.privacy.button.continue.hint', ''),
                          backgroundColor: Styles().colors.background,
                          borderColor: Styles().colors.fillColorSecondaryVariant,
                          textColor: Styles().colors.fillColorPrimary,
                          onTap: () => _goNext(context),
                        ),),
                    ],
                  ),
                ),
              ],
            )));
  }


  void _goNext(BuildContext context) {
    return Onboarding().next(context, this);
  }

  void _goBack(BuildContext context) {
    Navigator.of(context).pop();
  }
}
