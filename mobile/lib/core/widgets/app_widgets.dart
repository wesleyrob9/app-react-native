import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class LoadingWidget extends StatelessWidget {
  final String? message;
  const LoadingWidget({super.key, this.message});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(message!, style: const TextStyle(color: AppColors.textSecondary)),
            ],
          ],
        ),
      );
}

class AppErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const AppErrorWidget({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary)),
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                ElevatedButton(onPressed: onRetry, child: const Text('Tentar novamente')),
              ],
            ],
          ),
        ),
      );
}

class EmptyWidget extends StatelessWidget {
  final String message;
  final IconData icon;
  const EmptyWidget({super.key, required this.message, this.icon = Icons.inbox_outlined});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.textSecondary, size: 64),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 16)),
            ],
          ),
        ),
      );
}

class StarRating extends StatelessWidget {
  final int stars;
  final int maxStars;
  final double size;
  const StarRating({super.key, required this.stars, this.maxStars = 5, this.size = 16});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(maxStars, (i) => Icon(
          i < stars ? Icons.star : Icons.star_border,
          color: AppColors.starColor,
          size: size,
        )),
      );
}

class PosicaoBadge extends StatelessWidget {
  final String? posicao;
  const PosicaoBadge({super.key, required this.posicao});

  Color get _color {
    switch (posicao ?? '') {
      case 'Goleiro': return Colors.orange.shade700;
      case 'Zagueiro': return Colors.blue.shade700;
      case 'Meio': return Colors.indigo;
      case 'Atacante': return Colors.red.shade700;
      // legado
      case 'Lateral': return Colors.teal;
      case 'Volante': return Colors.purple;
      case 'Meio-campo': return Colors.indigo;
      case 'Meia-atacante': return Colors.cyan.shade700;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (posicao == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _color.withOpacity(0.4)),
      ),
      child: Text(posicao!, style: TextStyle(fontSize: 11, color: _color, fontWeight: FontWeight.w600)),
    );
  }
}

class RoleBadge extends StatelessWidget {
  final String papel;
  const RoleBadge({super.key, required this.papel});

  @override
  Widget build(BuildContext context) {
    if (papel != 'admin') return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.adminBadge.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.adminBadge.withOpacity(0.4)),
      ),
      child: const Text('Admin', style: TextStyle(fontSize: 11, color: AppColors.adminBadge, fontWeight: FontWeight.w600)),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const SectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            if (trailing != null) trailing!,
          ],
        ),
      );
}
