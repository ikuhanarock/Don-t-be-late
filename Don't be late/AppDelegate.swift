//
//  AppDelegate.swift
//  Don't be late
//
//  Created by UCHIDAYUTA on 2016/1/22.
//  Copyright © 2016 YUT. All rights reserved.
//

import UIKit
import CoreLocation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate {

    var window: UIWindow?
    var lm: CLLocationManager!

    var timer: NSTimer!

    let targetLocation = TargetLocation(latitude: NSUserDefaults.standardUserDefaults().doubleForKey("targetLatitudeKey"),
        longitude: NSUserDefaults.standardUserDefaults().doubleForKey("targetLongitudeKey"))

    let currentLocation = CurrentLocation(latitude: 0.0, longitude: 0.0)

    let myConfig = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier("backgroundTask")
    var mySession:NSURLSession? = nil

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.

        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    /// 位置情報取得成功時
    /// 現場近くにいる場合は、サーバーへ位置情報を送信する。
    func locationManager(manager: CLLocationManager, didUpdateToLocation newLocation: CLLocation, fromLocation oldLocation: CLLocation){

        // NSLog("Get Location from AppDelegate")

        currentLocation.latitude = newLocation.coordinate.latitude
        currentLocation.longitude = newLocation.coordinate.longitude

        // 現場から200[m]以内の場合は、処理を中断
        let target: uint = Utils().locationToMeter(
            currentLocation.latitude,
            latitude2: targetLocation.latitude,
            longitude1: currentLocation.longitude,
            longitude2: targetLocation.longitude)

        let formatter = NSDateFormatter()
        formatter.locale = NSLocale(localeIdentifier: "ja_JP")
        formatter.dateFormat = "yyyyMMddHHmm"

        // 今日の現場開始時間を生成
        formatter.dateFormat = "yyyyMMdd"
        let today:String = formatter.stringFromDate(NSDate())
        let time:String = NSUserDefaults.standardUserDefaults().stringForKey("workStartTime") ?? "0000"
        formatter.dateFormat = "yyyyMMddHHmm"
        let workStartTimeAtToday:NSDate = formatter.dateFromString(today + time)!

        // 遅刻になる時間は、現場開始時間の 5分前
        let beInTime: NSDate = NSDate(timeInterval: -5 * 60, sinceDate: workStartTimeAtToday)

        // スヌーズ時間を取得する。
        // let snoozeTime: NSDate = NSUserDefaults.standardUserDefaults().stringForKey("nextAlertDateTime") as? NSDate ?? NSDate()
        let nextAlertDateTimeStr: String = NSUserDefaults.standardUserDefaults().stringForKey("nextAlertDateTime")!
        let snoozeTime: NSDate = formatter.dateFromString(nextAlertDateTimeStr)! ?? NSDate()

        // 通知する条件
        let isSnoozeOn: Bool = NSUserDefaults.standardUserDefaults().boolForKey("isSnoozeOn") ?? true
        var isSetAlerm: Bool = NSUserDefaults.standardUserDefaults().boolForKey("isSetAlerm") ?? true

        // 最終アラーム完了日が今日より前ならアラートをオンにする。
        let prevDoneDate:String = NSUserDefaults.standardUserDefaults().stringForKey("prevDoneDate") ?? "20000101"
        let prevDoneDateTime:NSDate = formatter.dateFromString(prevDoneDate + "2359")!
        let isPastDoneDate: Bool = prevDoneDateTime < NSDate()
        if (isSetAlerm && isPastDoneDate)
        { isSetAlerm = true }
        else
        { isSetAlerm = false }

        let nowDate: NSDate = NSDate()
        // 現在地が現場から200m以上離れていたら True
        let isDistance: Bool = target >= 200
        // 現在時刻が遅刻になる時間を過ぎていたら True
        let isPastBeInTime: Bool = nowDate > beInTime
        // 現在時刻が現場開始時間前なら True
        let isBeforeStart: Bool = nowDate < workStartTimeAtToday
        // 現在時刻がスヌーズ時刻を過ぎていたら True
        let isPastSnoozeTime: Bool = nowDate > snoozeTime

        // アラームを発動するかの判定
        let isAlerm: Bool = isSetAlerm && isPastBeInTime && isBeforeStart
        // ズヌーズを発動するかの判定
        let isSnooze: Bool = isSnoozeOn && isPastSnoozeTime

        // 通知する条件をクリアできない場合、以降の処理を中断する。
        if !( isDistance && ( isAlerm || isSnooze ) ) {
            return
        }

        // アラート中にアラートが重複しないように アラートとスヌーズ をオフにする。
        NSUserDefaults.standardUserDefaults().setObject(false, forKey:"isSnooze")
        NSUserDefaults.standardUserDefaults().setObject(false, forKey:"isSetAlerm")
        NSUserDefaults.standardUserDefaults().synchronize()

        // 現在位置をログ出力
        let log = Utils().formatLocationLog(currentLocation.latitude, longitude: currentLocation.longitude)
        NSLog(log)

        // アラート発動
        let alert = UIAlertController(title:"alert", message: "もう間に合わなくなりますよ。", preferredStyle: UIAlertControllerStyle.Alert)
        // Snooze ボタン生成
        let defaultAction:UIAlertAction = UIAlertAction(title: "Snooze",
                                                        style: UIAlertActionStyle.Default,
                                                        handler:{
                                                            (action:UIAlertAction!) -> Void in
                                                            print("Snooze")
                                                            // スヌーズオン
                                                            NSUserDefaults.standardUserDefaults().setObject(true, forKey:"isSnoozeOn")

                                                            let formatter = NSDateFormatter()
                                                            formatter.locale = NSLocale(localeIdentifier: "ja_JP")
                                                            formatter.dateFormat = "yyyyMMddHHmm"

                                                            // 前回アラート時間
                                                            //let nowDateString = formatter.stringFromDate(NSDate())
                                                            // NSUserDefaults.standardUserDefaults().setObject(nowDateString, forKey:"prevAlertDateTime")
                                                            // 次回アラート時間は、５分後
                                                            let nextDateString = formatter.stringFromDate(NSDate(timeInterval: 5 * 60, sinceDate: NSDate()))
                                                            NSUserDefaults.standardUserDefaults().setObject(nextDateString, forKey:"nextAlertDateTime")

                                                            NSUserDefaults.standardUserDefaults().synchronize()
        })
        // Done ボタン生成
        let cancelAction:UIAlertAction = UIAlertAction(title: "Done",
                                                       style: UIAlertActionStyle.Cancel,
                                                       handler:{
                                                        (action:UIAlertAction!) -> Void in
                                                        print("Alert End")
                                                        // スヌーズオフ
                                                        NSUserDefaults.standardUserDefaults().setObject(false, forKey:"isSnoozeOn")
                                                        // アラートオン
                                                        NSUserDefaults.standardUserDefaults().setObject(true, forKey:"isSetAlerm")

                                                        // 現在日時を最終アラーム完了日として保存する。
                                                        let formatter = NSDateFormatter()
                                                        formatter.locale = NSLocale(localeIdentifier: "ja_JP")
                                                        formatter.dateFormat = "yyyyMMdd"
                                                        let nowDateString = formatter.stringFromDate(NSDate())
                                                        NSUserDefaults.standardUserDefaults().setObject(nowDateString, forKey:"prevDoneDate")

                                                        NSUserDefaults.standardUserDefaults().synchronize()
        })
        alert.addAction(defaultAction)
        alert.addAction(cancelAction)
        self.window?.rootViewController?.presentViewController(alert, animated: true, completion: nil)
    }

    /// 位置情報取得失敗時
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {

        NSLog("位置情報の取得に失敗しました。")

        lm.stopUpdatingLocation()
        lm  = nil
    }

    /// 位置情報使用許可
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {

        switch status {
            case .NotDetermined:
                if lm.respondsToSelector(#selector(CLLocationManager.requestWhenInUseAuthorization))
                {
                    lm.requestWhenInUseAuthorization()
                }
            case .Restricted, .Denied:
                break
            case .Authorized, .AuthorizedWhenInUse:
                break
        }

    }

}

// NSDate大小比較用のオーバーロード
infix operator > {
precedence 20
associativity none
}

func > (leftDate:NSDate, rightDate:NSDate) -> Bool {
    let isGreaterThen: Bool = leftDate.compare(rightDate) == NSComparisonResult.OrderedDescending
    return isGreaterThen
}

infix operator < {
precedence 20
associativity none
}

func < (leftDate:NSDate, rightDate:NSDate) -> Bool {
    let islittlerThen: Bool = leftDate.compare(rightDate) == NSComparisonResult.OrderedAscending
    return islittlerThen
}
