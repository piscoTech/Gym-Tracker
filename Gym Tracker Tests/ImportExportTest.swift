//
//  ImportExportTest.swift
//  Gym Tracker Tests
//
//  Created by Marco Boschi on 10/12/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import XCTest
@testable import Gym_Tracker

class ImportExportTest: XCTestCase {
	
	var importExpectation: XCTestExpectation!
	
	override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
		
		importExpectation = XCTestExpectation(description: "Workout imported")
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
		
		dataManager.discardAllChanges()
    }
    
    func testImportExport() {
        let w = dataManager.newWorkout()
		let name = "Workout Import Export Test"
		let ow = OrganizedWorkout(w)
		ow.name = name
		
		var e = dataManager.newExercize(for: w)
		let eName = "Exercize Import Export Test"
		e.set(name: eName)
		var s = dataManager.newSet(for: e)
		let sReps: Int32 = 10
		let sWeight = 5.0
		let sRest = 90.0
		s.set(reps: sReps)
		s.set(weight: sWeight)
		s.set(rest: sRest)
		s = dataManager.newSet(for: e)
		s.set(reps: sReps / 2)
		s.set(weight: sWeight * 2)
		s.set(rest: sRest)
		
		e = dataManager.newExercize(for: w)
		e.set(name: eName)
		s = dataManager.newSet(for: e)
		s.set(reps: sReps)
		s.set(weight: sWeight)
		s.set(rest: sRest)
		s = dataManager.newSet(for: e)
		s.set(reps: sReps / 2)
		s.set(weight: sWeight * 2)
		s.set(rest: sRest)
		
		e = dataManager.newExercize(for: w)
		let rest = 4 * 60.0
		e.set(rest: rest)
		
		e = dataManager.newExercize(for: w)
		e.set(name: eName)
		s = dataManager.newSet(for: e)
		s.set(reps: sReps)
		s.set(weight: sWeight)
		s.set(rest: sRest)
		
		ow.makeCircuit(exercize: ow[0]!, isCircuit: true)
		ow.enableCircuitRestPeriods(for: ow[1]!, enable: true)
		
		if let f = dataManager.importExportManager.export(workout: w) {
			dataManager.importExportManager.import(f, isRestoring: false, performCallback: { fileValid, number, doPerform in
				XCTAssertTrue(fileValid)
				XCTAssertEqual(number, 1)
				XCTAssertNotNil(doPerform)
				doPerform?()
			}) { wrktList in
				if let wrkt = wrktList {
					XCTAssertEqual(wrkt.count, 1)
					let w = wrkt[0]
					let ow = OrganizedWorkout(w)
					XCTAssertEqual(ow.name, name)
					
					XCTAssertEqual(ow.exercizes.count, 4)
					XCTAssertFalse(ow[0]!.isRest)
					XCTAssertFalse(ow[1]!.isRest)
					XCTAssertTrue(ow[2]!.isRest)
					XCTAssertFalse(ow[3]!.isRest)
					
					if let (n, t) = ow.circuitStatus(for: ow[1]!) {
						XCTAssertEqual(n, 2)
						XCTAssertEqual(n, t)
					} else {
						XCTFail("Unexpected nil")
					}
					
					XCTAssertFalse(ow[0]!.hasCircuitRest)
					XCTAssertTrue(ow[1]!.hasCircuitRest)
					
					let e0 = ow[0]!
					XCTAssertFalse(e0.isRest)
					XCTAssertEqual(e0.name, eName)
					XCTAssertEqual(e0.sets.count, 2)
					
					let s0 = e0[0]!
					XCTAssertEqual(s0.reps, sReps)
					XCTAssertEqual(s0.weight, sWeight, accuracy: 0.0001)
					XCTAssertEqual(s0.rest, sRest, accuracy: 0.0001)
					
					let s1 = e0[0]!
					XCTAssertEqual(s1.reps, sReps / 2)
					XCTAssertEqual(s1.weight, sWeight * 2, accuracy: 0.0001)
					XCTAssertEqual(s1.rest, sRest, accuracy: 0.0001)
					
					self.importExpectation.fulfill()
				} else {
					XCTFail("Import failed")
				}
			}
		} else {
			XCTFail("Export failed")
		}
		
		wait(for: [importExpectation], timeout: 10)
    }
	
}
