import "@stdlib/deploy";
import "./messages.tact";

const MIN_TONS_FOR_STORAGE: Int = 50000000;

contract Nft {
    index: Int as uint64;
    collection_address: Address;
    owner_address: Address?;
    content: Cell?; // nft item content uri

    init(index: Int, collection_address: Address){
        self.index = index;
        self.collection_address = collection_address;
        self.owner_address = null;
        self.content = null;
    }

    receive(){
        nativeThrow(0xffff);
    }

    receive(msg: Transfer){
        let ctx: Context = context();
        if (ctx.bounced == true) {
            return ;
        }
        let sender_address: Address = ctx.sender;
        nativeThrowUnless(401, sender_address == self.owner_address!!);
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
                    body: Excesses{ query_id: msg.query_id }.toCell()
                }
            );
        }
        self.owner_address = new_owner_address;
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

    // Philip defined custom receiver, hehe :p
    receive(msg: DeployNft){
        let ctx: Context = context();
        let sender_address: Address = ctx.sender;

        nativeThrowUnless(405, self.collection_address == sender_address);
        
        if(self.owner_address == null && self.content == null){
            self.owner_address = msg.owner_address;
            self.content = msg.content;
        }
    }

    receive(msg: Slice){
        throw(0xffff);
    }

    get fun get_nft_data(): NftData {
        if (self.owner_address != null && self.content != null) {
            return
                NftData{
                    init: -1,
                    index: self.index,
                    collection_address: self.collection_address,
                    owner_address: self.owner_address!!,
                    content: self.content!!
                };
        } else {
            return
                NftData{
                    init: 0,
                    index: self.index,
                    collection_address: self.collection_address,
                    owner_address: null,
                    content: null
                };
        }
    }
}

contract NftCollection with Deployable {
    owner: Address;
    next_item_index: Int as uint64;
    content: Cell;
    royalty_params: RoyaltyParams;
    second_owner: Address?;

    init(nextItemIndex: Int, collectionContentUrl: Cell, royaltyPercent: Int, royaltyAddress: Address){
        self.owner = context().sender;
        self.next_item_index = nextItemIndex;
        self.content = collectionContentUrl;
        self.royalty_params = RoyaltyParams{ numerator: royaltyPercent, denominator: 100, destination: royaltyAddress };
    }

    receive(){
        nativeThrow(0xffff);
    }

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
                royalty_params: self.royalty_params
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

    get fun get_collection_data(): NftCollectionData {
        return NftCollectionData{
            next_item_index: self.next_item_index,
            content: self.content,
            owner_address: self.owner
        };
    }

    get fun get_nft_address_by_index(index: Int): Address {
        let stateInit: StateInit = initOf Nft(index, myAddress());
        let nft_address: Address = contractAddress(stateInit);
        return nft_address;
    }

    get fun royalty_params(): RoyaltyParams {
        return self.royalty_params;
    }

    get fun get_second_owner_address(): Address {
        if(self.second_owner != null){
            return self.second_owner!!;
        } else {
            return self.owner;
        }
    }
}
