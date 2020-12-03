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

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/Event.dart';
import 'package:illinois/model/Explore.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Connectivity.dart';
import 'package:illinois/service/ExploreService.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/ui/explore/ExploreEventDetailPanel.dart';
import 'package:illinois/ui/widgets/FilterWidgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/RoundedButton.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:illinois/service/Styles.dart';

class GroupEventsContext {
  StreamController<void> eventsController = StreamController<void>();
  List<Event> _events;
  List<Event> get events => _events;
  set events(value){
    _events = value;
    eventsController.add(null);
  }
  
  GroupEventsContext({List<Event> events}) {
    _events = events;
  }

  void finish(){
    eventsController.close();
  }
}

class GroupFindEventPanel extends StatefulWidget{
  final GroupEventsContext groupContext;

  GroupFindEventPanel({@required this.groupContext});

  _GroupFindEventPanelState createState() => _GroupFindEventPanelState();
}

enum FilterType {none, eventCategories, tags, time}

class _GroupFindEventPanelState extends State<GroupFindEventPanel>{

  final ScrollController _scrollController = ScrollController();
  TextEditingController _textEditingController = TextEditingController();
  FocusNode _textFocusNode = FocusNode();

  bool _isCategoryLoading = false;
  bool _isEventLoading = false;
  bool get _isLoading => _isCategoryLoading || _isEventLoading;

  // Categories Filter
  final String _allCategoriesConst = Localization().getStringEx("panel.find_event.label.all_categories", "All categories");
  List<String> _eventCategories;
  String _selectedEventCategory;

  // Tags Filter
  final String _tagFilterAllTags = Localization().getStringEx('panel.find_event.filter.tags.all', 'All Tags');
  final String _tagFilterMyTags = Localization().getStringEx('panel.find_event.filter.tags.my', 'My Tags');
  List<String> _tags;
  String _selectedTag;

  // Time Filter
  final String _timeFilterUpcoming = Localization().getStringEx("panel.find_event.filter.time.upcoming","Upcoming");
  final String _timeFilterToday = Localization().getStringEx("panel.find_event.filter.time.today","Today");
  final String _timeFilterNextSevenDays = Localization().getStringEx("find_event.find_event.filter.time.next_7_days","Next 7 days");
  final String _timeFilterThisWeekend = Localization().getStringEx("panel.find_event.filter.time.this_weekend","This Weekend");
  final String _timeFilterNextMonth = Localization().getStringEx("panel.find_event.filter.time.next_30_days","Next 30 days");
  List<String> _time;
  String __selectedTime;
  String get _selectedTime => __selectedTime;
  set _selectedTime(String value){
    if(value != null && __selectedTime != value){
      __selectedTime = value;
      _loadEvents();
    }
  }

  // Events
  List<Event> _events;
  List<Event> _filteredEvents;
  final List<Event> _selectedEvents = List<Event>();
  final Set<String> _selectedEventIds = Set<String>();

  FilterType __activeFilterType = FilterType.none;
  bool get _hasActiveFilter{ return _activeFilterType != FilterType.none; }
  FilterType get _activeFilterType{ return __activeFilterType; }
  set _activeFilterType(FilterType value){
    if(__activeFilterType != value){
      __activeFilterType = value;
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedEventCategory = _allCategoriesConst;

    _loadFilters();
    _loadEventCategories();
    _loadEvents();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textFocusNode.dispose();
    _textEditingController.dispose();
    super.dispose();
  }

  void _loadFilters(){
    _tags = [_tagFilterAllTags, _tagFilterMyTags];
    _selectedTag = _tagFilterAllTags;

    _time = [_timeFilterUpcoming, _timeFilterToday, _timeFilterNextSevenDays, _timeFilterThisWeekend, _timeFilterNextMonth];
    _selectedTime = _timeFilterUpcoming;
  }

  void _loadEventCategories() {
    if (Connectivity().isNotOffline) {
      setState(() {_isCategoryLoading = true;});
      ExploreService().loadEventCategoriesEx().then((List<ExploreCategory> result) {
        _eventCategories = List<String>();
        _eventCategories.add(_allCategoriesConst);
        if(AppCollection.isCollectionNotEmpty(result)){
          _eventCategories.addAll(result.map((category)=>category.name));
        }
        setState(() {_isCategoryLoading = false;});
      });
    }
  }

  void _loadEvents() {
    if (Connectivity().isNotOffline) {
      setState(() {_isEventLoading = true;});

      EventTimeFilter eventFilter;
      // endDate should be null for Upcoming
      if(_selectedTime == _timeFilterToday){
        eventFilter = EventTimeFilter.today;
      } else if(_selectedTime == _timeFilterNextSevenDays){
        eventFilter = EventTimeFilter.next7Day;
      } else if(_selectedTime == _timeFilterThisWeekend){
        eventFilter = EventTimeFilter.thisWeekend;
      } else if(_selectedTime == _timeFilterNextMonth) {
        eventFilter = EventTimeFilter.next30Days;
      }

      ExploreService().loadEvents(searchText: _textEditingController.text, eventFilter: eventFilter).then((List<Explore> result) {
        _events = result;
        _isEventLoading = false;
        _applyFilter();
      });
    }
  }

  void _applyFilter(){
    _filteredEvents = _events != null ? _events.where((entry)=>(entry.category == _selectedEventCategory || _selectedEventCategory == _allCategoriesConst)).toList() : null;
    setState(() {});
    if(_scrollController.hasClients && _scrollController.offset > 0){
      _scrollController.jumpTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SimpleHeaderBarWithBack(
        context: context,
        backIconRes: 'images/icon-circle-close.png',
        titleWidget: Text(Localization().getStringEx("panel.find_event.header.title", "Find event"),
          style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontFamily: Styles().fontFamilies.extraBold,
              letterSpacing: 1.0),
        ),
      ),
      body: Column(
        children: <Widget>[
          _buildSearchHeading(),
          _buildFilterButtons(),
          Expanded(
            child: Stack(
              alignment: AlignmentDirectional.topCenter,
              children: <Widget>[
                Container(
                  color: Styles().colors.background,
                  child: _buildCardsContent(),
                ),
                Visibility(
                    visible: _hasActiveFilter,
                    child: _buildDimmedContainer()
                ),
                _hasActiveFilter
                    ? _buildFilterContent()
                    : Container(),
                _isLoading
                    ? _buildLoading()
                    : Container(),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            color: Styles().colors.white,
            child: RoundedButton(
              label: Localization().getStringEx("panel.find_event.button.add_selected_events.title", "Add (#) event to group").replaceAll("#", _selectedEvents.length.toString()),
              hint: Localization().getStringEx("panel.find_event.button.add_selected_events.hint", ""),
              backgroundColor: Styles().colors.white,
              textColor: Styles().colors.fillColorPrimary,
              borderColor: Styles().colors.fillColorSecondary,
              onTap: _onTapAddEvents,
            ),
          ),
        ],
      ),
      backgroundColor: Styles().colors.background,
    );
  }

  Widget _buildSearchHeading(){
    return Container(
      padding: EdgeInsets.only(left: 16),
      color: Styles().colors.fillColorPrimary,
      height: 48,
      child: Row(
        children: <Widget>[
          Flexible(
              child:
              Semantics(
                label: Localization().getStringEx('panel.find_event.field.search.title', 'Search'),
                hint: Localization().getStringEx('panel.find_event.field.search.hint', ''),
                textField: true,
                excludeSemantics: true,
                child: TextField(
                  controller: _textEditingController,
                  focusNode: _textFocusNode,
                  onSubmitted: (_) => _onTapSearch(),
                  cursorColor: Styles().colors.fillColorSecondary,
                  keyboardType: TextInputType.text,
                  style: TextStyle(
                      fontSize: 16,
                      fontFamily: Styles().fontFamilies.regular,
                      color: Styles().colors.white),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Styles().colors.white, fontSize: 16, fontFamily: Styles().fontFamilies.regular, ),
                    hintText: Localization().getStringEx("panel.find_event.label.search_event_by_title", "Search event by title"),
                  ),
                ),
              )
          ),
          Semantics(
              label: Localization().getStringEx('panel.find_event.button.clear.title', 'Clear'),
              hint: Localization().getStringEx('panel.find_event.button.clear.hint', ''),
              button: true,
              excludeSemantics: true,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: GestureDetector(
                  onTap: _onTapClear,
                  child: Image.asset(
                    'images/icon-x-orange.png',
                    width: 25,
                    height: 25,
                  ),
                ),
              )
          ),
          Semantics(
            label: Localization().getStringEx('panel.find_event.button.search.title', 'Search'),
            hint: Localization().getStringEx('panel.find_event.button.search.hint', ''),
            button: true,
            excludeSemantics: true,
            child: Padding(
              padding: EdgeInsets.all(12),
              child: GestureDetector(
                onTap: _onTapSearch,
                child: Image.asset(
                  'images/icon-search.png',
                  color: Styles().colors.fillColorSecondary,
                  width: 25,
                  height: 25,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButtons(){
    return Container(
      width: double.infinity,
      color: Styles().colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              _buildFilterButton(FilterType.eventCategories, _selectedEventCategory,"FilterByCategories"),
              Container(width: 12,),
              _buildFilterButton(FilterType.tags, _selectedTag, "FilterByTags"),
              Container(width: 12,),
              _buildFilterButton(FilterType.time, _selectedTime, "FilterByTime"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton(FilterType filterType, String selectedValue, String analyticsEvent){
    return FilterSelectorWidget(
      label: selectedValue,
      hint: "",
      active: (_activeFilterType == filterType),
      visible: true,
      onTap: (){
        Analytics.instance.logSelect(target: analyticsEvent);
        setState(() {
          _activeFilterType = (_activeFilterType != filterType) ? filterType : FilterType.none;
        });
      },
    );
  }

  Widget _buildFilterContent(){
    switch(_activeFilterType){
      case FilterType.eventCategories: return _buildFilterCategoryContent();
      case FilterType.tags: return _buildFilterTagsContent();
      case FilterType.time: return _buildFilterTimeContent();
      default: return Container();
    }
  }

  Widget _buildFilterTimeContent(){
    return _buildFilterContentEx(
        itemCount: _time.length,
        itemBuilder: (context, index) {
          return FilterListItemWidget(
            label: _time[index],
            selected: (_selectedTime == _time[index]),
            onTap: (){
              setState(() {
                _selectedTime = _time[index];
                _activeFilterType = FilterType.none;
                _applyFilter();
              });
            },
          );
        }
    );
  }

  Widget _buildFilterTagsContent(){
    return _buildFilterContentEx(
        itemCount: _tags.length,
        itemBuilder: (context, index) {
          return FilterListItemWidget(
            label: _tags[index],
            selected: (_selectedTag == _tags[index]),
            onTap: (){
              setState(() {
                _selectedTag = _tags[index];
                _activeFilterType = FilterType.none;
                _applyFilter();
              });
            },
          );
        }
    );
  }

  Widget _buildFilterCategoryContent(){
    return _buildFilterContentEx(
        itemCount: _eventCategories.length,
        itemBuilder: (context, index) {
          return FilterListItemWidget(
            label: _eventCategories[index],
            selected: (_selectedEventCategory == _eventCategories[index]),
            onTap: (){
              setState(() {
                _selectedEventCategory = _eventCategories[index];
                _activeFilterType = FilterType.none;
                _applyFilter();
              });
            },
          );
        }
    );
  }

  Widget _buildFilterContentEx({@required int itemCount, @required IndexedWidgetBuilder itemBuilder}){

    return Semantics(child:Padding(
        padding: EdgeInsets.only(left: 16, right: 16, top: 0, bottom: 40),
        child: Semantics(child:Container(
          decoration: BoxDecoration(
            color: Styles().colors.fillColorSecondary,
            borderRadius: BorderRadius.circular(5.0),
          ),
          child: Padding(
            padding: EdgeInsets.only(top: 2),
            child: Container(
              color: Colors.white,
              child: ListView.separated(
                shrinkWrap: true,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: Styles().colors.fillColorPrimaryTransparent03,
                ),
                itemCount: itemCount,
                itemBuilder: itemBuilder,
              ),
            ),
          ),
        ))));
  }

  Widget _buildDimmedContainer() {
    return BlockSemantics(child:GestureDetector(
        onTap: (){
          setState(() {
            _activeFilterType = FilterType.none;
          });
        },
        child: Container(color: Color(0x99000000)))
    );
  }

  Widget _buildLoading() {
    return Center(child: CircularProgressIndicator(),);
  }

  Widget _buildCardsContent(){
    if(!_isLoading) {
      return AppCollection.isCollectionNotEmpty(_filteredEvents)
        ? ListView.builder(
            controller: _scrollController,
            itemBuilder: (BuildContext context, int index) => _EventCard(
              event: _filteredEvents[index],
              selected: _selectedEventIds.contains(_filteredEvents[index].id),
              onSelectEvent: _onSelectedEvent,
              onDeselectEvent: _onDeselectedEvent,
            ),
            itemCount: _filteredEvents .length)
        :  Container(
            child: Center(child: Text(Localization().getStringEx('panel.find_event.label.search.empty',  "Unable to find events")),),
        );
    }
    else{
      return Container();
    }
  }

  void _onTapSearch() {
    Analytics.instance.logSelect(target: "Search");
    _textFocusNode.unfocus();
    if (AppString.isStringNotEmpty(_textEditingController.text)) {
      _loadEvents();
    }
  }

  void _onTapClear(){
    Analytics.instance.logSelect(target: "Clear");
    _textFocusNode.unfocus();
    if(AppString.isStringNotEmpty(_textEditingController.text)){
      _textEditingController.text = "";
      _loadEvents();
    }
  }

  void _onSelectedEvent(Event event){
    if(event != null) {
      _selectedEvents.add(event);
      _selectedEventIds.add(event.id);
      setState(() {});
    }
  }

  void _onDeselectedEvent(Event event){
    if(event != null) {
      _selectedEvents.removeWhere((entry)=>entry?.id == event?.id);
      _selectedEventIds.remove(event?.id);
      setState(() {});
    }
  }

  void _onTapAddEvents(){
    if(_selectedEvents.isEmpty){
      if(mounted ) {
        AppAlert.showDialogResult(context, Localization().getStringEx("panel.find_event.error.please_select.title", "Please select at least one event")).then((value) {
          Navigator.pop(context);
        });
        return;
      }
    }
    widget.groupContext.events = _selectedEvents;
    Navigator.pop(context);
  }
}

class _EventCard extends StatefulWidget {
  final Event event;
  final bool selected;
  final Function(Event) onSelectEvent;
  final Function(Event) onDeselectEvent;

  _EventCard({@required this.event, this.selected = false, @required this.onSelectEvent, @required  this.onDeselectEvent});

  _EventCardState createState() => _EventCardState();
}

class _EventCardState extends State<_EventCard>{

  bool _selected = false;

  @override
  void initState() {
    _selected = widget.selected;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16, top: 16,),
      child: Row(
        children: <Widget>[
          Container(
            width: 60,
            height: 60,
            child: Center(
              child: Checkbox(
                value: _selected,
                onChanged: (value){
                  _onSelectionChanged(value);
                },
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: ()=>_onTapEvent(context),
              child: Container(
                decoration: BoxDecoration(
                  color: Styles().colors.white,
                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(4), bottomRight: Radius.circular(4)),
                ),
                child: Column(
                  children: <Widget>[
                    Container(height: 4, color: Styles().colors.fillColorSecondary,),
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(AppString.isStringNotEmpty(widget.event.exploreTitle) ? widget.event.exploreTitle : "",
                            style: TextStyle(
                              fontFamily: Styles().fontFamilies.extraBold,
                              fontSize: 20,
                              color: Styles().colors.fillColorPrimary
                            ),
                          ),
                          Container(height: 4,),
                          _exploreTimeDetail()
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _exploreTimeDetail() {
    String displayTime = widget.event.timeDisplayString;
    if (AppString.isStringEmpty(displayTime)) {
      return Container();
    }
    return Semantics(label: displayTime, child: Row(
      children: <Widget>[
        Image.asset('images/icon-calendar.png'),
        Container(width: 7,),
        Flexible(child: Text(displayTime, overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: TextStyle(
                fontFamily: Styles().fontFamilies.medium,
                fontSize: 14,
                color: Styles().colors.textBackground)),)
      ],
    ));
  }

  void _onSelectionChanged(bool value){
    setState(() {
      _selected = value;
      if(_selected){
        widget.onSelectEvent(widget.event);
      }
      else{
        widget.onDeselectEvent(widget.event);
      }
    });
  }

  void _onTapEvent(BuildContext context){
    Navigator.push(context, CupertinoPageRoute(builder: (context)=>ExploreEventDetailPanel(event: widget.event,)));
  }
}