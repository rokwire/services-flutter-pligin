/*
 * Copyright 2023 Board of Trustees of the University of Illinois.
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

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:rokwire_plugin/model/actions.dart';
import 'package:rokwire_plugin/model/rules.dart';
import 'package:rokwire_plugin/model/survey.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/service/surveys.dart';
import 'package:rokwire_plugin/ui/panels/survey_panel.dart';
import 'package:rokwire_plugin/ui/panels/survey_data_creation_panel.dart';
import 'package:rokwire_plugin/ui/popups/popup_message.dart';
import 'package:rokwire_plugin/ui/widget_builders/loading.dart';
import 'package:rokwire_plugin/ui/widgets/form_field.dart';
import 'package:rokwire_plugin/ui/widgets/header_bar.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';

class SurveyCreationPanel extends StatefulWidget {
  final Widget? tabBar;
  final Widget? offlineWidget;

  const SurveyCreationPanel({Key? key, this.tabBar, this.offlineWidget}) : super(key: key);

  @override
  _SurveyCreationPanelState createState() => _SurveyCreationPanelState();
}

class _SurveyCreationPanelState extends State<SurveyCreationPanel> {
  GlobalKey? dataKey;

  bool _loading = false;
  final ScrollController _scrollController = ScrollController();
  late final Map<String, TextEditingController> _textControllers;

  final List<SurveyData> _data = [];
  bool _scored = true;
  // bool _sensitive = false;

  final Map<String, String> _constants = {};
  final Map<String, Map<String, String>> _strings = {};

  Rule? _defaultDataKeyRule;
  List<Rule>? _resultRules;
  final Map<String, Rule> _subRules = {};
  List<String>? _responseKeys;

  final Map<String, String> _supportedLangs = {};

  @override
  void initState() {
    _textControllers = {
      "title": TextEditingController(),
      "more_info": TextEditingController(),
      "type": TextEditingController(),
      "default_data_key": TextEditingController(),
    };
    super.initState();
  }

  @override
  void dispose() {
    _textControllers.forEach((_, value) { value.dispose(); });

    for (String lang in Localization().defaultSupportedLanguages) {
      _supportedLangs[lang] = lang;
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const HeaderBar(title: "Create Survey"),
      bottomNavigationBar: widget.tabBar,
      backgroundColor: Styles().colors?.background,
      body: Column(
        children: [
          Expanded(child: Scrollbar(
            radius: const Radius.circular(2),
            thumbVisibility: true,
            controller: _scrollController,
            child: SingleChildScrollView(
              controller: _scrollController,
              child: _buildSurveyCreationTools(),
            ),
          )),
          Container(
            color: Styles().colors?.backgroundVariant,
            child: _buildPreviewAndContinue(),
          ),
        ],
    ));
  }

  Widget _buildSurveyCreationTools() {
    return Column(children: [
      // title
      FormFieldText('Title', controller: _textControllers["title"], inputType: TextInputType.text, textCapitalization: TextCapitalization.words, required: true),
      // more_info
      FormFieldText('Additional Information', controller: _textControllers["more_info"], multipleLines: true, inputType: TextInputType.text, textCapitalization: TextCapitalization.sentences),
      // survey type (make this a dropdown?)
      FormFieldText('Type', controller: _textControllers["type"], multipleLines: false, inputType: TextInputType.text, textCapitalization: TextCapitalization.words, required: true),

      // data
      _buildCollapsibleWrapper("Survey Data", "data", _data.length, _buildSurveyDataWidget),

      // scored
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text("Scored", style: Styles().textStyles?.getTextStyle('fillColorSecondary')),
        Checkbox(
          checkColor: Styles().colors?.surface,
          activeColor: Styles().colors?.fillColorPrimary,
          value: _scored,
          onChanged: _onToggleScored,
        ),
      ],),
      
      // sensitive
      // Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      //   Text("Scored", style: Styles().textStyles?.getTextStyle('fillColorSecondary')),
      //   Checkbox(
      //     checkColor: Styles().colors?.surface,
      //     activeColor: Styles().colors?.fillColorPrimary,
      //     value: _sensitive,
      //     onChanged: _onToggleSensitive,
      //   ),
      // ],),

      // default data key (i.e., first "question") -> assume first data widget represents first question
      FormFieldText('First Item', controller: _textControllers["default_data_key"], multipleLines: false, inputType: TextInputType.text,),

      // default data key rule (i.e., rule for determining first "question") -> checkbox to use rule to determine first question, when checked shows UI to create rule
      _buildRuleWidget(0, "default_data_key_rule"),

      // constants
      // _buildCollapsibleWrapper("Constants", "constants", _constants.length, _buildStringMapEntryWidget),
      // strings
      // _buildCollapsibleWrapper("Strings", "strings", _strings.length, _buildStringMapWidget),
      // result_rules
      // _buildCollapsibleWrapper("Result Rules", "result_rules", _resultRules?.length ?? 0, _buildRuleWidget),
      // sub_rules
      // _buildCollapsibleWrapper("Sub Rules", "sub_rules", _subRules.length, _buildRuleWidget), //TODO: rule map widget
      // response_keys
      // _buildCollapsibleWrapper("Response Keys", "response_keys", _responseKeys?.length ?? 0, _buildStringListEntryWidget),
    ],);
  }

  Widget _buildPreviewAndContinue() {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.end, children: [
      Flexible(flex: 1, child: Padding(padding: const EdgeInsets.all(4.0), child: RoundedButton(
        label: 'Preview',
        borderColor: Styles().colors?.fillColorPrimaryVariant,
        backgroundColor: Styles().colors?.surface,
        textStyle: Styles().textStyles?.getTextStyle('widget.detail.large.fat'),
        onTap: _onTapPreview,
      ))),
      Flexible(flex: 1, child: Padding(padding: const EdgeInsets.all(4.0), child: Stack(children: [
        Visibility(visible: _loading, child: LoadingBuilder.loading()),
        RoundedButton(
          label: 'Continue',
          borderColor: Styles().colors?.fillColorSecondary,
          backgroundColor: Styles().colors?.surface,
          textStyle: Styles().textStyles?.getTextStyle('widget.detail.large.fat'),
          onTap: _onTapContinue,
        ),
      ]))),
    ],);
  }

  Widget _buildCollapsibleWrapper(String label, String textGroup, int dataLength, Widget Function(int, String) listItemBuilder) {
    return Ink(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(4.0), color: Styles().colors?.getColor('surface')),
      child: ExpansionTile(
        iconColor: Styles().colors?.getColor('fillColorSecondary'),
        backgroundColor: Styles().colors?.getColor('surface'),
        collapsedBackgroundColor: Styles().colors?.getColor('surface'),
        title: Text(
          label,
          style: Styles().textStyles?.getTextStyle('widget.detail.regular'),
        ),
        children: <Widget>[
          Container(height: 2, color: Styles().colors?.getColor('fillColorSecondary'),),
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxHeight: 500
            ),
            child: dataLength > 0 ? Scrollbar(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: dataLength,
                itemBuilder: (BuildContext context, int index) {
                  return Column(
                    children: [
                      listItemBuilder(index, textGroup),
                      Container(height: 1, color: Styles().colors?.getColor('dividerLine'),),
                    ],
                  );
                },
              ),
            ) : _buildAddRemoveButtons(0, textGroup),
          ),
        ],
      ),
    );
  }

  Widget _buildSurveyDataWidget(int index, String textGroup) {
    return Ink(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(4.0), color: Styles().colors?.getColor('surface')),
      child: Row(children: [
        Flexible(flex: 2, child: Text(
          _data[index].key,
          style: Styles().textStyles?.getTextStyle('widget.detail.regular'),
        )),
        Flexible(flex: 1, child: Padding(padding: const EdgeInsets.all(4.0), child: RoundedButton(
          label: 'Edit',
          borderColor: Styles().colors?.fillColorPrimaryVariant,
          backgroundColor: Styles().colors?.surface,
          textStyle: Styles().textStyles?.getTextStyle('widget.detail.large.fat'),
          onTap: () => _onTapEditData(index),
        ))),
        Flexible(flex: 1, child: _buildAddRemoveButtons(index + 1, textGroup)),
      ],)
    );
  }

  Widget _buildRuleWidget(int index, String textGroup) {
    //RuleCondition
      //RuleComparison
      //RuleLogic
    //RuleResult
      //Rule
      //RuleReference
      //RuleActionResult
        //RuleAction
        //RuleActionList

    // condition = 
    // {
    //   "operator": "",
    //   "conditions": [
            // condition
    //   ]
    // } OR
    // {
    //   'operator': "",
    //   'data_key': "",
    //   'data_param': "",
    //   'compare_to': "",
    //   'compare_to_param': "",
    //   'default_result': "",
    // }
      //TODO
  // 
  // RuleAction.supportedActions
  // RuleComparison.supportedOperators
  // RuleLogic.supportedOperators
    
          // dropdown for actions
          // dropdown for comparison options
          // dropdown for logic options
          // dropdown for data keys, compare_to options (stats, responses, constants, strings, etc.)
    //TODO
    return Container();
  }

  Widget _buildStringListEntryWidget(int index, String textGroup) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      FormFieldText('Value', controller: _textControllers["$textGroup$index.value"], inputType: TextInputType.text, required: true),
      _buildAddRemoveButtons(index + 1, textGroup),
    ]);
  }

  Widget _buildStringMapEntryWidget(int index, String textGroup) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      FormFieldText('Key', controller: _textControllers["$textGroup$index.key"], inputType: TextInputType.text, required: true),
      FormFieldText('Value', controller: _textControllers["$textGroup$index.value"], inputType: TextInputType.text, required: true),
      _buildAddRemoveButtons(index + 1, textGroup),
    ]);
  }

  Widget _buildStringMapWidget(int index, String textGroup) {
    return Ink(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(4.0), color: Styles().colors?.getColor('surface')),
      child: ExpansionTile(
        iconColor: Styles().colors?.getColor('fillColorSecondary'),
        backgroundColor: Styles().colors?.getColor('surface'),
        collapsedBackgroundColor: Styles().colors?.getColor('surface'),
        title: Text(
          "Language Strings",
          style: Styles().textStyles?.getTextStyle('widget.detail.regular'),
        ),
        leading: DropdownButtonHideUnderline(child:
          DropdownButton<String>(
            icon: Styles().images?.getImage('chevron-down', excludeFromSemantics: true),
            isExpanded: true,
            style: Styles().textStyles?.getTextStyle('widget.detail.regular'),
            items: _buildSurveyDropDownItems<String>(_supportedLangs),
            value: index < _strings.length ? _strings.keys.elementAt(index) : Localization().defaultSupportedLanguages.first,
            onChanged: (value) => _onChangeStringsLanguage(index, value),
            dropdownColor: Styles().colors?.textBackground,
          ),
        ),
        trailing: _buildAddRemoveButtons(index + 1, textGroup),
        children: <Widget>[
          Container(height: 2, color: Styles().colors?.getColor('fillColorSecondary'),),
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxHeight: 500
            ),
            child: _strings[_strings.keys.elementAt(index)]?.isNotEmpty ?? false ? Scrollbar(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _strings[_strings.keys.elementAt(index)]!.length,
                itemBuilder: (BuildContext context, int index) {
                  return Column(
                    children: [
                      _buildStringMapEntryWidget(index, "${_strings.keys.elementAt(index)}.$textGroup"),
                      Container(height: 1, color: Styles().colors?.getColor('dividerLine'),),
                    ],
                  );
                },
              ),
            ) : _buildAddRemoveButtons(0, textGroup),
          ),
        ],
      ),
    );
  }

  Widget _buildAddRemoveButtons(int index, String textGroup) {
    return Row(mainAxisAlignment: MainAxisAlignment.end, mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
      IconButton(
        icon: Styles().images?.getImage('plus-circle', color: Styles().colors?.getColor('fillColorPrimary')) ?? const Icon(Icons.add),
        onPressed: () => _onTapAddDataAtIndex(index, textGroup),
        padding: EdgeInsets.zero,
      ),
      IconButton(
        icon: Styles().images?.getImage('minus-circle', color: Styles().colors?.getColor('alert')) ?? const Icon(Icons.add),
        onPressed: () => _onTapRemoveDataAtIndex(index, textGroup),
        padding: EdgeInsets.zero,
      ),
    ]);
  }

  List<DropdownMenuItem<T>> _buildSurveyDropDownItems<T>(Map<T, String> supportedItems) {
    List<DropdownMenuItem<T>> items = [];

    for (MapEntry<T, String> item in supportedItems.entries) {
      items.add(DropdownMenuItem<T>(
        value: item.key,
        child: Align(alignment: Alignment.center, child: Text(item.value, style: Styles().textStyles?.getTextStyle('widget.detail.regular'), textAlign: TextAlign.center,)),
      ));
    }
    return items;
  }

  void _onTapEditData(int index) async {
    SurveyData updatedData = await Navigator.push(context, CupertinoPageRoute(builder: (context) => SurveyDataCreationPanel(data: _data[index], tabBar: widget.tabBar)));
    _updateState(() {
      _data[index] = updatedData;
    });
  }

  void _onTapAddDataAtIndex(int index, String textGroup, {int? dataIndex}) {
    if (mounted) {
      if (textGroup.contains("data")) {
        if (textGroup.contains("options")) {
          //TODO
        } else if (textGroup.contains("correct_answers")) {
          //TODO
        } else if (textGroup.contains("actions")) {
          //TODO
          // "params"
        } else {
          SurveyData insert;
          if (index > 0) {
            insert = SurveyData.fromOther(_data[index-1]);
            insert.key = "$textGroup${_data.length}";
            insert.text = "New survey data";
            insert.defaultFollowUpKey = index == _data.length ? null : _data[index].key;
          } else {
            insert = SurveyQuestionTrueFalse(text: "New True/False Question", key: "$textGroup${_data.length}");
          }
          setState(() {
            _data.insert(index, insert);
            if (index > 0 && _data[index-1].followUpRule == null) {
              _data[index-1].defaultFollowUpKey = "$textGroup${_data.length}";
            }
            //TODO: how to update follow up rules?
          });
        }
      } else if (textGroup.contains("constants")) {
        setState(() {
          _constants["$textGroup${_constants.length}"] = _constants["$textGroup${_constants.length - 1}"] ?? "";
        });
      } else if (textGroup.contains("strings")) {
        if (textGroup.contains(".")) {
          List<String> stringsKeys = textGroup.split(".");
          setState(() {
            _strings[stringsKeys[0]] ??= {};
            _strings[stringsKeys[0]]!["${stringsKeys[1]}${_strings[stringsKeys[0]]!.length}"] = _strings[stringsKeys[0]]!["${stringsKeys[1]}${_strings[stringsKeys[0]]!.length - 1}"] ?? "";
          });
        } else {
          for (String lang in Localization().defaultSupportedLanguages) {
            if (_strings[lang] == null) {
              setState(() {
                _strings[lang] = {};
              });
              break;
            }
          }
        }
      } else if (textGroup.contains("result_rules")) {
        setState(() {
          _resultRules ??= [];
          _resultRules!.insert(index, index > 0 ? Rule.fromOther(_resultRules![index-1]) : Rule());
        });
      } else if (textGroup.contains("sub_rules")) {
        setState(() {
          _subRules["$textGroup${_subRules.length}"] =  _subRules["$textGroup${_subRules.length - 1}"] ?? Rule();
        });
      } else if (textGroup.contains("response_keys")) {
        setState(() {
          _responseKeys ??= [];
          _responseKeys!.insert(index, index > 0 ? _responseKeys![index-1] : "");
        });
      }
    }
  }

  void _onTapRemoveDataAtIndex(int index, String textGroup) {
    //TODO
    // if (mounted) {
    //   SurveyData insert;
    //   if (index > 0) {
    //     insert = SurveyData.fromOther(_data[index-1]);
    //     insert.key = "$textGroup$index";
    //     insert.text = "New survey data";
    //     insert.defaultFollowUpKey = index == _data.length ? null : _data[index].key;
    //   } else {
    //     insert = SurveyQuestionTrueFalse(text: "New True/False Question", key: "$textGroup$index");
    //   }
    //   setState(() {
    //     _data.insert(index, insert);
    //     if (index > 0 && _data[index-1].followUpRule == null) {
    //       _data[index-1].defaultFollowUpKey = "$textGroup$index";
    //     }
    //     //TODO: how to update follow up rules?
    //   });
    // }
  }

  void _onChangeSurveyDataType(int index, String textGroup, String? type) {
    if (mounted) {
      setState(() {
        switch (type) {
          case "survey_data.true_false":
            _data[index] = SurveyQuestionTrueFalse(text: "New True/False Question", key: "$textGroup$index");
            break;
          case "survey_data.multiple_choice":
            _data[index] = SurveyQuestionMultipleChoice(text: "New Multiple Choice Question", key: "$textGroup$index", options: []);
            break;
          case "survey_data.date_time":
            _data[index] = SurveyQuestionDateTime(text: "New Date/Time Question", key: "$textGroup$index");
            break;
          case "survey_data.numeric":
            _data[index] = SurveyQuestionNumeric(text: "New Numeric Question", key: "$textGroup$index");
            break;
          case "survey_data.text":
            _data[index] = SurveyQuestionText(text: "New Text Question", key: "$textGroup$index");
            break;
          case "survey_data.result":
            _data[index] = SurveyDataResult(text: "New Info/Action", key: "$textGroup$index");
            break;
        }
      });
    }
  }

  void _onChangeSurveyDataStyle(int index) {
    //TODO
  }

  void _onChangeSurveyDataAction(int index) {
    //TODO
  }

  void _onChangeStringsLanguage(int index, String? value) {
    //TODO
  }

  void _onToggleScored(bool? value) {
    if (mounted) {
      setState(() {
        _scored = value ?? true;
      });
    }
  }

  // void _onToggleSensitive(bool? value) {
  //   if (mounted) {
  //     setState(() {
  //       _sensitive = value ?? false;
  //     });
  //   }
  // }

  void _onToggleRequired(bool? value, int index) {
    if (mounted) {
      setState(() {
        _data[index].allowSkip = value ?? false;
      });
    }
  }

  // void _onToggleReplace(bool? value, int index) {
  //   if (mounted) {
  //     setState(() {
  //       _data[index].replace = value ?? false;
  //     });
  //   }
  // }

  void _onToggleMultipleAnswers(bool? value, int index) {
    if (mounted) {
      setState(() {
        (_data[index] as SurveyQuestionMultipleChoice).allowMultiple = value ?? false;
      });
    }
  }

  void _onToggleSelfScore(bool? value, int index) {
    if (mounted) {
      setState(() {
        (_data[index] as SurveyQuestionMultipleChoice).selfScore = value ?? false;
      });
    }
  }
  
  Survey _buildSurvey() {
    return Survey(
      id: '',
      data: Map.fromIterable(_data, key: (item) => (item as SurveyData).key),
      type: _textControllers["type"]?.text ?? 'survey',
      scored: _scored,
      title: _textControllers["title"]?.text ?? 'New Survey',
      moreInfo: _textControllers["more_info"]?.text,
      defaultDataKey: _textControllers["default_data_key"]?.text ?? (_defaultDataKeyRule == null && _data.isNotEmpty ? _data.first.key : null),
      defaultDataKeyRule: _defaultDataKeyRule,
      resultRules: _resultRules,
      responseKeys: _responseKeys,
      constants: _constants,
      strings: _strings,
      subRules: _subRules,
    );
  }

  void _onTapPreview() {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => SurveyPanel(survey: _buildSurvey(), inputEnabled: false)));
  }

  void _onTapContinue() {
    setLoading(true);
    Surveys().createSurvey(_buildSurvey()).then((success) {
      setLoading(false);
      if (success != true) {
        PopupMessage.show(context: context,
          title: "Create Survey",
          message: "Survey creation failed",
          buttonTitle: Localization().getStringEx("dialog.ok.title", "OK")
        );
      }
    });
  }

  void setLoading(bool value) {
    if (mounted) {
      setState(() {
        _loading = value;
      });
    }
  }

  //TODO: use these for SurveyQuestionDateTime
  // void _onStartDateTap() {
  //   DateTime initialDate = _startDate ?? DateTime.now();
  //   DateTime firstDate =
  //   DateTime.fromMillisecondsSinceEpoch(initialDate.millisecondsSinceEpoch)
  //       .add(Duration(days: -365));
  //   DateTime lastDate =
  //   DateTime.fromMillisecondsSinceEpoch(initialDate.millisecondsSinceEpoch)
  //       .add(Duration(days: 365));
  //   showDatePicker(
  //     context: context,
  //     firstDate: firstDate,
  //     lastDate: lastDate,
  //     initialDate: initialDate,
  //     builder: (BuildContext context, Widget? child) {
  //       return Theme(
  //         data: ThemeData.light(),
  //         child: child!,
  //       );
  //     },
  //   ).then((selectedDateTime) => _onStartDateChanged(selectedDateTime));
  // }

  // void _onStartDateChanged(DateTime? startDate) {
  //   if(mounted) {
  //     setState(() {
  //       _startDate = startDate;
  //     });
  //   }
  // }

  // void _onTapPickReminderTime() {
  //   if (_loading) {
  //     return;
  //   }
  //   TimeOfDay initialTime = TimeOfDay(hour: _reminderDateTime.hour, minute: _reminderDateTime.minute);
  //   showTimePicker(context: context, initialTime: initialTime).then((resultTime) {
  //     if (resultTime != null) {
  //       _reminderDateTime =
  //           DateTime(_reminderDateTime.year, _reminderDateTime.month, _reminderDateTime.day, resultTime.hour, resultTime.minute);
  //       _updateState();
  //     }
  //   });
  // }

  void _updateState(Function() fn) {
    if (mounted) {
      setState(() {
        fn();
      });
    }
  }
}