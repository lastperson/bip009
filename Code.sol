// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

contract DefineErrors {
    error SubtractionUnderflow(uint a, uint b);

    // If called as sub(1, 2);
    function sub(uint a, uint b) public pure returns(uint) {
        if (a < b) {
            revert SubtractionUnderflow(a, b);
            // Will revert with:
            // SubtractionUnderflow(uint256,uint256).sig
            // 0000000000000000000000000000000000000000000000000000000000000001
            // 0000000000000000000000000000000000000000000000000000000000000002
        }
        return b - a;
    }
}

contract SafeMathByDefault {
    function subThenAdd() public pure returns(uint) {
        return 1 - 2 + 3; // Reverts.
    }

    function addThenSub() public pure returns(uint) {
        return 1 + 3 - 2; // Success.
    }

    function subThenAddUnchecked() public pure returns(uint) {
        unchecked { return 1 - 2 + 3; } // Success.
    }
}

contract PushReturnsReference {
    struct MyStruct {
        uint128 a;
        uint128 b;
    }

    MyStruct[] public list;

    function push() public {
        // list.push(MyStruct(1, 2)); // 41083 gas.
        // list.push() = MyStruct(1, 2); // 41083 gas.
        
        MyStruct storage entry = list.push(); // 40952 gas. Cheaper!
        entry.a = 1;
        entry.b = 2;
    }
}

contract BytesConcat {
    // Assume a call concat(0x1234, 0x5678cafe, 0xc001c001c001);
    function concat(bytes2 a, bytes4 b, bytes memory c) public pure returns(bytes memory) {
        return bytes.concat(a, b, c); // Will return 0x12345678cafec001c001c001.
        // Basically same as abi.encodePacked(a, b, c); but more readable.
    }
}

contract PushPopOnBytes {
    bytes public b = hex'12345678';

    // Assume a call push(0xff);
    function push(bytes1 a) public {
        b.push(a); // b == 0x12345678ff
        b.push(a); // b == 0x12345678ffff
    }

    function pop() public {
        b.pop(); // b == 0x123456
        b.pop(); // b == 0x1234
        b.pop(); // b == 0x12
    }
}

interface IPushPopOnBytes {
    function push(bytes1 a) external;
    function pop() external;
}

contract TypeOnContract {
    function name() public pure returns(string memory) {
        return type(PushPopOnBytes).name; // Returns "PushPopOnBytes"
    }

    function creationCode() public pure returns(bytes memory) {
        return type(PushPopOnBytes).creationCode; // Returns plenty of bytes.
    }

    function runtimeCode() public pure returns(bytes memory) {
        return type(PushPopOnBytes).runtimeCode; // Returns plenty of bytes.
    }

    function interfaceId() public pure returns(bytes4) {
        return type(IPushPopOnBytes).interfaceId; // Returns EIP-165 interface Id like 0xca2234fe.
    }
}

contract CreateWithSalt {
    function create2() public returns(PushPopOnBytes) {
        // Deterministic address deploy.
        return new PushPopOnBytes{salt: 'bip001'}();
    }
}

contract CheapEvents {
    event Note(uint a, uint b) anonymous;
    event Note(uint a, uint b, uint c) anonymous;
    // 375 * topics + 375 * 32 bytes data.
    
    // 1 topic + 64 bytes data 375*3 + 375
    
    // 0 topics + 64 bytes data 375*2 + 375

    function note() public {
        emit Note(1, 2); // Costs 1072 gas vs 1453 gas with named event.
    }
}

contract BoolIsBig {
    uint248 a;
    bool b; // End of slot 0

    bool c; // Start of slot 1

    // Will take 40952 gas cause 2 SSTORE.
    function store() public {
        a = 1;
        b = true;
        c = true;
    }
}

function outsideOfContract(uint a, uint b) pure returns(uint) {
    return a + b;
}

enum OutsideOfContract {
    A, B, C
}

struct AlsoOutsideOfContract {
    uint a;
    uint b;
}

contract ShortCircuit {
    function short() public pure returns(bool) {
        return success() || fail(); // Returns true.
    }

    function success() public pure returns(bool) {
        return true;
    }

    function fail() public pure returns(bool) {
        revert('Fail');
    }
}


contract MinMax {
    uint constant public TOTAL_SUPPLY = type(uint).max;
    int constant public SMALLEST_NEGATIVE = type(int).min;

    function fail() public pure returns(int) {
        return -SMALLEST_NEGATIVE; // Reverts.
    }
}


contract AbiDecode {
    // If called with
    // 00000000000000000000000000000000000000000000000000000001
    // 00000000000000000000000000000000000000000000000000000002
    function customAction(bytes memory input) public pure returns(uint, uint) {
        (uint a, uint b) = abi.decode(input, (uint, uint));
        return (a, b); // returns (1, 2);
    }

    // If called with
    // 00000000000000000000000000000000000000000000000000000001
    // 00000000000000000000000000000000000000000000000000000002
    function decodePart(bytes calldata input) external pure returns(uint) {
        uint b = abi.decode(input[32:], (uint));
        return b; // returns 2;
    }
}

contract BytesToBytesXX {
    // If called with
    // 12345678000000000000000000000000000000000000000000000000
    function bytesToBytesXX(bytes calldata input) external pure returns(bool) {
        bytes4 oldStyle = bytes4(abi.decode(input[0:32], (bytes32)));
        bytes4 newStyle = bytes4(input[0:4]); // 0x12345678
        
        return oldStyle == newStyle; // returns true;
    }
}

contract ReadabilityImprovement {
    uint constant public TEN_BILLIONS = 10_000_000_000;

    function someText() public pure returns(string memory) {
        return "Here is a very long string, and I want to respect 80 col bounds"
            " so I continue here without concat syntax.";
    }

    function unicodeAlsoPossible() public pure returns(string memory) {
        return unicode"💎"
            unicode"⛽";
    }

    function hexAlsoPossible() public pure returns(bytes memory) {
        return
            hex"0000000000000000000000000000000000000000000000000000000012345678"
            hex"cafecafe000000000000000000000000000000000000000000000000cafecafe";
    }
}


contract ImmutablesAccessInConstructor {
    uint immutable public CAP;
    uint public totalSupply;
    mapping(address => uint) public balances;

    constructor (uint cap, uint initialSupply) {
        CAP = cap;
        mint(msg.sender, initialSupply);
    }

    function mint(address to, uint amount) public {
        // require(totalSupply + amount <= CAP, 'CAP reached');
        totalSupply += amount;
        balances[to] += amount;
    }
}

contract ImmutablesAccessInConstructorFixed {
    uint immutable public CAP;
    uint public totalSupply;
    mapping(address => uint) public balances;

    constructor (uint cap) {
        CAP = cap;
    }

    function mint(address to, uint amount) public {
        require(totalSupply + amount <= CAP, 'CAP reached');
        totalSupply += amount;
        balances[to] += amount;
    }
}

contract Deployer {
    constructor (uint cap, uint initialSupply) {
        ImmutablesAccessInConstructorFixed f = new ImmutablesAccessInConstructorFixed(cap);
        f.mint(msg.sender, initialSupply);
    }
}


contract PassingExternalFunctions {
    function callMeBack(
        uint input,
        function (uint) external returns(bool) callback
    ) public returns(bool) {
        return callback(input + 1); // Returns true.
    }
}

contract Caller {
    uint public callbackValue; // Will be set to 11 after callIt().

    function callIt(PassingExternalFunctions target) public returns(bool) {
        return target.callMeBack(10, this.callback);
    }

    function callback(uint input) public returns(bool) {
        callbackValue = input;
        return true;
    }
}
