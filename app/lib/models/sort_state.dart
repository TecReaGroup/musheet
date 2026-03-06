/// Sort State - Shared sort models for Library and Team screens
///
/// Provides unified sorting functionality across different screens.
library;

/// Sort type enumeration
enum SortType {
  recentCreated,
  alphabetical,
  recentOpened,
}

/// Sort state class
class SortState {
  final SortType type;
  final bool ascending;

  const SortState({
    this.type = SortType.recentCreated,
    this.ascending = false,
  });

  SortState copyWith({SortType? type, bool? ascending}) {
    return SortState(
      type: type ?? this.type,
      ascending: ascending ?? this.ascending,
    );
  }

  /// Toggle sort direction or change sort type
  /// - Same type: toggle ascending/descending
  /// - Different type: alphabetical defaults to ascending (A→Z), others default to descending (newest first)
  SortState withSort(SortType newType) {
    if (type == newType) {
      return copyWith(ascending: !ascending);
    } else {
      final defaultAscending = newType == SortType.alphabetical;
      return SortState(type: newType, ascending: defaultAscending);
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SortState && other.type == type && other.ascending == ascending;
  }

  @override
  int get hashCode => type.hashCode ^ ascending.hashCode;
}
