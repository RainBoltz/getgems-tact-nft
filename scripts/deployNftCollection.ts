import { toNano } from '@ton/core';
import { NftCollectionWrap } from '../wrappers/Nft';
import { NetworkProvider } from '@ton/blueprint';
import { beginCell } from '@ton/ton';

export async function run(provider: NetworkProvider) {
    const addr = provider.sender().address!!;

    const { NftCollection } = NftCollectionWrap;

    const nftCollectionContentUrl =
        'https://cloudflare-ipfs.com/ipfs/QmYvP3RsDpBQiNSxueZkgEhqsJA17oJk3vjkMFfN7ZvFTv?filename=collection_meta.json';
    const nftItemContentUrl = 'https://d2126epqdbsmq2.cloudfront.net/info/';
    const nftCollection = provider.open(
        await NftCollection.fromInit(
            0n,
            beginCell().storeUint(1, 8).storeStringTail(nftCollectionContentUrl).endCell(),
            beginCell().storeUint(1, 8).storeStringTail(nftItemContentUrl).endCell(),
            0n,
            addr,
        ),
    );

    await nftCollection.send(
        provider.sender(),
        {
            value: toNano('0.05'),
        },
        {
            $$type: 'Deploy',
            queryId: 0n,
        },
    );

    await provider.waitForDeploy(nftCollection.address);

    // run methods on `nft`
}
