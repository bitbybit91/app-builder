import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../models/offer.dart';
import '../services/api_service.dart';

class OfferProvider extends ChangeNotifier {
  List<Offer> _offers = [];
  Offer? _selectedOffer;
  bool _loading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;
  String? _filterType;
  String? _filterCurrency;
  String? _filterPaymentMethod;

  List<Offer> get offers => _offers;
  Offer? get selectedOffer => _selectedOffer;
  bool get loading => _loading;
  String? get error => _error;
  bool get hasMore => _hasMore;

  Future<void> fetchOffers({bool refresh = false}) async {
    if (_loading) return;
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _offers = [];
    }
    if (!_hasMore) return;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final queryParams = <String, String>{
        'page': _currentPage.toString(),
      };
      if (_filterType != null) queryParams['type'] = _filterType!;
      if (_filterCurrency != null) queryParams['currency'] = _filterCurrency!;
      if (_filterPaymentMethod != null) {
        queryParams['payment_method'] = _filterPaymentMethod!;
      }

      final query = Uri(queryParameters: queryParams).query;
      final endpoint = '${ApiEndpoints.offers}?$query';
      final response = await ApiService.instance.get(endpoint);

      final data = response as Map<String, dynamic>;
      final items = (data['data'] as List<dynamic>? ?? [])
          .map((e) => Offer.fromJson(e as Map<String, dynamic>))
          .toList();

      _offers.addAll(items);
      final meta = data['meta'] as Map<String, dynamic>?;
      final lastPage = meta?['last_page'] as int? ?? 1;
      _hasMore = _currentPage < lastPage;
      _currentPage++;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> fetchOffer(int id) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await ApiService.instance.get(ApiEndpoints.offerById(id));
      final data = response as Map<String, dynamic>;
      _selectedOffer = Offer.fromJson(data['data'] as Map<String, dynamic>? ?? data);
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> createOffer(Map<String, dynamic> data) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await ApiService.instance.post(ApiEndpoints.offers, body: data);
      final responseData = response as Map<String, dynamic>;
      final newOffer = Offer.fromJson(
        responseData['data'] as Map<String, dynamic>? ?? responseData,
      );
      _offers.insert(0, newOffer);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> updateOffer(int id, Map<String, dynamic> data) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await ApiService.instance.put(ApiEndpoints.offerById(id), body: data);
      final responseData = response as Map<String, dynamic>;
      final updated = Offer.fromJson(
        responseData['data'] as Map<String, dynamic>? ?? responseData,
      );
      final idx = _offers.indexWhere((o) => o.id == id);
      if (idx != -1) _offers[idx] = updated;
      if (_selectedOffer?.id == id) _selectedOffer = updated;
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteOffer(int id) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await ApiService.instance.delete(ApiEndpoints.offerById(id));
      _offers.removeWhere((o) => o.id == id);
      if (_selectedOffer?.id == id) _selectedOffer = null;
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void setFilter({String? type, String? currency, String? paymentMethod}) {
    _filterType = type;
    _filterCurrency = currency;
    _filterPaymentMethod = paymentMethod;
    fetchOffers(refresh: true);
  }
}
