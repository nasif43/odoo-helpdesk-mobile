import 'package:flutter/material.dart';

class AttachmentViewerScreen extends StatelessWidget {
  final String fileName;
  final String? url;
  final String? mimeType;
  final int? fileSize;

  const AttachmentViewerScreen({
    super.key,
    required this.fileName,
    this.url,
    this.mimeType,
    this.fileSize,
  });

  bool get _isImage {
    final mime = mimeType?.toLowerCase() ?? '';
    final name = fileName.toLowerCase();
    return mime.startsWith('image/') ||
        name.endsWith('.png') ||
        name.endsWith('.jpg') ||
        name.endsWith('.jpeg') ||
        name.endsWith('.gif') ||
        name.endsWith('.webp');
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null || bytes == 0) return '0 KB';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          fileName,
          style: const TextStyle(fontSize: 16, color: Colors.white),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Sharing $fileName...')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.download_outlined, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Downloading $fileName...')),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: _isImage && url != null
            ? InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  url!,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => _buildDocFallback(),
                ),
              )
            : _buildDocFallback(),
      ),
    );
  }

  Widget _buildDocFallback() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.insert_drive_file_outlined, size: 80, color: Colors.white70),
        const SizedBox(height: 16),
        Text(
          fileName,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          '${mimeType ?? "Document"} • ${_formatFileSize(fileSize)}',
          style: const TextStyle(color: Colors.white60, fontSize: 14),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          icon: const Icon(Icons.download),
          label: const Text('Download File'),
          onPressed: () {},
        ),
      ],
    );
  }
}
