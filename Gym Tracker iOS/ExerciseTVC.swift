//
//  ExerciseTVC.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 14/11/2016.
//  Copyright © 2016 Marco Boschi. All rights reserved.
//

import UIKit
import MBLibrary
import GymTrackerCore

class ExerciseTableViewController: UITableViewController, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource, PartCollectionController {
	
	class func instanciate() -> ExerciseTableViewController {
		return UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "exerciseView") as! ExerciseTableViewController
	}
	
	var editMode = false
	var exercise: GTSimpleSetsExercise!
	var partCollection: GTDataObject {
		return exercise
	}
	weak var delegate: PartCollectionController!
	
	func addDeletedEntities(_ del: [GTDataObject]) {
		delegate.addDeletedEntities(del)
	}
	
	private var oldName: String? {
		didSet {
			if let val = oldName, val.isEmpty {
				oldName = nil
			}
		}
	}
	private let defaultName = GTLocalizedString("EXERCISE", comment: "Exercise")

    override func viewDidLoad() {
        super.viewDidLoad()
		
		for (n, i) in [collectionDataId] {
			tableView.register(UINib(nibName: n, bundle: Bundle.main), forCellReuseIdentifier: i)
		}
		
		tableView.rowHeight = UITableView.automaticDimension
		tableView.estimatedRowHeight = 44
		
		if exercise.sets.isEmpty && editMode {
			DispatchQueue.main.async {
				self.newSet(self)
			}
		}
		oldName = exercise.name
		
		if #available(iOS 13, *) {} else {
			tableView.backgroundColor = .black
		}
    }
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		
		if self.isMovingFromParent {
			if exercise.name.isEmpty {
				exercise.set(name: oldName ?? defaultName)
			}

			DispatchQueue.main.async {
				self.delegate.exerciseUpdated(self.exercise)
			}
		}
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	func updateView(global: Bool = false) {
		tableView.reloadData()
	}
	
	func updateSecondaryInfoChange() {
		tableView.reloadSections([1], with: .automatic)
	}
	
	func exerciseUpdated(_ e: GTPart) {}
	
	func dismissPresentedController() {}
	
	// MARK: - Table view data source
	
	private enum SetCellType {
		case set, rest, picker
	}
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		return editMode ? 3 : 2
	}
	
	override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
		if editMode && section == 1 {
			return GTLocalizedString("REMOVE_SET_TIP", comment: "Remove set")
		}
		
		return nil
	}
	
	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		if indexPath.section == 1 && setCellType(for: indexPath) == .picker {
			return 150
		} else if indexPath.section == 0 && indexPath.row == 0 && !editMode {
			return UITableView.automaticDimension
		}
		
		return tableView.estimatedRowHeight
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		switch section {
		case 0:
			return 1 + numberOfRowInHeaderSection()
		case 1:
			let (g, l) = exercise.restStatus
			return exercise.sets.count * (g ? 2 : 1) + (g && !l ? -1 : 0) + (editRest != nil ? 1 : 0)
		case 2:
			return 1
		default:
			return 0
		}
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		switch indexPath.section {
		case 0:
			if indexPath.row == 0 {
				if editMode {
					let cell = tableView.dequeueReusableCell(withIdentifier: "editTitle", for: indexPath) as! SingleFieldCell
					cell.textField.text = exercise.name
					return cell
				} else {
					let cell = tableView.dequeueReusableCell(withIdentifier: "title", for: indexPath) as! MultilineCell
					cell.isUserInteractionEnabled = false
					cell.label.text = exercise.name
					return cell
				}
			} else { // Parent collection rows
				return headerCell(forRowAt: IndexPath(row: indexPath.row - 1, section: 0), reallyAt: indexPath)
			}
		case 1:
			let s = exercise[Int32(setNumber(for: indexPath))]!
			switch setCellType(for: indexPath) {
			case .rest:
				let cell = tableView.dequeueReusableCell(withIdentifier: "rest", for: indexPath) as! RestCell
				cell.set(rest: s.rest)
				
				return cell
			case .set:
				let cell = tableView.dequeueReusableCell(withIdentifier: "set", for: indexPath) as! SetCell
				cell.isEnabled = editMode
				cell.set = s
				
				return cell
			case .picker:
				let cell = tableView.dequeueReusableCell(withIdentifier: "restPicker", for: indexPath) as! RestPickerCell
				cell.picker.selectRow(Int(ceil(s.rest / GTRest.restStep)), inComponent: 0, animated: false)
				
				return cell
			}
		case 2:
			return tableView.dequeueReusableCell(withIdentifier: "add", for: indexPath)
		default:
			fatalError("Unknown section")
		}
	}
	
	// MARK: - Editing
	
	@IBAction func newSet(_ sender: AnyObject) {
		guard editMode else {
			return
		}
		
		let s = appDelegate.dataManager.newSet(for: exercise)
		s.set(mainInfo: 0)
		s.set(secondaryInfo: 0)
		s.set(rest: 60)
		
		insertSet(s)
	}
	
	@IBAction func cloneSet(_ sender: AnyObject) {
		guard editMode else {
			return
		}
		
		var setList = exercise.setList
		guard let last = setList.popLast() else {
			return
		}
		
		let s = appDelegate.dataManager.newSet(for: exercise)
		s.set(mainInfo: last.mainInfo)
		s.set(secondaryInfo: last.secondaryInfo)
		last.set(rest: setList.last?.rest ?? last.rest)
		s.set(rest: last.rest)
		insertSet(s)
	}
	
	private func insertSet(_ s: GTSet) {
		let (g, _) = exercise.restStatus
		let count = tableView(tableView, numberOfRowsInSection: 1)
		var rows = [IndexPath(row: count - 1, section: 1)] // Last set (if no last rest) or last rest
		if count > 1 && g {
			rows.append(IndexPath(row: count - 2, section: 1)) // Rest before last set (if no last rest) or last set
		}
		
		tableView.insertRows(at: rows, with: .automatic)
	}
	
	// MARK: - Delete set
	
	override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		return editMode && indexPath.section == 1 && setCellType(for: indexPath) == .set
	}
	
	override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
		guard editingStyle == .delete else {
			return
		}
		
		let (g, l) = exercise.restStatus
		let setN = Int(setNumber(for: indexPath))
		let isLast = setN == exercise.sets.count - 1
		guard let set = exercise[Int32(setN)] else {
			return
		}
		
		var remove = [indexPath]
		var removeFade = [IndexPath]()
		
		if g {
			var removedPreviousRest = false
			if l || !isLast { // Always has own rest
				// Remove own set rest row
				remove.append(IndexPath(row: indexPath.row + 1, section: 1))
			} else { // Last with no own rest, remove previous one
				// Remove previous set rest row
				removedPreviousRest = true
				remove.append(IndexPath(row: indexPath.row - (editRest == setN - 1 ? 2 : 1), section: 1))
			}
			
			if let rest = editRest, rest == (removedPreviousRest ? setN - 1 : setN) {
				editRest = nil
				removeFade.append(IndexPath(row: indexPath.row + (removedPreviousRest ? -1 : 2), section: 1))
			}
		}
		
		exercise.removeSet(set)
		addDeletedEntities([set])
		
		tableView.beginUpdates()
		tableView.deleteRows(at: remove, with: .automatic)
		tableView.deleteRows(at: removeFade, with: .fade)
		tableView.endUpdates()
	}
	
	// MARK: - Edit name
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		
		return true
	}
	
	@IBAction func nameChanged(_ sender: UITextField) {
		exercise.set(name: sender.text ?? "")
	}
	
	func textFieldDidEndEditing(_ textField: UITextField) {
		textField.text = exercise.name
	}
	
	// MARK: - Edit circuit
	
	func enableCircuitRest(_ s: UISwitch) {
		guard editMode, exercise.isInCircuit, exercise.allowCircuitRest else {
			return
		}
		
		exercise.enableCircuitRest(s.isOn)
		s.isOn = exercise.hasCircuitRest
		tableView.reloadSections([1], with: .automatic)
	}
	
	// MARK: - Edit rest
	
	private var editRest: Int?
	
	private func setNumber(for i: IndexPath) -> Int32 {
		let (g, _) = exercise.restStatus
		var row = i.row
		
		if g { // If have rests, having or not the last one is indiffferent here
			if let r = editRest {
				if (r + 1) * 2 == row {
					return Int32(r)
				} else if (r + 1) * 2 < row {
					row -= 1
				}
			}
			
			return Int32(row / 2)
		} else { // No rests
			return Int32(row)
		}
	}
	
	private func setCellType(for i: IndexPath) -> SetCellType {
		let (g, _) = exercise.restStatus
		var row = i.row
		
		if g { // If have rests, having or not the last one is indiffferent here
			if let r = editRest {
				if (r + 1) * 2 == row {
					return .picker
				} else if (r + 1) * 2 < row {
					row -= 1
				}
			}
			
			return row % 2 == 0 ? .set : .rest
		} else { // No rests
			return .set
		}
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		
		guard editMode && indexPath.section == 1 && setCellType(for: indexPath) == .rest else {
			return
		}
		let setNum = setNumber(for: indexPath)
		
		tableView.beginUpdates()
		
		var onlyClose = false
		if let r = editRest {
			onlyClose = Int32(r) == setNum
			tableView.deleteRows(at: [IndexPath(row: (r + 1) * 2, section: 1)], with: .fade)
		}
		
		if onlyClose {
			editRest = nil
		} else {
			tableView.insertRows(at: [IndexPath(row: (Int(setNum) + 1) * 2, section: 1)], with: .automatic)
			editRest = Int(setNum)
		}
		
		tableView.endUpdates()
	}
	
	func numberOfComponents(in pickerView: UIPickerView) -> Int {
		return 1
	}

	func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
		return Int(ceil(GTRest.maxRest / GTRest.restStep)) + 1
	}
	
	func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
		if #available(iOS 13, *) {
			// Fallback to un-styled picker
			return nil
		} else {
			guard let title = self.pickerView(pickerView, titleForRow: row, forComponent: component) else {
				return nil
			}
			
			return NSAttributedString(string: title, attributes: [.foregroundColor : UIColor(named: "Text Color")!])
		}
	}
	
	func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
		return (TimeInterval(row) * GTRest.restStep).formattedDuration
	}
	
	func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
		guard let setN = editRest, let set = exercise[Int32(setN)] else {
			return
		}
		
		set.set(rest: TimeInterval(row) * GTRest.restStep)
		tableView.reloadRows(at: [IndexPath(row: setN * 2 + 1, section: 1)], with: .none)
	}

}
