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
TEST5OUTPUT=`grep ^TEST5OUTPUT= settings.txt | sed "s/^.*=//"`
TEST5RESULTS=`grep ^TEST5RESULTS= settings.txt | sed "s/^.*=//"`

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

printf "MODE               = '$MODE'\n" | tee $TEST5OUTPUT
printf "GETHATTACHPOINT    = '$GETHATTACHPOINT'\n" | tee -a $TEST5OUTPUT
printf "PASSWORD           = '$PASSWORD'\n" | tee -a $TEST5OUTPUT
printf "SOURCEDIR          = '$SOURCEDIR'\n" | tee -a $TEST5OUTPUT
printf "CROWDSALESOL       = '$CROWDSALESOL'\n" | tee -a $TEST5OUTPUT
printf "CROWDSALEJS        = '$CROWDSALEJS'\n" | tee -a $TEST5OUTPUT
printf "DEPLOYMENTDATA     = '$DEPLOYMENTDATA'\n" | tee -a $TEST5OUTPUT
printf "INCLUDEJS          = '$INCLUDEJS'\n" | tee -a $TEST5OUTPUT
printf "TEST5OUTPUT        = '$TEST5OUTPUT'\n" | tee -a $TEST5OUTPUT
printf "TEST5RESULTS       = '$TEST5RESULTS'\n" | tee -a $TEST5OUTPUT
printf "CURRENTTIME        = '$CURRENTTIME' '$CURRENTTIMES'\n" | tee -a $TEST5OUTPUT
printf "DATE_PRESALE_START = '$DATE_PRESALE_START' '$DATE_PRESALE_START_S'\n" | tee -a $TEST5OUTPUT
printf "DATE_PRESALE_END   = '$DATE_PRESALE_END' '$DATE_PRESALE_END_S'\n" | tee -a $TEST5OUTPUT
printf "DATE_ICO_START     = '$DATE_ICO_START' '$DATE_ICO_START_S'\n" | tee -a $TEST5OUTPUT
printf "DATE_ICO_END       = '$DATE_ICO_END' '$DATE_ICO_END_S'\n" | tee -a $TEST5OUTPUT

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
echo "--- Differences $SOURCEDIR/$CROWDSALESOL $CROWDSALESOL ---" | tee -a $TEST5OUTPUT
echo "$DIFFS1" | tee -a $TEST5OUTPUT

solc_0.4.16 --version | tee -a $TEST5OUTPUT
echo "var tokenOutput=`solc_0.4.16 --optimize --combined-json abi,bin,interface $CROWDSALESOL`;" > $CROWDSALEJS

geth --verbosity 3 attach $GETHATTACHPOINT << EOF | tee -a $TEST5OUTPUT
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
var sendContribution4_1Tx = eth.sendTransaction({from: account7, to: tokenAddress, gas: 400000, value: web3.toWei("39630", "ether")});
while (txpool.status.pending > 0) {
}
printTxData("sendContribution4_1Tx", sendContribution4_1Tx);
printBalances();
failIfTxStatusError(sendContribution4_1Tx, sendContribution4Message + " - ac7 39,630 ETH = 39,630 IDH");
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
// Wait for DATE_ICO_END 
// -----------------------------------------------------------------------------
waitUntil("DATE_ICO_END", token.DATE_ICO_END(), 0);


// -----------------------------------------------------------------------------
var airdropMessage = "Airdrop";
var airdropAddresses = [account4, account5, account6, account7];
// -----------------------------------------------------------------------------
console.log("RESULT: " + airdropMessage);
var airdrop1_1Tx = token.adminClaimAirdropMultiple(airdropAddresses, {from: adminWallet, gas: 400000});
while (txpool.status.pending > 0) {
}
printTxData("airdrop1_1Tx", airdrop1_1Tx);
printBalances();
failIfTxStatusError(airdrop1_1Tx, airdropMessage + " - multiple [ac4, ac5, ac6, ac7] by admin");
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var unlockTokenMessage = "Unlock Tokens";
var removeLockAccounts = [account4, account8, account9, account10];
// -----------------------------------------------------------------------------
console.log("RESULT: " + unlockTokenMessage);
var unlockToken1Tx = token.removeLockMultiple(removeLockAccounts, {from: adminWallet, gas: 100000});
while (txpool.status.pending > 0) {
}
printTxData("unlockToken1Tx", unlockToken1Tx);
printBalances();
failIfTxStatusError(unlockToken1Tx, unlockTokenMessage + " - ac4, ac8, ac9, ac10");
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
// Wait for DATE_ICO_END + COOLDOWN_PERIOD [30 seconds] start
// -----------------------------------------------------------------------------
waitUntil("DATE_ICO_END + COOLDOWN_PERIOD [30 seconds]", token.DATE_ICO_END(), token.COOLDOWN_PERIOD());


// -----------------------------------------------------------------------------
var moveTokenMessage = "Multiple Move Tokens After Transfers Allowed";
var moveTo = [account8, account9, account10];
var moveAmounts = [1100000, 2200000, 3300000];
// -----------------------------------------------------------------------------
console.log("RESULT: " + moveTokenMessage);
var moveToken1Tx = token.transferMultiple(moveTo, moveAmounts, {from: account4, gas: 400000});
while (txpool.status.pending > 0) {
}
printTxData("moveToken1Tx", moveToken1Tx);
printBalances();
failIfTxStatusError(moveToken1Tx, moveTokenMessage + " - multiple moves to [ac8, ac9, ac10]");
printTokenContractDetails();
console.log("RESULT: ");


EOF
grep "DATA: " $TEST5OUTPUT | sed "s/DATA: //" > $DEPLOYMENTDATA
cat $DEPLOYMENTDATA
grep "RESULT: " $TEST5OUTPUT | sed "s/RESULT: //" > $TEST5RESULTS
cat $TEST5RESULTS
