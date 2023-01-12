# Changelog
All notable changes to this library will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased
<!-- The next build on `develop` should refer to version 1.4.0 -->
### Changed
- Switch to xCode 14.2.
- Delete poll notification is not a lifecycle notification any more [#2173](https://github.com/rokwire/illinois-app/issues/2173).
- Improve default handling for UIImages [#193](https://github.com/rokwire/app-flutter-plugin/issues/193)
### Fixed
- Clear unread notifications count when logged out.
- Formatting date times when using device local time zone [#240](https://github.com/rokwire/app-flutter-plugin/issues/240).
### Added
- Added hint in VerticalTitleValueSection [#2892](https://github.com/rokwire/illinois-app/issues/2892).
- Acknowledge the new group date fields [#244](https://github.com/rokwire/app-flutter-plugin/issues/244).
- Load poll by id [#2645](https://github.com/rokwire/illinois-app/issues/2645).

## [1.3.1] - 2023-01-03
### Deleted
- Removed category from inbox message model [#237](https://github.com/rokwire/app-flutter-plugin/issues/237).

## [1.3.0] - 2022-12-22
### Fixed
- Fix launchUrlString LaunchMode [#167](https://github.com/rokwire/app-flutter-plugin/issues/167).
- Move "getContentString" method to Localization service [#136](https://github.com/rokwire/app-flutter-plugin/issues/136).
- Improve SectionSlantHeader [#211](https://github.com/rokwire/app-flutter-plugin/issues/211).
- Crash in header bar widget [#2654](https://github.com/rokwire/illinois-app/issues/2654).
- Crash on tapping image in detail panels [#223](https://github.com/rokwire/app-flutter-plugin/issues/223).
- Survey bug fixes [#219](https://github.com/rokwire/app-flutter-plugin/issues/219)
- Privacy level is not getting saved property [#222](https://github.com/rokwire/app-flutter-plugin/issues/222)
- Missing close button from ModalImagePanel[#227](https://github.com/rokwire/app-flutter-plugin/issues/227).
- Fixed Groups.notifyGroupCreated notification param [#2683](https://github.com/rokwire/illinois-app/issues/2683).
- Hide "Vote" button after user selectes all options in a poll [#2776](https://github.com/rokwire/illinois-app/issues/2776).
- Improve accessibility for surveys [#234](https://github.com/rokwire/app-flutter-plugin/issues/234)
### Added
- Image/icon abstraction [#145](https://github.com/rokwire/app-flutter-plugin/issues/145)
- Added TextStyle capability to pass custom metadata values like color or height [#2311](https://github.com/rokwire/illinois-app/issues/2311).
- Added TextStyle properties to Styles service. Added: decoration and wordSpacing [#2311](https://github.com/rokwire/illinois-app/issues/2311).
- Search group by name support hidden groups [#2403](https://github.com/rokwire/illinois-app/issues/2403).
- Added answers section to Auth2UserProfile [#174](https://github.com/rokwire/app-flutter-plugin/issues/174).
- Intermediate work on "muted" and "unread" notifications [#177](https://github.com/rokwire/app-flutter-plugin/issues/177).
- Add survey UI components [#161](https://github.com/rokwire/app-flutter-plugin/issues/161).
- Introduce ModalImageHolder widget  [#2474](https://github.com/rokwire/illinois-app/issues/2474).
- Introduced research projects [#178](https://github.com/rokwire/app-flutter-plugin/issues/178).
- Survey rules local notifications action [#179](https://github.com/rokwire/app-flutter-plugin/issues/179)
- Acknowledge group member's notification preferences [#198](https://github.com/rokwire/app-flutter-plugin/issues/198)
- Added researchConfirmation flag to Groups [#202](https://github.com/rokwire/app-flutter-plugin/issues/202).
- Survey rules remote notification action [#188](https://github.com/rokwire/app-flutter-plugin/issues/188)
- Added API for loading target audience count in Groups service [#2544](https://github.com/rokwire/illinois-app/issues/2544).
- Implement "Mark all as read" [#2570](https://github.com/rokwire/illinois-app/issues/2570).
- Survey improvements for BESSI [#206](https://github.com/rokwire/app-flutter-plugin/issues/206)
- Add additional group settings [#2619](https://github.com/rokwire/illinois-app/issues/2619).
- Delete survey responses request [#210](https://github.com/rokwire/app-flutter-plugin/issues/210).
- Support font family references in text styles [#213](https://github.com/rokwire/app-flutter-plugin/issues/213).
- Create utility method for launching urls [#217](https://github.com/rokwire/app-flutter-plugin/issues/217).
- Added Explore.exploreLocationDescription interface [#2633](https://github.com/rokwire/illinois-app/issues/2633).
- Support for FlexUI-based access widget [#229](https://github.com/rokwire/app-flutter-plugin/issues/229).
- Fire local notification when message is read [#2833](https://github.com/rokwire/illinois-app/issues/2833).
### Deleted
- Removed Auth2.canFavorite [#2325](https://github.com/rokwire/illinois-app/issues/2325).
- Removed UserRole.resident [#2547](https://github.com/rokwire/illinois-app/issues/2547).
### Changed
- Optimized Groups /user/login API call [#141](https://github.com/rokwire/app-flutter-plugin/issues/141).
- Android: Upgrade compileSdkVersion to 32 [#147](https://github.com/rokwire/app-flutter-plugin/issues/147).
- Upgrade project to build with flutter 3.3.2 [#158](https://github.com/rokwire/app-flutter-plugin/issues/158).
- Applied preliminary work on multiple brands support [#149](https://github.com/rokwire/app-flutter-plugin/issues/149).
- Updated version of firebase_messaging plugin [#2446](https://github.com/rokwire/illinois-app/issues/2446).
- Store research questionnaire answers in account profile [#181](https://github.com/rokwire/app-flutter-plugin/issues/181).
- Cleaned up group model.
- Hook Notifications BB message model changes [#2530](https://github.com/rokwire/illinois-app/issues/2530).
- Researh Project updates in group model [#204](https://github.com/rokwire/app-flutter-plugin/issues/204).
- Filter open resource projects not to include projects where the current user is member, disable paging until this gets resolved on the backend [#2540](https://github.com/rokwire/illinois-app/issues/2540).
- Acknowledged 'exclude_my_groups' parameter for loading open research projects [#2540](https://github.com/rokwire/illinois-app/issues/2540).
- Omit null title/value in VerticalTitleValueSection [#2542](https://github.com/rokwire/illinois-app/issues/2542).
- ExploreLocation updated from ExplorePOI [#220](https://github.com/rokwire/app-flutter-plugin/issues/220).
- Introduce Surveys BB [#230](https://github.com/rokwire/app-flutter-plugin/issues/230)
- Acknowledge the new fields "mute" and "read" for InboxMessage [#2778](https://github.com/rokwire/illinois-app/issues/2778).
- Read messages count from a proper json field [#2833](https://github.com/rokwire/illinois-app/issues/2833).

## [1.2.4] - 2022-09-30
### Added
- Check if user has 'managed_group_admin' permission [#2429](https://github.com/rokwire/illinois-app/issues/2429).

## [1.2.3] - 2022-09-28
### Changed
- Show hidden groups only for admins - hide for all others [#163](https://github.com/rokwire/app-flutter-plugin/issues/163).

## [1.2.2] - 2022-09-16
### Added
- Search group by name support hidden groups [#2403](https://github.com/rokwire/illinois-app/issues/2403).

## [1.2.1] - 2022-09-13
### Added
- Load single group post by id [#2344](https://github.com/rokwire/illinois-app/issues/2344).
- Created AppNotification service [#143](https://github.com/rokwire/app-flutter-plugin/issues/143).
- Add reactions to group posts [#151](https://github.com/rokwire/app-flutter-plugin/issues/151)
### Changed
- Acknowledge "can_poll" in nudges data model [#2365](https://github.com/rokwire/illinois-app/issues/2365).
### Fixed
- Fixed text overflow in TabWidget [#152](https://github.com/rokwire/app-flutter-plugin/issues/152).

## [1.2.0] - 2022-08-15
### Fixed
- Use simple getter for deep link redirect url [#2065](https://github.com/rokwire/illinois-app/issues/2065).
- Properly convert colors that contain adjacent zeros [#122](https://github.com/rokwire/app-flutter-plugin/issues/122).
### Changed
- Allow referring string values from app config in FlexUI service [#118](https://github.com/rokwire/app-flutter-plugin/issues/118).
- Added Auth2UserPres.setFavorite method; use Iterable inetead of List for muliple favorites paramter [#2065](https://github.com/rokwire/illinois-app/issues/2065).
- FlexUI extended with content entry switch and multiple {content, rules} sets in single source  [#121](https://github.com/rokwire/app-flutter-plugin/issues/121).
- Acknowledged new paramters of 'report/abuse' API of Groups BB [#2083](https://github.com/rokwire/illinois-app/issues/2083).
- Refresh Auth2 account object instead of profile and prefs separately [#132](https://github.com/rokwire/app-flutter-plugin/issues/132).
- Updated format of settings APIs in Auth2UserPrefs [#2194](https://github.com/rokwire/illinois-app/issues/2194).
- Do not load all groups on portions (paging) [#125](https://github.com/rokwire/app-flutter-plugin/issues/125).
### Added
- Differ multi events and events that last more than one day [#126](https://github.com/rokwire/app-flutter-plugin/issues/126).
- Added Config().appStoreId getter [#2162](https://github.com/rokwire/illinois-app/issues/2162).
- Added MapUtils.get2 helper [#2169](https://github.com/rokwire/illinois-app/issues/2169).
- Check if event ends in the same year as it starts [#128](https://github.com/rokwire/app-flutter-plugin/issues/128).
- Load groups and members on portions (e.g. paging) [#125](https://github.com/rokwire/app-flutter-plugin/issues/125).
- Added system configs in Auth2Account [#132](https://github.com/rokwire/app-flutter-plugin/issues/132).
- Added int settings getter in Auth2UserPrefs [#2207](https://github.com/rokwire/illinois-app/issues/2207).
- Added config settings refs support for FlexUI enabled rules [#2210](https://github.com/rokwire/illinois-app/issues/2210).


## [1.1.0] - 2022-07-19
### Changed
- Added GeoFence location rules in FlexUI [#62](https://github.com/rokwire/app-flutter-plugin/issues/62).
- GeoFence service updated to load regions from content BB [#91](https://github.com/rokwire/app-flutter-plugin/issues/91).
- Cleaned up Favorites, prepare for UIUC 4 features [#88](https://github.com/rokwire/app-flutter-plugin/issues/88).
- Preserve the order of Favorite items [#88](https://github.com/rokwire/app-flutter-plugin/issues/88).
- StringUtils.capitalize extended to process sentences [#88](https://github.com/rokwire/app-flutter-plugin/issues/88).
- Removed Group polls hook methods [#1679](https://github.com/rokwire/app-flutter-plugin/issues/1679).
- Do not delete automatically empty favorites sections [#88](https://github.com/rokwire/app-flutter-plugin/issues/88).
- Updated Groups.reportAbuse API [1854](https://github.com/rokwire/illinois-app/issues/1854).
- Update inbox Sent By message [#1958](https://github.com/rokwire/illinois-app/issues/1958).
- Check Post Nudges for list of group names or group with wild card [#113](https://github.com/rokwire/app-flutter-plugin/issues/113).
- Updated format of Favorite.toString [#2052](https://github.com/rokwire/illinois-app/issues/2052).
- Remove check for attendance group for authman sync call [#115](https://github.com/rokwire/app-flutter-plugin/issues/115).
### Fixed
- Fixed auth2AnonymousId storage key [#79](https://github.com/rokwire/app-flutter-plugin/issues/79).
- Handle "leftToRight" horizontal direction in TrianglePainter widget [#83](https://github.com/rokwire/app-flutter-plugin/issues/83).
- Update UserGroups when group firebase message is fired [#1605](https://github.com/rokwire/illinois-app/issues/1605).
- Fixed FlexUI service dependency [#88](https://github.com/rokwire/app-flutter-plugin/issues/88).
- Fixed equality check in Auth2UserProfile.setFavorites [#88](https://github.com/rokwire/app-flutter-plugin/issues/88).
- Send correct "ids" parameter when loading content items [#106](https://github.com/rokwire/app-flutter-plugin/issues/106).
### Added
- Acknowledge the field for hidden group [#81](https://github.com/rokwire/app-flutter-plugin/issues/81).
- Update Group API to hook polls  [#1617](https://github.com/rokwire/illinois-app/issues/1617).
- Added API call for content items [#1636](https://github.com/rokwire/illinois-app/issues/1636)
- Group Attendance [#94](https://github.com/rokwire/app-flutter-plugin/issues/94).
- Cache attended group members [#94](https://github.com/rokwire/app-flutter-plugin/issues/94).
- Added access to FlexUI content source [#88](https://github.com/rokwire/app-flutter-plugin/issues/88).
- Added methods for updating entire category of favorites [#88](https://github.com/rokwire/app-flutter-plugin/issues/88).
- StringUtils.capitalize extended with custom delimters [#88](https://github.com/rokwire/app-flutter-plugin/issues/88).
- Added FavoriteItem class [#88](https://github.com/rokwire/app-flutter-plugin/issues/88).
- Expose getter for user's first name [#102](https://github.com/rokwire/app-flutter-plugin/issues/102).
- Added DayPart parser utility to DateTimeUtils [#1822](https://github.com/rokwire/illinois-app/issues/1822).
- Added Groups.reportAbuse API [#1847](https://github.com/rokwire/illinois-app/issues/1847).
- Added DateTimeUtils util methods [#1692](https://github.com/rokwire/illinois-app/issues/1692).
- Added debugDisplayName getter in Service interface [#1869](https://github.com/rokwire/illinois-app/issues/1869).
- Load group post templates from the backend [#108](https://github.com/rokwire/app-flutter-plugin/issues/108).
- Added ListUtils.entry helper.
- Added delete API to Polls [#1954](https://github.com/rokwire/illinois-app/issues/1954).
- Defined equality operators to Event and Poll [#2020](https://github.com/rokwire/illinois-app/issues/2020).

## [1.0.2] - 2022-04-27
### Changed
- Bring back the old Polls BB [#76](https://github.com/rokwire/app-flutter-plugin/issues/76).

## [1.0.1] - 2022-04-20
### Changed
- Group service: linkEventToGroup implements members param [#1487](https://github.com/rokwire/illinois-app/issues/1487).
- GroupPost implements members param [#1450](https://github.com/rokwire/illinois-app/issues/1450).
- Group service: implement loadGroupEventMemberSelection [#1519](https://github.com/rokwire/illinois-app/issues/1519).
- Provide possibility for skipping notification when privacy level is changed [#63](https://github.com/rokwire/app-flutter-plugin/issues/63).
- Do not skip sending notification when changing privacy level [#65](https://github.com/rokwire/app-flutter-plugin/issues/65).
- Update favorite icon availability for privacy level 4+ [#68](https://github.com/rokwire/app-flutter-plugin/issues/68).
### Fixed
- Fixed crash on activity destroy in Android native side (#50).
- Image rotation before upload [#58](https://github.com/rokwire/app-flutter-plugin/issues/58).
### Added
- Get, Create, Update and Delete user's profile picture [#53](https://github.com/rokwire/app-flutter-plugin/issues/53).
- Send notification when user changes profile picture [#61](https://github.com/rokwire/app-flutter-plugin/issues/61).
- Integrate new Polls BB [#70](https://github.com/rokwire/app-flutter-plugin/issues/70).

## [1.0.0] - 2022-03-15
### Changed
- Updated homepage and author details in rokwire_plugin.podspec [#34](https://github.com/rokwire/app-flutter-plugin/issues/34).
### Added
- Added miscelanious controls to UI section [#2](https://github.com/rokwire/app-flutter-plugin/issues/2).
 
## [0.0.3] - 2022-03-17
### Fixed
- Wait for applyLogin in Auth2.processLoginResponse [#46](https://github.com/rokwire/app-flutter-plugin/issues/46).

## [0.0.2] - 2022-03-07
### Added
- OIDC auth result codes [#25](https://github.com/rokwire/app-flutter-plugin/issues/25).
- Add auth requests to new Core BB endpoints [#19](https://github.com/rokwire/app-flutter-plugin/issues/19).
- Group rules in FlexUI [#18](https://github.com/rokwire/app-flutter-plugin/issues/18).
- Fix issues with account linking [#11](https://github.com/rokwire/app-flutter-plugin/issues/11).
- Added capability to filter staled analytics packets before sending them to log service [#4](https://github.com/rokwire/app-flutter-plugin/issues/4).
- Added miscelanious controls to UI section [#2](https://github.com/rokwire/app-flutter-plugin/issues/2).
- Added progress capability to RoundedButton [#29](https://github.com/rokwire/app-flutter-plugin/issues/29).
### Changed
- Allow more functions in services to be overridden [#1](https://github.com/rokwire/app-flutter-plugin/issues/1).
- Content expose method uploadImage() [#1375](https://github.com/rokwire/illinois-app/issues/1375).
### Fixed
- Match Core BB JSON keys in Auth Profile [#22](https://github.com/rokwire/app-flutter-plugin/issues/22).
- Fixed crash in FlexContentWidget when no buttons definition persists.
- Android: plugin initialization [#27](https://github.com/rokwire/app-flutter-plugin/issues/27).
- Do not acknowledge pending membership in FlexUI [#31](https://github.com/rokwire/app-flutter-plugin/issues/31).

## [0.0.1] - 2022-02-07
### Added
- Rokwire plugin moved in own GIT repo [#1203](https://github.com/rokwire/illinois-app/issues/1203).


