pragma solidity >=0.8.4;

import "forge-std/Test.sol";

contract AccountFactory is Test {
    // Create users with 10 ether balance
    function createUsers(uint256 userNum)
        internal
        returns (address[] memory)
    {
        address[] memory users = new address[](userNum);

        for (uint256 i = 0; i < userNum; i++) {
            // This will create a new address using `keccak256(i)` as the private key
            address user = vm.addr(uint256(keccak256(abi.encodePacked(i))));
            vm.deal(user, 10 ether);
            users[i] = user;
        }

        return users;
    }

    // Create users with 10 ether balance
    function createUsers(uint256 userNum, uint256 startIndex)
        internal
        returns (address[] memory)
    {
        address[] memory users = new address[](userNum);

        for (uint256 i = startIndex; i < userNum + startIndex; i++) {
            // This will create a new address using `keccak256(i)` as the private key
            address user = vm.addr(uint256(keccak256(abi.encodePacked(i))));
            vm.deal(user, 10 ether);
            users[i - startIndex] = user;
        }

        return users;
    }

    /*function testManyUsers() external {
        address[] memory users = createUsers(3);
        vm.prank(users[0]);
        // do something as users[0];
    }*/
}