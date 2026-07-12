import 'package:flutter_test/flutter_test.dart';
import 'package:front_arcobot/features/simulator/domain/block_program.dart';
import 'package:front_arcobot/features/simulator/domain/board_model.dart';

void main() {
  test('compileBlocks expande repetir', () {
    final blocks = [
      const CommandBlock(RobotCommand.forward),
      const RepeatBlock(times: 3, children: [
        CommandBlock(RobotCommand.turnRight),
        CommandBlock(RobotCommand.forward),
      ]),
    ];
    expect(compileBlocks(blocks), [
      RobotCommand.forward,
      RobotCommand.turnRight,
      RobotCommand.forward,
      RobotCommand.turnRight,
      RobotCommand.forward,
      RobotCommand.turnRight,
      RobotCommand.forward,
    ]);
  });

  test('codegen Python con for e indentación', () {
    final blocks = [
      const CommandBlock(RobotCommand.forward),
      const RepeatBlock(times: 2, children: [
        CommandBlock(RobotCommand.turnLeft),
      ]),
    ];
    expect(
      blocksToPython(blocks),
      'robot.avanzar()\n'
      'for i in range(2):\n'
      '    robot.girar_izquierda()',
    );
  });

  test('codegen JS con for y llaves', () {
    final blocks = [
      const RepeatBlock(times: 4, children: [
        CommandBlock(RobotCommand.forward),
      ]),
    ];
    expect(
      blocksToJavaScript(blocks),
      'for (let i = 0; i < 4; i++) {\n'
      '  robot.avanzar();\n'
      '}',
    );
  });

  test('programa vacío genera comentario educativo', () {
    expect(blocksToPython(const []), startsWith('#'));
    expect(blocksToJavaScript(const []), startsWith('//'));
  });
}
