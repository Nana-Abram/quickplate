import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/map_config.dart';
import '../../data/models/address.dart';
import '../../providers/address_book_provider.dart';
import '../../providers/address_picker_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import 'widgets/pin_map.dart';

/// Full-screen map to choose where the order goes. Pops with an [Address].
class AddressPickerScreen extends StatefulWidget {
  const AddressPickerScreen({super.key, this.initialAddress});

  final Address? initialAddress;

  @override
  State<AddressPickerScreen> createState() => _AddressPickerScreenState();
}

class _AddressPickerScreenState extends State<AddressPickerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mapController = MapController();
  late final _label = TextEditingController(
    text: widget.initialAddress?.label ?? 'Home',
  );
  late final _line1 = TextEditingController(
    text: widget.initialAddress?.line1 ?? '',
  );
  bool _saveAddress = true;

  @override
  void dispose() {
    _mapController.dispose();
    _label.dispose();
    _line1.dispose();
    super.dispose();
  }

  Future<void> _useMyLocation() async {
    final picker = context.read<AddressPickerProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final location = await picker.locate();
    if (!mounted) return;
    if (location != null) {
      _mapController.move(location, MapConfig.locatedZoom);
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(picker.locateError ?? 'Could not find your location.'),
        persist: false,
        action: picker.canOpenSettings
            ? SnackBarAction(label: 'Settings', onPressed: picker.openSettings)
            : null,
      ),
    );
  }

  void _confirm() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final address = context.read<AddressPickerProvider>().buildAddress(
      label: _label.text,
      line1: _line1.text,
    );
    if (_saveAddress) {
      // Saving is a convenience; the order must not wait for it.
      unawaited(context.read<AddressBookProvider>().add(address));
    }
    context.pop(address);
  }

  @override
  Widget build(BuildContext context) {
    final picker = context.read<AddressPickerProvider>();
    final isLocating = context.select<AddressPickerProvider, bool>(
      (p) => p.isLocating,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Delivery address')),
      body: Column(
        children: [
          Expanded(
            child: PinMap(
              controller: _mapController,
              initialCenter: picker.center,
              onCenterChanged: picker.updateCenter,
              onLocate: _useMyLocation,
              isLocating: isLocating,
            ),
          ),
          Material(
            elevation: 8,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppTextField(
                        label: 'Address for the rider',
                        hint: 'Street, house number or landmark',
                        controller: _line1,
                        prefixIcon: Icons.home_outlined,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.next,
                        validator: (value) => (value?.trim().isEmpty ?? true)
                            ? 'Tell the rider where to find you.'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: 'Label',
                        hint: 'Home, Work, ...',
                        controller: _label,
                        prefixIcon: Icons.bookmark_outline,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _confirm(),
                      ),
                      CheckboxListTile(
                        value: _saveAddress,
                        onChanged: (value) =>
                            setState(() => _saveAddress = value ?? false),
                        title: const Text('Save to my addresses'),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      AppButton(label: 'Confirm address', onPressed: _confirm),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
