//
//  ZHDatePicker.swift
//  HonghaoZ
//
//  Created by Honghao Zhang on 2014-11-21.
//  Copyright (c) 2014 HonghaoZ. All rights reserved.
//

import UIKit

@objc protocol ZHDatePickerDelegate {
    optional func datePickerValueDidChanged(picker: ZHDatePicker)
}

class ZHDatePicker: UIPickerView, UIPickerViewDataSource, UIPickerViewDelegate {
    
    // MARK:- View Related
    class var kPickerFixedHeight: CGFloat { return 216.0 }
    private let rowHeight: CGFloat = 34
    
    // 18000 is divisible with 12, 24 (for the hour) and 60 (for the minutes and seconds)
    // It can still get to the end.. but need continue scroll until to end
    private let numberOfRows: Int = 18000
    private var _numberOfComponents: Int = 3 {
        didSet {
            initPickerRowOffset()
        }
    }
    private func initNumberOfComponents() {
        if is24HourFormat {
            _numberOfComponents = 3
        } else {
            _numberOfComponents = 4
        }
    }
    
    private var componentIndexToDateComponentDict: [Int: DateTimeComponent]!
    private func initComponentIndexToDateComponentDict() {
        componentIndexToDateComponentDict = Dictionary<Int, DateTimeComponent>()
        componentIndexToDateComponentDict[0] = .Date
        if is24HourFormat {
            componentIndexToDateComponentDict[1] = .Hour
            componentIndexToDateComponentDict[2] = .Minute
        } else if isAmpmAfterTime {
            componentIndexToDateComponentDict[1] = .Hour
            componentIndexToDateComponentDict[2] = .Minute
            componentIndexToDateComponentDict[3] = .AMPM
        } else {
            componentIndexToDateComponentDict[1] = .AMPM
            componentIndexToDateComponentDict[2] = .Hour
            componentIndexToDateComponentDict[3] = .Minute
        }
    }
    
    /// Store offset for Date, Hour, Minute rows
    private var pickerRowOffsetDict: [Int: Int]!
    private func initPickerRowOffset() {
        self.pickerRowOffsetDict = Dictionary<Int, Int>()
        for i in 0 ..< _numberOfComponents {
            self.pickerRowOffsetDict[i] = 0
        }
    }
    
    // Font
    var font: UIFont! = UIFont.systemFontOfSize(20) //UIFont(name: "HelveticaNeue-Light", size: 20.0)!
    var textColor: UIColor = UIColor(white: 1.0, alpha: 0.95)
    
    
    // MARK: - NSDate Related
    
    /// initialDate is a helper for calculating text showing on picker
    var initialDate: NSDate!
    
    /// NSDate showing on picker
    var date: NSDate {
        get {
            // Here we are parsing text from picker to a NSDate
            let tempDateFormatter = NSDateFormatter()
            tempDateFormatter.dateFormat = formatStringYear
            // Init string with year
            var dateString: String = tempDateFormatter.stringFromDate(fakeDate)
            
            // Perpare to parse other parts
            if isDateAfterWeekday {
                tempDateFormatter.dateFormat = formatStringYear + " " + formatStringHour + " " +
                    (formatStringWeekday + " " + formatStringMonth + " " + formatStringDay)
                    + " " + formatStringMinute
            } else {
                tempDateFormatter.dateFormat = formatStringYear + " " + formatStringHour + " " +
                    (formatStringMonth + " " + formatStringDay + " " + formatStringWeekday)
                    + " " + formatStringMinute
            }
            
            if is24HourFormat {
                dateString += " " + getTextForRow(getRealRowFromRawRow(self.selectedRowInComponent(1), inComponent: 1), inComponent: 1)
                dateString += " " + getTextForRow(getRealRowFromRawRow(self.selectedRowInComponent(0), inComponent: 0), inComponent: 0)
                dateString += " " + getTextForRow(getRealRowFromRawRow(self.selectedRowInComponent(2), inComponent: 2), inComponent: 2)
            } else {
                tempDateFormatter.dateFormat = tempDateFormatter.dateFormat + " " + formatStringAMPM
                
                if isAmpmAfterTime {
                    dateString += " " + getTextForRow(getRealRowFromRawRow(self.selectedRowInComponent(1), inComponent: 1), inComponent: 1)
                    dateString += " " + getTextForRow(getRealRowFromRawRow(self.selectedRowInComponent(0), inComponent: 0), inComponent: 0)
                    dateString += " " + getTextForRow(getRealRowFromRawRow(self.selectedRowInComponent(2), inComponent: 2), inComponent: 2)
                    dateString += " " + getTextForRow(getRealRowFromRawRow(self.selectedRowInComponent(3), inComponent: 3), inComponent: 3)
                } else {
                    dateString += " " + getTextForRow(getRealRowFromRawRow(self.selectedRowInComponent(2), inComponent: 2), inComponent: 2)
                    dateString += " " + getTextForRow(getRealRowFromRawRow(self.selectedRowInComponent(0), inComponent: 0), inComponent: 0)
                    dateString += " " + getTextForRow(getRealRowFromRawRow(self.selectedRowInComponent(3), inComponent: 3), inComponent: 3)
                    dateString += " " + getTextForRow(getRealRowFromRawRow(self.selectedRowInComponent(1), inComponent: 1), inComponent: 1)
                }
            }
            
            tempDateFormatter.timeZone = timeZone
            return tempDateFormatter.dateFromString(dateString)!
        }
        
        set {
            self.gotoDate(newValue)
        }
    }
    
    /// fakeDate may affects by daylight saving time, may not true date showing on picker
    private var fakeDate: NSDate {
        var timeOffset: NSTimeInterval = 0.0
        for component in 0 ..< self._numberOfComponents {
            // Get real row consider row offset
            let rawRow = self.selectedRowInComponent(component)
            let row = getRealRowFromRawRow(rawRow, inComponent: component)
            var rowOffset: Int = row - getStartRow(component)
            
            timeOffset += getTimeIntervalFromRowOffset(rowOffset, inComponent: component)
        }
        return initialDate.dateByAddingTimeInterval(timeOffset)
    }
    
    var locale: NSLocale? = nil {
        didSet {
            dateFormatter.locale = locale
            self.reloadAllComponents()
        }
    }
    var timeZone: NSTimeZone?
    
    // MARK: - NSDateFormatter Related
    private var dateFormatter =  NSDateFormatter()
    
    private let formatStringYear = "yyyy"
    private let formatStringDate = "ccc MMM d"
    private let formatStringMonth = "MMM"
    private let formatStringDay = "d"
    private let formatStringWeekday = "ccc"
    private var formatStringHour: String { return is24HourFormat ? "H" : "h" }
    private let formatStringMinute = "mm"
    private let formatStringAMPM = "a"
    
    private var is24HourFormat: Bool { return NSLocale.timeIs24HourFormatZH() }
    private var isAmpmAfterTime: Bool { return dateFormatter.isAmpmAfterTimeZH() }
    private var isDateAfterWeekday: Bool { return dateFormatter.isDateAfterWeekdayZH() }
    
    // Calendar Helper, to get hour and min integer for initial date
    enum AMPM: Int {
        case AM = 0
        case PM = 1
    }
    
    let calendar: NSCalendar = NSCalendar.currentCalendar()
    var dateComponent: NSDateComponents {
        return calendar.components(.CalendarUnitHour | .CalendarUnitMinute, fromDate: initialDate)
    }
    
    var initialHour: Int { return dateComponent.hour }
    var initialMinute: Int { return dateComponent.minute }
    var initialAMPM: AMPM {
        if initialHour > 12 {
            return .PM
        } else {
            return .AM
        }
    }
    
    // MARK:- Other variables
    weak var pickerDelegate: ZHDatePickerDelegate?
    
    // MARK:- Init Methods
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    class func datePickerWithMonthSelectionStyle() -> ZHDatePicker {
        let datePicker = self()
        
        // Add Styles
        datePicker.layer.borderColor = UIColor(white: 1.0, alpha: 0.5).CGColor
        datePicker.layer.borderWidth = 1.0
        datePicker.layer.cornerRadius = 4.0
        
        // Add Header Month Selection
        var views = [String: UIView]()
        
        let headerContainerView = UIView()
        headerContainerView.setTranslatesAutoresizingMaskIntoConstraints(false)
        datePicker.addSubview(headerContainerView)
        views["headerContainerView"] = headerContainerView
        
        headerContainerView.userInteractionEnabled = true
        
        datePicker.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[headerContainerView]|", options: NSLayoutFormatOptions(0), metrics: nil, views: views))
        datePicker.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[headerContainerView(40)]", options: NSLayoutFormatOptions(0), metrics: nil, views: views))
        
        let monthIndicatorLabel = UILabel()
        monthIndicatorLabel.setTranslatesAutoresizingMaskIntoConstraints(false)
        headerContainerView.addSubview(monthIndicatorLabel)
        
        monthIndicatorLabel.text = "April 21"//
        monthIndicatorLabel.textColor = UIColor.whiteColor()
        monthIndicatorLabel.font = UIFont.systemFontOfSize(20)
        monthIndicatorLabel.textAlignment = NSTextAlignment.Center
        
        monthIndicatorLabel.setContentCompressionResistancePriority(1000, forAxis: UILayoutConstraintAxis.Horizontal)
        monthIndicatorLabel.setContentCompressionResistancePriority(1000, forAxis: UILayoutConstraintAxis.Vertical)
        monthIndicatorLabel.setContentHuggingPriority(1000, forAxis: UILayoutConstraintAxis.Horizontal)
        monthIndicatorLabel.setContentHuggingPriority(1000, forAxis: UILayoutConstraintAxis.Vertical)
        headerContainerView.addConstraint(NSLayoutConstraint(item: monthIndicatorLabel, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: headerContainerView, attribute: NSLayoutAttribute.CenterX, multiplier: 1.0, constant: 0.0))
        headerContainerView.addConstraint(NSLayoutConstraint(item: monthIndicatorLabel, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: headerContainerView, attribute: NSLayoutAttribute.CenterY, multiplier: 1.0, constant: 0.0))
        
        //
        let backwardButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        backwardButton.setTranslatesAutoresizingMaskIntoConstraints(false)
        views["backwardButton"] = backwardButton
        headerContainerView.addSubview(backwardButton)
        
        backwardButton.titleLabel!.font = UIFont.boldSystemFontOfSize(18)
        backwardButton.setTitle("<", forState: .Normal)
        backwardButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        backwardButton.setTitleColor(UIColor(white: 1.0, alpha: 0.3), forState: UIControlState.Highlighted)
        backwardButton.addTarget(self, action: "backwardMonthButtonTapped:", forControlEvents: UIControlEvents.TouchUpInside)
        headerContainerView.addConstraint(NSLayoutConstraint(item: backwardButton, attribute: NSLayoutAttribute.Leading, relatedBy: NSLayoutRelation.Equal, toItem: headerContainerView, attribute: NSLayoutAttribute.Leading, multiplier: 1.0, constant: 10))
        headerContainerView.addConstraint(NSLayoutConstraint(item: headerContainerView, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: backwardButton, attribute: NSLayoutAttribute.CenterY, multiplier: 1.0, constant: 0.0))
        
        let forwardButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        forwardButton.setTranslatesAutoresizingMaskIntoConstraints(false)
        views["forwardButton"] = forwardButton
        headerContainerView.addSubview(forwardButton)
        
        forwardButton.titleLabel!.font = UIFont.boldSystemFontOfSize(18)
        forwardButton.setTitle(">", forState: .Normal)
        forwardButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        forwardButton.setTitleColor(UIColor(white: 1.0, alpha: 0.3), forState: UIControlState.Highlighted)
        forwardButton.addTarget(self, action: "forwardMonthButtonTapped:", forControlEvents: UIControlEvents.TouchUpInside)
        headerContainerView.addConstraint(NSLayoutConstraint(item: forwardButton, attribute: NSLayoutAttribute.Trailing, relatedBy: NSLayoutRelation.Equal, toItem: headerContainerView, attribute: NSLayoutAttribute.Trailing, multiplier: 1.0, constant: -10))
        headerContainerView.addConstraint(NSLayoutConstraint(item: headerContainerView, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: forwardButton, attribute: NSLayoutAttribute.CenterY, multiplier: 1.0, constant: 0.0))
        
        return datePicker
    }
    
    private func setup() {
        setupViews()
        initOthers()
        
        self.dataSource = self
        self.delegate = self
        
        if initialDate == nil {
            self.gotoCurrentDate()
        } else {
            self.gotoDate(initialDate)
        }
    }
    
    /**
    Extra views setup
    */
    private func setupViews() {
        self.backgroundColor = UIColor.clearColor()
        func createSeparatorLineView() -> UIView {
            let separatorLine = UIView()
            separatorLine.setTranslatesAutoresizingMaskIntoConstraints(false)
            self.addSubview(separatorLine)
            separatorLine.backgroundColor = UIColor.whiteColor()
            separatorLine.addConstraint(NSLayoutConstraint(item: separatorLine, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 0.0, constant: 0.5))
            self.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[separatorLine]|", options: NSLayoutFormatOptions(0), metrics: nil, views: ["separatorLine": separatorLine]))
            return separatorLine
        }
        
        // Add two white cover lines
        let spacing = (ZHDatePicker.kPickerFixedHeight - rowHeight) / 2.0 - 1.5
        
        let topSeparatorLine = createSeparatorLineView()
        self.addConstraint(NSLayoutConstraint(item: topSeparatorLine, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.Top, multiplier: 1.0, constant: spacing))
        
        let bottomSeparatorLine = createSeparatorLineView()
        self.addConstraint(NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: bottomSeparatorLine, attribute: NSLayoutAttribute.Bottom, multiplier: 1.0, constant: spacing))
    }
    
    private func initOthers() {
        self.initNumberOfComponents()
        self.initComponentIndexToDateComponentDict()
    }
    
    func gotoCurrentDate() {
        self.initialDate = NSDate()
        for i in 0 ..< _numberOfComponents {
            self.selectRow(getStartRow(i), inComponent: i, animated: false)
        }
    }
    
    func gotoDate(date: NSDate) {
        self.initialDate = date
        for i in 0 ..< _numberOfComponents {
            self.selectRow(getStartRow(i), inComponent: i, animated: false)
        }
    }
    
    func gotoDateWithMonthOffset(offset: Int) {
        let currentShowingDate = date
        let calendar = NSCalendar.currentCalendar()
        var components = calendar.components(NSCalendarUnit.CalendarUnitYear |  NSCalendarUnit.CalendarUnitMonth | NSCalendarUnit.CalendarUnitDay, fromDate: currentShowingDate)
        components.month += offset
        let resultDate = calendar.dateFromComponents(components)
        
        let interval = resultDate?.timeIntervalSinceDate(currentShowingDate)
        let days: Int = Int(interval!) / (60 * 60 * 24) + (interval > 0 ? 1 : 0)
        self.selectRow(selectedRowInComponent(0) + days, inComponent: 0, animated: true)
        self.pickerDelegate?.datePickerValueDidChanged?(self)
    }
    
    // MARK: Actions
    func backwardMonthButtonTapped(sender: AnyObject) {
        gotoDateWithMonthOffset(-1)
    }
    
    func forwardMonthButtonTapped(sender: AnyObject) {
        gotoDateWithMonthOffset(1)
    }
    
    // MARK: - UIPickerView Data Source
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return _numberOfComponents
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if getDateTimeComponentFromIndex(component) != .AMPM {
            return numberOfRows
        } else {
            return 2
        }
    }
    
    // MARK: - UIPickerView Delegate
    func pickerView(pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return rowHeight
    }
    
    func pickerView(pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        // Create a date which has longest string
        let usFormatter = NSDateFormatter()
        var tempDateString: String!
        if is24HourFormat {
            usFormatter.locale = NSLocale.new24HourLocaleZH()
            usFormatter.dateFormat = "yyyy MMM d, HH:m"
            tempDateString = "2014 Dec 10, 11:11"
        } else {
            usFormatter.locale = NSLocale.new12HourLocaleZH()
            usFormatter.dateFormat = "yyyy MMM d, hh:m a"
            tempDateString = "2014 Dec 10, 11:11 AM"
        }
        
        let tempDate = usFormatter.dateFromString(tempDateString)!
        
        // Set dateFormat
        switch getDateTimeComponentFromIndex(component) {
        case .Date: // Date
            self.dateFormatter.dateFormat = formatStringDate + " "
        case .Hour: // Hour
            self.dateFormatter.dateFormat = isAmpmAfterTime ? "    " : "" + formatStringHour
        case .Minute: // Minute
            self.dateFormatter.dateFormat = "  " + formatStringMinute
        case .AMPM: // AM/PM
            self.dateFormatter.dateFormat = isAmpmAfterTime ? "     " : " " + formatStringAMPM
        default:
            assert(false, "Wrong component")
        }
        
        // Calculate width
        let text = self.dateFormatter.stringFromDate(tempDate)
        var newSize = text.sizeWithAttributes([NSFontAttributeName: self.font])
        return ceil(newSize.width + 10)
    }
    
    // TODO: show "Today"
    func pickerView(pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusingView view: UIView!) -> UIView {
        let realRow = row + pickerRowOffsetDict[component]!
        
        // FIXME: Align to center
        let label = UILabel()
        label.font = self.font
        label.text = getTextForRow(realRow, inComponent: component)
        label.textAlignment = NSTextAlignment.Right
        label.textColor = self.textColor
        return label
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        logOutDate(date)
        
        // Only restore for Date, Hour and Minute
        if getDateTimeComponentFromIndex(component) != .AMPM {
            // Restore to startRow (center row), to make a inifinite picker view
            if row < numberOfRows / 3 {
                pickerRowOffsetDict[component] = pickerRowOffsetDict[component]! + (row - getStartRow(component))
                self.selectRow(getStartRow(component), inComponent: component, animated: false)
            }
            if row > numberOfRows * 2 / 3 {
                pickerRowOffsetDict[component] = pickerRowOffsetDict[component]! + (row - getStartRow(component))
                self.selectRow(getStartRow(component), inComponent: component, animated: false)
            }
        }
        
        self.pickerDelegate?.datePickerValueDidChanged?(self)
    }
    
    // MARK: - Helpers
    
    private func getDateTimeComponentFromIndex(componentIndex: Int) -> DateTimeComponent {
        return self.componentIndexToDateComponentDict[componentIndex]!
    }
    
    private func getStartRow(component: Int) -> Int {
        if getDateTimeComponentFromIndex(component) != .AMPM {
            return numberOfRows / 2
        } else {
            return initialAMPM.rawValue
        }
    }
    
    /**
    Get time interval with rows offset and component index
    
    :param: rowOffset The real row offset, need consider row offset
    :param: component Component index
    
    :returns: Time interval calculated
    */
    func getTimeIntervalFromRowOffset(rowOffset: Int, inComponent component: Int) -> NSTimeInterval {
        
        // Calculate
        var timeOffset: NSTimeInterval = 0.0
        switch getDateTimeComponentFromIndex(component){
        case .Date:
            // Date
            var baseTimeInterval: NSTimeInterval = 24 * 60 * 60
            timeOffset = NSTimeInterval(rowOffset) * baseTimeInterval
        case .Hour:
            // Hour
            var baseTimeInterval: NSTimeInterval = 60 * 60
            timeOffset = NSTimeInterval(((initialHour + rowOffset) % 24 + 24) % 24 - initialHour) * baseTimeInterval
        case .Minute:
            // Minute
            var baseTimeInterval: NSTimeInterval = 60
            timeOffset = NSTimeInterval(((initialMinute + rowOffset) % 60 + 60) % 60 - initialMinute) * baseTimeInterval
        case .AMPM:
            // AM/PM
            var baseTimeInterval: NSTimeInterval = 12 * 60 * 60
            if initialAMPM == .AM {
                if rowOffset < 0 || rowOffset > 1 {
                    assert(false, "Wrong row offset")
                } else {
                    timeOffset = NSTimeInterval(rowOffset) * baseTimeInterval
                }
            } else {
                if rowOffset < -1 || rowOffset > 0 {
                    assert(false, "Wrong row offset")
                } else {
                    timeOffset = NSTimeInterval(rowOffset) * baseTimeInterval
                }
            }
        default:
            assert(false, "Wrong component")
        }
        return timeOffset
    }
    
    func getTextForRow(row: Int, inComponent component: Int) -> String {
        
        func getDateFromRow(row: Int, inComponent component: Int) -> NSDate {
            var rowsOffset: Int = row - getStartRow(component)
            var timeOffset: NSTimeInterval = getTimeIntervalFromRowOffset(rowsOffset, inComponent: component)
            return initialDate.dateByAddingTimeInterval(timeOffset)
        }
        
        let targetDate = getDateFromRow(row, inComponent: component)
        switch getDateTimeComponentFromIndex(component) {
        case .Date:
            dateFormatter.dateFormat = isDateAfterWeekday ? formatStringWeekday + " " + formatStringMonth + " " + formatStringDay : formatStringMonth + " " + formatStringDay + " " + formatStringWeekday
        case .Hour:
            dateFormatter.dateFormat = formatStringHour
        case .Minute:
            dateFormatter.dateFormat = formatStringMinute
        case .AMPM:
            dateFormatter.dateFormat = formatStringAMPM
        default:
            assert(false, "Wrong component")
        }
        return dateFormatter.stringFromDate(targetDate)
    }
    
    /**
    Get real row from raw row
    
    :param: rawRow    rawRow is current selected row (not considering row offset)
    :param: component component index
    
    :returns: row index consider rowOffset
    */
    func getRealRowFromRawRow(rawRow: Int, inComponent component: Int) -> Int {
        return rawRow + pickerRowOffsetDict[component]!
    }
    
    // Debug Related
    func logOutDate(date: NSDate) {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "y ccc LLL d, hh:mm a"
        println("Date: " + dateFormatter.stringFromDate(date))
    }
}

// MARK: Other
enum DateTimeComponent {
    case Date
    case Year
    case Month
    case Day
    case Weekday
    
    case Time
    case Hour
    case Minute
    case AMPM
}

extension NSDateFormatter {
    
    // Returned value is only useful in 12H mode
    func isAmpmAfterTimeZH() -> Bool {
        // Keep original settings
        let originalDateFormat = self.dateFormat
        let originalDateStyle = self.dateStyle
        let originalTimeStyle = self.timeStyle
        
        // Temporarily changes
        self.dateFormat = nil
        self.dateStyle = .NoStyle
        self.timeStyle = .ShortStyle // 3:30pm
        
        // Set minute to 49, avoid confilts with hour number
        let date = NSDate(timeIntervalSince1970: 49 * 60)
        let dateString: NSString = self.stringFromDate(date)
        
        self.dateFormat = "mm"
        let minuteSymbol = self.stringFromDate(date)
        self.dateFormat = "a"
        let ampmSymbol = self.stringFromDate(date)
        
        let minuteRange = dateString.rangeOfString(minuteSymbol)
        let ampmRange = dateString.rangeOfString(ampmSymbol)
        
        // Restore
        self.dateFormat = originalDateFormat
        self.dateStyle = originalDateStyle
        self.timeStyle = originalTimeStyle
        
        return ampmRange.location > minuteRange.location
    }
    
    func isDateAfterWeekdayZH() -> Bool {
        // Keep original settings
        let originalDateFormat = self.dateFormat
        let originalDateStyle = self.dateStyle
        let originalTimeStyle = self.timeStyle
        
        // Temporarily changes
        self.dateFormat = nil
        self.dateStyle = .FullStyle // Tuesday, April 12, 1952 AD
        self.timeStyle = .NoStyle
        
        // Set date to 25, avoid confilts with day number
        let date = NSDate(timeIntervalSince1970: 25 * 24 * 60 * 60)
        let dateString: NSString = self.stringFromDate(date)
        
        self.dateFormat = "d"
        let daySymbol = self.stringFromDate(date)
        self.dateFormat = "EEEE"
        let weekdaySymbol = self.stringFromDate(date)
        
        // Restore
        self.dateFormat = originalDateFormat
        self.dateStyle = originalDateStyle
        self.timeStyle = originalTimeStyle
        
        let dayRange = dateString.rangeOfString(daySymbol)
        let weekdayRange = dateString.rangeOfString(weekdaySymbol)
        return dayRange.location > weekdayRange.location
    }
}

extension NSLocale {
    
    func timeIs24HourFormatZH() -> Bool {
        let formatter: NSDateFormatter = NSDateFormatter()
        formatter.dateStyle = NSDateFormatterStyle.NoStyle
        formatter.timeStyle = NSDateFormatterStyle.ShortStyle
        formatter.locale = self
        
        let dateString: NSString = formatter.stringFromDate(NSDate())
        let amRange = dateString.rangeOfString(formatter.AMSymbol)
        let pmRange = dateString.rangeOfString(formatter.PMSymbol)
        let is24Hour = amRange.location == NSNotFound && pmRange.location == NSNotFound
        return is24Hour
    }
    
    class func timeIs24HourFormatZH() -> Bool {
        return NSLocale.currentLocale().timeIs24HourFormatZH()
    }
    
    class func new12HourLocaleZH() -> NSLocale {
        return NSLocale(localeIdentifier: "en_US_POSIX")
    }
    
    class func new24HourLocaleZH() -> NSLocale {
        return NSLocale(localeIdentifier: "en_GB")
    }
}
