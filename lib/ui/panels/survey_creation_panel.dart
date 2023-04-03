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

import 'package:rokwire_plugin/model/rules.dart';
import 'package:rokwire_plugin/model/survey.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/service/surveys.dart';
import 'package:rokwire_plugin/ui/panels/rule_element_creation_panel.dart';
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

  // final Map<String, String> _constants = {};
  // final Map<String, Map<String, String>> _strings = {};

  final List<RuleResult> _followUpRules = [];
  final List<RuleResult> _resultRules = [];
  // final Map<String, Rule> _subRules = {};
  // List<String>? _responseKeys;

  final Map<String, String> _supportedLangs = {};

  @override
  void initState() {
    _textControllers = {
      "title": TextEditingController(),
      "more_info": TextEditingController(),
      "type": TextEditingController(),
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
      _buildCollapsibleWrapper("Survey Data", _data, _buildSurveyDataWidget, Collapsible.data),

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

      // follow up rules (determine survey data ordering/flow)
      _buildCollapsibleWrapper("Flow Rules", _followUpRules, _buildRuleWidget, Collapsible.followUpRules),
      // result_rules
      _buildCollapsibleWrapper("Result Rules", _resultRules, _buildRuleWidget, Collapsible.resultRules),

      // constants
      // _buildCollapsibleWrapper("Constants", "constants", _constants.length, _buildStringMapEntryWidget),
      // strings
      // _buildCollapsibleWrapper("Strings", "strings", _strings.length, _buildStringMapWidget),
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

  Widget _buildCollapsibleWrapper(String label, List<dynamic> dataList, Widget Function(int, List<dynamic>, Collapsible) listItemBuilder, Collapsible collType, {String? parentId}) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0), child: Ink(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(4.0), color: Styles().colors?.getColor('surface')),
      child: ExpansionTile(
        iconColor: Styles().colors?.getColor('fillColorSecondary'),
        backgroundColor: Styles().colors?.getColor('surface'),
        collapsedBackgroundColor: Styles().colors?.getColor('surface'),
        title: Text(
          label,
          style: Styles().textStyles?.getTextStyle('widget.detail.regular'),
        ),
        //TODO: handle indentation using displayDepth
        trailing: (collType == Collapsible.followUpRules || collType == Collapsible.resultRules) && parentId != null ? Padding(padding: const EdgeInsets.all(4.0), child: RoundedButton(
          label: 'Edit',
          borderColor: Styles().colors?.fillColorPrimaryVariant,
          backgroundColor: Styles().colors?.surface,
          textStyle: Styles().textStyles?.getTextStyle('widget.detail.large.fat'),
          onTap: () => collType == Collapsible.followUpRules ? _onTapEditFlowRuleElement(parentId) : _onTapEditResultRuleElement(parentId),
        )) : null,
        children: <Widget>[
          Container(height: 2, color: Styles().colors?.getColor('fillColorSecondary'),),
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxHeight: 500
            ),
            child: dataList.isNotEmpty ? ListView.builder(
              shrinkWrap: true,
              itemCount: dataList.length,
              itemBuilder: (BuildContext context, int index) {
                return Column(
                  children: [
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 8.0), child: listItemBuilder(index, dataList, collType)),
                    Container(height: 1, color: Styles().colors?.getColor('dividerLine'),),
                  ],
                );
              },
            ) : (collType == Collapsible.data || collType == Collapsible.resultRules) ? _buildAddRemoveButtons(0) : Container(height: 0,),
          ),
        ],
      ),
    ));
  }

  Widget _buildSurveyDataWidget(int index, List<dynamic> data, Collapsible collType) {
    Widget surveyDataText = Text(data[index].key, style: Styles().textStyles?.getTextStyle('widget.detail.regular'),);
    Widget displayEntry = Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Flexible(flex: 2, child: surveyDataText),
      Flexible(flex: 1, child: _buildAddRemoveButtons(index + 1)),
      Flexible(flex: 1, child: Padding(padding: const EdgeInsets.all(4.0), child: RoundedButton(
        label: 'Edit',
        borderColor: Styles().colors?.fillColorPrimaryVariant,
        backgroundColor: Styles().colors?.surface,
        textStyle: Styles().textStyles?.getTextStyle('widget.detail.large.fat'),
        onTap: () => _onTapEditData(index),
      ))),
    ],);

    return Draggable<int>(
      data: index,
      feedback: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(4.0), color: Styles().colors?.getColor('surface')),
        child: surveyDataText
      ),
      childWhenDragging: DragTarget<int>(
        builder: (BuildContext context, List<int?> accepted, List<dynamic> rejected) {
          return displayEntry;
        },
        onAccept: (oldIndex) => _onAcceptDataDrag(oldIndex, index),
      ),
      child: Ink(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(4.0), color: Styles().colors?.getColor('surface')),
        child: displayEntry,
      ),
    );
  }

  Widget _buildRuleWidget(int index, List<dynamic> ruleElements, Collapsible collType) {
    RuleResult ruleResult = ruleElements[index];
    String summary = ruleResult.getSummary();
    if (index == 0 && collType == Collapsible.followUpRules) {
      summary = "Start: $summary";
    }

    late Widget displayEntry;
    Widget ruleText = Text(summary, style: Styles().textStyles?.getTextStyle('widget.detail.regular'), overflow: TextOverflow.fade);
    if (ruleResult is RuleReference || ruleResult is RuleAction) {
      displayEntry = Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Flexible(flex: 3, child: ruleText),
        Flexible(flex: 1, child: Padding(padding: const EdgeInsets.all(4.0), child: RoundedButton(
          label: 'Edit',
          borderColor: Styles().colors?.fillColorPrimaryVariant,
          backgroundColor: Styles().colors?.surface,
          textStyle: Styles().textStyles?.getTextStyle('widget.detail.large.fat'),
          onTap: () => collType == Collapsible.followUpRules ? _onTapEditFlowRuleElement(ruleResult.id) : _onTapEditResultRuleElement(ruleResult.id),
        ))),
      ],);
    } else if (ruleResult is Rule) {
      List<RuleElement> elementsSlice = [];
      if (ruleResult.trueResult != null) {
        elementsSlice.add(ruleResult.trueResult!);
      }
      if (ruleResult.falseResult != null) {
        elementsSlice.add(ruleResult.falseResult!);
      }
      displayEntry = _buildCollapsibleWrapper(ruleResult.condition?.getSummary() ?? "", elementsSlice, _buildRuleWidget, collType, parentId: ruleResult.condition?.id);
    } else if (ruleResult is RuleCases) {
      displayEntry = _buildCollapsibleWrapper(summary, ruleResult.cases, _buildRuleWidget, collType, parentId: ruleResult.id);
    } else if (ruleResult is RuleActionList) {
      displayEntry = _buildCollapsibleWrapper(summary, ruleResult.actions, _buildRuleWidget, collType, parentId: ruleResult.id);
    }

    return Draggable<int>(
      data: index,
      feedback: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(4.0), color: Styles().colors?.getColor('surface')),
        child: ruleText
      ),
      childWhenDragging: DragTarget<int>(
        builder: (BuildContext context, List<int?> accepted, List<dynamic> rejected) {
          return displayEntry;
        },
        onAccept: (oldIndex) => _onAcceptFlowRuleDrag(oldIndex, index),
      ),
      child: Ink(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(4.0), color: Styles().colors?.getColor('surface')),
        child: displayEntry,
      ),
    );
  }

  /*
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

  Widget _buildStringMapWidget(int index) {
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
        trailing: _buildAddRemoveButtons(index + 1),
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
            ) : _buildAddRemoveButtons(0),
          ),
        ],
      ),
    );
  }
  */

  Widget _buildAddRemoveButtons(int index) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      IconButton(
        icon: Styles().images?.getImage('plus-circle', color: Styles().colors?.getColor('fillColorPrimary')) ?? const Icon(Icons.add),
        onPressed: () => _onTapAddDataAtIndex(index),
        padding: EdgeInsets.zero,
      ),
      IconButton(
        icon: Styles().images?.getImage('minus-circle', color: Styles().colors?.getColor('alert')) ?? const Icon(Icons.remove),
        onPressed: () => _onTapRemoveDataAtIndex(index - 1),
        padding: EdgeInsets.zero,
      ),
    ]);
  }

  /*  
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
  */

  void _onAcceptDataDrag(int oldIndex, int newIndex) {
    _updateState(() {
      SurveyData temp = _data[oldIndex];
      _data.removeAt(oldIndex);
      _data.insert(newIndex, temp);
      //TODO: update follow up rules appropriately
    });
  }

  void _onAcceptFlowRuleDrag(int oldIndex, int newIndex) {
    _updateState(() {
      RuleResult temp = _followUpRules[oldIndex];
      _followUpRules.removeAt(oldIndex);
      _followUpRules.insert(newIndex, temp);
      //TODO: update follow up rules appropriately
    });
  }

  void _onAcceptResultRuleDrag(int oldIndex, int newIndex) {
    _updateState(() {
      RuleResult temp = _resultRules[oldIndex];
      _resultRules.removeAt(oldIndex);
      _resultRules.insert(newIndex, temp);
      //TODO: update follow up rules appropriately
    });
  }

  void _onTapEditData(int index) async {
    SurveyData updatedData = await Navigator.push(context, CupertinoPageRoute(builder: (context) => SurveyDataCreationPanel(data: _data[index], tabBar: widget.tabBar)));
    _updateState(() {
      _data[index] = updatedData;
      //TODO: update follow up rules appropriately
    });
  }

  void _onTapEditFlowRuleElement(String id) async {
    RuleElement? followUpRuleElem;
    for (RuleResult result in _followUpRules) {
      RuleElement? elem = result.findElementById(id);
      if (elem != null) {
        followUpRuleElem = elem;
      }
    }

    if (followUpRuleElem != null) {
      RuleElement ruleElement = await Navigator.push(context, CupertinoPageRoute(builder: (context) => RuleElementCreationPanel(data: followUpRuleElem!, tabBar: widget.tabBar)));
      _updateState(() {
        for (RuleResult result in _followUpRules) {
          result.updateElementById(id, ruleElement);
        }
      });
    }
  }

  void _onTapEditResultRuleElement(String id) async {
    RuleElement? resultRulesElem;
    for (RuleResult result in _resultRules) {
      RuleElement? elem = result.findElementById(id);
      if (elem != null) {
        resultRulesElem = elem;
      }
    }

    if (resultRulesElem != null) {
      RuleElement ruleElement = await Navigator.push(context, CupertinoPageRoute(builder: (context) => RuleElementCreationPanel(data: resultRulesElem!, tabBar: widget.tabBar)));
      _updateState(() {
        for (RuleResult result in _resultRules) {
          result.updateElementById(id, ruleElement);
        }
      });
    }
  }

  void _onTapAddDataAtIndex(int index) {
    SurveyData insert;
    if (index > 0) {
      insert = SurveyData.fromOther(_data[index-1]);
      insert.key = "data${_data.length}";
      insert.text = "New survey data";
      insert.defaultFollowUpKey = index == _data.length ? null : _data[index].key;
    } else {
      insert = SurveyQuestionTrueFalse(text: "New True/False Question", key: "data${_data.length}");
    }
    _updateState(() {
      _data.insert(index, insert);
      if (index == 0) {
        if (_followUpRules.isEmpty) {
          _followUpRules.add(RuleAction(action: "return", data: insert.key));
        } else {
          _followUpRules[0] = RuleAction(action: "return", data: insert.key);
          _followUpRules.insert(1, RuleAction(action: "return", data: _data[1].key));
        }
      } else {
        _followUpRules.insert(index, RuleAction(action: "return", data: _data[index].key));
      }
      //update follow up rules other than returns
      // if index > 0:
        // update keys for _followUpRules[index-1]
    });
  }

  void _onTapRemoveDataAtIndex(int index) {
    _updateState(() {
      _data.removeAt(index);
      _followUpRules.removeAt(index);
      //TODO: update follow up rules
    });
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

  
  Survey _buildSurvey() {
    //TODO: map rules into each survey data
    return Survey(
      id: '',
      data: Map.fromIterable(_data, key: (item) => (item as SurveyData).key),
      type: _textControllers["type"]?.text ?? 'survey',
      scored: _scored,
      title: _textControllers["title"]?.text ?? 'New Survey',
      moreInfo: _textControllers["more_info"]?.text,
      // defaultDataKeyRule: _defaultDataKeyRule,
      resultRules: _resultRules,
      // responseKeys: _responseKeys,
      // constants: _constants,
      // strings: _strings,
      // subRules: _subRules,
    );
  }

  void _onTapPreview() {
    // should preview evaluate rules?/which rules should it evaluate if not all of them?
    Navigator.push(context, CupertinoPageRoute(builder: (context) => SurveyPanel(survey: _buildSurvey())));
  }

  void _onTapContinue() {
    setLoading(true);
    Surveys().createSurvey(_buildSurvey()).then((success) {
      setLoading(false);
      PopupMessage.show(context: context,
        title: "Create Survey",
        message: "Survey creation ${success == true ? "succeeded" : "failed"}",
        buttonTitle: Localization().getStringEx("dialog.ok.title", "OK"),
        onTapButton: (context) {
          Navigator.pop(context);
          Navigator.pop(context);
        },
        barrierDismissible: false,
      );
    });
  }

  void setLoading(bool value) {
    if (mounted) {
      setState(() {
        _loading = value;
      });
    }
  }

  void _updateState(Function() fn) {
    if (mounted) {
      setState(() {
        fn();
      });
    }
  }
}