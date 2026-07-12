import 'package:front_arcobot/features/simulator/domain/board_model.dart';

/// Programa por bloques estilo Scratch. Extensible: para un bloque nuevo
/// se agrega una subclase de [ProgramBlock] y su traducción en compile /
/// codegen; el motor de simulación no cambia (todo termina en
/// [RobotCommand]).
sealed class ProgramBlock {
  const ProgramBlock();
}

/// Bloque simple de movimiento/giro (equivale a una tarjeta).
class CommandBlock extends ProgramBlock {
  const CommandBlock(this.command);

  final RobotCommand command;
}

/// Bloque "repetir N veces" con bloques hijos (introduce los loops).
class RepeatBlock extends ProgramBlock {
  const RepeatBlock({required this.times, required this.children});

  final int times;
  final List<ProgramBlock> children;

  static const int minTimes = 2;
  static const int maxTimes = 9;

  RepeatBlock copyWith({int? times, List<ProgramBlock>? children}) {
    return RepeatBlock(
      times: times ?? this.times,
      children: children ?? this.children,
    );
  }
}

/// Expande los bloques a la lista plana de comandos que corre el robot.
List<RobotCommand> compileBlocks(List<ProgramBlock> blocks) {
  final commands = <RobotCommand>[];
  for (final block in blocks) {
    switch (block) {
      case CommandBlock(:final command):
        commands.add(command);
      case RepeatBlock(:final times, :final children):
        final inner = compileBlocks(children);
        for (var i = 0; i < times; i++) {
          commands.addAll(inner);
        }
    }
  }
  return commands;
}

int countBlocks(List<ProgramBlock> blocks) {
  var count = 0;
  for (final block in blocks) {
    count += 1;
    if (block is RepeatBlock) {
      count += countBlocks(block.children);
    }
  }
  return count;
}

String _pythonCall(RobotCommand command) => switch (command) {
      RobotCommand.forward => 'robot.avanzar()',
      RobotCommand.backward => 'robot.retroceder()',
      RobotCommand.turnLeft => 'robot.girar_izquierda()',
      RobotCommand.turnRight => 'robot.girar_derecha()',
    };

String _jsCall(RobotCommand command) => switch (command) {
      RobotCommand.forward => 'robot.avanzar();',
      RobotCommand.backward => 'robot.retroceder();',
      RobotCommand.turnLeft => 'robot.girarIzquierda();',
      RobotCommand.turnRight => 'robot.girarDerecha();',
    };

/// Código Python equivalente al programa (educativo, solo lectura).
String blocksToPython(List<ProgramBlock> blocks) {
  final buffer = StringBuffer();
  void write(List<ProgramBlock> items, int depth) {
    final indent = '    ' * depth;
    for (final block in items) {
      switch (block) {
        case CommandBlock(:final command):
          buffer.writeln('$indent${_pythonCall(command)}');
        case RepeatBlock(:final times, :final children):
          buffer.writeln('${indent}for i in range($times):');
          if (children.isEmpty) {
            buffer.writeln('$indent    pass');
          } else {
            write(children, depth + 1);
          }
      }
    }
  }

  write(blocks, 0);
  final code = buffer.toString().trimRight();
  return code.isEmpty ? '# Agrega bloques para ver el código' : code;
}

/// Código JavaScript equivalente al programa.
String blocksToJavaScript(List<ProgramBlock> blocks) {
  final buffer = StringBuffer();
  void write(List<ProgramBlock> items, int depth) {
    final indent = '  ' * depth;
    for (final block in items) {
      switch (block) {
        case CommandBlock(:final command):
          buffer.writeln('$indent${_jsCall(command)}');
        case RepeatBlock(:final times, :final children):
          buffer.writeln('${indent}for (let i = 0; i < $times; i++) {');
          write(children, depth + 1);
          buffer.writeln('$indent}');
      }
    }
  }

  write(blocks, 0);
  final code = buffer.toString().trimRight();
  return code.isEmpty ? '// Agrega bloques para ver el código' : code;
}
