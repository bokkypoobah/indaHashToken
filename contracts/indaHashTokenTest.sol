pragma solidity ^0.4.16;

import 'indaHashToken.sol';

contract IndaHashTokenTest is IndaHashToken {

  uint public testTime = 1;

  // Events ---------------------------

  event TestTimeSet(
    uint _now
  );

  // Functions ------------------------

  function indaHashTokenTest() {}

  function atNow() constant returns (uint) {
      return testTime;
  }

  function setTestTime(uint _t) onlyOwner {
    require( _t > testTime ); // to avoid errors during testing
    testTime = _t;
    TestTimeSet(_t);
  }  

}
