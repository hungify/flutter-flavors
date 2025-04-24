import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:xml/xml.dart';

class District {
  final String id;
  final String path;

  District({required this.id, required this.path});
}

class InteractableSvg extends StatefulWidget {
  final String svgAddress;
  final void Function(String id)? onChanged;
  final double width;
  final double height;
  final bool toggleEnable;
  final bool isMultiSelectable;
  final Color dotColor;
  final Color selectedColor;
  final Color strokeColor;
  final String? unSelectableId;
  final bool centerDotEnable;
  final bool centerTextEnable;
  final double strokeWidth;
  final TextStyle centerTextStyle;

  const InteractableSvg({
    super.key,
    required this.svgAddress,
    this.onChanged,
    required this.width,
    required this.height,
    this.toggleEnable = true,
    this.isMultiSelectable = false,
    this.dotColor = Colors.black,
    this.selectedColor = const Color(0xFF00FF00),
    this.strokeColor = Colors.blue,
    this.unSelectableId,
    this.centerDotEnable = false,
    this.centerTextEnable = false,
    this.strokeWidth = 2.0,
    this.centerTextStyle = const TextStyle(fontSize: 12, color: Colors.black),
  });

  @override
  State<InteractableSvg> createState() => _InteractableSvgState();
}

class _InteractableSvgState extends State<InteractableSvg> {
  List<District> districts = [];
  Set<String> selectedIds = {};

  @override
  void initState() {
    super.initState();
    _loadSvg();
  }

  Future<void> _loadSvg() async {
    final svgStr = await rootBundle.loadString(widget.svgAddress);
    final document = XmlDocument.parse(svgStr);
    final paths = document.findAllElements('path');
    final items = <District>[];

    for (var path in paths) {
      final id = path.getAttribute('id') ?? '';
      if (id.isEmpty || id == widget.unSelectableId) continue;
      final d = path.getAttribute('d') ?? '';
      items.add(District(id: id, path: d));
    }

    setState(() => districts = items);
  }

  void _onSelect(District district) {
    setState(() {
      if (widget.isMultiSelectable) {
        if (selectedIds.contains(district.id)) {
          selectedIds.remove(district.id);
        } else {
          selectedIds.add(district.id);
        }
      } else {
        if (widget.toggleEnable && selectedIds.contains(district.id)) {
          selectedIds.clear();
        } else {
          selectedIds = {district.id};
        }
      }
      widget.onChanged?.call(district.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(
        children: districts.map((district) {
          final path = parseSvgPathData(district.path)
              .transform((Matrix4.identity()..scale(1.1, 1.1)).storage);

          final isSelected = selectedIds.contains(district.id);
          return Stack(
            children: [
              CustomPaint(
                painter: _PathPainter(
                  path: path,
                  color: widget.strokeColor,
                  strokeWidth: widget.strokeWidth,
                ),
              ),
              ClipPath(
                clipper: _SvgClipper(path),
                child: GestureDetector(
                  onTap: () => _onSelect(district),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    color: isSelected
                        ? widget.selectedColor
                        : const Color(0xFFD7D3D2).withOpacity(0.6),
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _SvgClipper extends CustomClipper<Path> {
  final Path path;
  const _SvgClipper(this.path);

  @override
  Path getClip(Size size) => path;
  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _PathPainter extends CustomPainter {
  final Path path;
  final Color color;
  final double strokeWidth;

  _PathPainter({
    required this.path,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
