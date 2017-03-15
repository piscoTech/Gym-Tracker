//
//  TableView Cells.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 13/03/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import UIKit
import MBLibrary

class SingleFieldCell: UITableViewCell {

	@IBOutlet weak var textField: UITextField!
	
	var isEnabled: Bool {
		get {
			return textField.isEnabled
		}
		set {
			textField.isEnabled = newValue
			textField.isUserInteractionEnabled = newValue
		}
	}

}

class RepsSetCell: UITableViewCell, UITextFieldDelegate {
	
	@IBOutlet weak var repsCount: UITextField!
	@IBOutlet weak var weight: UITextField!
	
	var set: RepsSet! {
		didSet {
			updateView()
		}
	}
	
	private func updateView() {
		self.repsCount.text = set.reps > 0 ? "\(set.reps)" : ""
		self.weight.text = set.weight > 0 ? set.weight.toString() : ""
	}
	
	func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
		let check = "[^0-9\(textField == weight ? "\\\(decimalPoint)" : "")]"
		
		return string.range(of: check, options: .regularExpression) == nil
	}
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		
		return true
	}
	
	@IBAction func valueChanged(_ sender: UITextField) {
		switch sender {
		case repsCount:
			set.set(reps: Int32(sender.text ?? "") ?? 0)
		case weight:
			set.set(weight: sender.text?.toDouble() ?? 0)
		default:
			fatalError("Unknown field")
		}
	}
	
	func textFieldDidEndEditing(_ textField: UITextField) {
		updateView()
	}
	
}

class RestPickerCell: UITableViewCell {
	
	@IBOutlet weak var picker: UIPickerView!
	var startsAtZero = true
	
	func set(rest: TimeInterval) {
		picker.selectRow(Int(ceil(rest / 30) - (startsAtZero ? 0 : 1)), inComponent: 0, animated: false)
	}
	
}
