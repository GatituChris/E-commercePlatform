## **Ecommerce_Platform Module**

### **Introduction**
The `Ecommerce_Platform` module is designed to facilitate a decentralized e-commerce platform on the Sui blockchain. It provides functionalities for creating and managing digital stores, listing items for sale, handling item purchases, initiating deliveries, and processing refunds. Additionally, the module supports user feedback and ratings, giving buyers the ability to review their purchases.

Key features include:
- **Store Creation and Management**: Users can create their own stores, manage items, and handle store funds.
- **Item Listings and Sales**: Store owners can add items, set prices, and handle sales directly through the module.
- **Event-driven Architecture**: Each significant action emits an event, allowing for easy tracking and logging of activities.
- **Secure Purchase Process**: Buyers can purchase items with on-chain payments, and the module ensures secure handling of payments and inventory.

### **Structs**
1. **Store**: Represents a digital store on the platform.
   - Fields:
     - `id`: Unique identifier for the store.
     - `owner_cap`: Identifier for the owner’s capability.
     - `balance`: Balance of SUI tokens held by the store.
     - `item_count`: Total number of items listed in the store.
   
2. **StoreOwnerCapability**: A capability struct that grants permissions for managing a specific store.
   - Fields:
     - `id`: Unique identifier for the capability.
     - `store`: Identifier for the associated store.

3. **Item**: Represents a product listed for sale within a store.
   - Fields:
     - `id`: Unique identifier for the item.
     - `title`: Title of the item.
     - `description`: A detailed description of the item.
     - `price`: Price per unit of the item.
     - `url`: URL pointing to an image or resource related to the item.
     - `listed`: Boolean indicating whether the item is available for purchase.
     - `category`: Numeric category code for the item.
     - `total_supply`: Total number of units available when the item was first listed.
     - `available`: Current number of units available for sale.

4. **TransactionRating**: Struct to store feedback for a completed transaction.
   - Fields:
     - `id`: Unique identifier for the rating.
     - `store_id`: Identifier of the store being reviewed.
     - `item_id`: Identifier of the item being reviewed.
     - `rating`: Numeric rating between 1-5 for the item.
     - `review`: Text review of the item.
     - `buyer`: Address of the buyer who made the purchase.

### **Events**
1. **StoreCreated**: Triggered when a new store is created.
2. **ItemAdded**: Triggered when a new item is added to a store.
3. **ItemPurchased**: Triggered when an item is successfully purchased.
4. **ItemUnlisted**: Triggered when an item is unlisted from a store.
5. **StoreWithdrawal**: Triggered when funds are withdrawn from a store.
6. **DeliveryInitiated**: Triggered when the delivery process for an item starts.

### **Error Codes**
The module uses error codes to handle invalid operations:
- `ENotShopOwner`: Triggered when a non-owner tries to modify a store or its items.
- `EInvalidWithdrawalAmount`: Triggered when an invalid withdrawal amount is specified.
- `EInvalidQuantity`: Triggered when an invalid quantity is specified for an item operation.
- `EInsufficientPayment`: Triggered when the buyer's payment is insufficient for the specified purchase.
- `EInvalidPrice`: Triggered when an item price is zero or negative.
- `EInvalidSupply`: Triggered when the supply for a new item is zero or less.
- `EItemIsNotListed`: Triggered when attempting to purchase an unlisted item.

### **Core Functions**
1. **`create_store(ctx: &mut TxContext)`**:
   - Creates a new store and assigns the ownership to the caller.
   - Generates a `StoreOwnerCapability` for the caller and emits a `StoreCreated` event.

2. **`add_item(store: &mut Store, owner_cap: &StoreOwnerCapability, title: vector<u8>, description: vector<u8>, url: vector<u8>, price: u64, supply: u64, category: u8, ctx: &mut TxContext)`**:
   - Adds a new item to the specified store, ensuring the caller is the store owner.
   - The item is created with a unique identifier and added to the store's item list.
   - Emits an `ItemAdded` event.

3. **`unlist_item(store: &mut Store, owner_cap: &StoreOwnerCapability, item_id: ID)`**:
   - Unlists an item from the store, marking it as unavailable for purchase.
   - Emits an `ItemUnlisted` event.

4. **`purchase_item(store: &mut Store, item_id: ID, quantity: u64, recipient: address, payment_coin: &mut Coin<SUI>, ctx: &mut TxContext)`**:
   - Facilitates the purchase of a specified quantity of an item, ensuring payment is sufficient.
   - Updates the item’s inventory and transfers the purchased item to the recipient.
   - Emits `ItemPurchased` and potentially `ItemUnlisted` events.

5. **`initiate_delivery(store: &mut Store, item_id: ID, buyer: address, _ctx: &mut TxContext)`**:
   - Initiates the delivery process for a purchased item and emits a `DeliveryInitiated` event.

6. **`confirm_delivery(store: &mut Store, item_id: ID, buyer: address, cap: &mut TreasuryCap<SUI>, ctx: &mut TxContext)`**:
   - Confirms the delivery of an item, updates the store balance, and emits an `ItemPurchased` event.

7. **`withdraw_from_store(store: &mut Store, owner_cap: &StoreOwnerCapability, amount: u64, recipient: address, ctx: &mut TxContext)`**:
   - Allows store owners to withdraw funds from their store’s balance and transfer it to a specified recipient.
   - Emits a `StoreWithdrawal` event.

8. **`rate_transaction(store: &Store, item_id: ID, rating: u8, review: vector<u8>, buyer: address, ctx: &mut TxContext)`**:
   - Allows buyers to rate and review an item they purchased.
   - Creates a `TransactionRating` and transfers it to the buyer.

9. **`refund_purchase(store: &mut Store, item_id: ID, quantity: u64, buyer: address, cap: &mut TreasuryCap<SUI>, ctx: &mut TxContext)`**:
   - Processes a refund for a buyer, updating the store’s inventory and balance.
   - Emits an `ItemPurchased` event indicating the return.

### **Getter Functions**
The module provides getter functions for accessing various attributes of the `Store`, `StoreOwnerCapability`, and `Item` structs, such as retrieving item descriptions, prices, and store balances.

### **Conclusion**
The `Ecommerce_Platform` module offers a robust solution for building decentralized marketplaces on the Sui blockchain. It ensures a secure and transparent process for managing digital stores, conducting purchases, and processing buyer feedback.

For developers, understanding the structure and flow of this module will enable the creation of sophisticated e-commerce solutions on the Sui network.
