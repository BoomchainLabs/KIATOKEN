// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract KIATOKEN is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, PausableUpgradeable, OwnableUpgradeable {
    
    // Event for warnings
    event Warning(string message);

    // Percentage earned on donation
    uint256 constant public royalty = 2;
    
    // Lock durations and release times for the lockers
uint public lockDurationLocker1;
uint public lockDurationLocker2;
uint public lockDurationLocker3;
uint public lockToken1ReleaseTime;
uint public lockToken2ReleaseTime;
uint public lockToken3ReleaseTime;

// Variable for calculation of staking rewards
    uint256 internal deployTime;

    // Total supply of 1 billion tokens
    uint256 immutable public _totalSupply = 1000000000 * 10 ** decimals();
    
    // Rate of reward tokens to be distributed
    uint public rewardPerThousandPerDay = 2;
    
    // Time interval for reward calculation (1 Day)
    uint public rewardPerDay = 1;

    uint256 public overallTotalDonatedTokens;

    mapping(address => mapping(address => uint256)) private _allowances;

    // List of staking addresses
    address[] public stakingAddresses;

    // List of donating addresses
    address[] public donatingAddresses;


    // Function to get staking addresses
    function getStakingAddresses() public view returns (address[] memory) {
        return stakingAddresses;
    }

    // Function to get donating addresses
    function getDonatingAddresses() public view returns (address[] memory) {
        return donatingAddresses;
    }
    
    // Wallets
    address constant public airDropwallet = 0xB0975EF03767f0eb374F71575B7F870198a0420f;
    address constant public StackingRewardTokens = 0xc5fA8a6E836e2a7F5712A1328B5Cc04D1cBEe2F8;
    address constant public managemenetWallet = 0x0A8c07a76E8febBB6928a9c811512709cf7A2B93;
    address constant public technicalteam = 0xbD343bf6b8eb858bD6F5AC797f217903e6c5E75E;
    address constant public privatesales = 0x521BCefF84c59fc75C71d6D085A416155F5D1d7b;
    address constant public publicsales = 0x9B1d41E5F93e726951F2BEe2224dC43a2A6d108c;
    address constant public liquidity = 0xf5DcC03E798e336c0df9Aad0a2329B1951e764b7;
    address constant public devTeamwallet = 0x99C5BcEC445C4E24f342037f2bc730406a460b2E;
    address constant public TokenBurningWallet = 0xe1Be0e1B6B543Dde93Da98694508C2Bfb272FbeB;
    address constant public locker1 = 0xaf7b3E7d217Ffd8325831988397c1E235CC9600E;
    address constant public locker2 = 0xadb07859C50AdD82F716b9F0833DFD815b3b8c34;
    address constant public locker3 = 0x02267e9C1456f80D738176C6627680D255a9146F;

    // Define the struct
struct charity_organization {
    string name;
    string description;
    address ch_add;
    bool accept_donation;
    uint256 totalDonations;
    uint256 totalParticipants;
}

// Struct to represent a donor
struct Donor {
    address donorAddress;
    uint256 donatedAmount;
}

struct DonorInfo {
    address donorAddress;
    uint256 donatedAmount;
}


    charity_organization internal co;
    address[] internal organizationAddressArray;

    struct stakeInfor {
        address stakerAddress;
        uint stakeTime;
        uint amountStaked;
    }

    struct StakingReport {
        uint stakedAmount;
        uint startTime;
        uint endTime;
        uint rewardsEarned;
    }

    // Struct to represent a transfer record
    struct TransferRecord {
    address from;
    address to;
    uint256 amount;
    uint256 timestamp;
    }


// Modifier to apply a burn percentage before a function call
   modifier burntrx(uint amount) {
        amount = amount / 100;
        _;
    }

// Modifier to apply a burn percentage before a function call
     modifier applyBurnPercentage(uint amount) {
        amount = amount / 100;
        _;
    }


// Event to log transfer history
    event TransferRecordEvent(address indexed from, address indexed to, uint256 amount, uint256 timestamp);

    // Array to store staking reports for each user
    mapping(address => StakingReport[]) public stakingReports;

    mapping(address => charity_organization) public ch_org_info;

    mapping(address => uint) public totalDonations;

    mapping(address => uint) public charity_balance;

    mapping(address => stakeInfor) public stakers;

    mapping(address => uint) public donorInfo;

    mapping(address => bool) public isTokenLocked;

    // Mapping to store transfer history
    mapping(address => TransferRecord[]) public transferHistory;

    // Mapping to store donor information for each charity
    mapping(address => Donor[]) public donorsForCharity;


    event Donation(address indexed donor, address indexed organization, uint amount, string message);
    event AddOrganization(string indexed, string indexed, address indexed, bool);
    event Donate(address indexed, uint);
    event Unstaked(address indexed staker, uint totalAmount);
    event Staked(address indexed staker, uint amount);


// Function to get the list of active charities
    function getActiveCharities() external view returns (address[] memory) {
        uint256 activeCharityCount = 0;

        // Count the number of active charities
        for (uint256 i = 0; i < organizationAddressArray.length; i++) {
            if (ch_org_info[organizationAddressArray[i]].accept_donation) {
                activeCharityCount++;
            }
        }

        // Create an array to store active charity addresses
        address[] memory activeCharities = new address[](activeCharityCount);

        // Populate the array with active charity addresses
        uint256 currentIndex = 0;
        for (uint256 i = 0; i < organizationAddressArray.length; i++) {
            if (ch_org_info[organizationAddressArray[i]].accept_donation) {
                activeCharities[currentIndex] = organizationAddressArray[i];
                currentIndex++;
            }
        }

        return activeCharities;
    }

// Function to get the list of donors for a specific active charity
function getDonorsForCharity(address orgAddress) external view returns (DonorInfo[] memory) {
    uint256 donorCount = getNumDonorsForCharity(orgAddress);

    DonorInfo[] memory donors = new DonorInfo[](donorCount);

    for (uint256 i = 0; i < donorCount; i++) {
        Donor memory donor = getDonorForCharity(orgAddress, i);
        donors[i] = DonorInfo(donor.donorAddress, donor.donatedAmount);
    }

    return donors;
}

    // Function to get the number of donors for a specific charity
function getNumDonorsForCharity(address orgAddress) public view returns (uint256) {
    return donorsForCharity[orgAddress].length;
}

// Function to get the total donations for a specific charity
function getTotalDonationsForOrg(address orgAddress) public view returns (uint256) {
    return totalDonations[orgAddress];
}


// Function to check the remaining Airdrop tokens
    function getRemainingAirdropTokens() external view returns (uint256) {
        return balanceOf(airDropwallet);
    }

    // Function to check the remaining Stacking tokens
    function getRemainingStackingTokens() external view returns (uint256) {
        return balanceOf(StackingRewardTokens);
    }




// function to get the contract information
    function getContractInfo() external view returns (uint deploymentTime, uint currentTime ) {
    deploymentTime = deployTime;
    currentTime = block.timestamp;
}

// Function to get transfer history for a specific address
function getTransferHistory(address account) public view returns (TransferRecord[] memory) {
    return transferHistory[account];
}


// Function to get the remaining lock time for a specific locker
function getRemainingLockTime(address locker) public view returns (uint) {
    require(locker == locker1 || locker == locker2 || locker == locker3, "Invalid locker address");

    // Determine the corresponding lock duration and release time for the locker
    uint lockDuration;
    uint lockerDeployTime;

    if (locker == locker1) {
        lockDuration = lockDurationLocker1;
        lockerDeployTime = deployTime;
    } else if (locker == locker2) {
        lockDuration = lockDurationLocker2;
        lockerDeployTime = deployTime;
    } else if (locker == locker3) {
        lockDuration = lockDurationLocker3;
        lockerDeployTime = deployTime;
    }

    // Ensure the locker is currently locked
    require(isTokenLocked[locker], "Locker is not currently locked");

    // Calculate the remaining lock time
    uint currentTime = block.timestamp;
    uint remainingLockTime;

    if (currentTime < lockerDeployTime + lockDuration) {
        remainingLockTime = lockDuration - (currentTime - lockerDeployTime);
    }

    return remainingLockTime;
}

// Event to log the burned amount
event Burned(address indexed account, uint256 amount);

// Mapping to track burned amounts
mapping(address => uint256) private burnedBalances;
uint256 private totalBurnedTokens;

// Function to burn tokens from the owner's address or TokenBurningWallet
function burn(uint256 amount) override public {
    require(_msgSender() == owner() || _msgSender() == TokenBurningWallet, "Not authorized to burn tokens");
    super.burn(amount);

    // Log the burned amount
    emit Burned(_msgSender(), amount);

    // Update the burned balance and total burned tokens
    burnedBalances[_msgSender()] += amount;
    totalBurnedTokens += amount;
}

// Function to burn tokens from a specific account, restricted to owner and TokenBurningWallet
function burnFrom(address account, uint256 amount) public override {
    require(_msgSender() == owner() || _msgSender() == TokenBurningWallet, "Not authorized to burn tokens");
    
    // Burn the tokens directly (since _burnFrom might not be directly available)
    super._burn(account, amount);

    // Log the burned amount
    emit Burned(account, amount);

    // Update the burned balance and total burned tokens
    burnedBalances[account] += amount;
    totalBurnedTokens += amount;
}

// Function to get the total amount of burned tokens for a specific address
function getBurnedTokens(address account) external view returns (uint256) {
    return burnedBalances[account];
}

// Function to get the total amount of burned tokens
function getTotalBurnedTokens() external view returns (uint256) {
    return totalBurnedTokens;
}




// Function to get the total number of stacked tokens across the contract
function getTotalStakedTokens() external view returns (uint256) {
    uint256 totalStackedTokens = 0;

    // Iterate through all staking addresses and sum up the staked amounts
    for (uint256 i = 0; i < stakingAddresses.length; i++) {
        totalStackedTokens += stakers[stakingAddresses[i]].amountStaked;
    }

    return totalStackedTokens;
}


  
// Airdrop function
    function airdrop(address[] memory recipients, uint256 amount) public {
        require(msg.sender == airDropwallet, "Only the airdrop wallet can call this function");
        require(amount > 0, "Airdrop amount must be greater than 0");

        // Ensure that the contract has enough balance for the airdrop
        require(balanceOf(airDropwallet) >= recipients.length * amount, "Insufficient balance for airdrop");

        // Perform the airdrop
        for (uint256 i = 0; i < recipients.length; i++) {
            _transfer(airDropwallet, recipients[i], amount);
        }
    }


// Function to lock a specific locker
function lockLocker(address locker) external onlyOwner {
    require(!isTokenLocked[locker], "Locker is already locked");

    // Ensure that the lock duration has been set for the locker
    uint lockDuration;

    if (locker == locker1) {
        lockDuration = lockDurationLocker1;
    } else if (locker == locker2) {
        lockDuration = lockDurationLocker2;
    } else if (locker == locker3) {
        lockDuration = lockDurationLocker3;
    } else {
        revert("Invalid locker address");
    }

    require(lockDuration > 0, "Lock duration not set for the locker");

    isTokenLocked[locker] = true;  // Set to true to lock the locker
}

// Function to unlock a specific locker
function unlockLocker(address locker) external onlyOwner {
    require(isTokenLocked[locker], "Locker is not locked");

    // Ensure that the lock duration has been set for the locker
    uint lockDuration;

    if (locker == locker1) {
        lockDuration = lockDurationLocker1;
    } else if (locker == locker2) {
        lockDuration = lockDurationLocker2;
    } else if (locker == locker3) {
        lockDuration = lockDurationLocker3;
    } else {
        revert("Invalid locker address");
    }

    require(lockDuration > 0, "Lock duration not set for the locker");

    isTokenLocked[locker] = false;  // Set to false to unlock the locker
}



// Function to set the lock duration for locker1
function setLockDurationLocker1(uint durationInSeconds) external onlyOwner {
    lockDurationLocker1 = durationInSeconds;
}

// Function to set the lock duration for locker2
function setLockDurationLocker2(uint durationInSeconds) external onlyOwner {
    lockDurationLocker2 = durationInSeconds;
}

// Function to set the lock duration for locker3
function setLockDurationLocker3(uint durationInSeconds) external onlyOwner {
    lockDurationLocker3 = durationInSeconds;
}


// Function to get the total locked tokens
function getTotalLockedTokens() external view returns (uint) {
    // Calculate the total locked tokens across all lockers
    uint totalLockedTokens = 0;

    if (isTokenLocked[locker1]) {
        totalLockedTokens += balanceOf(locker1);
    }

    if (isTokenLocked[locker2]) {
        totalLockedTokens += balanceOf(locker2);
    }

    if (isTokenLocked[locker3]) {
        totalLockedTokens += balanceOf(locker3);
    }

    return totalLockedTokens;
}

function getLockDuration(address locker) public view returns (uint) {
        if (locker == locker1) {
            return lockDurationLocker1;
        } else if (locker == locker2) {
            return lockDurationLocker2;
        } else if (locker == locker3) {
            return lockDurationLocker3;
        } else {
            // Return 0 for unknown locker
            return 0;
        }
        }


    // Function to update the staking report when tokens are staked
    function updateStakingReport(uint stakedAmount) internal {
       
       
        // Add your logic here to update the staking report
        StakingReport memory report;
        report.stakedAmount = stakedAmount;
        report.startTime = block.timestamp;
        report.endTime = 0; // Update this when the tokens are unstaked
        report.rewardsEarned = 0; // Initialize rewards earned
        stakingReports[msg.sender].push(report);
    }

    // Function to update the staking report when tokens are unstaked
    function updateUnstakingReport(uint rewardsEarned) internal {
        // Add your logic here to update the staking report when tokens are unstaked
        uint lastIndex = stakingReports[msg.sender].length - 1;
        stakingReports[msg.sender][lastIndex].endTime = block.timestamp;
        stakingReports[msg.sender][lastIndex].rewardsEarned = rewardsEarned;
    }

    function initialize(address initialOwner) initializer public {
    __ERC20_init("KIATOKEN", "KIA");
    __ERC20Burnable_init();
    __Pausable_init();
    __Ownable_init(initialOwner);

    _mint(msg.sender, _totalSupply);
    _transfer(msg.sender, managemenetWallet, 100000000 * 10 ** decimals());
    _transfer(msg.sender, StackingRewardTokens, 100000000 * 10 ** decimals());
    _transfer(msg.sender, airDropwallet, 50000000 * 10 ** decimals());
    _transfer(msg.sender, technicalteam, 100000000 * 10 ** decimals());
    _transfer(msg.sender, privatesales, 50000000 * 10 ** decimals());
    _transfer(msg.sender, publicsales, 50000000 * 10 ** decimals());
    _transfer(msg.sender, liquidity, 50000000 * 10 ** decimals());
    _transfer(msg.sender, locker1, 100000000 * 10 ** decimals());
    _transfer(msg.sender, locker2, 200000000 * 10 ** decimals());
    _transfer(msg.sender, locker3, 200000000 * 10 ** decimals());

    deployTime = block.timestamp;

    // Initialize lock durations and lock release times for the lockers
        lockDurationLocker1 = 0;  // Initially locked, set to 0 seconds
        lockToken1ReleaseTime = deployTime + lockDurationLocker1;

        lockDurationLocker2 = 0;  // Initially locked, set to 0 seconds
        lockToken2ReleaseTime = deployTime + lockDurationLocker2;

        lockDurationLocker3 = 0;  // Initially locked, set to 0 seconds
        lockToken3ReleaseTime = deployTime + lockDurationLocker3;
}
    
    function checkBurn(uint amount) internal pure returns (uint) {
    return amount / 100;
}


// Function to donate
function donate(address org_add, uint amount) public payable {
    require(org_add != address(0), "Invalid charity organization address");
    require(amount > 0, "Donation amount must be greater than 0");

    // Add the donor's address to the list
    if (!isAddressInArray(msg.sender, donatingAddresses)) {
        donatingAddresses.push(msg.sender);
    }

    // Check if the sender is a locker wallet
    require(!isLocker(msg.sender), "Lockers cannot donate");

    charity_organization storage organization = ch_org_info[org_add];
    require(bytes(organization.name).length > 0, "Invalid charity organization");
    require(organization.accept_donation, "This charity organization does not accept donations");

    uint royalty_fees = (amount * royalty) / 100;
    uint donationAmount = amount - royalty_fees;

    // Check if the sender's locker is not locked
    require(!isTokenLocked[msg.sender], "Cannot donate from a locked locker");
    require(balanceOf(msg.sender) >= amount, "Insufficient balance to donate");

    // If the recipient is a charity wallet, emit a warning
    if (isApprovedCharityWallet(org_add)) {
        emit Warning("Warning: Donation to a charity wallet. A royalty fee has been applied.");
    }

    _transfer(msg.sender, org_add, donationAmount);
    _transfer(msg.sender, devTeamwallet, royalty_fees);

    // Update donor recognition
    donorInfo[msg.sender] += donationAmount;

    // Update overall total donated tokens
    overallTotalDonatedTokens += donationAmount;

    // Modify the charity balance and total donations
    charity_balance[org_add] += donationAmount;
    totalDonations[org_add] += donationAmount;

    // Update donor information for the specific charity
    donorsForCharity[org_add].push(Donor({
        donorAddress: msg.sender,
        donatedAmount: donationAmount
    }));

    // Emit the Donation event
    emit Donation(msg.sender, org_add, donationAmount, "Donation received from external source");
    emit Donate(msg.sender, donationAmount);
}

// Function to get the overall total donated tokens
function getOverallTotalDonatedTokens() public view returns (uint256) {
    return overallTotalDonatedTokens;
}

// Function to check if an address is one of the lockers
function isLocker(address wallet) internal pure returns (bool) {
    return wallet == locker1 || wallet == locker2 || wallet == locker3;
}



// Function to get donor information for a specific charity by index
function getDonorForCharity(address orgAddress, uint256 index) public view returns (Donor memory) {
    require(index < donorsForCharity[orgAddress].length, "Invalid index");
    return donorsForCharity[orgAddress][index];
}



function rewardDonor(address donor) internal {
    // Calculate rewards and perform reward logic here
    // You can reward donors based on donation tiers, frequency, or other criteria.
    // For simplicity, this example does not include specific reward logic.
}

function addOrganization(string memory name, string memory description, address ch_addr, bool status) public onlyOwner {
    // Initialize the charity organization with totalDonations and totalParticipants set to 0
    ch_org_info[ch_addr] = charity_organization({
        name: name,
        description: description,
        ch_add: ch_addr,
        accept_donation: status,
        totalDonations: 0,
        totalParticipants: 0
    });

    // Add the organization address to the array
    organizationAddressArray.push(ch_addr);

    // Emit an event to log the addition of the organization
    emit AddOrganization(name, description, ch_addr, status);
}



//function donate

    function donationStatus(address org_add, bool status) public onlyOwner {
        ch_org_info[org_add].accept_donation = status;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal whenNotPaused override {
        super._beforeTokenTransfer(from, to, amount);
    }

function calculateRoyaltyFee(uint256 amount, bool isCharityWallet) internal pure returns (uint256) {
    // Calculate the royalty fee, which is 2% for donations and direct transfers to charity wallets
    uint royaltyFee = isCharityWallet ? (amount * 2) / 100 : 0;
    return royaltyFee;
}

// Function to get the number of stakers
function getNumberOfStakers() public view returns (uint) {
    return stakingAddresses.length;
}

// Function to get the number of donors
function getNumberOfDonors() public view returns (uint) {
    return donatingAddresses.length;
}

// Function to check the number of people in each position
function getNumberOfParticipants() public view returns (uint numberOfStackers, uint numberOfDonors) {
    numberOfStackers = getNumberOfStakers();
    numberOfDonors = getNumberOfDonors();
}


//Approve function
function approve(address spender, uint256 amount) public virtual override returns (bool) {
    require(!isLocker(_msgSender()), "Lockers cannot receive allowance");
    require(!isLocker(spender), "Lockers cannot be given allowance");
    require(spender != StackingRewardTokens, "StackingRewardTokens cannot be approved");
    require(_msgSender() != StackingRewardTokens, "StackingRewardTokens cannot approve other wallets");
    _approve(_msgSender(), spender, amount);
    return true;
}


//function trnasfer

function transfer(address to, uint256 amount) public virtual override burntrx(amount) returns (bool) {
    require(to != address(0), "ERC20: transfer to the zero address");
    require(amount > 0, "Transfer amount must be greater than 0");

    // Check if the recipient is a charity wallet
    bool isCharityWallet = isApprovedCharityWallet(to);

    // If the recipient is a locker wallet, check the lock duration
    if (to == locker1 || to == locker2 || to == locker3) {
        require(!isTokenLocked[to], "Tokens for the locker are still locked");
    }

    // If the sender is a locker wallet, check the lock duration
    if (_msgSender() == locker1 || _msgSender() == locker2 || _msgSender() == locker3) {
        require(!isTokenLocked[_msgSender()], "Tokens for the locker are still locked");
    }

    // Calculate the royalty fee
    uint royaltyFee = calculateRoyaltyFee(amount, isCharityWallet);

    // Ensure the sender has enough balance after deducting the royalty fee
    require(balanceOf(_msgSender()) >= amount, "Insufficient balance for transfer");

    // Deduct the royalty fee and transfer the remaining amount
    uint256 transferAmount = amount - royaltyFee;

    // Transfer the remaining amount
    bool success = super.transfer(to, transferAmount);

    if (success) {
        // Log transfer history
        TransferRecord memory record;
        record.from = msg.sender;
        record.to = to;
        record.amount = transferAmount; // Log the actual transferred amount
        record.timestamp = block.timestamp;

        transferHistory[to].push(record);
        transferHistory[msg.sender].push(record);

        emit TransferRecordEvent(msg.sender, to, transferAmount, block.timestamp);
    }

    // If the recipient is a charity wallet, transfer the royalty fee to the DevTeamwallet
    if (isCharityWallet) {
        emit Warning("Warning: Direct transfer to a charity wallet. A royalty fee has been applied.");
        _transfer(_msgSender(), devTeamwallet, royaltyFee);
    }

    // Update totalDonations for direct transfers to charity wallets (this might not be needed here)
    totalDonations[to] += transferAmount;

    // If the recipient is a charity wallet, update charity_balance
    if (isApprovedCharityWallet(to)) {
        charity_balance[to] += transferAmount;
    }

    return success;
}

//Transferfrom function
// Event to log royalty fee transfers
event RoyaltyFeeTransfer(address indexed sender, address indexed recipient, uint256 royaltyFee);

function transferFrom(address sender, address recipient, uint256 amount) public virtual override burntrx(amount) returns (bool) {
    require(amount > 0, "Transfer amount must be greater than 0");

    // Deduct the allowance
    _spendAllowance(sender, _msgSender(), amount);

    // Log transfer history
    TransferRecord memory record;
    record.from = sender;
    record.to = recipient;
    record.amount = amount;
    record.timestamp = block.timestamp;

    transferHistory[recipient].push(record);
    transferHistory[sender].push(record);

    emit TransferRecordEvent(sender, recipient, amount, block.timestamp);

    // Calculate the royalty fee
    uint royaltyFee = calculateRoyaltyFee(amount, isApprovedCharityWallet(recipient));

    // Deduct the royalty fee
    uint256 transferAmount = amount - royaltyFee;

    // Transfer the royalty fee to the DevTeamwallet
    _transfer(sender, devTeamwallet, royaltyFee);

    // If the recipient is a charity wallet, update charity_balance
    if (isApprovedCharityWallet(recipient)) {
        charity_balance[recipient] += transferAmount;

        // Emit event for debugging
        emit RoyaltyFeeTransfer(sender, recipient, royaltyFee);
    } else {
        // Transfer tokens directly for non-charity recipients
        _transfer(sender, recipient, transferAmount);
    }

    // Update totalDonations for all recipients
    totalDonations[recipient] += transferAmount;

    // Check if the sender is a locker wallet
    if (sender == locker1 || sender == locker2 || sender == locker3) {
        require(isTokenLocked[sender], "Cannot operate with a locked locker");
        require(block.timestamp >= deployTime + getLockDuration(sender), "Tokens for the locker are not yet unlockable");
    }

    // Check if the recipient is a locker wallet
    if (recipient == locker1 || recipient == locker2 || recipient == locker3) {
        require(isTokenLocked[recipient], "Cannot operate with a locked locker");
    }

    // Emit event to log information
    emit TransferFromEvent(sender, recipient, amount);

    return true;
}



// Event to log allowance before transfer
event AllowanceBeforeTransfer(uint256 allowance);

// Event to log balance before transfer
event BalanceBeforeTransfer(uint256 balance);

// Event to log allowance after transfer
event AllowanceAfterTransfer(uint256 newAllowance);



    // Event to log allowance after transfer
event AllowanceAfterTransfer(address indexed owner, address indexed spender, uint256 newAllowance);


   // Event to log information
   event TransferFromEvent(address indexed sender, address indexed recipient, uint256 amount);


   function isApprovedCharityWallet(address wallet) public view returns (bool) {
    // Check if the wallet is one of the approved charity wallets
    return ch_org_info[wallet].accept_donation;
}



    // Staking variables and modifiers
    bool public stakingEnabled;

    modifier onlyWhenStakingEnabled() {
        require(stakingEnabled, "Staking is not currently enabled");
        _;
    }

    function enableStaking() public onlyOwner {
        stakingEnabled = true;
    }

    function disableStaking() public onlyOwner {
        stakingEnabled = false;
    }

    function generateStakingReport() public view returns (StakingReport[] memory) {
        return stakingReports[msg.sender];
    }

    // Declare events
event StakingInitiated(address indexed staker, uint amount);
event UnstakingInitiated(address indexed staker, uint originalAmount, uint rewards);

// Staking function

function stakeToken(uint amount) public onlyWhenStakingEnabled returns (string memory) {
    require(balanceOf(msg.sender) >= 1000 * 10 ** decimals(), "You are not eligible to stake");
    require(amount >= 1000 * 10 ** decimals(), "You are staking less than 1000 tokens");
    require(amount <= 100000 * 10 ** decimals(), "Exceeds maximum staking amount");

    // Add the staker's address to the list
    if (!isAddressInArray(msg.sender, stakingAddresses)) {
        stakingAddresses.push(msg.sender);
    }
   
    // Check if the sender is a locker wallet
    require(!isLocker(msg.sender), "Lockers cannot stake");

    // Deduct the staked amount from the staker's balance
    _transfer(msg.sender, address(this), amount);

    stakers[msg.sender] = stakeInfor(msg.sender, block.timestamp, amount);

    // Create a new staking report
    updateStakingReport(amount);

    // Emit staking event
    emit Staked(msg.sender, amount);

    return "Tokens are staked. You will receive 3 KIA for every 1,000 KIA staked after 1 minute.";
}

function isAddressInArray(address _address, address[] memory _array) internal pure returns (bool) {
    for (uint i = 0; i < _array.length; i++) {
        if (_array[i] == _address) {
            return true;
        }
    }
    return false;
}

//function unstack

function unstakeTokens() public onlyWhenStakingEnabled returns (string memory) {
    require(stakers[msg.sender].amountStaked > 0, "You have not staked any tokens");

    uint stakingDuration = block.timestamp - stakers[msg.sender].stakeTime;
    uint daysStaked = stakingDuration / 1 days; // convert seconds to days

    uint rewardTokens = 0; // Initialize reward tokens

    // Calculate reward tokens if the minimum duration is met
    if (daysStaked >= 1) {
        rewardTokens = (stakers[msg.sender].amountStaked * 2 * daysStaked) / 1000;

        // Update the staking report after unstaking
        updateUnstakingReport(rewardTokens);

        // Transfer the original stake amount back to the staker's wallet
        _transfer(address(this), msg.sender, stakers[msg.sender].amountStaked);

        // Remove the staker's address from the list
        removeAddressFromArray(msg.sender, stakingAddresses);

        // Clear the staker's information
        delete stakers[msg.sender];

        // If rewards were earned, transfer them from StackingRewardTokens
        if (rewardTokens > 0) {
            _transfer(StackingRewardTokens, msg.sender, rewardTokens);
        }

        // Emit unstaking event
        emit Unstaked(msg.sender, stakers[msg.sender].amountStaked + rewardTokens);
        return "Tokens successfully unstaked, and rewards received.";
    } else {
        // If unstaking before the minimum duration, provide a message without rewards
        // Transfer the original stake amount back to the staker's wallet
        _transfer(address(this), msg.sender, stakers[msg.sender].amountStaked);

        // Remove the staker's address from the list
        removeAddressFromArray(msg.sender, stakingAddresses);

        // Clear the staker's information
        delete stakers[msg.sender];

        // Emit unstaking event
        emit Unstaked(msg.sender, stakers[msg.sender].amountStaked);
        return "Tokens successfully unstaked. Note: You did not meet the minimum staking duration, so no rewards were earned.";
    }
}


// Function to remove an address from an array
function removeAddressFromArray(address addr, address[] storage array) internal {
    for (uint i = 0; i < array.length; i++) {
        if (array[i] == addr) {
            // Move the last element to the position of the element to be removed
            array[i] = array[array.length - 1];
            // Remove the last element
            array.pop();
            return;
        }
    }
}
}