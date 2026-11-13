import 'package:flutter/material.dart';
import 'package:mobile_app/features/home/presentation/pages/parent/home_theme.dart';
import 'package:mobile_app/features/home/presentation/widgets/parents/phone_call.dart';

/// Thẻ liên hệ nhanh (cô giáo, tài xế); bấm vào để gọi.
class ContactCard extends StatelessWidget {
  const ContactCard({
    super.key,
    required this.role,
    required this.name,
    required this.phone,
    required this.icon,
    required this.bg,
    required this.fg,
  });

  final String role;
  final String name;
  final String? phone;
  final IconData icon;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    final has = phone != null && phone!.trim().isNotEmpty;
    return Material(
      color: Colors.white,
      elevation: 1.5,
      shadowColor: const Color(0x2610224A),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => callPhone(context, phone),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                    child: Icon(icon, size: 20, color: fg),
                  ),
                  const Spacer(),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: has ? HomeColors.green : HomeColors.greySoft,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.call,
                        size: 18, color: has ? Colors.white : HomeColors.muted),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(role, style: homeText(12, FontWeight.w400, HomeColors.muted)),
              const SizedBox(height: 2),
              Text(name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: homeText(14, FontWeight.w700, HomeColors.ink)),
              Text(has ? phone! : 'Chưa có số điện thoại',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: homeText(12, FontWeight.w400, HomeColors.muted)),
            ],
          ),
        ),
      ),
    );
  }
}