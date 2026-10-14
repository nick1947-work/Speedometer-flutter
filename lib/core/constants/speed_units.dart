enum SpeedUnit {
  kmh('km/h', 1.0, 'Kilometers per hour'),
  mph('mph', 0.621371, 'Miles per hour'),
  knot('knots', 0.539957, 'Nautical miles per hour');

  final String label;
  final double conversionFactorFromKmh;
  final String description;

  const SpeedUnit(this.label, this.conversionFactorFromKmh, this.description);

  double fromKmh(double kmh) => kmh * conversionFactorFromKmh;
  double toKmh(double value) => value / conversionFactorFromKmh;

  String formatSpeed(double kmh) {
    return fromKmh(kmh).toStringAsFixed(0);
  }

  String formatDistance(double meters) {
    if (this == SpeedUnit.mph) {
      final miles = meters / 1609.344;
      return miles >= 100 ? miles.toStringAsFixed(1) : miles.toStringAsFixed(2);
    } else if (this == SpeedUnit.knot) {
      final nauticalMiles = meters / 1852.0;
      return nauticalMiles >= 100 ? nauticalMiles.toStringAsFixed(1) : nauticalMiles.toStringAsFixed(2);
    } else {
      final km = meters / 1000.0;
      return km >= 100 ? km.toStringAsFixed(1) : km.toStringAsFixed(2);
    }
  }

  String distanceUnitLabel() {
    switch (this) {
      case SpeedUnit.mph:
        return 'mi';
      case SpeedUnit.knot:
        return 'NM';
      case SpeedUnit.kmh:
        return 'km';
    }
  }
}
