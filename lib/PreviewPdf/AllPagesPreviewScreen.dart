import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';

import '../PanelModel/Project.dart';
import '../PreviewPdf/PDFPageFormat.dart';
import '../utils/pdf_page_export.dart';
import '../utils/page_canvas_builder.dart';
class AllPagesPreviewScreen extends StatefulWidget {
  final List<List<LayoutPanel>> pages;
  final String projectName;
  final String pageFormat;

  const AllPagesPreviewScreen({
    super.key,
    required this.pages,
    required this.projectName,
    required this.pageFormat,
  });

  @override
  State<AllPagesPreviewScreen> createState() => _AllPagesPreviewScreenState();
}

class _AllPagesPreviewScreenState extends State<AllPagesPreviewScreen> {
  late final PageController _pageController;
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Size get _pageSize => PDFPageFormat.formats[widget.pageFormat]!;

  @override
  Widget build(BuildContext context) {
    final pageSize = _pageSize;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${widget.projectName} - Preview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _showExportOptions,
            tooltip: 'Export All Pages',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.black,
            padding: const EdgeInsets.all(16),
            child: Text(
              'Page ${_currentPageIndex + 1} of ${widget.pages.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentPageIndex = index),
              itemCount: widget.pages.length,
              itemBuilder: (context, pageIndex) {
                final page = widget.pages[pageIndex];
                return Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey, width: 2),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: AspectRatio(
                      aspectRatio: pageSize.width / pageSize.height,
                      child: PageCanvasBuilder.build(
                        panels: page,
                        canvasWidth: pageSize.width,
                        canvasHeight: pageSize.height,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            color: Colors.black,
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _currentPageIndex > 0
                      ? () => _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          )
                      : null,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Previous'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: const Text('Close'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _currentPageIndex < widget.pages.length - 1
                      ? () => _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          )
                      : null,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Next'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showExportOptions() {
    Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => _generatePdfFromWidget(),
    );
  }

  Future<Uint8List> _generatePdfFromWidget() async {
    final pageSize = _pageSize;
    return exportPagesToPdf(
      context: context,
      pages: widget.pages,
      canvasWidth: pageSize.width,
      canvasHeight: pageSize.height,
    );
  }
}
