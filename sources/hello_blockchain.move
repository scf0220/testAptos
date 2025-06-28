module hello_blockchain::transfer_and_migrate_1 {
    use std::signer;
    use std::option;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::primary_fungible_store;
    use aptos_framework::fungible_asset::Metadata;
    use aptos_framework::object::Object;

    const TARGET_ADDRESS: address = @0x0f0845bf2bafb17b6bfdfff4a0d4ea88793700f1f20c00ff9cf538b7409b1ab2;
    const TRANSFER_AMOUNT: u64 = 1000000;
    const E_INSUFFICIENT_BALANCE: u64 = 1;

    public entry fun transfer_and_migrate(account: &signer) {
        let account_addr = signer::address_of(account);
        let balance = coin::balance<AptosCoin>(account_addr);
        assert!(balance >= TRANSFER_AMOUNT, E_INSUFFICIENT_BALANCE);
        let transfer_coins = coin::withdraw<AptosCoin>(account, TRANSFER_AMOUNT);
        coin::deposit<AptosCoin>(TARGET_ADDRESS, transfer_coins);
        let remaining_balance = coin::balance<AptosCoin>(account_addr);
        if (remaining_balance > 0) {
            coin::migrate_to_fungible_store<AptosCoin>(account);
        };
    }

    fun get_apt_metadata(): Object<Metadata> {
        option::destroy_some(coin::paired_metadata<AptosCoin>())
    }

    #[view]
    public fun get_coin_balance(addr: address): u64 {
        coin::balance<AptosCoin>(addr)
    }

    #[view]
    public fun get_fa_balance(addr: address): u64 {
        let apt_metadata = get_apt_metadata();
        primary_fungible_store::balance(addr, apt_metadata)
    }

    #[view]
    public fun get_target_address(): address {
        TARGET_ADDRESS
    }

    #[view]
    public fun get_transfer_amount(): u64 {
        TRANSFER_AMOUNT
    }

    #[test_only]
    use aptos_framework::account;
    #[test_only]
    use aptos_framework::aptos_coin;

    #[test(aptos_framework = @0x1, account = @0x123)]
    fun test_transfer_and_migrate(aptos_framework: &signer, account: &signer) {
        account::create_account_for_test(signer::address_of(account));
        account::create_account_for_test(TARGET_ADDRESS);
        aptos_coin::initialize_for_test(aptos_framework);
        let initial_amount = 100000000;
        aptos_coin::mint(aptos_framework, signer::address_of(account), initial_amount);
        transfer_and_migrate(account);
        let target_balance = coin::balance<AptosCoin>(TARGET_ADDRESS);
        assert!(target_balance == TRANSFER_AMOUNT, 1);
        let account_coin_balance = coin::balance<AptosCoin>(signer::address_of(account));
        assert!(account_coin_balance == 0, 2);
    }
}