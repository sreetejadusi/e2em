import 'package:mongo_dart/mongo_dart.dart';

// You can still keep a global instance for easy access.
final mongoDB = MongoDBConnection.instance;

class MongoDBConnection {
  // --- This is a more robust Singleton pattern ---
  MongoDBConnection._internal();
  static final MongoDBConnection instance = MongoDBConnection._internal();

  // --- Private variables ---
  Db? _db;
  bool _isConnecting = false;

  // --- Store your connection string securely ---
  static const String _connectionString =
      'mongodb+srv://teame2emtechnologies:V9jmf43q1JnK83bI@ezing.gulz8.mongodb.net/teame2emtechnologies';

  /// The main method to get the database instance.
  /// This is now the ONLY method you should call from your app to get the DB.
  /// It handles checking the connection, preventing multiple connection attempts,
  /// and returning a valid Db object.
  Future<Db> getDb() async {
    // If the connection is already open, return it immediately.
    if (_db != null && _db!.isConnected) {
      return _db!;
    }

    // If we are already in the process of connecting, wait for it to complete.
    // This prevents a "race condition" where multiple parts of your app
    // might try to connect at the same time.
    if (_isConnecting) {
      // Wait for the ongoing connection attempt to finish.
      await Future.doWhile(() => _isConnecting);
      // If the connection is now open, return it.
      if (_db != null && _db!.isConnected) {
        return _db!;
      }
    }

    // If we are not connected and not trying to connect, start a new connection.
    return await _openConnection();
  }

  /// Private method to handle the actual connection logic.
  Future<Db> _openConnection() async {
    print("MONGO: Attempting to open a new connection...");
    _isConnecting = true;
    try {
      _db = await Db.create(_connectionString);
      await _db!.open(secure: true); // Use secure: true for srv addresses

      if (_db!.isConnected) {
        print("MONGO: Connection successful!");
      } else {
        print("MONGO: Connection failed silently.");
      }
      return _db!;
    } catch (e) {
      print("MONGO: An error occurred while connecting: $e");
      // If connection fails, set db to null and rethrow the error
      _db = null;
      rethrow;
    } finally {
      // Whether it succeeded or failed, we are no longer "in the process" of connecting.
      _isConnecting = false;
    }
  }

  /// A proactive method to ensure the connection is live.
  /// Call this from your AppLifecycleListener when the app resumes.
  Future<void> ensureConnection() async {
    print("MONGO: Proactively ensuring connection is active...");
    await getDb();
  }

  /// Closes the connection. Call this when the app is permanently closing.
  Future<void> close() async {
    if (_db != null && _db!.isConnected) {
      await _db!.close();
      _db = null;
      print("MONGO: Connection closed.");
    }
  }
}
