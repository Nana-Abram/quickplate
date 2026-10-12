import 'package:flutter/foundation.dart';

import '../core/errors/app_exception.dart';
import '../data/models/menu_category.dart';
import '../data/models/restaurant.dart';
import '../data/repositories/restaurant_repository.dart';
import 'view_state.dart';

/// Menu for one restaurant. Created with its screen and disposed with it.
class MenuProvider extends ChangeNotifier {
  MenuProvider(this._repository, this.restaurantId)
    : _restaurant = _repository.cachedRestaurant(restaurantId);

  final RestaurantRepository _repository;
  final String restaurantId;

  ViewState _state = ViewState.idle;
  Restaurant? _restaurant;
  List<MenuCategory> _categories = const [];
  String? _errorMessage;
  bool _disposed = false;

  ViewState get state => _state;

  /// Available straight away when the restaurant came from the home list.
  Restaurant? get restaurant => _restaurant;
  List<MenuCategory> get categories => _categories;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _state = ViewState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _restaurant ??= await _repository.getRestaurant(restaurantId);
      final menu = await _repository.getMenu(restaurantId);
      _categories = menu.where((c) => c.items.isNotEmpty).toList();
      _state = _categories.isEmpty ? ViewState.empty : ViewState.success;
    } on AppException catch (error) {
      _errorMessage = error.message;
      _state = ViewState.error;
    }
    notifyListeners();
  }

  // The user can leave the screen while a request is in flight.
  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
