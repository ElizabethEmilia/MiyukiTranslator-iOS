//
//  ViewController.swift
//  Translator-iOS
//
//  Created by Zhixun Liu on 2020/12/31.
//

import UIKit
import WebKit

class ViewController: UIViewController {

    @IBOutlet weak var resultDisplay: WKWebView!
    
    @IBOutlet weak var navBar: UINavigationBar!
    
    var storedStringInPasteBoard: String = "";
    
    var shouldUpdateUI = false;
    var occursError = false;
    var isDictionaryResult = false;
    var dictResultHTML = "";
    var errorMsg = "";
    
    var translatedResultToUpdate = "";
    var textToTranslateToUpdate = "";
    var lastPasteboardCount = 0
    
    func lookupDictionary(word: String) {
        _ = lookupDictionaryAsync(word: word, onComplete: {
            (html: String) in
            self.isDictionaryResult = true
            self.dictResultHTML = html
            self.shouldUpdateUI = true
        }, onError: {
            (code: Int, msg: String) in
            print("Dictionary: code=\(code)  message=\(msg)")
            self.translateWithBaidu(str: word, strToShow: word, langTo: "zh")
        })
    }
    
    func translateWithBaidu(str: String, strToShow: String, langTo: String) {
        translateUsingBaiduTranslateAPIAsync(textToTranslate: str, langFrom: "auto", langTo: langTo, appID: UserDefaults.standard.string(forKey: KEY_APP_ID), appKey: UserDefaults.standard.string(forKey: KEY_APP_KEY),
            onComplete: { (ret: String) in
                let translatedResult = ret.replacingOccurrences(of: "<", with: "&lt;")
                        .replacingOccurrences(of: ">", with: "&gt;")
                self.textToTranslateToUpdate = strToShow
                self.translatedResultToUpdate = translatedResult
                self.shouldUpdateUI = true
            },
        
        // handle error
        onError: { (errCode: Int, errmsg: String) in
            var errorMessage = errmsg
            if errmsg == "UNAUTHORIZED USER" {
                errorMessage = NSLocalizedString("error.unauthorizedUser", comment: "")
            }
            else if errmsg == "Invalid Sign" {
                errorMessage = NSLocalizedString("error.invalidSign", comment: "")
            }
            self.textToTranslateToUpdate = strToShow
            self.translatedResultToUpdate = ""
            self.errorMsg = errorMessage
            self.occursError = true
            self.shouldUpdateUI = true
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup the navigation bar and UI color
        navBar.frame = navBar.frame.offsetBy(dx: 0, dy: UIApplication.shared.windows.first?.windowScene?.statusBarManager?.statusBarFrame.size.height ?? 0)
        
        resultDisplay.frame = resultDisplay.frame.offsetBy(dx: 0, dy: UIApplication.shared.windows.first?.windowScene?.statusBarManager?.statusBarFrame.size.height ?? 0)
        
        resultDisplay.backgroundColor = .clear
        let bgToolbar: UIToolbar = UIToolbar(frame: resultDisplay.frame)
        bgToolbar.barStyle = .default
        resultDisplay.superview?.insertSubview(bgToolbar, belowSubview: resultDisplay)
        
        self.navBar.delegate = self
        navBar.translatesAutoresizingMaskIntoConstraints = false
        navBar.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        navBar.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        navBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        
        let mainFrontColor = self.traitCollection.userInterfaceStyle == .light ? "#000" : "#fff"
        let mainBackColor = self.traitCollection.userInterfaceStyle == .light ? "#fff" : "#111"
        
        // Initialize user defaults
        print("Enterring configure setting...")
        let defaults = UserDefaults.standard;
        print("done)")
        if (defaults.object(forKey: KEY_APP_ID) == nil) {
            defaults.setValue("", forKey: KEY_APP_ID)
        }
        if (defaults.object(forKey: KEY_APP_KEY) == nil) {
            defaults.setValue("", forKey: KEY_APP_KEY)
        }
        if (defaults.object(forKey: KEY_TRANSLATE_INTO) == nil) {
            defaults.setValue(0, forKey: KEY_TRANSLATE_INTO)
        }
        if (defaults.object(forKey: KEY_WHEN_MEET_CHINESE_CHARACTER) == nil) {
            defaults.setValue(0, forKey: KEY_WHEN_MEET_CHINESE_CHARACTER)
        }
        if (defaults.object(forKey: KEY_LOOKUP_DICT) == nil) {
            defaults.setValue(true, forKey: KEY_LOOKUP_DICT)
            print("set default KEY_LOOKUP_DICT to: \( defaults.bool(forKey: KEY_LOOKUP_DICT) )")
        }
        
        if (defaults.string(forKey: KEY_APP_ID) == "") {
            defaults.setValue("20160628000024160", forKey: KEY_APP_ID)
        }
        if (defaults.string(forKey: KEY_APP_KEY) == "") {
            defaults.setValue("835JS22N3C2PA4Brrrwo", forKey: KEY_APP_KEY)
        }
        
        // Load initial screen
        resultDisplay.backgroundColor = UIColor.clear;
        let welcomeHTML = ui_template__main_page(backgroundColor: mainBackColor)
        resultDisplay.loadHTMLString(welcomeHTML, baseURL: nil)
        
        // Timer to update UI
        Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { (t) in
            if !self.shouldUpdateUI {
                return
            }
            self.shouldUpdateUI = false
            // check theme
            let mainFrontColor = self.traitCollection.userInterfaceStyle == .light ? "#000" : "#fff"
            let mainBackColor = self.traitCollection.userInterfaceStyle == .light ? "#fff" : "#111"
            let fontColor = self.traitCollection.userInterfaceStyle == .light ? "#000" : "#fff"
            let backColor = self.traitCollection.userInterfaceStyle == .light ? "(200,200,200,0.2)" : "(255,255,255,0.2)"
            
            if self.occursError {
                self.occursError = false
                let resultHTML = ui_template__process_info(backColor: backColor, fontColor: fontColor, backgroundColor: mainBackColor, originalText: self.textToTranslateToUpdate, title: NSLocalizedString("title.error", comment: ""), message: self.errorMsg)
                self.resultDisplay.loadHTMLString(resultHTML, baseURL: nil)
            }
            else if self.isDictionaryResult {
                self.isDictionaryResult = false
                let resultHTML = ui_template__dictionary_result(htmlString: self.dictResultHTML, backColor: backColor, fontColor: fontColor, backgroundColor: mainBackColor)
                print(resultHTML)
                self.resultDisplay.loadHTMLString(resultHTML, baseURL: nil)
            }
            else {
                let resultHTML = ui_template_display_result(backColor: backColor, fontColor: fontColor, backgroundColor: mainBackColor, originalText: self.textToTranslateToUpdate, resultText: self.translatedResultToUpdate)
                self.resultDisplay.loadHTMLString(resultHTML, baseURL: nil)
            }
        }
        
        // Set timer to check clipbpard
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { (t) in
            let pccount = UIPasteboard.general.changeCount
            if self.lastPasteboardCount == pccount {
                return
            }
            self.lastPasteboardCount = pccount
            // read from clipboard
            let strInPasteboard = UIPasteboard.general.string
            if let str = strInPasteboard {
                if str == "" {
                    return
                }
                // check theme
                let mainFrontColor = self.traitCollection.userInterfaceStyle == .light ? "#000" : "#fff"
                let mainBackColor = self.traitCollection.userInterfaceStyle == .light ? "#fff" : "#111"
                let fontColor = self.traitCollection.userInterfaceStyle == .light ? "#000" : "#fff"
                let backColor = self.traitCollection.userInterfaceStyle == .light ? "(200,200,200,0.2)" : "(255,255,255,0.2)"
                
                self.storedStringInPasteBoard = str;
                let strToShow = str.replacingOccurrences(of: "\r", with: " ")
                    .replacingOccurrences(of: "\n", with: " ")
                    .replacingOccurrences(of: "&", with: "&amp;")
                    .replacingOccurrences(of: "<", with: "&lt;")
                    .replacingOccurrences(of: ">", with: "&gt;")
                
                let resultHTML = ui_template__process_info(backColor: backColor, fontColor: fontColor, backgroundColor: mainBackColor, originalText: strToShow, title: NSLocalizedString("title.translating", comment: ""), message: NSLocalizedString("msg.translating", comment: ""))
                    
                // 判断是应该中文->英语还是英语->中文
                let charArr = str.unicodeScalars
                var nonAsciiCount = 0
                var nonLetterCount = 0
                var spaceCount = 0
                for char in str {
                    if char.isASCII {
                        if !char.isLetter {
                            nonLetterCount = nonLetterCount + 1
                        }
                        if char.asciiValue == 32 {
                            spaceCount = spaceCount + 1
                        }
                    }
                    else {
                        nonAsciiCount = nonAsciiCount + 1
                    }
                }
                
                let isInChinese = nonAsciiCount > charArr.count / 3
                let isEnglishWord = nonLetterCount == 0
                let doNotTranslateIfInChinese = UserDefaults.standard.integer(forKey: KEY_WHEN_MEET_CHINESE_CHARACTER) == 0
                //let translateToAnotherLanguage = !doNotTranslateIfInChinese
                
                if isInChinese && doNotTranslateIfInChinese {
                    return
                }
                
                // Display translating UI message
                self.resultDisplay.loadHTMLString(resultHTML, baseURL: nil)
                
                // 最大允许的短语长度（用于查词典）
                let allowedParseLength = 4
            
                // Baidu Translate Information
                let currLangCode = getCurrentLanguageCode()
                var langTo = isInChinese || currLangCode != "zh" ? currLangCode : "zh"
                if isInChinese && currLangCode == "zh" {
                    langTo = "en"
                }
                print("language to: \(langTo), currLangCode=\(currLangCode)")
                
                // If is English word and set to look up in dictionary
                if UserDefaults.standard.bool(forKey: KEY_LOOKUP_DICT)
                    && (isEnglishWord || (nonLetterCount - max(spaceCount, allowedParseLength-1) <= 0))
                    && langTo == "zh" {
                    self.lookupDictionary(word: str)
                }
                // Otherwise
                else {
                    self.translateWithBaidu(str: str, strToShow: strToShow, langTo: langTo)
                }
            }
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
           // Trait collection has already changed
        self.shouldUpdateUI = true;
    }
}

extension ViewController: UINavigationBarDelegate {
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return UIBarPosition.topAttached
    }
}
