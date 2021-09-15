# ThievesGuild
Disclaimer: work in progress

Brief description:

Thief's guild consists of members with different ranks based on experience (earned from guild quests ) inside the guild and a guild master. It has a treasury that can be managed by the Guild Master who can be conspired against by the members and be killed (voting power is determined by experience inside the guild ). Thus opening a window for a new master to be chosen. Allowed classes in the guild: rogue / bard / wizard / fighter (open to discussions).

The guild master can call different functions ( do strategic actions ) which will initiate a cooldown . As an example: a guild master at a given time can choose to either onboard new members to enlarge the treasury of the guild or call bribeGuards() function ( 1 of many different actions ) to reset guards' satisfaction level. If for example, guard's satisfaction level becomes too low they will raid the guild and take x% of the treasury and arrest the guild master for x time, rendering him unable to do further actions for the time being.

Guild members can do stealing quests everyday to gain guild xp, stealing quests may yield loot, ( loot can be different types for different classes ) loot fate is randomness is seeded by acceptanceTime ( open to discussions ).

---- IMPORTANT -----
Loot system is yet to be fully developed but my idea was to initally seed them based on something applicant can't controll, acceptanceTime () when the acceptNewMembers functions is called ) and making loot precalculated, example: 3rd drop would be the same doesn't matter if you did it inside a block of blockhash of X or blockhash of Y, but future events like guild actions or other members doing quests could be used to seed the randomness to re-compute the loot, so you couldn't just see your future drops ( well you could, but that would be calculated on current state of the contract, and if it's calculated based on future state which is not to 1 user's control that would be as close to random as i can think of ). That way we get rid of precomputability with current dice rolling mechanism which is dependant on blockhash as salt. Ofcourse nothing would be better than have Chainlink/Band VRF at this moment , but I think my solution fixed the problem in a quite innovative way ( if anyone finds a hole in this logic i would love to discuss it with you ).

TL:DR: Loot drops won't depend on the blockhash as salt,but they can be precomputed by shadowy super coders, but the actions in the future will recalculate future loot drops so it will keep them random. Yes someone could wait few days (vs few blocks in in blockhash seeding) for the state of whatever's seeding the loot to be changed, but that's an opportunity cost of being idle.


---- detailed process of current implementation ----

1) summoner makes an application with function applyForMembership( uint summonerID )
allowed classes are
  uint[] public allowedClasses = [
    2 , // Bard
    5, // Fighter
    9, // Rogue
    11 // wizard
  ];
and your summoner needs to be atleast Level 2 to be able to submit an application.

2) Guild master can at any point , unless he is on actionCooldown call acceptNewMembers(uint amount) with a restriction: require(amount < 50 || amount < guildMembers.length ,"Cant onboard too much people at once"); ( subject to change). After function is initiated it loops through all applications and whichever are of atleast x hours old it takes tribute payment in form of Gold, accepts and enrolls the new members with rank 1: "toad". Application which were not old enough ( too fresh) will be included in the next wave. Whoever was qualified but didn't have gold approved at the time is disqualified and taken off applicant list ( although they are free to apply at any point after ). Whatever gold is gathered from tributes goes to guild treasury for guild master to manage for the benefit of the whole guild ( if he won't make good decision, he might be conspired against and killed/overthrown ).

3) After being enrolled you'll be met with a list of quests that will trigger different cooldown periods and will yield different XP amount aswell. Some quests are unlocked only for certain ranks. Quests have loot and some of them give bonus to xp multipliers or some guild specific benefits. Every other rank requires rarityXp (different from guild xp) to be spent, increasing with each level.
  if ((_rank % 2) == 0) {
    rarityContract.spend_xp(_summoner,_rank * xp_cost);
  }



Current Rank titles: ( forgive my lazyness )

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
