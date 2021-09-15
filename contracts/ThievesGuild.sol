// SPDX-License-Identifier: MIT
////////////////////////////////////////////////////////////////////////////////////////////
pragma solidity ^0.8.0;

import "./IRarity.sol";
import "./IRarityGold.sol";

contract ThievesGuild {
  IRarity public rarityContract = IRarity(0xce761D788DF608BD21bdd59d6f4B54b2e27F25Bb); // Rarity manifested root contract
  IRarityGold public rarityGoldContract = IRarityGold(0x2069B76Afe6b734Fb65D1d099E7ec64ee9CC76B2); // Rariy gold contract

  address public guildMaster;
  uint public _Treasurer;
  uint public lastActionTimestamp;
  uint public tributeAmount;
  uint public applicationCreationToReadyTime;
  uint public actionCooldownTime;
  uint public minLevelRequirement;
  uint public xp_cost;

  mapping(uint => uint) public questToCooldown; // all quests have different cooldown periods
  mapping(uint => uint) public questToXp; // different quests give different xp
  mapping(uint => uint) public quest_log;

  mapping(uint => uint) public xp; // this is guild xp has nothing to do with main xp
  mapping(uint => uint) public rank; // same

  uint[] public applicants;
  mapping(uint => uint) applicationCreationTimes;

  mapping(uint => uint) public xpMultipliers; // xp multipliers for different classes

  uint[] public guildMembers; // summonerID's that have been accepted in the past


  uint[] public allowedClasses = [
    2 , // Bard
    5, // Fighter
    9, // Rogue
    11 // wizard
  ];


  event NewMembersAccepted(uint numAccepted,uint numNotReady,uint numDisqualified);

  event UpRanked(address indexed wallet,uint indexed summonerID, uint indexed level);



  constructor() {
    // create treasurer summoner NPC to hold all guild gold
    _Treasurer = rarityContract.next_summoner();
    rarityContract.summon(5); // our treasurer gotta be strong
    guildMaster = msg.sender; // initial guild master is deployer

    // xp multipliers for different classes
    xpMultipliers[2]=100; // bard has multiplier of 1 == default
    xpMultipliers[5]=95; // warrior has 0.95 == 5% less than default
    xpMultipliers[9]=105; // rogue 1.05
    xpMultipliers[11]=100; // wizard default

    // quest xp settings
    questToXp[0] = 75e18;
    // quest to cooldown settings
    questToCooldown[0] = 6 hours;

    // other settings
    xp_cost = 75e18;
    lastActionTimestamp = 0; // ready for action
    tributeAmount = 500e18; // 500 gold
    applicationCreationToReadyTime = 2 hours; // atleast 2 hours need to be passe before able to be accepted
    actionCooldownTime = 1 days; // cooldown between actions
    minLevelRequirement = 2; // summoner has to be of atleast level 2 to be bale to join the guild
  }

  //Toad
  // Wet Ear
  // Footpad
  // Blackcap
  // Operative
  // Bandit
  // Captain
  // Ringleader
  // Mastermind
  // Master Thief
  // Oblivion ranks
  //
  // Pickpocket
  // Footpad
  // Bandit
  // Prowler
  // Cat Burglar
  // Shadowfoot
  // Master Thief
  //Gray Fox

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

  modifier ownerOrApproved(uint summonerID) {
    require( rarityContract.ownerOf(summonerID) == msg.sender || rarityContract.getApproved(summonerID) == msg.sender , "Neither owner nor approved");
    _;
  }

  modifier notApplicant( uint summonerID ) {
    bool isApplicant = false;
    uint i;
    for ( i = 0; i< applicants.length; i++ ) {
      if ( applicants[i] == summonerID ) {
        isApplicant = true;
        break;
      }
    }
    require( isApplicant == false, "Already an applicant");
    _;
  }

  modifier onlyGuildMaster {
    require( msg.sender == guildMaster ,"Not a guild master");
    _;
  }

  modifier action {
    // means the function is an action that can be performed by guild master only and is suspectible to cooldown
    require( msg.sender == guildMaster ,"Actions can be performed by guild master only");
    require ( block.timestamp > ( lastActionTimestamp + actionCooldownTime ) ,"Action cooldown hasnt passed");
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

  modifier hasRank(uint summonerID , uint rankRequirment) {
    require( rank[summonerID] >= rankRequirment,"Your summoner lacks required rank inside the guild");
    _;
  }

  function practicePickpocket(uint summonerID) external
    onlyMember( summonerID )
    ownerOrApproved( summonerID )
  {
    // questID = 0
    require(block.timestamp > quest_log[summonerID]);
    quest_log[summonerID] = block.timestamp + questToCooldown[0];
    xp[summonerID] += (questToXp[0] * xpMultipliers[rarityContract.class(summonerID)]) / 100;
  }


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

  function applyForMembership( uint summonerID ) external
    ownerOrApproved(summonerID)
    notApplicant(summonerID)
    notGuildMember(summonerID)
    allowedClass(summonerID)
  {
    require( rarityContract.level(summonerID) >= minLevelRequirement,"Min level requirment for applying has not been met");
    applicants.push(summonerID);
    applicationCreationTimes[summonerID] = block.timestamp;
  }

  // accepts given amount of new members from applicants
  function acceptNewMembers( uint amount ) external action {
    require(amount!=0,"Cant onboard 0 people");
    require(amount < 50 || amount < guildMembers.length ,"Cant onboard too much people at once");

    uint[] memory notReadyYet = new uint[](applicants.length); // will be included in the next wave
    uint nrCounter = 0;
    uint newMembersCounter = 0;
    uint disqualifiedCounter = 0;

    if ( applicants.length < amount ) {
      amount=applicants.length;
    }

    uint i;
    for ( i = 0 ; i < amount; i+=1 ) {
      if ( isReadyToBeAccepted(applicants[i]) ) {
        if ( canPayTribute(applicants[i]) ) {
          require(rarityGoldContract.transferFrom(_Treasurer,applicants[i],_Treasurer,tributeAmount),"How did this even happen");
          guildMembers.push(applicants[i]);
          newMembersCounter+=1;
        } else {
          // applicant didn't have gold ready at this time = disqualified
          disqualifiedCounter+=1;
          amount+=1; // open up 1 more slot
        }
      } else {
        // skip this application and include it in next wave
        notReadyYet[nrCounter] = applicants[i];
        nrCounter+=1;
        amount+=1; // open up 1 more slot
      }
    }
    // review of applications done, clear up applicants array and insert notReady ones
    delete applicants;
    for (i=0;i<notReadyYet.length;i+=1) {
      if ( notReadyYet[i]== 0 ) break;
      applicants.push(notReadyYet[i]);
    }

    emit NewMembersAccepted(newMembersCounter,nrCounter,disqualifiedCounter);
  }

  //Checks if enough time (applicationCreationToReadyTime) passed for the application to be ready
  function isReadyToBeAccepted( uint summonerID ) public view returns(bool) {
    return block.timestamp > ( applicationCreationTimes[summonerID] + applicationCreationToReadyTime );
  }

  function canPayTribute(uint summonerID ) public view returns(bool) {
    return ( rarityGoldContract.balanceOf(summonerID) >= tributeAmount ) && ( rarityGoldContract.allowance(summonerID,_Treasurer) >= tributeAmount );
  }


}
