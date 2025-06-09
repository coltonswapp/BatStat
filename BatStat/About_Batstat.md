
# Baseball Stat Tracking App - Product Requirements Document

## Introduction

The Baseball Stat Tracking App is a mobile application designed to help baseball coaches, managers, and enthusiasts track player statistics, game results, and lineup information. This document outlines the core features, data structures, and technical requirements for the app's implementation using GRDB.swift for local data storage.

## Product Overview

### Purpose
To provide a reliable, intuitive way to track and analyze baseball statistics for individual players and teams across multiple games.

### Target Users
- Baseball coaches and team managers
- Amateur baseball league administrators
- Baseball enthusiasts who track detailed game statistics

### Core Functionality
- Player management and roster organization
- Game creation and tracking
- Player lineup management for each game
- Comprehensive stat tracking during games
- Statistical analysis and reporting

## Technical Requirements

### Database Storage
- The app will use GRDB.swift, a SQLite toolkit for Swift, for local data storage
- Data will be persisted locally on the device
- The database must maintain relationships between players, games, lineups, and statistics

### Data Models

#### Player
- **Description**: Represents an individual player in the roster
- **Attributes**:
  - `id`: Unique identifier (auto-incremented)
  - `name`: Player's name
  - `number`: Jersey number (optional)
  - `primaryPosition`: Main playing position
  - `secondaryPositions`: Additional positions (stored as JSON array)

#### Game
- **Description**: Represents a single baseball game
- **Attributes**:
  - `id`: Unique identifier (auto-incremented)
  - `date`: Date and time of the game
  - `location`: Where the game is played
  - `opponent`: Name of the opposing team
  - `homeScore`: Team's score (optional)
  - `opponentScore`: Opponent's score (optional)
  - `weatherConditions`: Weather during the game (optional)

#### GameLineup
- **Description**: Join table linking players to games with lineup information
- **Attributes**:
  - `gameId`: Reference to a game
  - `playerId`: Reference to a player
  - `position`: Position played in this specific game
  - `battingOrder`: Batting order position (optional)
- **Constraints**: Composite primary key on `gameId` and `playerId`

#### Stat
- **Description**: Individual statistical event recorded during a game
- **Attributes**:
  - `id`: Unique identifier (auto-incremented)
  - `gameId`: Reference to the game
  - `playerId`: Reference to the player
  - `timestamp`: When the stat occurred (optional)
  - `type`: Type of statistical event (e.g., "hit", "strikeout", "run")
  - `value`: Numerical value associated with the stat (optional)
  - `notes`: Additional information (optional)

## Database Schema

```swift
// Database schema creation
try dbQueue.write { db in
    // Create player table
    try db.create(table: "player") { t in
        t.autoIncrementedPrimaryKey("id")
        t.column("name", .text).notNull()
        t.column("number", .integer)
        t.column("primaryPosition", .text).notNull()
        t.column("secondaryPositions", .text) // JSON array
    }
    
    // Create game table
    try db.create(table: "game") { t in
        t.autoIncrementedPrimaryKey("id")
        t.column("date", .date).notNull()
        t.column("location", .text).notNull()
        t.column("opponent", .text).notNull()
        t.column("homeScore", .integer)
        t.column("opponentScore", .integer)
        t.column("weatherConditions", .text)
    }
    
    // Create gameLineup table
    try db.create(table: "gameLineup") { t in
        t.column("gameId", .integer)
            .notNull()
            .references("game", onDelete: .cascade)
        t.column("playerId", .integer)
            .notNull()
            .references("player", onDelete: .cascade)
        t.column("position", .text).notNull()
        t.column("battingOrder", .integer)
        t.primaryKey(["gameId", "playerId"])
        t.index(["gameId"])
        t.index(["playerId"])
    }
    
    // Create stat table
    try db.create(table: "stat") { t in
        t.autoIncrementedPrimaryKey("id")
        t.column("gameId", .integer)
            .notNull()
            .references("game", onDelete: .cascade)
        t.column("playerId", .integer)
            .notNull()
            .references("player", onDelete: .cascade)
        t.column("timestamp", .date)
        t.column("type", .text).notNull()
        t.column("value", .integer)
        t.column("notes", .text)
        t.index(["gameId"])
        t.index(["playerId"])
        t.index(["type"])
    }
}
```

## Model Implementations

### Player Model
```swift
struct Player: Codable, FetchableRecord, PersistableRecord, Identifiable {
    var id: Int64?
    var name: String
    var number: Int?
    var primaryPosition: String
    var secondaryPositions: [String]? // Will be stored as JSON
    
    // Update auto-incremented id upon successful insertion
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
```

### Game Model
```swift
struct Game: Codable, FetchableRecord, PersistableRecord, Identifiable {
    var id: Int64?
    var date: Date
    var location: String
    var opponent: String
    var homeScore: Int?
    var opponentScore: Int?
    var weatherConditions: String?
    
    // Update auto-incremented id upon successful insertion
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
```

### GameLineup Model
```swift
struct GameLineup: Codable, FetchableRecord, PersistableRecord {
    var gameId: Int64
    var playerId: Int64
    var position: String
    var battingOrder: Int?
    
    // Composite primary key
    static let databaseTableName = "gameLineup"
}
```

### Stat Model
```swift
struct Stat: Codable, FetchableRecord, PersistableRecord, Identifiable {
    var id: Int64?
    var gameId: Int64
    var playerId: Int64
    var timestamp: Date?
    var type: String
    var value: Int? // Could be count, distance, or other stat value
    var notes: String?
    
    // Update auto-incremented id upon successful insertion
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
```

## Associations

```swift
// Extensions for associations
extension Player {
    static let stats = hasMany(Stat.self)
    static let games = hasMany(GameLineup.self)
}

extension Game {
    static let lineup = hasMany(GameLineup.self)
    static let stats = hasMany(Stat.self)
    
    // Convenience to get players in a game
    static let players = hasMany(Player.self, through: lineup, using: GameLineup.player)
}

extension GameLineup {
    static let game = belongsTo(Game.self)
    static let player = belongsTo(Player.self)
}

extension Stat {
    static let game = belongsTo(Game.self)
    static let player = belongsTo(Player.self)
}
```

## Repository Layer

The app should implement a repository pattern to provide a clean interface between the database and the UI:

### Player Repository
```swift
class PlayerRepository {
    private let dbQueue: DatabaseQueue
    
    init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }
    
    func fetchAllPlayers() throws -> [Player] {
        try dbQueue.read { db in
            try Player.fetchAll(db)
        }
    }
    
    func fetchPlayers(byPosition position: String) throws -> [Player] {
        try dbQueue.read { db in
            try Player
                .filter(Column("primaryPosition") == position)
                .fetchAll(db)
        }
    }
    
    func searchPlayers(byName name: String) throws -> [Player] {
        try dbQueue.read { db in
            try Player
                .filter(Column("name").like("%\(name)%"))
                .fetchAll(db)
        }
    }
    
    func savePlayer(_ player: Player) throws -> Player {
        try dbQueue.write { db in
            var player = player
            try player.save(db)
            return player
        }
    }
    
    func deletePlayer(withId id: Int64) throws -> Bool {
        try dbQueue.write { db in
            try Player.deleteOne(db, id: id)
        }
    }
}
```

### Game Repository
```swift
class GameRepository {
    private let dbQueue: DatabaseQueue
    
    init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }
    
    func fetchAllGames() throws -> [Game] {
        try dbQueue.read { db in
            try Game.order(Column("date").desc).fetchAll(db)
        }
    }
    
    func fetchGame(withId id: Int64) throws -> Game? {
        try dbQueue.read { db in
            try Game.fetchOne(db, id: id)
        }
    }
    
    func saveGame(_ game: Game) throws -> Game {
        try dbQueue.write { db in
            var game = game
            try game.save(db)
            return game
        }
    }
    
    func deleteGame(withId id: Int64) throws -> Bool {
        try dbQueue.write { db in
            try Game.deleteOne(db, id: id)
        }
    }
    
    func getLineup(forGameId gameId: Int64) throws -> [(player: Player, position: String, battingOrder: Int?)] {
        try dbQueue.read { db in
            let request = GameLineup
                .filter(Column("gameId") == gameId)
                .including(required: GameLineup.player)
                .order(Column("battingOrder"))
            
            return try request.fetchAll(db).map { lineup in
                return (
                    player: lineup.player,
                    position: lineup.position,
                    battingOrder: lineup.battingOrder
                )
            }
        }
    }
    
    func saveLineup(forGameId gameId: Int64, lineup: [(player: Player, position: String, battingOrder: Int?)]) throws {
        try dbQueue.write { db in
            // Delete existing lineup
            try GameLineup.filter(Column("gameId") == gameId).deleteAll(db)
            
            // Save new lineup
            for entry in lineup {
                guard let playerId = entry.player.id else { continue }
                var lineupEntry = GameLineup(
                    gameId: gameId,
                    playerId: playerId,
                    position: entry.position,
                    battingOrder: entry.battingOrder
                )
                try lineupEntry.insert(db)
            }
        }
    }
}
```

### Stat Repository
```swift
class StatRepository {
    private let dbQueue: DatabaseQueue
    
    init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }
    
    func fetchStats(forGameId gameId: Int64) throws -> [Stat] {
        try dbQueue.read { db in
            try Stat.filter(Column("gameId") == gameId).fetchAll(db)
        }
    }
    
    func fetchStats(forPlayerId playerId: Int64) throws -> [Stat] {
        try dbQueue.read { db in
            try Stat.filter(Column("playerId") == playerId).fetchAll(db)
        }
    }
    
    func saveStat(_ stat: Stat) throws -> Stat {
        try dbQueue.write { db in
            var stat = stat
            try stat.save(db)
            return stat
        }
    }
    
    func saveMultipleStats(_ stats: [Stat]) throws {
        try dbQueue.write { db in
            for var stat in stats {
                try stat.save(db)
            }
        }
    }
    
    func deleteStat(withId id: Int64) throws -> Bool {
        try dbQueue.write { db in
            try Stat.deleteOne(db, id: id)
        }
    }
}
```

## Database Manager

```swift
class DatabaseManager {
    static let shared = DatabaseManager()
    
    private(set) var dbQueue: DatabaseQueue!
    
    private init() { }
    
    func setupDatabase() throws {
        // Create database directory if it doesn't exist
        let fileManager = FileManager.default
        let appSupportURL = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true)
        let directoryURL = appSupportURL.appendingPathComponent("BaseballStats", isDirectory: true)
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        
        // Open or create database
        let databaseURL = directoryURL.appendingPathComponent("baseball.sqlite")
        
        var config = Configuration()
        config.prepareDatabase { db in
            // Setup migrations
            var migrator = DatabaseMigrator()
            migrator.registerMigration("createTables") { db in
                // Create tables code from above...
                try db.create(table: "player") { t in
                    t.autoIncrementedPrimaryKey("id")
                    t.column("name", .text).notNull()
                    t.column("number", .integer)
                    t.column("primaryPosition", .text).notNull()
                    t.column("secondaryPositions", .text)
                }
                
                try db.create(table: "game") { t in
                    t.autoIncrementedPrimaryKey("id")
                    t.column("date", .date).notNull()
                    t.column("location", .text).notNull()
                    t.column("opponent", .text).notNull()
                    t.column("homeScore", .integer)
                    t.column("opponentScore", .integer)
                    t.column("weatherConditions", .text)
                }
                
                try db.create(table: "gameLineup") { t in
                    t.column("gameId", .integer)
                        .notNull()
                        .references("game", onDelete: .cascade)
                    t.column("playerId", .integer)
                        .notNull()
                        .references("player", onDelete: .cascade)
                    t.column("position", .text).notNull()
                    t.column("battingOrder", .integer)
                    t.primaryKey(["gameId", "playerId"])
                    t.index(["gameId"])
                    t.index(["playerId"])
                }
                
                try db.create(table: "stat") { t in
                    t.autoIncrementedPrimaryKey("id")
                    t.column("gameId", .integer)
                        .notNull()
                        .references("game", onDelete: .cascade)
                    t.column("playerId", .integer)
                        .notNull()
                        .references("player", onDelete: .cascade)
                    t.column("timestamp", .date)
                    t.column("type", .text).notNull()
                    t.column("value", .integer)
                    t.column("notes", .text)
                    t.index(["gameId"])
                    t.index(["playerId"])
                    t.index(["type"])
                }
            }
            try migrator.migrate(db)
        }
        
        dbQueue = try DatabaseQueue(path: databaseURL.path, configuration: config)
    }
    
    // Get repository instances
    func playerRepository() -> PlayerRepository {
        return PlayerRepository(dbQueue: dbQueue)
    }
    
    func gameRepository() -> GameRepository {
        return GameRepository(dbQueue: dbQueue)
    }
    
    func statRepository() -> StatRepository {
        return StatRepository(dbQueue: dbQueue)
    }
}
```

## Database Observation

The app should leverage GRDB's observation capabilities to keep the UI updated:

```swift
class PlayerListViewModel {
    private var cancellable: DatabaseCancellable?
    private let repository: PlayerRepository
    
    // Published property for SwiftUI
    @Published var players: [Player] = []
    
    init(repository: PlayerRepository) {
        self.repository = repository
        startObservation()
    }
    
    private func startObservation() {
        let observation = ValueObservation.tracking { db in
            try Player.order(Column("name")).fetchAll(db)
        }
        
        cancellable = observation.start(
            in: DatabaseManager.shared.dbQueue,
            onError: { error in
                print("Error observing players: \(error)")
            },
            onChange: { [weak self] players in
                self?.players = players
            }
        )
    }
}

class GameListViewModel {
    private var cancellable: DatabaseCancellable?
    private let repository: GameRepository
    
    // Published property for SwiftUI
    @Published var games: [Game] = []
    
    init(repository: GameRepository) {
        self.repository = repository
        startObservation()
    }
    
    private func startObservation() {
        let observation = ValueObservation.tracking { db in
            try Game.order(Column("date").desc).fetchAll(db)
        }
        
        cancellable = observation.start(
            in: DatabaseManager.shared.dbQueue,
            onError: { error in
                print("Error observing games: \(error)")
            },
            onChange: { [weak self] games in
                self?.games = games
            }
        )
    }
}
```

## Functionality Requirements

### Player Management

1. The app must allow adding new players with name, number, and position(s)
2. Users should be able to edit existing player information
3. Users should be able to view a list of all players in the roster
4. Users should be able to filter players by position
5. Users should be able to search for players by name
6. Users should be able to view detailed statistics for each player

### Game Management

1. The app must allow creating new games with opponent, date, location information
2. Users should be able to edit game details
3. Users should be able to view a list of all games played
4. Users should be able to filter games by opponent or date range
5. Users should be able to record game scores
6. Users should be able to create and edit lineups for each game

### Stat Tracking

1. The app must allow recording various statistical events during games
2. Stats should be associated with both a player and a game
3. Users should be able to view all stats for a specific game
4. Users should be able to view all stats for a specific player
5. The app should support common baseball stats (at-bats, hits, runs, etc.)
6. Users should be able to add notes to statistical events

### Data Analysis

1. The app should calculate batting averages and other derived statistics
2. Users should be able to view player performance trends over time
3. The app should display team-level statistics aggregated from player stats

## UI Requirements

The user interface should be intuitive and follow platform design guidelines. Key screens should include:

1. Player roster screen with filtering options
2. Individual player detail screen showing stats
3. Game list screen
4. Game detail screen with lineup and stats
5. Stat entry interface during games
6. Reports and analytics dashboard

## Performance Requirements

1. The app should load player and game lists in under 1 second
2. Database operations should not block the UI thread
3. The app should handle at least 100 players and 50 games without performance degradation
4. The app should gracefully handle large numbers of statistical events

## Implementation Notes

1. Use GRDB's ValueObservation for reactive UI updates
2. Implement proper error handling throughout the app
3. Use the repository pattern to abstract database operations
4. Consider UI state persistence for improved user experience
5. Implement proper data validation before saving to the database
6. Consider implementing an export feature for data backup

## Future Considerations

1. Cloud synchronization capabilities
2. Team management for multi-team scenarios
3. Advanced statistical analysis and visualizations
4. Import/export functionality for data sharing