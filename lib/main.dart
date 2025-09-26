import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

void main() {
  runApp(
    const MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox.expand(
            child: InfiniteDotsGrid(),
          ),
        ),
      ),
    ),
  );
}

class InfiniteDotsGrid extends LeafRenderObjectWidget {
  const InfiniteDotsGrid({super.key});

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderInfiniteDotsGrid();
  }
}

class RenderInfiniteDotsGrid extends RenderBox {
  final double _scale = 1;
  Offset _offset = Offset.zero;
  Offset? _lastDragPos;

  final double spacing = 40;
  final double pointRadius = 3;
  final Color pointColor = Colors.teal;

  @override
  void performLayout() {
    size = constraints.biggest;
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  void handleEvent(PointerEvent event, HitTestEntry entry) {
    if (event is PointerDownEvent) {
      _lastDragPos = event.localPosition;
    } else if (event is PointerMoveEvent && event.down) {
      if (_lastDragPos != null) {
        final delta = event.localPosition - _lastDragPos!;
        _offset += delta;
        _lastDragPos = event.localPosition;
        markNeedsPaint();
      }
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      _lastDragPos = null;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas
      ..save()
      ..translate(_offset.dx, _offset.dy)
      ..scale(_scale);

    final paint = Paint()
      ..color = pointColor
      ..style = PaintingStyle.fill;

    final startCol = (-_offset.dx / (_scale * spacing)).floor();
    final endCol = ((size.width - _offset.dx) / (_scale * spacing)).ceil();
    final startRow = (-_offset.dy / (_scale * spacing)).floor();
    final endRow = ((size.height - _offset.dy) / (_scale * spacing)).ceil();
    for (int row = startRow; row <= endRow; row++) {
      for (int col = startCol; col <= endCol; col++) {
        final base = Offset(col * spacing, row * spacing);
        canvas.drawCircle(base, pointRadius / _scale, paint);
      }
    }

    canvas.restore();
  }
}
