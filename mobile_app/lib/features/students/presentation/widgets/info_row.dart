import 'package:flutter/material.dart';

class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.label, required this.value});
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: t.bodyMedium?.copyWith(color: Colors.grey)),
          ),
          Expanded(child: Text(value?.isNotEmpty == true ? value! : '—', style: t.bodyMedium)),
        ],
      ),
    );
  }
}