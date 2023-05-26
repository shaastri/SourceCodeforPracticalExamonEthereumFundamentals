//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract NFTMarketPlace is Ownable {
    address payable public admin;

    struct Listing {
        address nftAddress;
        uint tokenId;
        uint price;
        address seller;
        bool sold;
    }

    uint256 public saleCommissionPercentage;
    mapping(uint => uint) tokenIdToListingId;
    Listing[] listings;

    constructor() {
        admin = payable(msg.sender);
        saleCommissionPercentage = 10;
    }

    function listNFT(address _nftAddress, uint _tokenId, uint _price) external {
        require(_price > 0, "Invalid Value");
        require(msg.sender != address(0), "Zero Address");
        require(IERC721(_nftAddress).ownerOf(_tokenId) == msg.sender, "Only the owner of the NFT can list it");

        IERC721(_nftAddress).transferFrom(msg.sender, address(this), _tokenId);

        listings.push(Listing(_nftAddress, _tokenId, _price, msg.sender, false));
        tokenIdToListingId[_tokenId] = listings.length-1;
    }

    function buyNFT(uint _listingId) external payable {
        require(_listingId < listings.length, "Invalid listingId");

        Listing storage listing = listings[_listingId];

        require(listing.seller != msg.sender, "seller cannot buy his own NFT");
        require(msg.value >= listing.price, "Insufficient funds");
        require(!listing.sold, "Already been Sold Out");
        require(msg.sender != address(0), "Zero Address");

        listing.sold = true;
        uint256 commission = (listing.price * saleCommissionPercentage) / 100;
        admin.transfer(commission);
        payable(listing.seller).transfer(listing.price - commission);
        IERC721(listing.nftAddress).transferFrom(address(this), msg.sender, listing.tokenId);        
    }

    function getListing(uint _listingId) external view returns(Listing memory) {
        return listings[_listingId];
    }

    function withdraw() external onlyOwner {
        uint bal = address(this).balance;
        admin.transfer(bal);
    }
}
