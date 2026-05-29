import 'dart:async';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:flutter/foundation.dart';

class ProceduralAudioEngine {
  bool _isInitialized = false;

  AudioSource? _pathSource;
  AudioSource? _errorSource;
  AudioSource? _fanfareSource;
  AudioSource? _uiClickSource;
  AudioSource? _ambientSource;
  
  SoundHandle? _ambientHandle1;
  SoundHandle? _ambientHandle2;
  SoundHandle? _ambientHandle3;
  SoundHandle? _ambientHandle4;
  Timer? _ambientTimer;

  bool _isCMaj7 = true;

  // Ratios for a Major Pentatonic scale
  final List<double> _pentatonicRatios = [
    1.0, 1.122, 1.260, 1.498, 1.682,
    2.0, 2.245, 2.520, 2.997, 3.364,
    4.0, 4.490, 5.040, 5.993, 6.727,
    8.0, 8.980, 10.08, 11.99, 13.45,
  ];

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      await SoLoud.instance.init();
      _isInitialized = true;

      _pathSource = await SoLoud.instance.loadWaveform(
        WaveForm.sin, true, 0.25, 0.5,
      );

      _errorSource = await SoLoud.instance.loadWaveform(
        WaveForm.triangle, false, 1.0, 0.0,
      );

      _fanfareSource = await SoLoud.instance.loadWaveform(
        WaveForm.triangle, true, 0.3, 0.5,
      );
      
      _uiClickSource = await SoLoud.instance.loadWaveform(
        WaveForm.square, false, 0.2, 0.0,
      );

      _ambientSource = await SoLoud.instance.loadWaveform(
        WaveForm.sin, true, 0.15, 0.2,
      );

      startAmbientMusic();

    } catch (e) {
      debugPrint("Failed to init SoLoud: $e");
    }
  }

  void dispose() {
    stopAmbientMusic();
    if (_isInitialized) {
      SoLoud.instance.deinit();
    }
  }

  /// Ambient Pad: Smooth morphing between C-Maj7 and F-Maj7 every 4s
  void startAmbientMusic() async {
    if (!_isInitialized || _ambientSource == null) return;
    
    // Play 4 notes at low volume, looped continuously
    _ambientHandle1 = await SoLoud.instance.play(_ambientSource!, volume: 0.05, looping: true);
    _ambientHandle2 = await SoLoud.instance.play(_ambientSource!, volume: 0.05, looping: true);
    _ambientHandle3 = await SoLoud.instance.play(_ambientSource!, volume: 0.04, looping: true);
    _ambientHandle4 = await SoLoud.instance.play(_ambientSource!, volume: 0.04, looping: true);

    _applyAmbientChord();

    _ambientTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      _isCMaj7 = !_isCMaj7;
      _applyAmbientChord();
    });
  }

  void stopAmbientMusic() {
    _ambientTimer?.cancel();
    if (_ambientHandle1 != null) SoLoud.instance.stop(_ambientHandle1!);
    if (_ambientHandle2 != null) SoLoud.instance.stop(_ambientHandle2!);
    if (_ambientHandle3 != null) SoLoud.instance.stop(_ambientHandle3!);
    if (_ambientHandle4 != null) SoLoud.instance.stop(_ambientHandle4!);
  }

  void _applyAmbientChord() {
    // C-Maj7: C2 (0.25), E2 (0.315), G2 (0.375), B2 (0.472)
    // F-Maj7: F1 (0.168), A1 (0.211), C2 (0.25), E2 (0.315)
    
    final cMaj7 = [0.25, 0.315, 0.375, 0.472];
    final fMaj7 = [0.168, 0.211, 0.25, 0.315];
    final target = _isCMaj7 ? cMaj7 : fMaj7;

    // Use oscillate to glide pitches smoothly over 2 seconds
    final duration = const Duration(seconds: 2);
    if (_ambientHandle1 != null) SoLoud.instance.oscillateRelativePlaySpeed(_ambientHandle1!, target[0], target[0], duration);
    if (_ambientHandle2 != null) SoLoud.instance.oscillateRelativePlaySpeed(_ambientHandle2!, target[1], target[1], duration);
    if (_ambientHandle3 != null) SoLoud.instance.oscillateRelativePlaySpeed(_ambientHandle3!, target[2], target[2], duration);
    if (_ambientHandle4 != null) SoLoud.instance.oscillateRelativePlaySpeed(_ambientHandle4!, target[3], target[3], duration);
  }

  void playUIClick() async {
    if (!_isInitialized || _uiClickSource == null) return;
    try {
      final handle = await SoLoud.instance.play(_uiClickSource!, volume: 0.1);
      SoLoud.instance.setRelativePlaySpeed(handle, 2.5); // High pitch square wave ping
      Timer(const Duration(milliseconds: 30), () {
        if (_isInitialized) SoLoud.instance.stop(handle);
      });
    } catch (e) {
      debugPrint("Audio Error: $e");
    }
  }

  void playDragStartClick() async {
    if (!_isInitialized || _pathSource == null) return;
    try {
      final handle = await SoLoud.instance.play(_pathSource!, volume: 0.3);
      SoLoud.instance.setRelativePlaySpeed(handle, 1.5);
      Timer(const Duration(milliseconds: 60), () {
        if (_isInitialized) SoLoud.instance.stop(handle);
      });
    } catch (e) {
      debugPrint("Audio Error: $e");
    }
  }

  void playPathExtensionNote(int pathLength) async {
    if (!_isInitialized || _pathSource == null) return;
    int index = (pathLength - 1).clamp(0, _pentatonicRatios.length - 1);
    double pitch = 0.5 * _pentatonicRatios[index];

    try {
      final handle = await SoLoud.instance.play(_pathSource!, volume: 0.4);
      SoLoud.instance.setRelativePlaySpeed(handle, pitch);
      Timer(const Duration(milliseconds: 150), () {
        if (_isInitialized) SoLoud.instance.stop(handle);
      });
    } catch (e) {
      debugPrint("Audio Error: $e");
    }
  }

  void playErrorTone() async {
    if (!_isInitialized || _errorSource == null || _uiClickSource == null) return;
    try {
      // White noise / rough sweep down
      final h1 = await SoLoud.instance.play(_errorSource!, volume: 0.4);
      final h2 = await SoLoud.instance.play(_uiClickSource!, volume: 0.1); // Add square 'noise'
      
      SoLoud.instance.setRelativePlaySpeed(h1, 0.4);
      SoLoud.instance.setRelativePlaySpeed(h2, 0.3);

      SoLoud.instance.oscillateRelativePlaySpeed(h1, 0.4, 0.1, const Duration(milliseconds: 150));
      SoLoud.instance.oscillateRelativePlaySpeed(h2, 0.3, 0.05, const Duration(milliseconds: 150));
      
      Timer(const Duration(milliseconds: 180), () {
        if (_isInitialized) {
          SoLoud.instance.stop(h1);
          SoLoud.instance.stop(h2);
        }
      });
    } catch (e) {
      debugPrint("Audio Error: $e");
    }
  }

  void playLevelCompleteFanfare() async {
    if (!_isInitialized || _fanfareSource == null) return;
    try {
      final notes = [1.0, 1.25, 1.5, 2.0];
      for (int i = 0; i < notes.length; i++) {
        if (!_isInitialized) break;
        final handle = await SoLoud.instance.play(_fanfareSource!, volume: 0.3);
        SoLoud.instance.setRelativePlaySpeed(handle, notes[i]);
        Timer(const Duration(milliseconds: 300), () {
          if (_isInitialized) SoLoud.instance.stop(handle);
        });
        await Future.delayed(const Duration(milliseconds: 80)); 
      }
    } catch (e) {
      debugPrint("Audio Error: $e");
    }
  }
}
