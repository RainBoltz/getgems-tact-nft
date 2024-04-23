// structs
struct NftData {
    init: Int as uint32;
    index: Int as uint64;
    collection_address: Address;
    owner_address: Address?;
    content: Cell?; // nft item content uri
}
struct NftCollectionData {
    next_item_index: Int as uint64;
    content: Cell;
    owner_address: Address;
}
struct RoyaltyParams {
    numerator: Int as uint16;
    denominator: Int as uint16;
    destination: Address;
}
struct NftContent {
    offchain_tag: Int as uint8;
    common_content: Slice; // Base url for NFT items metadata
    individual_nft_content: Cell; // nft item content uri
}


message(0x5fcc3d14) Transfer {
    query_id: Int as uint64;
    new_owner_address: Address;
    response_destination: Address?;
    custom_payload: Cell?;
    forward_amount: Int as coins;
    forward_payload: Slice as remaining;
}
message(0x0c4f4f90) DeployNft {
    // this is a custom message defined by Philip
    owner_address: Address;
    content: Cell;
    editor_address: Address;
}
message(0x05138d91) OwnershipAssigned {
    query_id: Int as uint64;
    prev_owner: Address;
    forward_payload: Slice as remaining;
}
message(0xd53276db) Excesses {
    query_id: Int as uint64;
}
message(0x2fcb26a2) GetStaticData {
    query_id: Int as uint64;
}
message(0x8b771735) ReportStaticData {
    query_id: Int as uint64;
    index: Int as uint256;
    collection_address: Address;
}
message(0x693d3950) GetRoyaltyParams {
    query_id: Int as uint64;
}
message(0xa8cb00ad) ReportRoyaltyParams {
    query_id: Int as uint64;
    royalty_params: RoyaltyParams;
}

// NFT Collection specified
message(0x00000001) NftCollectionDeployNewNft {
    query_id: Int as uint64;
    item_index: Int as uint64;
    amount: Int as coins;
    nft_content: Cell;
}
message(0x00000002) NftCollectionBatchDeployNewNft {
    query_id: Int as uint64;
    deploy_list: Cell;
    use_next_item_index: Bool?;
}
message(0x00000003) NftCollectionChangeOwner {
    query_id: Int as uint64;
    new_owner: Address;
}
message(0x00000005) NftCollectionReturnBalance {
    query_id: Int as uint64;
}
message(0x00000006) NftCollectionChangeSecondOwner {
    query_id: Int as uint64;
    new_second_owner: Address;
}

//TODO: SBT
message(0xd0c3bfea) RequestOwner {
}
message(0x0dd607e3) OwnerInfo {
}
message(0x04ded148) ProveOwnership {
}
message(0x0524c7ae) OwnershipProof {
}
message(0xc18e86d2) OwnershipProofBounced {
}
message(0x1f04537a) Destroy {
}
message(0x6f89f5e3) Revoke {
}
message(0xd136d3b3) TakeExcess {
}