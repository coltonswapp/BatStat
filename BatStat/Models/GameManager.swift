//
//  GameManager.swift
//  BatStat
//
//  Created by Colton Swapp on 5/5/25.
//

import Foundation
import CoreData

class GameManager {
    
    static let shared = GameManager()
    
    private let persistenceController = PersistenceController.shared
    
    // MARK: - Game Operations
    
    func createGame(opponentName: String, players: [Player]) -> GameEntity {
        let context = persistenceController.viewContext
        let game = GameEntity(context: context)
        game.id = UUID()
        game.opponentName = opponentName
        game.date = Date()
        
        // Add players to the game lineup
        for (index, player) in players.enumerated() {
            let playerEntity = PlayerEntity(context: context)
            playerEntity.id = player.id
            playerEntity.firstName = player.firstName
            playerEntity.lastName = player.lastName
            playerEntity.number = Int16(player.number)
            playerEntity.orderIndex = Int16(index)
            playerEntity.game = game
        }
        
        // Save the context
        persistenceController.save()
        
        // Post notification that data has changed
        NotificationCenter.default.post(name: NSNotification.Name("GameDataChanged"), object: nil)
        
        return game
    }
    
    func fetchGames() -> [GameEntity] {
        let context = persistenceController.viewContext
        let fetchRequest = NSFetchRequest<GameEntity>(entityName: "GameEntity")
        let sortDescriptor = NSSortDescriptor(key: "date", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        do {
            let games = try context.fetch(fetchRequest)
            return games
        } catch {
            print("Error fetching games: \(error)")
            return []
        }
    }
    
    func deleteGame(_ game: GameEntity) {
        let context = persistenceController.viewContext
        context.delete(game)
        persistenceController.save()
        
        // Post notification that data has changed
        NotificationCenter.default.post(name: NSNotification.Name("GameDataChanged"), object: nil)
    }
    
    // MARK: - Player Operations
    
    func getPlayersForGame(_ game: GameEntity) -> [Player] {
        guard let lineup = game.lineup?.array as? [PlayerEntity] else {
            return []
        }
        
        // Sort players by order index
        let sortedLineup = lineup.sorted { $0.orderIndex < $1.orderIndex }
        
        // Convert PlayerEntity to Player model
        return sortedLineup.map { entity in
            Player(
                firstName: entity.firstName ?? "",
                lastName: entity.lastName ?? "",
                number: Int(entity.number)
            )
        }
    }
    
    func updateGameLineup(game: GameEntity, players: [Player]) {
        let context = persistenceController.viewContext
        
        // First, fetch all existing PlayerEntity objects related to this game
        let fetchRequest = NSFetchRequest<PlayerEntity>(entityName: "PlayerEntity")
        fetchRequest.predicate = NSPredicate(format: "game == %@", game)
        
        do {
            let existingPlayers = try context.fetch(fetchRequest)
            
            // Delete all existing players
            for player in existingPlayers {
                context.delete(player)
            }
            
            // Now create new player entities
            for (index, player) in players.enumerated() {
                let playerEntity = PlayerEntity(context: context)
                playerEntity.id = player.id
                playerEntity.firstName = player.firstName
                playerEntity.lastName = player.lastName
                playerEntity.number = Int16(player.number)
                playerEntity.orderIndex = Int16(index)
                playerEntity.game = game
            }
            
            // Save changes
            persistenceController.save()
            
            // Post notification that data has changed
            NotificationCenter.default.post(name: NSNotification.Name("GameDataChanged"), object: nil)
            
        } catch {
            print("Error updating game lineup: \(error)")
        }
    }
} 