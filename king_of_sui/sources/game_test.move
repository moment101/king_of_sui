#[test_only]
module king_of_sui::game_tests {
    
    #[test]
    fun create_game() {
        use sui::transfer;
        use sui::sui::SUI;
        use sui::coin::{Self, Coin};
        use sui::object::{Self, UID};
        use sui::balance::{Self, Balance};
        use sui::tx_context::{Self, TxContext};
        use sui::clock::{Self, Clock};
        use std::string::{Self, String};
        use std::vector;
        use std::debug;

        use king_of_sui::game::{Self, GameStorage, GameStorageCap, LeaderBoard, init_test, kings_of_leaderboard, games_of_game_storage, create_game, lastest_game_current_king, account_of_player, lastest_game, lastest_game_mut, replaceKing, stopGame};
        use sui::test_scenario as ts;

        let owner = @0xCAFE;
        let alice = @0x2;
        let bob = @0x3;
        let tom = @0x4;
        let scenario_val = ts::begin(owner);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, owner);
        {
            init_test(ts::ctx(scenario));
        };

        ts::next_tx(scenario, owner);
        {
            assert!(ts::has_most_recent_for_sender<GameStorageCap>(scenario), 0);
        };

        ts::next_tx(scenario, owner);
        {
            let leader_board = ts::take_shared<LeaderBoard>(scenario);
            assert!(vector::length(kings_of_leaderboard(&leader_board)) == 0, 0);
            ts::return_shared<LeaderBoard>(leader_board);
        };

        ts::next_tx(scenario, owner);
        {
            let storage = ts::take_shared<GameStorage>(scenario);
            assert!(vector::length(games_of_game_storage(&storage)) == 0, 0);
            ts::return_shared<GameStorage>(storage);
        };

        ts::next_tx(scenario, owner);
        {
            let coin = coin::mint_for_testing<SUI>(10000, ts::ctx(scenario));
            transfer::public_transfer(coin, owner);
        };

        ts::next_tx(scenario, alice);
        {
            let coin = coin::mint_for_testing<SUI>(10000, ts::ctx(scenario));
            transfer::public_transfer(coin, alice);
        };

        ts::next_tx(scenario, bob);
        {
            let coin = coin::mint_for_testing<SUI>(10000, ts::ctx(scenario));
            transfer::public_transfer(coin, bob);
        };

        ts::next_tx(scenario, tom);
        {
            let coin = coin::mint_for_testing<SUI>(10000, ts::ctx(scenario));
            transfer::public_transfer(coin, tom);
        };

        ts::next_tx(scenario, alice);
        {
            let clock = clock::create_for_testing(ts::ctx(scenario));
            clock::share_for_testing(clock);
        };

        ts::next_tx(scenario, alice);
        {
            let storage = ts::take_shared<GameStorage>(scenario);
            let alice_coin = ts::take_from_sender<Coin<SUI>>(scenario);
            let create_game_coin = coin::split(&mut alice_coin, 1000, ts::ctx(scenario));
            let clock = ts::take_shared<Clock>(scenario);
            create_game(&mut storage, b"Alice", create_game_coin, &clock, ts::ctx(scenario));
            transfer::public_transfer(alice_coin, alice);
            ts::return_shared<GameStorage>(storage);
            ts::return_shared<Clock>(clock);
        };

        ts::next_tx(scenario, bob);
        {
            let storage = ts::take_shared<GameStorage>(scenario);
            let current_king = lastest_game_current_king(& storage);
            debug::print<GameStorage>(&storage);
            assert!(account_of_player(current_king) == alice, 0);
            ts::return_shared<GameStorage>(storage);
        };

        ts::next_tx(scenario, owner);
        {
            let clock = ts::take_shared<Clock>(scenario);
            clock::increment_for_testing(&mut clock, 60*10*1000);
            ts::return_shared<Clock>(clock);
        };

        ts::next_tx(scenario, bob);
        {
            let storage = ts::take_shared<GameStorage>(scenario);
            let bob_coin = ts::take_from_sender<Coin<SUI>>(scenario);
            let bid_game_coin = coin::split(&mut bob_coin, 1500, ts::ctx(scenario));
            let clock = ts::take_shared<Clock>(scenario);
            replaceKing(&mut storage, b"Bob", bid_game_coin, &clock, ts::ctx(scenario));
            transfer::public_transfer(bob_coin, bob);
            ts::return_shared<GameStorage>(storage);
            ts::return_shared<Clock>(clock);
        };

        ts::next_tx(scenario, bob);
        {
            let storage = ts::take_shared<GameStorage>(scenario);
            let current_king = lastest_game_current_king(& storage);
            debug::print<GameStorage>(&storage);
            assert!(account_of_player(current_king) == bob, 0);
            ts::return_shared<GameStorage>(storage);
        };

        ts::next_tx(scenario, tom);
        {
            let storage = ts::take_shared<GameStorage>(scenario);
            let tom_coin = ts::take_from_sender<Coin<SUI>>(scenario);
            let bid_game_coin = coin::split(&mut tom_coin, 2000, ts::ctx(scenario));
            let clock = ts::take_shared<Clock>(scenario);
            replaceKing(&mut storage, b"Tom", bid_game_coin, &clock, ts::ctx(scenario));
            transfer::public_transfer(tom_coin, tom);
            ts::return_shared<GameStorage>(storage);
            ts::return_shared<Clock>(clock);
        };

        ts::next_tx(scenario, bob);
        {
            let storage = ts::take_shared<GameStorage>(scenario);
            let current_king = lastest_game_current_king(& storage);
            debug::print<GameStorage>(&storage);
            assert!(account_of_player(current_king) == tom, 0);
            ts::return_shared<GameStorage>(storage);
        };

        ts::next_tx(scenario, owner);
        {
            let clock = ts::take_shared<Clock>(scenario);
            clock::increment_for_testing(&mut clock, 1);
            ts::return_shared<Clock>(clock);
        };

        ts::next_tx(scenario, owner);
        {
            let storage = ts::take_shared<GameStorage>(scenario);
            let clock = ts::take_shared<Clock>(scenario);
            stopGame(&mut storage, &clock, ts::ctx(scenario));
            ts::return_shared<GameStorage>(storage);
            ts::return_shared<Clock>(clock);
        };

        // Game is end, below will fail
        // ts::next_tx(scenario, bob);
        // {
        //     let storage = ts::take_shared<GameStorage>(scenario);
        //     let bob_coin = ts::take_from_sender<Coin<SUI>>(scenario);
        //     let bid_game_coin = coin::split(&mut bob_coin, 2500, ts::ctx(scenario));
        //     let clock = ts::take_shared<Clock>(scenario);
        //     replaceKing(&mut storage, b"Bob", bid_game_coin, &clock, ts::ctx(scenario));
        //     transfer::public_transfer(bob_coin, bob);
        //     ts::return_shared<GameStorage>(storage);
        //     ts::return_shared<Clock>(clock);
        // };

        ts::end(scenario_val);
    }
}