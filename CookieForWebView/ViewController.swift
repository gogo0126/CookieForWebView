//
//  ViewController.swift
//  CookieForWebView
//
//  Created by uitox_macbook on 2015/9/27.
//
//

import UIKit

class ViewController: UIViewController, UIWebViewDelegate, NSURLConnectionDelegate
{
	var webView: UIWebView?
	var _authenticated:Bool = false
	var _urlConnection:NSURLConnection?
	var _request:NSMutableURLRequest?
	let kUserDefaultsCookie = "kUserDefaultsCookie"
	var storage: NSHTTPCookieStorage = NSHTTPCookieStorage.sharedHTTPCookieStorage()
	let memberUrl = NSURL(string: "https://ecvip.pchome.com.tw")!

	override func viewDidLoad() {
		super.viewDidLoad()

		self.webView = UIWebView(frame: self.view.bounds)
		self.webView!.scalesPageToFit = true
		self.webView!.delegate = self
		self.view.addSubview(self.webView!)

		self._request = NSMutableURLRequest(URL: memberUrl)

		resetRequestHeader()

		self.webView!.loadRequest(self._request!)
	}

	func saveCookiesToLocal() {
		let data = NSKeyedArchiver.archivedDataWithRootObject(storage.cookies!)
		NSUserDefaults.standardUserDefaults().setObject(data, forKey: self.kUserDefaultsCookie)
	}

	func reSaveToStorage() {
		let cookiesdata = NSUserDefaults.standardUserDefaults().objectForKey(self.kUserDefaultsCookie) as? NSData
		if let cookiesdata = cookiesdata {
			let cookies = NSKeyedUnarchiver.unarchiveObjectWithData(cookiesdata) as? [NSHTTPCookie]
			for cookie in cookies! {
				storage.setCookie(cookie)
			}
		}
	}

	func resetRequestHeader() {
		reSaveToStorage()
		var cookieHeaders = NSHTTPCookie.requestHeaderFieldsWithCookies(storage.cookies!)
		self._request!.allHTTPHeaderFields = cookieHeaders
	}

	func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {

		NSLog("Did start loading: %@ auth:%d", request.URL!.absoluteString!, _authenticated)
		resetRequestHeader()

		if !_authenticated {
			_authenticated = false
			_urlConnection = NSURLConnection(request: self._request!, delegate: self)!
			_urlConnection!.start()
			return false
		}
		return true
	}

	func connection(connection: NSURLConnection, willSendRequest request: NSURLRequest, redirectResponse response: NSURLResponse?) -> NSURLRequest? {
		NSLog("redirect %@", request.URL!.absoluteString!)

		resetRequestHeader()

		return self._request
	}

	func connection(connection: NSURLConnection, didReceiveResponse response: NSURLResponse) {
		NSLog("WebController received response via NSURLConnection")

		_authenticated = true
		_urlConnection!.cancel()

		resetRequestHeader()

		webView!.loadRequest(self._request!)
	}

	func webViewDidFinishLoad(webView: UIWebView) {
		NSLog("Did finish load")
	}

	func connection(connection: NSURLConnection, willSendRequestForAuthenticationChallenge challenge: NSURLAuthenticationChallenge) {
		NSLog("WebController Got auth challange via NSURLConnection")
		if challenge.previousFailureCount == 0 {
			_authenticated = true
			var credential: NSURLCredential = NSURLCredential(forTrust: challenge.protectionSpace.serverTrust!)
			challenge.sender.useCredential(credential, forAuthenticationChallenge: challenge)
		}
		else {
			challenge.sender.cancelAuthenticationChallenge(challenge)
		}
		challenge.sender.continueWithoutCredentialForAuthenticationChallenge(challenge)
		
	}


}

