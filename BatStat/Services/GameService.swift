import Foundation
import Supabase

class GameService {
    private let supabase = SupabaseConfig.shared.client
    
    static let shared = GameService()
    
    func createGame(opponent: String, location: String, date: Date) async throws -> Game {
        Logger.info("Creating game: opponent=\(opponent), location=\(location), date=\(date)", category: .games)
        
        // Check authentication
        if let currentUser = supabase.auth.currentUser {
            Logger.debug("User authenticated: \(currentUser.id)", category: .games)
        } else {
            Logger.error("No authenticated user found", category: .games)
            throw NSError(domain: "GameService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let newGame = Game(
            date: date,
            location: location,
            opponent: opponent
        )
        
        Logger.debug("Game object created: \(newGame)", category: .games)
        
        do {
            let response: Game = try await supabase
                .from("games")
                .insert(newGame)
                .select()
                .single()
                .execute()
                .value
            
            Logger.info("Successfully created game with ID: \(response.id)", category: .games)
            return response
        } catch {
            Logger.error("Failed to create game: \(error)", category: .games)
            throw error
        }
    }
    
    func fetchAllGames() async throws -> [Game] {
        let response: [Game] = try await supabase
            .from("games")
            .select()
            .order("date", ascending: false)
            .execute()
            .value
        
        return response
    }
    
    func fetchGame(by id: UUID) async throws -> Game {
        let response: Game = try await supabase
            .from("games")
            .select()
            .eq("id", value: id)
            .single()
            .execute()
            .value
        
        return response
    }
    
    func updateGame(_ game: Game) async throws -> Game {
        let response: Game = try await supabase
            .from("games")
            .update(game)
            .eq("id", value: game.id)
            .select()
            .single()
            .execute()
            .value
        
        return response
    }
    
    func deleteGame(id: UUID) async throws {
        try await supabase
            .from("games")
            .delete()
            .eq("id", value: id)
            .execute()
    }
    
    func markGameAsFinished(gameId: UUID) async throws -> Game {
        let response: Game = try await supabase
            .from("games")
            .update(["is_complete": true])
            .eq("id", value: gameId)
            .select()
            .single()
            .execute()
            .value
        
        return response
    }
    
    func updateGameScore(gameId: UUID, homeScore: Int, opponentScore: Int) async throws -> Game {
        let response: Game = try await supabase
            .from("games")
            .update([
                "home_score": homeScore,
                "opponent_score": opponentScore
            ])
            .eq("id", value: gameId)
            .select()
            .single()
            .execute()
            .value
        
        return response
    }
}
