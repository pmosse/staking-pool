// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;


library Date {
    struct _Date {
        uint16 year;
        uint8 month;
        uint8 day;
    }

    uint constant DAY_IN_SECONDS = 86400;
    uint constant YEAR_IN_SECONDS = 31536000;
    uint constant LEAP_YEAR_IN_SECONDS = 31622400;

    uint16 constant ORIGIN_YEAR = 1970;

    function isLeapYear(uint16 year) public pure returns (bool) {
        if (year % 4 != 0) {
                return false;
        }
        if (year % 100 != 0) {
                return true;
        }
        if (year % 400 != 0) {
                return false;
        }
        return true;
    }

    function leapYearsBefore(uint year) public pure returns (uint) {
        year -= 1;
        return year / 4 - year / 100 + year / 400;
    }

    function getDaysInMonth(uint8 month, uint16 year) public pure returns (uint8) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
                return 31;
        }
        else if (month == 4 || month == 6 || month == 9 || month == 11) {
                return 30;
        }
        else if (isLeapYear(year)) {
                return 29;
        }
        else {
                return 28;
        }
    }

    function parseTimestamp(uint timestamp) internal pure returns (_Date memory dt) {
        uint secondsAccountedFor = 0;
        uint buf;
        uint8 i;

        // Year
        dt.year = getYear(timestamp);
        buf = leapYearsBefore(dt.year) - leapYearsBefore(ORIGIN_YEAR);

        secondsAccountedFor += LEAP_YEAR_IN_SECONDS * buf;
        secondsAccountedFor += YEAR_IN_SECONDS * (dt.year - ORIGIN_YEAR - buf);

        // Month
        uint secondsInMonth;
        for (i = 1; i <= 12; i++) {
                secondsInMonth = DAY_IN_SECONDS * getDaysInMonth(i, dt.year);
                if (secondsInMonth + secondsAccountedFor > timestamp) {
                        dt.month = i;
                        break;
                }
                secondsAccountedFor += secondsInMonth;
        }

        // Day
        for (i = 1; i <= getDaysInMonth(dt.month, dt.year); i++) {
                if (DAY_IN_SECONDS + secondsAccountedFor > timestamp) {
                        dt.day = i;
                        break;
                }
                secondsAccountedFor += DAY_IN_SECONDS;
        }
    }

    function getYear(uint timestamp) public pure returns (uint16) {
        uint secondsAccountedFor = 0;
        uint16 year;
        uint numLeapYears;

        // Year
        year = uint16(ORIGIN_YEAR + timestamp / YEAR_IN_SECONDS);
        numLeapYears = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);

        secondsAccountedFor += LEAP_YEAR_IN_SECONDS * numLeapYears;
        secondsAccountedFor += YEAR_IN_SECONDS * (year - ORIGIN_YEAR - numLeapYears);

        while (secondsAccountedFor > timestamp) {
                if (isLeapYear(uint16(year - 1))) {
                        secondsAccountedFor -= LEAP_YEAR_IN_SECONDS;
                }
                else {
                        secondsAccountedFor -= YEAR_IN_SECONDS;
                }
                year -= 1;
        }
        return year;
    }

    function getMonth(uint timestamp) public pure returns (uint8) {
        return parseTimestamp(timestamp).month;
    }

    function getDay(uint timestamp) public pure returns (uint8) {
        return parseTimestamp(timestamp).day;
    }

    function toTimestamp(uint16 year, uint8 month, uint8 day) public pure returns (uint timestamp) {
        uint16 i;

        // Year
        for (i = ORIGIN_YEAR; i < year; i++) {
                if (isLeapYear(i)) {
                        timestamp += LEAP_YEAR_IN_SECONDS;
                }
                else {
                        timestamp += YEAR_IN_SECONDS;
                }
        }

        // Month
        uint8[12] memory monthDayCounts;
        monthDayCounts[0] = 31;
        if (isLeapYear(year)) {
                monthDayCounts[1] = 29;
        }
        else {
                monthDayCounts[1] = 28;
        }
        monthDayCounts[2] = 31;
        monthDayCounts[3] = 30;
        monthDayCounts[4] = 31;
        monthDayCounts[5] = 30;
        monthDayCounts[6] = 31;
        monthDayCounts[7] = 31;
        monthDayCounts[8] = 30;
        monthDayCounts[9] = 31;
        monthDayCounts[10] = 30;
        monthDayCounts[11] = 31;

        for (i = 1; i < month; i++) {
                timestamp += DAY_IN_SECONDS * monthDayCounts[i - 1];
        }

        // Day
        timestamp += DAY_IN_SECONDS * (day - 1);

        return timestamp;
    }
}


contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner || tx.origin == _owner;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b);
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

contract StakingPool is Ownable {
    using SafeMath for uint256;

    IERC20 token;
    uint256 decimals;
    
    uint256 minimumStakeAmount = 1000;
    uint256 public totalStakes = 0;
    uint256 public totalStaked = 0;
    uint256 public adminCanWithdraw = 0;

    struct Stake {
        bool exists;
        uint256 createdOn;
        uint256 initialAmount;
        bool compound;
        uint8 lockupPeriod;
        uint256 withdrawn;
        address referrer;
    }
    
    mapping(address => Stake) public stakes;
    
    uint256 DEFAULT_ROI1 = 2; //0.02% daily ROI
    uint256 DEFAULT_ROI2 = 3; //0.03% daily ROI
    uint256 DEFAULT_ROI3 = 4; //0.04% daily ROI
    uint256 DEFAULT_ROI6 = 5; //0.05% daily ROI

    struct ROI {
        bool exists;
        uint256 roi1;
        uint256 roi2;
        uint256 roi3;
        uint256 roi6;
    }

    //Year to Month to ROI
    mapping (uint256 => mapping (uint256 => ROI)) private rois;
    
    event NewStake(address indexed staker, uint256 totalStaked, uint8 lockupPeriod, bool compound, address referrer);
    event StakeIncreasedForReferral(address indexed staker, uint256 initialAmount, uint256 delta);
    event RewardsWithdrawn(address indexed staker, uint256 total);
    event StakeFinished(address indexed staker, uint256 totalReturned, uint256 fees);

    function _setRoi(uint256 _month, uint256 _year, uint256 _roi1, uint256 _roi2, uint256 _roi3, uint256 _roi6) public onlyOwner {
        require(!rois[_year][_month].exists, "Roi already set");
        
        uint256 today_year = Date.getYear(now);
        uint256 today_month = Date.getMonth(now);
        
        require((_month >= today_month  && _year == today_year) || _year > today_year, "You can only set it for this month or a future month");
        
        rois[_year][_month].exists = true;
        rois[_year][_month].roi1 = _roi1;
        rois[_year][_month].roi2 = _roi2;
        rois[_year][_month].roi3 = _roi3;
        rois[_year][_month].roi6 = _roi6;
    }
    
    function getRoi(uint256 month, uint256 year, uint8 lockupPeriod) public view returns (uint256) {
        if (rois[year][month].exists) {
            if (lockupPeriod == 1) {
                return rois[year][month].roi1;
            }
            else if (lockupPeriod == 2) {
                return rois[year][month].roi2;
            }
            else if (lockupPeriod == 3) {
                return rois[year][month].roi3;
            }
            else if (lockupPeriod == 6) {
                return rois[year][month].roi6;
            }
        }
        
        if (lockupPeriod == 1) {
            return DEFAULT_ROI1;
        }
        else if (lockupPeriod == 2) {
            return DEFAULT_ROI2;
        }
        else if (lockupPeriod == 3) {
            return DEFAULT_ROI3;
        }
        else if (lockupPeriod == 6) {
            return DEFAULT_ROI6;
        }
        
        return 0;
    }
    
    constructor(IERC20 _token) public {
        token = _token;
    }

    function _setMinimumStakeAmount(uint256 _minimumStakeAmount) public onlyOwner {
        minimumStakeAmount = _minimumStakeAmount;
    }

    function getMinimumStakeAmount() public view returns (uint256) {
        return minimumStakeAmount;
    }
    
    function createStake(uint256 _amount, uint8 _lockupPeriod, bool _compound, address _referrer) public {
        require(!stakes[msg.sender].exists, "You already have a stake");
        require(_isValidLockupPeriod(_lockupPeriod), "Invalid lockup period");
        require(_amount >= getMinimumStakeAmount(), "Invalid minimum");
        require(IERC20(token).transferFrom(msg.sender, address(this), _amount * 10 ** decimals), "Couldn't take the tokens");
        
        if (_referrer != address(0) && stakes[_referrer].exists) {
            uint256 amountToIncrease = stakes[_referrer].initialAmount.mul(1).div(100);
            emit StakeIncreasedForReferral(_referrer, stakes[_referrer].initialAmount, amountToIncrease);
            stakes[_referrer].initialAmount += amountToIncrease;
            totalStaked = totalStaked.add(amountToIncrease); 
        }

        Stake memory stake = Stake({exists:true,
                                    createdOn: now, 
                                    initialAmount:_amount, 
                                    compound:_compound, 
                                    lockupPeriod:_lockupPeriod, 
                                    withdrawn:0,
                                    referrer:_referrer
        });
                                    
        stakes[msg.sender] = stake;
        totalStakes = totalStakes.add(1);
        totalStaked = totalStaked.add(_amount);
        
        emit NewStake(msg.sender, _amount, _lockupPeriod, _compound, _referrer);
    }
    
    function finishStake() public {
        require(stakes[msg.sender].exists, "Invalid stake");
        
        Stake memory stake = stakes[msg.sender];
        
        uint256 finishesOn = calculateFinishTimestamp(stake.createdOn, stake.lockupPeriod);
        
        uint256 total;
        uint256 totalToDeduct;
        uint256 penalty;
        
        if (stake.compound) {
            require(now > finishesOn, "Can't be finished yet");
            total = getTotalToWidthdrawForCompounders(msg.sender); //This includes the initial amount
            totalToDeduct = total.mul(2).div(100);
        }
        else {
            if (now > finishesOn) {
                total = getTotalToWidthdrawForNotCompounders(msg.sender);
            }
            else {
                //As it didn't finish, pay a fee of 5% (before first half) or 2% (after first half)
                uint8 penaltyPerc = 5;
                if (_isFirstHalf(stake.createdOn, stake.lockupPeriod)) {
                    penaltyPerc = 2;
                }
                total = getPartialToWidthdrawForNotCompounders(msg.sender, now);
                penalty = total.mul(penaltyPerc).div(100);
                total = total.sub(penalty);
            }
            total = total.add(stake.initialAmount);
            totalToDeduct = total.mul(1).div(100);
        }
        
        totalToDeduct = totalToDeduct.add(penalty);
        //10% of the fees are for the Admin. The rest stays in the contract
        adminCanWithdraw = adminCanWithdraw.add(totalToDeduct.div(10));
        
        totalStakes = totalStakes.sub(1);
        totalStaked = totalStaked.sub(stake.initialAmount);
        delete stakes[msg.sender];

        total = total.sub(totalToDeduct);
        require(token.transfer(msg.sender, total * 10 ** decimals));
        
        emit StakeFinished(msg.sender, total, totalToDeduct);
    }
    
    function _isFirstHalf(uint256 _createdOn, uint8 _lockupPeriod) internal view returns (bool) {
        uint256 day = 60 * 60 * 24;
        
        if (_lockupPeriod == 1) {
            return _createdOn + day.mul(15) > now;
        }
        if (_lockupPeriod == 2) {
            return _createdOn + day.mul(30) > now;
        }
        if (_lockupPeriod == 3) {
            return _createdOn + day.mul(45) > now;
        }
        return _createdOn + day.mul(90) > now;
    }
    
    function withdraw() public {
        require(stakes[msg.sender].exists, "Invalid stake");
        require(!stakes[msg.sender].compound, "Compounders can't withdraw before they finish their stake");

        Stake storage stake = stakes[msg.sender];
        uint256 total = getPartialToWidthdrawForNotCompounders(msg.sender, now);
        stake.withdrawn += total;
        
        require(token.transfer(msg.sender, total * 10 ** decimals));

        emit RewardsWithdrawn(msg.sender, total);
    }
    
    function calcPartialRewardsForInitialMonth(uint256 _initialAmount, uint8 _lockupPeriod, uint8 _todayDay, uint8 _initialDay, uint8 _initialMonth, uint16 _initialYear, bool compounding) internal view returns (uint256) {
        uint256 roi = getRoi(_initialMonth, _initialYear, _lockupPeriod);
        if (compounding) {
            return calcRewardsForMonthComp(_initialAmount, _todayDay - _initialDay, roi);
        }
        return calcRewardsForMonthNotComp(_initialAmount, _todayDay - _initialDay, roi);
    }

    function calcFullRewardsForInitialMonth(uint256 _initialAmount, uint8 _lockupPeriod, uint8 _initialDay, uint8 _initialMonth, uint16 _initialYear, bool compounding) internal view returns (uint256) {
        uint256 totalDays = Date.getDaysInMonth(_initialMonth, _initialYear);
        uint256 roi = getRoi(_initialMonth, _initialYear, _lockupPeriod);
        if (compounding) {
            return calcRewardsForMonthComp(_initialAmount, totalDays.sub(_initialDay), roi);
        }
        return calcRewardsForMonthNotComp(_initialAmount, totalDays.sub(_initialDay), roi);
    }
    
    function calcPartialRewardsForMonth(uint256 currentTotal, uint256 upToDay, uint256 roi, bool compounding) internal pure returns (uint256) {
        if (compounding) {
            return calcRewardsForMonthComp(currentTotal, upToDay, roi);
        }
        return calcRewardsForMonthNotComp(currentTotal, upToDay, roi);
    }

    function calcFullRewardsForMonth(uint256 _currentTotal, uint256 _roi, uint16 _year, uint8 _month, bool compounding) internal pure returns (uint256) {
        uint256 totalDays = Date.getDaysInMonth(_month, _year);
        if (compounding) {
            return calcRewardsForMonthComp(_currentTotal, totalDays, _roi);
        }
        return calcRewardsForMonthNotComp(_currentTotal, totalDays, _roi);
    }
    
    function calcRewardsForMonthComp(uint256 currentTotal, uint256 totalDays, uint256 roi) internal pure returns (uint256) {
        while(totalDays > 10) {
            currentTotal = currentTotal * (roi.add(1000)) ** 10 / 1000 ** 10;
            totalDays -= 10;
        }
        return currentTotal * (roi.add(1000)) ** totalDays / 1000 ** totalDays;
    }
    
    function calcRewardsForMonthNotComp(uint256 currentTotal, uint256 totalDays, uint256 roi) internal pure returns (uint256) {
        return currentTotal.mul(totalDays).mul(roi).div(1000);
    }
    
    //This function is meant to be called internally when finishing your stake
    function getTotalToWidthdrawForNotCompounders(address _account) internal view returns (uint256) {
        Stake memory stake = stakes[_account];
        
        Date._Date memory initial = Date.parseTimestamp(stake.createdOn);
        
        uint256 total = calcFullRewardsForInitialMonth(stake.initialAmount, stake.lockupPeriod, initial.day, initial.month, initial.year, false);
        
        uint256 finishTimestamp = calculateFinishTimestamp(stake.createdOn, stake.lockupPeriod);
        Date._Date memory finishes = Date.parseTimestamp(finishTimestamp);
        
        for(uint8 i=1;i<=stake.lockupPeriod;i++) {
            uint8 currentMonth = initial.month + i;
            uint16 currentYear = initial.year;
            if (currentMonth > 12) {
                currentYear += 1;
                currentMonth = currentMonth % 12;
            }

            uint256 roi = getRoi(currentMonth, currentYear ,stake.lockupPeriod);

            //This is the month it finishes on
            if (currentMonth == finishes.month) {
                total += calcPartialRewardsForMonth(stake.initialAmount, finishes.day, roi, false);
                break;
            }
            
            //This is a complete month I need to add
            total += calcFullRewardsForMonth(stake.initialAmount, roi, currentYear, currentMonth, false);
        }
        
        total = total.sub(stake.withdrawn);
        return total;
    }
    
    //This function is meant to be called internally when withdrawing as much as you can, or by the UI
    function getPartialToWidthdrawForNotCompounders(address _account, uint256 _now) public view returns (uint256) {
        Stake memory stake = stakes[_account];
        
        Date._Date memory initial = Date.parseTimestamp(stake.createdOn);
        Date._Date memory today = Date.parseTimestamp(_now);
        
        //I am still in my first month of staking
        if (initial.month == today.month) {
            uint256 total = calcPartialRewardsForInitialMonth(stake.initialAmount, stake.lockupPeriod, today.day, initial.day, initial.month, initial.year, false);
            total = total.sub(stake.withdrawn);
            return total;
        }
        
        //I am in a month after my first month of staking
        uint256 total = calcFullRewardsForInitialMonth(stake.initialAmount, stake.lockupPeriod, initial.day, initial.month, initial.year, false);
        
        uint256 finishTimestamp = calculateFinishTimestamp(stake.createdOn, stake.lockupPeriod);
        Date._Date memory finishes = Date.parseTimestamp(finishTimestamp);
        
        for(uint8 i=1;i<=stake.lockupPeriod;i++) {
            uint8 currentMonth = initial.month + i;
            uint16 currentYear = initial.year;
            if (currentMonth > 12) {
                currentYear += 1;
                currentMonth = currentMonth % 12;
            }

            uint256 roi = getRoi(currentMonth, currentYear, stake.lockupPeriod);

            //This is the month it finishes
            if (currentMonth == finishes.month) {
                uint8 upToDay = _getMin(finishes.day, today.day);
                total += calcPartialRewardsForMonth(stake.initialAmount, upToDay, roi, false);
                break;
            }
            else if (currentMonth == today.month) { // We reached the current month
                total += calcPartialRewardsForMonth(stake.initialAmount, today.day, roi, false);
                break;
            }
            
            //This is a complete month I need to add
            total += calcFullRewardsForMonth(stake.initialAmount, roi, currentYear, currentMonth, false);
        }
        
        total = total.sub(stake.withdrawn);
        return total;
    }
    
    //This function is meant to be called internal on finishing your stake
    function getTotalToWidthdrawForCompounders(address _account) internal view returns (uint256) {
        Stake memory stake = stakes[_account];
        
        Date._Date memory initial = Date.parseTimestamp(stake.createdOn);
        
        uint256 total = calcFullRewardsForInitialMonth(stake.initialAmount, stake.lockupPeriod, initial.day, initial.month, initial.year, true);
        
        uint256 finishTimestamp = calculateFinishTimestamp(stake.createdOn, stake.lockupPeriod);
        Date._Date memory finishes = Date.parseTimestamp(finishTimestamp);
        
        for(uint8 i=1;i<=stake.lockupPeriod;i++) {
            uint8 currentMonth = initial.month + i;
            uint16 currentYear = initial.year;
            if (currentMonth > 12) {
                currentYear += 1;
                currentMonth = currentMonth % 12;
            }

            uint256 roi = getRoi(currentMonth, currentYear, stake.lockupPeriod);

            //This is the month it finishes on
            if (currentMonth == finishes.month) {
                return calcPartialRewardsForMonth(total, finishes.day, roi, true);
            }
            
            //This is a complete month I need to add
            total = calcFullRewardsForMonth(total, roi, currentYear, currentMonth, true);
        }
    }
    
    //This function is meant to be called from the UI
    function getPartialRewardsForCompounders(address _account, uint256 _now) public view returns (uint256) {
        Stake memory stake = stakes[_account];
        
        Date._Date memory initial = Date.parseTimestamp(stake.createdOn);
        Date._Date memory today = Date.parseTimestamp(_now);
        
        //I am still in my first month of staking
        if (initial.month == today.month) {
            uint256 total = calcPartialRewardsForInitialMonth(stake.initialAmount, stake.lockupPeriod, today.day, initial.day, initial.month, initial.year, true);
            total = total.sub(stake.withdrawn);
            return total;
        }
        
        //I am in a month after my first month of staking
        uint256 total = calcFullRewardsForInitialMonth(stake.initialAmount, stake.lockupPeriod, initial.day, initial.month, initial.year, true);
        
        uint256 finishTimestamp = calculateFinishTimestamp(stake.createdOn, stake.lockupPeriod);
        Date._Date memory finishes = Date.parseTimestamp(finishTimestamp);
        
        for(uint8 i=1;i<=stake.lockupPeriod;i++) {
            uint8 currentMonth = initial.month + i;
            uint16 currentYear = initial.year;
            if (currentMonth > 12) {
                currentYear += 1;
                currentMonth = currentMonth % 12;
            }

            uint256 roi = getRoi(currentMonth, currentYear, stake.lockupPeriod);

            //This is the month it finishes
            if (currentMonth == finishes.month) {
                uint8 upToDay = _getMin(finishes.day, today.day);
                return calcPartialRewardsForMonth(total, upToDay, roi, true);
            }
            else if (currentMonth == today.month) { // We reached the current month
                return calcPartialRewardsForMonth(total, today.day, roi, true);
            }
            
            //This is a complete month I need to add
            total = calcFullRewardsForMonth(total, roi, currentYear, currentMonth, true);
        }
    }
    
    function _getMin(uint8 num1, uint8 num2) internal pure returns (uint8) {
        if (num1 < num2) {
            return num1;
        }
        
        return num2;
    }
    
    function calculateFinishTimestamp(uint256 _timestamp, uint8 _lockupPeriod) public pure returns (uint256) {
        uint16 year = Date.getYear(_timestamp);
        uint8 month = Date.getMonth(_timestamp);
        month += _lockupPeriod;
        if (month > 12) {
            year += 1;
            month = month % 12;
        }
        uint8 day = Date.getDay(_timestamp);
        return Date.toTimestamp(year, month, day);
    }
    
    function _adminWithdraw() public onlyOwner {
        uint256 amount = adminCanWithdraw;
        adminCanWithdraw = 0;
        require(token.transfer(msg.sender, amount * 10 ** decimals));
    }

    function _extractDESTSentByMistake(uint256 amount, address _sendTo) public onlyOwner {
        require(token.transfer(_sendTo, amount * 10 ** decimals));
    }

    function _isValidLockupPeriod(uint8 n) internal pure returns (bool) {
        return n == 1 || n == 2 || n == 3 || n == 6;
    }
}
