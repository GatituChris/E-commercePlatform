module Ecommerce_Platform::Platform {
    use sui::balance::{Balance, Self};
    use sui::coin::{Self, Coin, TreasuryCap};
    use sui::event::emit;
    use std::string::{Self, String};
    use sui::url::{Self, Url};
    use sui::transfer::public_transfer;
    use sui::sui::SUI;
    use sui::object::uid_to_inner;

    // Error codes
    const ENotShopOwner: u64 = 1;
    const EInvalidWithdrawalAmount: u64 = 2;
    const EInvalidQuantity: u64 = 3;
    const EInsufficientPayment: u64 = 4;
    const EInvalidPrice: u64 = 6;
    const EInvalidSupply: u64 = 7;
    const EItemIsNotListed: u64 = 8;

    // Structs
    public struct Store has key, store {
        id: UID,
        owner_cap: ID,
        balance: Balance<SUI>,
        item_count: u64,
    }

    public struct StoreOwnerCapability has key, store {
        id: UID,
        store: ID,
    }

    public struct Item has key, store {
        id: UID,
        title: String,
        description: String,
        price: u64,
        url: Url,
        listed: bool,
        category: u8,
        total_supply: u64,
        available: u64,
    }

    public struct StoreCreated has copy, drop {
        store_id: ID,
        store_owner_cap_id: ID,
    }

    public struct ItemAdded has copy, drop {
        store_id: ID,
        item_id: ID,
    }

    public struct ItemPurchased has copy, drop {
        store_id: ID,
        item_id: ID,
        quantity: u64,
        buyer: address,
    }

    public struct ItemUnlisted has copy, drop {
        store_id: ID,
        item_id: ID,
    }

    public struct StoreWithdrawal has copy, drop {
        store_id: ID,
        amount: u64,
        recipient: address,
    }

    public struct DeliveryInitiated has copy, drop {
        store_id: ID,
        item_id: ID,
        buyer: address,
    }

    public struct TransactionRating has key, store {
        id: UID,
        store_id: ID,
        item_id: ID,
        rating: u8,
        review: String,
        buyer: address,
    }

    #[allow(lint(self_transfer))]
    // Function to create a store
    public fun create_store(ctx: &mut TxContext) {
        let store_uid = object::new(ctx);
        let store_owner_cap_uid = object::new(ctx);

        let store_id = uid_to_inner(&store_uid);
        let store_owner_cap_id = uid_to_inner(&store_owner_cap_uid);

        public_transfer(StoreOwnerCapability {
            id: store_owner_cap_uid,
            store: store_id
        }, tx_context::sender(ctx));

        transfer::share_object(Store {
            id: store_uid,
            owner_cap: store_owner_cap_id,
            balance: balance::zero<SUI>(),
            item_count: 0,
        });

        emit(StoreCreated {
            store_id,
            store_owner_cap_id
        });
    }

    // Function to add items to a store
    public fun add_item(
        store: &mut Store,
        owner_cap: &StoreOwnerCapability,
        title: vector<u8>,
        description: vector<u8>,
        url: vector<u8>,
        price: u64,
        supply: u64,
        category: u8,
        ctx: &mut TxContext
    ) {
        assert!(store.owner_cap == uid_to_inner(&owner_cap.id), ENotShopOwner);
        assert!(price > 0, EInvalidPrice);
        assert!(supply > 0, EInvalidSupply);

        let item_uid = object::new(ctx);
        let item_id = uid_to_inner(&item_uid);

        let item = Item {
            id: item_uid,
            title: string::utf8(title),
            description: string::utf8(description),
            price: price,
            url: url::new_unsafe_from_bytes(url),
            listed: true,
            category: category,
            total_supply: supply,
            available: supply,
        };

        store.item_count = store.item_count + 1;

        sui::dynamic_field::add(&mut store.id, item_id, item);

        emit(ItemAdded {
            store_id: owner_cap.store,
            item_id: item_id,
        });
    }

    // Function to unlist an item from the store
    public fun unlist_item(
        store: &mut Store,
        owner_cap: &StoreOwnerCapability,
        item_id: ID
    ) {
        assert!(store.owner_cap == uid_to_inner(&owner_cap.id), ENotShopOwner);

        let item: &mut Item = sui::dynamic_field::borrow_mut(&mut store.id, item_id);
        item.listed = false;

        emit(ItemUnlisted {
            store_id: owner_cap.store,
            item_id: item_id,
        });
    }

    // Function to purchase an item from the store
    public fun purchase_item(
        store: &mut Store,
        item_id: ID,
        quantity: u64,
        recipient: address,
        payment_coin: &mut Coin<SUI>,
        ctx: &mut TxContext
    ) {
        let item: &mut Item = sui::dynamic_field::borrow_mut(&mut store.id, item_id);
        assert!(item.available >= quantity, EInvalidQuantity);
        let value = payment_coin.value();
        let total_price = item.price * quantity;
        assert!(value >= total_price, EInsufficientPayment);
        assert!(item.listed == true, EItemIsNotListed);
        item.available = item.available - quantity;
        let paid = payment_coin.split(total_price, ctx);
        coin::put(&mut store.balance, paid);
        let mut i = 0_u64;
        while (i < quantity) {
            let _purchased_item_uid = object::new(ctx);
            let item_transfer = Item {
                id: _purchased_item_uid,
                title: item.title,
                description: item.description,
                price: item.price,
                url: item.url,
                listed: item.listed,
                category: item.category,
                total_supply: item.total_supply,
                available: item.available,
            };
            public_transfer(item_transfer, recipient);
            i = i + 1;
        };

        if (item.available == 0) {
            item.listed = false;
            emit(ItemUnlisted {
                store_id: uid_to_inner(&store.id),
                item_id: item_id,
            });
        };
    }

    // Function to initiate delivery of an item
    public fun initiate_delivery(
        store: &mut Store,
        item_id: ID,
        buyer: address,
        _ctx: &mut TxContext
    ) {
        emit(DeliveryInitiated {
            store_id: uid_to_inner(&store.id),
            item_id: item_id,
            buyer: buyer,
        });
    }

    // Function to confirm delivery of an item
    public fun confirm_delivery(
        store: &mut Store,
        item_id: ID,
        buyer: address,
        cap: &mut TreasuryCap<SUI>,
        ctx: &mut TxContext
    ) {
        let item: &Item = sui::dynamic_field::borrow(&store.id, item_id);
        let total_price = item.price;
        coin::put(&mut store.balance, coin::mint(cap, total_price, ctx));
        emit(ItemPurchased {
            store_id: uid_to_inner(&store.id),
            item_id: item_id,
            quantity: 1,
            buyer: buyer,
        });
    }

    // Function to withdraw funds from the store
    public fun withdraw_from_store(
        store: &mut Store,
        owner_cap: &StoreOwnerCapability,
        amount: u64,
        recipient: address,
        ctx: &mut TxContext
    ) {
        assert!(store.owner_cap == uid_to_inner(&owner_cap.id), ENotShopOwner);
        assert!(amount > 0 && amount <= store.balance.value(), EInvalidWithdrawalAmount);
        let take_coin = coin::take(&mut store.balance, amount, ctx);
        public_transfer(take_coin, recipient);
        emit(StoreWithdrawal {
            store_id: uid_to_inner(&store.id),
            amount: amount,
            recipient: recipient,
        });
    }

    // Function to rate a transaction
    public fun rate_transaction(
        store: &Store,
        item_id: ID,
        rating: u8,
        review: vector<u8>,
        buyer: address,
        ctx: &mut TxContext
    ) {
        let rating_uid = object::new(ctx);
        public_transfer(TransactionRating {
            id: rating_uid,
            store_id: uid_to_inner(&store.id),
            item_id: item_id,
            rating: rating,
            review: string::utf8(review),
            buyer: buyer,
        }, buyer);
    }

    // Function to refund a purchase
    public fun refund_purchase(
        store: &mut Store,
        item_id: ID,
        quantity: u64,
        buyer: address,
        cap: &mut TreasuryCap<SUI>,
        ctx: &mut TxContext
    ) {
        let item: &mut Item = sui::dynamic_field::borrow_mut(&mut store.id, item_id);
        assert!(item.available + quantity <= item.total_supply, EInvalidQuantity);
        let refund_amount = item.price * quantity;
        coin::put(&mut store.balance, coin::mint(cap, refund_amount, ctx));
        item.available = item.available + quantity;
        emit(ItemPurchased {
            store_id: uid_to_inner(&store.id),
            item_id: item_id,
            quantity: quantity,
            buyer: buyer,
        });
    }

    // Getters for the store struct
    public fun get_store_uid(store: &Store): &UID {
        &store.id
    }

    public fun get_store_owner_cap(store: &Store): ID {
        store.owner_cap
    }

    public fun get_store_balance(store: &Store): &Balance<SUI> {
        &store.balance
    }

    public fun get_store_item_count(store: &Store): u64 {
        store.item_count
    }

    // Getters for the store owner capability struct
    public fun get_store_owner_cap_uid(owner_cap: &StoreOwnerCapability): &UID {
        &owner_cap.id
    }

    public fun get_store_owner_cap_store(owner_cap: &StoreOwnerCapability): ID {
        owner_cap.store
    }

    public fun get_item_title(item: &Item): &String {
        &item.title
    }

    public fun get_item_description(item: &Item): &String {
        &item.description
    }

    public fun get_item_price(item: &Item): u64 {
        item.price
    }

    public fun get_item_total_supply(item: &Item): u64 {
        item.total_supply
    }

    public fun get_item_available(item: &Item): u64 {
        item.available
    }

    public fun get_item_url(item: &Item): &Url {
        &item.url
    }

    public fun get_item_listed(item: &Item): bool {
        item.listed
    }

    public fun get_item_category(item: &Item): u8 {
        item.category
    }
}
