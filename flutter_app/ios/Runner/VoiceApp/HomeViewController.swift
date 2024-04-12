//
//  DailScreenVC.swift
//  jetixiOSApp
//
//  Created by Exotel on 08/11/21.
//

import UIKit
import DropDown
import jetixiOS

class HomeViewController: UIViewController, UITextViewDelegate {
    @IBOutlet weak var userNameLbl: UILabel!
    @IBOutlet weak var dailBottomLine: UILabel!
    @IBOutlet weak var recentCallsBottomLine: UILabel!
    @IBOutlet weak var recentCallsHideView: UIView!
    @IBOutlet weak var recentCallsTableView: UITableView!
    @IBOutlet weak var blurView: UIView!
    @IBOutlet weak var dailToTextView: UITextView!
    @IBOutlet weak var reportPrblmView: UIView!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var descriptionTextViewHeight: NSLayoutConstraint!
    @IBOutlet weak var callFeedbackView: UIView!
    @IBOutlet weak var ratingLbl: UILabel!
    @IBOutlet weak var issuesLbl: UILabel!
    let TAG = "HomeViewController"
    
    private let DAY_IN_MS: Double = 1000 * 60 * 60 * 24;
    private let UPLOAD_LOG_NUM_DAYS: Int = 7;
    
    @IBOutlet weak var dropFrameView: UIView!
    let dropDown = DropDown()
    var recentCallsData: [RecentCallDetails] = [RecentCallDetails]()
    let databaseHelper = DatabaseHelper.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        VoiceAppLogger.debug(TAG: TAG, message: "Home View Controller loaded")
        // Do any additional setup after loading the view.
        userNameLbl.text = UserDefaults.Keys.subscriberName.rawValue
        blurView.isHidden = true
        callFeedbackView.isHidden = true
        reportPrblmView.isHidden = true
        dailBottomLine.isHidden = false
        recentCallsBottomLine.isHidden = true
        recentCallsTableView.delegate = self
        recentCallsTableView.dataSource = self
        recentCallsTableView.estimatedRowHeight = 60
        recentCallsTableView.rowHeight = UITableView.automaticDimension
        recentCallsHideView.isHidden = true
        statusBarColorChange()
        descriptionTextView.delegate = self
        descriptionTextView.adjustUITextViewHeight()
        descriptionTextViewHeight.constant = 40
        NotificationCenter.default.addObserver(self, selector: #selector(self.onIncomingCall), name: Notification.Name(rawValue: incomingCallKey), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onCallInitiated), name: Notification.Name(rawValue: initiateCallKey), object: nil)
        
        VoiceAppLogger.zipOlderLogs()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: incomingCallKey), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: initiateCallKey), object: nil)
    }
    
    @objc func onIncomingCall(notification: NSNotification) {
        let call: Call = (notification.object as? Call)!
        
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let incomingVC = storyBoard.instantiateViewController(withIdentifier: "IncomingCallViewController") as! IncomingCallViewController
        
        incomingVC.caller_id = call.getCallDetails().getRemoteId()
        self.navigationController?.pushViewController(incomingVC, animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        dailToTextView.text = ""
    }
    
    func textViewDidChange(_ textView: UITextView) {
        descriptionTextView.adjustUITextViewHeight()
        descriptionTextViewHeight.constant = descriptionTextView.frame.size.height
    }
    
    @IBAction func dailTabBtnAction(_ sender: UIButton) {
        dailBottomLine.isHidden = false
        recentCallsBottomLine.isHidden = true
        recentCallsHideView.isHidden = true
    }
    
    @IBAction func recentCallsTabBtnAction(_ sender: UIButton) {
        dailBottomLine.isHidden = true
        recentCallsBottomLine.isHidden = false
        recentCallsHideView.isHidden = false
        recentCallsData = databaseHelper.getAllData()
        recentCallsTableView.reloadData()
    }
    
    @IBAction func callBtnAction(_ sender: UIButton) {
        self.view.endEditing(true)
        if dailToTextView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true {
            ApiClassConnection.alertDismiss("", message: "No number entered.", view: self)
        } else if UserDefaults.Keys.subscriberName.rawValue == dailToTextView.text {
            ApiClassConnection.alertDismiss("", message: "Cannot dial out to yourself", view: self)
        } else {
            do {
                _ = try VoiceAppService.shared.dial(destination: dailToTextView.text.trimmingCharacters(in: .whitespacesAndNewlines))
            } catch let voiceError as VoiceAppServiceError {
                ApiClassConnection.alertDismiss("", message: voiceError.localizedDescription, view: self)
            } catch {
                ApiClassConnection.alertDismiss("", message: "Failed to Dial", view: self)
            }
        }
    }
    
    @objc func onCallInitiated(notificaiton: NSNotification) {
        let call: Call = notificaiton.object as! Call
        DispatchQueue.main.async {
            let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let dialVC = storyBoard.instantiateViewController(withIdentifier: "CallViewController") as! CallViewController
            dialVC.destinationStr = call.getCallDetails().getRemoteId()
            dialVC.call = call
            self.navigationController?.pushViewController(dialVC, animated: false)
        }
    }
    
    // ToDo
    @IBAction func menuBtnTapped(_ sender: UIButton) {
        dropDown.dataSource = ["Logout", "Report Problem", "SDK Details", "Last Call Feedback", "Account Details", "Enable Debug Dialing", "Disable Debug Dialing"]
        //"Enable Multi-call", "Disable Multi-call"] - Multicall is future implementation.
        dropDown.anchorView = dropFrameView
        dropDown.textFont = UIFont(name: "Roboto-Medium", size: 15)!
        dropDown.bottomOffset = CGPoint(x: 0, y: sender.frame.size.height)
        dropDown.show()
        dropDown.selectionAction = { [weak self] (index: Int, item: String) in
            guard let _ = self else { return }
            switch index {
            case 0:
                UserDefaults.standard.reset()
                VoiceAppService.shared.reset()
                self?.navigationController?.popViewController(animated: false)
                
            case 1:
                self?.blurView.isHidden = false
                self?.reportPrblmView.isHidden = false
                self?.descriptionTextView.text = ""
                
            case 2:
                ApiClassConnection.alert("SDK details", message: "\(VoiceAppService.shared.getVerionDetails())", view: self!)
            case 3:
                self?.blurView.isHidden = false
                self?.callFeedbackView.isHidden = false
                self?.ratingLbl.text = "5"
                self?.issuesLbl.text = "NO_ISSUE"
            case 4:
                self?.showAccountDetails()
            case 5:
                UserDefaults.standard.set(true, forKey: UserDefaults.Keys.enableDebugDialing.rawValue)
            case 6:
                UserDefaults.standard.set(false, forKey: UserDefaults.Keys.enableDebugDialing.rawValue)
            default:
                print("Have you done something new?")
            }
        }
    }
    
    @IBAction func reportPrblmOkBtnAction(_ sender: UIButton) {
        let endDate = Date()
        let startDate = Date(timeInterval: -(Double(UPLOAD_LOG_NUM_DAYS) * DAY_IN_MS), since: endDate)
        
        var description = "Something went wrong!"
        if !descriptionTextView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            description = descriptionTextView.text
        }
        VoiceAppService.shared.uploadLogs(startDate: startDate, endDate: endDate, description: description)
        blurView.isHidden = true
        reportPrblmView.isHidden = true
        self.view.endEditing(true)
    }
    
    @IBAction func reportPrblmCancelBtnAction(_ sender: UIButton) {
        blurView.isHidden = true
        reportPrblmView.isHidden = true
        self.view.endEditing(true)
    }
    
    @IBAction func ratingBtnAction(_ sender: UIButton) {
        dropDown.dataSource = ["1", "2", "3", "4", "5"]
        dropDown.anchorView = sender
        dropDown.textFont = UIFont(name: "Roboto-Medium", size: 15)!
        dropDown.bottomOffset = CGPoint(x: 0, y: sender.frame.size.height)
        dropDown.show()
        dropDown.selectionAction = { [weak self] (index: Int, item: String) in
            guard let _ = self else { return }
            self?.ratingLbl.text = item
        }
    }
    
    @IBAction func issuesBtnAction(_ sender: UIButton) {
        dropDown.dataSource = ["NO_ISSUE", "ECHO", "NO_AUDIO", "HIGH_LATENCY", "CHOPPY_AUDIO", "BACKGROUND_NOISE"]
        dropDown.textFont = UIFont(name: "Roboto-Medium", size: 15)!
        dropDown.anchorView = sender
        dropDown.bottomOffset = CGPoint(x: 0, y: sender.frame.size.height)
        dropDown.show()
        dropDown.selectionAction = { [weak self] (index: Int, item: String) in
            guard let _ = self else { return }
            self?.issuesLbl.text = item
        }
    }
    
    @IBAction func callFeedbackCancelBtnAction(_ sender: UIButton) {
        blurView.isHidden = true
        callFeedbackView.isHidden = true
    }
    
    @IBAction func callFeedbackOkBtnAction(_ sender: UIButton) {
        blurView.isHidden = true
        callFeedbackView.isHidden = true
    }
    
    func showAccountDetails() {
        ApiClassConnection.alert("Account Details:", message: "\nSubscriber Name: \(UserDefaults.Keys.subscriberName.rawValue) \nAccount SID: \(UserDefaults.Keys.accountSID.rawValue) \nBase URL: \(UserDefaults.Keys.hostName.rawValue)", view: self)
    }
}

extension HomeViewController : UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return recentCallsData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = recentCallsTableView.dequeueReusableCell(withIdentifier: "RecentCallsCell", for: indexPath) as! RecentCallsCell
        let indexRow = indexPath.row
        cell.phoneNoLbl.text = recentCallsData[indexRow].getRemoteId()
        cell.callTypeLbl.text = CallType.stringFromEnum(callType: recentCallsData[indexRow].getCallType())
        cell.dateTimeLbl.text = recentCallsData[indexRow].getTime()
        cell.callBtn.tag = indexRow
        cell.callBtn.addTarget(self, action: #selector(onCallBtnTapped(sender:)), for: .touchUpInside)
        return cell
    }
    
    // ToDo:
    @objc func onCallBtnTapped(sender:UIButton){
        do {
            let destination = recentCallsData[sender.tag].getRemoteId()
            _ = try VoiceAppService.shared.dial(destination: destination)
        } catch let voiceError as VoiceAppServiceError {
            ApiClassConnection.alertDismiss("", message: voiceError.localizedDescription, view: self)
        } catch {
            ApiClassConnection.alertDismiss("", message: "Failed to Dial", view: self)
        }
    }
}
