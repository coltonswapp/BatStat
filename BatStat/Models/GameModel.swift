import Foundation
import UIKit.UIColor

// MARK: - Mock Data Models

struct Player: Identifiable, Codable {
    let id: UUID
    var name: String
    var number: Int?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case number
    }
    
    init(id: UUID = UUID(), name: String, number: Int? = nil) {
        self.id = id
        self.name = name
        self.number = number
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
    var isComplete: Bool
    var isWin: Bool? {
        guard let home = homeScore, let opponent = opponentScore else { return nil }
        return home > opponent
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case date
        case location
        case opponent
        case homeScore = "home_score"
        case opponentScore = "opponent_score"
        case weatherConditions = "weather_conditions"
        case isComplete = "is_complete"
    }
    
    init(id: UUID = UUID(), date: Date, location: String, opponent: String, homeScore: Int? = nil, opponentScore: Int? = nil, weatherConditions: String? = nil, isComplete: Bool = false) {
        self.id = id
        self.date = date
        self.location = location
        self.opponent = opponent
        self.homeScore = homeScore
        self.opponentScore = opponentScore
        self.weatherConditions = weatherConditions
        self.isComplete = isComplete
    }
}

struct GameLineup: Codable {
    let gameId: UUID
    let playerId: UUID
    var battingOrder: Int?
    
    enum CodingKeys: String, CodingKey {
        case gameId = "game_id"
        case playerId = "player_id"
        case battingOrder = "batting_order"
    }
    
    init(gameId: UUID, playerId: UUID, battingOrder: Int? = nil) {
        self.gameId = gameId
        self.playerId = playerId
        self.battingOrder = battingOrder
    }
}

struct Stat: Identifiable, Codable {
    let id: UUID
    let createdAt: Date?
    let updatedAt: Date?
    let gameId: UUID
    let playerId: UUID
    var inning: Int?
    var atBatNumber: Int?
    var timestamp: Date
    var outcome: String?
    var runsBattedIn: Int?
    var type: StatType
    var hitLocationX: Double?
    var hitLocationY: Double?
    var hitLocationHeight: Double?
    var hitLocationGridResolution: Int? // Track grid size used for this hit
    
    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case gameId = "game_id"
        case playerId = "player_id"
        case inning
        case atBatNumber = "at_bat_number"
        case timestamp
        case outcome
        case runsBattedIn = "runs_batted_in"
        case type = "stat_type"
        case hitLocationX = "hit_location_x"
        case hitLocationY = "hit_location_y"
        case hitLocationHeight = "hit_location_height"
        case hitLocationGridResolution = "hit_location_grid_resolution"
    }
    
    init(gameId: UUID, playerId: UUID, inning: Int? = nil, atBatNumber: Int? = nil, timestamp: Date = Date(), outcome: String? = nil, runsBattedIn: Int? = nil, type: StatType, hitLocation: HitLocation? = nil) {
        self.id = UUID()
        self.createdAt = nil // Let Supabase handle this
        self.updatedAt = nil
        self.gameId = gameId
        self.playerId = playerId
        self.inning = inning
        self.atBatNumber = atBatNumber
        self.timestamp = timestamp
        self.outcome = outcome
        self.runsBattedIn = runsBattedIn
        self.type = type
        
        // Store hit location data if provided
        if let hitLocation = hitLocation {
            self.hitLocationX = hitLocation.x
            self.hitLocationY = hitLocation.y
            self.hitLocationHeight = hitLocation.height
            self.hitLocationGridResolution = hitLocation.gridResolution
        } else {
            self.hitLocationX = nil
            self.hitLocationY = nil
            self.hitLocationHeight = nil
            self.hitLocationGridResolution = nil
        }
    }
    
    // Computed property to get HitLocation from the stored fields
    var hitLocation: HitLocation? {
        guard let x = hitLocationX,
              let y = hitLocationY,
              let height = hitLocationHeight,
              let gridResolution = hitLocationGridResolution else {
            return nil
        }
        
        return HitLocation(
            x: x, y: y, height: height, gridResolution: gridResolution
        )
    }
}

// Hit location data for plotting on diamond using normalized grid coordinates
struct HitLocation: Codable {
    let x: Double // Normalized 0.0-1.0 grid coordinates
    let y: Double // Normalized 0.0-1.0 grid coordinates  
    let height: Double // 0.0-1.0, where 0 = ground ball, 1 = high fly ball
    let gridResolution: Int // Track grid size used for this hit
    
    // Initialize from normalized grid coordinates (preferred method)
    init(normalizedPoint: CGPoint, height: Double, gridResolution: Int = 40) {
        self.x = Double(normalizedPoint.x)
        self.y = Double(normalizedPoint.y)
        self.height = height
        self.gridResolution = gridResolution
    }
    
    // Legacy initializer for backward compatibility with screen coordinates
    init(point: CGPoint, height: Double, fieldSize: CGSize, gridResolution: Int = 40) {
        // Convert screen point to normalized coordinates
        self.x = Double(point.x / fieldSize.width)
        self.y = Double(point.y / fieldSize.height)
        self.height = height
        self.gridResolution = gridResolution
    }
    
    // Direct initializer for database storage
    init(x: Double, y: Double, height: Double, gridResolution: Int = 40) {
        self.x = x
        self.y = y
        self.height = height
        self.gridResolution = gridResolution
    }
    
    // Convert normalized coordinates to screen coordinates for any field size
    func toCGPoint(for fieldSize: CGSize) -> CGPoint {
        return CGPoint(
            x: CGFloat(x) * fieldSize.width,
            y: CGFloat(y) * fieldSize.height
        )
    }
    
    // Get the normalized coordinates as a CGPoint
    func normalizedPoint() -> CGPoint {
        return CGPoint(x: x, y: y)
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
    case flyOut = "FO"
    
    var legendLabel: String {
        switch self  {
        case .single:
            return "Single"
        case .double:
            return "Double"
        case .triple:
            return "Triple"
        case .homeRun:
            return "Home Run"
        case .flyOut:
            return "Fly Out"
        default:
            return rawValue
        }
    }
    
    var color: UIColor {
        switch self {
        case .single:
            return UIColor.systemGreen
        case .double:
            return UIColor.systemOrange
        case .triple:
            return UIColor.systemBlue
        case .homeRun:
            return UIColor.systemRed
        case .flyOut:
            return UIColor.black
        default:
            return UIColor.systemBlue
        }
    }
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
                atBats += 1
            case .hit, .single:
                hits += 1
                atBats += 1
            case .double:
                hits += 1
                atBats += 1
            case .triple:
                hits += 1
                atBats += 1
            case .homeRun:
                hits += 1
                homeRuns += 1
                runs += 1 // Home run always counts as a run for the batter
                atBats += 1
            case .run:
                runs += 1
            case .strikeOut:
                atBats += 1
            case .walk:
                // Walks don't count as at-bats
                break
            case .rbi:
                // RBI is handled separately below
                break
            default:
                // Most other outcomes count as at-bats
                atBats += 1
            }
            
            // Add RBIs if present
            if let rbiCount = stat.runsBattedIn {
                rbis += rbiCount
            }
        }
    }
}
