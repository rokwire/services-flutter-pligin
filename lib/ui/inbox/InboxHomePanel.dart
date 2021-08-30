import 'package:flutter/material.dart';
import 'package:illinois/model/Inbox.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/AppDateTime.dart';
import 'package:illinois/service/Inbox.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/service/User.dart';
import 'package:illinois/ui/widgets/FilterWidgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBarWidget.dart';
import 'package:illinois/utils/Utils.dart';

class InboxHomePanel extends StatefulWidget {
  InboxHomePanel();

  _InboxHomePanelState createState() => _InboxHomePanelState();
}

class _InboxHomePanelState extends State<InboxHomePanel> implements NotificationsListener {

  final List<_FilterEntry> _categories = [
    _FilterEntry(value: null, name: "Any Category"),
    _FilterEntry(value: "Admin"),
    _FilterEntry(value: "Academic"),
    _FilterEntry(value: "Athletics"),
    _FilterEntry(value: "Community"),
    _FilterEntry(value: "Entertainment"),
    _FilterEntry(value: "Recreation"),
    _FilterEntry(value: "Other"),
  ];

  final List<_FilterEntry> _times = [
    _FilterEntry(name: "Any Time", value: null),
    _FilterEntry(name: "Today", value: _TimeFilter.Today),
    _FilterEntry(name: "Today and Yesterday", value: _TimeFilter.TodayAndYesterday),
    _FilterEntry(name: "This week", value: _TimeFilter.ThisWeek),
    _FilterEntry(name: "Last week", value: _TimeFilter.LastWeek),
    _FilterEntry(name: "This month", value: _TimeFilter.ThisMonth),
    _FilterEntry(name: "Last Month", value: _TimeFilter.LastMonth),
  ];

  final int _messagesPageSize = 8;

  String _selectedCategory;
  _TimeFilter _selectedTime;
  _FilterType _selectedFilter;
  bool _hasMoreMessages;
  
  bool _loading, _loadingMore;
  List<InboxMessage> _messages = <InboxMessage>[];
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, []);

    _scrollController.addListener(_scrollListener);

    _loadinInitialContent();
  }

  @override
  void dispose() {
    super.dispose();
    NotificationService().unsubscribe(this);
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SimpleHeaderBarWithBack(
        context: context,
        titleWidget: Text(Localization().getStringEx('panel.inbox.label.heading', 'Inbox'), style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: Styles().fontFamilies.extraBold),),
      ),
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          _buildFilters(),
          Expanded(child:
            _buildContent(),
          ),
          TabBarWidget(),
        ],),
      backgroundColor: Styles().colors.background,
    );
  }

  Widget _buildContent() {
    return Stack(children: [
      Visibility(visible: (_loading != true), child:
        Padding(padding: EdgeInsets.only(top: 12), child:
          _buildMessagesContent()
        ),
      ),
      Visibility(visible: (_loading == true), child:
        Align(alignment: Alignment.center, child:
          CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(Styles().colors.fillColorSecondary), )
        )
      ),
      Visibility(visible: (_selectedFilter != null), child:
        Stack(children:<Widget>[
          _buildDisabledContentLayer(),
          _buildFilterValues(),
        ]),
      ),
    ]);
  }

  Widget _buildMessagesContent() {
    if (_messages.length == 0) {
      return Column(children: <Widget>[
        Expanded(child: Container(), flex: 1),
        Text(Localization().getStringEx('panel.inbox.label.content.empty', 'No messages'), textAlign: TextAlign.center,),
        Expanded(child: Container(), flex: 3),
      ]);
    }
    else {
      int count = _messages.length + ((_loadingMore == true) ? 1 : 0);
      return ListView.separated(
        separatorBuilder: (context, index) => Container(height: 24),
        itemCount: count,
        itemBuilder: (BuildContext context, int index){
          return (index < _messages.length) ? _InboxMessageCard(message: _messages[index]) : _buildListLoadingIndicator();
        },
        controller: _scrollController);
    }
  }

  Widget _buildListLoadingIndicator() {
    return Container(padding: EdgeInsets.all(6), child:
      Align(alignment: Alignment.center, child:
        SizedBox(width: 24, height: 24, child:
          CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(Styles().colors.fillColorSecondary),),),),);
  }

  Widget _buildDisabledContentLayer() {
    return Padding(padding: EdgeInsets.only(top: 12), child:
      BlockSemantics(child:
        Container(color: Color(0x99000000))
      ),
    );
  }

  Widget _buildFilterValues() {

    List<_FilterEntry> filterValues;
    dynamic selectedFilterValue;
    List<String> subLabels;
    switch(_selectedFilter) {
      case _FilterType.Category: filterValues = _categories; selectedFilterValue = _selectedCategory; subLabels = null; break;
      case _FilterType.Time: filterValues = _times; selectedFilterValue = _selectedTime; subLabels = _buildTimeDates(); break;
      default: filterValues = []; break;
    }

    return Padding(padding: EdgeInsets.only(top: 6, left: 16, right: 16, bottom: 32), child:
      Container(decoration: BoxDecoration(color: Styles().colors.fillColorSecondary, borderRadius: BorderRadius.circular(5.0)), child: 
        Padding(padding: EdgeInsets.only(top: 2), child:
          Container(color: Colors.white, child:
            ListView.separated(
              shrinkWrap: true,
              separatorBuilder: (context, index) => Divider(height: 1, color: Styles().colors.fillColorPrimaryTransparent03,),
              itemCount: filterValues.length,
              itemBuilder: (context, index) {
                return FilterListItemWidget(
                  label: filterValues[index].name,
                  subLabel: (subLabels != null) ? subLabels[index] : null,
                  selected: selectedFilterValue == filterValues[index].value,
                  onTap: () { _onFilterValue(_selectedFilter, filterValues[index]); },
                );
              }
            ),
          ),
        )
      )
    );
  }

  List<String> _buildTimeDates() {
    DateTime now = DateTime.now();
    String todayStr = AppDateTime().formatDateTime(now, format: AppDateTime.eventFilterDisplayDateFormat, ignoreTimeZone: true);

    List<String> timeDates = <String>[];
    for (_FilterEntry timeEntry in _times) {
      String timeDate;
      switch(timeEntry?.value) {
        case _TimeFilter.Today:
          timeDate = todayStr;
          break;

        case _TimeFilter.TodayAndYesterday:
          DateTime yesterday = DateTime(now.year, now.month, now.day - 1);
          String yesterdayStr = AppDateTime().formatDateTime(yesterday, format: AppDateTime.eventFilterDisplayDateFormat, ignoreTimeZone: true);
          timeDate = "$yesterdayStr - $todayStr";
          break;

        case _TimeFilter.ThisWeek:
          if (1 < now.weekday) {
            DateTime startOfThisWeek = DateTime(now.year, now.month, now.day - now.weekday + 1);
            String startOfThisWeekStr = AppDateTime().formatDateTime(startOfThisWeek, format: AppDateTime.eventFilterDisplayDateFormat, ignoreTimeZone: true);
            timeDate = "$startOfThisWeekStr - $todayStr";
          }
          else {
            timeDate = todayStr;
          }
          break;

        case _TimeFilter.LastWeek:
          DateTime startOfLastWeek = DateTime(now.year, now.month, now.day - now.weekday + 1 - 7);
          String startOfLastWeekStr = AppDateTime().formatDateTime(startOfLastWeek, format: AppDateTime.eventFilterDisplayDateFormat, ignoreTimeZone: true);
          DateTime endOfLastWeek = DateTime(now.year, now.month, now.day - now.weekday);
          String endOfLastWeekStr = AppDateTime().formatDateTime(endOfLastWeek, format: AppDateTime.eventFilterDisplayDateFormat, ignoreTimeZone: true);
          timeDate = "$startOfLastWeekStr - $endOfLastWeekStr";
          break;

        case _TimeFilter.ThisMonth:
          if (1 < now.day) {
            DateTime startOfThisMonth = DateTime(now.year, now.month, 1);
            String startOfThisMonthStr = AppDateTime().formatDateTime(startOfThisMonth, format: AppDateTime.eventFilterDisplayDateFormat, ignoreTimeZone: true);
            timeDate = "$startOfThisMonthStr - $todayStr";
          }
          break;

        case _TimeFilter.LastMonth:
          DateTime startOfLastMonth = DateTime(now.year, now.month - 1, 1);
          String startOfLastMonthStr = AppDateTime().formatDateTime(startOfLastMonth, format: AppDateTime.eventFilterDisplayDateFormat, ignoreTimeZone: true);
          DateTime endOfLastMonth = DateTime(now.year, now.month, 0);
          String endOfLastMonthStr = AppDateTime().formatDateTime(endOfLastMonth, format: AppDateTime.eventFilterDisplayDateFormat, ignoreTimeZone: true);
          timeDate = "$startOfLastMonthStr - $endOfLastMonthStr";
          break;
      }
      timeDates.add(timeDate);
    }
    return timeDates;
  }

  static List<DateTime> _getTimeDates(_TimeFilter timeFilter) {
    DateTime now = DateTime.now();
    switch(timeFilter) {
      case _TimeFilter.Today:             return [ DateTime(now.year, now.month, now.day) ];
      case _TimeFilter.TodayAndYesterday: return [ DateTime(now.year, now.month, now.day - 1)];
      case _TimeFilter.ThisWeek:          return [ DateTime(now.year, now.month, now.day - now.weekday + 1) ];
      case _TimeFilter.LastWeek:          return [ DateTime(now.year, now.month, now.day - now.weekday + 1 - 7), DateTime(now.year, now.month, now.day - now.weekday)];
      case _TimeFilter.ThisMonth:         return [ DateTime(now.year, now.month, 1)];
      case _TimeFilter.LastMonth:         return [ DateTime(now.year, now.month - 1, 1), DateTime(now.year, now.month, 0)];
    }
    return null;
  }

  void _onFilterValue(_FilterType filterType, _FilterEntry filterEntry) {
    Analytics().logSelect(target: "FilterItem: ${filterEntry.name}");
    setState(() {
      switch(filterType) {
        case _FilterType.Category: _selectedCategory = filterEntry?.value; break;
        case _FilterType.Time: _selectedTime = filterEntry?.value; break;
      }
      _selectedFilter = null;
    });

    _loadinInitialContent();
  }

  // Filters

  Widget _buildFilters() {
    return SingleChildScrollView(scrollDirection: Axis.horizontal, child:
      Padding(padding: EdgeInsets.only(left: 12, right: 12, top: 12), child:
        Row(children: <Widget>[
          // Hide the "Categories" drop down in Inbox panel (#721)
          /*FilterSelectorWidget(
            label: _FilterEntry.entryInList(_categories, _selectedCategory)?.name ?? '',
            active: _selectedFilter == _FilterType.Category,
            visible: true,
            onTap: () { _onFilter(_FilterType.Category); }
          ),*/
          FilterSelectorWidget(
            label: _FilterEntry.entryInList(_times, _selectedTime)?.name ?? '',
            active: _selectedFilter == _FilterType.Time,
            visible: true,
            onTap: () { _onFilter(_FilterType.Time); }
          ),
        ],
    ),),);
  }

  void _onFilter(_FilterType filterType) {
    setState(() {
      _selectedFilter = (filterType != _selectedFilter) ? filterType : null;
    });
  }

  // Content

  void _loadinInitialContent() {
    List<DateTime> dates = _getTimeDates(_selectedTime);
    DateTime startDate = ((dates != null) && (0 < dates.length)) ? dates[0] : null;
    DateTime endDate = ((dates != null) && (1 < dates.length)) ? dates[1] : null;

    setState(() {
      _loading = true;
    });

    Inbox().loadMessages(offset: 0, limit: _messagesPageSize, category: _selectedCategory, startDate: startDate, endDate: endDate).then((List<InboxMessage> messages) {
      if (mounted) {
        setState(() {
          if (messages != null) {
            _messages = messages;
            _hasMoreMessages = (_messagesPageSize <= messages.length);
          }
          else {
            _messages.clear();
            _hasMoreMessages = null;
          }
          _loading = false;
        });
      }
    });
  }

  void _loadinMoreContent() {
    List<DateTime> dates = _getTimeDates(_selectedTime);
    DateTime startDate = ((dates != null) && (0 < dates.length)) ? dates[0] : null;
    DateTime endDate = ((dates != null) && (1 < dates.length)) ? dates[1] : null;

    setState(() {
      _loadingMore = true;
    });

    Inbox().loadMessages(offset: _messages.length, limit: _messagesPageSize, category: _selectedCategory, startDate: startDate, endDate: endDate).then((List<InboxMessage> messages) {
      if (mounted) {
        setState(() {
          if (messages != null) {
            _messages.addAll(messages);
            _hasMoreMessages = (_messagesPageSize <= messages.length);
          }
          _loadingMore = false;
        });
      }
    });
  }

  void _scrollListener() {
    if ((_scrollController.offset >= _scrollController.position.maxScrollExtent) && (_hasMoreMessages != false) && (_loadingMore != true) && (_loading != true)) {
      _loadinMoreContent();
    }
  }
}

class _FilterEntry {
  final String _name;
  final dynamic _value;
  _FilterEntry({String name, dynamic value}) :
    _name = name ?? value?.toString(),
    _value = value;

  String get name => _name;
  dynamic get value => _value;
  
  static _FilterEntry entryInList(List<_FilterEntry> entries, dynamic value) {
    if (entries != null) {
      for (_FilterEntry entry in entries) {
        if (entry.value == value) {
          return entry;
        }
      }
    }
    return null;
  }
  
}

enum _TimeFilter {
  Today, TodayAndYesterday, ThisWeek, LastWeek, ThisMonth, LastMonth
}

enum _FilterType {
  Category, Time
}

class _InboxMessageCard extends StatefulWidget {
  final InboxMessage message;
  _InboxMessageCard({this.message});

  @override
  _InboxMessageCardState createState() {
    return _InboxMessageCardState();
  }
}

class _InboxMessageCardState extends State<_InboxMessageCard> implements NotificationsListener {

  bool _isFavorite;

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [
      User.notifyFavoritesUpdated,
    ]);
    _isFavorite = User().isFavorite(widget.message);
  }

  @override
  void dispose() {
    super.dispose();
    NotificationService().unsubscribe(this);
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == User.notifyFavoritesUpdated) {
      setState(() {
        _isFavorite = User().isFavorite(widget.message);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child:
      Container(
        decoration: BoxDecoration(
          color: Styles().colors.white,
          borderRadius: BorderRadius.all(Radius.circular(4)),
          boxShadow: [BoxShadow(color: Styles().colors.blackTransparent018, spreadRadius: 2.0, blurRadius: 6.0, offset: Offset(2, 2))]
        ),
        clipBehavior: Clip.none,
        child: Stack(children: [
          Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16), child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            AppString.isStringNotEmpty(widget.message?.category) ?
              Padding(padding: EdgeInsets.only(bottom: 3), child:
                Row(children: [
                  Expanded(child:
                    Text(widget.message?.category ?? '', style: TextStyle(fontFamily: Styles().fontFamilies.bold, fontSize: 16, color: Styles().colors.fillColorPrimary))
              )])) : Container(),
            

            AppString.isStringNotEmpty(widget.message?.subject) ?
              Padding(padding: EdgeInsets.only(bottom: 4), child:
                Row(children: [
                  Expanded(child:
                    Text(widget.message?.subject ?? '', style: TextStyle(fontFamily: Styles().fontFamilies.extraBold, fontSize: 20, color: Styles().colors.fillColorPrimary))
              )])) : Container(),

            AppString.isStringNotEmpty(widget.message?.body) ?
              Padding(padding: EdgeInsets.only(bottom: 6), child:
                Row(children: [
                  Expanded(child:
                    Text(widget.message?.body ?? '', style: TextStyle(fontFamily: Styles().fontFamilies.regular, fontSize: 16, color: Styles().colors.textBackground))
              )])) : Container(),

            Row(children: [
              Expanded(child:
                Text(widget.message?.displayInfo ?? '', style: TextStyle(fontFamily: Styles().fontFamilies.regular, fontSize: 14, color: Styles().colors.textSurface))
            )]),
          
          ])),
          Container(color: Styles().colors.fillColorSecondary, height: 4),
          Visibility(visible: User().favoritesStarVisible, child:
            Align(alignment: Alignment.topRight, child:
            Semantics(
              label: _isFavorite
                  ? Localization().getStringEx('widget.card.button.favorite.off.title', 'Remove From Favorites')
                  : Localization().getStringEx('widget.card.button.favorite.on.title', 'Add To Favorites'),
              hint: _isFavorite
                  ? Localization().getStringEx('widget.card.button.favorite.off.hint', '')
                  : Localization().getStringEx('widget.card.button.favorite.on.hint', ''),
              button: true,
              child:
              GestureDetector(onTap: _onTapFavorite, child:
                Container(padding: EdgeInsets.all(9), child:
                  Image.asset(_isFavorite ? 'images/icon-star-selected.png' : 'images/icon-star.png', excludeFromSemantics: true,)
            ),)),),),
        ],)
    ),);
  }

  void _onTapFavorite() {
    Analytics.instance.logSelect(target: "Favorite: ${widget.message.subject}");
    setState(() {
      User().switchFavorite(widget.message);
    });
  }
}