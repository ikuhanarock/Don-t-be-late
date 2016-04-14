//
//  ViewController.swift
//  Don't be late
//
//  Created by UCHIDAYUTA on 2016/1/22.
//  Copyright © 2016 YUT. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

protocol ViewControllerDelegate {
    func initView()
}

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, ViewControllerDelegate {

    var lm: CLLocationManager!

    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate

    var infoBtn: UIButton!
    var getLocationBtn: UIButton!
    let getLocationBtnText = "Get"
    var workStartTimeDatePicker: UIDatePicker!
    var viewsDictionary = [String: AnyObject]()

    var mapView = MKMapView()
    var longtapGesture = UILongPressGestureRecognizer()

    // 現場開始時間設定
    var effectView: UIVisualEffectView!
    var messageLabel: UILabel!
    var submitBtn: UIButton!
    let submitBtnText = "設定"

    override func viewDidLoad() {
        super.viewDidLoad()

        initView()

        // 現場の位置を読み込んでピンをドロップする
        appDelegate.targetLocation.latitude = NSUserDefaults.standardUserDefaults().doubleForKey("targetLatitudeKey")
        appDelegate.targetLocation.longitude = NSUserDefaults.standardUserDefaults().doubleForKey("targetLongitudeKey")

        let mapPoint:CLLocationCoordinate2D = CLLocationCoordinate2DMake(appDelegate.targetLocation.latitude,appDelegate.targetLocation.longitude)
        dropPin(mapPoint)

        // 画面長押し時のイベント購読開始
        self.longtapGesture.addTarget(self, action: #selector(ViewController.longPressed(_:)))
        self.mapView.addGestureRecognizer(self.longtapGesture)
    }

    /// 画面の初期化
    func initView() -> Void {

        // マップ 生成
        self.mapView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height)
        self.mapView.delegate = self
        self.view.addSubview(self.mapView)

        // Infoボタン 生成
        infoBtn = UIButton(type: UIButtonType.InfoDark)
        infoBtn.addTarget(self, action: #selector(ViewController.onClickInfo), forControlEvents: UIControlEvents.TouchUpInside)

        infoBtn.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(infoBtn)
        let infoBtnKey = "infoBtn_layout"
        var vLayoutStr: String
        var hLayoutStr: String
        (vLayoutStr, hLayoutStr) =
            Utils().GenerateAutoLayoutString(
                infoBtnKey,
                pxWidth: 20,
                pxHeight: 20,
                pxTop: 30,
                pxRight: 20)
        viewsDictionary[infoBtnKey] = infoBtn
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat(
            hLayoutStr,
            options: NSLayoutFormatOptions(rawValue: 0),
            metrics: nil,
            views: viewsDictionary))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat(
            vLayoutStr,
            options: NSLayoutFormatOptions(rawValue: 0),
            metrics: nil,
            views: viewsDictionary))
        self.view.addSubview(infoBtn)

        // Getボタン 生成
        getLocationBtn = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        getLocationBtn.backgroundColor = UIColor.orangeColor()
        getLocationBtn.layer.masksToBounds = true
        getLocationBtn.setTitle(getLocationBtnText, forState: .Normal)
        getLocationBtn.layer.cornerRadius = 25.0
        getLocationBtn.addTarget(self, action: #selector(ViewController.onClickGetCurrentLocation(_:)), forControlEvents: .TouchUpInside)

        getLocationBtn.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(getLocationBtn)
        let getBtnKey = "getBtn_layout"
        (vLayoutStr, hLayoutStr) =
            Utils().GenerateAutoLayoutString(
                getBtnKey,
                pxWidth: 50,
                pxHeight: 50,
                pxBottom: 20,
                pxLeft: 20)
        viewsDictionary[getBtnKey] = getLocationBtn
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat(
            hLayoutStr,
            options: NSLayoutFormatOptions(rawValue: 0),
            metrics: nil,
            views: viewsDictionary))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat(
            vLayoutStr,
            options: NSLayoutFormatOptions(rawValue: 0),
            metrics: nil,
            views: viewsDictionary))
        self.view.addSubview(getLocationBtn)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func viewDidAppear(animated: Bool) {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.onOrientationChange(_:)), name: UIDeviceOrientationDidChangeNotification, object: nil)
    }

    /// 端末の向きがかわったら呼び出される
    func onOrientationChange(notification: NSNotification){
        // 再描画
        initView()
    }

    /// Infoボタン押下で呼び出される
    func onClickInfo() {
        let rootViewViewController = SettingsViewController()
        rootViewViewController.delegate = self
        let second:SettingsViewController = rootViewViewController
        self.presentViewController(second, animated: true, completion: nil)
    }

    /// Getボタン押下で呼び出される
    func onClickGetCurrentLocation(sender: UIButton){

        if self.lm == nil {
            self.lm = CLLocationManager()
            self.lm.delegate = self

            let status = CLLocationManager.authorizationStatus()
            if(status == CLAuthorizationStatus.NotDetermined) {
                print("didChangeAuthorizationStatus:\(status)")
                self.lm.requestAlwaysAuthorization()
            }

            self.lm.desiredAccuracy = kCLLocationAccuracyBest
            self.lm.distanceFilter = 100
        }

        self.lm.startUpdatingLocation()
    }

    /// 画面長押し時に呼び出される
    func longPressed(sender: UILongPressGestureRecognizer){

        // 指を離したときだけ反応するようにする
        if(sender.state != .Began){
            return
        }

        let location = sender.locationInView(self.mapView)
        let mapPoint:CLLocationCoordinate2D = self.mapView.convertPoint(location, toCoordinateFromView: self.mapView)

        self.changeWorkplace(mapPoint)
    }

    /// 現場変更処理
    func changeWorkplace(mapPoint: CLLocationCoordinate2D) {

        // 現場の開始時間の入力を促す。
        self.displayWorkStartTime()

        // ピンをドロップする。
        self.dropPin(mapPoint)
    }

    /// 現場の開始時間の入力を促す。
    func displayWorkStartTime() {

        // Blur生成
        effectView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.Light))
        effectView.layer.masksToBounds = true

        effectView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(effectView)
        let effectViewKey = "getEffect_layout"
        var vLayoutStr: String
        var hLayoutStr: String
        (vLayoutStr, hLayoutStr) =
            Utils().GenerateAutoLayoutString(
                effectViewKey,
                pxTop:0,
                pxRight:0,
                pxBottom:0,
                pxLeft:0)
        viewsDictionary[effectViewKey] = effectView
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat(
            hLayoutStr,
            options: NSLayoutFormatOptions(rawValue: 0),
            metrics: nil,
            views: viewsDictionary))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat(
            vLayoutStr,
            options: NSLayoutFormatOptions(rawValue: 0),
            metrics: nil,
            views: viewsDictionary))
        view.addSubview(effectView)

        // メッセージラベル生成
        messageLabel = UILabel()
        messageLabel.text = "現場の開始時間を設定してください。"
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(messageLabel)
        let messageLabelKey = "messageLabel_layout"
        (vLayoutStr, hLayoutStr) =
            Utils().GenerateAutoLayoutString(
                messageLabelKey,
                pxHeight: 50,
                pxTop: 100,
                pxRight: 30,
                pxLeft: 30)
        viewsDictionary[messageLabelKey] = messageLabel
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat(
            hLayoutStr,
            options: NSLayoutFormatOptions(rawValue: 0),
            metrics: nil,
            views: viewsDictionary))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat(
            vLayoutStr,
            options: NSLayoutFormatOptions(rawValue: 0),
            metrics: nil,
            views: viewsDictionary))
        self.view.addSubview(messageLabel)


        // DatePicker生成
        workStartTimeDatePicker = UIDatePicker()
        workStartTimeDatePicker.timeZone = NSTimeZone.systemTimeZone()
        workStartTimeDatePicker.datePickerMode = UIDatePickerMode.Time
        workStartTimeDatePicker.date = NSUserDefaults.standardUserDefaults().objectForKey("workStartTime") as? NSDate ?? NSDate()

        workStartTimeDatePicker.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(workStartTimeDatePicker)
        let dataPickerKey = "getDatePicker_layout"
        (vLayoutStr, hLayoutStr) =
            Utils().GenerateAutoLayoutString(
                dataPickerKey,
                pxHeight: 300,
                pxRight: 30,
                pxBottom: 100,
                pxLeft: 30)
        viewsDictionary[dataPickerKey] = workStartTimeDatePicker
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat(
            hLayoutStr,
            options: NSLayoutFormatOptions(rawValue: 0),
            metrics: nil,
            views: viewsDictionary))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat(
            vLayoutStr,
            options: NSLayoutFormatOptions(rawValue: 0),
            metrics: nil,
            views: viewsDictionary))
        self.view.addSubview(workStartTimeDatePicker)

        // 設定完了ボタン生成
        submitBtn = UIButton(frame: CGRect(x: 0, y: 0, width: 100, height: 60))
        submitBtn.backgroundColor = UIColor.whiteColor()
        submitBtn.layer.masksToBounds = true
        submitBtn.layer.cornerRadius = 5.0
        submitBtn.setTitle(submitBtnText, forState: UIControlState.Normal)
        submitBtn.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
        submitBtn.addTarget(self, action: #selector(ViewController.onClickSubmitBtn), forControlEvents: .TouchUpInside)
        submitBtn.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(submitBtn)
        let getBtn2Key = "getBtn2_layout"
        (vLayoutStr, hLayoutStr) =
            Utils().GenerateAutoLayoutString(
                getBtn2Key,
                pxHeight: 60,
                pxRight: 50,
                pxBottom: 50,
                pxLeft: 50)
        viewsDictionary[getBtn2Key] = submitBtn
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat(
            hLayoutStr,
            options: NSLayoutFormatOptions(rawValue: 0),
            metrics: nil,
            views: viewsDictionary))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat(
            vLayoutStr,
            options: NSLayoutFormatOptions(rawValue: 0),
            metrics: nil,
            views: viewsDictionary))
        self.view.addSubview(submitBtn)
    }

    /// 設定完了ボタン押下時イベント
    /// 入力値を現場開始時間として保存
    func onClickSubmitBtn() {

        messageLabel.hidden = true
        workStartTimeDatePicker.hidden = true
        submitBtn.hidden = true
        effectView.hidden = true

        // 選択した時間を保存する。
        let formatter = NSDateFormatter()
        formatter.locale = NSLocale(localeIdentifier: "ja_JP")
        formatter.dateFormat = "HHmm"
        let pickedDate = formatter.stringFromDate(workStartTimeDatePicker.date)
        NSUserDefaults.standardUserDefaults().setObject(pickedDate, forKey:"workStartTime")

        // ピンの位置を保存する。
        NSUserDefaults.standardUserDefaults().setObject(appDelegate.targetLocation.latitude, forKey:"targetLatitudeKey")
        NSUserDefaults.standardUserDefaults().setObject(appDelegate.targetLocation.longitude, forKey:"targetLongitudeKey")

        // スヌーズをリセットする。
        NSUserDefaults.standardUserDefaults().setObject(false, forKey:"isSnoozeOn")
        NSUserDefaults.standardUserDefaults().setObject(true, forKey:"isSetAlerm")
        NSUserDefaults.standardUserDefaults().setObject("20000101", forKey:"prevDoneDate")

        NSUserDefaults.standardUserDefaults().synchronize()

        // 位置情報取得開始
        if appDelegate.timer == nil {
            appDelegate.timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(ViewController.onUpdateLocation), userInfo: nil, repeats: true)
        }
    }

    /// 地図にピンを配置する
    func dropPin(mapPoint: CLLocationCoordinate2D) {

        let annotation = MKPointAnnotation()

        annotation.coordinate  = mapPoint
        annotation.title       = "workplace"
        annotation.subtitle    = ""
        self.mapView.removeAnnotations(self.mapView.annotations)
        self.mapView.addAnnotation(annotation)

        appDelegate.targetLocation.latitude = mapPoint.latitude
        appDelegate.targetLocation.longitude = mapPoint.longitude

    }

    /// タイマーで呼び出される
    func onUpdateLocation() {
        if appDelegate.lm == nil {
            appDelegate.lm = CLLocationManager()
            appDelegate.lm.delegate = appDelegate

            appDelegate.lm.requestAlwaysAuthorization()
            appDelegate.lm.desiredAccuracy = kCLLocationAccuracyBest
            appDelegate.lm.activityType = CLActivityType.Fitness

            appDelegate.lm.startUpdatingLocation()
        }
    }

    /// 位置情報取得に成功したときに呼び出される
    func locationManager(manager: CLLocationManager, didUpdateToLocation newLocation: CLLocation, fromLocation oldLocation: CLLocation){

        let latitude = newLocation.coordinate.latitude
        let longitude = newLocation.coordinate.longitude

        let mapPoint:CLLocationCoordinate2D = CLLocationCoordinate2DMake(latitude,longitude)
        mapView.setCenterCoordinate(mapPoint, animated: false)

        // 取得した位置へズームする。
        var zoom = mapView.region
        zoom.span.latitudeDelta = 0.005
        zoom.span.longitudeDelta = 0.005
        mapView.setRegion(zoom, animated: true)
        mapView.showsUserLocation = true

        // dropPin(mapPoint)

        self.lm.stopUpdatingLocation()
        self.lm = nil
    }

    /// 位置情報取得に失敗した時に呼び出される
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("error")
    }
}