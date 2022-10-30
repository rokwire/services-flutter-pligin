import 'package:rokwire_plugin/utils/utils.dart';

enum ActionType {
  launchUri,
  showSurvey,
  dismiss,
  none
}

class ActionData {
  ActionType type;
  String? label;
  dynamic data;

  ActionData({this.type = ActionType.none, this.label, this.data});

  factory ActionData.fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      dynamic data = json['data'];
      if (data is String) {
        dynamic decoded = JsonUtils.decode(data);
        if (decoded != null) {
          data = decoded;
        }
      }

      ActionType? type;
      try {
        type = ActionType.values.byName(json['type']);
      } catch(e) { }

      return ActionData(
        type: type ?? ActionType.none,
        label: JsonUtils.stringValue(json['label']),
        data: data,
      );
    } else if (json is String) {
      ActionType? type;
      try {
        type = ActionType.values.byName(json);
      } catch(e) { }

      return ActionData(type: type ?? ActionType.none);
    }
    return ActionData(type: ActionType.none);
  }

  static List<ActionData> listFromJson(List<dynamic>? jsonList) {
    List<ActionData> list = [];
    for (dynamic json in jsonList ?? []) {
      list.add(ActionData.fromJson(json));
    }
    return list;
  }

  static List<Map<String, dynamic>> listToJson(List<ActionData>? actions) {
    List<Map<String, dynamic>> actionsJson = [];
    for (ActionData action in actions ?? []) {
      actionsJson.add(action.toJson());
    }
    return actionsJson;
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'label': label,
      'data': JsonUtils.encode(data),
    };
  }
}

class ButtonAction {
  String title;
  void Function()? action;

  ButtonAction(this.title, this.action);
}