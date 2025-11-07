import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../data/models/country.dart';

class CountryDetailDialog extends StatelessWidget {
  final Country country;

  const CountryDetailDialog({
    super.key,
    required this.country,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(country.nameOfficial),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (country.flagPng != null)
              Center(
                child: CachedNetworkImage(
                  imageUrl: country.flagPng!,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 16),
            if (country.cca2 != null)
              _buildDetailRow('Code (CCA2)', country.cca2!),
            if (country.cca3 != null) ...[
              const SizedBox(height: 8),
              _buildDetailRow('Code (CCA3)', country.cca3!),
            ],
            if (country.nativeNames.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildDetailRow('Native Names', country.nativeNames),
            ],
            if (country.altNames.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildDetailRow('Alternative Names', country.altNames),
            ],
            if (country.callingCodes.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildDetailRow('Calling Codes', country.callingCodes),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label:',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(value),
      ],
    );
  }
}
