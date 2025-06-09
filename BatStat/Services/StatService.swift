import Foundation
import Supabase

class StatService {
    private let supabase = SupabaseConfig.shared.client
    
    static let shared = StatService()
    
    private init() {}
    
    /// Record a new at-bat for a player in a game
    func recordAtBat(
        gameId: UUID,
        playerId: UUID,
        type: StatType,
        outcome: String? = nil,
        runsBattedIn: Int? = nil,
        inning: Int? = nil,
        atBatNumber: Int? = nil,
        hitLocation: HitLocation? = nil
    ) async throws -> Stat {
        Logger.info("Recording at-bat: \(type.rawValue) for player \(playerId) in game \(gameId)", category: .stats)
        
        // Debug: Log the at-bat number being passed
        if let atBatNumber = atBatNumber {
            print("🔢 At-bat number being saved: \(atBatNumber)")
        } else {
            print("⚠️ WARNING: at-bat number is NIL")
        }
        
        // Log hit location details if present
        if let hitLocation = hitLocation {
            print("💾 Saving hit location: x=\(hitLocation.x), y=\(hitLocation.y), height=\(hitLocation.height), gridRes=\(hitLocation.gridResolution)")
        } else {
            print("💾 No hit location data to save")
        }
        
        let newStat = Stat(
            gameId: gameId,
            playerId: playerId,
            inning: inning,
            atBatNumber: atBatNumber,
            timestamp: Date(),
            outcome: outcome,
            runsBattedIn: runsBattedIn,
            type: type,
            hitLocation: hitLocation
        )
        
        // Debug: Log the Stat object being created
        print("📊 Created Stat object with at_bat_number: \(newStat.atBatNumber ?? -1)")
        
        // Log the actual database fields that will be saved
        print("📝 Database fields: hitLocationX=\(newStat.hitLocationX ?? 0), hitLocationY=\(newStat.hitLocationY ?? 0), hitLocationHeight=\(newStat.hitLocationHeight ?? 0), hitLocationGridResolution=\(newStat.hitLocationGridResolution ?? 0)")
        
        do {
            let response: Stat = try await supabase
                .from("stats")
                .insert(newStat)
                .select()
                .single()
                .execute()
                .value
            
            Logger.info("Successfully recorded at-bat", category: .stats)
            
            // Debug: Log what was actually returned from database
            print("✅ Database returned at_bat_number: \(response.atBatNumber ?? -1)")
            
            // Log what was actually saved and returned from database
            if let savedHitLocation = response.hitLocation {
                print("✅ Database saved hit location: x=\(savedHitLocation.x), y=\(savedHitLocation.y), height=\(savedHitLocation.height), gridRes=\(savedHitLocation.gridResolution)")
            }
            
            return response
        } catch {
            Logger.error("Failed to record at-bat: \(error.localizedDescription)", category: .stats)
            throw error
        }
    }
    
    /// Fetch all stats for a specific game
    func fetchGameStats(gameId: UUID) async throws -> [Stat] {
        Logger.debug("Fetching stats for game: \(gameId)", category: .stats)
        
        do {
            let response: [Stat] = try await supabase
                .from("stats")
                .select()
                .eq("game_id", value: gameId)
                .order("timestamp", ascending: true)
                .execute()
                .value
            
            Logger.info("Fetched \(response.count) stats for game", category: .stats)
            return response
        } catch {
            Logger.error("Failed to fetch game stats: \(error.localizedDescription)", category: .stats)
            throw error
        }
    }
    
    /// Fetch stats for a specific player in a specific game
    func fetchPlayerGameStats(gameId: UUID, playerId: UUID) async throws -> [Stat] {
        Logger.debug("Fetching stats for player \(playerId) in game \(gameId)", category: .stats)
        
        do {
            let response: [Stat] = try await supabase
                .from("stats")
                .select()
                .eq("game_id", value: gameId)
                .eq("player_id", value: playerId)
                .order("timestamp", ascending: true)
                .execute()
                .value
            
            Logger.info("Fetched \(response.count) stats for player in game", category: .stats)
            return response
        } catch {
            Logger.error("Failed to fetch player game stats: \(error.localizedDescription)", category: .stats)
            throw error
        }
    }
    
    /// Fetch recent at-bats for a game (last 10)
    func fetchRecentAtBats(gameId: UUID, limit: Int = 10) async throws -> [Stat] {
        Logger.debug("Fetching recent at-bats for game: \(gameId)", category: .stats)
        
        do {
            let response: [Stat] = try await supabase
                .from("stats")
                .select()
                .eq("game_id", value: gameId)
                .order("timestamp", ascending: false)
                .limit(limit)
                .execute()
                .value
            
            Logger.info("Fetched \(response.count) recent at-bats for game", category: .stats)
            return response
        } catch {
            Logger.error("Failed to fetch recent at-bats: \(error.localizedDescription)", category: .stats)
            throw error
        }
    }
    
    /// Calculate PlayerGameStats from raw stat data
    func calculatePlayerGameStats(player: Player, stats: [Stat]) -> PlayerGameStats {
        return PlayerGameStats(player: player, stats: stats)
    }
    
    /// Convenience method to get calculated stats for a player in a game
    func getPlayerGameStats(gameId: UUID, player: Player) async throws -> PlayerGameStats {
        let stats = try await fetchPlayerGameStats(gameId: gameId, playerId: player.id)
        return calculatePlayerGameStats(player: player, stats: stats)
    }
}
