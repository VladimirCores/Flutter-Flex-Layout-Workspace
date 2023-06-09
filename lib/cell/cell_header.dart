import 'package:flutter/material.dart';

class CellHeader extends StatefulWidget {
  const CellHeader({
    super.key,
    this.height = 32,
    required this.title,
    required this.onPointerDown,
    required this.onPointerUp,
    required this.onRemove,
  });

  final double height;
  final String title;
  final Function() onPointerDown;
  final Function() onPointerUp;
  final Function()? onRemove;

  @override
  State<CellHeader> createState() => _CellHeaderState();
}

class _CellHeaderState extends State<CellHeader> {
  bool isCloseButtonHover = false;

  @override
  Widget build(BuildContext context) {
    var color = Colors.transparent;
    final canInteract = widget.onRemove != null;
    return Material(
      child: Theme(
        data: Theme.of(context).copyWith(
          splashFactory: NoSplash.splashFactory,
          highlightColor: color,
          splashColor: color,
          hoverColor: color,
        ),
        child: Container(
          width: double.maxFinite,
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                if (!canInteract)
                  Text(widget.title)
                else
                  Listener(
                    onPointerDown: (_) => widget.onPointerDown(),
                    onPointerUp: (_) => widget.onPointerUp(),
                    child: Row(children: [
                      Text(widget.title),
                      const SizedBox(width: 4),
                      StatefulBuilder(
                        builder: (_, setState) {
                          return InkWell(
                            onHover: (_) {
                              setState(() {
                                isCloseButtonHover = !isCloseButtonHover;
                              });
                            },
                            onTap: widget.onRemove,
                            child: Icon(
                              Icons.close,
                              weight: 700,
                              size: 16.0,
                              color: isCloseButtonHover ? Colors.black87 : Colors.black26,
                            ),
                          );
                        },
                      ),
                    ]),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
