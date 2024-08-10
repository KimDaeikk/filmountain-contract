// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;
import './utils/TransferHelper.sol';
import './interfaces/IForwarder.sol';
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";


contract WalletSimple is EIP712 {
  event Deposited(address, uint256, bytes);
  // Public fields
  mapping(address => bool) public signers; // The addresses that can co-sign transactions on the wallet

  // Internal fields
  uint256 private constant MAX_SEQUENCE_ID_INCREASE = 10000;
  uint256 constant SEQUENCE_ID_WINDOW_SIZE = 10;
  uint256[SEQUENCE_ID_WINDOW_SIZE] recentSequenceIds;

  // EIP-712 related constants
  string constant SEND_MULTI_SIG_TYPEHASH = "SendMultiSig(address toAddress,uint256 value,bytes data,uint256 expireTime,uint256 sequenceId)";
  bytes32 constant SEND_MULTI_SIG_TYPEHASH_HASH = keccak256(abi.encodePacked(SEND_MULTI_SIG_TYPEHASH));

  string constant BATCH_TYPEHASH = "BatchTransfer(address[] recipients,uint256[] values,uint256 expireTime,uint256 sequenceId)";
  bytes32 constant BATCH_TYPEHASH_HASH = keccak256(abi.encodePacked(BATCH_TYPEHASH));

  string constant TOKEN_TRANSFER_TYPEHASH = "TokenTransfer(address toAddress,uint256 value,address tokenContractAddress,uint256 expireTime,uint256 sequenceId)";
  bytes32 constant TOKEN_TRANSFER_TYPEHASH_HASH = keccak256(abi.encodePacked(TOKEN_TRANSFER_TYPEHASH));

  constructor(address[] memory allowedSigners) EIP712("WalletSimple", "1") {
    require(allowedSigners.length == 4, 'Invalid number of signers');

    for (uint8 i = 0; i < allowedSigners.length; i++) {
      require(allowedSigners[i] != address(0), 'Invalid signer');
      signers[allowedSigners[i]] = true;
    }
  }

  function getNetworkId() internal view virtual returns (string memory) {
    return Strings.toString(block.chainid);
  }

  modifier onlySigner() {
    require(signers[msg.sender], 'Non-signer in onlySigner method');
    _;
  }

  fallback() external payable {
    if (msg.value > 0) {
      // Fire deposited event if we are receiving funds
      emit Deposited(msg.sender, msg.value, msg.data);
    }
  }

  receive() external payable {
    if (msg.value > 0) {
      // Fire deposited event if we are receiving funds
      // message data is always empty for receive. If there is data it is sent to fallback function.
      emit Deposited(msg.sender, msg.value, '');
    }
  }

  function sendMultiSig(
    address toAddress,
    uint256 value,
    bytes calldata data,
    uint256 expireTime,
    uint256 sequenceId,
    bytes calldata signature
  ) external onlySigner {
    bytes32 structHash = keccak256(abi.encode(
        SEND_MULTI_SIG_TYPEHASH_HASH,
        toAddress,
        value,
        keccak256(data),
        expireTime,
        sequenceId
    ));

    bytes32 hash = _hashTypedDataV4(structHash);
    address signer = verifyMultiSig(hash, signature, expireTime, sequenceId);

    // require(signer != msg.sender, "Signers cannot be equal");

    // (bool success, ) = toAddress.call{value: value}(data);
    // require(success, "Call execution failed");
}

  /**
   * Transfer funds in a batch to each of recipients
   * @param recipients The list of recipients to send to
   * @param values The list of values to send to recipients.
   *  The recipient with index i in recipients array will be sent values[i].
   *  Thus, recipients and values must be the same length
   */
  function batchTransfer(
    address[] calldata recipients,
    uint256[] calldata values
  ) private {
    for (uint256 i = 0; i < recipients.length; i++) {
      require(address(this).balance >= values[i], 'Insufficient funds');

      (bool success, ) = recipients[i].call{ value: values[i] }('');
      require(success, 'Call failed');
    }
  }

  /**
   * Execute a multi-signature token transfer from this wallet using 2 signers: one from msg.sender and the other from ecrecover.
   * Sequence IDs are numbers starting from 1. They are used to prevent replay attacks and may not be repeated.
   *
   * @param toAddress the destination address to send an outgoing transaction
   * @param value the amount in tokens to be sent
   * @param tokenContractAddress the address of the erc20 token contract
   * @param expireTime the number of seconds since 1970 for which this transaction is valid
   * @param sequenceId the unique sequence id obtainable from getNextSequenceId
   * @param signature see Data Formats
   */
  function sendMultiSigToken(
    address toAddress,
    uint256 value,
    address tokenContractAddress,
    uint256 expireTime,
    uint256 sequenceId,
    bytes calldata signature
  ) external onlySigner {
      bytes32 operationHash = _hashTypedDataV4(keccak256(abi.encode(
          TOKEN_TRANSFER_TYPEHASH_HASH,
          toAddress,
          value,
          tokenContractAddress,
          expireTime,
          sequenceId
      )));
      verifyMultiSig(operationHash, signature, expireTime, sequenceId);
      TransferHelper.safeTransfer(tokenContractAddress, toAddress, value);
  }

  /**
   * Execute a token flush from one of the forwarder addresses. This transfer needs only a single signature and can be done by any signer
   *
   * @param forwarderAddress the address of the forwarder address to flush the tokens from
   * @param tokenContractAddress the address of the erc20 token contract
   */
  function flushForwarderTokens(
    address payable forwarderAddress,
    address tokenContractAddress
  ) external onlySigner {
    IForwarder forwarder = IForwarder(forwarderAddress);
    forwarder.flushTokens(tokenContractAddress);
  }

  /**
   * Execute a ERC721 token flush from one of the forwarder addresses. This transfer needs only a single signature and can be done by any signer
   *
   * @param forwarderAddress the address of the forwarder address to flush the tokens from
   * @param tokenContractAddress the address of the erc20 token contract
   */
  function flushERC721ForwarderTokens(
    address payable forwarderAddress,
    address tokenContractAddress,
    uint256 tokenId
  ) external onlySigner {
    IForwarder forwarder = IForwarder(forwarderAddress);
    forwarder.flushERC721Token(tokenContractAddress, tokenId);
  }

  /**
   * Execute a ERC1155 batch token flush from one of the forwarder addresses.
   * This transfer needs only a single signature and can be done by any signer.
   *
   * @param forwarderAddress the address of the forwarder address to flush the tokens from
   * @param tokenContractAddress the address of the erc1155 token contract
   */
  function batchFlushERC1155ForwarderTokens(
    address payable forwarderAddress,
    address tokenContractAddress,
    uint256[] calldata tokenIds
  ) external onlySigner {
    IForwarder forwarder = IForwarder(forwarderAddress);
    forwarder.batchFlushERC1155Tokens(tokenContractAddress, tokenIds);
  }

  /**
   * Execute a ERC1155 token flush from one of the forwarder addresses.
   * This transfer needs only a single signature and can be done by any signer.
   *
   * @param forwarderAddress the address of the forwarder address to flush the tokens from
   * @param tokenContractAddress the address of the erc1155 token contract
   * @param tokenId the token id associated with the ERC1155
   */
  function flushERC1155ForwarderTokens(
    address payable forwarderAddress,
    address tokenContractAddress,
    uint256 tokenId
  ) external onlySigner {
    IForwarder forwarder = IForwarder(forwarderAddress);
    forwarder.flushERC1155Tokens(tokenContractAddress, tokenId);
  }

  /**
   * Sets the autoflush 721 parameter on the forwarder.
   *
   * @param forwarderAddress the address of the forwarder to toggle.
   * @param autoFlush whether to autoflush erc721 tokens
   */
  function setAutoFlush721(address forwarderAddress, bool autoFlush)
    external
    onlySigner
  {
    IForwarder forwarder = IForwarder(forwarderAddress);
    forwarder.setAutoFlush721(autoFlush);
  }

  /**
   * Sets the autoflush 721 parameter on the forwarder.
   *
   * @param forwarderAddress the address of the forwarder to toggle.
   * @param autoFlush whether to autoflush erc1155 tokens
   */
  function setAutoFlush1155(address forwarderAddress, bool autoFlush)
    external
    onlySigner
  {
    IForwarder forwarder = IForwarder(forwarderAddress);
    forwarder.setAutoFlush1155(autoFlush);
  }

  function verifyMultiSig(
    bytes32 operationHash,
    bytes calldata signature,
    uint256 expireTime,
    uint256 sequenceId
  ) public returns (address) {
    address otherSigner = ECDSA.recover(operationHash, signature);

    require(expireTime >= block.timestamp, 'Transaction expired');
    tryInsertSequenceId(sequenceId);
    require(signers[otherSigner], 'Invalid signer');
    require(otherSigner != msg.sender, 'Signers cannot be equal');

    return otherSigner;
  }

  function domainSeparatorV4() public view returns (bytes32) {
    return _domainSeparatorV4();
  }

  /**
   * Verify that the sequence id has not been used before and inserts it. Throws if the sequence ID was not accepted.
   * We collect a window of up to 10 recent sequence ids, and allow any sequence id that is not in the window and
   * greater than the minimum element in the window.
   * @param sequenceId to insert into array of stored ids
   */
  function tryInsertSequenceId(uint256 sequenceId) private {
    // Keep a pointer to the lowest value element in the window
    uint256 lowestValueIndex = 0;
    // fetch recentSequenceIds into memory for function context to avoid unnecessary sloads

    uint256[SEQUENCE_ID_WINDOW_SIZE]
      memory _recentSequenceIds = recentSequenceIds;
    for (uint256 i = 0; i < SEQUENCE_ID_WINDOW_SIZE; i++) {
      require(_recentSequenceIds[i] != sequenceId, 'Sequence ID already used');

      if (_recentSequenceIds[i] < _recentSequenceIds[lowestValueIndex]) {
        lowestValueIndex = i;
      }
    }

    // The sequence ID being used is lower than the lowest value in the window
    // so we cannot accept it as it may have been used before
    require(
      sequenceId > _recentSequenceIds[lowestValueIndex],
      'Sequence ID below window'
    );

    // Block sequence IDs which are much higher than the lowest value
    // This prevents people blocking the contract by using very large sequence IDs quickly
    require(
      sequenceId <=
        (_recentSequenceIds[lowestValueIndex] + MAX_SEQUENCE_ID_INCREASE),
      'Sequence ID above maximum'
    );

    recentSequenceIds[lowestValueIndex] = sequenceId;
  }

  /**
   * Gets the next available sequence ID for signing when using executeAndConfirm
   * returns the sequenceId one higher than the highest currently stored
   */
  function getNextSequenceId() external view returns (uint256) {
    uint256 highestSequenceId = 0;
    for (uint256 i = 0; i < SEQUENCE_ID_WINDOW_SIZE; i++) {
      if (recentSequenceIds[i] > highestSequenceId) {
        highestSequenceId = recentSequenceIds[i];
      }
    }
    return highestSequenceId + 1;
  }
}