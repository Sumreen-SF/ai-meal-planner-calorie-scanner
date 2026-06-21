import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ErrorCard extends StatelessWidget {
  final String message;
  const ErrorCard({super.key, required this.message});

  bool get _isKeyError =>
      message.toLowerCase().contains('api key') ||
          message.toLowerCase().contains('401') ||
          message.toLowerCase().contains('unauthorized');

  bool get _isNetworkError =>
      message.toLowerCase().contains('internet') ||
          message.toLowerCase().contains('network') ||
          message.toLowerCase().contains('socket');

  String get _title {
    if (_isKeyError) return 'API Key Required';
    if (_isNetworkError) return 'No Connection';
    return 'Something went wrong';
  }

  String get _emoji {
    if (_isKeyError) return '🔑';
    if (_isNetworkError) return '📡';
    return '⚠️';
  }

  String get _hint {
    if (_isKeyError) {
      return 'Open lib/services/ai_service.dart and replace YOUR_XAI_API_KEY with your real key from console.x.ai';
    }
    if (_isNetworkError) {
      return 'Check your Wi-Fi or mobile data connection and try again.';
    }
    return 'Check the debug console for details.';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.error.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(_emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Text(
                _title,
                style: const TextStyle(
                  color: AppTheme.error,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Raw error message in a monospace box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFFF9A9A),
                fontSize: 12,
                fontFamily: 'monospace',
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded,
                  color: AppTheme.textMuted, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _hint,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}