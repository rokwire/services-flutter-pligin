// Copyright 2022 Board of Trustees of the University of Illinois.
// 
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
//     http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:flutter/foundation.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:uuid/uuid.dart';

abstract class RuleElement {
  String id = const Uuid().v4();
  int displayDepth;

  RuleElement({this.displayDepth = 0});

  Map<String, dynamic> toJson();

  String getSummary({String? prefix, String? suffix}) => "";

  void setDisplayDepth(int parentDepth) {
    displayDepth = parentDepth + 1;
  }

  // RuleElement? findElementById(String elementId) => id == elementId ? this : null;

  bool updateElementById(String elementId, RuleElement update);

  static Map<String, String> get supportedElements => const {
    "comparison": "Comparison",
    "logic": "Logic",
    // "reference": "Reference",
    "action": "Action",
    "action_list": "Action List",
    "cases": "Cases",
  };
} 

abstract class RuleCondition extends RuleElement {

  RuleCondition({int displayDepth = 0}) : super(displayDepth: displayDepth);

  factory RuleCondition.fromJson(Map<String, dynamic> json) {
    dynamic conditions = json["conditions"];
    if (conditions is List<dynamic>) {
      List<RuleCondition> parsedConditions = [];
      for (dynamic condition in conditions) {
        parsedConditions.add(RuleCondition.fromJson(condition));
      }
      return RuleLogic(json["operator"], parsedConditions);
    }
    return RuleComparison.fromJson(json);
  }
}           

class RuleComparison extends RuleCondition {
  String operator;
  String dataKey;
  dynamic dataParam;
  dynamic compareTo;
  dynamic compareToParam;
  bool? defaultResult;

  RuleComparison({required this.dataKey, required this.operator, this.dataParam,
    required this.compareTo, this.compareToParam, this.defaultResult = false, int displayDepth = 0}) : super(displayDepth: displayDepth);

  factory RuleComparison.fromJson(Map<String, dynamic> json) {
    return RuleComparison(
      operator: json["operator"],
      dataKey: json["data_key"],
      dataParam: json["data_param"],
      compareTo: json["compare_to"],
      compareToParam: json["compare_to_param"],
      defaultResult: json["default_result"] ?? false,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'operator': operator,
      'data_key': dataKey,
      'data_param': dataParam,
      'compare_to': compareTo,
      'compare_to_param': compareToParam,
      'default_result': defaultResult,
    };
  }

  static Map<String, String> get supportedOperators => const {
    "<": "less than",
    ">": "greater than",
    "<=": "less than or equal to",
    ">=": "greater than or equal to",
    "==": "equal to",
    "!=": "not equal to",
    "in_range": "in range",
    "any": "any of",
    "all": "all of",
  };

  @override
  String getSummary({String? prefix, String? suffix}) {
    String summary = "Is $dataKey ${supportedOperators[operator]} $compareTo?";
    if (prefix != null) {
      summary = "$prefix $summary";
    }
    if (suffix != null) {
      summary = "$summary $suffix";
    }
    return summary;
  }

  @override
  bool updateElementById(String elementId, RuleElement update) {
    if (id == elementId && update is RuleComparison) {
      operator = update.operator;
      dataKey = update.dataKey;
      dataParam = update.dataParam;
      compareTo = update.compareTo;
      compareToParam = update.compareToParam;
      defaultResult = update.defaultResult;
      return true;
    }
    return false;
  }
}

class RuleLogic extends RuleCondition {
  String operator;
  List<RuleCondition> conditions;

  RuleLogic(this.operator, this.conditions, {int displayDepth = 0}) : super(displayDepth: displayDepth);

  @override
  Map<String, dynamic> toJson() {
    return {
      'operator': operator,
      'conditions': conditions.map((e) => e.toJson()),
    };
  }

  static Map<String, String> get supportedOperators => const {
    "or": "OR",
    "and": "AND",
  };

  @override
  String getSummary({String? prefix, String? suffix}) {
    String summary = "";
    for (int i = 0; i < conditions.length; i++) {
      if (i == conditions.length - 1) {
        summary += "(${conditions[i].getSummary()})";
      } else {
        summary += "(${conditions[i].getSummary()}) ${supportedOperators[operator]}";
      }
    }
    summary = "Is $summary?";
    if (prefix != null) {
      summary = "$prefix $summary";
    }
    if (suffix != null) {
      summary = "$summary $suffix";
    }
    return summary;
  }

  @override
  void setDisplayDepth(int parentDepth) {
    super.setDisplayDepth(parentDepth);
    for (RuleCondition condition in conditions) {
      condition.setDisplayDepth(displayDepth);
    }
  }

  @override
  bool updateElementById(String elementId, RuleElement update) {
    if (id == elementId && update is RuleLogic) {
      operator = update.operator;
      conditions = update.conditions;
      return true;
    }

    for (RuleCondition condition in conditions) {
      if (condition.updateElementById(elementId, update)) {
        return true;
      }
    }
    return false;
  }
}

abstract class RuleResult extends RuleElement {

  RuleResult({int displayDepth = 0}) : super(displayDepth: displayDepth);

  factory RuleResult.fromJson(Map<String, dynamic> json) {
    dynamic ruleKey = json["rule_key"];
    if (ruleKey is String) {
      return RuleReference(ruleKey);
    }
    dynamic cases = json["cases"];
    if (cases is List<dynamic>) {
      List<Rule> caseList = [];
      for (dynamic caseItem in caseList) {
        caseList.add(Rule.fromJson(caseItem));
      }
      return RuleCases(cases: caseList);
    }
    dynamic condition = json["condition"];
    if (condition != null) {
      return Rule.fromJson(json);
    }
    return RuleActionResult.fromJson(json);
  }

  static List<Map<String, dynamic>> listToJson(List<RuleResult>? resultRules) {
    if (resultRules == null) {
      return [];
    }
    List<Map<String, dynamic>> resultsJson = [];
    for (RuleResult ruleResult in resultRules) {
      resultsJson.add(ruleResult.toJson());
    }
    return resultsJson;
  }
}

abstract class RuleActionResult extends RuleResult {
  abstract final int? priority;

  RuleActionResult({int displayDepth = 0}) : super(displayDepth: displayDepth);

  factory RuleActionResult.fromJson(Map<String, dynamic> json) {
    dynamic actions = json["actions"];
    if (actions is List<dynamic>) {
      List<RuleAction> actionList = [];
      for (dynamic action in actions) {
        actionList.add(RuleAction.fromJson(action));
      }
      return RuleActionList(actions: actionList, priority: json["priority"]);
    }
    return RuleAction.fromJson(json);
  }
}

class RuleReference extends RuleResult {
  String ruleKey;

  RuleReference(this.ruleKey, {int displayDepth = 0}) : super(displayDepth: displayDepth);

  @override
  Map<String, dynamic> toJson() {
    return {
      'rule_key': ruleKey,
    };
  }

  @override
  String getSummary({String? prefix, String? suffix}) {
    String summary = "Evaluate $ruleKey";
    if (prefix != null) {
      summary = "$prefix $summary";
    }
    if (suffix != null) {
      summary = "$summary $suffix";
    }
    return summary;
  }

  @override
  bool updateElementById(String elementId, RuleElement update) {
    if (id == elementId && update is RuleReference) {
      ruleKey = update.ruleKey;
      return true;
    }
    return false;
  }
}

class RuleAction extends RuleActionResult {
  String action;
  dynamic data;
  String? dataKey;
  @override int? priority;

  RuleAction({required this.action, required this.data, this.dataKey, this.priority, int displayDepth = 0}) : super(displayDepth: displayDepth);

  factory RuleAction.fromJson(Map<String, dynamic> json) {
    return RuleAction(
      action: json["action"],
      data: json["data"],
      dataKey: JsonUtils.stringValue(json["data_key"]),
      priority: json["priority"],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'action': action,
      'data': data,
      'data_key': dataKey,
      'priority': priority,
    };
  }

  static Map<String, String> get supportedActions => const {
    "return": "Return",
    "sum": "Sum",
    "set_result": "Set Result",
    "show_survey": "Show Survey",
    "alert": "Alert",
    "alert_result": "Alert Result",
    "notify": "Notify",
    "save": "Save",
    "local_notify": "Local Notify",
  };

  @override
  String getSummary({String? prefix, String? suffix}) {
    String summary = "${supportedActions[action]} $data";
    if (prefix != null) {
      summary = "$prefix $summary";
    }
    if (suffix != null) {
      summary = "$summary $suffix";
    }
    return summary;
  }

  @override
  bool updateElementById(String elementId, RuleElement update) {
    if (id == elementId && update is RuleAction) {
      action = update.action;
      data = update.data;
      dataKey = update.dataKey;
      priority = update.priority;
      return true;
    }
    return false;
  }
}

class RuleActionList extends RuleActionResult {
  List<RuleAction> actions;
  @override int? priority;

  RuleActionList({required this.actions, this.priority, int displayDepth = 0}) : super(displayDepth: displayDepth);

  @override
  Map<String, dynamic> toJson() {
    return {
      'priority': priority,
      'actions': actions.map((e) => e.toJson()),
    };
  }

  @override
  void setDisplayDepth(int parentDepth) {
    super.setDisplayDepth(parentDepth);
    for (RuleAction action in actions) {
      action.setDisplayDepth(displayDepth);
    }
  }

  // @override
  // RuleElement? findElementById(String elementId, {RuleElement? update}) {
  //   for (RuleAction action in actions) {
  //     RuleElement? element = action.findElementById(elementId);
  //     if (element != null) {
  //       return element;
  //     }
  //   }
  //   return super.findElementById(elementId);
  // }

  @override
  bool updateElementById(String elementId, RuleElement update) {
    if (id == elementId && update is RuleActionList) {
      actions = update.actions;
      priority = update.priority;
      return true;
    }

    for (RuleAction action in actions) {
      if (action.updateElementById(elementId, update)) {
        return true;
      }
    }
    return false;
  }
}

class Rule extends RuleResult {
  RuleCondition? condition;
  RuleResult? trueResult;
  RuleResult? falseResult;

  Rule({this.condition, this.trueResult, this.falseResult, int displayDepth = 0}) : super(displayDepth: displayDepth);

  factory Rule.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? condition = json["condition"];
    Map<String, dynamic>? trueResult = json["true_result"];
    Map<String, dynamic>? falseResult = json["false_result"];
    return Rule(
      condition: condition != null ? RuleCondition.fromJson(condition) : null,
      trueResult: trueResult != null ? RuleResult.fromJson(trueResult) : null,
      falseResult: falseResult != null ? RuleResult.fromJson(falseResult) : null,
    );
  }

  factory Rule.fromOther(Rule other) {
    return Rule(
      condition: other.condition,
      trueResult: other.trueResult,
      falseResult: other.falseResult,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'condition': condition?.toJson(),
      'true_result': trueResult?.toJson(),
      'false_result': falseResult?.toJson(),
    };
  }

  static List<Rule> listFromJson(List<dynamic>? jsonList) {
    if (jsonList == null) {
      return [];
    }
    List<Rule> rules = [];
    for (dynamic json in jsonList) {
      if (json is Map<String, dynamic>) {
        rules.add(Rule.fromJson(json));
      }
    }
    return rules;
  }

  static List<Map<String, dynamic>> listToJson(List<Rule>? rules) {
    if (rules == null) {
      return [];
    }
    List<Map<String, dynamic>> rulesJson = [];
    for (Rule rule in rules) {
      rulesJson.add(rule.toJson());
    }
    return rulesJson;
  }

  @override
  void setDisplayDepth(int parentDepth) {
    condition?.setDisplayDepth(parentDepth);
    trueResult?.setDisplayDepth(condition?.displayDepth ?? parentDepth);
    falseResult?.setDisplayDepth(condition?.displayDepth ?? parentDepth);
  }

  // @override
  // RuleElement? findElementById(String elementId) => condition?.findElementById(elementId) ?? trueResult?.findElementById(elementId) ?? falseResult?.findElementById(elementId);

  @override
  bool updateElementById(String elementId, RuleElement update) {
    if (id == elementId && update is Rule) {
      condition = update.condition;
      trueResult = update.trueResult;
      falseResult = update.falseResult;
      return true;
    }

    if (condition?.updateElementById(elementId, update) ?? false) {
      return true;
    } else if (trueResult?.updateElementById(elementId, update) ?? false) {
      return true;
    } else if (falseResult?.updateElementById(elementId, update) ?? false) {
      return true;
    }
    return false;
  }
}

class RuleCases extends RuleResult {
  List<Rule> cases;

  RuleCases({required this.cases, int displayDepth = 0}) : super(displayDepth: displayDepth);

  @override
  Map<String, dynamic> toJson() {
    return {
      'cases': cases.map((e) => e.toJson()),
    };
  }

  @override
  String getSummary({String? prefix, String? suffix}) {
    String summary = "Evaluate the contents of the first true statement:";
    if (prefix != null) {
      summary = "$prefix $summary";
    }
    if (suffix != null) {
      summary = "$summary $suffix";
    }
    return summary;
  }

  @override
  void setDisplayDepth(int parentDepth) {
    super.setDisplayDepth(parentDepth);
    for (Rule ruleCase in cases) {
      ruleCase.setDisplayDepth(displayDepth);
    }
  }

  // @override
  // RuleElement? findElementById(String elementId) {
  //   for (Rule ruleCase in cases) {
  //     RuleElement? element = ruleCase.findElementById(elementId);
  //     if (element != null) {
  //       return element;
  //     }
  //   }
  //   return super.findElementById(elementId);
  // }

  @override
  bool updateElementById(String elementId, RuleElement update) {
    if (id == elementId && update is RuleCases) {
      cases = update.cases;
      return true;
    }

    for (Rule ruleCase in cases) {
      if (ruleCase.updateElementById(elementId, update)) {
        return true;
      }
    }
    return false;
  }
}

abstract class RuleEngine {
  abstract final String id;
  abstract final String type;

  final Map<String, dynamic> constants;
  final Map<String, Map<String, String>> strings;
  final Map<String, Rule> subRules;
  dynamic resultData;

  RuleEngine({this.constants = const {}, this.strings = const {}, this.subRules = const {}, this.resultData});

  static Map<String, Rule> subRulesFromJson(Map<String, dynamic> json) {
    Map<String, Rule> subRules = {};
    dynamic subRulesJson = json["sub_rules"];
    if (subRulesJson is Map<String, dynamic>) {
      for (MapEntry<String, dynamic> entry in subRulesJson.entries) {
        subRules[entry.key] = Rule.fromJson(entry.value);
      }
    }
    return subRules;
  }

  static Map<String, dynamic> subRulesToJson(Map<String, Rule> subRules) {
    Map<String, dynamic> json = {};
    for (MapEntry<String, Rule> entry in subRules.entries) {
      json[entry.key] = entry.value.toJson();
    }
    return json;
  }

  static Map<String, Map<String, String>> stringsFromJson(Map<String, dynamic> json) {
    Map<String, Map<String, String>> stringsMap = {};
    dynamic stringsJson = json["strings"];
    if (stringsJson is Map<String, dynamic>) {
      for (MapEntry<String, dynamic> language in stringsJson.entries) {
        if (language.value is Map<String, dynamic>) {
          Map<String, String> strings = {};
          for (MapEntry<String, dynamic> string in language.value.entries) {
            if (string.value is String) {
              strings[string.key] = string.value;
            }
          }
          stringsMap[language.key] = strings;
        }
      }
    }
    return stringsMap;
  }

  static Map<String, dynamic> constantsFromJson(Map<String, dynamic> json) {
    Map<String, dynamic> constMap = {};
    dynamic constJson = json["constants"];
    if (constJson is Map<String, dynamic>) {
      for (MapEntry<String, dynamic> constant in constJson.entries) {
        constMap[constant.key] = constant.value;
      }
    }
    return constMap;
  }
}

class RuleKey {
  final String key;
  final String? subKey;

  RuleKey(this.key, this.subKey);

  factory RuleKey.fromKey(String key) {
    int dotIdx = key.indexOf('.');
    if (dotIdx >= 0) {
      return RuleKey(
        key.substring(0, dotIdx),
        key.substring(dotIdx + 1),
      );
    }
    return RuleKey(key, null);
  }

  RuleKey? get subRuleKey {
    if (subKey != null) {
      return RuleKey.fromKey(subKey!);
    }
    return null;
  }

  @override
  String toString() => subKey != null ? '$key.$subKey' : key;
}

class RuleData {
  final dynamic param;
  final dynamic value;

  RuleData({required this.value, this.param});

  bool match(dynamic param) {
    if (param is Map) {
      if (this.param is Map) {
        if (!mapEquals(param, this.param)) {
          return false;
        }
      } else {
        return false;
      }
    } else if (param is List) {
      if (this.param is List) {
        if (!listEquals(param, this.param)) {
          return false;
        }
      } else {
        return false;
      }
    } else {
      if (param != this.param) {
        return false;
      }
    }

    return true;
  }
}
