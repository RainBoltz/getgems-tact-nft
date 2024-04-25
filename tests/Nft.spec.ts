import { Blockchain, SandboxContract, TreasuryContract } from '@ton/sandbox';
import { toNano, beginCell } from '@ton/core';
import { NftCollectionWrap } from '../wrappers/Nft';
import '@ton/test-utils';

describe('Nft', () => {
    const { NftCollection } = NftCollectionWrap;
    const nftCollectionContentUrl =
        'https://cloudflare-ipfs.com/ipfs/QmYvP3RsDpBQiNSxueZkgEhqsJA17oJk3vjkMFfN7ZvFTv?filename=collection_meta.json';
    const nftItemContentUrl = 'https://d2126epqdbsmq2.cloudfront.net/info/';

    let blockchain: Blockchain;
    let deployer: SandboxContract<TreasuryContract>;

    // eslint-disable-next-line
    let nftCollection: any;

    beforeEach(async () => {
        blockchain = await Blockchain.create();

        nftCollection = blockchain.openContract(
            await NftCollection.fromInit(
                0n,
                beginCell().storeUint(1, 8).storeStringTail(nftCollectionContentUrl).endCell(),
                beginCell().storeUint(1, 8).storeStringTail(nftItemContentUrl).endCell(),
                0n,
                deployer.address,
            ),
        );

        deployer = await blockchain.treasury('deployer');

        const deployResult = await nftCollection.send(
            deployer.getSender(),
            {
                value: toNano('0.05'),
            },
            {
                $$type: 'Deploy',
                queryId: 0n,
            },
        );

        expect(deployResult.transactions).toHaveTransaction({
            from: deployer.address,
            to: nftCollection.address,
            deploy: true,
            success: true,
        });
    });

    it('should deploy', async () => {
        // the check is done inside beforeEach
        // blockchain and nft are ready to use
    });

    it('should mint item', async () => {
        const itemIndex = 0n;

        const mintResult = await nftCollection.send(
            deployer.getSender(),
            {
                value: toNano('0.15'),
            },
            {
                $$type: 'NftCollectionDeployNewNft',
                query_id: 0n,
                item_index: itemIndex,
                nft_content: beginCell().storeStringTail(`${itemIndex}`).endCell(),
            },
        );

        expect(mintResult.transactions).toHaveTransaction({
            from: deployer.address,
            to: nftCollection.address,
            deploy: false,
            success: true,
        });
    });
});
