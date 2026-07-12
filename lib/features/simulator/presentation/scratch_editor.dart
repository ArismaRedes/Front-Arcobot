import 'package:flutter/material.dart';
import 'package:front_arcobot/core/theme/design_tokens.dart';
import 'package:front_arcobot/features/simulator/domain/block_program.dart';
import 'package:front_arcobot/features/simulator/domain/board_model.dart';
import 'package:front_arcobot/features/simulator/presentation/command_blocks.dart';
import 'package:front_arcobot/features/simulator/presentation/simulator_provider.dart';

const Color _repeatOrange = Color(0xFFFF9F43);

/// Editor por bloques estilo Scratch: paleta arriba, programa apilado
/// abajo. Tap agrega al final o dentro del "repetir" seleccionado.
/// Cada cambio recompila a comandos y avisa al simulador.
class ScratchEditor extends StatefulWidget {
  const ScratchEditor({
    required this.enabled,
    required this.onProgramChanged,
    super.key,
  });

  final bool enabled;
  final ValueChanged<List<RobotCommand>> onProgramChanged;

  @override
  State<ScratchEditor> createState() => ScratchEditorState();
}

class ScratchEditorState extends State<ScratchEditor> {
  final List<ProgramBlock> _blocks = [];

  /// Índice del bloque "repetir" seleccionado (los taps de la paleta
  /// agregan adentro); null = agregar al final del programa.
  int? _selectedRepeat;

  void clear() {
    setState(() {
      _blocks.clear();
      _selectedRepeat = null;
    });
    widget.onProgramChanged(const []);
  }

  bool get isEmpty => _blocks.isEmpty;

  void _notify() {
    widget.onProgramChanged(compileBlocks(_blocks));
  }

  bool _fits(int extraCommands) {
    return compileBlocks(_blocks).length + extraCommands <=
        SimulatorState.maxProgramLength;
  }

  void _addCommand(RobotCommand command) {
    final target = _selectedRepeat;
    final extra = target == null
        ? 1
        : (_blocks[target] as RepeatBlock).times;
    if (!_fits(extra)) {
      _showLimit();
      return;
    }
    setState(() {
      if (target == null) {
        _blocks.add(CommandBlock(command));
      } else {
        final repeat = _blocks[target] as RepeatBlock;
        _blocks[target] = repeat.copyWith(
          children: [...repeat.children, CommandBlock(command)],
        );
      }
    });
    _notify();
  }

  void _addRepeat() {
    if (!_fits(0)) {
      _showLimit();
      return;
    }
    setState(() {
      _blocks.add(const RepeatBlock(times: 2, children: []));
      _selectedRepeat = _blocks.length - 1;
    });
    _notify();
  }

  void _removeAt(int index) {
    setState(() {
      _blocks.removeAt(index);
      _selectedRepeat = null;
    });
    _notify();
  }

  void _removeChild(int repeatIndex, int childIndex) {
    setState(() {
      final repeat = _blocks[repeatIndex] as RepeatBlock;
      final children = [...repeat.children]..removeAt(childIndex);
      _blocks[repeatIndex] = repeat.copyWith(children: children);
    });
    _notify();
  }

  void _changeTimes(int index, int delta) {
    final repeat = _blocks[index] as RepeatBlock;
    final times = (repeat.times + delta)
        .clamp(RepeatBlock.minTimes, RepeatBlock.maxTimes);
    if (times == repeat.times) {
      return;
    }
    final next = repeat.copyWith(times: times);
    // Validar límite al aumentar repeticiones.
    final preview = [..._blocks]..[index] = next;
    if (compileBlocks(preview).length > SimulatorState.maxProgramLength) {
      _showLimit();
      return;
    }
    setState(() => _blocks[index] = next);
    _notify();
  }

  void _showLimit() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('¡Programa lleno! Máximo 20 movimientos.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showCode() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => _CodeSheet(blocks: List.unmodifiable(_blocks)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Paleta de bloques.
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (final command in RobotCommand.values)
              _PaletteBlock(
                visual: CommandVisual.of(command),
                enabled: widget.enabled,
                onTap: () => _addCommand(command),
              ),
            _PaletteRepeat(
              enabled: widget.enabled,
              onTap: _addRepeat,
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Programa armado.
        Container(
          constraints: const BoxConstraints(minHeight: 88, maxHeight: 240),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F9FC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE4EAF2)),
          ),
          child: _blocks.isEmpty
              ? const Center(
                  child: Text(
                    'Toca los bloques para armar tu programa',
                    style: TextStyle(
                      color: ArcobotKidColors.textSecondary,
                      fontSize: 13.5,
                    ),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final (index, block) in _blocks.indexed)
                        switch (block) {
                          CommandBlock(:final command) => _StackedBlock(
                              visual: CommandVisual.of(command),
                              enabled: widget.enabled,
                              onRemove: () => _removeAt(index),
                            ),
                          RepeatBlock() => _RepeatBlockView(
                              repeat: block,
                              selected: _selectedRepeat == index,
                              enabled: widget.enabled,
                              onSelect: () => setState(() {
                                _selectedRepeat =
                                    _selectedRepeat == index ? null : index;
                              }),
                              onRemove: () => _removeAt(index),
                              onTimesDelta: (delta) =>
                                  _changeTimes(index, delta),
                              onRemoveChild: (child) =>
                                  _removeChild(index, child),
                            ),
                        },
                    ],
                  ),
                ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              onPressed: _showCode,
              icon: const Icon(Icons.code_rounded, size: 18),
              label: const Text('Ver código'),
              style: TextButton.styleFrom(
                foregroundColor: ArcobotColors.skyBlue,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PaletteBlock extends StatelessWidget {
  const _PaletteBlock({
    required this.visual,
    required this.enabled,
    required this.onTap,
  });

  final CommandVisual visual;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _BlockShape(
      color: visual.color,
      enabled: enabled,
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(visual.icon, color: Colors.white, size: 18),
          const SizedBox(width: 6),
          Text(
            visual.semantics.split(' ').first,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaletteRepeat extends StatelessWidget {
  const _PaletteRepeat({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _BlockShape(
      color: _repeatOrange,
      enabled: enabled,
      onTap: onTap,
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.repeat_rounded, color: Colors.white, size: 18),
          SizedBox(width: 6),
          Text(
            'Repetir',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Forma base de bloque estilo Scratch (redondeado con "muesca" lateral).
class _BlockShape extends StatelessWidget {
  const _BlockShape({
    required this.color,
    required this.enabled,
    required this.onTap,
    required this.child,
  });

  final Color color;
  final bool enabled;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? color : color.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(10),
      elevation: enabled ? 2 : 0,
      shadowColor: color.withValues(alpha: 0.5),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: child,
        ),
      ),
    );
  }
}

class _StackedBlock extends StatelessWidget {
  const _StackedBlock({
    required this.visual,
    required this.enabled,
    required this.onRemove,
    this.compact = false,
  });

  final CommandVisual visual;
  final bool enabled;
  final VoidCallback onRemove;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 10,
          vertical: compact ? 5 : 7,
        ),
        decoration: BoxDecoration(
          color: visual.color,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(visual.icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(
              visual.semantics,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 6),
            if (enabled)
              GestureDetector(
                onTap: onRemove,
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white70,
                  size: 15,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RepeatBlockView extends StatelessWidget {
  const _RepeatBlockView({
    required this.repeat,
    required this.selected,
    required this.enabled,
    required this.onSelect,
    required this.onRemove,
    required this.onTimesDelta,
    required this.onRemoveChild,
  });

  final RepeatBlock repeat;
  final bool selected;
  final bool enabled;
  final VoidCallback onSelect;
  final VoidCallback onRemove;
  final ValueChanged<int> onTimesDelta;
  final ValueChanged<int> onRemoveChild;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: _repeatOrange.withValues(alpha: selected ? 1 : 0.88),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: selected ? Colors.white : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: enabled ? onSelect : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.repeat_rounded,
                      color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  const Text(
                    'repetir',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _TimesButton(
                    icon: Icons.remove_rounded,
                    enabled: enabled,
                    onTap: () => onTimesDelta(-1),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '${repeat.times}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  _TimesButton(
                    icon: Icons.add_rounded,
                    enabled: enabled,
                    onTap: () => onTimesDelta(1),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'veces',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (enabled)
                    GestureDetector(
                      onTap: onRemove,
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white70,
                        size: 15,
                      ),
                    ),
                ],
              ),
            ),
            // Hijos indentados: lo que se repite.
            Padding(
              padding: const EdgeInsets.only(left: 18, top: 4),
              child: repeat.children.isEmpty
                  ? Text(
                      selected
                          ? 'Toca un bloque de la paleta para meterlo aquí'
                          : 'Vacío — tócame y agrega bloques',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final (childIndex, child)
                            in repeat.children.indexed)
                          if (child is CommandBlock)
                            _StackedBlock(
                              visual: CommandVisual.of(child.command),
                              enabled: enabled,
                              compact: true,
                              onRemove: () => onRemoveChild(childIndex),
                            ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimesButton extends StatelessWidget {
  const _TimesButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.25),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }
}

/// Visor educativo: el código Python/JS equivalente al programa del niño.
class _CodeSheet extends StatefulWidget {
  const _CodeSheet({required this.blocks});

  final List<ProgramBlock> blocks;

  @override
  State<_CodeSheet> createState() => _CodeSheetState();
}

class _CodeSheetState extends State<_CodeSheet> {
  bool _python = true;

  @override
  Widget build(BuildContext context) {
    final code = _python
        ? blocksToPython(widget.blocks)
        : blocksToJavaScript(widget.blocks);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.code_rounded, color: ArcobotColors.skyBlue),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Así se ve tu programa en código',
                  style: TextStyle(
                    color: ArcobotKidColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('Python')),
                  ButtonSegment(value: false, label: Text('JS')),
                ],
                selected: {_python},
                onSelectionChanged: (selection) =>
                    setState(() => _python = selection.first),
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 300),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2E44),
              borderRadius: BorderRadius.circular(14),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                code,
                style: const TextStyle(
                  color: Color(0xFFB5F0E4),
                  fontSize: 13.5,
                  height: 1.6,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Cada bloque es una instrucción. El bloque "repetir" '
            'se convierte en un ciclo (for).',
            style: TextStyle(
              color: ArcobotKidColors.textSecondary,
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
