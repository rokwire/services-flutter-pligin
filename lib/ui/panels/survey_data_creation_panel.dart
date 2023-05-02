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
import 'package:rokwire_plugin/model/options.dart';
import 'package:rokwire_plugin/model/rules.dart';
import 'package:rokwire_plugin/model/survey.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/panels/rule_element_creation_panel.dart';
import 'package:rokwire_plugin/ui/panels/survey_data_options_panel.dart';
import 'package:rokwire_plugin/ui/widgets/form_field.dart';
import 'package:rokwire_plugin/ui/widgets/header_bar.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/ui/widgets/survey_creation.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class SurveyDataCreationPanel extends StatefulWidget {
  final SurveyData data;
  final List<String> dataKeys;
  final List<String> dataTypes;
  final Widget? tabBar;
  final List<String?> sections;
  final bool scoredSurvey;

  const SurveyDataCreationPanel({Key? key, required this.data, required this.dataKeys, required this.dataTypes, required this.sections, required this.scoredSurvey, this.tabBar}) : super(key: key);

  @override
  _SurveyDataCreationPanelState createState() => _SurveyDataCreationPanelState();
}

class _SurveyDataCreationPanelState extends State<SurveyDataCreationPanel> {
  GlobalKey? dataKey;

  final ScrollController _scrollController = ScrollController();
  late final Map<String, TextEditingController> _textControllers;
  final List<String> _defaultTextControllers = ["key", "text", "more_info", "maximum_score"];

  late SurveyData _data;
  RuleResult? _defaultResponseRule;
  RuleResult? _scoreRule;
  final Map<String, String> _supportedActions = {};

  @override
  void initState() {
    _data = widget.data;
    for (ActionType action in ActionType.values) {
      _supportedActions[action.name] = action.name;
    }

    _textControllers = {
      "key": TextEditingController(text: _data.key),
      "text": TextEditingController(text: _data.text),
      "more_info": TextEditingController(text: _data.moreInfo),
      "maximum_score": TextEditingController(text: _data.maximumScore?.toString()),
    };

    if (_data.section != null && !widget.sections.contains(_data.section)) {
      _data.section = null;
    }

    super.initState();
  }

  @override
  void dispose() {
    _removeTextControllers();
    super.dispose();
  }

  void _removeTextControllers({bool keepDefaults = false}) {
    List<String> removedControllers = [];
    _textControllers.forEach((key, value) {
      if (!keepDefaults || !_defaultTextControllers.contains(key)) {
        value.dispose();
        removedControllers.add(key);
      }
    });

    for (String removed in removedControllers) {
      _textControllers.remove(removed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const HeaderBar(title: "Edit Survey Data"),
      bottomNavigationBar: widget.tabBar,
      backgroundColor: Styles().colors?.background,
      body: SurveyElementCreationWidget(body: _buildSurveyDataComponents(), completionOptions: _buildDone(), scrollController: _scrollController,)
    );
  }

  Widget _buildSurveyDataComponents() {
    List<Widget> dataContent = [];
    if (_data is SurveyQuestionTrueFalse) {
      // style
      String styleVal = (_data as SurveyQuestionTrueFalse).style ?? SurveyQuestionTrueFalse.supportedStyles.entries.first.key;
      dataContent.add(SurveyElementCreationWidget.buildDropdownWidget<String>(SurveyQuestionTrueFalse.supportedStyles, "Style", styleVal, _onChangeStyle));

      // correct answer (dropdown: Yes/True, No/False, null)
      Map<bool?, String> supportedAnswers = {null: "None", true: "Yes/True", false: "No/False"};
      dataContent.add(SurveyElementCreationWidget.buildDropdownWidget<bool?>(supportedAnswers, "Correct Answer", (_data as SurveyQuestionTrueFalse).correctAnswer, _onChangeCorrectAnswer));
    } else if (_data is SurveyQuestionMultipleChoice) {
      // style
      String styleVal = (_data as SurveyQuestionMultipleChoice).style ?? SurveyQuestionMultipleChoice.supportedStyles.entries.first.key;
      dataContent.add(SurveyElementCreationWidget.buildDropdownWidget<String>(SurveyQuestionMultipleChoice.supportedStyles, "Style", styleVal, _onChangeStyle));

      // options
      List<OptionData> options = (_data as SurveyQuestionMultipleChoice).options;
      dataContent.add(Padding(padding: const EdgeInsets.only(top: 16.0), child: SurveyElementList(
        type: SurveyElementListType.options,
        label: 'Options (${options.length})',
        dataList: options,
        surveyElement: SurveyElement.data,
        onAdd: _onTapAdd,
        onEdit: _onTapEdit,
        onRemove: _onTapRemove,
        onDrag: _onAcceptDataDrag,
      )));
      
      // allowMultiple
      dataContent.add(SurveyElementCreationWidget.buildCheckboxWidget("Multiple Answers", (_data as SurveyQuestionMultipleChoice).allowMultiple, _onToggleMultipleAnswers));
      
      // selfScore
      dataContent.add(SurveyElementCreationWidget.buildCheckboxWidget("Self-Score", (_data as SurveyQuestionMultipleChoice).selfScore, _onToggleSelfScore));
    } else if (_data is SurveyQuestionDateTime) {
      _textControllers["start_time"] ??= TextEditingController(text: DateTimeUtils.localDateTimeToString((_data as SurveyQuestionDateTime).startTime, format: "MM-dd-yyyy"));
      _textControllers["end_time"] ??= TextEditingController(text: DateTimeUtils.localDateTimeToString((_data as SurveyQuestionDateTime).endTime, format: "MM-dd-yyyy"));

      // startTime (datetime picker?)
      dataContent.add(FormFieldText('Start Date',
        inputType: TextInputType.datetime,
        hint: "MM-dd-yyyy",
        controller: _textControllers["start_time"],
        validator: _validateDate,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ));
      // endTime (datetime picker?)
      dataContent.add(FormFieldText('End Date',
        inputType: TextInputType.datetime,
        hint: "MM-dd-yyyy",
        controller: _textControllers["end_time"],
        validator: _validateDate,
        padding: EdgeInsets.zero,
      ));
    } else if (_data is SurveyQuestionNumeric) {
      // style
      String styleVal = (_data as SurveyQuestionNumeric).style ?? SurveyQuestionNumeric.supportedStyles.entries.first.key;
      dataContent.add(SurveyElementCreationWidget.buildDropdownWidget<String>(SurveyQuestionNumeric.supportedStyles, "Style", styleVal, _onChangeStyle));

      _textControllers["minimum"] ??= TextEditingController(text: (_data as SurveyQuestionNumeric).minimum?.toString());
      _textControllers["maximum"] ??= TextEditingController(text: (_data as SurveyQuestionNumeric).maximum?.toString());
      //minimum
      dataContent.add(FormFieldText('Minimum', padding: const EdgeInsets.symmetric(vertical: 16), controller: _textControllers["minimum"], inputType: TextInputType.number,));
      //maximum
      dataContent.add(FormFieldText('Maximum', padding: EdgeInsets.zero, controller: _textControllers["maximum"], inputType: TextInputType.number,));

      // wholeNum
      dataContent.add(SurveyElementCreationWidget.buildCheckboxWidget("Whole Number", (_data as SurveyQuestionNumeric).wholeNum, _onToggleWholeNumber));

      // selfScore
      dataContent.add(SurveyElementCreationWidget.buildCheckboxWidget("Self-Score", (_data as SurveyQuestionNumeric).selfScore, _onToggleSelfScore));
    } else if (_data is SurveyQuestionText) {
      _textControllers["min_length"] ??= TextEditingController(text: (_data as SurveyQuestionText).minLength.toString());
      _textControllers["max_length"] ??= TextEditingController(text: (_data as SurveyQuestionText).maxLength?.toString());
      //minLength*
      dataContent.add(FormFieldText('Minimum Length', padding: const EdgeInsets.symmetric(vertical: 16), controller: _textControllers["min_length"], inputType: TextInputType.number, required: true));
      //maxLength
      dataContent.add(FormFieldText('Maximum Length', padding: EdgeInsets.zero, controller: _textControllers["max_length"], inputType: TextInputType.number,));
    } else if (_data is SurveyDataResult && _data.type == 'survey_data.action') {
      // actions
      List<ActionData> actions = (_data as SurveyDataResult).actions ?? [];
      dataContent.add(Padding(padding: const EdgeInsets.only(top: 16.0), child: SurveyElementList(
        type: SurveyElementListType.actions,
        label: 'Actions (${actions.length})',
        dataList: actions,
        surveyElement: SurveyElement.data,
        onAdd: _onTapAdd,
        onEdit: _onTapEdit,
        onRemove: _onTapRemove,
        onDrag: _onAcceptDataDrag,
      )));
    }
    // add SurveyDataPage and SurveyDataEntry later

    List<Widget> baseContent = [
      // data type
      SurveyElementCreationWidget.buildDropdownWidget<String>(SurveyData.supportedTypes, "Type", _data.type, _onChangeType, margin: EdgeInsets.zero),

      // section
      Visibility(
        visible: widget.sections.isNotEmpty && _data is! SurveyDataResult,
        child: SurveyElementCreationWidget.buildDropdownWidget<String>(Map.fromIterable(widget.sections, value: (v) => v ?? 'None'), "Section", _data.section, _onChangeSection)
      ),

      // key*
      FormFieldText('Key', padding: const EdgeInsets.only(top: 16), controller: _textControllers["key"], inputType: TextInputType.text, required: true),
      // question text*
      FormFieldText('Question Text', padding: const EdgeInsets.only(top: 16), controller: _textControllers["text"], inputType: TextInputType.text, textCapitalization: TextCapitalization.sentences, required: true),
      // more info (Additional Info)
      FormFieldText('Additional Info', padding: const EdgeInsets.only(top: 16), controller: _textControllers["more_info"], multipleLines: true, inputType: TextInputType.text, textCapitalization: TextCapitalization.sentences,),
      // maximum score (number, show if survey is scored)
      Visibility(visible: _data.isQuestion, child: FormFieldText('Maximum Score', padding: const EdgeInsets.only(top: 16), controller: _textControllers["maximum_score"], inputType: TextInputType.number,)),

      // allowSkip
      Visibility(visible: _data.isQuestion, child: SurveyElementCreationWidget.buildCheckboxWidget("Required", !_data.allowSkip, _onToggleRequired)),
      
      // defaultResponseRule
      Visibility(visible: _data is! SurveyDataResult, child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(4.0), color: Styles().colors?.getColor('surface')),
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(top: 16),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text("Default Response Rule", style: Styles().textStyles?.getTextStyle('widget.message.regular')),
            GestureDetector(
              onTap: _onTapManageDefaultResponseRule,
              child: Text(_defaultResponseRule == null ? "None" : "Clear", style: Styles().textStyles?.getTextStyle('widget.button.title.medium.underline'))
            ),
          ],),
          Visibility(visible: _defaultResponseRule != null, child: Padding(padding: const EdgeInsets.only(top: 16), child: 
            SurveyElementList(
              type: SurveyElementListType.rules,
              label: '',
              dataList: [_defaultResponseRule],
              surveyElement: SurveyElement.defaultResponseRule,
              onAdd: _onTapAdd,
              onEdit: _onTapEdit,
              onRemove: _onTapRemove,
              singleton: true,
            )
          )),
        ])
      )),

      // scoreRule (show entry if survey is scored)
      Visibility(visible: widget.scoredSurvey && _data is! SurveyDataResult, child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(4.0), color: Styles().colors?.getColor('surface')),
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(top: 16),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text("Score Rule", style: Styles().textStyles?.getTextStyle('widget.message.regular')),
            GestureDetector(
              onTap: _onTapManageScoreRule,
              child: Text(_scoreRule == null ? "None" : "Clear", style: Styles().textStyles?.getTextStyle('widget.button.title.medium.underline'))
            ),
          ],),
          Visibility(visible: widget.scoredSurvey && _scoreRule != null, child: Padding(padding: const EdgeInsets.only(top: 16), child: 
            SurveyElementList(
              type: SurveyElementListType.rules,
              label: '',
              dataList: [_scoreRule],
              surveyElement: SurveyElement.scoreRule,
              onAdd: _onTapAdd,
              onEdit: _onTapEdit,
              onRemove: _onTapRemove,
              singleton: true,
            )
          )),
        ])
      )),

      // type specific data
      ...dataContent,
    ];

    return Padding(padding: const EdgeInsets.all(16), child: Column(children: baseContent,));
  }

  Widget _buildDone() {
    return Padding(padding: const EdgeInsets.all(8.0), child: RoundedButton(
      label: 'Done',
      borderColor: Styles().colors?.fillColorPrimaryVariant,
      backgroundColor: Styles().colors?.surface,
      textStyle: Styles().textStyles?.getTextStyle('widget.detail.large.fat'),
      onTap: _onTapDone,
    ));
  }

  void _onTapAdd(int index, SurveyElement surveyElement, RuleElement? parentElement) {
    switch (surveyElement) {
      case SurveyElement.data: _onTapAddDataAtIndex(index); break;
      case SurveyElement.defaultResponseRule: _onTapAddRuleElementForId(index, surveyElement, parentElement); break;
      case SurveyElement.scoreRule: _onTapAddRuleElementForId(index, surveyElement, parentElement); break;
      default: return;
    }
  }

  void _onTapRemove(int index, SurveyElement surveyElement, RuleElement? parentElement) {
    switch (surveyElement) {
      case SurveyElement.data: _onTapRemoveDataAtIndex(index); break;
      case SurveyElement.defaultResponseRule: _onTapRemoveRuleElementForId(index, surveyElement, parentElement); break;
      case SurveyElement.scoreRule: _onTapRemoveRuleElementForId(index, surveyElement, parentElement); break;
      default: return;
    }
  }

  void _onTapEdit(int index, SurveyElement surveyElement, RuleElement? element) {
    switch (surveyElement) {
      case SurveyElement.data: _onTapEditData(index); break;
      case SurveyElement.defaultResponseRule: _onTapEditRuleElement(element, surveyElement); break;
      case SurveyElement.scoreRule: _onTapEditRuleElement(element, surveyElement); break;
      default: return;
    }
  }

  void _onAcceptDataDrag(int oldIndex, int newIndex) {
    setState(() {
      if (_data is SurveyQuestionMultipleChoice) {
        OptionData temp = (_data as SurveyQuestionMultipleChoice).options[oldIndex];
        (_data as SurveyQuestionMultipleChoice).options.removeAt(oldIndex);
        (_data as SurveyQuestionMultipleChoice).options.insert(newIndex, temp);
      } else if (_data is SurveyDataResult) {
        ActionData temp = (_data as SurveyDataResult).actions![oldIndex];
        (_data as SurveyDataResult).actions!.removeAt(oldIndex);
        (_data as SurveyDataResult).actions!.insert(newIndex, temp);
      }
    });
  }

  void _onTapAddDataAtIndex(int index) {
    setState(() {
      if (_data is SurveyQuestionMultipleChoice) {
        (_data as SurveyQuestionMultipleChoice).options.insert(index, OptionData(
          title: index > 0 ? (_data as SurveyQuestionMultipleChoice).options[index-1].title : "New Option",
          value: index > 0 ? (_data as SurveyQuestionMultipleChoice).options[index-1].value : ""
        ));
      } else if (_data is SurveyDataResult) {
        (_data as SurveyDataResult).actions ??= [];
        (_data as SurveyDataResult).actions!.insert(index, ActionData(label: 'New Action'));
      }
    });
  }

  void _onTapRemoveDataAtIndex(int index) {
    setState(() {
      if (_data is SurveyQuestionMultipleChoice) {
        (_data as SurveyQuestionMultipleChoice).options.removeAt(index);
      } else if (_data is SurveyDataResult) {
        (_data as SurveyDataResult).actions!.removeAt(index);
      }
    });
  }

  void _onTapEditData(int index) async {
    if (_data is SurveyQuestionMultipleChoice) {
      dynamic updatedData = await Navigator.push(context, CupertinoPageRoute(builder: (context) => SurveyDataOptionsPanel(data: (_data as SurveyQuestionMultipleChoice).options[index], tabBar: widget.tabBar)));
      if (updatedData != null && mounted) {
        setState(() {
          (_data as SurveyQuestionMultipleChoice).options[index] = updatedData;
        });
      }
    } else if (_data is SurveyDataResult) {
      dynamic updatedData = await Navigator.push(context, CupertinoPageRoute(builder: (context) => SurveyDataOptionsPanel(data: (_data as SurveyDataResult).actions![index], tabBar: widget.tabBar)));
      if (updatedData != null && mounted) {
        setState(() {
          (_data as SurveyDataResult).actions![index] = updatedData;
        });
      }
    }
  }

  void _onTapAddRuleElementForId(int index, SurveyElement surveyElement, RuleElement? element) {
    //TODO: what should defaults be?
    if (element is RuleCases) {
      element.cases.insert(index, index > 0 ? Rule.fromOther(element.cases[index-1]) : Rule(
        condition: RuleComparison(dataKey: "", operator: "==", compareTo: ""),
        trueResult: RuleAction(action: "return", data: null),
      ));
    } else if (element is RuleActionList) {
      element.actions.insert(index, index > 0 ? RuleAction.fromOther(element.actions[index-1]) : RuleAction(action: "return", data: null));
    } else if (element is RuleLogic) {
      element.conditions.insert(index, index > 0 ? RuleCondition.fromOther(element.conditions[index-1]) : RuleComparison(dataKey: "", operator: "==", compareTo: ""));
    }

    if (element != null) {
      setState(() {
        (surveyElement == SurveyElement.defaultResponseRule ? _defaultResponseRule : _scoreRule)?.updateElement(element);
      });
    }
  }

  void _onTapRemoveRuleElementForId(int index, SurveyElement surveyElement, RuleElement? element) {
    if (element is RuleCases) {
      element.cases.removeAt(index);
    } else if (element is RuleActionList) {
      element.actions.removeAt(index);
    } else if (element is RuleLogic) {
      element.conditions.removeAt(index);
    }

    if (element != null) {
      setState(() {
        (surveyElement == SurveyElement.defaultResponseRule ? _defaultResponseRule : _scoreRule)?.updateElement(element);
      });
    }
  }

  void _onTapEditRuleElement(RuleElement? element, SurveyElement surveyElement, {RuleElement? parentElement}) async {
    if (element != null) {
      RuleElement? ruleElement = await Navigator.push(context, CupertinoPageRoute(builder: (context) => RuleElementCreationPanel(
        data: element,
        dataKeys: widget.dataKeys,
        dataTypes: widget.dataTypes,
        sections: widget.sections,
        tabBar: widget.tabBar, mayChangeType: parentElement is! RuleCases && parentElement is! RuleActionList
      )));

      if (ruleElement != null && mounted) {
        setState(() {
          if (surveyElement == SurveyElement.defaultResponseRule) {
            if (element.id == _defaultResponseRule!.id && ruleElement is RuleResult) {
              _defaultResponseRule = ruleElement;
            }
            else {
              _defaultResponseRule!.updateElement(ruleElement);
            }
          } else {
            if (element.id == _scoreRule!.id && ruleElement is RuleResult) {
              _scoreRule = ruleElement;
            }
            else {
              _scoreRule!.updateElement(ruleElement);
            }
          }
        });
      }
    }
  }

  void _onTapManageDefaultResponseRule() {
    RuleResult? defaultRule;
    switch (_data.type) {
      case "survey_data.true_false":
        List<OptionData> options = (_data as SurveyQuestionTrueFalse).options;
        defaultRule = RuleAction(action: "return", data: options.first.value);
        break;
      case "survey_data.multiple_choice":
        List<OptionData> options = (_data as SurveyQuestionMultipleChoice).options;
        defaultRule = RuleAction(action: "return", data: options.isNotEmpty ? options.first.value : 0);
        break;
      case "survey_data.date_time":
        defaultRule = RuleAction(action: "return", data: DateTimeUtils.localDateTimeToString(DateTime.now(), format: "MM-dd-yyyy"));
        break;
      case "survey_data.numeric":
        defaultRule = RuleAction(action: "return", data: 0);
        break;
      case "survey_data.text":
        defaultRule = RuleAction(action: "return", data: "");
        break;
    }
    setState(() {
      _defaultResponseRule = _defaultResponseRule == null ? defaultRule : null;
    });
  }

  void _onTapManageScoreRule() {
    setState(() {
      _scoreRule = _scoreRule == null ? RuleAction(action: "return", data: 0) : null;
    });
  }

  void _onChangeType(String? type) {
    String key = _textControllers["key"]!.text;
    String text = _textControllers["text"]!.text;
    String? moreInfo = _textControllers["more_info"]!.text.isNotEmpty ? _textControllers["more_info"]!.text : null;
    num? maximumScore = num.tryParse(_textControllers["maximum_score"]!.text);
    _removeTextControllers(keepDefaults: true);

    setState(() {
      switch (type) {
        case "survey_data.true_false":
          _data = SurveyQuestionTrueFalse(key: key, text: text, moreInfo: moreInfo, section: _data.section, maximumScore: maximumScore);
          break;
        case "survey_data.multiple_choice":
          _data = SurveyQuestionMultipleChoice(key: key, text: text, moreInfo: moreInfo, section: _data.section, maximumScore: maximumScore, options: []);
          break;
        case "survey_data.date_time":
          _data = SurveyQuestionDateTime(key: key, text: text, moreInfo: moreInfo, section: _data.section, maximumScore: maximumScore);
          break;
        case "survey_data.numeric":
          _data = SurveyQuestionNumeric(key: key, text: text, moreInfo: moreInfo, section: _data.section, maximumScore: maximumScore);
          break;
        case "survey_data.text":
          _data = SurveyQuestionText(key: key, text: text, moreInfo: moreInfo, section: _data.section, maximumScore: maximumScore);
          break;
        case "survey_data.info":
          _data = SurveyDataResult(key: key, text: text, moreInfo: moreInfo);
          break;
        case "survey_data.action":
          _data = SurveyDataResult(key: key, text: text, moreInfo: moreInfo, actions: []);
          break;
      }
    });
  }

  void _onChangeSection(String? section) {
    setState(() {
      _data.section = section;
    });
  }

  void _onChangeStyle(String? style) {
    setState(() {
      if (_data is SurveyQuestionTrueFalse) {
        (_data as SurveyQuestionTrueFalse).style = style ?? SurveyQuestionTrueFalse.supportedStyles.keys.first;
      } else if (_data is SurveyQuestionMultipleChoice) {
        (_data as SurveyQuestionMultipleChoice).style = style ?? SurveyQuestionMultipleChoice.supportedStyles.keys.first;
      } else if (_data is SurveyQuestionNumeric) {
        (_data as SurveyQuestionNumeric).style = style ?? SurveyQuestionNumeric.supportedStyles.keys.first;
      }
    });
  }

  void _onChangeCorrectAnswer(bool? answer) {
    setState(() {
      (_data as SurveyQuestionTrueFalse).correctAnswer = answer;
    });
  }

  void _onToggleRequired(bool? value) {
    setState(() {
      _data.allowSkip = !(value ?? false);
    });
  }

  void _onToggleMultipleAnswers(bool? value) {
    setState(() {
      (_data as SurveyQuestionMultipleChoice).allowMultiple = value ?? false;
    });
  }

  void _onToggleSelfScore(bool? value) {
    setState(() {
      if (_data is SurveyQuestionMultipleChoice) {
        (_data as SurveyQuestionMultipleChoice).selfScore = value ?? false;
      } else if (_data is SurveyQuestionNumeric) {
        (_data as SurveyQuestionNumeric).selfScore = value ?? false;
      }
    });
  }

  void _onToggleWholeNumber(bool? value) {
    setState(() {
      (_data as SurveyQuestionNumeric).wholeNum = value ?? false;
    });
  }

  String? _validateDate(String? dateStr) {
    if (dateStr != null) {
      if (DateTimeUtils.parseDateTime(dateStr, format: "MM-dd-yyyy") == null) {
        return "Invalid format: must be MM-dd-yyyy";
      }
    }
    return null;
  }

  void _onTapDone() {
    // defaultFollowUpKey and followUpRule will be handled by rules defined on SurveyCreationPanel
    _data.key = _textControllers["key"]!.text;
    _data.text = _textControllers["text"]!.text;
    _data.moreInfo = _textControllers["more_info"]!.text.isNotEmpty ? _textControllers["more_info"]!.text : null;
    _data.maximumScore = num.tryParse(_textControllers["maximum_score"]!.text);

    if (_data is SurveyQuestionMultipleChoice) {
      for (OptionData option in (_data as SurveyQuestionMultipleChoice).options) {
        if (option.isCorrect) {
          (_data as SurveyQuestionMultipleChoice).correctAnswers ??= [];
          (_data as SurveyQuestionMultipleChoice).correctAnswers!.add(option.value);
        }
      }
    } else if (_data is SurveyQuestionDateTime) {
      (_data as SurveyQuestionDateTime).startTime = DateTimeUtils.dateTimeFromString(_textControllers["start_time"]!.text);
      (_data as SurveyQuestionDateTime).endTime = DateTimeUtils.dateTimeFromString(_textControllers["end_time"]!.text);
    } else if (_data is SurveyQuestionNumeric) {
      (_data as SurveyQuestionNumeric).minimum = double.tryParse(_textControllers["minimum"]!.text);
      (_data as SurveyQuestionNumeric).maximum = double.tryParse(_textControllers["maximum"]!.text);
    } else if (_data is SurveyQuestionText) {
      (_data as SurveyQuestionText).minLength = int.tryParse(_textControllers["min_length"]!.text) ?? 0;
      (_data as SurveyQuestionText).maxLength = int.tryParse(_textControllers["max_length"]!.text);
    } else if (_data is SurveyDataResult) {
      // for (int i = 0; i < ((_data as SurveyDataResult).actions?.length ?? 0); i++) {
        //TODO: data, params
      // }
    }
    
    Navigator.of(context).pop(_data);
  }
}