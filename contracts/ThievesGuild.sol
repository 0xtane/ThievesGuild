// SPDX-License-Identifier: MIT
////////////////////////////////////////////////////////////////////////////////////////////
pragma solidity ^0.8.0;

import "./IRarity.sol";
import "./IRarityGold.sol";

contract ThievesGuild {
  IRarity public constant rarityContract = IRarity(0xce761D788DF608BD21bdd59d6f4B54b2e27F25Bb); // Rarity manifested root contract
  IRarityGold public constant rarityGoldContract = IRarityGold(0x2069B76Afe6b734Fb65D1d099E7ec64ee9CC76B2); // Rariy gold contract

  uint public minLevelRequirement;
  uint public xp_cost;
  uint immutable numNPCsPerMember;
  uint immutable rankProtectionPayments;
  
  mapping(uint => uint) public questToCooldown; // all quests have different cooldown periods
  mapping(uint => uint) public questToXp; // different quests give different xp
  mapping(uint => uint) public quest_log;
  mapping(uint => uint) public xp; // this is guild xp has nothing to do with main xp
  mapping(uint => uint) public rank; // same
  mapping(uint => uint[]) internal memberToNPCs;
  mapping(uint => mapping(uint => uint)) public questsCompleted; // keeps track what quest was completed how many times by a summoner. Is used in requireProficiency
  mapping(uint => uint) public xpMultipliers; // xp multipliers for different classes

  uint[] public guildMembers; // summonerID's that have been accepted in the past
  uint[] public immutable allowedClasses;


  constructor() {
    //limitation settings
    rankProtectionPayments = 4; // Blackcap / ranktitle required to collect protection payments
    minLevelRequirement = 2; // summoner has to be of atleast level 2 to be able to join the guild
    allowedClasses = [
      2 , // Bard
      5, // Fighter
      9, // Rogue
      11 // wizard
    ];

    // xp multipliers for different classes
    xpMultipliers[2]=100; // bard has multiplier of 1 == default
    xpMultipliers[5]=95; // warrior has 0.95 == 5% less than default
    xpMultipliers[9]=105; // rogue 1.05
    xpMultipliers[11]=100; // wizard default

    // quest xp settings
    questToXp[0] = 40e18;
    questToXp[1] = 100e18;
    questToXp[2] = 7e18;
    questToXp[3] = 110e18;
    questToXp[4] = 8e18;

    // quest to cooldown settings
    questToCooldown[0] = 5 hours; // practicePickpocket
    questToCooldown[1] = 7 hours; // tryPickpocket
    questToCooldown[2] = 2 hours;
    questToCooldown[3] = 7 hours; // tryPickpocket
    questToCooldown[4] = 9 hours;


    // other settings
    xp_cost = 75e18;
    numNPCsPerMember = 5;  // amount of NPCs assigned to each member for providing protection payments in future
  }
  //////////////////////////////////////////////////////
  event UpRanked(address indexed wallet,uint indexed summonerID, uint indexed level);



  modifier ownerOrApproved(uint summonerID) {
    require( rarityContract.ownerOf(summonerID) == msg.sender || rarityContract.getApproved(summonerID) == msg.sender , "Neither owner nor approved");
    _;
  }

  modifier onlyMember( uint summonerID ) {
    require(isGuildMember(summonerID),"Not a member of the guild");
    _;
  }

  modifier allowedClass ( uint summonerID ) {
    uint class = rarityContract.class(summonerID);
    bool allowed = false;
    uint i;
    for ( i = 0; i < allowedClasses.length; i+=1 ) {
      if ( class == allowedClasses[i] ) {
        allowed = true;
        break;
      }
    }
    require(allowed,"Class not allowed");
    _;
  }

  modifier notGuildMember( uint summonerID ) {
    uint i;
    for ( i=0;i<guildMembers.length;i+=1 ) {
      require( guildMembers[i] != summonerID,"Cant apply if already a member" );
    }
    _;
  }

  modifier quest( uint summonerID ,questID ) {
    require(isGuildMember(summonerID),"Not a member of the guild");
    require( rarityContract.ownerOf(summonerID) == msg.sender || rarityContract.getApproved(summonerID) == msg.sender , "Neither owner nor approved");
    require(block.timestamp > quest_log[summonerID]);
    quest_log[summonerID] = block.timestamp + questToCooldown[questID];
    xp[summonerID] += (questToXp[questID] * xpMultipliers[rarityContract.class(summonerID)]) / 100;
    questsCompleted[summonerID][questID]+=1;
    _;
  }

  // some quests will be tagged with this modifier. those quests will require other type of quest to be completed x times before able to complete these ones
  modifier requireProficiency( uint summonerID, uint questID, uint requiredProficiency ) {
    require( questsCompleted[summonerID][questID]>=requiredProficiency, "Not proficient enough");
    _;
  }

  modifier hasRank(uint summonerID , uint rankRequirment) {
    require( rank[summonerID] >= rankRequirment,"Your summoner lacks required rank inside the guild");
    _;
  }

  function join( uint summonerID ) external
    ownerOrApproved(summonerID)
    notGuildMember(summonerID)
    allowedClass(summonerID)
  {
    require( rarityContract.level(summonerID) >= minLevelRequirement,"Min level requirment for applying has not been met");
    guildMembers.push(summonerID);
  }

  function rankTitle(uint rank_) public pure returns(string memory) {
      // took help from reddit + elderscrolls
      if (rank_ == 1) {
          return "Toad";
      } else if (rank_ == 2) {
          return "Wet Ear";
      } else if (rank_ == 3) {
          return "Footpad";
      } else if (rank_ == 4 ) {
          return "Blackcap";
      } else if (rank_ == 5) {
          return "Operative";
      } else if (rank_ <= 7) {
          return "Bandit";
      } else if (rank_ == 8) {
          return "Captain";
      } else if (rank_ <= 10) {
          return "Ringleader";
      } else if (rank_ == 11) {
          return "Mastermind";
      } else if (rank_ == 12) {
          return "Master Thief candidate";
      } else if (rank_ <= 14) {
          return "Master Thief";
      } else {
          return "Gray Fox";
      }
    }

  // loops through all NPCS assigned to member and returns their total gold balance
  function checkPotentialPayments( uint summonerID ) public  view returns(uint){
    uint goldAmount;
    for (uint i=0;i<numNPCsPerMember;i++) {
      goldAmount+=rarityGoldContract.balanceOf(memberToNPCs[summonerID][i]);
    }
    return goldAmount;
  }
  // llops through all NPCs assigned to member and transfer all gold from each
  function claimProtectionPayments( uint summonerID ) public
    ownerOrApproved(summonerID)
    onlyMember(summonerID)
    hasRank( summonerID, rankProtectionPayments)
  {
    uint goldBalanceEach = rarityGoldContract.balanceOf(memberToNPCs[summonerID][0]);
    require(goldBalanceEach>0,"No available payments to claim");
    for ( uint i =0;i <numNPCsPerMember;i++ ) {
      rarityGoldContract.transfer( memberToNPCs[summonerID][i],summonerID,goldBalanceEach );
    }
  }

  function checkPaymentSystem(uint summonerID) internal {
    if (memberToNPCs[summonerID].length==0) {
      assignNPCs(summonerID);
    }
    attemptAdventures( summonerID );

    if (attemptLevelUps(summonerID)) attemptGatherGold(summonerID);
  }

  function attemptGatherGold(uint summonerID) internal {
    uint i;
    for (i=0;i<numNPCsPerMember;i++) {
      rarityGoldContract.claim(memberToNPCs[summonerID][i]);
    }
  }

  function attemptLevelUps(uint summonerID) internal returns(bool){
    uint level = rarityContract.level(memberToNPCs[summonerID][0]);
    uint _xp_required = rarityContract.xp_required(level);
    uint current_xp = rarityContract.xp(memberToNPCs[summonerID][0]);


    if (current_xp>=_xp_required) {
      uint i;
      for (i=0;i<numNPCsPerMember;i++) {
        rarityContract.level_up( memberToNPCs[summonerID][i] );
      }
      return true;
    }
    return false;
  }

  function attemptAdventures(uint summonerID) internal {
    if ( block.timestamp > rarityContract.adventurers_log(memberToNPCs[summonerID][0]) ) {
      uint i;
      for ( i=0;i<numNPCsPerMember;i++){
        rarityContract.adventure(memberToNPCs[summonerID][i]);
      }
    }
  }

  function assignNPCs(uint summonerID) internal {
    while ( memberToNPCs[summonerID].length!=numNPCsPerMember ) {
      memberToNPCs[summonerID].push(rarityContract.next_summoner());
      rarityContract.summon(2);
    }
  }

  function practicePickpocket(uint summonerID) external
    quest( summonerID , 0 )
  {
    // questID = 0
  }

  function tryPickpocket(uint summonerID) external
    // questID
    quest( summonerID , 1 )
    requireProficiency( summonerID, 0 , 5 )
  {
    // questID = 1
  }

  function practiceSilentWalking(uint summonerID) external
    quest( summonerID , 2)
    hasRank( summonerID , 2 )
  {
    //questID = 2
  }

  function tryRobHome(uint summonerID) external
    quest(summonerID, 3)
    hasRank( summonerID, 3)
    requireProficiency( summonerID, 2 , 5 )
  {
    //questID = 3
  }

  function robHome(uint summonerID) external
    quest(summonerID, 5)
    hasRank( summonerID, 5)
    requireProficiency( summonerID, 3 , 5 )
  {
    //questID = 5
  }

  function mug(uint summonerID) external
    quest(summonerID, 4)
    hasRank( summonerID, 2)
  {
    // questId = 4
  }

  // function stealFood(uint summonerID) external
  //   quest(summonerID, 5)
  // {
  //   // questID = 5
  // }

  function spend_xp(uint _summoner, uint _xp) public
    onlyMember( _summoner )
    ownerOrApproved( _summoner )
  {
    xp[_summoner] -= _xp;
  }

  function rank_up(uint _summoner) external
    onlyMember( _summoner )
    ownerOrApproved( _summoner )
  {
    uint _rank = rank[_summoner];
    if ((_rank % 2) == 0) {
      rarityContract.spend_xp(_summoner,_rank * xp_cost);
    }
    uint _xp_required = xp_required(_rank);
    xp[_summoner] -= _xp_required;
    rank[_summoner] = _rank+1;
    emit UpRanked(msg.sender, _summoner , _rank);
  }

  function xp_required(uint curent_rank) public pure returns (uint xp_to_next_rank) {
    xp_to_next_rank = curent_rank * 1000e18;
    for (uint i = 1; i < curent_rank; i++) {
          xp_to_next_rank += i * 1000e18;
      }
  }

  function isGuildMember(uint summonerID) public view returns(bool) {
    uint i;
    for ( i=0;i<guildMembers.length;i+=1 ) {
      if ( guildMembers[i] == summonerID ) return true;
    }
    return false;
  }

  // apply for guild membership with your summonerID, he has to be one of the allowed classes
  // gold needs to be approved by the time application is accepted otherwise if summoner won't be able to present tribute he will be declined


}
