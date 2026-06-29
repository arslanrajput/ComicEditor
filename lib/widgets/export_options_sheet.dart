import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../PanelModel/Project.dart';
import '../services/app_settings.dart';
import '../utils/image_page_export.dart';
import '../utils/pdf_page_export.dart';

/// Shared export sheet: PDF, PNG pages, or both.
Future<void> showComicExportSheet({
  required BuildContext context,
  required List<List<LayoutPanel>> pages,
  required String projectName,
  required String pageFormatKey,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Export “$projectName”',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${pages.length} page(s) · $pageFormatKey · '
              '${AppSettings.exportPixelRatio.toStringAsFixed(1)}× quality',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: const Text('Export as PDF'),
              subtitle: const Text('Print or share multi-page PDF'),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  await Printing.layoutPdf(
                    onLayout: (_) => exportPagesToPdf(
                      context: context,
                      pages: pages,
                      pageFormatKey: pageFormatKey,
                      pixelRatio: AppSettings.exportPixelRatio,
                    ),
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('PDF ready to share')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Export failed: $e')),
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: const Text('Export as PNG images'),
              subtitle: const Text('One PNG per page — great for social'),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  await sharePagesAsPng(
                    context: context,
                    pages: pages,
                    projectName: projectName,
                    pageFormatKey: pageFormatKey,
                  );
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('PNG export failed: $e')),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    ),
  );
}
