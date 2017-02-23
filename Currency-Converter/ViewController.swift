//
//  ViewController.swift
//  Currency-Converter
//
//  Created by NickJun on 21.02.17.
//  Copyright © 2017 wowinter13. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    
    
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var pickerFrom: UIPickerView!
    @IBOutlet weak var pickerTo: UIPickerView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var inputLabel: UITextField!
    
    
    let currencies = ["EUR", "GBP", "RUB", "USD"]
    
    
   
    
    //MARK: - UIPickerViewDataSource
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) ->Int {
        if pickerView === pickerTo {
            return self.currenciesExceptBase().count
        }
        
        return currencies.count
    }
    
    // View
    func requestCurrentCurrencyRate() {
        self.activityIndicator.startAnimating()
        self.label.text = ""
        
        let baseCurrencyIndex = self.pickerFrom.selectedRow(inComponent: 0)
        let toCurrencyIndex = self.pickerTo.selectedRow(inComponent: 0)
        
        let baseCurrency = self.currencies[baseCurrencyIndex]
        let toCurrency = self.currenciesExceptBase()[toCurrencyIndex]
        
        self.retrieveCurrencyRate(baseCurrency: baseCurrency, toCurrency: toCurrency ) {[weak self]
            (value) in
            DispatchQueue.main.async (execute: {
                if let strongSelf = self {
                    let amount:Double = Double(self!.inputLabel.text!)!
                    let valueD = Double(value)! * amount
                    
                    strongSelf.label.text = String(valueD)
                    strongSelf.activityIndicator.stopAnimating()
                }
            })
            
        }

    }
    
    //MARK: - UIPickerViewDelegate
    
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView === pickerTo {
            return self.currenciesExceptBase()[row]
        }
        return currencies[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView === pickerFrom {
            self.pickerTo.reloadAllComponents()
        }
        
        self.requestCurrentCurrencyRate()
            }
    
    // kill duplicates in pickerFrom
    func currenciesExceptBase() -> [String] {
        var currenciesExceptBase = currencies
        currenciesExceptBase.remove(at: pickerFrom.selectedRow(inComponent: 0))
    
        return currenciesExceptBase
    }
    
    //main
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        self.pickerFrom.dataSource = self
        self.pickerTo.dataSource = self
        
        self.pickerFrom.delegate = self
        self.pickerTo.delegate = self
        
        self.activityIndicator.hidesWhenStopped = true
        self.requestCurrentCurrencyRate()
        
        
    }
    
    //MARK: - Network
    // Parser-starter
    func requestCurrencyRates(baseCurrency : String, parseHandler: @escaping (Data?, Error?)-> Void) {
        let url = URL(string: "https://api.fixer.io/latest?base=" + baseCurrency)!
        
        
        let dataTask = URLSession.shared.dataTask(with: url) {
            (dataReceived, response, error) in
            parseHandler(dataReceived, error)
        }
        dataTask.resume()
    }
    
    //Hey, parser-maker
    func parseCurrencyRatesResponse(data: Data?, toCurrency: String) -> String {
        var value : String = ""
        
        do {
            let json = try JSONSerialization.jsonObject(with: data!, options: []) as? Dictionary<String, Any>
            
            if let parsedJSON = json {
                print ("\(parsedJSON)")
                if let rates = parsedJSON["rates"] as?  Dictionary<String, Double> {
                    if let rate =  rates[toCurrency] {
                        value = "\(rate)"
                    } else {
                        value = "No rate for currency \"\(toCurrency)\" found"
                    }
                } else {
                    value = "No \"rates\" field found"
                }
            } else {
                value = "No JSON value parsed"
            }
        } catch {
                value = error.localizedDescription
        }
        return value
    }
    
    //parser-remaker
    func retrieveCurrencyRate(baseCurrency: String, toCurrency: String, completion: @escaping (String) -> Void) {
        self.requestCurrencyRates(baseCurrency: baseCurrency) {[weak self] (data,error) in
            var string = "No currency retrieved!"
            
            if let currentError = error {
                string = currentError.localizedDescription
            } else {
                if let strongSelf = self {
                    string = strongSelf.parseCurrencyRatesResponse(data: data, toCurrency: toCurrency)
                }
            }
            completion(string)
        }
    }
    
   
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }


    
}

