import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class DatabaseService {
  static Future<Database> initDatabase() async {
    return openDatabase(
      p.join(await getDatabasesPath(), 'mood_mind.db'),
      onCreate: (db, version) async {
        print('Creating database...');
        await db.execute(
          'CREATE TABLE journal(id INTEGER PRIMARY KEY AUTOINCREMENT, mood TEXT, intensity INTEGER, note TEXT, timestamp TEXT)',
        );
        await db.execute(
          'CREATE TABLE habits(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, completed INTEGER, date TEXT, notification_time TEXT)',
        );
        await db.execute(
          'CREATE TABLE settings(id INTEGER PRIMARY KEY AUTOINCREMENT, notifications_enabled INTEGER, dark_mode INTEGER, language TEXT)',
        );
        await db.execute(
          'CREATE TABLE achievements(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, description TEXT, earned INTEGER, timestamp TEXT)',
        );
        await db.insert('settings', {
          'id': 1,
          'notifications_enabled': 1,
          'dark_mode': 0,
          'language': 'ro',
        });
        print('Database created successfully.');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        print('Upgrading database from version $oldVersion to $newVersion...');
        if (oldVersion < 2) {
          final tables = await db.rawQuery(
            "SELECT name FROM sqlite_master WHERE type='table' AND name='settings'",
          );
          if (tables.isEmpty) {
            await db.execute(
              'CREATE TABLE settings(id INTEGER PRIMARY KEY AUTOINCREMENT, notifications_enabled INTEGER, dark_mode INTEGER, language TEXT)',
            );
            await db.insert('settings', {
              'id': 1,
              'notifications_enabled': 1,
              'dark_mode': 0,
              'language': 'ro',
            });
          }
        }
        if (oldVersion < 3) {
          final columns = await db.rawQuery("PRAGMA table_info(journal)");
          bool hasIntensity = columns.any((col) => col['name'] == 'intensity');
          if (!hasIntensity) {
            await db
                .execute('ALTER TABLE journal ADD COLUMN intensity INTEGER');
            print('Added intensity column to journal table.');
          }
        }
        if (oldVersion < 4) {
          final tables = await db.rawQuery(
            "SELECT name FROM sqlite_master WHERE type='table' AND name='habits'",
          );
          if (tables.isNotEmpty) {
            await db.execute(
              'CREATE TABLE habits_temp(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, completed INTEGER, date TEXT)',
            );
            await db.execute(
              'INSERT INTO habits_temp(name, completed, date) SELECT name, completed, date FROM habits',
            );
            await db.execute('DROP TABLE habits');
            await db.execute('ALTER TABLE habits_temp RENAME TO habits');
            print('Updated habits table schema.');
          }
        }
        if (oldVersion < 5) {
          final columns = await db.rawQuery("PRAGMA table_info(habits)");
          bool hasNotificationTime =
              columns.any((col) => col['name'] == 'notification_time');
          if (!hasNotificationTime) {
            await db.execute(
                'ALTER TABLE habits ADD COLUMN notification_time TEXT');
            print('Added notification_time column to habits table.');
          }
        }
        if (oldVersion < 6) {
          final tables = await db.rawQuery(
            "SELECT name FROM sqlite_master WHERE type='table' AND name='achievements'",
          );
          if (tables.isEmpty) {
            await db.execute(
              'CREATE TABLE achievements(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, description TEXT, earned INTEGER, timestamp TEXT)',
            );
            print('Created achievements table.');
          }
        }
        print('Database upgraded successfully.');
      },
      version: 6,
    );
  }
}
