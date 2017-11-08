// Oct 21 2017
var ethPriceUSD = 310.1470;

// -----------------------------------------------------------------------------
// Accounts
// -----------------------------------------------------------------------------
var accounts = [];
var accountNames = {};

addAccount(eth.accounts[0], "Account #0 - Miner");
addAccount(eth.accounts[1], "Account #1 - Contract Owner");
addAccount(eth.accounts[2], "Account #2 - Wallet");
addAccount(eth.accounts[3], "Account #3 - Admin Wallet");
addAccount(eth.accounts[4], "Account #4");
addAccount(eth.accounts[5], "Account #5");
addAccount(eth.accounts[6], "Account #6");
addAccount(eth.accounts[7], "Account #7");
addAccount(eth.accounts[8], "Account #8");
addAccount(eth.accounts[9], "Account #9");
addAccount(eth.accounts[10], "Account #10");
addAccount(eth.accounts[11], "Account #11 - Marketing 1");
addAccount(eth.accounts[12], "Account #12 - Marketing 2");


var minerAccount = eth.accounts[0];
var contractOwnerAccount = eth.accounts[1];
var wallet = eth.accounts[2];
var adminWallet = eth.accounts[3];
var account4 = eth.accounts[4];
var account5 = eth.accounts[5];
var account6 = eth.accounts[6];
var account7 = eth.accounts[7];
var account8 = eth.accounts[8];
var account9 = eth.accounts[9];
var account10 = eth.accounts[10];
var marketing1 = eth.accounts[11];
var marketing2 = eth.accounts[12];

var baseBlock = eth.blockNumber;

function unlockAccounts(password) {
  for (var i = 0; i < eth.accounts.length; i++) {
    personal.unlockAccount(eth.accounts[i], password, 100000);
  }
}

function addAccount(account, accountName) {
  accounts.push(account);
  accountNames[account] = accountName;
}


// -----------------------------------------------------------------------------
// Token Contract
// -----------------------------------------------------------------------------
var tokenContractAddress = null;
var tokenContractAbi = null;

function addTokenContractAddressAndAbi(address, tokenAbi) {
  tokenContractAddress = address;
  tokenContractAbi = tokenAbi;
}


// -----------------------------------------------------------------------------
// Account ETH and token balances
// -----------------------------------------------------------------------------
function printBalances() {
  var token = tokenContractAddress == null || tokenContractAbi == null ? null : web3.eth.contract(tokenContractAbi).at(tokenContractAddress);
  var decimals = token == null ? 6 : token.decimals();
  var i = 0;
  var totalTokenBalance = new BigNumber(0);
  console.log("RESULT:  # Account                                             EtherBalanceChange              Token Name");
  console.log("RESULT: -- ------------------------------------------ --------------------------- ------------------ ---------------------------");
  accounts.forEach(function(e) {
    var etherBalanceBaseBlock = eth.getBalance(e, baseBlock);
    var etherBalance = web3.fromWei(eth.getBalance(e).minus(etherBalanceBaseBlock), "ether");
    var tokenBalance = token == null ? new BigNumber(0) : token.balanceOf(e).shift(-decimals);
    totalTokenBalance = totalTokenBalance.add(tokenBalance);
    console.log("RESULT: " + pad2(i) + " " + e  + " " + pad(etherBalance) + " " + padToken(tokenBalance, decimals) + " " + accountNames[e]);
    i++;
  });
  console.log("RESULT: -- ------------------------------------------ --------------------------- ------------------ ---------------------------");
  console.log("RESULT:                                                                           " + padToken(totalTokenBalance, decimals) + " Total Token Balances");
  console.log("RESULT: -- ------------------------------------------ --------------------------- ------------------ ---------------------------");
  console.log("RESULT: ");
}

function pad2(s) {
  var o = s.toFixed(0);
  while (o.length < 2) {
    o = " " + o;
  }
  return o;
}

function pad(s) {
  var o = s.toFixed(18);
  while (o.length < 27) {
    o = " " + o;
  }
  return o;
}

function padToken(s, decimals) {
  var o = s.toFixed(decimals);
  var l = parseInt(decimals)+12;
  while (o.length < l) {
    o = " " + o;
  }
  return o;
}


// -----------------------------------------------------------------------------
// Transaction status
// -----------------------------------------------------------------------------
function printTxData(name, txId) {
  var tx = eth.getTransaction(txId);
  var txReceipt = eth.getTransactionReceipt(txId);
  var gasPrice = tx.gasPrice;
  var gasCostETH = tx.gasPrice.mul(txReceipt.gasUsed).div(1e18);
  var gasCostUSD = gasCostETH.mul(ethPriceUSD);
  var block = eth.getBlock(txReceipt.blockNumber);
  console.log("RESULT: " + name + " status=" + txReceipt.status + " gas=" + tx.gas +
      " gasUsed=" + txReceipt.gasUsed + " costETH=" + gasCostETH + " costUSD=" + gasCostUSD +
      " @ ETH/USD=" + ethPriceUSD + " gasPrice=" + gasPrice + " block=" + 
      txReceipt.blockNumber + " txIx=" + tx.transactionIndex + " txId=" + txId +
      " @ " + block.timestamp + " " + new Date(block.timestamp * 1000).toUTCString());
}

function assertEtherBalance(account, expectedBalance) {
  var etherBalance = web3.fromWei(eth.getBalance(account), "ether");
  if (etherBalance == expectedBalance) {
    console.log("RESULT: OK " + account + " has expected balance " + expectedBalance);
  } else {
    console.log("RESULT: FAILURE " + account + " has balance " + etherBalance + " <> expected " + expectedBalance);
  }
}

function failIfTxStatusError(tx, msg) {
  var status = eth.getTransactionReceipt(tx).status;
  if (status == 0) {
    console.log("RESULT: FAIL " + msg);
    return 0;
  } else {
    console.log("RESULT: PASS " + msg);
    return 1;
  }
}

function passIfTxStatusError(tx, msg) {
  var status = eth.getTransactionReceipt(tx).status;
  if (status == 1) {
    console.log("RESULT: FAIL " + msg);
    return 0;
  } else {
    console.log("RESULT: PASS " + msg);
    return 1;
  }
}

function gasEqualsGasUsed(tx) {
  var gas = eth.getTransaction(tx).gas;
  var gasUsed = eth.getTransactionReceipt(tx).gasUsed;
  return (gas == gasUsed);
}

function failIfGasEqualsGasUsed(tx, msg) {
  var gas = eth.getTransaction(tx).gas;
  var gasUsed = eth.getTransactionReceipt(tx).gasUsed;
  if (gas == gasUsed) {
    console.log("RESULT: FAIL " + msg);
    return 0;
  } else {
    console.log("RESULT: PASS " + msg);
    return 1;
  }
}

function passIfGasEqualsGasUsed(tx, msg) {
  var gas = eth.getTransaction(tx).gas;
  var gasUsed = eth.getTransactionReceipt(tx).gasUsed;
  if (gas == gasUsed) {
    console.log("RESULT: PASS " + msg);
    return 1;
  } else {
    console.log("RESULT: FAIL " + msg);
    return 0;
  }
}

function failIfGasEqualsGasUsedOrContractAddressNull(contractAddress, tx, msg) {
  if (contractAddress == null) {
    console.log("RESULT: FAIL " + msg);
    return 0;
  } else {
    var gas = eth.getTransaction(tx).gas;
    var gasUsed = eth.getTransactionReceipt(tx).gasUsed;
    if (gas == gasUsed) {
      console.log("RESULT: FAIL " + msg);
      return 0;
    } else {
      console.log("RESULT: PASS " + msg);
      return 1;
    }
  }
}


//-----------------------------------------------------------------------------
// Wait until some unixTime + additional seconds
//-----------------------------------------------------------------------------
function waitUntil(message, unixTime, addSeconds) {
  var t = parseInt(unixTime) + parseInt(addSeconds) + parseInt(1);
  var time = new Date(t * 1000);
  console.log("RESULT: Waiting until '" + message + "' at " + unixTime + "+" + addSeconds + "s =" + time + " now=" + new Date());
  while ((new Date()).getTime() <= time.getTime()) {
  }
  console.log("RESULT: Waited until '" + message + "' at at " + unixTime + "+" + addSeconds + "s =" + time + " now=" + new Date());
  console.log("RESULT: ");
}


//-----------------------------------------------------------------------------
// Token Contract
//-----------------------------------------------------------------------------
var tokenFromBlock = 0;
function printTokenContractDetails() {
  console.log("RESULT: tokenContractAddress=" + tokenContractAddress);
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

    var lockRemovedEvents = contract.LockRemoved({}, { fromBlock: tokenFromBlock, toBlock: latestBlock });
    i = 0;
    lockRemovedEvents.watch(function (error, result) {
      console.log("RESULT: LockRemoved " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    lockRemovedEvents.stopWatching();

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
