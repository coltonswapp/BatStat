import Foundation
import Supabase

class PlayerService {
    private let supabase = SupabaseConfig.shared.client
    
    func createPlayer(name: String, jerseyNumber: Int?) async throws -> Player {
        Logger.info("Creating new player: \(name)", category: .players)
        
        let newPlayer = Player(
            name: name,
            number: jerseyNumber
        )
        
        do {
            let response: Player = try await supabase
                .from("players")
                .insert(newPlayer)
                .select()
                .single()
                .execute()
                .value
            
            Logger.info("Successfully created player: \(response.name) (ID: \(response.id))", category: .players)
            return response
        } catch {
            Logger.error("Failed to create player '\(name)': \(error.localizedDescription)", category: .players)
            throw error
        }
    }
    
    func fetchAllPlayers() async throws -> [Player] {
        Logger.debug("Fetching all players", category: .players)
        
        do {
            let response: [Player] = try await supabase
                .from("players")
                .select()
                .order("name", ascending: true)
                .execute()
                .value
            
            Logger.info("Successfully fetched \(response.count) players", category: .players)
            return response
        } catch {
            Logger.error("Failed to fetch players: \(error.localizedDescription)", category: .players)
            throw error
        }
    }
    
    func fetchPlayer(by id: UUID) async throws -> Player {
        let response: Player = try await supabase
            .from("players")
            .select()
            .eq("id", value: id)
            .single()
            .execute()
            .value
        
        return response
    }
    
    func fetchPlayersInGame(gameId: UUID) async throws -> [Player] {
        Logger.debug("Fetching players for game ID: \(gameId)", category: .players)
        
        do {
            // First, get the game lineups for this game
            let lineups: [GameLineup] = try await supabase
                .from("game_lineups")
                .select()
                .eq("game_id", value: gameId)
                .order("batting_order", ascending: true)
                .execute()
                .value
            
            Logger.debug("Found \(lineups.count) lineup entries for game", category: .players)
            
            if lineups.isEmpty {
                Logger.info("No players found in game lineup", category: .players)
                return []
            }
            
            // Then get all the players for those player IDs
            let playerIds = lineups.map { $0.playerId }
            let players: [Player] = try await supabase
                .from("players")
                .select()
                .in("id", values: playerIds)
                .execute()
                .value
            
            // Sort players by their batting order from the lineup
            let sortedPlayers = players.sorted { player1, player2 in
                let order1 = lineups.first(where: { $0.playerId == player1.id })?.battingOrder ?? Int.max
                let order2 = lineups.first(where: { $0.playerId == player2.id })?.battingOrder ?? Int.max
                return order1 < order2
            }
            
            Logger.info("Successfully fetched \(sortedPlayers.count) players for game", category: .players)
            return sortedPlayers
        } catch {
            Logger.error("Failed to fetch players in game: \(error)", category: .players)
            throw error
        }
    }
    
    func addPlayerToGame(playerId: UUID, gameId: UUID, battingOrder: Int) async throws {
        Logger.info("Adding player \(playerId) to game \(gameId) at batting order \(battingOrder)", category: .players)
        
        let lineup = GameLineup(
            gameId: gameId,
            playerId: playerId,
            battingOrder: battingOrder
        )
        
        Logger.debug("GameLineup object: \(lineup)", category: .players)
        
        do {
            try await supabase
                .from("game_lineups")
                .insert(lineup)
                .execute()
            
            Logger.info("Successfully added player to game lineup", category: .players)
        } catch {
            Logger.error("Failed to add player to game: \(error)", category: .players)
            throw error
        }
    }
    
    func removePlayerFromGame(playerId: UUID, gameId: UUID) async throws {
        try await supabase
            .from("game_lineups")
            .delete()
            .eq("player_id", value: playerId)
            .eq("game_id", value: gameId)
            .execute()
    }
    
    func updatePlayer(_ player: Player) async throws -> Player {
        let response: Player = try await supabase
            .from("players")
            .update(player)
            .eq("id", value: player.id)
            .select()
            .single()
            .execute()
            .value
        
        return response
    }
    
    func deletePlayer(id: UUID) async throws {
        Logger.info("Deleting player with ID: \(id)", category: .players)
        
        do {
            try await supabase
                .from("players")
                .delete()
                .eq("id", value: id)
                .execute()
            
            Logger.info("Successfully deleted player with ID: \(id)", category: .players)
        } catch {
            Logger.error("Failed to delete player with ID \(id): \(error.localizedDescription)", category: .players)
            throw error
        }
    }
}
