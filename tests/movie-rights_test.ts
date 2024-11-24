import {
    Clarinet,
    Tx,
    Chain,
    Account,
    types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Ensure can register new movie",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const user1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('movie-rights', 'register-movie', [
                types.uint(1),
                types.ascii("Test Movie"),
                types.principal(user1.address),
                types.uint(100),
                types.bool(true)
            ], deployer.address)
        ]);
        
        block.receipts[0].result.expectOk().expectBool(true);
    },
});

Clarinet.test({
    name: "Ensure rights can be transferred",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const user1 = accounts.get('wallet_1')!;
        const user2 = accounts.get('wallet_2')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('movie-rights', 'register-movie', [
                types.uint(1),
                types.ascii("Test Movie"),
                types.principal(user1.address),
                types.uint(100),
                types.bool(true)
            ], deployer.address),
            
            Tx.contractCall('movie-rights', 'transfer-rights', [
                types.uint(1),
                types.principal(user2.address)
            ], user1.address)
        ]);
        
        block.receipts[0].result.expectOk().expectBool(true);
        block.receipts[1].result.expectOk().expectBool(true);
    },
});

Clarinet.test({
    name: "Check rights status",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const user1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('movie-rights', 'register-movie', [
                types.uint(1),
                types.ascii("Test Movie"),
                types.principal(user1.address),
                types.uint(100),
                types.bool(true)
            ], deployer.address),
            
            Tx.contractCall('movie-rights', 'are-rights-active', [
                types.uint(1)
            ], deployer.address)
        ]);
        
        block.receipts[1].result.expectOk().expectBool(true);
    },
});
