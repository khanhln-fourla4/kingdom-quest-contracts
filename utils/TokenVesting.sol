// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @title TokenVesting
 */
contract TokenVesting is Context, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // address of the ERC20 token
    IERC20 private immutable _token;
    uint256 private constant _percent = 1000;

    // Note
    address private _beneficiary;
    uint256 private _startTime; // miliseconds
    uint256 private _endTime; // miliseconds
    uint256 private _vestingDuration; // miliseconds
    uint256 private _vestingSlice; // slice of vesting duration
    uint256 private _totalVestingAmount;
    uint256 private _totalVestingReleased;
    uint256 private _totalTGEAmount;
    uint256 private _totalTGEReleased;
    uint256 private _percentTGE;

    event Released(uint256 phase, uint256 amount);
    event EmergencyRevoke(uint256 amount);

    constructor(
        address token,
        address beneficiary,
        uint256 startTime,
        uint256 vestingDuration,
        uint256 vestingSlice,
        uint256 total,
        uint256 percentTGE
    ) {
        _token = IERC20(token);
        _beneficiary = beneficiary;
        _startTime = startTime;
        _vestingDuration = vestingDuration;
        _endTime = startTime + vestingDuration;
        _vestingSlice = vestingSlice;
        _totalTGEAmount = (total * percentTGE) / _percent;
        _totalVestingAmount = total - _totalTGEAmount;
    }

    function releaseTGE(uint256 amount) external nonReentrant {
        uint256 remaining = _totalTGEAmount - _totalTGEReleased;

        require(remaining > 0, "Vesting: released all TGE token");
        require(amount <= remaining, "Vesting: exceed amount remaining");

        _totalTGEReleased += amount;

        _token.safeTransfer(_beneficiary, amount);

        emit Released(0, amount); // TGE is phase 0
    }

    /// @notice Release amount of token by phase
    /// @param amount want to release
    function release(uint256 amount) external nonReentrant {
        uint256 remaining = _totalVestingAmount - _totalVestingReleased;

        require(remaining > 0, "Vesting: released all vesting token");
        require(amount <= remaining, "Vesting: exceed amount remaining");

        uint256 releasableAmount = getVestingReleasableAmountNow();

        require(releasableAmount > 0, "Vesting: nothing to release");
        require(
            amount <= releasableAmount,
            "Vesting: exceed amount releasable"
        );

        _totalVestingReleased += amount;

        _token.safeTransfer(_beneficiary, amount);

        emit Released(getCurrentPhase(), amount);
    }

    function emergengyRevoke(uint256 amount) public onlyOwner  {
        _token.safeTransfer(owner(), amount);
        emit EmergencyRevoke(amount);
    }

    function emergencyRevokeAll() public onlyOwner  {
        uint256 balance = getBalance();
        emergengyRevoke(balance);
    }

    function getVestingReleasableAmountNow() public view returns (uint256) {
        return getVestingReleasableAmount(getTimestamp());
    }

    function getVestingReleasableAmount(uint256 timestamp)
        public
        view
        returns (uint256)
    {
        if (timestamp < _startTime) {
            return 0;
        } else if (timestamp >= _endTime) {
            return _totalVestingAmount - _totalVestingReleased;
        } else {
            uint256 amountPerPhase = getAmountPerPhase();
            uint256 phase = getPhase(timestamp);
            uint256 remaining = _totalVestingAmount - _totalVestingReleased;
            return (amountPerPhase * phase) - (_totalVestingAmount - remaining);
        }
    }

    function getAmountPerPhase() public view returns (uint256) {
        return _totalVestingAmount / _vestingSlice;
    }

    function getCurrentPhase() public view returns (uint256) {
        uint256 timestamp = getTimestamp();

        if (timestamp < _startTime) {
            return 0;
        }

        return getPhase(timestamp);
    }

    function getPhase(uint256 timestamp) public view returns (uint256) {
        uint256 period = _vestingDuration / _vestingSlice;
        return ((timestamp - _startTime) / period) + 1;
    }

    function getTotalVestingAmount() public view returns (uint256) {
        return _totalVestingAmount;
    }

    function getTotalVestingReleased() public view returns (uint256) {
        return _totalVestingReleased;
    }

    function getTotalVestingRemaining() public view returns (uint256) {
        return _totalVestingAmount - _totalVestingReleased;
    }

    function getTotalTGEAmount() public view returns (uint256) {
        return _totalTGEAmount;
    }

    function getTotalTGEReleased() public view returns (uint256) {
        return _totalTGEReleased;
    }

    function getTotalTGERemaining() public view returns (uint256) {
        return _totalTGEAmount - _totalTGEReleased;
    }

    function getTotalAmount() public view returns (uint256) {
        return _totalVestingAmount + _totalTGEAmount;
    }

    function getTotalReleased() public view returns (uint256) {
        return _totalVestingReleased + _totalTGEReleased;
    }

    function getTimeStartPhases() public view returns (uint256[] memory) {
        uint256[] memory starts = new uint256[](_vestingSlice);
        uint256 next = _startTime;
        uint256 period = _vestingDuration / _vestingSlice;
        for (uint256 i = 0; i < starts.length; i++) {
            starts[i] = next;
            next += period;
        }
        return starts;
    }

    function getTimestamp() public view returns (uint256) {
        return block.timestamp * 1000;
    }

    function getBalance() public view returns (uint256) {
        return _token.balanceOf(address(this));
    }
}
