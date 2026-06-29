import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../PanelModel/Project.dart';
import '../PreviewPdf/PDFPageFormat.dart';
import '../services/app_settings.dart';
import '../utils/page_canvas_builder.dart';

/// Fullscreen comic reader — tap edges to turn pages, webtoon scroll optional.
class ComicReaderScreen extends StatefulWidget {
  final List<List<LayoutPanel>> pages;
  final String projectName;
  final String pageFormat;

  const ComicReaderScreen({
    super.key,
    required this.pages,
    required this.projectName,
    this.pageFormat = 'A4',
  });

  @override
  State<ComicReaderScreen> createState() => _ComicReaderScreenState();
}

class _ComicReaderScreenState extends State<ComicReaderScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  bool _showChrome = true;
  bool _webtoonMode = false;
  bool _rtl = false;

  @override
  void initState() {
    super.initState();
    _webtoonMode = AppSettings.webtoonReaderMode;
    _rtl = AppSettings.readingDirection == 'rtl';
    _pageController = PageController(
      initialPage: _rtl ? widget.pages.length - 1 : 0,
    );
    _currentPage = _rtl ? widget.pages.length - 1 : 0;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _pageController.dispose();
    super.dispose();
  }

  Size get _pageSize => PDFPageFormat.formats[widget.pageFormat]!;

  void _toggleChrome() => setState(() => _showChrome = !_showChrome);

  void _goNext() {
    if (_webtoonMode) return;
    if (_rtl) {
      if (_currentPage > 0) {
        _pageController.previousPage(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    } else {
      if (_currentPage < widget.pages.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    }
  }

  void _goPrev() {
    if (_webtoonMode) return;
    if (_rtl) {
      if (_currentPage < widget.pages.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    } else {
      if (_currentPage > 0) {
        _pageController.previousPage(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_webtoonMode)
            _buildWebtoonScroll()
          else
            _buildPageReader(),
          if (_showChrome) _buildTopBar(),
          if (_showChrome && !_webtoonMode) _buildBottomHint(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        color: Colors.black.withValues(alpha: 0.75),
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 4,
          bottom: 8,
          left: 4,
          right: 4,
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: Text(
                widget.projectName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!_webtoonMode)
              Text(
                '${_currentPage + 1}/${widget.pages.length}',
                style: const TextStyle(color: Colors.white70),
              ),
            IconButton(
              icon: Icon(
                _webtoonMode ? Icons.view_day : Icons.view_stream,
                color: Colors.white,
              ),
              tooltip: _webtoonMode ? 'Page mode' : 'Webtoon mode',
              onPressed: () => setState(() => _webtoonMode = !_webtoonMode),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomHint() {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 12,
      left: 0,
      right: 0,
      child: Center(
        child: Text(
          _rtl
              ? 'Tap left for next · right for previous'
              : 'Tap left/right to turn pages',
          style: const TextStyle(color: Colors.white38, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildPageReader() {
    return Stack(
      children: [
        GestureDetector(
          onTap: _toggleChrome,
          child: PageView.builder(
            clipBehavior: Clip.none,
            controller: _pageController,
            reverse: _rtl,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: widget.pages.length,
            itemBuilder: (_, i) => _buildPage(widget.pages[i]),
          ),
        ),
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: 56,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _goPrev,
          ),
        ),
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          width: 56,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _goNext,
          ),
        ),
      ],
    );
  }

  Widget _buildWebtoonScroll() {
    return GestureDetector(
      onTap: _toggleChrome,
      child: ListView.builder(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + (_showChrome ? 56 : 8),
          bottom: MediaQuery.of(context).padding.bottom + 16,
          left: 8,
          right: 8,
        ),
        itemCount: widget.pages.length,
        itemBuilder: (_, i) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: LayoutBuilder(
              builder: (context, constraints) => PageCanvasBuilder.buildFittedPage(
                panels: widget.pages[i],
                formatKey: widget.pageFormat,
                maxWidth: constraints.maxWidth,
                maxHeight: constraints.maxWidth / (_pageSize.width / _pageSize.height),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPage(List<LayoutPanel> page) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: PageCanvasBuilder.buildFittedPage(
            panels: page,
            formatKey: widget.pageFormat,
            maxWidth: constraints.maxWidth,
            maxHeight: constraints.maxHeight,
          ),
        );
      },
    );
  }
}
