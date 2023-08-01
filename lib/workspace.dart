import 'package:flutter/material.dart';
import 'package:workspace/consts/enums.dart';
import 'package:workspace/handler.dart';
import 'package:workspace/panel.dart';
import 'package:workspace/panel/panel_header.dart';
import 'package:workspace/panel/panel_params.dart';
import 'package:workspace/regions.dart';

const double HANDLER_SIZE = 4;

class Workspace {
  Workspace();

  final ValueNotifier<List<WorkspacePanel>> _items = ValueNotifier([]);
  final ValueNotifier<WorkspacePanel?> selectedPanel = ValueNotifier(null);
  final ValueNotifier<({WorkspacePanel? panel, PanelRegionSide? side})?> panelRegionSide = ValueNotifier(null);

  WorkspacePanel get root => _items.value.first;
  ValueNotifier<List<WorkspacePanel>> get panels => _items;

  _breakConnectionWithPrevious(WorkspacePanel panel) {
    if (panel.previous?.right == panel) panel.previous!.right = null;
    if (panel.previous?.bottom == panel) panel.previous!.bottom = null;
  }

  WorkspacePanel add(WorkspacePanel panel) {
    if (!_items.value.contains(panel)) {
      _items.value.add(panel);
    }
    return panel;
  }

  WorkspacePanel addRight(WorkspacePanel to, WorkspacePanel panel) {
    _breakConnectionWithPrevious(panel);
    to.right = panel;
    panel.previous = to;
    return add(panel);
  }

  WorkspacePanel addBottom(WorkspacePanel to, WorkspacePanel panel) {
    _breakConnectionWithPrevious(panel);
    if (to.hasBottom) {
      if (panel.hasBottom && !panel.isRoot) {
        panel.previous!.bottom = panel.bottom;
      }
      panel.bottom = to.bottom;
    }
    to.bottom = panel;
    panel.previous = to;
    return add(panel);
  }

  _connectRightToBottomMostRight(WorkspacePanel panel, WorkspacePanel panelBottom, double handleSize) {
    WorkspacePanel? right = panelBottom;
    double parentWidth = panel.parentWidth;
    print('parent width = ${parentWidth}');
    while (right != null) {
      final rightWidthRelative = right.absoluteWidth / parentWidth;
      print('right width = ${rightWidthRelative} | ${right.width} | ${right.absoluteWidth}');
      right.parentWidth = parentWidth;
      right.width = rightWidthRelative;
      parentWidth -= right.absoluteWidth + handleSize;
      right = right.right;
    }
    final bottomMostRight = panelBottom.findMostRight();
    bottomMostRight.right = panel.right;
  }

  _rearrangeConnectionWithPrevious(
    WorkspacePanel prev,
    WorkspacePanel panel,
    double handleSize, [
    isRemoveFromPreviousBottom = true,
  ]) {
    print('> \t -> rearrange: isRemoveFromPreviousBottom = ${isRemoveFromPreviousBottom}');
    final hasBottomOnCell = panel.bottom != null;
    final hasRightOnCell = panel.right != null;
    final isHorizontal = panel.isHorizontal;
    print('> \t\t -> isHorizontal: ${isHorizontal}');
    print('> \t\t -> hasBottomOnCell = ${hasBottomOnCell}');
    print('> \t\t -> hasRightOnCell: ${hasRightOnCell}');
    if (hasBottomOnCell) {
      final panelBottom = panel.bottom!;
      if (isRemoveFromPreviousBottom) {
        prev.bottom = panelBottom;
        final shouldConnectRightToBottomRight = hasRightOnCell && panelBottom.hasRight;
        print('> \t\t\t -> shouldConnectRightToBottomRight: ${shouldConnectRightToBottomRight}');
        if (shouldConnectRightToBottomRight) {
          _connectRightToBottomMostRight(panel, panelBottom, handleSize);
        } else {
          if (hasRightOnCell) {
            print('> \t\t\t -> but panel has');
            panelBottom.right = panel.right;
            panelBottom.absoluteWidth = panel.absoluteWidth;
            panelBottom.width = panel.width;
          }
        }
      } else {
        final shouldShiftRightToLeft = panel.isHorizontal && hasRightOnCell;
        print('> \t\t\t -> shouldShiftRightToLeft: ${shouldShiftRightToLeft}');
        if (shouldShiftRightToLeft) {
          final panelRight = panel.right!;
          prev.right = panelRight;
          final shouldConnectBottomToRightBottom = panelRight.bottom != null;
          print('> \t\t\t -> shouldConnectBottomToRightBottom: ${shouldConnectBottomToRightBottom}');
          if (shouldConnectBottomToRightBottom) {
            final rightMostBottom = panelRight.findMostBottom();
            rightMostBottom.bottom = panelBottom;
          } else {
            panelRight.bottom = panelBottom;
          }
          panelRight.height = -1;
        } else {
          final shouldConnectRightToBottomRight = hasRightOnCell && panelBottom.hasRight;
          print('> \t\t\t -> shouldConnectRightToBottomRight: ${shouldConnectRightToBottomRight}');
          print('> \t\t\t -> panel width: ${panel.width}');
          print('> \t\t\t -> panelBottom width: ${panelBottom.width}');
          prev.right = panelBottom;
          if (shouldConnectRightToBottomRight) {
            _connectRightToBottomMostRight(panel, panelBottom, handleSize);
          } else {
            print('> \t\t\t -> panel bottom has no right');
            if (hasRightOnCell) {
              print('> \t\t\t -> panelBottom.isHorizontal = ${panelBottom.isHorizontal}');
              if (panelBottom.isHorizontal) {
                final tempCellBottomBottom = panelBottom.bottom;
                panelBottom.bottom = null;
                panelBottom.right = panel.right;
                panelBottom.bottom = tempCellBottomBottom;
              } else {
                print('> \t\t\t -> but panel has');
                panelBottom.right = panel.right;
              }
              panelBottom.absoluteWidth = panel.absoluteWidth;
              panelBottom.width = panel.width;
            }
          }
        }
      }
    } else if (hasRightOnCell) {
      final panelRight = panel.right!;
      print('> \t\t -> remove - right only');
      if (isRemoveFromPreviousBottom) {
        // print('> \t\t\t -> isPreviousHorizontal (before): ${isPreviousHorizontal}');
        prev.bottom = panelRight;
        // print('> \t\t\t -> isPreviousHorizontal (after): ${prev.isHorizontal}');
      } else {
        prev.right = panelRight;
      }
      panelRight.parentWidth = panel.parentWidth;
      panelRight.width = panel.width + (panelRight.absoluteWidth + handleSize) / panel.parentWidth;
    } else {
      print('> \t\t -> remove - no further connections');
      if (isRemoveFromPreviousBottom) {
        prev.bottom = null;
        prev.height = -1;
      } else {
        prev.right = null;
        prev.width = -1;
      }
    }
  }

  void removePanel(WorkspacePanel deletePanel, {keep = false, willBecomeRoot = false}) {
    print('> Layout -> removeCell: keep = ${keep}');
    final previous = deletePanel.previous;
    final hasPrevious = previous != null;
    print('> \t -> hasPrevious = ${hasPrevious}');
    if (hasPrevious) {
      final isFromBottom = previous.bottom == deletePanel;
      _rearrangeConnectionWithPrevious(
        previous,
        deletePanel,
        HANDLER_SIZE,
        isFromBottom,
      );
      deletePanel.clearConnection();
    }
    if (keep) {
      if (willBecomeRoot) {
        _items.value.remove(deletePanel);
        _items.value.insert(0, deletePanel);
      }
      _items.notifyListeners();
    } else {
      _items.value = _items.value.where((el) => el != deletePanel).toList();
    }
  }

  List<Widget> _createNextSideWithHandler(WorkspacePanelParams params, bool toRight, bool toBottom) {
    return [
      Handler(HANDLER_SIZE, params.handleParams),
      positionPanelsAt(
        params.panel,
        parentWidth: params.parentWidth - (toRight ? HANDLER_SIZE : 0),
        parentHeight: params.parentHeight - (toBottom ? HANDLER_SIZE : 0),
      ),
    ];
  }

  Widget _buildPanelContent(WorkspacePanel panel) {
    return Stack(
      alignment: AlignmentDirectional.center,
      children: [
        panel.widgetContent ?? Container(),
        ValueListenableBuilder(
          valueListenable: selectedPanel,
          builder: (_, WorkspacePanel? selected, __) {
            final hasSelected = selected != null;
            final isDifferent = selected != panel;
            // print('> panelContent -> hasSelected: ${hasSelected}');
            return hasSelected && isDifferent
                ? WorkspaceRegions(
                    panel,
                    selected,
                    panelRegionSide,
                  )
                : Container();
          },
        ),
      ],
    );
  }

  Widget positionPanelsAt(
    WorkspacePanel panel, {
    required double parentWidth,
    required double parentHeight,
  }) {
    final hasRight = panel.right != null;
    final hasBottom = panel.bottom != null;

    final hasWidth = panel.width > 0;
    final hasHeight = panel.height > 0;

    panel.parentWidth = parentWidth;
    panel.parentHeight = parentHeight;

    final initialWidth = hasWidth ? panel.width * parentWidth : parentWidth / (hasRight ? 2 : 1);
    final initialHeight = hasHeight ? panel.height * parentHeight : parentHeight / (hasBottom ? 2 : 1);

    ValueNotifier<double> horizontalResizer = ValueNotifier(initialWidth);
    ValueNotifier<double> verticalResizer = ValueNotifier(initialHeight);

    final isHorizontal = panel.isHorizontal;

    return Container(
      width: parentWidth,
      height: parentHeight,
      color: panel.colorCode,
      child: ValueListenableBuilder(
        valueListenable: isHorizontal ? verticalResizer : horizontalResizer,
        builder: (_, double blockHeightWidth, __) {
          return Flex(
            direction: isHorizontal ? Axis.vertical : Axis.horizontal,
            children: [
              ValueListenableBuilder(
                valueListenable: isHorizontal ? horizontalResizer : verticalResizer,
                builder: (_, double blockWidthHeight, __) {
                  panel.absoluteWidth = (isHorizontal ? blockWidthHeight : blockHeightWidth);
                  panel.absoluteHeight = (isHorizontal ? blockHeightWidth : blockWidthHeight);

                  panel.width = panel.absoluteWidth / parentWidth;
                  panel.height = panel.absoluteHeight / parentHeight;

                  return Flex(
                    direction: isHorizontal ? Axis.horizontal : Axis.vertical,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: panel.absoluteWidth,
                        height: panel.absoluteHeight,
                        child: Column(
                          children: [
                            PanelHeader(
                              title: 'Panel',
                              onPointerDown: () => selectedPanel.value = panel,
                              onPointerUp: _onHeaderPointerUp,
                              onRemove: panel.isRoot ? null : () => removePanel(panel),
                            ),
                            Expanded(child: _buildPanelContent(panel)),
                          ],
                        ),
                        // child: PanelContent(panel),
                      ),
                      if (isHorizontal ? hasRight : hasBottom)
                        ..._createNextSideWithHandler(
                            isHorizontal
                                ? WorkspacePanelParams(
                                    panel.right!,
                                    parentWidth - panel.absoluteWidth,
                                    panel.absoluteHeight,
                                    WorkspaceHandleParams(horizontalResizer, panel.absoluteHeight, false),
                                  )
                                : WorkspacePanelParams(
                                    panel.bottom!,
                                    panel.absoluteWidth,
                                    parentHeight - panel.absoluteHeight,
                                    WorkspaceHandleParams(verticalResizer, panel.absoluteWidth, true),
                                  ),
                            isHorizontal && panel.hasRight,
                            !isHorizontal && panel.hasBottom),
                    ],
                  );
                },
              ),
              if (hasBottom || hasRight)
                ..._createNextSideWithHandler(
                    isHorizontal
                        ? WorkspacePanelParams(
                            panel.bottom!,
                            parentWidth,
                            parentHeight - blockHeightWidth,
                            WorkspaceHandleParams(verticalResizer, parentWidth, true),
                          )
                        : WorkspacePanelParams(
                            panel.right!,
                            parentWidth - blockHeightWidth,
                            parentHeight,
                            WorkspaceHandleParams(horizontalResizer, parentHeight, false),
                          ),
                    !isHorizontal && panel.hasRight,
                    isHorizontal && panel.hasBottom)
            ],
          );
        },
      ),
    );
  }

  final REMOVABLE_SIDES = [
    PanelRegionSide.TOP,
    PanelRegionSide.RIGHT,
    PanelRegionSide.BOTTOM,
    PanelRegionSide.LEFT,
  ];

  _onHeaderPointerUp() {
    final canRearrange = panelRegionSide.value?.side != null && selectedPanel.value != null;
    print('> Layout -> CellHeader - onPointerUp: canRearrange = ${canRearrange}');
    if (canRearrange) {
      final targetPanelSide = panelRegionSide.value?.side;
      final targetPanel = panelRegionSide.value!.panel!;
      final movingPanel = selectedPanel.value!;

      print('> \t panel side: ${targetPanelSide}');

      if (REMOVABLE_SIDES.contains(targetPanelSide)) {
        final isTargetSideCanBeRoot = [PanelRegionSide.LEFT, PanelRegionSide.TOP].contains(targetPanelSide);
        final isMovingCellBecomeRoot = targetPanel.isRoot && isTargetSideCanBeRoot;
        removePanel(movingPanel, keep: true, willBecomeRoot: isMovingCellBecomeRoot);
      }

      switch (targetPanelSide) {
        case PanelRegionSide.TOP:
          _positionPanelTop(targetPanel, movingPanel);
          break;
        case PanelRegionSide.BOTTOM:
          _positionPanelBottom(targetPanel, movingPanel);
          break;
        case PanelRegionSide.RIGHT:
          _positionPanelRight(targetPanel, movingPanel);
          break;
        case PanelRegionSide.LEFT:
          _positionPanelLeft(targetPanel, movingPanel);
          break;
        case PanelRegionSide.CENTER:
        case null:
      }
    }
    selectedPanel.value = null;
    panelRegionSide.value = null;
  }

  void _positionPanelLeft(WorkspacePanel leftPanel, WorkspacePanel movingPanel) {
    final sizes = divideHalf(leftPanel.absoluteWidth, leftPanel.width, HANDLER_SIZE);

    final isTargetOnBottom = leftPanel.previous!.bottom == leftPanel;
    final isTargetOnRight = leftPanel.previous!.right == leftPanel;

    print('> \t isTargetOnBottom = ${isTargetOnBottom}');
    print('> \t isTargetOnRight = ${isTargetOnRight}');

    if (isTargetOnBottom) {
      leftPanel.previous!.bottom = movingPanel;
    } else if (isTargetOnRight) {
      leftPanel.previous!.right = movingPanel;
    }
    movingPanel.right = leftPanel;

    movingPanel.width = sizes.$1;
    leftPanel.width = sizes.$2;

    movingPanel.height = -1;
  }

  void _positionPanelRight(WorkspacePanel rightPanel, WorkspacePanel movingPanel) {
    final sizes = divideHalf(rightPanel.absoluteWidth, rightPanel.width, HANDLER_SIZE);

    print('> \t targetCell.isHorizontal: ${rightPanel.isHorizontal}');
    print('> \t targetCell.hasRight: ${rightPanel.hasRight}');

    final right = rightPanel.right;
    rightPanel.right = null;
    movingPanel.right = right;
    rightPanel.right = movingPanel;

    rightPanel.width = sizes.$1;
    movingPanel.width = sizes.$2;

    movingPanel.height = -1;
  }

  void _positionPanelBottom(WorkspacePanel bottomPanel, WorkspacePanel movingPanel) {
    final sizes = divideHalf(bottomPanel.absoluteHeight, bottomPanel.height, HANDLER_SIZE);

    movingPanel.bottom = bottomPanel.bottom;
    bottomPanel.bottom = movingPanel;

    bottomPanel.height = sizes.$1;
    movingPanel.height = sizes.$2;
    movingPanel.width = -1;
  }

  void _positionPanelTop(WorkspacePanel topPanel, WorkspacePanel movingPanel) {
    final previous = topPanel.previous!;
    final isTopOnBottom = previous.bottom == topPanel;
    final isTopOnRight = previous.right == topPanel;

    final sizes = divideHalf(topPanel.absoluteHeight, topPanel.height, HANDLER_SIZE);

    if (isTopOnBottom) {
      previous.bottom = movingPanel;
    } else if (isTopOnRight) {
      previous.right = movingPanel;
    }
    if (topPanel.hasRight) {
      final right = topPanel.right;
      topPanel.right = null;
      movingPanel.right = right;
    }
    movingPanel.bottom = topPanel;

    movingPanel.height = sizes.$1;
    topPanel.height = sizes.$2;

    movingPanel.width = topPanel.width;
    topPanel.width = -1;
  }

  (double, double) divideHalf(double sizeAbsolute, double size, [double innerOffset = 0]) {
    final sizeAbsoluteHalf = 0.5 * sizeAbsolute - innerOffset;
    final sizeSecondRelative = 1 / size - 1;
    final sizeSecondAbsolute = sizeSecondRelative * sizeAbsolute;
    final sizeSecondAbsoluteAfter = sizeSecondAbsolute + sizeAbsoluteHalf;
    return (size * 0.5, sizeAbsoluteHalf / sizeSecondAbsoluteAfter);
  }
}
