import '../../l10n/app_localizations.dart';
import '../location/device_location.dart';

/// Maps canonical English place / subcity ids (API + seed data) to UI labels.
String localizedPlace(AppLocalizations l10n, String raw) {
  final key = raw.trim();
  if (key.isEmpty) return raw;
  return switch (key) {
    'Addis Ababa' => l10n.placeAddisAbaba,
    'Addis Ketema' => l10n.placeAddisKetema,
    'Arada' => l10n.placeArada,
    'Bole' => l10n.placeBole,
    'Bole Airport' => l10n.placeBoleAirport,
    'Bole Atlas' => l10n.placeBoleAtlas,
    'CMC' => l10n.placeCmc,
    'CMC Michael' => l10n.placeCmcMichael,
    'Gulele' => l10n.placeGulele,
    'Kazanchis' => l10n.placeKazanchis,
    'Kirkos' => l10n.placeKirkos,
    'Lideta' => l10n.placeLideta,
    'Mexico Square' => l10n.placeMexicoSquare,
    'Nifas Silk' => l10n.placeNifasSilk,
    'Piassa' => l10n.placePiassa,
    'Sarbet' => l10n.placeSarbet,
    'Yeka' => l10n.placeYeka,
    _ => raw,
  };
}

/// Localize a comma-separated coverage list (e.g. `Bole, CMC`).
String localizedPlaceList(AppLocalizations l10n, String csv) {
  return csv
      .split(',')
      .map((part) => localizedPlace(l10n, part.trim()))
      .where((part) => part.isNotEmpty)
      .join('${l10n.listSeparator} ');
}

String localizedVehicleClass(AppLocalizations l10n, String vehicleClass) {
  if (vehicleClass == 'Economy') return l10n.rideVehicleEconomy;
  return vehicleClass;
}

String deviceLocationMessage(
  AppLocalizations l10n,
  DeviceLocationException exception,
) {
  return switch (exception.code) {
    DeviceLocationCode.turnOn => l10n.locationTurnOn,
    DeviceLocationCode.denied => l10n.locationDenied,
    DeviceLocationCode.blocked => l10n.locationBlocked,
    DeviceLocationCode.noPickupPlaces => l10n.locationNoPickupPlaces,
  };
}
