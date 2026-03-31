import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String formatShortDate(BuildContext context, DateTime date) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  return DateFormat.yMd(locale).format(date);
}

String formatIsoLikeDate(BuildContext context, DateTime date) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  if (locale.startsWith('zh')) {
    return DateFormat('yyyy-MM-dd', locale).format(date);
  }
  return DateFormat.yMd(locale).format(date);
}
