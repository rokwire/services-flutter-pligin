import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rokwire_plugin/model/places.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'auth2.dart';
import 'config.dart';
import 'network.dart';

class PlacesService {
  static final PlacesService _instance = PlacesService._internal();

  factory PlacesService() => _instance;

  PlacesService._internal();

  /// Retrieves all places based on provided filters.
  Future<List<Place>?> getAllPlaces({
    List<String>? ids,
    List<String>? types,
    List<String>? tags,
  }) async {
    Map<String, String> queryParams = {};

    if (ids != null && ids.isNotEmpty) queryParams['ids'] = ids.join(',');
    if (types != null && types.isNotEmpty) queryParams['types'] = types.join(',');
    if (tags != null && tags.isNotEmpty) queryParams['tags'] = tags.join(',');

    Uri uri;
    try {
      uri = Uri.parse('${Config().placesUrl}/places').replace(queryParameters: queryParams);
    } catch (e) {
      debugPrint('Failed to parse URI: $e');
      return null;
    }

    try {
      final response = await Network().get(uri.toString(), auth: Auth2());

      if (response?.statusCode == 200) {
        List<dynamic>? jsonList = JsonUtils.decodeList(response?.body);
        if (jsonList != null) {
          try {
            return Place.listFromJson(jsonList);
          } catch (e) {
            debugPrint('Failed to parse places: $e');
            return null;
          }
        } else {
          debugPrint('Failed to decode places list');
          return null;
        }
      } else {
        debugPrint('Failed to load places: ${response?.statusCode} ${response?.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Network error while fetching places: $e');
      return null;
    }
  }

  /// Updates the 'visited' status of a place.
  Future<Place?> updatePlaceVisited(String id, bool visited) async {
    Map<String, String> queryParams = {'visited': visited.toString()};

    Uri uri;
    try {
      uri = Uri.parse('${Config().placesUrl}/places/visited/$id').replace(queryParameters: queryParams);
    } catch (e) {
      debugPrint('Failed to parse URI: $e');
      return null;
    }

    try {
      final response = await Network().put(
        uri.toString(),
        headers: {'Content-Type': 'application/json'},
        auth: Auth2(),
      );

      if (response?.statusCode == 200) {
        Map<String, dynamic>? jsonMap = JsonUtils.decodeMap(response?.body);
        if (jsonMap != null) {
          try {
            return Place.fromJson(jsonMap);
          } catch (e) {
            debugPrint('Failed to parse place from JSON: $e');
            return null;
          }
        } else {
          debugPrint('Failed to decode response body');
          return null;
        }
      } else {
        debugPrint('Failed to update place visited status: ${response?.statusCode} ${response?.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Network error while updating place visited status: $e');
      return null;
    }
  }
}
