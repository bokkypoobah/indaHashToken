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

library SafeMath3 {

  function mul(uint a, uint b) internal constant 
    returns (uint c)
  {
    c = a * b;
    assert( a == 0 || c / a == b );
  }

  function sub(uint a, uint b) internal constant
    returns (uint)
  {
    assert( b <= a );
    return a - b;
  }

  function add(uint a, uint b) internal constant
    returns (uint c)
  {
    c = a + b;
    assert( c >= a );
  }

}


// ----------------------------------------------------------------------------
//
// Owned contract
//
// ----------------------------------------------------------------------------

contract Owned {

  address public owner;
  address public newOwner;

  // Events ---------------------------

  event OwnershipTransferProposed(
    address indexed _from,
    address indexed _to
  );

  event OwnershipTransferred(
    address indexed _from,
    address indexed _to
  );

  // Modifier -------------------------

  modifier onlyOwner
  {
    require( msg.sender == owner );
    _;
  }

  // Functions ------------------------

  function Owned()
  {
    owner = msg.sender;
  }

  function transferOwnership(address _newOwner) onlyOwner
  {
    require( _newOwner != owner );
    require( _newOwner != address(0x0) );
    OwnershipTransferProposed(owner, _newOwner);
    newOwner = _newOwner;
  }

  function acceptOwnership()
  {
    require(msg.sender == newOwner);
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


// ----------------------------------------------------------------------------
//
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
//
// ----------------------------------------------------------------------------

contract ERC20Interface {

  // Events ---------------------------

  event Transfer(
    address indexed _from,
    address indexed _to,
    uint _value
  );
  
  event Approval(
    address indexed _owner,
    address indexed _spender,
    uint _value
  );

  // Functions ------------------------

  function totalSupply() constant
    returns (uint);
  
  function balanceOf(address _owner) constant 
    returns (uint balance);
  
  function transfer(address _to, uint _value)
    returns (bool success);
  
  function transferFrom(address _from, address _to, uint _value) 
    returns (bool success);
  
  function approve(address _spender, uint _value) 
    returns (bool success);
  
  function allowance(address _owner, address _spender) constant 
    returns (uint remaining);

}


// ----------------------------------------------------------------------------
//
// ERC Token Standard #20
//
// note that totalSupply() is not defined here
//
// ----------------------------------------------------------------------------

contract ERC20Token is ERC20Interface, Owned {
  
  using SafeMath3 for uint;

  mapping(address => uint) balances;
  mapping(address => mapping (address => uint)) allowed;

  // Functions ------------------------

  /* Get the account balance for an address */

  function balanceOf(address _owner) constant 
    returns (uint balance)
  {
    return balances[_owner];
  }

  /* Transfer the balance from owner's account to another account */

  function transfer(address _to, uint _amount) 
    returns (bool success)
  {
    // Amount sent cannot exceed balance
    require( balances[msg.sender] >= _amount );

    // update balances
    balances[msg.sender] = balances[msg.sender].sub(_amount);
    balances[_to]        = balances[_to].add(_amount);

    // Log event
    Transfer(msg.sender, _to, _amount);
    return true;
  }

  /* Allow _spender to withdraw from your account up to _amount */

  function approve(address _spender, uint _amount) 
    returns (bool success)
  {
    // before changing the approve amount for an address, its allowance
    // must be reset to 0 to mitigate the race condition described here:
    // https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require( _amount == 0 || allowed[msg.sender][_spender] == 0 );
      
    // approval amount cannot exceed the balance
    require ( balances[msg.sender] >= _amount );
      
    // update allowed amount
    allowed[msg.sender][_spender] = _amount;
    
    // log event
    Approval(msg.sender, _spender, _amount);
    return true;
  }

  /* Spender of tokens transfers tokens from the owner's balance */
  /* Must be pre-approved by owner */

  function transferFrom(address _from, address _to, uint _amount) 
    returns (bool success) 
  {
    // balance checks
    require( balances[_from] >= _amount );
    require( allowed[_from][msg.sender] >= _amount );

    // update balances and allowed amount
    balances[_from]            = balances[_from].sub(_amount);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
    balances[_to]              = balances[_to].add(_amount);

    // log event
    Transfer(_from, _to, _amount);
    return true;
  }

  /* Returns the amount of tokens approved by the owner */
  /* that can be transferred by spender */

  function allowance(address _owner, address _spender) constant 
    returns (uint remaining)
  {
    return allowed[_owner][_spender];
  }

}


// ----------------------------------------------------------------------------
//
// IDH public token sale
//
// ----------------------------------------------------------------------------

contract IndaHashToken is ERC20Token {

  /* Utility variable */
  
  uint constant E6 = 10**6;
  
  /* Basic token data */

  string public constant name     = "indaHash Coin";
  string public constant symbol   = "IDH";
  uint8  public constant decimals = 6;

  /* Wallet addresses - initially set to owner at deployment */
  
  address public wallet;
  address public adminWallet;

  /* ICO dates */

  uint public constant DATE_PRESALE_START = 1508517605; // Fri 20 Oct 2017 16:40:05 UTC
  uint public constant DATE_PRESALE_END   = 1508517665; // Fri 20 Oct 2017 16:41:05 UTC

  uint public constant DATE_ICO_START = 1508517725; // Fri 20 Oct 2017 16:42:05 UTC
  uint public constant DATE_ICO_END   = 1508517785; // Fri 20 Oct 2017 16:43:05 UTC

  /* ICO tokens per ETH */
  
  uint public tokensPerEth = 3200 * E6; // rate during last ICO week

  uint public constant BONUS_PRESALE      = 40;
  uint public constant BONUS_ICO_WEEK_ONE = 20;
  uint public constant BONUS_ICO_WEEK_TWO = 10;

  /* Other ICO parameters */  
  
  uint public constant TOKEN_SUPPLY_TOTAL = 400 * E6 * E6; // 400 mm tokens
  uint public constant TOKEN_SUPPLY_ICO   = 320 * E6 * E6; // 320 mm tokens
  uint public constant TOKEN_SUPPLY_MKT   =  80 * E6 * E6; //  80 mm tokens

  uint public constant MIN_FUNDING_GOAL =  40 * E6 * E6; // 40 mm tokens
  
  uint public constant MIN_CONTRIBUTION = 1 ether / 20; // 0.05 Ether

  uint public constant COOLDOWN_PERIOD =  2 days;
  uint public constant CLAWBACK_PERIOD = 90 days;

  /* Crowdsale variables */

  uint public icoEtherReceived = 0; // Ether actually received by the contract

  uint public tokensIssuedTotal = 0;
  uint public tokensIssuedIco   = 0;
  uint public tokensIssuedMkt   = 0;
  
  uint public tokensClaimedAirdrop = 0;
  
  /* Keep track of Ether contributed and tokens received during Crowdsale */
  
  mapping(address => uint) public icoEtherContributed;
  mapping(address => uint) public icoTokensReceived;

  /* Keep track of participants who 
  /* - have received their airdropped tokens after a successful ICO */
  /* - or have reclaimed their contributions in case of fialed Crowdsale */
  
  mapping(address => bool) public airdropClaimed;
  mapping(address => bool) public refundClaimed;

  // Events ---------------------------
  
  event WalletUpdated(
    address _newWallet
  );
  
  event AdminWalletUpdated(
    address _newAdminWallet
  );

  event TokensPerEthUpdated(
    uint _tokensPerEth
  );

  event TokensMinted(
    address indexed _owner,
    uint _tokens,
    uint _balance
  );

  event TokensIssued(
    address indexed _owner,
    uint _tokens, 
    uint _balance, 
    uint _etherContributed
  );
  
  event Refund(
    address indexed _owner,
    uint _amount,
    uint _tokens
  );

  event Airdrop(
    address indexed _owner,
    uint _amount,
    uint _balance
  );

  // Basic Functions ------------------

  /* Initialize (owner is set to msg.sender by Owned.Owned() */

  function IndaHashToken() {
    require( TOKEN_SUPPLY_ICO + TOKEN_SUPPLY_MKT == TOKEN_SUPPLY_TOTAL );
    wallet = owner;
    adminWallet = owner;
  }

  /* Fallback */
  
  function () payable
  {
    buyTokens();
  }
  
  // Information functions ------------
  
  /* What time is it? */
  
  function atNow() constant
    returns (uint)
  {
    return now;
  }
  
  /* Has the minimum threshold been reached? */
  
  function icoThresholdReached() constant
    returns (bool thresholdReached)
  {
     if (tokensIssuedIco < MIN_FUNDING_GOAL) return false;
     return true;
  }  
  
  /* Are tokens transferable? */

  function isTransferable() constant
    returns (bool transferable)
  {
     if ( !icoThresholdReached() ) return false;
     if ( atNow() < DATE_ICO_END + COOLDOWN_PERIOD ) return false;
     return true;
  }
  
  /* Crowdsale contribution in Ether */

  function icoEtherContributedOf(address _owner) constant 
    returns (uint)
  {
    return icoEtherContributed[_owner];
  }

  /* Number of tokens received during crowdsale */  
  
  function icoTokensReceivedOf(address _owner) constant 
    returns (uint)
  {
    return icoTokensReceived[_owner];
  }

  /* Has a refund been claimed? */  
  
  function isRefundClaimed(address _owner) constant 
    returns (bool)
  {
    return refundClaimed[_owner];
  } 

  /* Has the aidrop been claimed? */  
  
  function isAirdropClaimed(address _owner) constant 
    returns (bool)
  {
    return airdropClaimed[_owner];
  }
  
  // Owner Functions ------------------
  
  /* Change the crowdsale wallet address */

  function setWallet(address _wallet) onlyOwner
  {
    require( _wallet != address(0x0) );
    wallet = _wallet;
    WalletUpdated(wallet);
  }

  /* Change the admin wallet address */

  function setAdminWallet(address _wallet) onlyOwner
  {
    require( _wallet != address(0x0) );
    adminWallet = _wallet;
    AdminWalletUpdated(adminWallet);
  }

  /* Change tokensPerEth before ICO start */
  
  function updateTokensPerEth(uint _tokensPerEth) onlyOwner
  {
    require( atNow() < DATE_PRESALE_START );
    tokensPerEth = _tokensPerEth;
    TokensPerEthUpdated(_tokensPerEth);
  }

  /* Minting of marketing tokens by owner */

  function mintMarketing(address _participant, uint _tokens) onlyOwner 
  {
    // Check amount
    require( _tokens <= TOKEN_SUPPLY_MKT.sub(tokensIssuedMkt) );
    
    // Update balances
    balances[_participant] = balances[_participant].add(_tokens);
    tokensIssuedMkt        = tokensIssuedMkt.add(_tokens);
    tokensIssuedTotal      = tokensIssuedTotal.add(_tokens);
    
    // Log the miniting
    Transfer(0x0, _participant, _tokens);
    TokensMinted(_participant, _tokens, balances[_participant]);
  }

  /* Owner clawback of remaining funds after clawback period */
  /* (for use in case of a failed Crwodsale) */
  
  function ownerClawback() external onlyOwner {
    require( atNow() > DATE_ICO_END + CLAWBACK_PERIOD );
    wallet.transfer(this.balance);
  }

  /* Transfer out any accidentally sent ERC20 tokens */

  function transferAnyERC20Token(address tokenAddress, uint amount) onlyOwner 
    returns (bool success) 
  {
      return ERC20Interface(tokenAddress).transfer(owner, amount);
  }

  // Private functions ----------------

  /* Accept ETH during crowdsale (called by default function) */

  function buyTokens() private
  {
    uint ts = atNow();
    bool isPresale = false;
    bool isIco = false;
    uint tokens = 0;
    
    require( msg.value >= MIN_CONTRIBUTION );

    // check dates for presale or ICO
    if (ts > DATE_PRESALE_START && ts < DATE_PRESALE_END) isPresale = true;  
    if (ts > DATE_ICO_START && ts < DATE_ICO_END) isIco = true;  
    require( isPresale || isIco );

    // get baseline number of tokens
    tokens = tokensPerEth.mul(msg.value) / 1 ether;
    
    // apply bonuses (none for last week)
    if (isPresale) {
      tokens = tokens.mul(100 + BONUS_PRESALE) / 100;
    }
    else if (ts < DATE_ICO_START + 7 days) {
      // first week ico bonus
      tokens = tokens.mul(100 + BONUS_ICO_WEEK_ONE) / 100;
    }
    else if (ts < DATE_ICO_START + 14 days) {
      // second week ico bonus
      tokens = tokens.mul(100 + BONUS_ICO_WEEK_TWO) / 100;
    }
    
    // ICO token volume cap
    require( tokensIssuedIco.add(tokens) <= TOKEN_SUPPLY_ICO );

    // Register tokens
    balances[msg.sender]          = balances[msg.sender].add(tokens);
    icoTokensReceived[msg.sender] = icoTokensReceived[msg.sender].add(tokens);
    tokensIssuedIco               = tokensIssuedIco.add(tokens);
    tokensIssuedTotal             = tokensIssuedTotal.add(tokens);
    
    // Register Ether
    icoEtherReceived                = icoEtherReceived.add(msg.value);
    icoEtherContributed[msg.sender] = icoEtherContributed[msg.sender].add(msg.value);
    
    // Log token issuance
    Transfer(0x0, msg.sender, tokens);
    TokensIssued(msg.sender, tokens, balances[msg.sender], msg.value);

    // transfer Ether if we're over the threshold
    if ( icoThresholdReached() ) wallet.transfer(this.balance);
  }
  
  // ERC20 functions ------------------

  /* Implement totalSupply() ERC20 function */
  
  function totalSupply() constant
    returns (uint)
  {
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