address admin {
    module token {
        use aptos_framework::coin;
        use std::signer;
        use std::string;
        use std::option;

        struct Token has key {}

        struct CoinCapabilities<phantom Token> has key {
            mint_capability: coin::MintCapability<Token>,
            burn_capability: coin::BurnCapability<Token>,
            freeze_capability: coin::FreezeCapability<Token>,
        }

        const E_NO_ADMIN: u64 = 0;
        const E_NO_CAPABILITIES: u64 = 1;
        const E_HAS_CAPABILITIES: u64 = 2;

        public entry fun name(): string::String {
            return coin::name<Token>()
        }

        public entry fun symbol(): string::String {
            return coin::symbol<Token>()
        }

        public entry fun decimals(): u8 {
            return coin::decimals<Token>()
        }

        public entry fun balance(account: address): u64{
            return coin::balance<Token>(account)
        }

        public entry fun supply(): u128 {
            let supply_option: option::Option<u128> = coin::supply<Token>();
            let supply: u128 = *option::borrow(&supply_option);
            return supply
        }

        public entry fun initialize(admin: &signer) {
            let (burn_capability, freeze_capability, mint_capability) = coin::initialize<Token>(
                admin,
                string::utf8(b"Fan V4 Token"),
                string::utf8(b"Token"),
                6,
                true,
            );
            assert!(signer::address_of(admin) == @admin, E_NO_ADMIN);
            assert!(!exists<CoinCapabilities<Token>>(@admin), E_HAS_CAPABILITIES);
            move_to<CoinCapabilities<Token>>(
                admin, 
                CoinCapabilities<Token>{
                    mint_capability, 
                    burn_capability, 
                    freeze_capability
                }
            );
            coin::register<Token>(admin);
        }

        public entry fun register(account: &signer) {
            coin::register<Token>(account);
        }

        public entry fun transfer(from: &signer, to: address, amount: u64) {
            coin::transfer<Token>(from, to, amount);
        }

        public entry fun mint(account: &signer, to: address, amount: u64) acquires CoinCapabilities {
            let account_address = signer::address_of(account);
            assert!(account_address == @admin, E_NO_ADMIN);
            assert!(exists<CoinCapabilities<Token>>(account_address), E_NO_CAPABILITIES);
            let mint_capability = &borrow_global<CoinCapabilities<Token>>(account_address).mint_capability;
            let coins = coin::mint<Token>(amount, mint_capability);
            coin::deposit(to, coins)
        }

        public entry fun burn(account: &signer, amount: u64) acquires CoinCapabilities {
            let account_address = signer::address_of(account);
            let burn_capability = &borrow_global<CoinCapabilities<Token>>(account_address).burn_capability;
            coin::burn_from<Token>(account_address, amount, burn_capability);
        }

    }
}