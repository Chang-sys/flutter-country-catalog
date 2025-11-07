import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../data/models/country.dart';

class CountryTile extends StatelessWidget {
  final Country country;
  final VoidCallback? onTap;

  const CountryTile({super.key, required this.country, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: country.flagPng != null
          ? CachedNetworkImage(
              imageUrl: country.flagPng!,
              width: 40,
              height: 30,
              fit: BoxFit.cover,
              placeholder: (context, url) => const SizedBox(
                width: 40,
                height: 30,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              errorWidget: (context, url, error) => const Icon(Icons.flag),
            )
          : const Icon(Icons.flag),
      title: Text(country.nameOfficial),
      subtitle: Text.rich(
        TextSpan(
          children: [
            if (country.nativeNames.isNotEmpty)
              TextSpan(
                text: country.nativeNames,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            if (country.nativeNames.isNotEmpty && country.cca2 != null)
              const TextSpan(text: '  •  '),
            if (country.cca2 != null)
              TextSpan(
                text: '${country.cca2}',
                style: const TextStyle(color: Colors.grey),
              ),
          ],
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
