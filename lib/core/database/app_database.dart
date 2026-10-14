import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../models/trip.dart';
import '../../models/waypoint.dart';
import '../../models/user_settings.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;

  AppDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('gps_speedometer.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE trips (
        id TEXT PRIMARY KEY,
        start_time INTEGER NOT NULL,
        end_time INTEGER,
        total_distance_meters REAL NOT NULL DEFAULT 0.0,
        duration_seconds INTEGER NOT NULL DEFAULT 0,
        max_speed_kmh REAL NOT NULL DEFAULT 0.0,
        avg_speed_kmh REAL NOT NULL DEFAULT 0.0,
        speed_unit TEXT NOT NULL DEFAULT 'KMH'
      )
    ''');

    await db.execute('''
      CREATE TABLE waypoints (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        trip_id TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        speed_kmh REAL NOT NULL,
        altitude_meters REAL,
        timestamp INTEGER NOT NULL,
        FOREIGN KEY (trip_id) REFERENCES trips (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE user_settings (
        id INTEGER PRIMARY KEY,
        unit TEXT NOT NULL DEFAULT 'KMH',
        speed_limit_kmh REAL NOT NULL DEFAULT 80.0,
        alert_audio_enabled INTEGER NOT NULL DEFAULT 1,
        alert_vibrate_enabled INTEGER NOT NULL DEFAULT 1,
        theme_color TEXT NOT NULL DEFAULT '#00FF66',
        keep_screen_on INTEGER NOT NULL DEFAULT 1,
        display_mode TEXT NOT NULL DEFAULT 'DIGITAL'
      )
    ''');

    // Insert default settings
    await db.insert('user_settings', const UserSettings().toMap());
  }

  // --- Trips ---
  Future<void> insertTrip(Trip trip) async {
    final db = await database;
    await db.insert(
      'trips',
      trip.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateTrip(Trip trip) async {
    final db = await database;
    await db.update(
      'trips',
      trip.toMap(),
      where: 'id = ?',
      whereArgs: [trip.id],
    );
  }

  Future<List<Trip>> getAllTrips() async {
    final db = await database;
    final maps = await db.query('trips', orderBy: 'start_time DESC');
    return maps.map((m) => Trip.fromMap(m)).toList();
  }

  Future<Trip?> getTripWithWaypoints(String tripId) async {
    final db = await database;
    final tripMaps = await db.query('trips', where: 'id = ?', whereArgs: [tripId]);
    if (tripMaps.isEmpty) return null;

    final waypointMaps = await db.query(
      'waypoints',
      where: 'trip_id = ?',
      whereArgs: [tripId],
      orderBy: 'timestamp ASC',
    );

    final waypoints = waypointMaps.map((w) => Waypoint.fromMap(w)).toList();
    return Trip.fromMap(tripMaps.first, waypoints);
  }

  Future<void> deleteTrip(String tripId) async {
    final db = await database;
    await db.delete('waypoints', where: 'trip_id = ?', whereArgs: [tripId]);
    await db.delete('trips', where: 'id = ?', whereArgs: [tripId]);
  }

  // --- Waypoints ---
  Future<void> insertWaypoint(Waypoint waypoint) async {
    final db = await database;
    await db.insert('waypoints', waypoint.toMap());
  }

  // --- Settings ---
  Future<UserSettings> getSettings() async {
    final db = await database;
    final maps = await db.query('user_settings', where: 'id = 1');
    if (maps.isNotEmpty) {
      return UserSettings.fromMap(maps.first);
    }
    return const UserSettings();
  }

  Future<void> saveSettings(UserSettings settings) async {
    final db = await database;
    await db.insert(
      'user_settings',
      settings.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
