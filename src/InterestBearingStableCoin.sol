// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


// AMS - This is the end of the chronicle code

/**
 * @title OracleReader
 * @notice A simple contract to read from Chronicle oracles
 * @dev To see the full repository, visit https://github.com/chronicleprotocol/OracleReader-Example.
 * @dev Addresses in this contract are hardcoded for the Sepolia testnet.
 * For other supported networks, check the https://chroniclelabs.org/dashboard/oracles.
 */
contract OracleReader {
    /**
    * @notice The Chronicle oracle to read from.
    * Chronicle_ETH_USD_3:0xdd6D76262Fd7BdDe428dcfCd94386EbAe0151603
    * Network: Base Sepolia
    */

    IChronicle public chronicle = IChronicle(address(0xCf2aF249b2d71B33339B9613E78f8D1B7F9eeE83));

    /** 
    * @notice The SelfKisser granting access to Chronicle oracles.
    * SelfKisser_1:0x0Dcc19657007713483A5cA76e6A7bbe5f56EA37d
    * Network: Base Sepolia
    */
    ISelfKisser public selfKisser = ISelfKisser(address(0x70E58b7A1c884fFFE7dbce5249337603a28b8422));

    constructor() {
        // Note to add address(this) to chronicle oracle's whitelist.
        // This allows the contract to read from the chronicle oracle.
        selfKisser.selfKiss(address(chronicle));
    }

    /** 
    * @notice Function to read the latest data from the Chronicle oracle.
    * @return val The current value returned by the oracle.
    * @return age The timestamp of the last update from the oracle.
    */
    function read() external view returns (uint256 val, uint256 age) {
        (val, age) = chronicle.readWithAge();
    }
}

// Copied from [chronicle-std](https://github.com/chronicleprotocol/chronicle-std/blob/main/src/IChronicle.sol).
interface IChronicle {
    /** 
    * @notice Returns the oracle's current value.
    * @dev Reverts if no value set.
    * @return value The oracle's current value.
    */
    function read() external view returns (uint256 value);

    /** 
    * @notice Returns the oracle's current value and its age.
    * @dev Reverts if no value set.
    * @return value The oracle's current value using 18 decimals places.
    * @return age The value's age as a Unix Timestamp .
    * */
    function readWithAge() external view returns (uint256 value, uint256 age);
}

// Copied from [self-kisser](https://github.com/chronicleprotocol/self-kisser/blob/main/src/ISelfKisser.sol).
interface ISelfKisser {
    /// @notice Kisses caller on oracle `oracle`.
    function selfKiss(address oracle) external;
}










// AMS - This is the end of the chronicle code



interface IOracle {
    function getInterestRate() external view returns (uint256); // Annual interest rate in basis points (bps)
}

interface IDEX {
    function swapTokens(address from, address to, uint256 amount) external returns (uint256);
}

contract InterestBearingStablecoin is Ownable {
    struct Deposit {
        uint256 stethAmount;
        uint256 depositTime;
    }

    IERC20 public usdc;
    IERC20 public steth;
    IOracle public oracle;
    IDEX public dex;

    mapping(address => Deposit) public deposits;

    event Deposited(address indexed user, uint256 usdcAmount, uint256 stethAmount);
    event Withdrawn(address indexed user, uint256 usdcAmount, uint256 interest);

    constructor(
        address _usdc,
        address _steth,
        address _oracle,
        address _dex

    ) Ownable(msg.sender) { // Pass msg.sender as the initial owner
        usdc = IERC20(_usdc);
        steth = IERC20(_steth);
        oracle = IOracle(_oracle);
        dex = IDEX(_dex);
    }

    /**
     * @dev Deposit USDC and convert to STETH.
     */
    function depositUSDC(uint256 usdcAmount) external {
        require(usdcAmount > 0, "Amount must be greater than zero");

        // Transfer USDC from user to contract
        require(usdc.transferFrom(msg.sender, address(this), usdcAmount), "USDC transfer failed");

        // Swap USDC for STETH using a DEX
        uint256 stethAmount = dex.swapTokens(address(usdc), address(steth), usdcAmount);

        // Record deposit details
        deposits[msg.sender] = Deposit({
            stethAmount: stethAmount,
            depositTime: block.timestamp
        });

        emit Deposited(msg.sender, usdcAmount, stethAmount);
    }

    /**
     * @dev Withdraw USDC with interest.
     */
    function withdraw() external {
        Deposit storage userDeposit = deposits[msg.sender];
        require(userDeposit.stethAmount > 0, "No active deposit");

        // Calculate time elapsed
        uint256 timeElapsed = block.timestamp - userDeposit.depositTime;

        // Get annual interest rate from oracle (e.g., in bps)
        uint256 interestRate = oracle.getInterestRate();
        uint256 interest = calculateInterest(userDeposit.stethAmount, timeElapsed, interestRate);

        // Swap STETH back to USDC
        uint256 usdcAmount = dex.swapTokens(address(steth), address(usdc), userDeposit.stethAmount);

        // Add interest to USDC amount
        uint256 totalPayout = usdcAmount + interest;

        // Clear user deposit
        delete deposits[msg.sender];

        // Transfer USDC to user
        require(usdc.transfer(msg.sender, totalPayout), "USDC transfer failed");

        emit Withdrawn(msg.sender, usdcAmount, interest);
    }

    /**
     * @dev Helper to calculate interest.
     * @param principal Amount in STETH.
     * @param timeElapsed Time since deposit (in seconds).
     * @param annualRate Annual interest rate in bps.
     */
    function calculateInterest(
        uint256 principal,
        uint256 timeElapsed,
        uint256 annualRate
    ) public pure returns (uint256) {
        uint256 timeInYears = timeElapsed * 1e18 / 365 days; // Convert to fixed-point years
        uint256 rate = annualRate * 1e12 / 10_000; // Convert bps to fixed-point rate
        return (principal * rate * timeInYears) / 1e18; // Fixed-point interest
    }

    /**
     * @dev Set new oracle address (Owner only).
     */
    function setOracle(address _oracle) external onlyOwner {
        oracle = IOracle(_oracle);
    }

    /**
     * @dev Set new DEX address (Owner only).
     */
    function setDex(address _dex) external onlyOwner {
        dex = IDEX(_dex);
    }
}
