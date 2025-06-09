import Foundation

class MockDataManager {
    static let shared = MockDataManager()
    
    private init() {}
    
    // MARK: - Mock Players
    
    lazy var players: [Player] = [
        Player(name: "M. Johnson", number: 22),
        Player(name: "D. Brown", number: 9),
        Player(name: "C. Wilson", number: 4),
        Player(name: "J. Davis", number: 12),
        Player(name: "A. Martinez", number: 7),
        Player(name: "R. Taylor", number: 15),
        Player(name: "S. Anderson", number: 33),
        Player(name: "K. Thompson", number: 8),
        Player(name: "L. Garcia", number: 19)
    ]
    
    // MARK: - Mock Games
    
    lazy var games: [Game] = [
        Game(
            date: Calendar.current.date(byAdding: .day, value: -7, to: Date())!,
            location: "Home Field",
            opponent: "Base Invaders",
            homeScore: 8,
            opponentScore: 5
        ),
        Game(
            date: Calendar.current.date(byAdding: .day, value: -14, to: Date())!,
            location: "Away Field",
            opponent: "Killa Bees",
            homeScore: 3,
            opponentScore: 7
        ),
        Game(
            date: Calendar.current.date(byAdding: .day, value: -21, to: Date())!,
            location: "Home Field",
            opponent: "Prestige",
            homeScore: 12,
            opponentScore: 4
        ),
        Game(
            date: Calendar.current.date(byAdding: .day, value: -28, to: Date())!,
            location: "Neutral",
            opponent: "PICS",
            homeScore: 6,
            opponentScore: 9
        ),
        Game(
            date: Calendar.current.date(byAdding: .day, value: -35, to: Date())!,
            location: "Home Field",
            opponent: "Base Invaders",
            homeScore: 4,
            opponentScore: 8
        )
    ]
    
    // Current game for the GameViewController
    lazy var currentGame: Game = {
        Game(
            date: Date(),
            location: "Home Field",
            opponent: "Base Invaders"
        )
    }()
    
    // MARK: - Mock Game Lineups
    
    func getLineup(for gameId: UUID) -> [GameLineup] {
        return players.enumerated().map { index, player in
            GameLineup(
                gameId: gameId,
                playerId: player.id,
                battingOrder: index + 1
            )
        }
    }
    
    // MARK: - Mock Stats
    
    func getStats(for gameId: UUID) -> [Stat] {
        var stats: [Stat] = []
        
        // Generate some sample stats for each player
//        for player in players.prefix(4) {
//            // At bats
//            stats.append(Stat(gameId: gameId, playerId: player.id, type: .atBat, value: 3))
//            
//            // Some hits
//            if player.name == "M. Johnson" {
//                stats.append(Stat(gameId: gameId, playerId: player.id, type: .hit, value: 2))
//                stats.append(Stat(gameId: gameId, playerId: player.id, type: .rbi, value: 2))
//            } else if player.name == "D. Brown" {
//                stats.append(Stat(gameId: gameId, playerId: player.id, type: .hit, value: 1))
//            }
//            
//            // Some runs
//            if ["M. Johnson", "C. Wilson"].contains(player.name) {
//                stats.append(Stat(gameId: gameId, playerId: player.id, type: .run, value: 1))
//            }
//        }
        
        return stats
    }
    
    func getPlayerStats(for playerId: UUID, in gameId: UUID) -> PlayerGameStats {
        let player = players.first { $0.id == playerId }!
        let stats = getStats(for: gameId).filter { $0.playerId == playerId }
        return PlayerGameStats(player: player, stats: stats)
    }
    
    func getAllPlayerStats(for gameId: UUID) -> [PlayerGameStats] {
        return players.map { player in
            getPlayerStats(for: player.id, in: gameId)
        }
    }
    
    func getPlayersInGame(gameId: UUID) -> [Player] {
        // For mock data, return all players
        return players
    }
    
    // MARK: - Current At Bat Management
    
    private var currentAtBatIndex = 0
    
    func getCurrentAtBatPlayer() -> Player {
        return players[currentAtBatIndex % players.count]
    }
    
    func nextAtBatPlayer() -> Player {
        currentAtBatIndex = (currentAtBatIndex + 1) % players.count
        return getCurrentAtBatPlayer()
    }
    
    func previousAtBatPlayer() -> Player {
        currentAtBatIndex = currentAtBatIndex == 0 ? players.count - 1 : currentAtBatIndex - 1
        return getCurrentAtBatPlayer()
    }
    
    // MARK: - Helper Methods
    
    func getGamesAgainst(opponent: String) -> [Game] {
        return games.filter { $0.opponent == opponent }
    }
    
    func formatGameDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"
        
        return "\(dateFormatter.string(from: date)), \(formatter.string(from: date))"
    }
}
