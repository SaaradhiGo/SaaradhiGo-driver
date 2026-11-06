/// The app's strings for a widget, in English when the host (a test, say)
/// has no localizations delegate.
library;

import 'package:flutter/widgets.dart';

import '../l10n/app_localizations.dart';

export '../l10n/app_localizations.dart' show AppLocalizations;

AppLocalizations sgL10n(BuildContext context) =>
    Localizations.of<AppLocalizations>(context, AppLocalizations) ??
    lookupAppLocalizations(const Locale('en'));
