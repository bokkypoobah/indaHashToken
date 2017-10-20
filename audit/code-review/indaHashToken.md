# indaHashToken

Source file [../../contracts/indaHashToken.sol](../../contracts/indaHashToken.sol).

<br />

<hr />

```javascript
// BK Ok
pragma solidity ^0.4.16;

// ----------------------------------------------------------------------------
//
// IDH indaHash token public sale contract
//
// For details, please visit: https://indahash.com/ico
//
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
//
// SafeMath3
//
// Adapted from https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/math/SafeMath.sol
// (no need to implement division)
//
// ----------------------------------------------------------------------------

// BK Ok
library SafeMath3 {

  // BK Ok
  function mul(uint a, uint b) internal constant 
    returns (uint c)
  {
    // BK Ok
    c = a * b;
    // BK Ok
    assert( a == 0 || c / a == b );
  }

  // BK Ok
  function sub(uint a, uint b) internal constant
    returns (uint)
  {
    // BK Ok
    assert( b <= a );
    // BK Ok
    return a - b;
  }

  // BK Ok
  function add(uint a, uint b) internal constant
    returns (uint c)
  {
    // BK Ok
    c = a + b;
    // BK Ok
    assert( c >= a );
  }

}


// ----------------------------------------------------------------------------
//
// Owned contract
//
// ----------------------------------------------------------------------------

// BK Ok
contract Owned {

  // BK Next 2 Ok
  address public owner;
  address public newOwner;

  // Events ---------------------------

  // BK Ok - Event
  event OwnershipTransferProposed(
    address indexed _from,
    address indexed _to
  );

  // BK Ok - Event
  event OwnershipTransferred(
    address indexed _from,
    address indexed _to
  );

  // Modifier -------------------------

  // BK Ok
  modifier onlyOwner
  {
    // BK Ok
    require( msg.sender == owner );
    // BK Ok
    _;
  }

  // Functions ------------------------

  // BK Ok - Constructor
  function Owned()
  {
    // BK Ok
    owner = msg.sender;
  }

  // BK Ok - Only owner can execute
  function transferOwnership(address _newOwner) onlyOwner
  {
    // BK Ok
    require( _newOwner != owner );
    // BK Ok
    require( _newOwner != address(0x0) );
    // BK Ok - Log event
    OwnershipTransferProposed(owner, _newOwner);
    // BK Ok
    newOwner = _newOwner;
  }

  // BK Ok - Only new owner can execute
  function acceptOwnership()
  {
    // BK Ok
    require(msg.sender == newOwner);
    // BK Ok
    OwnershipTransferred(owner, newOwner);
    // BK Ok
    owner = newOwner;
  }

}


// ----------------------------------------------------------------------------
//
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
//
// ----------------------------------------------------------------------------

// BK Ok
contract ERC20Interface {

  // Events ---------------------------

  // BK Ok - Event
  event Transfer(
    address indexed _from,
    address indexed _to,
    uint _value
  );
  
  // BK Ok - Event
  event Approval(
    address indexed _owner,
    address indexed _spender,
    uint _value
  );

  // Functions ------------------------

  // BK Ok
  function totalSupply() constant
    returns (uint);
  
  // BK Ok
  function balanceOf(address _owner) constant 
    returns (uint balance);

  // BK Ok
  function transfer(address _to, uint _value)
    returns (bool success);
  
  // BK Ok
  function transferFrom(address _from, address _to, uint _value) 
    returns (bool success);
  
  // BK Ok
  function approve(address _spender, uint _value) 
    returns (bool success);
  
  // BK Ok
  function allowance(address _owner, address _spender) constant 
    returns (uint remaining);

}


// BK NOTE - ERC20Token should implement all required functions, including totalSupply()
// ----------------------------------------------------------------------------
//
// ERC Token Standard #20
//
// note that totalSupply() is not defined here
//
// ----------------------------------------------------------------------------

// BK Ok
contract ERC20Token is ERC20Interface, Owned {
  
  // BK Ok
  using SafeMath3 for uint;

  // BK Ok
  mapping(address => uint) balances;
  // BK Ok
  mapping(address => mapping (address => uint)) allowed;

  // Functions ------------------------

  /* Get the account balance for an address */

  // BK Ok - Constant function
  function balanceOf(address _owner) constant 
    returns (uint balance)
  {
    // BK Ok
    return balances[_owner];
  }

  /* Transfer the balance from owner's account to another account */

  // BK Ok
  function transfer(address _to, uint _amount) 
    returns (bool success)
  {
    // Amount sent cannot exceed balance
    // BK Ok
    require( balances[msg.sender] >= _amount );

    // update balances
    // BK Ok
    balances[msg.sender] = balances[msg.sender].sub(_amount);
    // BK Ok
    balances[_to]        = balances[_to].add(_amount);

    // Log event
    // BK Ok
    Transfer(msg.sender, _to, _amount);
    // BK Ok
    return true;
  }

  /* Allow _spender to withdraw from your account up to _amount */

  // BK Ok
  function approve(address _spender, uint _amount) 
    returns (bool success)
  {
    // before changing the approve amount for an address, its allowance
    // must be reset to 0 to mitigate the race condition described here:
    // https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    // BK NOTE - Consider removing - see NOTE in https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md#approve
    require( _amount == 0 || allowed[msg.sender][_spender] == 0 );
      
    // approval amount cannot exceed the balance
    // BK Ok
    require ( balances[msg.sender] >= _amount );
      
    // update allowed amount
    // BK Ok
    allowed[msg.sender][_spender] = _amount;
    
    // log event
    // BK Ok - Log event
    Approval(msg.sender, _spender, _amount);
    // BK Ok
    return true;
  }

  /* Spender of tokens transfers tokens from the owner's balance */
  /* Must be pre-approved by owner */

  // BK Ok
  function transferFrom(address _from, address _to, uint _amount) 
    returns (bool success) 
  {
    // balance checks
    // BK Ok
    require( balances[_from] >= _amount );
    // BK Ok
    require( allowed[_from][msg.sender] >= _amount );

    // update balances and allowed amount
    // BK Ok
    balances[_from]            = balances[_from].sub(_amount);
    // BK Ok
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
    // BK Ok
    balances[_to]              = balances[_to].add(_amount);

    // log event
    // BK Ok - Log event
    Transfer(_from, _to, _amount);
    // BK Ok
    return true;
  }

  /* Returns the amount of tokens approved by the owner */
  /* that can be transferred by spender */

  // BK Ok - Constant function
  function allowance(address _owner, address _spender) constant 
    returns (uint remaining)
  {
    // BK Ok
    return allowed[_owner][_spender];
  }

}


// ----------------------------------------------------------------------------
//
// IDH public token sale
//
// ----------------------------------------------------------------------------

// BK Ok
contract IndaHashToken is ERC20Token {

  /* Utility variable */
  
  // BK Ok
  uint constant E6 = 10**6;
  
  /* Basic token data */

  // BK Next 3 Ok
  string public constant name     = "indaHash Coin";
  string public constant symbol   = "IDH";
  uint8  public constant decimals = 6;

  /* Wallet addresses - initially set to owner at deployment */
  
  // BK Next 2 Ok
  address public wallet;
  address public adminWallet;

  /* ICO dates */

  // BK Ok - new Date(1510153200 * 1000).toUTCString() => "Wed, 08 Nov 2017 15:00:00 UTC"
  uint public constant DATE_PRESALE_START = 1510153200; // 08-Nov-2017 15:00 UTC
  // BK Ok - new Date(1510758000 * 1000).toUTCString() => "Wed, 15 Nov 2017 15:00:00 UTC"
  uint public constant DATE_PRESALE_END   = 1510758000; // 15-Nov-2017 15:00 UTC

  // BK Ok - new Date(1511967600 * 1000).toUTCString() => "Wed, 29 Nov 2017 15:00:00 UTC"
  uint public constant DATE_ICO_START = 1511967600; // 29-Nov-2017 15:00 UTC
  // BK Ok - new Date(1513782000 * 1000).toUTCString() => "Wed, 20 Dec 2017 15:00:00 UTC"
  uint public constant DATE_ICO_END   = 1513782000; // 20-Dec-2017 15:00 UTC

  /* ICO tokens per ETH */
  
  // BK Ok
  uint public tokensPerEth = 3200 * E6; // rate during last ICO week

  // BK Next 3 Ok
  uint public constant BONUS_PRESALE      = 40;
  uint public constant BONUS_ICO_WEEK_ONE = 20;
  uint public constant BONUS_ICO_WEEK_TWO = 10;

  /* Other ICO parameters */  
  
  // BK Next 3 Ok
  uint public constant TOKEN_SUPPLY_TOTAL = 400 * E6 * E6; // 400 mm tokens
  uint public constant TOKEN_SUPPLY_ICO   = 320 * E6 * E6; // 320 mm tokens
  uint public constant TOKEN_SUPPLY_MKT   =  80 * E6 * E6; //  80 mm tokens

  // BK Ok
  uint public constant MIN_FUNDING_GOAL =  40 * E6 * E6; // 40 mm tokens
  
  // BK Ok
  uint public constant MIN_CONTRIBUTION = 1 ether / 20; // 0.05 Ether

  // BK Next 2 Ok
  uint public constant COOLDOWN_PERIOD =  2 days;
  uint public constant CLAWBACK_PERIOD = 90 days;

  /* Crowdsale variables */

  // BK Ok
  uint public icoEtherReceived = 0; // Ether actually received by the contract

  // BK Next 3 Ok
  uint public tokensIssuedTotal = 0;
  uint public tokensIssuedIco   = 0;
  uint public tokensIssuedMkt   = 0;
  
  // BK Ok
  uint public tokensClaimedAirdrop = 0;
  
  /* Keep track of Ether contributed and tokens received during Crowdsale */
  
  // BK Next 2 Ok
  mapping(address => uint) public icoEtherContributed;
  mapping(address => uint) public icoTokensReceived;

  /* Keep track of participants who 
  /* - have received their airdropped tokens after a successful ICO */
  /* - or have reclaimed their contributions in case of fialed Crowdsale */
  
  // BK Next 2 Ok
  mapping(address => bool) public airdropClaimed;
  mapping(address => bool) public refundClaimed;

  // Events ---------------------------
  
  // BK Ok - Event
  event WalletUpdated(
    address _newWallet
  );
  
  // BK Ok - Event
  event AdminWalletUpdated(
    address _newAdminWallet
  );

  // BK Ok - Event
  event TokensPerEthUpdated(
    uint _tokensPerEth
  );

  // BK Ok - Event
  event TokensMinted(
    address indexed _owner,
    uint _tokens,
    uint _balance
  );

  // BK Ok - Event
  event TokensIssued(
    address indexed _owner,
    uint _tokens, 
    uint _balance, 
    uint _etherContributed
  );
  
  // BK Ok - Event
  event Refund(
    address indexed _owner,
    uint _amount,
    uint _tokens
  );

  // BK Ok - Event
  event Airdrop(
    address indexed _owner,
    uint _amount,
    uint _balance
  );

  // Basic Functions ------------------

  /* Initialize (owner is set to msg.sender by Owned.Owned() */

  // BK Ok - Constructor
  function IndaHashToken() {
    // BK Ok
    require( TOKEN_SUPPLY_ICO + TOKEN_SUPPLY_MKT == TOKEN_SUPPLY_TOTAL );
    // BK Next 2 Ok
    wallet = owner;
    adminWallet = owner;
  }

  /* Fallback */
  
  // BK Ok - Fallback, payable
  function () payable
  {
    // BK Ok
    buyTokens();
  }
  
  // Information functions ------------
  
  /* What time is it? */
  
  // BK Ok - Constant function
  function atNow() constant
    returns (uint)
  {
    // BK Ok
    return now;
  }
  
  /* Has the minimum threshold been reached? */
  
  // BK Ok - Constant function
  function icoThresholdReached() constant
    returns (bool thresholdReached)
  {
     // BK Ok
     if (tokensIssuedIco < MIN_FUNDING_GOAL) return false;
     // BK Ok
     return true;
  }  
  
  /* Are tokens transferable? */

  // BK Ok - Constant function
  function isTransferable() constant
    returns (bool transferable)
  {
     // BK Ok
     if ( !icoThresholdReached() ) return false;
     // BK Ok
     if ( atNow() < DATE_ICO_END + COOLDOWN_PERIOD ) return false;
     // BK Ok
     return true;
  }
  
  /* Crowdsale contribution in Ether */

  // BK NOTE - Use can execute icoEtherContributed(address) which will provide the exact same result
  // BK Ok - Constant function
  function icoEtherContributedOf(address _owner) constant 
    returns (uint)
  {
    // BK Ok
    return icoEtherContributed[_owner];
  }

  /* Number of tokens received during crowdsale */  
  
  // BK NOTE - Use can execute icoTokensReceived(address) which will provide the exact same result
  // BK Ok - Constant function
  function icoTokensReceivedOf(address _owner) constant 
    returns (uint)
  {
    // BK Ok
    return icoTokensReceived[_owner];
  }

  /* Has a refund been claimed? */  
  
  // BK NOTE - Use can execute refundClaimed(address) which will provide the exact same result
  // BK Ok - Constant function
  function isRefundClaimed(address _owner) constant 
    returns (bool)
  {
    // BK Ok
    return refundClaimed[_owner];
  } 

  /* Has the aidrop been claimed? */  
  
  // BK NOTE - Use can execute airdropClaimed(address) which will provide the exact same result
  // BK Ok - Constant function
  function isAirdropClaimed(address _owner) constant 
    returns (bool)
  {
    // BK Ok
    return airdropClaimed[_owner];
  }
  
  // Owner Functions ------------------
  
  /* Change the crowdsale wallet address */

  // BK Ok - Only owner can execute
  function setWallet(address _wallet) onlyOwner
  {
    // BK Ok
    require( _wallet != address(0x0) );
    // BK Ok
    wallet = _wallet;
    // BK Ok - Log event
    WalletUpdated(wallet);
  }

  /* Change the admin wallet address */

  // BK Ok - Only owner can execute
  function setAdminWallet(address _wallet) onlyOwner
  {
    // BK Ok
    require( _wallet != address(0x0) );
    // BK Ok
    adminWallet = _wallet;
    // BK Ok - Log event
    AdminWalletUpdated(adminWallet);
  }

  /* Change tokensPerEth before ICO start */
  
  // BK Ok - Only owner can execute, before the Presale starts
  function updateTokensPerEth(uint _tokensPerEth) onlyOwner
  {
    // BK Ok
    require( atNow() < DATE_PRESALE_START );
    // BK Ok
    tokensPerEth = _tokensPerEth;
    // BK Ok - Log event
    TokensPerEthUpdated(_tokensPerEth);
  }

  /* Minting of marketing tokens by owner */

  // BK Ok - Only owner can execute
  function mintMarketing(address _participant, uint _tokens) onlyOwner 
  {
    // Check amount
    // BK Ok
    require( _tokens <= TOKEN_SUPPLY_MKT.sub(tokensIssuedMkt) );
    
    // Update balances
    // BK Next 3 Ok
    balances[_participant] = balances[_participant].add(_tokens);
    tokensIssuedMkt        = tokensIssuedMkt.add(_tokens);
    tokensIssuedTotal      = tokensIssuedTotal.add(_tokens);
    
    // Log the miniting
    // BK Next 2 Ok - Log events
    Transfer(0x0, _participant, _tokens);
    TokensMinted(_participant, _tokens, balances[_participant]);
  }

  /* Owner clawback of remaining funds after clawback period */
  /* (for use in case of a failed Crwodsale) */
  
  // BK Ok - Only owner can execute
  function ownerClawback() external onlyOwner {
    // BK Ok
    require( atNow() > DATE_ICO_END + CLAWBACK_PERIOD );
    // BK Ok
    wallet.transfer(this.balance);
  }

  /* Transfer out any accidentally sent ERC20 tokens */

  // BK Ok - Only owner can execute
  function transferAnyERC20Token(address tokenAddress, uint amount) onlyOwner 
    returns (bool success) 
  {
      // BK Ok
      return ERC20Interface(tokenAddress).transfer(owner, amount);
  }

  // Private functions ----------------

  /* Accept ETH during crowdsale (called by default function) */

  // BK Ok
  function buyTokens() private
  {
    // BK Ok
    uint ts = atNow();
    // BK Ok
    bool isPresale = false;
    // BK Ok
    bool isIco = false;
    // BK Ok
    uint tokens = 0;
    
    // BK Ok
    require( msg.value >= MIN_CONTRIBUTION );

    // check dates for presale or ICO
    // BK Ok
    if (ts > DATE_PRESALE_START && ts < DATE_PRESALE_END) isPresale = true;
    // BK Ok  
    if (ts > DATE_ICO_START && ts < DATE_ICO_END) isIco = true;
    // BK Ok  
    require( isPresale || isIco );

    // get baseline number of tokens
    // BK Ok
    tokens = tokensPerEth.mul(msg.value) / 1 ether;
    
    // apply bonuses (none for last week)
    // BK Ok
    if (isPresale) {
      // BK Ok
      tokens = tokens.mul(100 + BONUS_PRESALE) / 100;
    }
    // BK Ok
    else if (ts < DATE_ICO_START + 7 days) {
      // first week ico bonus
      // BK Ok
      tokens = tokens.mul(100 + BONUS_ICO_WEEK_ONE) / 100;
    }
    // BK Ok
    else if (ts < DATE_ICO_START + 14 days) {
      // second week ico bonus
      // BK Ok
      tokens = tokens.mul(100 + BONUS_ICO_WEEK_TWO) / 100;
    }
    
    // ICO token volume cap
    // BK Ok
    require( tokensIssuedIco.add(tokens) <= TOKEN_SUPPLY_ICO );

    // Register tokens
    // BK Next 4 Ok
    balances[msg.sender]          = balances[msg.sender].add(tokens);
    icoTokensReceived[msg.sender] = icoTokensReceived[msg.sender].add(tokens);
    tokensIssuedIco               = tokensIssuedIco.add(tokens);
    tokensIssuedTotal             = tokensIssuedTotal.add(tokens);
    
    // Register Ether
    // BK Next 2 Ok
    icoEtherReceived                = icoEtherReceived.add(msg.value);
    icoEtherContributed[msg.sender] = icoEtherContributed[msg.sender].add(msg.value);
    
    // Log token issuance
    // BK Next 2 Ok - Log events
    Transfer(0x0, msg.sender, tokens);
    TokensIssued(msg.sender, tokens, balances[msg.sender], msg.value);

    // transfer Ether if we're over the threshold
    // BK Ok
    if ( icoThresholdReached() ) wallet.transfer(this.balance);
  }
  
  // ERC20 functions ------------------

  /* Implement totalSupply() ERC20 function */
  
  // BK Ok - Constant function
  function totalSupply() constant
    returns (uint)
  {
    // BK Ok
    return tokensIssuedTotal;
  }

  /* Override "transfer" (ERC20) */

  function transfer(address _to, uint _amount) 
    returns (bool success)
  {
    require( isTransferable() );
    return super.transfer(_to, _amount);
  }
  
  /* Override "transferFrom" (ERC20) */

  function transferFrom(address _from, address _to, uint _amount) 
    returns (bool success)
  {
    require( isTransferable() );
    return super.transferFrom(_from, _to, _amount);
  }

  // External functions ---------------

  /* Reclaiming of funds by contributors in case of a failed crowdsale */
  /* (it will fail if account is empty after ownerClawback) */

  /* While there could not have been any token transfers yet, a contributor */
  /* may have received minted tokens, so the token balance after a refund */ 
  /* may still be positive */
  
  function reclaimFunds() external
  {
    uint tokens; // tokens to destroy
    uint amount; // refund amount
    
    // ico is finished and was not successful
    require( atNow() > DATE_ICO_END && !icoThresholdReached() );
    
    // check if refund has already been claimed
    require( !refundClaimed[msg.sender] );
    
    // check if there is anything to refund
    require( icoEtherContributed[msg.sender] > 0 );
    
    // update variables affected by refund
    tokens = icoTokensReceived[msg.sender];
    amount = icoEtherContributed[msg.sender];

    balances[msg.sender] = balances[msg.sender].sub(tokens);
    tokensIssuedTotal    = tokensIssuedTotal.sub(tokens);
    
    refundClaimed[msg.sender] = true;
    
    // transfer out refund
    msg.sender.transfer(amount);
    
    //log
    Transfer(msg.sender, 0x0, tokens);
    Refund(msg.sender, amount, tokens);
  }

  /* Claiming of "airdropped" tokens in case of successful crowdsale */
  /* Can be done by token holder, or by adminWallet */ 

  function claimAirdrop() external
  {
    doAirdrop(msg.sender);
  }

  function adminClaimAirdrop(address _participant) external
  {
    require( msg.sender == adminWallet );
    doAirdrop(_participant);
  }

  function doAirdrop(address _participant) internal
  {
    uint airdrop = computeAirdrop(_participant);

    require( airdrop > 0 );

    // update balances and token issue volume
    airdropClaimed[_participant] = true;
    balances[_participant] = balances[_participant].add(airdrop);
    tokensIssuedTotal      = tokensIssuedTotal.add(airdrop);
    tokensClaimedAirdrop   = tokensClaimedAirdrop.add(airdrop);
    
    // log
    Airdrop(_participant, airdrop, balances[_participant]);
    Transfer(0x0, _participant, airdrop);
  }

  /* Function to estimate airdrop amount. For some accounts, the value of */
  /* tokens received by calling claimAirdrop() may be less than gas costs */
  
  /* If an account has tokens from the ico, the amount after the airdrop */
  /* will be newBalance = tokens * TOKEN_SUPPLY_ICO / tokensIssuedIco */
      
  function computeAirdrop(address _participant) constant
    returns (uint airdrop)
  {
    // return 0 if it's too early or ico was not successful
    if ( atNow() < DATE_ICO_END || !icoThresholdReached() ) return 0;
    
    // return  0 is the airdrop was already claimed
    if( airdropClaimed[_participant] ) return 0;

    // return 0 if the account does not hold any crowdsale tokens
    if( icoTokensReceived[_participant] == 0 ) return 0;
    
    // airdrop amount
    uint tokens = icoTokensReceived[_participant];
    uint newBalance = tokens.mul(TOKEN_SUPPLY_ICO) / tokensIssuedIco;
    airdrop = newBalance - tokens;
  }  

}
```