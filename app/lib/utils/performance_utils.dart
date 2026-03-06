import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import 'logger.dart';

/// Performance optimization utilities for the MuSheet app

/// PDF Document Cache Manager
class PdfCacheManager {
  static final PdfCacheManager _instance = PdfCacheManager._internal();
  factory PdfCacheManager() => _instance;
  PdfCacheManager._internal();

  final Map<String, PdfDocument> _cache = {};
  final int _maxCacheSize = 10; // Maximum number of PDFs to cache

  /// Get or load a PDF document with caching
  Future<PdfDocument> getDocument(String url) async {
    // Return cached document if available
    if (_cache.containsKey(url)) {
      return _cache[url]!;
    }

    // Load new document
    final document = await PdfDocument.openUri(Uri.parse(url));
    
    // Add to cache
    _addToCache(url, document);
    
    return document;
  }

  void _addToCache(String url, PdfDocument document) {
    // Remove oldest entry if cache is full
    if (_cache.length >= _maxCacheSize) {
      final firstKey = _cache.keys.first;
      _cache[firstKey]?.dispose();
      _cache.remove(firstKey);
    }
    
    _cache[url] = document;
  }

  /// Clear specific document from cache
  void clearDocument(String url) {
    if (_cache.containsKey(url)) {
      _cache[url]?.dispose();
      _cache.remove(url);
    }
  }

  /// Clear all cached documents
  void clearAll() {
    for (var doc in _cache.values) {
      doc.dispose();
    }
    _cache.clear();
  }

  /// Get cache size
  int get cacheSize => _cache.length;
}

/// Image Cache Manager for score thumbnails
class ImageCacheManager {
  static final ImageCacheManager _instance = ImageCacheManager._internal();
  factory ImageCacheManager() => _instance;
  ImageCacheManager._internal();

  /// Precache images for better performance
  Future<void> precacheImages(BuildContext context, List<String> imageUrls) async {
    for (final url in imageUrls) {
      try {
        await precacheImage(NetworkImage(url), context);
      } catch (e) {
        // Silently handle errors
        Log.d('IMAGE_CACHE', 'Failed to precache image: $url');
      }
    }
  }

  /// Clear image cache
  void clearCache() {
    imageCache.clear();
    imageCache.clearLiveImages();
  }
}

/// List Performance Optimizer
class ListPerformanceOptimizer {
  /// Calculate optimal item extent for list views
  static double calculateItemExtent({
    required int itemCount,
    required double availableHeight,
    double minItemHeight = 80,
    double maxItemHeight = 120,
  }) {
    if (itemCount == 0) return minItemHeight;
    
    final idealHeight = availableHeight / itemCount;
    return idealHeight.clamp(minItemHeight, maxItemHeight);
  }

  /// Get cache extent for ListView
  static double getCacheExtent(int itemCount) {
    if (itemCount < 20) return 500;
    if (itemCount < 50) return 1000;
    return 1500;
  }
}

/// Memory Optimization Helper
class MemoryOptimizer {
  /// Clean up resources when leaving a screen
  static void cleanupOnDispose() {
    // Force garbage collection hint
    Future.microtask(() {
      // This helps Flutter know it's a good time to GC
    });
  }

  /// Monitor memory usage (debug only)
  static void logMemoryUsage(String context) {
    Log.d('MEMORY', 'Memory checkpoint: $context');
  }
}

/// Debouncer for search and other frequent operations
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({this.delay = const Duration(milliseconds: 300)});

  void call(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void dispose() {
    _timer?.cancel();
  }
}

/// Throttler for limiting function calls
class Throttler {
  final Duration duration;
  DateTime? _lastCall;

  Throttler({this.duration = const Duration(milliseconds: 500)});

  bool shouldExecute() {
    final now = DateTime.now();
    if (_lastCall == null || now.difference(_lastCall!) >= duration) {
      _lastCall = now;
      return true;
    }
    return false;
  }

  void call(VoidCallback action) {
    if (shouldExecute()) {
      action();
    }
  }
}

/// Performance monitoring widget
class PerformanceMonitor extends StatelessWidget {
  final Widget child;
  final String label;
  final bool enabled;

  const PerformanceMonitor({
    super.key,
    required this.child,
    required this.label,
    this.enabled = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    return RepaintBoundary(
      child: child,
    );
  }
}

/// Lazy loading helper
class LazyLoader<T> {
  final Future<T> Function() loader;
  T? _data;
  bool _isLoading = false;
  bool _hasError = false;

  LazyLoader(this.loader);

  bool get isLoaded => _data != null;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  T? get data => _data;

  Future<T?> load() async {
    if (_data != null) return _data;
    if (_isLoading) return null;

    _isLoading = true;
    _hasError = false;

    try {
      _data = await loader();
      return _data;
    } catch (e) {
      _hasError = true;
      return null;
    } finally {
      _isLoading = false;
    }
  }

  void clear() {
    _data = null;
    _hasError = false;
  }
}
