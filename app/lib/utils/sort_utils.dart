/// Sort Utilities - Unified sorting functions for scores and setlists
///
/// These functions are used by both library and team screens to sort
/// scores and setlists consistently.
library;

import '../models/score.dart';
import '../models/setlist.dart';
import '../models/sort_state.dart';

/// Sort a list of setlists based on sort state and recently opened times
List<Setlist> sortSetlists(
  List<Setlist> setlists,
  SortState sortState,
  Map<String, DateTime> recentlyOpened,
) {
  final sorted = List<Setlist>.from(setlists);

  switch (sortState.type) {
    case SortType.recentCreated:
      sorted.sort((a, b) => sortState.ascending
          ? a.createdAt.compareTo(b.createdAt)
          : b.createdAt.compareTo(a.createdAt));
    case SortType.alphabetical:
      sorted.sort((a, b) => sortState.ascending
          ? a.name.toLowerCase().compareTo(b.name.toLowerCase())
          : b.name.toLowerCase().compareTo(a.name.toLowerCase()));
    case SortType.recentOpened:
      sorted.sort((a, b) {
        final aOpened = recentlyOpened[a.id] ?? DateTime(1970);
        final bOpened = recentlyOpened[b.id] ?? DateTime(1970);
        return sortState.ascending
            ? aOpened.compareTo(bOpened)
            : bOpened.compareTo(aOpened);
      });
  }
  return sorted;
}

/// Sort a list of scores based on sort state and recently opened times
List<Score> sortScores(
  List<Score> scores,
  SortState sortState,
  Map<String, DateTime> recentlyOpened,
) {
  final sorted = List<Score>.from(scores);

  switch (sortState.type) {
    case SortType.recentCreated:
      sorted.sort((a, b) => sortState.ascending
          ? a.createdAt.compareTo(b.createdAt)
          : b.createdAt.compareTo(a.createdAt));
    case SortType.alphabetical:
      sorted.sort((a, b) => sortState.ascending
          ? a.title.toLowerCase().compareTo(b.title.toLowerCase())
          : b.title.toLowerCase().compareTo(a.title.toLowerCase()));
    case SortType.recentOpened:
      sorted.sort((a, b) {
        final aOpened = recentlyOpened[a.id] ?? DateTime(1970);
        final bOpened = recentlyOpened[b.id] ?? DateTime(1970);
        return sortState.ascending
            ? aOpened.compareTo(bOpened)
            : bOpened.compareTo(aOpened);
      });
  }
  return sorted;
}
