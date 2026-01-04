import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/score.dart';
import '../models/team.dart';
import '../providers/scores_provider.dart';
import '../theme/app_colors.dart';
import '../utils/icon_mappings.dart';

// Helper function to get icon for instrument type
IconData _getInstrumentIcon(InstrumentType type) {
  switch (type) {
    case InstrumentType.vocal:
      return AppIcons.mic;
    case InstrumentType.keyboard:
      return AppIcons.piano;
    case InstrumentType.guitar:
      return AppIcons.guitar;
    case InstrumentType.bass:
      return AppIcons.musicNote;
    case InstrumentType.drums:
      return AppIcons.drum;
    case InstrumentType.other:
      return AppIcons.musicNote;
  }
}

/// Dialog for importing instrument scores from personal library to Team
/// Per TEAM_SYNC_LOGIC.md §3.3.1: Select source Score �?Select instruments �?Execute import
class ImportFromLibraryDialog extends ConsumerStatefulWidget {
  /// The target TeamScore to import instruments into
  final TeamScore targetTeamScore;
  
  /// Callback when import is successful
  final void Function(Score sourceScore, List<InstrumentScore> selectedInstruments) onImport;
  
  /// Callback when dialog is closed
  final VoidCallback onClose;
  
  const ImportFromLibraryDialog({
    super.key,
    required this.targetTeamScore,
    required this.onImport,
    required this.onClose,
  });

  @override
  ConsumerState<ImportFromLibraryDialog> createState() => _ImportFromLibraryDialogState();
}

class _ImportFromLibraryDialogState extends ConsumerState<ImportFromLibraryDialog> {
  // Step 1: Score selection, Step 2: Instrument selection
  int _currentStep = 1;
  
  // Selected score from library
  Score? _selectedScore;
  
  // Selected instruments to import
  final Set<String> _selectedInstrumentIds = {};
  
  // Search query for filtering scores
  String _searchQuery = '';
  
  // Get instruments that already exist in target TeamScore
  Set<String> get _existingInstrumentKeys => widget.targetTeamScore.existingInstrumentKeys;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onClose,
      child: Container(
        color: Colors.black54,
        child: GestureDetector(
          onTap: () {}, // Prevent tap from closing
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(24),
              constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(),
                  Expanded(
                    child: _currentStep == 1 
                        ? _buildScoreSelectionStep()
                        : _buildInstrumentSelectionStep(),
                  ),
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.blue50, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.blue400, AppColors.blue600],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              AppIcons.cloud,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentStep == 1 ? 'Import from Library' : 'Select Instruments',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _currentStep == 1
                      ? 'Step 1: Select a score from your library'
                      : 'Step 2: Choose instruments to import',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.gray500,
                  ),
                ),
              ],
            ),
          ),
          // Step indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.blue100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$_currentStep/2',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.blue600,
              ),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: widget.onClose,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                AppIcons.close,
                color: AppColors.gray400,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildScoreSelectionStep() {
    final scores = ref.watch(scoresListProvider);
    
    // Filter scores matching the TeamScore's title/composer for suggestions
    // But also allow searching all scores
    final filteredScores = _searchQuery.isEmpty
        ? scores
        : scores.where((s) {
            final query = _searchQuery.toLowerCase();
            return s.title.toLowerCase().contains(query) ||
                   s.composer.toLowerCase().contains(query);
          }).toList();
    
    // Put matching scores (same title/composer) at the top
    final matchingScores = filteredScores.where((s) =>
        s.title.toLowerCase() == widget.targetTeamScore.title.toLowerCase() &&
        s.composer.toLowerCase() == widget.targetTeamScore.composer.toLowerCase()
    ).toList();
    
    final otherScores = filteredScores.where((s) =>
        s.title.toLowerCase() != widget.targetTeamScore.title.toLowerCase() ||
        s.composer.toLowerCase() != widget.targetTeamScore.composer.toLowerCase()
    ).toList();
    
    final sortedScores = [...matchingScores, ...otherScores];
    
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search scores...',
              prefixIcon: Icon(AppIcons.search, color: AppColors.gray400),
              filled: true,
              fillColor: AppColors.gray50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        
        // Matching scores hint
        if (matchingScores.isNotEmpty && _searchQuery.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.emerald50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(AppIcons.check, color: AppColors.emerald500, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Found ${matchingScores.length} matching score(s) with same title and composer',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.emerald600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        
        const SizedBox(height: 8),
        
        // Score list
        Expanded(
          child: sortedScores.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(AppIcons.musicNote, color: AppColors.gray300, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isEmpty
                            ? 'No scores in your library'
                            : 'No scores found',
                        style: const TextStyle(
                          color: AppColors.gray400,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: sortedScores.length,
                  itemBuilder: (context, index) {
                    final score = sortedScores[index];
                    final isMatching = matchingScores.contains(score);
                    final isSelected = _selectedScore?.id == score.id;
                    
                    return _buildScoreItem(score, isMatching, isSelected);
                  },
                ),
        ),
      ],
    );
  }
  
  Widget _buildScoreItem(Score score, bool isMatching, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedScore = score;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.blue50 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? AppColors.blue400 
                : isMatching 
                    ? AppColors.emerald200 
                    : AppColors.gray100,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Thumbnail or icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: score.instrumentScores.isNotEmpty && 
                     score.instrumentScores.first.thumbnail != null &&
                     score.instrumentScores.first.thumbnail!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(score.instrumentScores.first.thumbnail!),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) => Icon(AppIcons.musicNote, color: AppColors.gray400),
                      ),
                    )
                  : Icon(AppIcons.musicNote, color: AppColors.gray400),
            ),
            const SizedBox(width: 12),
            
            // Score info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (isMatching)
                        Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.emerald100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Match',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: AppColors.emerald600,
                            ),
                          ),
                        ),
                      Expanded(
                        child: Text(
                          score.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    score.composer,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.gray500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${score.instrumentScores.length} instrument(s)',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.gray400,
                    ),
                  ),
                ],
              ),
            ),
            
            // Selection indicator
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: AppColors.blue500,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInstrumentSelectionStep() {
    if (_selectedScore == null) {
      return const Center(child: Text('No score selected'));
    }
    
    final instruments = _selectedScore!.instrumentScores;
    
    // Check which instruments can be imported (not already in team)
    final availableInstruments = instruments.where((i) => 
        !_existingInstrumentKeys.contains(i.instrumentKey)
    ).toList();
    
    final existingInstruments = instruments.where((i) => 
        _existingInstrumentKeys.contains(i.instrumentKey)
    ).toList();
    
    return Column(
      children: [
        // Selected score info
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.blue50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(AppIcons.musicNote, color: AppColors.blue500),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedScore!.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _selectedScore!.composer,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.gray500,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _currentStep = 1;
                    _selectedInstrumentIds.clear();
                  });
                },
                child: const Text('Change'),
              ),
            ],
          ),
        ),
        
        // Select all / deselect all
        if (availableInstruments.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${_selectedInstrumentIds.length} selected',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.gray500,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      if (_selectedInstrumentIds.length == availableInstruments.length) {
                        _selectedInstrumentIds.clear();
                      } else {
                        _selectedInstrumentIds.clear();
                        _selectedInstrumentIds.addAll(
                          availableInstruments.map((i) => i.id)
                        );
                      }
                    });
                  },
                  child: Text(
                    _selectedInstrumentIds.length == availableInstruments.length
                        ? 'Deselect All'
                        : 'Select All',
                  ),
                ),
              ],
            ),
          ),
        
        // Instrument list
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              // Available instruments
              if (availableInstruments.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.only(top: 8, bottom: 8),
                  child: Text(
                    'Available to Import',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray500,
                    ),
                  ),
                ),
                ...availableInstruments.map((i) => _buildInstrumentItem(i, canSelect: true)),
              ],
              
              // Already existing instruments
              if (existingInstruments.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.only(top: 16, bottom: 8),
                  child: Text(
                    'Already in Team',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray400,
                    ),
                  ),
                ),
                ...existingInstruments.map((i) => _buildInstrumentItem(i, canSelect: false)),
              ],
              
              // No available instruments message
              if (availableInstruments.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: Column(
                    children: [
                      Icon(AppIcons.check, color: AppColors.emerald400, size: 48),
                      const SizedBox(height: 16),
                      const Text(
                        'All instruments already exist in this Team Score',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.gray500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildInstrumentItem(InstrumentScore instrument, {required bool canSelect}) {
    final isSelected = _selectedInstrumentIds.contains(instrument.id);
    
    return GestureDetector(
      onTap: canSelect
          ? () {
              setState(() {
                if (isSelected) {
                  _selectedInstrumentIds.remove(instrument.id);
                } else {
                  _selectedInstrumentIds.add(instrument.id);
                }
              });
            }
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: canSelect
              ? (isSelected ? AppColors.blue50 : Colors.white)
              : AppColors.gray50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: canSelect
                ? (isSelected ? AppColors.blue400 : AppColors.gray100)
                : AppColors.gray200,
          ),
        ),
        child: Row(
          children: [
            // Instrument icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: canSelect ? AppColors.gray100 : AppColors.gray200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getInstrumentIcon(instrument.instrumentType),
                color: canSelect ? AppColors.gray600 : AppColors.gray400,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            
            // Instrument info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    instrument.instrumentDisplayName,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: canSelect ? Colors.black : AppColors.gray400,
                    ),
                  ),
                  if (instrument.pdfHash != null)
                    Text(
                      'PDF available',
                      style: TextStyle(
                        fontSize: 11,
                        color: canSelect ? AppColors.emerald500 : AppColors.gray400,
                      ),
                    ),
                ],
              ),
            ),
            
            // Selection checkbox or status
            if (canSelect)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.blue500 : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected ? AppColors.blue500 : AppColors.gray300,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              )
            else
              Icon(
                AppIcons.check,
                color: AppColors.gray300,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button (in step 2)
          if (_currentStep == 2)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _currentStep = 1;
                    _selectedInstrumentIds.clear();
                  });
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Back'),
              ),
            )
          else
            Expanded(
              child: OutlinedButton(
                onPressed: widget.onClose,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Cancel'),
              ),
            ),
          
          const SizedBox(width: 12),
          
          // Next / Import button
          Expanded(
            child: ElevatedButton(
              onPressed: _getNextAction(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue500,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(_currentStep == 1 ? 'Next' : 'Import'),
            ),
          ),
        ],
      ),
    );
  }
  
  VoidCallback? _getNextAction() {
    if (_currentStep == 1) {
      // Step 1: Need a score selected to continue
      if (_selectedScore == null) return null;
      
      return () {
        setState(() {
          _currentStep = 2;
          // Auto-select all available instruments
          final availableInstruments = _selectedScore!.instrumentScores.where((i) =>
              !_existingInstrumentKeys.contains(i.instrumentKey)
          );
          _selectedInstrumentIds.addAll(availableInstruments.map((i) => i.id));
        });
      };
    } else {
      // Step 2: Need at least one instrument selected
      if (_selectedInstrumentIds.isEmpty) return null;
      
      return () {
        final selectedInstruments = _selectedScore!.instrumentScores
            .where((i) => _selectedInstrumentIds.contains(i.id))
            .toList();
        
        widget.onImport(_selectedScore!, selectedInstruments);
      };
    }
  }
}
