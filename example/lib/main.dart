import 'package:flutter/material.dart';
import 'package:workspace/workspace.dart';

void main() {
  runApp(WorkspaceApp());
}

class WorkspaceApp extends StatelessWidget {
  WorkspaceApp({super.key}) {
    // generateCell() => LayoutCell(colorCode: rndColorCode());
    generateCell([String title = '']) => WorkspacePanel(widgetContent: Text(title));
    final c0 = generateCell('0');
    final c1 = generateCell('1');
    final c2 = generateCell('2');
    final c3 = generateCell("3");
    // final c4 = generateCell("4");
    // final c5 = generateCell("5");
    // final c6 = generateCell("6");

    workspace.add(c0);
    final c2_right = generateCell('2-r');
    workspace.addRight(workspace.root, c1);
    workspace.addBottom(workspace.root, c2);
    workspace.addRight(c2, c2_right);
    workspace.addRight(c2_right, generateCell('2-r-r'));
    workspace.addBottom(c2_right, generateCell('2-r-b'));
    workspace.addBottom(c2, generateCell('2-b'));
    final c1_right = generateCell('1-r');
    workspace.addRight(c1, c1_right);
    workspace.addRight(c1_right, generateCell('1-r-r'));
    workspace.addBottom(c1_right, c3);
    workspace.addBottom(c3, generateCell('3-b'));
    final c1_bottom = generateCell('1-b');
    final c1_bottom_bottom = generateCell('1-b-b');
    final c1_bottom_right = generateCell('1-b-r');
    workspace.addBottom(c1, c1_bottom);
    workspace.addRight(c1_bottom, c1_bottom_right);
    workspace.addBottom(c1_bottom, c1_bottom_bottom);
    workspace.addRight(c1_bottom_bottom, generateCell('1-b-b-r'));
    workspace.addRight(c1_bottom_right, generateCell('1-b-r-r'));
    //
    // workspace.addRight(c3, c4);
    // workspace.addRight(c4, generateCell());
    //
    // workspace.addRight(c1, c2);
    // workspace.addBottom(c2, c5);

    // workspace.addRight(c5, c6);
    // workspace.addBottom(c6, generateCell());
  }

  final Workspace workspace = Workspace();

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WorkspaceGrid',
      theme: ThemeData(scaffoldBackgroundColor: Colors.black12),
      home: Scaffold(
        body: WorkspaceInherited(
          workspace: workspace,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return ValueListenableBuilder(
                valueListenable: workspace.panels,
                builder: (_, List<WorkspacePanel> value, __) {
                  return workspace.positionPanelsAt(
                    workspace.root,
                    parentWidth: constraints.maxWidth,
                    parentHeight: constraints.maxHeight,
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
