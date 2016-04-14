//
//  File.swift
//  Don't be late
//
//  Created by UCHIDAYUTA on 2016/1/22.
//  Copyright © 2016 YUT. All rights reserved.
//

import Foundation
import MapKit

protocol LocationProtocol {
    var name: String { get set }
    var latitude: Double { get set }
    var longitude: Double { get set }
}

class Location: LocationProtocol {
    var name = "(none)"
    var latitude = 0.0
    var longitude = 0.0

    init(latitude: Double?, longitude: Double?) {
        self.name = "(none)"
        self.latitude = latitude ?? 0.0
        self.longitude = longitude ?? 0.0
    }

    init(name:String, latitude: Double?, longitude: Double?) {
        self.name = name
        self.latitude = latitude ?? 0.0
        self.longitude = longitude ?? 0.0
    }
}

class CurrentLocation : Location {
    override init(latitude: Double?, longitude: Double?) {
        super.init(name: "Current Location", latitude: latitude!, longitude: longitude!)
    }
}

class TargetLocation : Location {

}

class Utils {

    /// ログ出力フォーマットに変換する。
    func formatLocationLog(latitude: CLLocationDegrees!, longitude: CLLocationDegrees!)-> String {

        let now = NSDate()
        let dateFormatter = NSDateFormatter()
        dateFormatter.locale = NSLocale(localeIdentifier: "ja_JP")
        dateFormatter.timeStyle = .MediumStyle
        dateFormatter.dateStyle = .MediumStyle
        let time = dateFormatter.stringFromDate(now)

        if latitude != nil && longitude != nil {
            return "\(time) latiitude: \(latitude) , longitude: \(longitude) \n"
        } else {
            let errMsg = "位置情報の取得に失敗しました。\n"
            return "\(time) \(errMsg)"
        }
    }

    /// CLLocationDegress から Meter に変換する。
    func locationToMeter(latitude1: CLLocationDegrees, latitude2: CLLocationDegrees?, longitude1: CLLocationDegrees, longitude2: CLLocationDegrees?)-> uint {

        let latitude3 = latitude2 ?? 0.0
        let longitude3 = longitude2 ?? 0.0

        let meter1 = pow((latitude1 - latitude3) / 0.0111, 2.0)
        let meter2 = pow((longitude1 - longitude3) / 0.0091, 2.0)
        let meter = sqrt(meter1 + meter2) * 1000
        return UInt32(meter)
    }

    /// AutoLayout を設定する。
    func GenerateAutoLayoutString(objecName: String, pxWidth: Int? = nil, pxHeight: Int? = nil, pxTop: Int? = nil, pxRight: Int? = nil, pxBottom: Int? = nil, pxLeft: Int? = nil) -> (String, String) {

        let topStr: String = pxTop != nil ? "-\(pxTop!)-" : "-"
        let rightStr: String = pxRight != nil ? "-\(pxRight!)-" : "-"
        let bottomStr: String = pxBottom != nil ? "-\(pxBottom!)-" : "-"
        let leftStr: String = pxLeft != nil ?  "-\(pxLeft!)-" : "-"
        let heightStr: String = pxHeight != nil ?  "(\(pxHeight!))" : ""
        let widthStr: String = pxWidth != nil ?  "(\(pxWidth!))" : ""

        let VautoLayoutStr: String = "V:|" + topStr + "[" + objecName + heightStr + "]" + bottomStr + "|"
        let HautoLayoutStr: String = "H:|" + leftStr + "[" + objecName + widthStr + "]" + rightStr + "|"

        return (VautoLayoutStr, HautoLayoutStr)
    }

}
