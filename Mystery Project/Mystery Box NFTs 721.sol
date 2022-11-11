// contracts/Coinllectibles.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MysteryBoxToken is ERC721Enumerable, Ownable {
    mapping (uint256 => string) private Items;
    string private ContractURI;
    string public TokenURIDefault;

    constructor (string memory name, string memory symbol, string memory tokenURIDefault) ERC721(name, symbol){
        TokenURIDefault = tokenURIDefault;
    }

    
    event createItemsEvent(uint256 nftId, string uri, uint256 itemId , address owner);
    event updateItemsEvent(string uri, uint256 itemId , address owner);
    
    function createItems(uint256[] memory nftIds, address owner) public onlyOwner{
        for(uint256 i = 0; i < nftIds.length; i++){
            uint256 newItemId = totalSupply();
            _safeMint(owner, newItemId);
            
            emit createItemsEvent(nftIds[i], TokenURIDefault, newItemId, owner);
        }
    } 

    function updateItems(uint256[] memory tokenIds, string[] memory tokenURIs) public onlyOwner{
        for(uint256 i = 0; i < tokenIds.length; i++){  
            require(keccak256(abi.encodePacked(Items[i])) == keccak256(abi.encodePacked("")), "Cannot update Token URI");
           
            Items[i] = tokenURIs[i];  
           
            emit updateItemsEvent(Items[i], tokenIds[i], _ownerOf(tokenIds[i]));
        }
    }   
    
    function setApprovalForItems(address to, uint256[] memory tokenIds) public{
        require(tokenIds.length > 0, "The input data is incorrect");
        
        for(uint256 i = 0; i < tokenIds.length; i++){
            require(_isApprovedOrOwner(msg.sender, tokenIds[i]), "You are not owner of item");

            _approve(to, tokenIds[i]);
        }
    }

    function transfers(address[] memory froms, address[] memory tos, uint256[] memory tokenIds) public{
        require(froms.length == tos.length, "The input data is incorrect");
        require(tokenIds.length == tos.length, "The input data is incorrect");

        for(uint256 i = 0; i < froms.length; i++){
            require(_isApprovedOrOwner(msg.sender, tokenIds[i]), "You are not owner of item");

            _transfer(froms[i], tos[i], tokenIds[i]);
        }
    }

    function setContractURI(string memory contractUri) public onlyOwner{
        ContractURI = contractUri;
    }

    function updateTokenURIDefault(string memory tokenURIDefault) public onlyOwner{
        TokenURIDefault = tokenURIDefault;
    }
    

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "No token ID exists");
        if(keccak256(abi.encodePacked(Items[tokenId])) == keccak256(abi.encodePacked("")))
            return TokenURIDefault;
        return Items[tokenId];
    }

    function contractURI() public view returns (string memory) {
        return ContractURI;
    }
}