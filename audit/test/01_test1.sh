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

DATE_PRESALE_START=`echo "$CURRENTTIME+120" | bc`
DATE_PRESALE_START_S=`date -r $DATE_PRESALE_START -u`
DATE_PRESALE_END=`echo "$CURRENTTIME+170" | bc`
DATE_PRESALE_END_S=`date -r $DATE_PRESALE_END -u`
DATE_ICO_START=`echo "$CURRENTTIME+180" | bc`
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
`perl -pi -e "s/DATE_ICO_START \+ 7 days/DATE_ICO_START \+ 30 seconds/" $CROWDSALESOL`
`perl -pi -e "s/DATE_ICO_START \+ 14 days/DATE_ICO_START \+ 60 seconds/" $CROWDSALESOL`
`perl -pi -e "s/COOLDOWN_PERIOD \=  2 days/COOLDOWN_PERIOD \=  30 seconds/" $CROWDSALESOL`
`perl -pi -e "s/PRESALE_ETH_CAP \=  10000 ether/PRESALE_ETH_CAP \=  500000 ether/" $CROWDSALESOL`
`perl -pi -e "s/MAX_CONTRIBUTION \= 300 ether/MAX_CONTRIBUTION \= 500000 ether/" $CROWDSALESOL`

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
var tokensPerEth = 1000000000;
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


// -----------------------------------------------------------------------------
// Wait for DATE_PRESALE_START start
// -----------------------------------------------------------------------------
waitUntil("DATE_PRESALE_START", token.DATE_PRESALE_START(), 0);


// -----------------------------------------------------------------------------
var sendContribution1Message = "Send Contribution After DATE_PRESALE_START";
// -----------------------------------------------------------------------------
console.log("RESULT: " + sendContribution1Message);
var sendContribution1Tx = eth.sendTransaction({from: account4, to: tokenAddress, gas: 400000, value: web3.toWei("100", "ether")});
while (txpool.status.pending > 0) {
}
printTxData("sendContribution1Tx", sendContribution1Tx);
printBalances();
failIfTxStatusError(sendContribution1Tx, sendContribution1Message + " - ac4 100 ETH = 140,000 IDH (100 x 1,000 x 140%)");
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
// Wait for DATE_ICO_START start
// -----------------------------------------------------------------------------
waitUntil("DATE_ICO_START", token.DATE_ICO_START(), 0);


// -----------------------------------------------------------------------------
var sendContribution2Message = "Send Contribution After DATE_ICO_START";
// -----------------------------------------------------------------------------
console.log("RESULT: " + sendContribution2Message);
var sendContribution2Tx = eth.sendTransaction({from: account5, to: tokenAddress, gas: 400000, value: web3.toWei("100", "ether")});
while (txpool.status.pending > 0) {
}
printTxData("sendContribution2Tx", sendContribution2Tx);
printBalances();
failIfTxStatusError(sendContribution2Tx, sendContribution2Message + " - ac5 100 ETH = 120,000 IDH (100 x 1,000 x 120%)");
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
// Wait for DATE_ICO_START + 1 Week [30 seconds] start
// -----------------------------------------------------------------------------
waitUntil("DATE_ICO_START + 1 week [30 seconds]", token.DATE_ICO_START(), 30);


// -----------------------------------------------------------------------------
var sendContribution3Message = "Send Contribution After DATE_ICO_START + 1 week [30 seconds]";
// -----------------------------------------------------------------------------
console.log("RESULT: " + sendContribution3Message);
var sendContribution3Tx = eth.sendTransaction({from: account6, to: tokenAddress, gas: 400000, value: web3.toWei("100", "ether")});
while (txpool.status.pending > 0) {
}
printTxData("sendContribution3Tx", sendContribution3Tx);
printBalances();
failIfTxStatusError(sendContribution3Tx, sendContribution3Message + " - ac6 100 ETH = 110,000 IDH (100 x 1,000 x 110%)");
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
// Wait for DATE_ICO_START + 2 Weeks [60 seconds] start
// -----------------------------------------------------------------------------
waitUntil("DATE_ICO_START + 2 weeks [60 seconds]", token.DATE_ICO_START(), 60);


// -----------------------------------------------------------------------------
var sendContribution4Message = "Send Contribution After DATE_ICO_START + 2 weeks [60 seconds]";
// -----------------------------------------------------------------------------
console.log("RESULT: " + sendContribution4Message);
var sendContribution4_1Tx = eth.sendTransaction({from: account7, to: tokenAddress, gas: 400000, value: web3.toWei("100", "ether")});
var sendContribution4_2Tx = eth.sendTransaction({from: account8, to: tokenAddress, gas: 400000, value: web3.toWei("319530", "ether")});
while (txpool.status.pending > 0) {
}
printTxData("sendContribution4_1Tx", sendContribution4_1Tx);
printTxData("sendContribution4_2Tx", sendContribution4_2Tx);
printBalances();
failIfTxStatusError(sendContribution4_1Tx, sendContribution4Message + " - ac7 100 ETH = 100,000 IDH (100 x 1,000)");
failIfTxStatusError(sendContribution4_2Tx, sendContribution4Message + " - ac8 319,530 ETH = 319,530,000 IDH");
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var unlockTokenMessage = "Unlock Tokens";
// -----------------------------------------------------------------------------
console.log("RESULT: " + unlockTokenMessage);
var unlockToken1Tx = token.removeLock(account4, {from: adminWallet, gas: 100000});
var unlockToken2Tx = token.removeLock(account5, {from: adminWallet, gas: 100000});
var unlockToken3Tx = token.removeLock(account6, {from: adminWallet, gas: 100000});
var unlockToken4Tx = token.removeLock(account8, {from: adminWallet, gas: 100000});
while (txpool.status.pending > 0) {
}
printTxData("unlockToken1Tx", unlockToken1Tx);
printTxData("unlockToken2Tx", unlockToken2Tx);
printTxData("unlockToken3Tx", unlockToken3Tx);
printTxData("unlockToken4Tx", unlockToken4Tx);
printBalances();
failIfTxStatusError(unlockToken1Tx, unlockTokenMessage + " - ac4");
failIfTxStatusError(unlockToken2Tx, unlockTokenMessage + " - ac5");
failIfTxStatusError(unlockToken3Tx, unlockTokenMessage + " - ac6");
failIfTxStatusError(unlockToken4Tx, unlockTokenMessage + " - ac8");
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
// Wait for DATE_ICO_END + COOLDOWN_PERIOD [30 seconds] start
// -----------------------------------------------------------------------------
waitUntil("DATE_ICO_END + COOLDOWN_PERIOD [30 seconds]", token.DATE_ICO_END(), token.COOLDOWN_PERIOD());


// -----------------------------------------------------------------------------
var moveTokenMessage = "Move Tokens After Transfers Allowed";
// -----------------------------------------------------------------------------
console.log("RESULT: " + moveTokenMessage);
var moveToken1Tx = token.transfer(account6, "1000000", {from: account4, gas: 100000});
var moveToken2Tx = token.approve(account7,  "30000000", {from: account5, gas: 100000});
while (txpool.status.pending > 0) {
}
var moveToken3Tx = token.transferFrom(account5, account8, "30000000", {from: account7, gas: 100000});
while (txpool.status.pending > 0) {
}
printTxData("moveToken1Tx", moveToken1Tx);
printTxData("moveToken2Tx", moveToken2Tx);
printTxData("moveToken3Tx", moveToken3Tx);
printBalances();
failIfTxStatusError(moveToken1Tx, moveTokenMessage + " - transfer 1 token ac4 -> ac6. CHECK for movement");
failIfTxStatusError(moveToken2Tx, moveTokenMessage + " - approve 3 token ac5 -> ac7");
failIfTxStatusError(moveToken3Tx, moveTokenMessage + " - transferFrom 3 token ac5 -> ac8 by ac7. CHECK for movement");
printTokenContractDetails();
console.log("RESULT: ");


EOF
grep "DATA: " $TEST1OUTPUT | sed "s/DATA: //" > $DEPLOYMENTDATA
cat $DEPLOYMENTDATA
grep "RESULT: " $TEST1OUTPUT | sed "s/RESULT: //" > $TEST1RESULTS
cat $TEST1RESULTS
