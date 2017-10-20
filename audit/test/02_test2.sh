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
TEST2OUTPUT=`grep ^TEST2OUTPUT= settings.txt | sed "s/^.*=//"`
TEST2RESULTS=`grep ^TEST2RESULTS= settings.txt | sed "s/^.*=//"`

CURRENTTIME=`date +%s`
CURRENTTIMES=`date -r $CURRENTTIME -u`

DATE_PRESALE_START=`echo "$CURRENTTIME+120" | bc`
DATE_PRESALE_START_S=`date -r $DATE_PRESALE_START -u`
DATE_PRESALE_END=`echo "$CURRENTTIME+150" | bc`
DATE_PRESALE_END_S=`date -r $DATE_PRESALE_END -u`
DATE_ICO_START=`echo "$CURRENTTIME+180" | bc`
DATE_ICO_START_S=`date -r $DATE_ICO_START -u`
DATE_ICO_END=`echo "$CURRENTTIME+210" | bc`
DATE_ICO_END_S=`date -r $DATE_ICO_END -u`

printf "MODE               = '$MODE'\n" | tee $TEST2OUTPUT
printf "GETHATTACHPOINT    = '$GETHATTACHPOINT'\n" | tee -a $TEST2OUTPUT
printf "PASSWORD           = '$PASSWORD'\n" | tee -a $TEST2OUTPUT
printf "SOURCEDIR          = '$SOURCEDIR'\n" | tee -a $TEST2OUTPUT
printf "CROWDSALESOL       = '$CROWDSALESOL'\n" | tee -a $TEST2OUTPUT
printf "CROWDSALEJS        = '$CROWDSALEJS'\n" | tee -a $TEST2OUTPUT
printf "DEPLOYMENTDATA     = '$DEPLOYMENTDATA'\n" | tee -a $TEST2OUTPUT
printf "INCLUDEJS          = '$INCLUDEJS'\n" | tee -a $TEST2OUTPUT
printf "TEST2OUTPUT        = '$TEST2OUTPUT'\n" | tee -a $TEST2OUTPUT
printf "TEST2RESULTS       = '$TEST2RESULTS'\n" | tee -a $TEST2OUTPUT
printf "CURRENTTIME        = '$CURRENTTIME' '$CURRENTTIMES'\n" | tee -a $TEST2OUTPUT
printf "DATE_PRESALE_START = '$DATE_PRESALE_START' '$DATE_PRESALE_START_S'\n" | tee -a $TEST2OUTPUT
printf "DATE_PRESALE_END   = '$DATE_PRESALE_END' '$DATE_PRESALE_END_S'\n" | tee -a $TEST2OUTPUT
printf "DATE_ICO_START     = '$DATE_ICO_START' '$DATE_ICO_START_S'\n" | tee -a $TEST2OUTPUT
printf "DATE_ICO_END       = '$DATE_ICO_END' '$DATE_ICO_END_S'\n" | tee -a $TEST2OUTPUT

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
`perl -pi -e "s/CLAWBACK_PERIOD \= 90 days/CLAWBACK_PERIOD \= 60 seconds/" $CROWDSALESOL`

DIFFS1=`diff $SOURCEDIR/$CROWDSALESOL $CROWDSALESOL`
echo "--- Differences $SOURCEDIR/$CROWDSALESOL $CROWDSALESOL ---" | tee -a $TEST2OUTPUT
echo "$DIFFS1" | tee -a $TEST2OUTPUT

solc_0.4.16 --version | tee -a $TEST2OUTPUT
echo "var tokenOutput=`solc_0.4.16 --optimize --combined-json abi,bin,interface $CROWDSALESOL`;" > $CROWDSALEJS

geth --verbosity 3 attach $GETHATTACHPOINT << EOF | tee -a $TEST2OUTPUT
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
// Wait for DATE_ICO_END 
// -----------------------------------------------------------------------------
waitUntil("DATE_ICO_END", token.DATE_ICO_END(), 0);


// -----------------------------------------------------------------------------
var refundTokenMessage = "Withdraw Refund";
// -----------------------------------------------------------------------------
console.log("RESULT: " + refundTokenMessage);
var refundToken1Tx = token.reclaimFunds({from: account4, gas: 100000});
while (txpool.status.pending > 0) {
}
printTxData("refundToken1Tx", refundToken1Tx);
printBalances();
failIfTxStatusError(refundToken1Tx, refundTokenMessage + " - ac4");
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
// Wait for DATE_ICO_END + CLAWBACK_PERIOD [60 seconds]
// -----------------------------------------------------------------------------
waitUntil("DATE_ICO_END + CLAWBACK_PERIOD [60 seconds]", token.DATE_ICO_END(), token.CLAWBACK_PERIOD());


// -----------------------------------------------------------------------------
var ownerClawbackMessage = "Owner Clawback";
// -----------------------------------------------------------------------------
console.log("RESULT: " + ownerClawbackMessage);
var ownerClawback1Tx = token.ownerClawback({from: contractOwnerAccount, gas: 100000});
while (txpool.status.pending > 0) {
}
printTxData("ownerClawback1Tx", ownerClawback1Tx);
printBalances();
failIfTxStatusError(ownerClawback1Tx, ownerClawbackMessage);
printTokenContractDetails();
console.log("RESULT: ");


EOF
grep "DATA: " $TEST2OUTPUT | sed "s/DATA: //" > $DEPLOYMENTDATA
cat $DEPLOYMENTDATA
grep "RESULT: " $TEST2OUTPUT | sed "s/RESULT: //" > $TEST2RESULTS
cat $TEST2RESULTS
