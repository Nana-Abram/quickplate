import '../models/address.dart';
import '../services/address_book_service.dart';

class AddressBookRepository {
  AddressBookRepository(this._service);

  final AddressBookService _service;

  Future<List<Address>> load(String uid) => _service.load(uid);

  Future<void> save(String uid, List<Address> addresses) =>
      _service.save(uid, addresses);
}
