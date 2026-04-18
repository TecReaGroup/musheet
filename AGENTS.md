- Keeping English code comments
- After editing, remember to run flutter analyze
- All problems should be fixed even lint warnings
- Use flutter run to test on device/emulator(no additional arguments needed)
- All packages should be up to date (run flutter pub get), and use latest stable versions
- Take care of log formatting use log class
- Test specifications: Fail = Bug Detected; Pass = Bug Fixed (Code is working correctly)

If you have any questions, please feel free to discuss them with me; I prefer questions that allow me to choose from different options.

app folder: ./lib
server folder: ./server

you are on windows operating system, command should be compatible with windows cmd or 

serverpod command：
"C:\Users\roupe\AppData\Local\Pub\Cache\bin\serverpod.bat" generate

# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with code in this repository.

## Project Overview

**MuSheet** is a Flutter-based digital sheet music management application designed for musicians and bands. It focuses on PDF score viewing with annotations, setlist management, and team collaboration with an offline-first architecture.

**Key Features:**
- High-performance PDF viewing with annotation support (drawing, erasing, undo/redo)
- Score library with multi-instrument support (one score → many instrument parts)
- Setlist management for organizing performance repertoire
- Team collaboration with role-based permissions
- Built-in metronome and practice tools
- Offline-first with cloud sync via Supabase
