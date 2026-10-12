import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/errors/app_exception.dart';
import '../core/utils/debouncer.dart';
import '../data/models/paged_result.dart';
import '../data/models/restaurant.dart';
import '../data/repositories/restaurant_repository.dart';
import 'view_state.dart';

/// The home list: search, category filter and cursor pagination.
class RestaurantsProvider extends ChangeNotifier {
  RestaurantsProvider(
    this._repository, {
    Duration searchDelay = const Duration(milliseconds: 400),
  }) : _searchDebouncer = Debouncer(searchDelay);

  static const int pageSize = 10;

  final RestaurantRepository _repository;
  final Debouncer _searchDebouncer;

  ViewState _state = ViewState.idle;
  List<Restaurant> _restaurants = const [];
  String? _errorMessage;
  String _query = '';
  String? _category;
  String? _nextCursor;
  bool _isLoadingMore = false;
  String? _loadMoreError;

  // Bumped on every reload so a slow response for an old search or filter
  // can never overwrite the results of a newer one.
  int _generation = 0;

  ViewState get state => _state;
  List<Restaurant> get restaurants => _restaurants;
  String? get errorMessage => _errorMessage;
  String get query => _query;
  String? get category => _category;
  bool get hasFilters => _query.isNotEmpty || _category != null;
  bool get hasMore => _nextCursor != null;
  bool get isLoadingMore => _isLoadingMore;
  String? get loadMoreError => _loadMoreError;

  /// Loads the first page once; later calls do nothing.
  Future<void> loadInitial() async {
    if (_state != ViewState.idle) return;
    await _reload();
  }

  Future<void> retry() => _reload();

  /// Pull-to-refresh: keeps the current list on screen while reloading.
  Future<void> refresh() => _reload(keepVisible: true);

  void search(String query) {
    final trimmed = query.trim();
    if (trimmed == _query) return;
    _query = trimmed;
    _searchDebouncer.run(() => unawaited(_reload()));
  }

  Future<void> selectCategory(String? category) async {
    if (category == _category) return;
    _category = category;
    _searchDebouncer.cancel();
    await _reload();
  }

  Future<void> clearFilters() async {
    _query = '';
    _category = null;
    _searchDebouncer.cancel();
    await _reload();
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || _nextCursor == null || _state != ViewState.success) {
      return;
    }
    final generation = _generation;
    _isLoadingMore = true;
    _loadMoreError = null;
    notifyListeners();

    try {
      final page = await _fetch(cursor: _nextCursor);
      if (generation != _generation) return;
      _restaurants = [..._restaurants, ...page.items];
      _nextCursor = page.nextCursor;
    } on AppException catch (error) {
      if (generation != _generation) return;
      _loadMoreError = error.message;
    } finally {
      if (generation == _generation) {
        _isLoadingMore = false;
        notifyListeners();
      }
    }
  }

  Future<void> _reload({bool keepVisible = false}) async {
    final generation = ++_generation;
    _nextCursor = null;
    _isLoadingMore = false;
    _loadMoreError = null;
    if (!keepVisible || _state != ViewState.success) {
      _state = ViewState.loading;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final page = await _fetch();
      if (generation != _generation) return;
      _restaurants = page.items;
      _nextCursor = page.nextCursor;
      _errorMessage = null;
      _state = page.items.isEmpty ? ViewState.empty : ViewState.success;
    } on AppException catch (error) {
      if (generation != _generation) return;
      _errorMessage = error.message;
      _state = ViewState.error;
    }
    notifyListeners();
  }

  Future<PagedResult<Restaurant>> _fetch({String? cursor}) {
    return _repository.getRestaurants(
      query: _query.isEmpty ? null : _query,
      category: _category,
      limit: pageSize,
      cursor: cursor,
    );
  }

  @override
  void dispose() {
    _searchDebouncer.cancel();
    super.dispose();
  }
}
