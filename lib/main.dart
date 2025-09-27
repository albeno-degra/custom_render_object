import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

const kScaleThreshold = 0.05;
const kDistanceSquaredThreshold = 2.0;
const kScaleStep = 0.1;
const kMinScale = 0.1;
const kMaxScale = 1.0;
const kSpacing = 72.0;
const kPointRadius = 6.0;
const kSubpointInterval = 10.0;
const kInitialCanvasScale = 0.5;
const kInitialGestureScale = 1.0;
const Color kPointColor = Colors.teal;

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(body: InfiniteDotsGridWidget()),
    ),
  );
}

class InfiniteDotsGridWidget extends StatefulWidget {
  const InfiniteDotsGridWidget({super.key});

  @override
  State<InfiniteDotsGridWidget> createState() => _InfiniteDotsGridWidgetState();
}

class _InfiniteDotsGridWidgetState extends State<InfiniteDotsGridWidget> {
  final GlobalKey _gridKey = GlobalKey();
  double _lastScale = kInitialGestureScale;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onScaleUpdate: (details) {
        final delta = details.scale - _lastScale;

        final render =
            _gridKey.currentContext!.findRenderObject()!
                as RenderInfiniteDotsGrid;

        if (delta.abs() > kScaleThreshold) {
          render
            ..startScaling()
            ..updateZoom(zoomIn: delta > 0);
          _lastScale = details.scale;
        }
      },
      onScaleEnd: (_) {
        (_gridKey.currentContext!.findRenderObject()! as RenderInfiniteDotsGrid)
            .stopScaling();
        _lastScale = kInitialGestureScale;
      },
      child: SizedBox.expand(
        child: InfiniteDotsGrid(
          key: _gridKey,
        ),
      ),
    );
  }
}

class InfiniteDotsGrid extends LeafRenderObjectWidget {
  const InfiniteDotsGrid({super.key});

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderInfiniteDotsGrid();
  }
}

class RenderInfiniteDotsGrid extends RenderBox {
  final double spacing = kSpacing;
  final double pointRadius = kPointRadius;
  final Color pointColor = kPointColor;
  double _scale = kInitialCanvasScale;

  Offset _offset = Offset.zero;
  Offset? _lastDragPos;
  bool _isScaling = false;

  void startScaling() => _isScaling = true;
  void stopScaling() => _isScaling = false;

  @override
  void performLayout() {
    size = constraints.biggest;
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  void handleEvent(PointerEvent event, HitTestEntry entry) {
    if (_isScaling) return;
    if (event is PointerDownEvent) {
      _lastDragPos = event.localPosition;
    } else if (event is PointerMoveEvent && event.down) {
      if (_lastDragPos != null) {
        final delta = event.localPosition - _lastDragPos!;
        if (delta.distanceSquared < kDistanceSquaredThreshold) return;
        _offset += delta;
        _lastDragPos = event.localPosition;
        markNeedsPaint();
      }
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      _lastDragPos = null;
    }
  }

  void updateZoom({bool zoomIn = true}) {
    const double step = kScaleStep;
    _scale = _scale + (zoomIn ? step : -step);
    _scale = double.parse(_scale.toStringAsFixed(1));
    if (_scale > kMaxScale) {
      _scale = kMinScale;
    } else if (_scale < kMinScale) {
      _scale = kMaxScale;
    }

    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas
      ..save()
      ..translate(_offset.dx, _offset.dy);

    final paint = Paint()
      ..color = pointColor
      ..style = PaintingStyle.fill;

    final scaledPointRadius = pointRadius * _scale;
    final scaledSpacing = spacing * _scale;

    assert(
      scaledPointRadius > 0,
      'Scaled point radius must be greater than zero',
    );

    final int startCol = ((-_offset.dx) / scaledSpacing).floor();
    final int endCol = ((size.width - _offset.dx) / scaledSpacing).ceil();
    final int startRow = ((-_offset.dy) / scaledSpacing).floor();
    final int endRow = ((size.height - _offset.dy) / scaledSpacing).ceil();

    for (int row = startRow; row <= endRow; row++) {
      for (int col = startCol; col <= endCol; col++) {
        final base = Offset(col * scaledSpacing, row * scaledSpacing);
        final isSuperDot =
            row % kSubpointInterval == 0 && col % kSubpointInterval == 0;

        if (isSuperDot) {
          canvas.drawCircle(
            base,
            scaledPointRadius * (scaledSpacing / scaledPointRadius),
            paint,
          );
        }
        canvas.drawCircle(base, scaledPointRadius, paint);
      }
    }

    canvas.restore();
  }
}
