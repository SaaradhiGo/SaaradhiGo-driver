/// Trips that SaaradhiGo support ended or released.
///
/// The backend tells the trip socket two things, in `trip_status_update`
/// (servers/ride/operator_end.py, servers/ride/admin_trips.py):
///
///   * support ended a STARTED trip:  status `complete`, message
///     "Your ride was ended by SaaradhiGo support."
///   * support released a trip the driver had not yet reached:
///     status `cancel`, message "Your ride was cancelled by support."
///
/// There is no structured flag on the frame today, so the wording is the signal
/// (a backend gap, reported). The check is deliberately specific so an
/// ordinary completion or a rider cancellation can never match.
library;

bool isSupportEndMessage(String? message) =>
    (message ?? '').toLowerCase().contains('ended by saaradhigo');

bool isSupportCancelMessage(String? message) =>
    (message ?? '').toLowerCase().contains('cancelled by support');

/// The headline for a trip support ended.
const String kSupportEndedTitle = 'Trip ended by SaaradhiGo';

/// Shown when the trip ended as a safety incident or platform fault: the rider
/// paid nothing and SaaradhiGo pays the driver instead.
const String kSupportEndedPlatformPaid =
    'Trip ended by SaaradhiGo: earnings paid by SaaradhiGo';

/// The headline for a trip support released before pickup.
const String kSupportReleasedTitle = 'Trip cancelled by SaaradhiGo';
