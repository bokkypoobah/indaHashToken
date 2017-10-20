#!/bin/bash
# ----------------------------------------------------------------------------------------------
# Testing the smart contract
#
# Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2017. The MIT Licence.
# ----------------------------------------------------------------------------------------------

MODE=${1:-test}

GETHATTACHPOINT=`grep ^IPCFILE= settings.txt | sed "s/^.*=//"`
PASSWORD=`grep ^PASSWORD= settings.txt | sed "s/^.*=//"`

SOURCEDIR=`grep ^SOURCEDIR= settings.txt | sed "s/^.*=//"`

CROWDSALESOL=`grep ^CROWDSALESOL= settings.txt | sed "s/^.*=//"`
CROWDSALEJS=`grep ^CROWDSALEJS= settings.txt | sed "s/^.*=//"`

DEPLOYMENTDATA=`grep ^DEPLOYMENTDATA= settings.txt | sed "s/^.*=//"`

INCLUDEJS=`grep ^INCLUDEJS= settings.txt | sed "s/^.*=//"`
TEST1OUTPUT=`grep ^TEST1OUTPUT= settings.txt | sed "s/^.*=//"`
TEST1RESULTS=`grep ^TEST1RESULTS= settings.txt | sed "s/^.*=//"`

CURRENTTIME=`date +%s`
CURRENTTIMES=`date -r $CURRENTTIME -u`

DATE_PRESALE_START=`echo "$CURRENTTIME+90" | bc`
DATE_PRESALE_START_S=`date -r $DATE_PRESALE_START -u`
DATE_PRESALE_END=`echo "$CURRENTTIME+150" | bc`
DATE_PRESALE_END_S=`date -r $DATE_PRESALE_END -u`
DATE_ICO_START=`echo "$CURRENTTIME+210" | bc`
DATE_ICO_START_S=`date -r $DATE_ICO_START -u`
DATE_ICO_END=`echo "$CURRENTTIME+270" | bc`
DATE_ICO_END_S=`date -r $DATE_ICO_END -u`

printf "MODE               = '$MODE'\n" | tee $TEST1OUTPUT
printf "GETHATTACHPOINT    = '$GETHATTACHPOINT'\n" | tee -a $TEST1OUTPUT
printf "PASSWORD           = '$PASSWORD'\n" | tee -a $TEST1OUTPUT
printf "SOURCEDIR          = '$SOURCEDIR'\n" | tee -a $TEST1OUTPUT
printf "CROWDSALESOL       = '$CROWDSALESOL'\n" | tee -a $TEST1OUTPUT
printf "CROWDSALEJS        = '$CROWDSALEJS'\n" | tee -a $TEST1OUTPUT
printf "DEPLOYMENTDATA     = '$DEPLOYMENTDATA'\n" | tee -a $TEST1OUTPUT
printf "INCLUDEJS          = '$INCLUDEJS'\n" | tee -a $TEST1OUTPUT
printf "TEST1OUTPUT        = '$TEST1OUTPUT'\n" | tee -a $TEST1OUTPUT
printf "TEST1RESULTS       = '$TEST1RESULTS'\n" | tee -a $TEST1OUTPUT
printf "CURRENTTIME        = '$CURRENTTIME' '$CURRENTTIMES'\n" | tee -a $TEST1OUTPUT
printf "DATE_PRESALE_START = '$DATE_PRESALE_START' '$DATE_PRESALE_START_S'\n" | tee -a $TEST1OUTPUT
printf "DATE_PRESALE_END   = '$DATE_PRESALE_END' '$DATE_PRESALE_END_S'\n" | tee -a $TEST1OUTPUT
printf "DATE_ICO_START     = '$DATE_ICO_START' '$DATE_ICO_START_S'\n" | tee -a $TEST1OUTPUT
printf "DATE_ICO_END       = '$DATE_ICO_END' '$DATE_ICO_END_S'\n" | tee -a $TEST1OUTPUT

# Make copy of SOL file and modify start and end times ---
# `cp modifiedContracts/SnipCoin.sol .`
`cp $SOURCEDIR/$CROWDSALESOL .`

# --- Modify parameters ---
`perl -pi -e "s/DATE_PRESALE_START \= 1510153200;.*$/DATE_PRESALE_START \= $DATE_PRESALE_START; \/\/ $DATE_PRESALE_START_S/" $CROWDSALESOL`
`perl -pi -e "s/DATE_PRESALE_END   \= 1510758000;.*$/DATE_PRESALE_END   \= $DATE_PRESALE_END; \/\/ $DATE_PRESALE_END_S/" $CROWDSALESOL`
`perl -pi -e "s/DATE_ICO_START \= 1511967600;.*$/DATE_ICO_START \= $DATE_ICO_START; \/\/ $DATE_ICO_START_S/" $CROWDSALESOL`
`perl -pi -e "s/DATE_ICO_END   \= 1513782000;.*$/DATE_ICO_END   \= $DATE_ICO_END; \/\/ $DATE_ICO_END_S/" $CROWDSALESOL`

DIFFS1=`diff $SOURCEDIR/$CROWDSALESOL $CROWDSALESOL`
echo "--- Differences $SOURCEDIR/$CROWDSALESOL $CROWDSALESOL ---" | tee -a $TEST1OUTPUT
echo "$DIFFS1" | tee -a $TEST1OUTPUT

solc_0.4.16 --version | tee -a $TEST1OUTPUT
echo "var tokenOutput=`solc_0.4.16 --optimize --combined-json abi,bin,interface $CROWDSALESOL`;" > $CROWDSALEJS

geth --verbosity 3 attach $GETHATTACHPOINT << EOF | tee -a $TEST1OUTPUT
loadScript("$CROWDSALEJS");
loadScript("functions.js");

var tokenAbi = JSON.parse(tokenOutput.contracts["$CROWDSALESOL:IndaHashToken"].abi);
var tokenBin = "0x" + tokenOutput.contracts["$CROWDSALESOL:IndaHashToken"].bin;

// console.log("DATA: tokenAbi=" + JSON.stringify(tokenAbi));
// console.log("DATA: tokenBin=" + JSON.stringify(tokenBin));

unlockAccounts("$PASSWORD");
printBalances();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var tokenMessage = "Deploy Crowdsale/Token Contract";
// -----------------------------------------------------------------------------
console.log("RESULT: " + tokenMessage);
var tokenContract = web3.eth.contract(tokenAbi);
// console.log(JSON.stringify(tokenContract));
var tokenTx = null;
var tokenAddress = null;

var token = tokenContract.new({from: contractOwnerAccount, data: tokenBin, gas: 6000000},
  function(e, contract) {
    if (!e) {
      if (!contract.address) {
        tokenTx = contract.transactionHash;
      } else {
        tokenAddress = contract.address;
        addAccount(tokenAddress, "Token '" + token.symbol() + "' '" + token.name() + "'");
        addTokenContractAddressAndAbi(tokenAddress, tokenAbi);
        console.log("DATA: tokenAddress=" + tokenAddress);
      }
    }
  }
);

while (txpool.status.pending > 0) {
}

printTxData("tokenAddress=" + tokenAddress, tokenTx);
printBalances();
failIfTxStatusError(tokenTx, tokenMessage);
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var setupMessage = "Setup";
var tokensPerEth = 3300000000;
// -----------------------------------------------------------------------------
console.log("RESULT: " + setupMessage);
var setup1Tx = token.setWallet(wallet, {from: contractOwnerAccount, gas: 400000});
var setup2Tx = token.setAdminWallet(adminWallet, {from: contractOwnerAccount, gas: 400000});
var setup3Tx = token.updateTokensPerEth(tokensPerEth, {from: contractOwnerAccount, gas: 400000});
var setup4Tx = token.mintMarketing(marketing1, "30000000000000", {from: contractOwnerAccount, gas: 400000});
var setup5Tx = token.mintMarketing(marketing2, "50000000000000", {from: contractOwnerAccount, gas: 400000});
while (txpool.status.pending > 0) {
}
printTxData("setup1Tx", setup1Tx);
printTxData("setup2Tx", setup2Tx);
printTxData("setup3Tx", setup3Tx);
printTxData("setup4Tx", setup4Tx);
printTxData("setup5Tx", setup5Tx);
printBalances();
failIfTxStatusError(setup1Tx, setupMessage + " - setWallet(...)");
failIfTxStatusError(setup2Tx, setupMessage + " - setAdminWallet(...)");
failIfTxStatusError(setup3Tx, setupMessage + " - updateTokensPerEth(...)");
failIfTxStatusError(setup3Tx, setupMessage + " - mintMarketing(marketing1)");
failIfTxStatusError(setup3Tx, setupMessage + " - mintMarketing(marketing2)");
printTokenContractDetails();
console.log("RESULT: ");

exit;

// -----------------------------------------------------------------------------
var whitelistMessage = "Whitelist";
// -----------------------------------------------------------------------------
console.log("RESULT: " + whitelistMessage);
var whitelist1Tx = token.addToWhitelist(account3, {from: whitelistWallet, gas: 400000});
var whitelist2Tx = token.addToWhitelist(account4, {from: whitelistWallet, gas: 400000});
var whitelist3Tx = token.removeFromWhitelist(account5, {from: whitelistWallet, gas: 400000});
while (txpool.status.pending > 0) {
}
printTxData("whitelist1Tx", whitelist1Tx);
printTxData("whitelist2Tx", whitelist2Tx);
printTxData("whitelist3Tx", whitelist3Tx);
printBalances();
failIfTxStatusError(whitelist1Tx, whitelistMessage + " - ac3 Whitelist Uncapped");
failIfTxStatusError(whitelist2Tx, whitelistMessage + " - ac4 Whitelist Capped");
failIfTxStatusError(whitelist2Tx, whitelistMessage + " - ac4 Whitelist Capped");
printTokenContractDetails();
console.log("RESULT: ");


exit;


// -----------------------------------------------------------------------------
var sendContribution1Message = "Send Contribution Before Start";
// -----------------------------------------------------------------------------
console.log("RESULT: " + sendContribution1Message);
var sendContribution1Tx = eth.sendTransaction({from: account3, to: tokenAddress, gas: 400000, value: web3.toWei("1", "ether")});
while (txpool.status.pending > 0) {
}
printTxData("sendContribution1Tx", sendContribution1Tx);
printBalances();
passIfGasEqualsGasUsed(sendContribution1Tx, sendContribution1Message + " - ac3 1 ETH - Expecting Failure");
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var openSaleMessage = "Open Sale";
// -----------------------------------------------------------------------------
console.log("RESULT: " + openSaleMessage);
var openSaleTx = token.openOrCloseSale(true, {from: contractOwnerAccount, gas: 400000});
while (txpool.status.pending > 0) {
}
printTxData("openSaleTx", openSaleTx);
printBalances();
failIfGasEqualsGasUsed(openSaleTx, openSaleMessage);
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var sendContribution2Message = "Send Contribution After Start";
// -----------------------------------------------------------------------------
console.log("RESULT: " + sendContribution2Message);
var sendContribution2Tx = eth.sendTransaction({from: account3, to: tokenAddress, gas: 400000, value: web3.toWei("1", "ether")});
while (txpool.status.pending > 0) {
}
printTxData("sendContribution2Tx", sendContribution2Tx);
printBalances();
failIfGasEqualsGasUsed(sendContribution2Tx, sendContribution2Message + " - ac3 1 ETH = 300,000 SNIP");
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var sendContribution3Message = "Send Contribution After Start - Past Cap";
// -----------------------------------------------------------------------------
console.log("RESULT: " + sendContribution3Message);
var sendContribution3_aTx = eth.sendTransaction({from: account3, to: tokenAddress, gas: 400000, value: web3.toWei("100", "ether")});
var sendContribution3_bTx = eth.sendTransaction({from: account4, to: tokenAddress, gas: 400000, value: web3.toWei("100", "ether")});
while (txpool.status.pending > 0) {
}
printTxData("sendContribution3_aTx", sendContribution3_aTx);
printTxData("sendContribution3_bTx", sendContribution3_bTx);
printBalances();
failIfGasEqualsGasUsed(sendContribution3_aTx, sendContribution3Message + " - ac3 100 ETH - 30,000,000");
passIfGasEqualsGasUsed(sendContribution3_bTx, sendContribution3Message + " - ac4 100 ETH - Fail");
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var sendContribution4Message = "Send Contribution After Start - Below Cap";
// -----------------------------------------------------------------------------
console.log("RESULT: " + sendContribution4Message);
var sendContribution4_aTx = eth.sendTransaction({from: account3, to: tokenAddress, gas: 400000, value: web3.toWei("10", "ether")});
var sendContribution4_bTx = eth.sendTransaction({from: account4, to: tokenAddress, gas: 400000, value: web3.toWei("10", "ether")});
while (txpool.status.pending > 0) {
}
printTxData("sendContribution4_aTx", sendContribution4_aTx);
printTxData("sendContribution4_bTx", sendContribution4_bTx);
printBalances();
failIfGasEqualsGasUsed(sendContribution4_aTx, sendContribution4Message + " - ac3 10 ETH - 3,000,000");
failIfGasEqualsGasUsed(sendContribution4_bTx, sendContribution4Message + " - ac4 10 ETH - 3,000,000");
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var closeSaleMessage = "Close Sale";
// -----------------------------------------------------------------------------
console.log("RESULT: " + closeSaleMessage);
var closeSaleTx = token.openOrCloseSale(false, {from: contractOwnerAccount, gas: 400000});
while (txpool.status.pending > 0) {
}
printTxData("closeSaleTx", closeSaleTx);
printBalances();
failIfGasEqualsGasUsed(closeSaleTx, closeSaleMessage);
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var allowTransfersMessage = "Enable Transfers";
// -----------------------------------------------------------------------------
console.log("RESULT: " + allowTransfersMessage);
var allowTransfersTx = token.allowTransfers({from: contractOwnerAccount, gas: 400000});
while (txpool.status.pending > 0) {
}
printTxData("allowTransfersTx", allowTransfersTx);
printBalances();
failIfGasEqualsGasUsed(allowTransfersTx, allowTransfersMessage);
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var moveTokenMessage = "Move Tokens After Transfers Allowed";
// -----------------------------------------------------------------------------
console.log("RESULT: " + moveTokenMessage);
var moveToken1Tx = token.transfer(account5, "100000000000000000", {from: account3, gas: 100000});
var moveToken2Tx = token.approve(account6,  "3000000000000000000", {from: account4, gas: 100000});
while (txpool.status.pending > 0) {
}
var moveToken3Tx = token.transferFrom(account4, account7, "3000000000000000000", {from: account6, gas: 100000});
while (txpool.status.pending > 0) {
}
printTxData("moveToken1Tx", moveToken1Tx);
printTxData("moveToken2Tx", moveToken2Tx);
printTxData("moveToken3Tx", moveToken3Tx);
printBalances();
failIfGasEqualsGasUsed(moveToken1Tx, moveTokenMessage + " - transfer 0.1 SNIP ac3 -> ac5. CHECK for movement");
failIfGasEqualsGasUsed(moveToken2Tx, moveTokenMessage + " - approve 3 SNIP ac4 -> ac6");
failIfGasEqualsGasUsed(moveToken3Tx, moveTokenMessage + " - transferFrom 3 SNIP ac4 -> ac7 by ac6. CHECK for movement");
printTokenContractDetails();
console.log("RESULT: ");


EOF
grep "DATA: " $TEST1OUTPUT | sed "s/DATA: //" > $DEPLOYMENTDATA
cat $DEPLOYMENTDATA
grep "RESULT: " $TEST1OUTPUT | sed "s/RESULT: //" > $TEST1RESULTS
cat $TEST1RESULTS
