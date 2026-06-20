enum StreamKpiStyleId {
  automatic,
  minimal,
  dense,
  glass,
  outline,
  solid,
  split;

  String get label {
    switch (this) {
      case StreamKpiStyleId.automatic: return 'Automatico';
      case StreamKpiStyleId.minimal: return 'Minimal';
      case StreamKpiStyleId.dense: return 'Dense';
      case StreamKpiStyleId.glass: return 'Glass';
      case StreamKpiStyleId.outline: return 'Outline';
      case StreamKpiStyleId.solid: return 'Solid';
      case StreamKpiStyleId.split: return 'Split';
    }
  }

  static StreamKpiStyleId fromString(String value) {
    return StreamKpiStyleId.values.firstWhere(
      (e) => e.name == value,
      orElse: () => StreamKpiStyleId.automatic,
    );
  }
}

enum StreamChartStyleId {
  automatic,
  soft,
  technical,
  highContrast,
  editorial;

  String get label {
    switch (this) {
      case StreamChartStyleId.automatic: return 'Automatico';
      case StreamChartStyleId.soft: return 'Morbido';
      case StreamChartStyleId.technical: return 'Tecnico';
      case StreamChartStyleId.highContrast: return 'Alto contrasto';
      case StreamChartStyleId.editorial: return 'Editoriale';
    }
  }

  static StreamChartStyleId fromString(String value) {
    return StreamChartStyleId.values.firstWhere(
      (e) => e.name == value,
      orElse: () => StreamChartStyleId.automatic,
    );
  }
}
