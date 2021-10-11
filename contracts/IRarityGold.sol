// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRarityGold {

  function balanceOf(uint) external view returns(uint);

  function allowance(uint,uint) external view returns(uint);

  function transferFrom(uint,uint,uint,uint) external returns (bool);

  function transfer(uint,uint,uint) external returns (bool);

  function claim(uint) external;

}
