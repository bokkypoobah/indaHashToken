# indaHash Token Contract Audit

## Summary

[indaHash](https://indahash.com/) intends to run a [crowdsale](https://indahash.com/ico) commencing in Nov 2017.

Bok Consulting Pty Ltd was commissioned to perform an audit on the indaHash's crowdsale and token Ethereum smart contract.

This audit has been conducted on indaHash's source code in commits
[f787eba](https://github.com/indahash/indaHashToken/commit/f787eba86b9f6d0f51aa4d9601e55a3010cfd5a6),
[6183f2b](https://github.com/indahash/indaHashToken/commit/6183f2b02977703fd5bb06a2f28e47b406d6fe21),
[f04260e](https://github.com/indahash/indaHashToken/commit/f04260efe809d55aca72d8441c10ed634e49c5a1),
[b2d1e02](https://github.com/indahash/indaHashToken/commit/b2d1e026b3f742ae7bf420a24851eea69fd942d4),
[1a6ebea](https://github.com/indahash/indaHashToken/commit/1a6ebeaef6605d1a77368b821392e8e7422952bb) and
[55d4922](https://github.com/indahash/indaHashToken/commit/55d49227376138076f07d1187565677ebc723e50).

No potential vulnerabilities have been identified in the crowdsale and token contract.

<br />

### Crowdsale Mainnet Addresses

The crowdsale contract has been deployed to [0x5136C98A80811C3f46bDda8B5c4555CFd9f812F0](https://etherscan.io/address/0x5136C98A80811C3f46bDda8B5c4555CFd9f812F0#code).

The script [scripts/getDeploymentParameters.sh](scripts/getDeploymentParameters.sh) was used to extract the following parameters from the deployed
contract:

    $ ./getDeploymentParameters.sh 
    tokenContractAddress=0x5136c98a80811c3f46bdda8b5c4555cfd9f812f0
    token.owner=0x0aeb979b25b3aba2b36ea33cfce5bca7fd401241
    token.newOwner=0x0aeb979b25b3aba2b36ea33cfce5bca7fd401241
    token.name=indaHash Coin
    token.symbol=IDH
    token.decimals=6
    token.totalSupply=0
    token.wallet=0x60edbfa1aa26dc07da5fb44f6f2a06e2c74dad41
    token.adminWallet=0xde53123a9798f23e69668cc4ce1e8497a8419e52
    token.DATE_PRESALE_START=1510153200 Wed, 08 Nov 2017 15:00:00 UTC
    token.DATE_PRESALE_END=1510758000 Wed, 15 Nov 2017 15:00:00 UTC
    token.DATE_ICO_START=1511967600 Wed, 29 Nov 2017 15:00:00 UTC
    token.DATE_ICO_END=1513782000 Wed, 20 Dec 2017 15:00:00 UTC
    token.tokensPerEth=3200000000
    token.BONUS_PRESALE=40
    token.BONUS_ICO_WEEK_ONE=20
    token.BONUS_ICO_WEEK_TWO=10
    token.TOKEN_SUPPLY_TOTAL=400000000
    token.TOKEN_SUPPLY_ICO=320000000
    token.TOKEN_SUPPLY_MKT=80000000
    token.PRESALE_ETH_CAP=15000
    token.MIN_FUNDING_GOAL=40000000
    token.MIN_CONTRIBUTION=0.5
    token.MAX_CONTRIBUTION=300
    token.COOLDOWN_PERIOD=172800
    token.CLAWBACK_PERIOD=7776000
    token.icoEtherReceived=0
    token.tokensIssuedTotal=0
    token.tokensIssuedIco=0
    token.tokensIssuedMkt=0
    token.tokensClaimedAirdrop=0
    token.icoThresholdReached=false
    token.isTransferable=false
    OwnershipTransferProposed 0 #4513513 {"_from":"0xde53123a9798f23e69668cc4ce1e8497a8419e52","_to":"0x0aeb979b25b3aba2b36ea33cfce5bca7fd401241"}
    OwnershipTransferred 0 #4513534 {"_from":"0xde53123a9798f23e69668cc4ce1e8497a8419e52","_to":"0x0aeb979b25b3aba2b36ea33cfce5bca7fd401241"}
    WalletUpdated 0 #4513517 {"_newWallet":"0x60edbfa1aa26dc07da5fb44f6f2a06e2c74dad41"}

A copy of the verified source code from the deployed contract has been saved to [deployed-contract/IndaHashToken_deployed_at_0x5136c98a80811c3f46bdda8b5c4555cfd9f812f0.sol](deployed-contract/IndaHashToken_deployed_at_0x5136c98a80811c3f46bdda8b5c4555cfd9f812f0.sol).

There were no differences between the deployed contract and the audited contract source code:

    $ diff -w IndaHashToken_deployed_at_0x5136c98a80811c3f46bdda8b5c4555cfd9f812f0.sol ../../contracts/indaHashToken.sol 
    $ 

Update Nov 10 2017 - The minimum funding goal has been reached and the contributed ETH is now flowing directly into the crowdsale wallet at
[0x60edbfa1aa26dc07da5fb44f6f2a06e2c74dad41](https://etherscan.io/address/0x60edbfa1aa26dc07da5fb44f6f2a06e2c74dad41#internaltx).

Token contract explorer - [EtherScan.io](https://etherscan.io/token/0x5136C98A80811C3f46bDda8B5c4555CFd9f812F0) or
[Ethplorer.io](https://ethplorer.io/address/0x5136c98a80811c3f46bdda8b5c4555cfd9f812f0).

<br />

<br />

### Crowdsale Contract

* Contributors sending ethers (ETH) to the crowdsale / token contract will result in tokens being generated for the sender's account
* The crowdsale closes at the specified date, or earlier if the maximum funding goal is reached
* Refunds are available if the minimum funding goal is not reached by the crowdsale end date
* Contributed ETH will accumulate in the crowdsale / token contract until the minimum funding goal is reached, after which all ETH will be
  immediately transferred to the crowdsale wallet 
* If the minimum funding goal is reached, the tokens will be transferable after a cooldown period, after the crowdsale closes

<br />

### Token Contract

The token contract adheres to the recently finalised [ERC20 Token Standard](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md).

Notable features are:

* 0 value transfers are permitted for `transfer(...)` and `transferFrom(...)`
* `approve(...)` does not require a non-0 allowance to be set to 0 before being able to modify the non-0 allowance to a different non-0 allowance
* There is no payload size check on the `transfer(...)` and `transferFrom(...)` functions - this is no longer a recommended feature
* `transfer(...)` and `transferFrom(...)` have checks that `REVERT` if there is an insufficient token balance to transfer (or approved),
  saving the user having to pay the full gas amount allocated for the transaction

<br />

<hr />

## Table Of Contents

* [Summary](#summary)
* [Recommendations](#recommendations)
* [Potential Vulnerabilities](#potential-vulnerabilities)
* [Scope](#scope)
* [Limitations](#limitations)
* [Due Diligence](#due-diligence)
* [Risks](#risks)
* [Testing](#testing)
  * [Test 1 Max Contribution](#test-1-max-contribution)
  * [Test 2 Refunds](#test-2-refunds)
  * [Test 3 Airdrops](#test-3-airdrops)
  * [Test 4 Contribution Limits](#test-4-contribution-limits)
  * [Test 5 Multiple Airdrop](#test-5-multiple-airdrop)
* [Code Review](#code-review)

<br />

<hr />

## Recommendations

* **LOW IMPORTANCE** Consider removing the requirement to set non-0 approval limits to 0 before modifying the limit to a new non-0 limit - see NOTE
  in [ERC20 - `approve(...)`](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md#approve).
  * [x] Removed in [6183f2b](https://github.com/indahash/indaHashToken/commit/6183f2b02977703fd5bb06a2f28e47b406d6fe21)
* **LOW IMPORTANCE** `icoEtherContributedOf(...)` is redundant as the exact same result is provided by the autogenerated getter function
  `icoEtherContributed(...)`
  * [x] Removed in [6183f2b](https://github.com/indahash/indaHashToken/commit/6183f2b02977703fd5bb06a2f28e47b406d6fe21)
* **LOW IMPORTANCE** `icoTokensReceivedOf(...)` is redundant as the exact same result is provided by the autogenerated getter function
  `icoTokensReceived(...)`
  * [x] Removed in [6183f2b](https://github.com/indahash/indaHashToken/commit/6183f2b02977703fd5bb06a2f28e47b406d6fe21)
* **LOW IMPORTANCE** `isRefundClaimed(...)` is redundant as the exact same result is provided by the autogenerated getter function
  `refundClaimed(...)`
  * [x] Removed in [6183f2b](https://github.com/indahash/indaHashToken/commit/6183f2b02977703fd5bb06a2f28e47b406d6fe21)
* **LOW IMPORTANCE** `isAirdropClaimed(...)` is redundant as the exact same result is provided by the autogenerated getter function
  `airdropClaimed(...)`
  * [x] Removed in [6183f2b](https://github.com/indahash/indaHashToken/commit/6183f2b02977703fd5bb06a2f28e47b406d6fe21)
* **LOW IMPORTANCE** *ERC20Token* should implement the functions required under the
  [ERC20 token standard](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md), including `totalSupply()`
  * [x] Moved `totalSupply()` in [6183f2b](https://github.com/indahash/indaHashToken/commit/6183f2b02977703fd5bb06a2f28e47b406d6fe21)

<br />

<hr />

## Potential Vulnerabilities

No potential vulnerabilities have been identified in the crowdsale and token contract.

<br />

<hr />

## Scope

This audit is into the technical aspects of the crowdsale contracts. The primary aim of this audit is to ensure that funds
contributed to these contracts are not easily attacked or stolen by third parties. The secondary aim of this audit is that
ensure the coded algorithms work as expected. This audit does not guarantee that that the code is bugfree, but intends to
highlight any areas of weaknesses.

<br />

<hr />

## Limitations

This audit makes no statements or warranties about the viability of the indaHash's business proposition, the individuals
involved in this business or the regulatory regime for the business model.

<br />

<hr />

## Due Diligence

As always, potential participants in any crowdsale are encouraged to perform their due diligence on the business proposition
before funding any crowdsales.

Potential participants are also encouraged to only send their funds to the official crowdsale Ethereum address, published on
the crowdsale beneficiary's official communication channel.

Scammers have been publishing phishing address in the forums, twitter and other communication channels, and some go as far as
duplicating crowdsale websites. Potential participants should NOT just click on any links received through these messages.
Scammers have also hacked the crowdsale website to replace the crowdsale contract address with their scam address.
 
Potential participants should also confirm that the verified source code on EtherScan.io for the published crowdsale address
matches the audited source code, and that the deployment parameters are correctly set, including the constant parameters.

<br />

<hr />

## Risks

* Contributed ETH will accumulate in the crowdsale contract until the minimum funding goal is reached to support a refund if the minimum
  funding goal is not reached. During this period the accumulated ETH will be a target for hackers, but there are limited vectors to transfer
  funds out from this contract. After the minimum funding goal is reach, the ETH balance from the crowdsale contract and any further ETH
  contributions are immediately transferred to an external crowdsale wallet and this minimises the risk of funds getting stolen or hacked
  from the bespoke crowdsale / token contract

<br />

<hr />

## Testing

### Test 1 Max Contribution

The following functions were tested using the script [test/01_test1.sh](test/01_test1.sh) with the summary results saved
in [test/test1results.txt](test/test1results.txt) and the detailed output saved in [test/test1output.txt](test/test1output.txt):

* [x] Deploy the crowdsale / token contracts
* [x] Set up wallets, change tokens/ETH rate
* [x] `mintMarketing(...)`
* [x] Contribute to the crowdsale contract in different periods
* [x] Complete the successful crowdsale by contributing to the max
* [x] Transfer tokens after cooling off period

<br />

### Test 2 Refunds

The following functions were tested using the script [test/02_test2.sh](test/02_test2.sh) with the summary results saved
in [test/test2results.txt](test/test2results.txt) and the detailed output saved in [test/test2output.txt](test/test2output.txt):

* [x] Deploy the crowdsale / token contracts
* [x] Set up wallets, change tokens/ETH rate
* [x] `mintMarketing(...)`
* [x] Contribute to the crowdsale contract in different periods
* [x] Execute refund withdrawals
* [x] Owner clawback

<br />

### Test 3 Airdrops

The following functions were tested using the script [test/03_test3.sh](test/03_test3.sh) with the summary results saved
in [test/test3results.txt](test/test3results.txt) and the detailed output saved in [test/test3output.txt](test/test3output.txt):

* [x] Deploy the crowdsale / token contracts
* [x] Set up wallets, change tokens/ETH rate
* [x] `mintMarketing(...)`
* [x] Contribute to the crowdsale contract in different periods
* [x] Execute airdrops after crowdsale end

<br />

### Test 4 Contribution Limits

The following functions were tested using the script [test/04_test4.sh](test/04_test4.sh) with the summary results saved
in [test/test4results.txt](test/test4results.txt) and the detailed output saved in [test/test4output.txt](test/test4output.txt):

* [x] Deploy the crowdsale / token contracts
* [x] Set up wallets, change tokens/ETH rate
* [x] `mintMarketing(...)`
* [x] Contribute to the crowdsale contract in different periods and confirm contribution limits

<br />

### Test 5 Multiple Airdrop

The following functions were tested using the script [test/05_test5.sh](test/05_test5.sh) with the summary results saved
in [test/test5results.txt](test/test5results.txt) and the detailed output saved in [test/test5output.txt](test/test5output.txt):

* [x] Deploy the crowdsale / token contracts
* [x] Set up wallets, change tokens/ETH rate
* [x] `mintMarketing(...)`
* [x] Contribute to the crowdsale contract in different periods
* [x] Execute a multiple airdrop after crowdsale end
* [x] Execute a multiple transfer

<br />

<hr />

## Code Review

* [x] [code-review/indaHashToken.md](code-review/indaHashToken.md)
  * [x] contract Owned 
  * [x] contract ERC20Interface 
  * [x] contract ERC20Token is ERC20Interface, Owned 
  * [x] contract IndaHashToken is ERC20Token 

<br />

<br />

(c) BokkyPooBah / Bok Consulting Pty Ltd for indaHash - Nov 10 2017. The MIT Licence.