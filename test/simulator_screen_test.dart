import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:front_arcobot/features/simulator/domain/board_model.dart';
import 'package:front_arcobot/features/simulator/presentation/board_widget.dart';
import 'package:front_arcobot/features/simulator/presentation/command_blocks.dart';
import 'package:front_arcobot/features/simulator/presentation/simulator_provider.dart';
import 'package:front_arcobot/features/simulator/presentation/simulator_screen.dart';

Widget _app() {
  return const ProviderScope(
    child: MaterialApp(home: SimulatorScreen()),
  );
}

Future<void> _setSize(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('renderiza tablero y paleta en móvil (420x860)', (tester) async {
    await _setSize(tester, const Size(420, 860));
    await tester.pumpWidget(_app());
    await tester.pump();

    expect(find.byType(BoardWidget), findsOneWidget);
    expect(find.byType(CommandPalette), findsOneWidget);
    expect(find.byType(ProgramStrip), findsOneWidget);
    expect(find.text('Arrastra o toca las tarjetas'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renderiza layout ancho (1280x800) sin overflow', (tester) async {
    await _setSize(tester, const Size(1280, 800));
    await tester.pumpWidget(_app());
    await tester.pump();

    expect(find.byType(BoardWidget), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tap en tarjeta la agrega a la secuencia y se puede quitar',
      (tester) async {
    await _setSize(tester, const Size(420, 860));
    await tester.pumpWidget(_app());
    await tester.pump();

    // 4 tarjetas en paleta, ninguna en secuencia.
    expect(find.byType(CommandCard), findsNWidgets(4));

    await tester.tap(find.byType(CommandCard).first);
    await tester.pump(const Duration(milliseconds: 250));

    // Ahora 5: 4 paleta + 1 en secuencia.
    expect(find.byType(CommandCard), findsNWidgets(5));
    expect(find.text('Arrastra o toca las tarjetas'), findsNothing);

    // Quitar: tap sobre la tarjeta de la secuencia (dentro del ProgramStrip).
    final inStrip = find.descendant(
      of: find.byType(ProgramStrip),
      matching: find.byType(CommandCard),
    );
    expect(inStrip, findsOneWidget);
    await tester.tap(inStrip);
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byType(CommandCard), findsNWidgets(4));
  });

  testWidgets('ejecutar programa que llega a la meta muestra celebración',
      (tester) async {
    await _setSize(tester, const Size(420, 860));
    await tester.pumpWidget(_app());
    await tester.pump();

    final element = tester.element(find.byType(SimulatorScreen));
    final container = ProviderScope.containerOf(element, listen: false);
    final controller = container.read(simulatorProvider.notifier);

    // Nivel 1 ("Primer paseo"): 4 adelante llegan a la meta.
    for (var i = 0; i < 4; i++) {
      controller.addCommand(RobotCommand.forward);
    }
    await tester.pump();

    final runFuture = controller.run();
    // 350ms de arranque + 4 pasos de 650ms + margen.
    await tester.pump(const Duration(milliseconds: 400));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 700));
    }
    await runFuture;
    await tester.pump();

    expect(container.read(simulatorProvider).phase, SimPhase.success);
    expect(find.text('¡Lo lograste!'), findsOneWidget);
  });

  testWidgets('drag de tarjeta a la secuencia funciona', (tester) async {
    await _setSize(tester, const Size(420, 860));
    await tester.pumpWidget(_app());
    await tester.pump();

    final card = find.byType(CommandCard).first;
    final strip = find.byType(ProgramStrip);

    await tester.drag(
      card,
      tester.getCenter(strip) - tester.getCenter(card),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(CommandCard), findsNWidgets(5));
  });
}
