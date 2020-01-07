pragma solidity ^0.5.8;

import "./Verifier.sol";

contract zkMultisig is Verifier {
  bytes32 public state;
  uint256 public nonce;

  event Deposit(address indexed sender, uint value);
  event StateChange(bytes32 newState);
  event Execution(uint indexed transactionId);

  modifier onlyWallet() {
    require(msg.sender == address(this));
    _;
  }

  constructor(bytes32 _state) public {
    state = _state;
  }

  function changeState(bytes32 _newState) public onlyWallet {
    state = _newState;
    emit StateChange(_newState);
  }

  function transaction(bytes calldata _proof, bytes32 _state, bytes32 _txHash, uint256 _nonce, address _destination, uint _value, bytes calldata _data) external {
    require(_txHash == keccak256(abi.encode(_nonce, _destination, _value, _data)), "Invalid transaction hash");
    require(verifyProof(_proof, [uint256(_state), uint256(_txHash)]), "Invalid transaction proof");
    require(_nonce == nonce);

    nonce++;
    external_call(_destination, _value, _data.length, _data);
  }

  // call has been separated into its own function in order to take advantage
  // of the Solidity's code generator to produce a loop that copies tx.data into memory.
  function external_call(address destination, uint value, uint dataLength, bytes memory data) internal returns (bool) {
    bool result;
    assembly {
      let x := mload(0x40)   // "Allocate" memory for output (0x40 is where "free memory" pointer is stored by convention)
      let d := add(data, 32) // First 32 bytes are the padded length of data, so exclude that
      result := call(
        sub(gas, 34710),   // 34710 is the value that solidity is currently emitting
        // It includes callGas (700) + callVeryLow (3, to pay for SUB) + callValueTransferGas (9000) +
        // callNewAccountGas (25000, in case the destination address does not exist and needs creating)
        destination,
        value,
        d,
        dataLength,        // Size of the input (in bytes) - this is what fixes the padding problem
        x,
        0                  // Output is ignored, therefore the output size is zero
      )
    }
    return result;
  }

  /// @dev Fallback function accepts Ether transactions.
  function() external payable { }
}