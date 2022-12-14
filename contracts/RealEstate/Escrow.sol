//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;
import "hardhat/console.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

interface IERC721 {
    function transferFrom(
        address _from,
        address _to,
        uint256 id
    ) external;
}

contract Escrow is Initializable {
    address public nftAddress;
    uint256 public nftID;
    uint256 public purchasePrice;
    uint256 public escrowAmount;
    address payable public seller;
    address payable public buyer;
    address public inspector;
    address public lender;

    modifier onlyBuyer() {
        require(msg.sender == buyer, "not called by buyer");
        _;
    }

    modifier onlySeller() {
        require(msg.sender == seller, "not called by seller");
        _;
    }

    modifier onlyInspector() {
        require(msg.sender == inspector, "not called by inspector");
        _;
    }

    modifier onlyWhiteListed() {
        require(
            msg.sender == buyer || msg.sender == seller || msg.sender == lender,
            "not whitelisted"
        );
        _;
    }

    bool public inspectionPassed;
    bool public fundsDeposited;
    mapping(address => bool) public approvals;

    function initialize(
        address _nftAddress,
        uint256 _nftID,
        uint256 _purchasePrice,
        uint256 _escrowAmount,
        address _seller,
        address _buyer,
        address _inspector,
        address _lender
    ) external {
        nftAddress = _nftAddress;
        nftID = _nftID;
        purchasePrice = _purchasePrice;
        escrowAmount = _escrowAmount;
        seller = payable(_seller);
        buyer = payable(_buyer);
        inspector = _inspector;
        lender = _lender;
    }

    // Put Under Contract (only buyer - payable escrow)
    function depositEarnest() external payable onlyBuyer {
        require(msg.value >= escrowAmount, "Insufficient deposit");
        fundsDeposited = true;
    }

    function approveSale() public onlyWhiteListed {
        approvals[msg.sender] = true;
    }

    // Finalize Sale
    // -> Require inspection status (add more items here, like appraisal)
    // -> Require sale to be authorized
    // -> Require funds to be correct amount
    // -> Transfer NFT to buyer
    // -> Transfer Funds to Seller

    function finalizeSale() public payable onlyInspector {
        uint256 balance = address(this).balance;
        require(inspectionPassed, "inspection not passed");
        require(approvals[lender] == true);
        require(approvals[buyer] == true);
        require(approvals[lender] == true);

        require(balance >= purchasePrice);

        // transfer NFT to buyer
        IERC721(nftAddress).transferFrom(address(this), buyer, nftID);
        // transfer funds to seller
        (bool success, ) = payable(seller).call{value: balance}("");
        require(success, "transfer failed");
    }

    function cancelSale() public onlyWhiteListed {
        // Cancel Sale (handle earnest deposit)
        // -> if inspection status is not approved, then refund, otherwise send to seller
        require(fundsDeposited, "funds not deposited");
        if (!inspectionPassed) {
            (bool success, ) = payable(buyer).call{
                value: address(this).balance
            }("");
            require(success);
        } else {
            (bool success, ) = payable(seller).call{
                value: address(this).balance
            }("");
            require(success);
        }
    }

    receive() external payable {}

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function setInspectionStatus(bool status) public onlyInspector {
        inspectionPassed = status;
    }
}
