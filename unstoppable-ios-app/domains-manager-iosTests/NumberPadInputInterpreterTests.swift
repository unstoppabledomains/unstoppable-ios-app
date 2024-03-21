//
//  NumberPadInputInterpreterTests.swift
//  domains-manager-iosTests
//
//  Created by Oleg Kuplin on 20.03.2024.
//

import XCTest
@testable import domains_manager_ios

final class NumberPadInputInterpreterTests: BaseTestClass {
 
    var interpreter: NumberPadInputInterpreter!
    
    override func setUp() {
        self.interpreter = NumberPadInputInterpreter()
    }
    
    func testInitialValue() {
        XCTAssertEqual(interpreter.getInput(), "0")
        XCTAssertEqual(interpreter.getInterpretedNumber(), 0)
    }
    
    func testEraseEmpty() {
        interpreter.addInput(.erase)
        XCTAssertEqual(interpreter.getInput(), "0")
        XCTAssertEqual(interpreter.getInterpretedNumber(), 0)
    }
    
    func testAddingInput() {
        interpreter.addInput(.number(1))
        XCTAssertEqual(interpreter.getInput(), "1")
        XCTAssertEqual(interpreter.getInterpretedNumber(), 1)
        
        interpreter.addInput(.number(2))
        XCTAssertEqual(interpreter.getInput(), "12")
        XCTAssertEqual(interpreter.getInterpretedNumber(), 12)
        
        interpreter.addInput(.dot)
        XCTAssertEqual(interpreter.getInput(), "12.")
        XCTAssertEqual(interpreter.getInterpretedNumber(), 12)
        
        interpreter.addInput(.number(4))
        XCTAssertEqual(interpreter.getInput(), "12.4")
        XCTAssertEqual(interpreter.getInterpretedNumber(), 12.4)
        
        interpreter.addInput(.number(5))
        XCTAssertEqual(interpreter.getInput(), "12.45")
        XCTAssertEqual(interpreter.getInterpretedNumber(), 12.45)
        
        interpreter.addInput(.erase)
        XCTAssertEqual(interpreter.getInput(), "12.4")
        XCTAssertEqual(interpreter.getInterpretedNumber(), 12.4)
        
        interpreter.addInput(.erase)
        XCTAssertEqual(interpreter.getInput(), "12.")
        XCTAssertEqual(interpreter.getInterpretedNumber(), 12)
        
        interpreter.addInput(.erase)
        XCTAssertEqual(interpreter.getInput(), "12")
        XCTAssertEqual(interpreter.getInterpretedNumber(), 12)
        
        interpreter.addInput(.erase)
        XCTAssertEqual(interpreter.getInput(), "1")
        XCTAssertEqual(interpreter.getInterpretedNumber(), 1)
        
        interpreter.addInput(.erase)
        XCTAssertEqual(interpreter.getInput(), "0")
        XCTAssertEqual(interpreter.getInterpretedNumber(), 0)
    }
    
    func testDoubleDotEntered() {
        interpreter.addInput(.dot)
        XCTAssertEqual(interpreter.getInput(), "0.")
        XCTAssertEqual(interpreter.getInterpretedNumber(), 0)
        
        interpreter.addInput(.dot)
        XCTAssertEqual(interpreter.getInput(), "0.")
        XCTAssertEqual(interpreter.getInterpretedNumber(), 0)
    }
    
    func testSecondDotEnteredInTheMiddle() {
        interpreter.addInput(.number(1))
        interpreter.addInput(.dot)
        interpreter.addInput(.number(2))
        interpreter.addInput(.dot)
        XCTAssertEqual(interpreter.getInput(), "1.2")
        XCTAssertEqual(interpreter.getInterpretedNumber(), 1.2)
    }
    
    func testZerosInput() {
        interpreter.addInput(.number(0))
        XCTAssertEqual(interpreter.getInput(), "0")
        XCTAssertEqual(interpreter.getInterpretedNumber(), 0)
        interpreter.addInput(.number(0))
        interpreter.addInput(.number(0))
        interpreter.addInput(.number(0))
        XCTAssertEqual(interpreter.getInput(), "0")
        XCTAssertEqual(interpreter.getInterpretedNumber(), 0)
    }
}

