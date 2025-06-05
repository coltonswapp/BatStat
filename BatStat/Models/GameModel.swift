import Foundation

// MARK: - Mock Data Models

struct Player: Identifiable, Codable {
    let id: UUID
    var name: String
    var number: Int?
    var primaryPosition: String
    var secondaryPositions: [String]
    
    init(id: UUID = UUID(), name: String, number: Int? = nil, primaryPosition: String, secondaryPositions: [String] = []) {
        self.id = id
        self.name = name
        self.number = number
        self.primaryPosition = primaryPosition
        self.secondaryPositions = secondaryPositions
    }
}

struct Game: Identifiable, Codable {
    let id: UUID
    var date: Date
    var location: String
    var opponent: String
    var homeScore: Int?
    var opponentScore: Int?
    var weatherConditions: String?
    var isWin: Bool? {
        guard let home = homeScore, let opponent = opponentScore else { return nil }
        return home > opponent
    }
    
    init(id: UUID = UUID(), date: Date, location: String, opponent: String, homeScore: Int? = nil, opponentScore: Int? = nil, weatherConditions: String? = nil) {
        self.id = id
        self.date = date
        self.location = location
        self.opponent = opponent
        self.homeScore = homeScore
        self.opponentScore = opponentScore
        self.weatherConditions = weatherConditions
    }
}

struct GameLineup: Codable {
    let gameId: UUID
    let playerId: UUID
    var position: String
    var battingOrder: Int?
    
    init(gameId: UUID, playerId: UUID, position: String, battingOrder: Int? = nil) {
        self.gameId = gameId
        self.playerId = playerId
        self.position = position
        self.battingOrder = battingOrder
    }
}

struct Stat: Identifiable, Codable {
    let id: UUID
    let gameId: UUID
    let playerId: UUID
    var timestamp: Date?
    var type: StatType
    var value: Int?
    var notes: String?
    
    // Hit location and trajectory data
    var hitLocation: HitLocation?
    
    init(id: UUID = UUID(), gameId: UUID, playerId: UUID, timestamp: Date? = nil, type: StatType, value: Int? = nil, notes: String? = nil, hitLocation: HitLocation? = nil) {
        self.id = id
        self.gameId = gameId
        self.playerId = playerId
        self.timestamp = timestamp
        self.type = type
        self.value = value
        self.notes = notes
        self.hitLocation = hitLocation
    }
}

// Hit location data for plotting on diamond
struct HitLocation: Codable {
    let x: Double // Normalized 0.0-1.0 relative to field width
    let y: Double // Normalized 0.0-1.0 relative to field height
    let height: Double // 0.0-1.0, where 0 = ground ball, 1 = high fly ball
    let fieldWidth: Double // Original field width when recorded (for scaling)
    let fieldHeight: Double // Original field height when recorded (for scaling)
    
    init(point: CGPoint, height: Double, fieldSize: CGSize) {
        self.x = Double(point.x / fieldSize.width)
        self.y = Double(point.y / fieldSize.height)
        self.height = height
        self.fieldWidth = Double(fieldSize.width)
        self.fieldHeight = Double(fieldSize.height)
    }
    
    // Convert back to CGPoint for any field size
    func toCGPoint(for fieldSize: CGSize) -> CGPoint {
        return CGPoint(
            x: CGFloat(x) * fieldSize.width,
            y: CGFloat(y) * fieldSize.height
        )
    }
}

enum StatType: String, CaseIterable, Codable {
    case atBat = "AB"
    case hit = "H"
    case run = "R"
    case rbi = "RBI"
    case homeRun = "HR"
    case strikeOut = "SO"
    case walk = "BB"
    case single = "1B"
    case double = "2B"
    case triple = "3B"
    case error = "E"
    case fieldersChoice = "FC"
    case sacrifice = "SAC"
}

// MARK: - Player Statistics Helper

struct PlayerGameStats {
    let player: Player
    var atBats: Int = 0
    var runs: Int = 0
    var hits: Int = 0
    var rbis: Int = 0
    var homeRuns: Int = 0
    
    var battingAverage: Double {
        guard atBats > 0 else { return 0.0 }
        return Double(hits) / Double(atBats)
    }
    
    init(player: Player, stats: [Stat]) {
        self.player = player
        
        for stat in stats {
            switch stat.type {
            case .atBat:
                atBats += stat.value ?? 1
            case .hit, .single, .double, .triple, .homeRun:
                hits += stat.value ?? 1
                if stat.type == .atBat || atBats == 0 {
                    atBats += 1
                }
            case .run:
                runs += stat.value ?? 1
            case .rbi:
                rbis += stat.value ?? 1
            case .homeRun:
                homeRuns += stat.value ?? 1
            default:
                if stat.type == .strikeOut || stat.type == .fieldersChoice {
                    atBats += 1
                }
            }
        }
    }
}