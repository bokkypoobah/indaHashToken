#!/bin/sh

geth attach << EOF | grep "RESULT: " | sed "s/RESULT: //"

loadScript("abi.js");

var tokenContractAddress = "0x5136c98a80811c3f46bdda8b5c4555cfd9f812f0";
var tokenFromBlock = 4513481;

function printTokenContractDetails() {
  console.log("RESULT: tokenContractAddress=" + tokenContractAddress);
  // console.log("RESULT: tokenContractAbi=" + JSON.stringify(tokenContractAbi));
  if (tokenContractAddress != null && tokenContractAbi != null) {
    var contract = eth.contract(tokenContractAbi).at(tokenContractAddress);
    var decimals = contract.decimals();
    console.log("RESULT: token.owner=" + contract.owner());
    console.log("RESULT: token.newOwner=" + contract.newOwner());
    console.log("RESULT: token.name=" + contract.name());
    console.log("RESULT: token.symbol=" + contract.symbol());
    console.log("RESULT: token.decimals=" + decimals);
    console.log("RESULT: token.totalSupply=" + contract.totalSupply().shift(-decimals));

    console.log("RESULT: token.wallet=" + contract.wallet());
    console.log("RESULT: token.adminWallet=" + contract.adminWallet());

    console.log("RESULT: token.DATE_PRESALE_START=" + contract.DATE_PRESALE_START() + " " + new Date(contract.DATE_PRESALE_START() * 1000).toUTCString());
    console.log("RESULT: token.DATE_PRESALE_END=" + contract.DATE_PRESALE_END() + " " + new Date(contract.DATE_PRESALE_END() * 1000).toUTCString());

    console.log("RESULT: token.DATE_ICO_START=" + contract.DATE_ICO_START() + " " + new Date(contract.DATE_ICO_START() * 1000).toUTCString());
    console.log("RESULT: token.DATE_ICO_END=" + contract.DATE_ICO_END() + " " + new Date(contract.DATE_ICO_END() * 1000).toUTCString());

    console.log("RESULT: token.tokensPerEth=" + contract.tokensPerEth());

    console.log("RESULT: token.BONUS_PRESALE=" + contract.BONUS_PRESALE());
    console.log("RESULT: token.BONUS_ICO_WEEK_ONE=" + contract.BONUS_ICO_WEEK_ONE());
    console.log("RESULT: token.BONUS_ICO_WEEK_TWO=" + contract.BONUS_ICO_WEEK_TWO());

    console.log("RESULT: token.TOKEN_SUPPLY_TOTAL=" + contract.TOKEN_SUPPLY_TOTAL().shift(-decimals));
    console.log("RESULT: token.TOKEN_SUPPLY_ICO=" + contract.TOKEN_SUPPLY_ICO().shift(-decimals));
    console.log("RESULT: token.TOKEN_SUPPLY_MKT=" + contract.TOKEN_SUPPLY_MKT().shift(-decimals));
    console.log("RESULT: token.PRESALE_ETH_CAP=" + contract.PRESALE_ETH_CAP().shift(-18));
    console.log("RESULT: token.MIN_FUNDING_GOAL=" + contract.MIN_FUNDING_GOAL().shift(-decimals));

    console.log("RESULT: token.MIN_CONTRIBUTION=" + contract.MIN_CONTRIBUTION().shift(-18));
    console.log("RESULT: token.MAX_CONTRIBUTION=" + contract.MAX_CONTRIBUTION().shift(-18));

    console.log("RESULT: token.COOLDOWN_PERIOD=" + contract.COOLDOWN_PERIOD());
    console.log("RESULT: token.CLAWBACK_PERIOD=" + contract.CLAWBACK_PERIOD());

    console.log("RESULT: token.icoEtherReceived=" + contract.icoEtherReceived().shift(-18));

    console.log("RESULT: token.tokensIssuedTotal=" + contract.tokensIssuedTotal().shift(-decimals));
    console.log("RESULT: token.tokensIssuedIco=" + contract.tokensIssuedIco().shift(-decimals));
    console.log("RESULT: token.tokensIssuedMkt=" + contract.tokensIssuedMkt().shift(-decimals));
    console.log("RESULT: token.tokensClaimedAirdrop=" + contract.tokensClaimedAirdrop().shift(-decimals));
    console.log("RESULT: token.icoThresholdReached=" + contract.icoThresholdReached());
    console.log("RESULT: token.isTransferable=" + contract.isTransferable());

    var latestBlock = eth.blockNumber;
    var i;

    var ownershipTransferProposedEvents = contract.OwnershipTransferProposed({}, { fromBlock: tokenFromBlock, toBlock: latestBlock });
    i = 0;
    ownershipTransferProposedEvents.watch(function (error, result) {
      console.log("RESULT: OwnershipTransferProposed " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    ownershipTransferProposedEvents.stopWatching();

    var ownershipTransferredEvents = contract.OwnershipTransferred({}, { fromBlock: tokenFromBlock, toBlock: latestBlock });
    i = 0;
    ownershipTransferredEvents.watch(function (error, result) {
      console.log("RESULT: OwnershipTransferred " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    ownershipTransferredEvents.stopWatching();

    var walletUpdatedEvents = contract.WalletUpdated({}, { fromBlock: tokenFromBlock, toBlock: latestBlock });
    i = 0;
    walletUpdatedEvents.watch(function (error, result) {
      console.log("RESULT: WalletUpdated " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    walletUpdatedEvents.stopWatching();

    var adminWalletUpdatedEvents = contract.AdminWalletUpdated({}, { fromBlock: tokenFromBlock, toBlock: latestBlock });
    i = 0;
    adminWalletUpdatedEvents.watch(function (error, result) {
      console.log("RESULT: AdminWalletUpdated " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    adminWalletUpdatedEvents.stopWatching();

    var tokensPerEthUpdatedEvents = contract.TokensPerEthUpdated({}, { fromBlock: tokenFromBlock, toBlock: latestBlock });
    i = 0;
    tokensPerEthUpdatedEvents.watch(function (error, result) {
      console.log("RESULT: TokensPerEthUpdated " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    tokensPerEthUpdatedEvents.stopWatching();

    var tokensMintedEvents = contract.TokensMinted({}, { fromBlock: tokenFromBlock, toBlock: latestBlock });
    i = 0;
    tokensMintedEvents.watch(function (error, result) {
      console.log("RESULT: TokensMinted " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    tokensMintedEvents.stopWatching();

    var tokensIssuedEvents = contract.TokensIssued({}, { fromBlock: tokenFromBlock, toBlock: latestBlock });
    i = 0;
    tokensIssuedEvents.watch(function (error, result) {
      console.log("RESULT: TokensIssued " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    tokensIssuedEvents.stopWatching();

    var refundEvents = contract.Refund({}, { fromBlock: tokenFromBlock, toBlock: latestBlock });
    i = 0;
    refundEvents.watch(function (error, result) {
      console.log("RESULT: Refund " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    refundEvents.stopWatching();

    var airdropEvents = contract.Airdrop({}, { fromBlock: tokenFromBlock, toBlock: latestBlock });
    i = 0;
    airdropEvents.watch(function (error, result) {
      console.log("RESULT: Airdrop " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    airdropEvents.stopWatching();

    var approvalEvents = contract.Approval({}, { fromBlock: tokenFromBlock, toBlock: latestBlock });
    i = 0;
    approvalEvents.watch(function (error, result) {
      console.log("RESULT: Approval " + i++ + " #" + result.blockNumber + " _owner=" + result.args._owner + " _spender=" + result.args._spender + " _value=" +
        result.args._value.shift(-decimals));
    });
    approvalEvents.stopWatching();

    var transferEvents = contract.Transfer({}, { fromBlock: tokenFromBlock, toBlock: latestBlock });
    i = 0;
    transferEvents.watch(function (error, result) {
      console.log("RESULT: Transfer " + i++ + " #" + result.blockNumber + ": _from=" + result.args._from + " _to=" + result.args._to +
        " _value=" + result.args._value.shift(-decimals));
    });
    transferEvents.stopWatching();

    tokenFromBlock = latestBlock + 1;
  }  
}

printTokenContractDetails();

EOF
