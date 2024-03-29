part of workspace;

class WorkspaceHandleParams {
  final ValueNotifier<double> resizer;
  final double parentSize;
  final bool isHorizontal;

  WorkspaceHandleParams(this.resizer, this.parentSize, this.isHorizontal);
}

class WorkspacePanelParams {
  final WorkspacePanel panel;
  final double parentWidth;
  final double parentHeight;

  final WorkspaceHandleParams handleParams;

  WorkspacePanelParams(
    this.panel,
    this.parentWidth,
    this.parentHeight,
    this.handleParams,
  );
}
