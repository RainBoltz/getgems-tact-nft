import { toNano } from '@ton/core';
import { NftCollectionWrap } from '../wrappers/Nft';
import { NetworkProvider } from '@ton/blueprint';
import { beginCell } from '@ton/ton';

export async function run(provider: NetworkProvider) {
    const ui = provider.ui();

    const addr = await ui.inputAddress('Enter the address of the NFT collection');

    const { NftCollection } = NftCollectionWrap;

    const nftItemContentUrl = 'https://d2126epqdbsmq2.cloudfront.net/info';
    const itemIndex = 0n;
    const nftCollection = provider.open(NftCollection.fromAddress(addr));

    await nftCollection.send(
        provider.sender(),
        {
            value: toNano('0.2'),
        },
        {
            $$type: 'NftCollectionDeployNewNft',
            query_id: 0n,
            item_index: itemIndex,
            nft_content: beginCell().storeStringTail(`${nftItemContentUrl}/${itemIndex}`).endCell()
        },
    );
}
