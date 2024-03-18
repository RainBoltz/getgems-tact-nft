import { toNano, Address, beginCell } from '@ton/core';
import { NftCollectionWrap } from '../wrappers/Nft';
import { NetworkProvider } from '@ton/blueprint';

const { NftCollection } = NftCollectionWrap;

export async function run(provider: NetworkProvider) {
    const addr = provider.sender().address!!;
    const nft = provider.open(await NftCollection.fromInit(0n, beginCell().endCell(), beginCell().endCell(), 0n, addr));

    await nft.send(
        provider.sender(),
        {
            value: toNano('0.05'),
        },
        {
            $$type: 'Deploy',
            queryId: 0n,
        },
    );

    await provider.waitForDeploy(nft.address);

    console.log(`NftCollection deployed at ${nft.address}`);
}
