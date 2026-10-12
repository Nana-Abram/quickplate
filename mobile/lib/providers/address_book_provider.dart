import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/errors/app_exception.dart';
import '../data/models/address.dart';
import '../data/models/app_user.dart';
import '../data/repositories/address_book_repository.dart';
import 'view_state.dart';

/// The signed-in user's saved delivery addresses, newest first. Changes are
/// shown at once and rolled back if saving fails.
class AddressBookProvider extends ChangeNotifier {
  AddressBookProvider(this._repository);

  static const int maxAddresses = 10;

  final AddressBookRepository _repository;

  String? _uid;
  ViewState _state = ViewState.idle;
  List<Address> _addresses = const [];
  String? _errorMessage;

  ViewState get state => _state;
  List<Address> get addresses => _addresses;
  String? get errorMessage => _errorMessage;

  /// Called by the proxy provider on every session change. It runs during a
  /// build, so loading starts in a microtask instead of notifying here.
  void onAuthChanged(AppUser? user) {
    if (user?.uid == _uid) return;
    _uid = user?.uid;
    _addresses = const [];
    _errorMessage = null;
    _state = ViewState.idle;
    if (user != null) unawaited(Future.microtask(load));
  }

  Future<void> load() async {
    final uid = _uid;
    if (uid == null) return;
    _state = ViewState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final addresses = await _repository.load(uid);
      if (uid != _uid) return;
      _addresses = addresses;
      _state = addresses.isEmpty ? ViewState.empty : ViewState.success;
    } on AppException catch (error) {
      if (uid != _uid) return;
      _errorMessage = error.message;
      _state = ViewState.error;
    }
    notifyListeners();
  }

  /// Saves [address] at the top. An address with the same label and line
  /// replaces the older copy, and only the newest [maxAddresses] are kept.
  Future<bool> add(Address address) {
    final others = _addresses.where(
      (saved) =>
          saved.label.toLowerCase() != address.label.toLowerCase() ||
          saved.line1.toLowerCase() != address.line1.toLowerCase(),
    );
    return _replace([address, ...others].take(maxAddresses).toList());
  }

  Future<bool> remove(Address address) {
    return _replace(_addresses.where((saved) => saved != address).toList());
  }

  Future<bool> _replace(List<Address> next) async {
    final uid = _uid;
    if (uid == null) return false;
    final previous = _addresses;
    final previousState = _state;
    _addresses = List.unmodifiable(next);
    _state = next.isEmpty ? ViewState.empty : ViewState.success;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.save(uid, next);
      return true;
    } on AppException catch (error) {
      if (uid != _uid) return false;
      _addresses = previous;
      _state = previousState;
      _errorMessage = error.message;
      notifyListeners();
      return false;
    }
  }
}
