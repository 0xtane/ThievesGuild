// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRarity {

  function next_summoner() external view returns(uint);

  function summon(uint) external;

  function ownerOf(uint) external view returns(address);

  function getApproved(uint) external returns(address);

  function level(uint) external view returns(uint);

  function class(uint) external view returns(uint);

  function spend_xp(uint,uint) external;

  function xp_required(uint) external pure returns(uint);

  function xp(uint) external pure returns(uint);

  function level_up(uint) external ;

  function adventurers_log(uint) external view returns(uint);

  function adventure(uint) external;
}
