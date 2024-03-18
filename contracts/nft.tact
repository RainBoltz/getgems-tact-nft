import "@stdlib/deploy";
import "./messages.tact";

const MIN_TONS_FOR_STORAGE: Int = 50000000;

struct NftData {
    is_initialized: Int as uint32;
    index: Int as uint64;
    collection_address: Address;
    owner_address: Address?;
    content: Cell?; // nft item content uri
    editor_address: Address?;
}
struct NftCollectionData {
    next_item_index: Int as uint64;
    content: Cell; // NftCollectionContent
    owner_address: Address;
}
struct RoyaltyParams {
    royalty_factor: Int as uint16;
    royalty_base: Int as uint16;
    royalty_address: Address;
}
struct NftCollectionContent {
    collection_content: Cell; // Base url for NFT collection metadata
    common_content: Cell; // Base url for NFT items metadata
}
struct NftContent {
    offchain_tag: Int as uint8;
    common_content: Cell; // Base url for NFT items metadata
    individual_nft_content: Cell; // nft item content uri
}

contract Nft {
    index: Int as uint64;
    collection_address: Address;
    owner_address: Address?;
    content: Cell?; // nft item content uri
    editor_address: Address?;

    init(index: Int, collection_address: Address){
        self.index = index;
        self.collection_address = collection_address;
    }

    receive(){ /* ignore */ }

    receive(msg: Transfer){
        let ctx: Context = context();
        if (ctx.bounced == true) {
            return ;
        }
        let sender_address: Address = ctx.sender;
        nativeThrowUnless(401, sender_address == self.owner_address);
        let new_owner_address: Address = msg.new_owner_address;

        // TODO: check work chain is same as new_owner_address

        let response_destination: Address? = msg.response_destination;
        let forward_amount: Int = msg.forward_amount;
        let fwd_fee: Int = ctx.readForwardFee() * 3 / 2;
        let rest_amount: Int = (myBalance() - MIN_TONS_FOR_STORAGE);
        if (forward_amount > 0) {
            rest_amount -= (forward_amount + fwd_fee);
        }
        if (response_destination != null) {
            rest_amount -= fwd_fee;
        }
        nativeThrowUnless(402, rest_amount >= 0); // base nft spends fixed amount of gas, will not check for response

        if (forward_amount > 0) {
            send(SendParameters{
                    to: new_owner_address,
                    value: forward_amount,
                    mode: SendPayGasSeparately,
                    bounce: false,
                    body: OwnershipAssigned{
                        query_id: msg.query_id,
                        prev_owner: self.owner_address!!,
                        forward_payload: msg.forward_payload
                    }.toCell()
                }
            );
        }
        if (response_destination != null) {
            // TODO: check work chain is same as response_destination
            send(SendParameters{
                    to: response_destination!!,
                    value: rest_amount,
                    mode: SendPayGasSeparately,
                    bounce: false,
                    body: Excesses{query_id: msg.query_id}.toCell()
                }
            );
        }
        self.owner_address = new_owner_address;
    }

    receive(msg: TransferEditorship){
        let ctx: Context = context();
        if (ctx.bounced == true) {
            return ;
        }
        let sender_address: Address = ctx.sender;
        nativeThrowUnless(401, sender_address == self.editor_address);
        let new_editor_address: Address = msg.new_editor_address;

        // TODO: check work chain is same as new_owner_address

        let response_destination: Address? = msg.response_destination;
        let forward_amount: Int = msg.forward_amount;
        let fwd_fee: Int = ctx.readForwardFee() * 3 / 2;
        let rest_amount: Int = (myBalance() - MIN_TONS_FOR_STORAGE);
        if (forward_amount > 0) {
            rest_amount -= (forward_amount + fwd_fee);
        }
        if (response_destination != null) {
            rest_amount -= fwd_fee;
        }
        nativeThrowUnless(402, rest_amount >= 0); // base nft spends fixed amount of gas, will not check for response

        if (forward_amount > 0) {
            send(SendParameters{
                    to: new_editor_address,
                    value: forward_amount,
                    mode: SendPayGasSeparately,
                    bounce: false,
                    body: EditorshipAssigned{
                        query_id: msg.query_id,
                        prev_editor: self.editor_address!!,
                        forward_payload: msg.forward_payload
                    }.toCell()
                }
            );
        }
        if (response_destination != null) {
            // TODO: check work chain is same as response_destination
            send(SendParameters{
                    to: response_destination!!,
                    value: rest_amount,
                    mode: SendPayGasSeparately,
                    bounce: false,
                    body: Excesses{query_id: msg.query_id}.toCell()
                }
            );
        }
        self.editor_address = new_editor_address;
    }

    receive(msg: GetStaticData){
        let ctx: Context = context();
        if (ctx.bounced == true) {
            return ;
        }
        let sender_address: Address = ctx.sender;
        send(SendParameters{
                to: sender_address,
                value: 0,
                mode: SendRemainingValue,
                bounce: false,
                body: ReportStaticData{
                    query_id: msg.query_id,
                    index: self.index,
                    collection_address: self.collection_address
                }.toCell()
            }
        );
    }

    receive(msg: EditContent){
        let ctx: Context = context();
        if (ctx.bounced == true) {
            return ;
        }
        let sender_address: Address = ctx.sender;
        nativeThrowUnless(410, sender_address == self.editor_address!!);
        self.content = msg.new_content;
    }

    // Philip defined custom receiver, hehe :p
    receive(msg: DeployNft){
        let ctx: Context = context();
        let sender_address: Address = ctx.sender;
        nativeThrowUnless(405, self.collection_address == sender_address);
        if (self.owner_address == null && self.content == null && self.editor_address == null) {
            self.owner_address = msg.owner_address;
            self.content = msg.content;
            self.editor_address = msg.editor_address;
        }
    }

    receive(msg: Slice){
        throw(0xffff);
    }

    get fun get_nft_data(): Cell {
        if (self.owner_address == null && self.content == null && self.editor_address == null) {
            return
                NftData{
                    is_initialized: -1,
                    index: self.index,
                    collection_address: self.collection_address,
                    owner_address: self.owner_address,
                    content: self.content,
                    editor_address: self.editor_address
                }.toCell();
        } else {
            return
                NftData{
                    is_initialized: 0,
                    index: self.index,
                    collection_address: self.collection_address,
                    owner_address: null,
                    content: null,
                    editor_address: null
                }.toCell();
        }
    }

    get fun get_editor(): Address? {
        return self.editor_address;
    }
}

contract NftCollection with Deployable {
    owner: Address;
    next_item_index: Int as uint64;
    content: NftCollectionContent;
    royalty_params: RoyaltyParams;
    second_owner: Address?;

    init(nextItemIndex: Int, collectionContentUrl: Cell, commonContentUrl: Cell, royaltyPercent: Int, royaltyAddress: Address){
        self.owner = context().sender;
        self.next_item_index = nextItemIndex;
        self.content = NftCollectionContent{collection_content: collectionContentUrl, common_content: commonContentUrl};
        self.royalty_params = RoyaltyParams{royalty_factor: royaltyPercent, royalty_base: 100, royalty_address: royaltyAddress};
    }

    receive(){ /* ignore */ }

    receive(msg: GetRoyaltyParams){
        let ctx: Context = context();
        if (ctx.bounced == true) {
            return;
        }

        let sender_address: Address = ctx.sender;
        send(SendParameters{
            to: sender_address,
            value: 0,
            mode: SendRemainingValue,
            bounce: false,
            body: ReportRoyaltyParams{
                query_id: msg.query_id,
                royalty_params: self.royalty_params.toCell()
            }.toCell()
        });
    }

    receive(msg: NftCollectionDeployNewNft){
        let ctx: Context = context();
        if (ctx.bounced == true) {
            return;
        }

        let sender_address: Address = ctx.sender;
        self.isOwner(sender_address);

        nativeThrowUnless(402, msg.item_index <= self.next_item_index);

        self.deployNftItem(msg.item_index, msg.amount, msg.nft_content);

        if(msg.item_index == self.next_item_index){
            self.next_item_index += 1;
        }
    }

    receive(msg: NftCollectionBatchDeployNewNft){
        // TODO: implement
    }

    receive(msg: NftCollectionChangeOwner){
        let ctx: Context = context();
        if (ctx.bounced == true) {
            return;
        }

        let sender_address: Address = ctx.sender;
        nativeThrowUnless(4001, sender_address == self.owner);

        self.owner = msg.new_owner;
        self.second_owner = msg.new_owner;
    }

    receive(msg: NftCollectionChangeContent){
        let ctx: Context = context();
        if (ctx.bounced == true) {
            return;
        }

        let sender_address: Address = ctx.sender;
        self.isOwner(sender_address);

        let slice: Slice = msg.new_content.beginParse();
        self.content = NftCollectionContent{
            collection_content: slice.loadRef(),
            common_content: slice.loadRef()
        };

        slice = msg.new_royalty_params.beginParse();
        self.royalty_params = RoyaltyParams{
            royalty_factor: slice.loadInt(16),
            royalty_base: slice.loadInt(16),
            royalty_address: slice.loadAddress()
        };
    }

    receive(msg: NftCollectionReturnBalance){
        let ctx: Context = context();
        if (ctx.bounced == true) {
            return;
        }

        let sender_address: Address = ctx.sender;
        self.isOwner(sender_address);

        nativeReserve(50000000, 0);

        send(SendParameters{
            to: sender_address,
            value: 0,
            mode: SendRemainingBalance,
            bounce: true,
            body: NftCollectionReturnBalance{
                query_id: msg.query_id
            }.toCell()
        });
    }

    receive(msg: NftCollectionChangeSecondOwner){
        let ctx: Context = context();
        if (ctx.bounced == true) {
            return;
        }

        let sender_address: Address = ctx.sender;
        self.isOwner(sender_address);

        self.second_owner = msg.new_second_owner;
    }

    receive(msg: Slice){
        throw(0xffff);
    }

    fun isOwner(address: Address) {
        nativeThrowUnless(401, self.owner == address || self.second_owner == address);
    }

    fun deployNftItem(itemIndex: Int, amount: Int, nftContent: Cell) {
        let stateInit: StateInit = initOf Nft(self.next_item_index, myAddress());
        let nft_address: Address = contractAddress(stateInit);
        
        send(SendParameters{
            to: nft_address,
            value: ton("0.1"),
            mode: SendPayGasSeparately,
            code: stateInit.code,  
            data: stateInit.data,
            body: DeployNft{
                owner_address: self.owner,
                content: nftContent,
                editor_address: self.owner
            }.toCell()
        });
    }

    get fun get_collection_data(): Cell {
        return NftCollectionData{next_item_index: self.next_item_index, content: self.content.toCell(), owner_address: self.owner}.toCell();
    }

    get fun get_nft_address_by_index(index: Int): Address {
        let stateInit: StateInit = initOf Nft(index, myAddress());
        let nft_address: Address = contractAddress(stateInit);
        return nft_address;
    }

    get fun royalty_params(): Cell {
        return self.royalty_params.toCell();
    }

    get fun get_nft_content(index: Int, individual_nft_content: Cell): Cell {
        return NftContent{offchain_tag: 1, common_content: self.content.common_content, individual_nft_content: individual_nft_content}.toCell();
    }

    get fun get_second_owner_address(): Address {
        if(self.second_owner != null){
            return self.second_owner!!;
        } else {
            return self.owner;
        }
    }
}
