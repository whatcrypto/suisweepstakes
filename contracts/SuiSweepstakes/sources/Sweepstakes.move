address suisweepstakes {

/// A simple sweepstakes contract allowing an owner to post a prize and randomize a winner
/// based on on-chain pseudo-randomness provided by the current transaction context.
module sweepstakes {
    use sui::object::{Self as object, UID};
    use sui::coin::{Self as coin, Coin};
    use sui::tx_context::{Self as tx_context, TxContext};
    use sui::transfer;
    use sui::vector;
    use sui::event;
    use sui::error;

    /// Event emitted when a winner is selected.
    struct WinnerEvent has drop, store {
        sweepstakes_id: UID,
        winner: address,
        prize_amount: u64,
    }

    /// The `Sweepstakes` object tracks participants and holds the prize money until the
    /// competition is closed by the owner.
    struct Sweepstakes has key, store {
        id: UID,
        owner: address,
        participants: vector<address>,
        prize: Coin<SUI>,
        end_timestamp_ms: u64,
    }

    /// Initialises a new sweepstakes instance.
    ///
    /// * `owner` – signer who funds and controls this sweepstakes.
    /// * `prize` – SUI coins to be awarded to the eventual winner.
    /// * `end_timestamp_ms` – unix epoch time (ms) after which `close` can be executed.
    public fun create(
        owner: &signer,
        mut prize: Coin<SUI>,
        end_timestamp_ms: u64,
        ctx: &mut TxContext,
    ): Sweepstakes {
        let prize_value = coin::value(&prize);
        // 0-value prizes would waste gas and be misleading.
        assert!(prize_value > 0, error::invalid_argument(0));

        let uid = object::new(ctx);
        let owner_addr = signer::address_of(owner);

        Sweepstakes {
            id: uid,
            owner: owner_addr,
            participants: vector::empty<address>(),
            prize,
            end_timestamp_ms,
        }
    }

    /// Allows any account to enter the sweepstakes before the deadline.
    public fun enter(sw: &mut Sweepstakes, participant: &signer, ctx: &TxContext) {
        // Require entries before the closing time.
        assert!(tx_context::get_timestamp_ms(ctx) < sw.end_timestamp_ms, error::permission_denied(1));

        let addr = signer::address_of(participant);
        // Prevent duplicate entries – you only get one ticket!
        assert!(!vector::contains(&sw.participants, &addr), error::already_exists(2));

        vector::push_back(&mut sw.participants, addr);
    }

    /// Closes the sweepstakes, selects a winner at random, and transfers the prize.
    /// Only the owner can invoke this function and only after the deadline has elapsed.
    public fun close(sw: &mut Sweepstakes, owner: &signer, ctx: &mut TxContext) acquires Sweepstakes {
        let caller = signer::address_of(owner);
        assert!(caller == sw.owner, error::permission_denied(3));
        assert!(tx_context::get_timestamp_ms(ctx) >= sw.end_timestamp_ms, error::permission_denied(4));

        let total_participants = vector::length(&sw.participants);
        assert!(total_participants > 0, error::invalid_state(5));

        // Obtain pseudo-random value from the context and turn it into an index.
        let rand = tx_context::random_u64(ctx);
        let index = rand % total_participants;
        let winner_addr = *vector::borrow(&sw.participants, index);

        let prize_amount = coin::value(&sw.prize);
        // Transfer the coin object to the winner.
        transfer::public_transfer(&mut sw.prize, winner_addr);

        // Emit an event so external watchers can detect the winner.
        event::emit<WinnerEvent>(WinnerEvent {
            sweepstakes_id: sw.id,
            winner: winner_addr,
            prize_amount,
        }, ctx);
    }
}

}