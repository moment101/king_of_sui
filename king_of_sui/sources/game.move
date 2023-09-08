module king_of_sui::game {

    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::balance::{Self, Balance};
    use sui::sui::SUI;
    use sui::coin::{Self, Coin};
    use sui::clock::{Self, Clock};
    use std::string::{Self, String};
    use std::vector;

    const ENotAdmin: u64 = 0;
    const ENotEnough: u64 = 1;
    const EGameInProcess: u64 = 2;
    const EGameNotInProcess: u64 = 3;
    const EGameIsEnded: u64 = 4;
    const EGameTimeIsNotUp: u64 = 5;

    const START_GAME_PRICE: u64 = 1000;
    const MINIMUM_BID_RATIO: u64 = 133;
    const FEE: u64 = 2;
    const LENGTH_OF_GAME_IN_MS: u64 = 60*10*1000; // 10 mins 

    struct GAME has drop {}

    struct GameStorageCap has key {
        id: UID
    }

    struct GameStorage has key {
        id: UID,
        games: vector<Game>,
        manage_balance: Balance<SUI>,
        in_progress: bool
    }

    struct Game has key ,store {
        id: UID,
        kings: vector<Player>,
        start_time: u64,
        in_progress: bool
    }

    struct Player has store {
        name: String,
        account :address,
        bid: u64
    }
    
    struct LeaderBoard has key {
        id: UID,
        kings: vector<Player>
    }

    fun init(_witness: GAME, ctx: &mut TxContext) {
        transfer::share_object(GameStorage{
            id: object::new(ctx),
            games: vector::empty<Game>(),
            manage_balance: balance::zero(),
            in_progress: false
        });

        transfer::share_object(LeaderBoard{
            id: object::new(ctx),
            kings: vector::empty<Player>()
        });

        transfer::transfer(GameStorageCap{
            id: object::new(ctx)
        }, tx_context::sender(ctx));
    }

    public entry fun create_game(storage: &mut GameStorage, name: vector<u8>, payment: Coin<SUI>, clock_object: &Clock, ctx: &mut TxContext) {
        assert!(storage.in_progress == false, EGameInProcess);
        assert!(coin::value(&payment) >= START_GAME_PRICE, ENotEnough);
        let player = Player {
            name: string::utf8(name),
            account: tx_context::sender(ctx),
            bid: coin::value(&payment)
        };
        
        let game = Game {
            id: object::new(ctx),
            kings: vector[player],
            start_time: clock::timestamp_ms(clock_object),
            in_progress: true 
        };
        balance::join(&mut storage.manage_balance, coin::into_balance(payment));
        vector::push_back<Game>(&mut storage.games, game);
        storage.in_progress = true;
    }

    public entry fun replaceKing(storage: &mut GameStorage, name: vector<u8>, payment: Coin<SUI>, clock_object: &Clock, ctx: &mut TxContext) {
        let games = &mut storage.games;
        let last_idx = vector::length(games) - 1;
        let game = vector::borrow_mut<Game>(games, last_idx);
        
        assert!(storage.in_progress == true, EGameNotInProcess);
        assert!(game.in_progress == true, EGameNotInProcess);
        assert!(clock::timestamp_ms(clock_object) <= game.start_time + LENGTH_OF_GAME_IN_MS, EGameIsEnded);
        
        let bidPrice = coin::value(&payment);
        assert!(bidPrice >= lastestBidPrice(game)*MINIMUM_BID_RATIO/100, ENotEnough);

        let player = Player {
            name: string::utf8(name),
            account: tx_context::sender(ctx),
            bid: bidPrice
        };
        vector::push_back<Player>(&mut game.kings, player);
        let feeAmount = bidPrice*FEE/100;
        let fee_coin = coin::split(&mut payment, feeAmount, ctx);
        balance::join(&mut storage.manage_balance, coin::into_balance(fee_coin));
        transfer::public_transfer(payment, lastestKing(game));
    }

    public fun lastestBidPrice(game: &Game): u64 {
        if (vector::is_empty(&game.kings)) return 0;
        let last_idx = vector::length(&game.kings) - 1;
        let king = vector::borrow<Player>(& game.kings, last_idx);
        king.bid
    }

    public fun lastestKing(game: &Game): address {
        let last_idx = vector::length(&game.kings) - 1;
        let king = vector::borrow<Player>(& game.kings, last_idx);
        king.account
    }

    public entry fun stopGame(storage: &mut GameStorage, clock_object: &Clock, _ctx: &mut TxContext) {
        let games = &mut storage.games;
        let last_idx = vector::length(games) - 1;
        let game = vector::borrow_mut<Game>(games, last_idx);
        
        assert!(storage.in_progress == true, EGameIsEnded);
        assert!(game.in_progress == true, EGameIsEnded);
        assert!(clock::timestamp_ms(clock_object) > game.start_time + LENGTH_OF_GAME_IN_MS, EGameTimeIsNotUp);
        storage.in_progress = false;
        game.in_progress = false;
    }

    public entry fun withdraw_all( _: &GameStorageCap, storage: &mut GameStorage, ctx: &mut TxContext) {
        let fee_coin: Coin<SUI> = coin::from_balance(balance::withdraw_all(&mut storage.manage_balance), ctx);
        transfer::public_transfer(fee_coin, tx_context::sender(ctx));
    }

    // Getter
    public fun kings_of_leaderboard(leader_board: &LeaderBoard): &vector<Player> {
        &leader_board.kings
    }

    public fun games_of_game_storage(storage: &GameStorage): &vector<Game> {
        &storage.games
    }

    public fun games_of_game_storage_mut(storage: &mut GameStorage): &mut vector<Game> {
        &mut storage.games
    }

    public fun exist_game(storage: &GameStorage): bool {
        let games = games_of_game_storage(storage);
        if (vector::length(games) == 0) {
            false
        } else {
            true
        }
    }

    public fun lastest_game(storage: &GameStorage): &Game {
        let games = games_of_game_storage(storage);
        
        let last_idx = vector::length(games) - 1;
        let game = vector::borrow<Game>(games, last_idx);
        game
    }

    public fun lastest_game_mut(storage: &mut GameStorage): &mut Game {
        let games = games_of_game_storage_mut(storage);
        
        let last_idx = vector::length(games) - 1;
        let game = vector::borrow_mut<Game>(games, last_idx);
        game
    }

    public fun lastest_game_current_king(storage: &GameStorage): &Player {
        let game = lastest_game(storage);
        let kings = &game.kings;

        let last_idx = vector::length(kings) - 1;
        let current_king = vector::borrow<Player>(kings, last_idx);
        current_king
    }

    public fun account_of_player(player: &Player): address {
        player.account
    }

    #[test_only]
    public fun init_test(ctx: &mut TxContext) {
        init(GAME{}, ctx);
    }
}
