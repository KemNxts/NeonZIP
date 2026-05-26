import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_theme.dart';
import '../services/player_progress_service.dart';
import 'bouncing_button.dart';

class RateUsModal extends StatefulWidget {
  const RateUsModal({super.key});

  @override
  State<RateUsModal> createState() => _RateUsModalState();
}

class _RateUsModalState extends State<RateUsModal> {
  int _selectedStars = 0;

  void _handleRate(BuildContext context, PlayerProgressService progress) {
    if (_selectedStars >= 4) {
      // Simulate url_launcher to native store
      // e.g. launchUrl(Uri.parse('market://details?id=YOUR_PACKAGENAME'));
      progress.markHasRated();
    } else if (_selectedStars > 0) {
      // Lower than 4 stars: just say thanks and consider it rated internally 
      // (or let them send private feedback).
      progress.markHasRated();
    }
    Navigator.of(context).pop();
  }

  void _handleMaybeLater(BuildContext context, PlayerProgressService progress) {
    progress.resetUnratedWinStreak(); // Backs off until the next big streak
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.zipTheme;
    final progress = Provider.of<PlayerProgressService>(context, listen: false);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          _handleMaybeLater(context, progress);
        }
      },
      child: Dialog(
        backgroundColor: theme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enjoying NeonZIP?',
                style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Your support helps us build more levels!',
                style: TextStyle(
                  color: theme.textSecondary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedStars = index + 1;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Icon(
                        index < _selectedStars ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: index < _selectedStars ? theme.warning : theme.surfaceAlt,
                        size: 44,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),
              BouncingButton(
                onPressed: _selectedStars > 0 ? () => _handleRate(context, progress) : () {},
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _selectedStars > 0 ? theme.accent : theme.surfaceAlt,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      'Rate on Play Store',
                      style: TextStyle(
                        color: _selectedStars > 0 ? Colors.white : theme.textSecondary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _handleMaybeLater(context, progress),
                child: Text(
                  'Maybe Later',
                  style: TextStyle(
                    color: theme.textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
