import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_event.dart';
import 'theme_state.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  static const String _themeKey = 'theme_mode';

  ThemeBloc() : super(const ThemeState()) {
    on<ThemeInitialize>(_onInitialize);
    on<ThemeChanged>(_onThemeChanged);
  }

  Future<void> _onInitialize(ThemeInitialize event, Emitter<ThemeState> emit) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeModeIndex = prefs.getInt(_themeKey) ?? 0; // 0 = system default
      
      ThemeMode themeMode;
      switch (themeModeIndex) {
        case 1:
          themeMode = ThemeMode.light;
          break;
        case 2:
          themeMode = ThemeMode.dark;
          break;
        default:
          themeMode = ThemeMode.system;
      }
      
      emit(state.copyWith(themeMode: themeMode));
    } catch (e) {
      // If error loading preference, keep system default
      emit(state.copyWith(themeMode: ThemeMode.system));
    }
  }

  Future<void> _onThemeChanged(ThemeChanged event, Emitter<ThemeState> emit) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      int themeModeIndex;
      switch (event.themeMode) {
        case ThemeMode.light:
          themeModeIndex = 1;
          break;
        case ThemeMode.dark:
          themeModeIndex = 2;
          break;
        default:
          themeModeIndex = 0; // system
      }
      
      await prefs.setInt(_themeKey, themeModeIndex);
      emit(state.copyWith(themeMode: event.themeMode));
    } catch (e) {
      // If error saving preference, still emit the change
      emit(state.copyWith(themeMode: event.themeMode));
    }
  }
}