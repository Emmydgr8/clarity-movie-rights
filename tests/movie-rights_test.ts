import {
    Clarinet,
    Tx,
    Chain,
    Account,
    types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

// [Previous test cases remain]

Clarinet.test({
    name: "Ensure contract pause functionality works",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const user1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('movie-rights', 'set-contract-pause', [
                types.bool(true)
            ], deployer.address),
            
            Tx.contractCall('movie-rights', 'register-movie', [
                types.uint(1),
                types.ascii("Test Movie"),
                types.principal(user1.address),
                types.uint(100),
                types.bool(true),
                types.ascii("Action"),
                types.uint(2023)
            ], deployer.address)
        ]);
        
        block.receipts[0].result.expectOk().expectBool(true);
        block.receipts[1].result.expectErr().expectUint(106);
    },
});

// [Additional test cases for new functionality]
