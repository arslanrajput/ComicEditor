/// Normalized panel bounds (0–1) within the preview page area.
typedef PreviewPanel = ({double left, double top, double right, double bottom});

const _p = 0.07;
const _g = 0.04;

List<PreviewPanel> previewPanelsForTemplate(String templateId) {
  switch (templateId) {
    case 'grid_2x2':
      return _grid(cols: 2, rows: 2);
    case 'grid_3x2':
      return _grid(cols: 3, rows: 2);
    case 'grid_2x3':
      return _grid(cols: 2, rows: 3);
    case 'single_column':
      return _grid(cols: 1, rows: 3);
    case 'webtoon':
      return _grid(cols: 1, rows: 4);
    case 'two_column':
      return _grid(cols: 2, rows: 1);
    case 'three_column':
      return _grid(cols: 3, rows: 1);
    case 'two_row':
      return _grid(cols: 1, rows: 2);
    case 'single_splash':
      return [_panel(_p, _p, 1 - _p, 1 - _p)];
    case 'comic_strip':
      return _horizontalStrip(count: 3, panelHeight: 0.52);
    case 'four_strip':
      return _horizontalStrip(count: 4, panelHeight: 0.48);
    case 'header_content':
      return [
        _panel(_p, _p, 1 - _p, _p + 0.18),
        _panel(_p, _p + 0.22, 1 - _p, 1 - _p),
      ];
    case 'manga_page':
      final split = _p + (1 - 2 * _p - _g) * 0.58;
      final midY = _p + (1 - 2 * _p - _g) / 2 + _g / 2;
      return [
        _panel(_p, _p, split, 1 - _p),
        _panel(split + _g, _p, 1 - _p, midY - _g / 2),
        _panel(split + _g, midY + _g / 2, 1 - _p, 1 - _p),
      ];
    case 'magazine':
      final split = _p + (1 - 2 * _p - _g) * 0.6;
      final sideMid = _p + (1 - 2 * _p) * 0.32 + _g / 2;
      return [
        _panel(_p, _p, split, 1 - _p),
        _panel(split + _g, _p, 1 - _p, sideMid - _g / 2),
        _panel(split + _g, sideMid + _g / 2, 1 - _p, 1 - _p),
      ];
    case 'five_panel':
      final topH = _p + (1 - 2 * _p - _g) * 0.36;
      final bottomTop = topH + _g;
      final cellW = (1 - 2 * _p - _g) / 2;
      final cellH = (1 - bottomTop - _p - _g) / 2;
      return [
        _panel(_p, _p, 1 - _p, topH),
        _panel(_p, bottomTop, _p + cellW, bottomTop + cellH),
        _panel(_p + cellW + _g, bottomTop, 1 - _p, bottomTop + cellH),
        _panel(_p, bottomTop + cellH + _g, _p + cellW, 1 - _p),
        _panel(_p + cellW + _g, bottomTop + cellH + _g, 1 - _p, 1 - _p),
      ];
    case 'splash_three':
      final splashH = _p + (1 - 2 * _p - _g) * 0.5;
      final rowTop = splashH + _g;
      final cellW = (1 - 2 * _p - 2 * _g) / 3;
      return [
        _panel(_p, _p, 1 - _p, splashH),
        _panel(_p, rowTop, _p + cellW, 1 - _p),
        _panel(_p + cellW + _g, rowTop, _p + 2 * cellW + _g, 1 - _p),
        _panel(_p + 2 * cellW + 2 * _g, rowTop, 1 - _p, 1 - _p),
      ];
    case 'story_l':
      final mainW = _p + (1 - 2 * _p - _g) * 0.62;
      final mainH = _p + (1 - 2 * _p - _g) * 0.56;
      return [
        _panel(_p, _p, mainW, mainH),
        _panel(_p, mainH + _g, mainW, 1 - _p),
        _panel(mainW + _g, _p, 1 - _p, 1 - _p),
      ];
    default:
      return const [];
  }
}

PreviewPanel _panel(double left, double top, double right, double bottom) =>
    (left: left, top: top, right: right, bottom: bottom);

List<PreviewPanel> _grid({
  required int cols,
  required int rows,
}) {
  final contentW = 1 - 2 * _p;
  final contentH = 1 - 2 * _p;
  final cellW = (contentW - (cols - 1) * _g) / cols;
  final cellH = (contentH - (rows - 1) * _g) / rows;

  return [
    for (var row = 0; row < rows; row++)
      for (var col = 0; col < cols; col++)
        _panel(
          _p + col * (cellW + _g),
          _p + row * (cellH + _g),
          _p + col * (cellW + _g) + cellW,
          _p + row * (cellH + _g) + cellH,
        ),
  ];
}

List<PreviewPanel> _horizontalStrip({
  required int count,
  required double panelHeight,
}) {
  final contentW = 1 - 2 * _p;
  final cellW = (contentW - (count - 1) * _g) / count;
  final top = (1 - panelHeight) / 2;
  final bottom = top + panelHeight;

  return [
    for (var i = 0; i < count; i++)
      _panel(
        _p + i * (cellW + _g),
        top,
        _p + i * (cellW + _g) + cellW,
        bottom,
      ),
  ];
}
