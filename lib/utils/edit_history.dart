/// Generic undo/redo stack for editor snapshots.
class EditHistory<T> {
  final List<T> _undo = [];
  final List<T> _redo = [];
  final int maxDepth;

  EditHistory({this.maxDepth = 50});

  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  void push(T snapshot) {
    _undo.add(snapshot);
    if (_undo.length > maxDepth) {
      _undo.removeAt(0);
    }
    _redo.clear();
  }

  /// Returns the state to restore (previous snapshot), or null if empty.
  T? undo(T currentSnapshot) {
    if (_undo.isEmpty) return null;
    _redo.add(currentSnapshot);
    return _undo.removeLast();
  }

  /// Returns the state to restore (next snapshot), or null if empty.
  T? redo(T currentSnapshot) {
    if (_redo.isEmpty) return null;
    _undo.add(currentSnapshot);
    return _redo.removeLast();
  }

  void clear() {
    _undo.clear();
    _redo.clear();
  }
}
