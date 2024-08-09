// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


contract MultiSig {
    using ECDSA for bytes32;
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;

    /// @notice keccak256("Execute(uint256 id,address[] targets,bytes[] datas,uint256 deadline)")
    bytes32 public constant EXECUTE_TYPEHASH = 0xea2b786765a2a3866619afc64bfb36f8668e4c2afac960ba57000f6a29c79d60;

    bytes32 public immutable DOMAIN_SEPARATOR;

    EnumerableSet.AddressSet private _owners;

    // Record whether ID has been executed
    mapping(uint256 => bool) isExecuted;

    /// @notice Emitted when execute task
    event Executed(uint256 indexed id, address[] targes, bytes[] datas);

    modifier onlyMultiSigOwner() {
        require(_owners.contains(msg.sender), "caller isn't owner");
        _;
    }

    modifier onlySelf() {
        require(msg.sender == address(this), "not owner contract");
        _;
    }

    /**
     * @notice Initialize parameters
     * @param owners_ Add contract owner
     */
    constructor(address[] memory owners_) {
        _addOwner(owners_);
        uint256 chainId;

        assembly {
            chainId := chainid()
        }

        DOMAIN_SEPARATOR = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes("MultiSig")),
            keccak256(bytes("1")),
            chainId,
            address(this)
        ));
    }

    /**
     * @notice Encrypt data for multisig operation
     * @param id Event ID for signature
     * @param targets Array of contract addresses to be called
     * @param datas The method called by the corresponding contract and the abi-encoded array of its parameters
     * @param deadline Valid time for signature
     * @return digest Data encrypted according to the EIP712 specification
     */
    function hashTypeData(uint256 id, address[] memory targets, bytes[] memory datas, uint256 deadline) public view returns (bytes32 digest) {
        bytes32[] memory hashedDatas = new bytes32[](datas.length);
        for(uint i = 0; i < datas.length; i++) {
            hashedDatas[i] = keccak256(datas[i]);
        }

        bytes32 structHash = keccak256(abi.encode(
            EXECUTE_TYPEHASH,
            id,
            keccak256(abi.encodePacked(targets)),
            keccak256(abi.encodePacked(hashedDatas)),
            deadline
        ));
        digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash));
    }

    /**
     * @notice Execute multi-transaction signature
     * @param id Event ID for signature
     * @param targets Array of contract addresses to be called
     * @param datas The method called by the corresponding contract and the abi-encoded array of its parameters
     * @param deadlines array of valid times for signature
     * @param sigs Array of signatures for multiple transactions
     */
    function execute(uint256 id, address[] memory targets, bytes[] memory datas, uint256[] memory deadlines, bytes[] memory sigs) public payable onlyMultiSigOwner {
        require(_validSignature(id, targets, datas, deadlines, sigs), "invalid signatures");

        for(uint256 i = 0; i < targets.length; i++) {
            targets[i].functionCall(datas[i]);
        }
        isExecuted[id] = true;
        emit Executed(id, targets, datas);
    }

    /**
     * @notice Signature validation
     * @param id Event id
     * @param targets Contract address array to be called
     * @param datas Array of ABI encodings of the corresponding contract call method and its parameters
     * @param deadlines Array of valid times for signatures
     * @param sigs Array of signatures for multiple transactions
     * @return bool Result of signature validation
     */
    function _validSignature(uint256 id, address[] memory targets, bytes[] memory datas, uint256[] memory deadlines, bytes[] memory sigs) private view returns (bool) {
        uint256 required = 2;
        require(!isExecuted[id], "tx is executed");
        require(sigs.length >= required, "sig num not enough");
        require(targets.length == datas.length, "INCONSISTENT_PARAMS_LENGTH");
        require(deadlines.length == sigs.length, "INCONSISTENT_PARAMS_LENGTH");

        address[] memory addrs = new address[](sigs.length);
        for(uint i = 0; i < sigs.length; i++) {
            require(deadlines[i] >= block.timestamp, "expired");
            bytes32 digest = hashTypeData(id, targets, datas, deadlines[i]);
            addrs[i] = digest.recover(sigs[i]);
        }
        require(_distinctOwners(addrs), "distinct owners");
        return true;
    }
  
    /**
     * @notice Remove duplicated owner
     * @param addrs owner array
     * @return bool Deduplication result
     */
    function _distinctOwners(address[] memory addrs) private view returns (bool) {
        if (addrs.length > _owners.length()) {
            return false;
        }
        for(uint i = 0; i < addrs.length; i++) {
            if (!_owners.contains(addrs[i])) {
                return false;
            }
            //address should be distinct
            for(uint j = 0; j < i; j++) {
                if (addrs[i] == addrs[j]) {
                    return false;
                }
            }
        }
        return true;
    }

    /**
     * @notice Get owner list
     * @return owners address array
     */
    function getOwners() external view returns (address[] memory owners) {
        uint256 length = _owners.length();
        owners = new address[](length);
        for(uint i = 0; i < length; i++) {
            owners[i] = _owners.at(i);
        }
    }

    /**
     * @notice Add contract owner
     * @param owners array of addresses to be added
     */
    function addOwner(address[] memory owners) external onlySelf {
        _addOwner(owners);
    }

    /**
     * @notice Add contract owner
     * @param owners Address array to be added
     */
    function _addOwner(address[] memory owners) private {
        for(uint256 i = 0; i < owners.length; i++) {
            require(owners[i] != address(0), "Invalid owner address provided");
            _owners.add(owners[i]);
        }
    }

    /**
     * @notice Remove contract owner
     * @param owners array of addresses to be removed
     */
    function removeOwner(address[] memory owners) external onlySelf {
        for(uint256 i = 0; i < owners.length; i++) {
            _owners.remove(owners[i]);
        }
        require(_owners.length() >= 1, "contract at least need one owner");
    }

    function sweepToken(IERC20 token, address receiver, uint256 amount) external onlySelf {
        token.safeTransfer(receiver, amount);
    }

    function sweepETH(address receiver, uint256 amount) external onlySelf {
        payable(receiver).transfer(amount);
    }

    receive() external payable {}
}