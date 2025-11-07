import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import '../models/country.dart';

class ApiService {
  static const String _baseUrl = 'https://restcountries.com/v3.1';

  Future<List<Country>> getCountries() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/all?fields=name,cca2,cca3,flags,idd,altSpellings'),
      );

      debugPrint('Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Country.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load countries');
      }
    } catch (e) {
      throw Exception('Error fetching countries: $e');
    }
  }

  Future<Country> getCountryByCode(String code) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/alpha/$code'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return Country.fromJson(data.first);
      } else {
        throw Exception('Failed to load country');
      }
    } catch (e) {
      throw Exception('Error fetching country: $e');
    }
  }

  Future<List<Country>> searchCountries(String query) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/name/$query'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Country.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }
}
