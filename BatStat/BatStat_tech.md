
## HomeViewController
- UICollectionView
    - Section 1 with 2 rows (.inset layout)
        - Row 1: Players & Stats
        - Row 2: New Game
    - Section 2 with all past games
        - Each cell will have the title of the game ("vs. Enemy Team"), date, and win/loss
        - Section 2 will have a custom layout which makes the cells be squares (2 columns) in a grid
        
## GameViewController
- UICollectionView with 3 sections
    - Section 1 will have 1 row, will be the `AtBat` section (.insetGrouped)
        - AtBat section will have the current player who up to bat (label in the center of the cell)
        - A button on the leading edge to go to the previous player in the lineup (chevron.left)
        - A button on the trailing edge to go to the next player in the lineup (chevron.right)
        - Tapping on the cell allows the user to enter the outcome of the AB (hit, strike, etc)
    - Section 2 will have as many rows as roster members (.insetGrouped)
        - Use a custom section header with several labels
            - Section leading edge label should say "Statistics"
            - Trailing group of labels should be for the statistics
                - Label for each AB, R, H, RBI, HR, AVG, aligned to the trailing side
        - Each cell in the section should be the player's name on the leading edge (C. Swapp)
        - Stats correlating with the header should be aligned on the trailing edge
    - Section 3 will have past games with the same cell layout as seen in section 2 of the `HomeViewController`
        - Populated with past games against the same team
        
        
## PlayerStatViewController
- UICollectionView with 2 sections
    - Refer to the `insetGrouped` style of constructing sections and headers used in the `GamesViewController`
    - Section 1 will be used to display the player's stats for the current game (reuse the @PlayerStatCell), include the @SectionHeaderView to display a header of `TONIGHT`
    - Section 2 will be used to display each of the user's at-bats for the current game
        - 2 labels, leading label denoting the # of at bat
        - trailing label denoting the outcome ("base hit", "fly out", "2 base RBI")
    
## RecordAtBatViewController
- UICollectionView
    - Section 1 (header: "BALL IN PLAY") will be used to display different outcomes of an at-bat with the following options
        - Out at first
        - Single
        - Double
        - Triple
        - Foul Ball
        - HR
        - RBI (add a button with UIMenu on the right side of the cell to select 1, 2, 3 run RBI)
    - Section 2 (header: "LOG HIT") will be used to enter the trajectory and location of the hit, using the `interactiveDiamondView`

## EditGameViewController
- UICollectionView
    - First section (.insetGrouped)
        - First cell has a textField to be able to enter the team name (UITextField placeholder "Team Name")
        - Second cell should have a date picker defaulted to today, to change date of game
    - Second section (.insetGrouped) (section title of "Roster")
        - List of player names and numbers with reorderability
        - Roster is limited to 10 players
        - Edit mode for CollectionView to freely remove rows
    - Third Section (.insetGrouped) is the player bank
        - List of ALL players (but not those who are already on the roster)
        - Edit mode for CollectionView to freely add players to the roster section
        
- Save button top right corner

## PlayByPlayViewController
- UICollectionView
    - Each inning will be it's own section
    - Displaying the at-bat results with the associated player's name
    - as the first cell in each section, we should display the number of ABs, Hits, RBI's, etc. Using a new header that is similar to the @statisticsHeaderView (title: "Inning 1") 
    
## PlayerSummaryViewController
- UICollectionView
    - Section 1, header "All-Time Stats" (use @StatisticsHeaderView)
        - used to display the all time statistics across all recorded games for the player
    - Section 2, header "Stats by Game" (use @StatisticsHeaderView)
        - used to display all the games the user has participated in with stats for that game 
            - opponent name on left + short date, statistics on right (ex: "Killa Bees ⋅ 6/6")
            - tapping on the game will navigate to the `PlayerGameSummaryViewController` to see stats for the individual game
    
## PlayerGameSummaryViewController
- used to display how a single player performed in a specific game. 
- Take inspiration from the @PlayerStatViewController
    - instead of `TONIGHT` section, `vs. Killa Bees ⋅ 6/6`
    - display all of the at-bats
    - remove the cell to add another at bat because this game is presumably ended
- Include spray chart from the game for the player

## GameSummaryViewController
- UICollectionView
    - Section 1 "Game Info"
        - display the opponent, date, score, win/loss
    - Section 2 "Player Statistics"
        - display the player statistics for the game, in the same manner that we display statistics on the @GameViewController
    - Section 3 "Innings"
        - display each inning that was recorded, along with the inning stats using the @InningTotalsCell (header of @InningStatsHeaderView)
        - Tapping on the inning cell will take us to an @InningDetailViewController
        
## InningDetailViewController
- This viewController will be setup almost the same way as the @PlayByPlayViewController
- Display all the events that happened in the associated inning (only 1 inning)
- Section 2 should be a spray chart of all the hits that were recorded that inning. 
    
     

## Queries
- all stats for an individual player
- all at-bats for an individual player (grouped by game)
- all at-bats for an individual game (all players)


I want to continue to build beyond our @BatStat/Scenes/PlayersListViewController.swift and view player stats on a          │
│   per-player and per game basis. I'd like to build a `PlayerSummaryViewController` which tells us a variety of statitics.    │
│   I've included new instructions for `PlayerSummaryViewController`, as well as the `PlayerGameSummaryViewController`  
