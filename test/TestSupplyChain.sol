pragma solidity ^0.5.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/SupplyChain.sol";

contract TestSupplyChain {

    string item = 'books';
    uint price = 1000 wei;
    uint public initialBalance = 1 ether;
    SupplyChain supplyChain = SupplyChain(DeployedAddresses.SupplyChain());

    function beforeEach() public{
        supplyChain = new SupplyChain();   
    }

    // Test for failing conditions in this contracts:
    // https://truffleframework.com/tutorials/testing-for-throws-in-solidity-tests

    //addItem
    function testAddItem() public{
        bool success = supplyChain.addItem(item, price);
        Assert.equal(success, true, "Item added successfully");
    }


    // buyItem
    function testBuyItem() public{
        supplyChain.addItem(item, price);
        supplyChain.buyItem.value(2000)(0);
        (,,, uint xstate,,) = supplyChain.fetchItem(0);
        Assert.equal(xstate, 1, "Should have a Sold state");
    }
    // test for failure if user does not send enough funds
    function testBuyWithInadequateFunds() public{
        supplyChain.addItem(item, price);
        bool success  = true;
        
        (success, ) = address(supplyChain).call.value(500)(abi.encodeWithSelector(supplyChain.buyItem.selector, 0));
        Assert.isFalse(success, "Item was bought with inadequate funds");
    }
    // test for purchasing an item that is not for Sale
    function testBuyNotForSale() public{
        supplyChain.addItem(item, price);
        bool success;

        (success, ) = address(supplyChain).call.value(1000)(abi.encodeWithSelector(supplyChain.buyItem.selector, 10));
        Assert.isFalse(success, "Item which was not for sale was bought");
    }

    // shipItem
    function testShipItem() public{
        supplyChain.addItem(item, price);
        supplyChain.buyItem.value(2000)(0);
        supplyChain.shipItem(0);

        (,,, uint xstate,,) = supplyChain.fetchItem(0);
        Assert.equal(xstate, 2, "Should have a Shipped state");
    }
    // test for calls that are made by not the seller
    function testShipByNonSeller() public{
        supplyChain.addItem(item, price);
        supplyChain.buyItem.value(2000)(0);

        bool success  = true;
        (success, ) = address(supplyChain).delegatecall(abi.encodeWithSelector(supplyChain.shipItem.selector, 0));
        Assert.isFalse(success, "Item was shipped by NonOwner");
    }
    // test for trying to ship an item that is not marked Sold
    function testShipNotForSale() public{
        supplyChain.addItem(item, price);
        supplyChain.buyItem.value(2000)(0);

        bool success  = true;
        (success, ) = address(supplyChain).call(abi.encodeWithSelector(supplyChain.shipItem.selector, 1));
        Assert.isFalse(success, "Item which was NOTFORSALE was shipped");
    }
    // receiveItem
    function testReceiveItem() public{
        supplyChain.addItem(item, price);
        supplyChain.buyItem.value(2000)(0);
        supplyChain.shipItem(0);
        supplyChain.receiveItem(0);

        (,,, uint xstate,,) = supplyChain.fetchItem(0);
        Assert.equal(xstate, 3, "Should have a Recieved state");
    }

    // test calling the function from an address that is not the buyer
    function testRecieveByNonSeller() public{
        supplyChain.addItem(item, price);
        supplyChain.buyItem.value(2000)(0);
        supplyChain.shipItem(0);
        supplyChain.receiveItem(0);

        bool success  = true;
        (success, ) = address(supplyChain).delegatecall(abi.encodeWithSelector(supplyChain.receiveItem.selector, 0));
        Assert.isFalse(success, "Item was received by NonOwner");
    }
    // test calling the function on an item not marked Shipped
    function testRecieveNotForSale() public{
        supplyChain.addItem(item, price);
        supplyChain.buyItem.value(2000)(0);
        supplyChain.shipItem(0);
        supplyChain.receiveItem(0);

        bool success  = true;
        (success, ) = address(supplyChain).call(abi.encodeWithSelector(supplyChain.receiveItem.selector, 1));
        Assert.isFalse(success, "Item NOTFORSALE was received");
    }

    function() payable external{}

}