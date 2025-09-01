import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/offline/log_bleed.dart';
import '../models/offline/infusion_log.dart';
import '../models/offline/calculator_history.dart';
import 'firestore.dart';

class OfflineService {
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal();

  final FirestoreService _firestoreService = FirestoreService();
  bool _isInitialized = false;

  // Box names
  static const String _bleedLogsBox = 'bleed_logs';
  static const String _infusionLogsBox = 'infusion_logs';
  static const String _calculatorHistoryBox = 'calculator_history';
  static const String _educationalResourcesBox = 'educational_resources';

  /// Initialize Hive database and register adapters
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final dir = await getApplicationDocumentsDirectory();
      Hive.init(dir.path);

      // Register adapters only if not already registered
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(InfusionLogAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(BleedLogAdapter());
      }
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(CalculatorHistoryAdapter());
      }

      // Open boxes
      await Future.wait([
        Hive.openBox<BleedLog>(_bleedLogsBox),
        Hive.openBox<InfusionLog>(_infusionLogsBox),
        Hive.openBox<CalculatorHistory>(_calculatorHistoryBox),
        Hive.openBox<Map>(_educationalResourcesBox),
      ]);

      _isInitialized = true;
      print('✅ OfflineService initialized successfully');

      // Start automatic sync if online
      _startAutoSync();
    } catch (e) {
      print('❌ Error initializing OfflineService: $e');
      rethrow;
    }
  }

  /// Check if device is online
  Future<bool> isOnline() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      print('Error checking connectivity: $e');
      return false;
    }
  }

  // ============================================================================
  //                            BLEED LOG OPERATIONS
  // ============================================================================

  /// Save bleed log offline
  Future<String> saveBleedLogOffline({
    required String date,
    required String time,
    required String bodyRegion,
    required String severity,
    required String specificRegion,
    required String notes,
  }) async {
    try {
      await initialize();

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final bleedLog = BleedLog(
        id: 'offline_${DateTime.now().millisecondsSinceEpoch}',
        date: date,
        time: time,
        bodyRegion: bodyRegion,
        severity: severity,
        specificRegion: specificRegion,
        notes: notes,
        uid: user.uid,
        createdAt: DateTime.now(),
        needsSync: true,
      );

      final box = Hive.box<BleedLog>(_bleedLogsBox);
      await box.put(bleedLog.id, bleedLog);

      print('💾 Bleed log saved offline: ${bleedLog.id}');

      // Try to sync immediately if online
      _attemptSync();

      return bleedLog.id;
    } catch (e) {
      print('❌ Error saving bleed log offline: $e');
      rethrow;
    }
  }

  /// Get all bleed logs (offline + synced)
  Future<List<BleedLog>> getBleedLogs() async {
    try {
      await initialize();

      final box = Hive.box<BleedLog>(_bleedLogsBox);
      final logs = box.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return logs;
    } catch (e) {
      print('❌ Error getting bleed logs: $e');
      return [];
    }
  }

  // ============================================================================
  //                           INFUSION LOG OPERATIONS
  // ============================================================================

  /// Save infusion log offline
  Future<String> saveInfusionLogOffline({
    required String medication,
    required int doseIU,
    required String date,
    required String time,
    required String notes,
  }) async {
    try {
      await initialize();

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final infusionLog = InfusionLog(
        id: 'offline_${DateTime.now().millisecondsSinceEpoch}',
        medication: medication,
        doseIU: doseIU,
        date: date,
        time: time,
        notes: notes,
        uid: user.uid,
        createdAt: DateTime.now(),
        needsSync: true,
      );

      final box = Hive.box<InfusionLog>(_infusionLogsBox);
      await box.put(infusionLog.id, infusionLog);

      print('💾 Infusion log saved offline: ${infusionLog.id}');

      // Try to sync immediately if online
      _attemptSync();

      return infusionLog.id;
    } catch (e) {
      print('❌ Error saving infusion log offline: $e');
      rethrow;
    }
  }

  /// Get all infusion logs (offline + synced)
  Future<List<InfusionLog>> getInfusionLogs() async {
    try {
      await initialize();

      final box = Hive.box<InfusionLog>(_infusionLogsBox);
      final logs = box.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return logs;
    } catch (e) {
      print('❌ Error getting infusion logs: $e');
      return [];
    }
  }

  // ============================================================================
  //                          CALCULATOR HISTORY OPERATIONS
  // ============================================================================

  /// Save calculator history offline
  Future<String> saveCalculatorHistoryOffline({
    required double weight,
    required String factorType,
    required double targetLevel,
    required double calculatedDose,
    required String notes,
  }) async {
    try {
      await initialize();

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final history = CalculatorHistory(
        id: 'calc_${DateTime.now().millisecondsSinceEpoch}',
        weight: weight,
        factorType: factorType,
        targetLevel: targetLevel,
        calculatedDose: calculatedDose,
        notes: notes,
        createdAt: DateTime.now(),
        uid: user.uid,
      );

      final box = Hive.box<CalculatorHistory>(_calculatorHistoryBox);
      await box.put(history.id, history);

      print('💾 Calculator history saved offline: ${history.id}');

      return history.id;
    } catch (e) {
      print('❌ Error saving calculator history offline: $e');
      rethrow;
    }
  }

  /// Get calculator history
  Future<List<CalculatorHistory>> getCalculatorHistory() async {
    try {
      await initialize();

      final box = Hive.box<CalculatorHistory>(_calculatorHistoryBox);
      final history = box.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return history;
    } catch (e) {
      print('❌ Error getting calculator history: $e');
      return [];
    }
  }

  // ============================================================================
  //                         EDUCATIONAL RESOURCES CACHE
  // ============================================================================

  /// Cache educational resources for offline access
  Future<void> cacheEducationalResources(Map<String, dynamic> resources) async {
    try {
      await initialize();

      final box = Hive.box<Map>(_educationalResourcesBox);
      await box.put('educational_data', resources);

      print('💾 Educational resources cached offline');
    } catch (e) {
      print('❌ Error caching educational resources: $e');
    }
  }

  /// Get cached educational resources
  Future<Map<String, dynamic>?> getCachedEducationalResources() async {
    try {
      await initialize();

      final box = Hive.box<Map>(_educationalResourcesBox);
      final data = box.get('educational_data');

      return data?.cast<String, dynamic>();
    } catch (e) {
      print('❌ Error getting cached educational resources: $e');
      return null;
    }
  }

  // ============================================================================
  //                             SYNC OPERATIONS
  // ============================================================================

  /// Attempt to sync all offline data with Firebase
  Future<void> syncAllData() async {
    try {
      final online = await isOnline();
      if (!online) {
        print('🔄 Device offline - skipping sync');
        return;
      }

      await initialize();

      print('🔄 Starting sync process...');

      await Future.wait([
        _syncBleedLogs(),
        _syncInfusionLogs(),
      ]);

      print('✅ Sync completed successfully');
    } catch (e) {
      print('❌ Error during sync: $e');
    }
  }

  /// Sync bleed logs to Firebase
  Future<void> _syncBleedLogs() async {
    try {
      final box = Hive.box<BleedLog>(_bleedLogsBox);
      final unsynced = box.values.where((log) => log.needsSync).toList();

      for (final log in unsynced) {
        try {
          await _firestoreService.saveBleedLog(
            uid: log.uid,
            date: log.date,
            time: log.time,
            bodyRegion: log.bodyRegion,
            severity: log.severity,
            specificRegion: log.specificRegion,
            notes: log.notes,
          );

          // Mark as synced
          log.needsSync = false;
          log.syncedAt = DateTime.now();
          await log.save();

          print('✅ Synced bleed log: ${log.id}');
        } catch (e) {
          print('❌ Failed to sync bleed log ${log.id}: $e');
        }
      }
    } catch (e) {
      print('❌ Error syncing bleed logs: $e');
    }
  }

  /// Sync infusion logs to Firebase
  Future<void> _syncInfusionLogs() async {
    try {
      final box = Hive.box<InfusionLog>(_infusionLogsBox);
      final unsynced = box.values.where((log) => log.needsSync).toList();

      for (final log in unsynced) {
        try {
          await _firestoreService.saveInfusionLog(
            uid: log.uid,
            medication: log.medication,
            doseIU: log.doseIU,
            date: log.date,
            time: log.time,
            notes: log.notes,
          );

          // Mark as synced
          log.needsSync = false;
          log.syncedAt = DateTime.now();
          await log.save();

          print('✅ Synced infusion log: ${log.id}');
        } catch (e) {
          print('❌ Failed to sync infusion log ${log.id}: $e');
        }
      }
    } catch (e) {
      print('❌ Error syncing infusion logs: $e');
    }
  }

  /// Start automatic sync process
  void _startAutoSync() {
    Connectivity().onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        print('📶 Connection restored - starting sync');
        _attemptSync();
      }
    });
  }

  /// Attempt sync without throwing errors
  void _attemptSync() {
    syncAllData().catchError((e) {
      print('⚠️ Background sync failed: $e');
    });
  }

  // ============================================================================
  //                              UTILITY METHODS
  // ============================================================================

  /// Get sync status
  Future<Map<String, int>> getSyncStatus() async {
    try {
      await initialize();

      final bleedBox = Hive.box<BleedLog>(_bleedLogsBox);
      final infusionBox = Hive.box<InfusionLog>(_infusionLogsBox);

      final pendingBleeds =
          bleedBox.values.where((log) => log.needsSync).length;
      final pendingInfusions =
          infusionBox.values.where((log) => log.needsSync).length;

      return {
        'pendingBleeds': pendingBleeds,
        'pendingInfusions': pendingInfusions,
        'totalPending': pendingBleeds + pendingInfusions,
      };
    } catch (e) {
      print('❌ Error getting sync status: $e');
      return {'pendingBleeds': 0, 'pendingInfusions': 0, 'totalPending': 0};
    }
  }

  /// Clear all offline data (use with caution)
  Future<void> clearAllOfflineData() async {
    try {
      await initialize();

      await Future.wait([
        Hive.box<BleedLog>(_bleedLogsBox).clear(),
        Hive.box<InfusionLog>(_infusionLogsBox).clear(),
        Hive.box<CalculatorHistory>(_calculatorHistoryBox).clear(),
        Hive.box<Map>(_educationalResourcesBox).clear(),
      ]);

      print('🗑️ All offline data cleared');
    } catch (e) {
      print('❌ Error clearing offline data: $e');
    }
  }

  /// Get storage statistics
  Future<Map<String, dynamic>> getStorageStats() async {
    try {
      await initialize();

      final bleedBox = Hive.box<BleedLog>(_bleedLogsBox);
      final infusionBox = Hive.box<InfusionLog>(_infusionLogsBox);
      final calcBox = Hive.box<CalculatorHistory>(_calculatorHistoryBox);
      final eduBox = Hive.box<Map>(_educationalResourcesBox);

      return {
        'bleedLogs': bleedBox.length,
        'infusionLogs': infusionBox.length,
        'calculatorHistory': calcBox.length,
        'educationalResources': eduBox.length,
        'totalEntries': bleedBox.length +
            infusionBox.length +
            calcBox.length +
            eduBox.length,
      };
    } catch (e) {
      print('❌ Error getting storage stats: $e');
      return {};
    }
  }
}
