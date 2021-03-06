//
//  GTWorkoutTests.swift
//  Model Tests
//
//  Created by Marco Boschi on 16/11/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import XCTest
@testable import MBLibrary
@testable import GymTrackerCore

class GTWorkoutTests: XCTestCase {
	
	private var workout: GTWorkout!
	private var e1, e2: GTSimpleSetsExercise!
	private var r: GTRest!
	
	private func newValidExercise() -> GTSimpleSetsExercise {
		let e = dataManager.newExercise()
		e.set(name: "Exercise")
		_ = dataManager.newSet(for: e)
		
		return e
	}
    
    override func setUp() {
        super.setUp()
		
		workout = dataManager.newWorkout()
		e1 = dataManager.newExercise()
		workout.add(parts: e1)
		e1.set(name: "Exercise")
		
		r = dataManager.newRest()
		workout.add(parts: r)
		r.set(rest: 30)
		
		e2 = dataManager.newExercise()
		workout.add(parts: e2)
		e2.set(name: "Exercise")
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
		dataManager.discardAllChanges()
		
		super.tearDown()
    }
	
	func testDescription() {
		let workout = dataManager.newWorkout()
		
		let e1 = newValidExercise()
		workout.add(parts: e1)
		XCTAssertTrue(workout.description.hasPrefix("1"), "Unexpected description '\(workout.description)'")
		let e2 = newValidExercise()
		workout.add(parts: e2)
		XCTAssertTrue(workout.description.hasPrefix("2"), "Unexpected description '\(workout.description)'")
		
		let ch = dataManager.newChoice()
		workout.add(parts: ch)
		ch.add(parts: e1, e2)
		XCTAssertTrue(workout.description.hasPrefix("1"), "Unexpected description '\(workout.description)'")
		
		let e3 = newValidExercise()
		let c = dataManager.newCircuit()
		workout.add(parts: c)
		c.add(parts: ch, e3)
		XCTAssertTrue(workout.description.hasPrefix("2"), "Unexpected description '\(workout.description)'")
	}
	
	func testIsValid() {
		XCTAssertFalse(workout.isSubtreeValid)
		XCTAssertFalse(workout.isValid)
		
		_ = dataManager.newSet(for: e1)
		_ = dataManager.newSet(for: e2)
		
		XCTAssertFalse(workout.isSubtreeValid)
		XCTAssertFalse(workout.isValid)
		workout.set(name: "Workt")
		
		XCTAssertTrue(workout.isSubtreeValid)
		XCTAssertTrue(workout.isValid)
	}
	
	func testIsValidRest() {
		_ = dataManager.newSet(for: e1)
		_ = dataManager.newSet(for: e2)
		workout.set(name: "Workt")
		XCTAssertTrue(workout.isSubtreeValid)
		XCTAssertTrue(workout.isValid)
		
		let r = dataManager.newRest()
		workout.add(parts: r)
		
		XCTAssertFalse(workout.isSubtreeValid)
		XCTAssertFalse(workout.isValid)
		
		workout.movePart(at: r.order, to: 0)
		
		XCTAssertFalse(workout.isSubtreeValid)
		XCTAssertFalse(workout.isValid)
		
		workout.movePart(at: r.order, to: self.r.order)
		
		XCTAssertFalse(workout.isSubtreeValid)
		XCTAssertFalse(workout.isValid)
		
		workout.remove(part: r)
		
		XCTAssertTrue(workout.isSubtreeValid)
		XCTAssertTrue(workout.isValid)
	}
	
	func testPurgeSetting() {
		let e = workout[2] as! GTSimpleSetsExercise
		XCTAssertFalse(e.hasCircuitRest)
		e.forceEnableCircuitRest(true)
		XCTAssertTrue(e.hasCircuitRest)
		XCTAssertTrue(workout.purge().isEmpty)
		XCTAssertFalse(e.hasCircuitRest)
		
		let c = dataManager.newCircuit()
		c.add(parts: e)
		workout.add(parts: c)
		XCTAssertFalse(e.hasCircuitRest)
		e.forceEnableCircuitRest(true)
		XCTAssertTrue(e.hasCircuitRest)
		XCTAssertTrue(workout.purge().isEmpty)
		XCTAssertTrue(e.hasCircuitRest)
	}
	
	func testParent() {
		XCTAssertNil(workout.parentLevel)
		
		let w = dataManager.newWorkout()
		XCTAssertNil(w.parentLevel)
	}
	
	func testSetName() {
		let n = "Workout"
		workout.set(name: n)
		XCTAssertEqual(workout.name, n)
	}
    
    func testSubScript() {
		XCTAssertEqual(workout.exercises.count, 3, "Not the expected number of exercises")
		
		let first = workout[0]
		XCTAssertNotNil(first, "Missing exercise")
		XCTAssertEqual(first, e1)
		
		let r = workout[1]
		XCTAssertNotNil(r, "Missing rest period")
		XCTAssertEqual(r, r)
		
		let last = workout[2]
		XCTAssertNotNil(last, "Missing exercise")
		XCTAssertEqual(last, e2)
    }
	
	func testReorderBefore() {
		workout.movePart(at: 2, to: 1)
		XCTAssertEqual(workout.exercises.count, 3, "Some exercises disappeared")
		XCTAssertEqual(workout[0], e1)
		XCTAssertEqual(workout[1], e2)
		XCTAssertEqual(workout[2], r)
	}
	
	func testReorderAfter() {
		workout.movePart(at: 0, to: 1)
		XCTAssertEqual(workout.exercises.count, 3, "Some exercises disappeared")
		XCTAssertEqual(workout[1], e1)
		XCTAssertEqual(workout[2], e2)
		XCTAssertEqual(workout[0], r)
	}
	
	func testCompactSimpleEnd() {
		workout.movePart(at: 2, to: 1)
		_ = dataManager.newSet(for: e1)
		_ = dataManager.newSet(for: e2)
		workout.set(name: "Workt")
		XCTAssertFalse(workout.isValid)
		XCTAssertTrue(workout.isPurgeableToValid)
		XCTAssertTrue(workout.purge(onlySettings: true).isEmpty)
		XCTAssertFalse(workout.isValid)
		XCTAssertTrue(workout.isPurgeableToValid)
		let del = workout.purge()
		XCTAssertEqual(del.count, 1, "Rest not removed")
		XCTAssertEqual(del.first, r, "Removed part is not the rest period")
		XCTAssertEqual(workout.exercises.count, 2)
	}
	
	func testCompactSimpleStart() {
		workout.movePart(at: 0, to: 1)
		_ = dataManager.newSet(for: e1)
		_ = dataManager.newSet(for: e2)
		workout.set(name: "Workt")
		XCTAssertFalse(workout.isValid)
		XCTAssertTrue(workout.isPurgeableToValid)
		XCTAssertTrue(workout.purge(onlySettings: true).isEmpty)
		XCTAssertFalse(workout.isValid)
		XCTAssertTrue(workout.isPurgeableToValid)
		let del = workout.purge()
		XCTAssertEqual(del.count, 1, "Rest not removed")
		XCTAssertEqual(del.first, r, "Removed part is not the rest period")
		XCTAssertEqual(workout.exercises.count, 2)
	}
	
	func testCompactSimpleMiddle() {
		let r2 = dataManager.newRest()
		workout.add(parts: r2)
		r2.set(rest: 30)
		workout.movePart(at: 3, to: 1)
		_ = dataManager.newSet(for: e1)
		_ = dataManager.newSet(for: e2)
		workout.set(name: "Workt")
		XCTAssertFalse(workout.isValid)
		XCTAssertTrue(workout.isPurgeableToValid)
		XCTAssertTrue(workout.purge(onlySettings: true).isEmpty)
		XCTAssertFalse(workout.isValid)
		XCTAssertTrue(workout.isPurgeableToValid)
		
		let del = workout.purge()
		XCTAssertEqual(del.count, 1, "Rest not removed")
		
		XCTAssertEqual(workout.exercises.count, 3)
		XCTAssertEqual(del.first, r)
	}
	
	func testPartList() {
		XCTAssertEqual(workout.exerciseList, [e1, r, e2])
		
		let w = dataManager.newWorkout()
		XCTAssertEqual(w.exerciseList, [])
		
		let e3 = newValidExercise()
		let e4 = newValidExercise()
		w.add(parts: e4, e3)
		
		XCTAssertEqual(w.exerciseList, [e4, e3])
		XCTAssertEqual(e3.order, 1)
		XCTAssertEqual(e4.order, 0)
		
		w.add(parts: e4)
		XCTAssertEqual(w.exerciseList, [e3, e4])
		XCTAssertEqual(e3.order, 0)
		XCTAssertEqual(e4.order, 1)
	}
	
	func testChoices() {
		XCTAssertEqual(workout.choices, [])
		
		let w = dataManager.newWorkout()
		XCTAssertEqual(w.choices, [])
		
		let e3 = newValidExercise()
		let e4 = newValidExercise()
		w.add(parts: e4, e3)
		
		XCTAssertEqual(w.choices, [])
		let ch1 = dataManager.newChoice()
		let ch2 = dataManager.newChoice()
		let c = dataManager.newCircuit()
		w.add(parts: ch1, c)
		c.add(parts: ch2)
		
		XCTAssertEqual(w.choices, [ch1, ch2])
		w.movePart(at: c.order, to: 0)
		XCTAssertEqual(w.choices, [ch2, ch1])
	}
	
	func testRemovePart() {
		XCTAssertEqual(workout.parts.count, 3)
		
		workout.remove(part: e2)
		XCTAssertEqual(workout.exercises.count, 2)
		XCTAssertEqual(workout[0], e1)
		XCTAssertEqual(workout[1], r)
	}
	
	func testSubtree() {
		var sets = [e1,e2].flatMap { $0!.sets }
		XCTAssertEqual(workout.subtreeNodes, Set(arrayLiteral: workout, r, e1, e2).union(sets))
		
		let ch1 = dataManager.newChoice()
		let ch2 = dataManager.newChoice()
		let c = dataManager.newCircuit()
		workout.add(parts: ch1, c)
		c.add(parts: ch2, e2)
		
		workout.movePart(at: ch1.order, to: 0)
		ch1.add(parts: e1)
		let e3 = newValidExercise()
		ch1.add(parts: e3)
		
		let e4 = newValidExercise()
		let e5 = newValidExercise()
		ch2.add(parts: e4, e5)
		
		sets = [e1,e2,e3,e4,e5].flatMap { $0!.sets }
		XCTAssertEqual(workout.subtreeNodes, Set(arrayLiteral: workout, r, e1, e2, e3, e4, e5, ch1, ch2, c).union(sets))
	}
	
	func testExport() {
		_ = dataManager.newSet(for: e1)
		_ = dataManager.newSet(for: e2)
		
		let c = dataManager.newCircuit()
		c.add(parts: newValidExercise(), newValidExercise())
		let ch = dataManager.newChoice()
		ch.add(parts: newValidExercise(), newValidExercise())
		workout.add(parts: c, ch)
		
		let xml = workout.export()
		assert(string: xml, containsInOrder: [GTWorkout.workoutTag, GTWorkout.nameTag, "</", GTWorkout.nameTag, GTWorkout.archivedTag, "</", GTWorkout.archivedTag, GTWorkout.partsTag, GTSimpleSetsExercise.exerciseTag, "</", GTSimpleSetsExercise.exerciseTag, GTRest.restTag, "</", GTRest.restTag, GTSimpleSetsExercise.exerciseTag, "</", GTSimpleSetsExercise.exerciseTag, GTCircuit.circuitTag, "</", GTCircuit.circuitTag, GTChoice.choiceTag, "</", GTChoice.choiceTag, "</", GTWorkout.partsTag, "</", GTWorkout.workoutTag])
	}

	static func validXml() -> XMLNode {
		let xml = XMLNode(name: GTWorkout.workoutTag)
		let n = XMLNode(name: GTWorkout.nameTag)
		n.set(content: "W")
		xml.add(child: n)
		let a = XMLNode(name: GTWorkout.archivedTag)
		a.set(content: "true")
		xml.add(child: a)
		let exs = XMLNode(name: GTCircuit.exercisesTag)
		xml.add(child: exs)
		
		exs.add(child: GTSimpleSetsExerciseTests.validXml())
		exs.add(child: GTRestTests.validXml())
		exs.add(child: GTCircuitTests.validXml())
		exs.add(child: GTChoiceTests.validXml())
		
		return xml
	}
	
	func testImport() {
		do {
			_ = try GTWorkout.import(fromXML: XMLNode(name: ""), withDataManager: dataManager)
			XCTFail()
		} catch GTError.importFailure(let o) {
			XCTAssertEqual(o, [])
		} catch _ {
			XCTFail()
		}
		
		do {
			let xml = XMLNode(name: GTWorkout.workoutTag)
			let n = XMLNode(name: GTWorkout.nameTag)
			n.set(content: "W")
			xml.add(child: n)
			let a = XMLNode(name: GTWorkout.archivedTag)
			a.set(content: "true")
			xml.add(child: a)
			let exs = XMLNode(name: GTCircuit.exercisesTag)
			xml.add(child: exs)
			
			_ = try GTWorkout.import(fromXML: xml, withDataManager: dataManager)
			XCTFail()
		} catch GTError.importFailure(let o) {
			XCTAssertEqual(o.count, 1)
			XCTAssertTrue(o.first is GTWorkout)
		} catch _ {
			XCTFail()
		}
		
		do {
			let xml = XMLNode(name: GTWorkout.workoutTag)
			let n = XMLNode(name: GTWorkout.nameTag)
			n.set(content: "W")
			xml.add(child: n)
			let a = XMLNode(name: GTWorkout.archivedTag)
			a.set(content: "true")
			xml.add(child: a)
			let exs = XMLNode(name: GTCircuit.exercisesTag)
			xml.add(child: exs)
			exs.add(child: GTSimpleSetsExerciseTests.validXml())
			
			let c = try GTWorkout.import(fromXML: xml, withDataManager: dataManager)
			XCTAssertTrue(c.isSubtreeValid)
			
			XCTAssertEqual(c.exercises.count, 1)
			XCTAssertEqual((c[0] as? GTSimpleSetsExercise)?.name, "Ex 1")
		} catch _ {
			XCTFail()
		}
		
		do {
			let xml = XMLNode(name: GTWorkout.workoutTag)
			let n = XMLNode(name: GTWorkout.nameTag)
			n.set(content: "W")
			xml.add(child: n)
			let a = XMLNode(name: GTWorkout.archivedTag)
			a.set(content: "true")
			xml.add(child: a)
			let exs = XMLNode(name: GTCircuit.exercisesTag)
			xml.add(child: exs)
			
			let c = XMLNode(name: GTCircuit.circuitTag)
			let cExs = XMLNode(name: GTCircuit.exercisesTag)
			c.add(child: cExs)
			cExs.add(child: GTSimpleSetsExerciseTests.validXml())
			
			exs.add(child: c)
			
			_ = try GTWorkout.import(fromXML: xml, withDataManager: dataManager)
			XCTFail()
		} catch GTError.importFailure(let o) {
			XCTAssertFalse(o.isEmpty)
			XCTAssertNil(o.first { !($0 is GTWorkout) && !($0 is GTCircuit) && !($0 is GTSimpleSetsExercise) && !($0 is GTRepsSet) && !($0 is GTChoice)})
		} catch _ {
			XCTFail()
		}
		
		do {
			let xml = XMLNode(name: GTWorkout.workoutTag)
			let n = XMLNode(name: GTWorkout.nameTag)
			n.set(content: "W")
			xml.add(child: n)
			let a = XMLNode(name: GTWorkout.archivedTag)
			a.set(content: "true")
			xml.add(child: a)
			let exs = XMLNode(name: GTCircuit.exercisesTag)
			xml.add(child: exs)
			
			let c = XMLNode(name: GTChoice.choiceTag)
			let cExs = XMLNode(name: GTChoice.exercisesTag)
			c.add(child: cExs)
			cExs.add(child: GTSimpleSetsExerciseTests.validXml())
			
			exs.add(child: c)
			
			_ = try GTWorkout.import(fromXML: xml, withDataManager: dataManager)
			XCTFail()
		} catch GTError.importFailure(let o) {
			XCTAssertFalse(o.isEmpty)
			XCTAssertNil(o.first { !($0 is GTWorkout) && !($0 is GTCircuit) && !($0 is GTSimpleSetsExercise) && !($0 is GTRepsSet) && !($0 is GTChoice)})
		} catch _ {
			XCTFail()
		}
		
		do {
			let cr = XMLNode(name: GTSimpleSetsExercise.hasCircuitRestTag)
			cr.set(content: "true")
			let xml = GTWorkoutTests.validXml()
			xml.children[2].children[0].add(child: cr)
			xml.children[2].add(child: GTRestTests.validXml())
			
			_ = try GTWorkout.import(fromXML: xml, withDataManager: dataManager)
			XCTFail()
		} catch GTError.importFailure(let o) {
			XCTAssertFalse(o.isEmpty)
			XCTAssertNil(o.first { !($0 is GTWorkout) && !($0 is GTCircuit) && !($0 is GTSimpleSetsExercise) && !($0 is GTRepsSet) && !($0 is GTChoice) && !($0 is GTRest) })
		} catch _ {
			XCTFail()
		}
		
		do {
			let cr = XMLNode(name: GTSimpleSetsExercise.hasCircuitRestTag)
			cr.set(content: "true")
			let xml = GTWorkoutTests.validXml()
			xml.children[2].children[0].add(child: cr)
			
			let w = try GTWorkout.import(fromXML: xml, withDataManager: dataManager)
			XCTAssertTrue(w.isSubtreeValid)
			XCTAssertTrue(w.isValid)
			
			XCTAssertEqual(w.exercises.count, 4)
			if let e1 = w[0] as? GTSimpleSetsExercise {
				XCTAssertFalse(e1.hasCircuitRest)
				XCTAssertEqual(e1.name, "Ex 1")
			} else {
				XCTFail("Unexpected part type")
			}
			XCTAssertTrue(w[1] is GTRest)
			XCTAssertTrue(w[2] is GTCircuit)
			XCTAssertTrue(w[3] is GTChoice)
		} catch _ {
			XCTFail()
		}
		
		do {
			let o = try GTDataObject.import(fromXML: GTWorkoutTests.validXml(), withDataManager: dataManager)
			XCTAssertTrue(o is GTWorkout)
		} catch _ {
			XCTFail()
		}
	}
	
	func testImport2_0() {
		let xml = XMLNode(name: GTWorkout.workoutTag)
		let n = XMLNode(name: GTWorkout.nameTag)
		n.set(content: "W")
		xml.add(child: n)
		let a = XMLNode(name: GTWorkout.archivedTag)
		a.set(content: "true")
		xml.add(child: a)
		let exs = XMLNode(name: GTCircuit.exercisesTag)
		xml.add(child: exs)
		
		func isc() -> XMLNode {
			let isc = XMLNode(name: GTSimpleSetsExercise.isCircuitTag)
			isc.set(content: "true")
			
			return isc
		}
		let cr = XMLNode(name: GTSimpleSetsExercise.hasCircuitRestTag)
		cr.set(content: "true")
		
		var e = GTSimpleSetsExerciseTests.validXml()
		e.add(child: isc())
		exs.add(child: e)
		
		e = GTSimpleSetsExerciseTests.validXml(name: 2)
		e.add(child: cr)
		exs.add(child: e)
		
		exs.add(child: GTSimpleSetsExerciseTests.validXml(name: 3))
		
		e = GTSimpleSetsExerciseTests.validXml(name: 4)
		e.add(child: isc())
		exs.add(child: e)
		
		e = GTSimpleSetsExerciseTests.validXml(name: 5)
		e.add(child: isc())
		exs.add(child: e)
		
		exs.add(child: GTRestTests.validXml())
		
		e = GTSimpleSetsExerciseTests.validXml(name: 6)
		e.add(child: isc())
		exs.add(child: e)
		
		e = GTSimpleSetsExerciseTests.validXml(name: 7)
		e.add(child: isc())
		exs.add(child: e)
		
		do {
			let w = try GTWorkout.import(fromXML: xml, withDataManager: dataManager)
			XCTAssertEqual(w.parts.count, 5)
			if let c = w[0] as? GTCircuit {
				XCTAssertEqual(c.exercises.count, 2)
				XCTAssertFalse(c[0]!.hasCircuitRest)
				XCTAssertEqual((c[0] as? GTSimpleSetsExercise)?.name, "Ex 1")
				XCTAssertTrue(c[1]!.hasCircuitRest)
				XCTAssertEqual((c[1] as? GTSimpleSetsExercise)?.name, "Ex 2")
			} else {
				XCTFail("No circuit")
			}
			
			XCTAssertEqual((w[1] as? GTSimpleSetsExercise)?.name, "Ex 3")
			
			if let c = w[2] as? GTCircuit {
				XCTAssertEqual(c.exercises.count, 2)
				XCTAssertFalse(c[0]!.hasCircuitRest)
				XCTAssertEqual((c[0] as? GTSimpleSetsExercise)?.name, "Ex 4")
				XCTAssertFalse(c[1]!.hasCircuitRest)
				XCTAssertEqual((c[1] as? GTSimpleSetsExercise)?.name, "Ex 5")
			} else {
				XCTFail("No circuit")
			}
			
			XCTAssertTrue(w[3] is GTRest)
			
			if let c = w[4] as? GTCircuit {
				XCTAssertEqual(c.exercises.count, 2)
				XCTAssertFalse(c[0]!.hasCircuitRest)
				XCTAssertEqual((c[0] as? GTSimpleSetsExercise)?.name, "Ex 6")
				XCTAssertFalse(c[1]!.hasCircuitRest)
				XCTAssertEqual((c[1] as? GTSimpleSetsExercise)?.name, "Ex 7")
			} else {
				XCTFail("No circuit")
			}
		} catch _ {
			XCTFail()
		}
	}
    
}
