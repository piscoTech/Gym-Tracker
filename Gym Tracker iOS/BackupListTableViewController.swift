//
//  BackupListTableViewController.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 26/04/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import UIKit
import GymTrackerCore

class BackupListTableViewController: UITableViewController {
	
	private var backups: ImportExportBackupManager.BackupList = []
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		updateList()
		
		if #available(iOS 13, *) {} else {
			tableView.backgroundColor = .black
		}
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	func updateList(lazy: Bool = false) {
		let load = {
			DispatchQueue.main.async {
				self.backups = appDelegate.dataManager.importExportManager.backups
				self.tableView.reloadSections([0], with: .automatic)
			}
		}
		
		if !lazy {
			appDelegate.dataManager.importExportManager.loadBackups {
				load()
			}
		} else {
			load()
		}
	}

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return max(1, backups.count)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard backups.count > 0 else {
			return tableView.dequeueReusableCell(withIdentifier: "noBackup", for: indexPath)
		}
		
		let b = backups[indexPath.row]
		let cell = tableView.dequeueReusableCell(withIdentifier: "backup", for: indexPath)
			
		cell.textLabel?.text = b.date.formattedDateTime
		
		return cell
    }
	
	// MARK: - Manage Backups
	
	private var documentController: UIActivityViewController?
	private var loading: UIAlertController?
	
	@IBAction func backupNow(_ sender: UIBarButtonItem) {
		sender.isEnabled = false
		
		appDelegate.dataManager.importExportManager.doBackup(manual: true) { success in
			DispatchQueue.main.async {
				sender.isEnabled = true
				if success {
					self.updateList(lazy: true)
				} else {
					self.present(UIAlertController(simpleAlert: GTLocalizedString("BACKUP_FAIL", comment: "Error"), message: nil), animated: true)
				}
			}
		}
	}

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
	}
	
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return appDelegate.dataManager.importExportManager.backups.count > 0
    }

	override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
		var act = [UITableViewRowAction]()
		
		let export = UITableViewRowAction(style: .normal, title: GTLocalizedString("EXPORT_BACKUP", comment: "export")) { _, row in
			self.tableView.setEditing(false, animated: true)
			
			DispatchQueue.main.async {
				self.documentController = UIActivityViewController(activityItems: [self.backups[row.row].path], applicationActivities: nil)
				self.documentController?.popoverPresentationController?.sourceView = tableView
				self.documentController?.popoverPresentationController?.sourceRect = tableView.rectForRow(at: indexPath)
				self.documentController?.completionWithItemsHandler = { _, _, _, _ in
					self.documentController = nil
				}
				
				self.present(self.documentController!, animated: true)
			}
		}
		act.append(export)
		
		if appDelegate.canEdit {
			let restore = UITableViewRowAction(style: .default, title: GTLocalizedString("RESTORE_BACKUP", comment: "Restore")) { _, row in
				self.tableView.setEditing(false, animated: true)
				guard appDelegate.canEdit else {
					return
				}
	
				self.loading = UIAlertController.getModalLoading()
				appDelegate.workoutList.exitDetailAndCreation {
					self.present(self.loading!, animated: true) {
						appDelegate.dataManager.readICloudDocument(self.backups[row.row].path) { url in
							appDelegate.dataManager.importExportManager.import(url, isRestoring: true, performCallback: { success, count, proceed in
								let confirm = {
									let alert: UIAlertController
									if let count = count, let proceed = proceed {
										alert = UIAlertController(
											title: GTLocalizedString("RESTORE_CONFIRM", comment: "err"),
											message: String(
												format: GTLocalizedString("RESTORE_CONFIRM_%lld", comment: "How many"),
												count),
											preferredStyle: .alert)
										alert.addAction(UIAlertAction(title: GTLocalizedString("CANCEL", comment: "Cancel"), style: .cancel, handler: nil))
										alert.addAction(UIAlertAction(title: GTLocalizedString("RESTORE_CONFIRM_BTN", comment: "Restore"), style: .default) { _ in
											self.loading = UIAlertController.getModalLoading()
											self.present(self.loading!, animated: true)
											proceed()
										})
									} else {
										alert = UIAlertController(simpleAlert: GTLocalizedString("RESTORE_FAIL", comment: "err"), message: GTLocalizedString("WRKT_INVALID", comment: "err"))
									}
									
									self.present(alert, animated: true)
								}
								
								if let load = self.loading {
									load.dismiss(animated: true, completion: confirm)
								} else {
									confirm()
								}
							}) { wrkt in
								let success: Bool
								let msg: String?
								if let wrkt = wrkt {
									success = true
									appDelegate.workoutList.refreshData()
									msg = String(
										format: GTLocalizedString("%lld_WORKOUTS", comment: "n workouts"),
										wrkt.count)
								} else {
									success = false
									msg = nil
								}
								let error = {
									self.present(UIAlertController(simpleAlert: GTLocalizedString(success ? "RESTORE_SUCCESS" : "RESTORE_FAIL", comment: "err/ok"), message: msg), animated: true)
								}
								
								if let load = self.loading {
									load.dismiss(animated: true, completion: error)
								} else {
									error()
								}
								self.loading = nil
							}
						}
					}
				}
			}
			restore.backgroundColor = greenTint
			act.append(restore)
		}
		
		let del = UITableViewRowAction(style: .destructive, title: GTLocalizedString("DELETE_BACKUP", comment: "Del")) { _, row in
			self.tableView.setEditing(false, animated: true)
			
			let b = self.backups[row.row]
			let confirm = UIAlertController(
				title: GTLocalizedString("DELETE_BACKUP_TITLE", comment: "Del"),
				message: String(
					format: GTLocalizedString("DELETE_BACKUP_CONFIRM", comment: "Del confirm"),
					b.date.formattedDateTime
				),
				preferredStyle: .actionSheet)
			confirm.addAction(UIAlertAction(title: GTLocalizedString("DELETE_BACKUP", comment: "Del"), style: .destructive) { _ in
				appDelegate.dataManager.deleteICloudDocument(b.path) { success in
					DispatchQueue.main.async {
						if success {
							self.backups.remove(at: row.row)
							self.tableView.reloadSections([0], with: .automatic)
						} else {
							let alert = UIAlertController(simpleAlert: GTLocalizedString("DELETE_BACKUP_FAIL", comment: "Err"), message: nil)
							self.present(alert, animated: true)
						}
					}
				}
			})
			confirm.addAction(UIAlertAction(title: GTLocalizedString("CANCEL", comment: "Cancel"), style: .cancel))
			
			self.present(confirm, animated: true)
		}
		act.append(del)
		
		return act
	}

}
