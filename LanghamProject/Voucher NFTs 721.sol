// contracts/Coinllectibles.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./strings.sol";
contract HotelVoucherToken is ERC721Enumerable, Ownable {
    using strings for *;
    struct Item{
        // Title is Offer name, 
        // Description include of Hotel name, information of Voucher, Condition and Inclusion 
        // Image URL is Image contain of Voucher QRCode  
        string TokenURI;      

        // Room Type Name | Minimum length of stay (nights) | Minimum advance booking (days) | Rate before tax | Applicable Tax | 
        // Sell rate (total) | Cancellation Policy (Hours) | and Other data
        string OtherData; 

        // Status of Voucher
        bool IsActive;

        // Used number
        uint256 Used;

    }

    address[] public ManagerAddress;
    mapping (address => bool) public Manager;
    mapping (uint256 => Item) private Items;

    string private ContractURI;

    constructor (string memory name, string memory symbol) ERC721(name, symbol){}
  
    event createItemsEvent(uint256 nftId, string uri, uint256 itemId, address owner);

    // require
    modifier onlyManager(){
        bool valid = false;
        if(msg.sender == owner()){
            valid = true;
        }          
        else if(Manager[msg.sender]){
            valid = true;
        }        

        require(valid, "You have not permission");
        _;
    }


    // normal function
    function createItems(uint256[] memory nftIds, string[] memory uris, string[] memory otherData, address owner) public onlyOwner{
        for(uint256 i = 0; i < nftIds.length; i++){
            uint256 newItemId = totalSupply();
            _safeMint(owner, newItemId);

            Items[newItemId].TokenURI = uris[i];
            Items[newItemId].OtherData = otherData[i];
            Items[newItemId].Used = 0;
            Items[newItemId].IsActive = true;

            emit createItemsEvent(nftIds[newItemId], Items[newItemId].TokenURI, newItemId, owner);
        }
    } 
  
    function setApprovalForItems(address to, uint256[] memory tokenIds) public{
        require(tokenIds.length > 0, "The input data is incor`rect");
        
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

    
    // View function
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "No token ID exists");

        return Items[tokenId].TokenURI;
    }

    function contractURI() public view returns (string memory) {
        return ContractURI;
    }


    // Process function
    function addManager(address managerAddress) public onlyOwner{
        require(Manager[managerAddress] == false, "The input data is incorrect");
        Manager[managerAddress] = true;
        ManagerAddress.push(managerAddress);
    }

    function dropManager(address managerAddress) public onlyOwner{
        require(Manager[managerAddress] == true, "The input data is incorrect");
        Manager[managerAddress] = false;
    }


    function changeStatus(uint256 tokenId, bool isActive) public onlyManager{
        require(isActive != Items[tokenId].IsActive, "The input data is incorrect");
        
        Items[tokenId].IsActive = isActive;
    }

    function changeUsedNumber(uint256 tokenId, uint256 usedNumber) public onlyManager{
         require(usedNumber != Items[tokenId].Used, "The input data is incorrect");
        
        Items[tokenId].Used = usedNumber;
    } 

    function getItemOfOtherData(uint256 tokenId, uint256 index) public view returns (string memory){
        //0 : Room Type Name
        //1 : Minimum length of stay (nights) 
        //2 : Minimum advance booking (days) 
        //3 : Rate before tax 
        //4 : Applicable Tax 
        //5 : Sell rate (total)
        //6 : Cancellation Policy (Hours)

        string[] memory data = splitOtherData(tokenId);
        return data[index];
    }

    function checkStatus(uint256 tokenId) public view returns (bool){
        return Items[tokenId].IsActive;
    }

    function checkAdvancedBooking(uint256 tokenId, uint256 usageTime) public view returns (bool){
        uint256 secondOfDay = 86400;
        string memory strMinimumAdvancedBooking = getItemOfOtherData(tokenId, 2);
        uint256 minumumAdvancedBooking = st2num(strMinimumAdvancedBooking);

        if(usageTime > (block.timestamp + (secondOfDay * minumumAdvancedBooking))){
            return true;
        }
        return false;
    }

    function checkAllowCancelBooking(uint256 tokenId, uint256 bookingTime) public view returns (bool){
        uint256 secondOfHour = 3600;
        string memory strCancelPolicy = getItemOfOtherData(tokenId, 6);
        uint256 cancelPolicy = st2num(strCancelPolicy);

        if(bookingTime < block.timestamp + (cancelPolicy * secondOfHour)){
            return true;
        }
        return false;
    }

    // Todo: waiting Minimum Logic



    // sp function
    function splitOtherData(uint256 tokenId) private view returns (string[] memory){
        string memory str = Items[tokenId].OtherData;
        strings.slice memory s = str.toSlice();
        strings.slice memory d = "|".toSlice();
        string[] memory value = new string[](s.count(d));
        for (uint i = 0; i < value.length; i++) {
           value[i] = s.split(d).toString();
        }
        return value;
    }


    function st2num(string memory numString) private pure returns(uint) {
        uint  val=0;
        bytes   memory stringBytes = bytes(numString);
        for (uint  i =  0; i<stringBytes.length; i++) {
            uint exp = stringBytes.length - i;
            bytes1 ival = stringBytes[i];
            uint8 uval = uint8(ival);
           uint jval = uval - uint(0x30);
   
           val +=  (uint(jval) * (10**(exp-1))); 
        }
      return val;
    }
}