import 'package:flutter/material.dart';

import '../../../providers/add_receipt_provider.dart';

/// Input nama merchant dengan dropdown suggestion dari merchant yang
/// sudah pernah dipakai. User tetap bebas ketik nama baru kalau
/// merchant-nya belum ada di daftar.
class MerchantAutocompleteField extends StatefulWidget {
  final AddReceiptProvider provider;

  const MerchantAutocompleteField({super.key, required this.provider});

  @override
  State<MerchantAutocompleteField> createState() =>
      _MerchantAutocompleteFieldState();
}

class _MerchantAutocompleteFieldState extends State<MerchantAutocompleteField> {
  // Autocomplete mewajibkan focusNode & textEditingController diisi
  // barengan (harus dua-duanya null atau dua-duanya diisi), jadi kita
  // buat FocusNode sendiri di sini.
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;

    return Autocomplete<String>(
      textEditingController: provider.merchantController,
      focusNode: _focusNode,
      optionsBuilder: (TextEditingValue textEditingValue) {
        final query = textEditingValue.text.trim().toLowerCase();
        if (query.isEmpty) {
          return provider.merchantSuggestions;
        }
        return provider.merchantSuggestions.where(
          (name) => name.toLowerCase().contains(query),
        );
      },
      onSelected: (String selection) {
        provider.merchantController.text = selection;
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.storefront_outlined, size: 18),
                    title: Text(option),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
      fieldViewBuilder:
          (context, textEditingController, focusNode, onFieldSubmitted) {
            return TextFormField(
              controller: textEditingController,
              focusNode: focusNode,
              decoration: InputDecoration(
                labelText: 'Nama Merchant',
                hintText: 'Ketik atau pilih merchant',
                prefixIcon: const Icon(Icons.storefront_outlined),
                suffixIcon: provider.isLoadingMerchants
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
              textCapitalization: TextCapitalization.words,
            );
          },
    );
  }
}
