//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BasicNFTContract is ERC721, Ownable {
    uint256 public minPrice = 0.05 ether;
    uint256 public totalSupply;
    uint256 public maxSupply;
    bool public isMintEnabled;
    mapping(address => uint256) public mintedWallets;

    constructor() payable ERC721('Jetking NFT', 'JET') {
        maxSupply = 2;
    }

    function toggleIsMintEnabled() external onlyOwner {
        isMintEnabled = !isMintEnabled;
    }

    function setMaxSupply(uint256 _maxsupply) external onlyOwner {
        maxSupply = _maxsupply;
    }

    function mint() external payable {
        require(isMintEnabled, 'Minting not enabled');
        require(msg.value == minPrice, 'Wrong Price');
        require(mintedWallets[msg.sender] < 1,'exceed max per wallet');
        require(maxSupply > totalSupply, 'Sold out');

        mintedWallets[msg.sender]++;
        totalSupply++;
        uint tokenID = totalSupply;
        _safeMint(msg.sender,tokenID);
    }
}
