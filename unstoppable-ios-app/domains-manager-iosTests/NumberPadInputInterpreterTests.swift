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
        XCTAssert(interpreter.getInput() == "0")
        XCTAssert(interpreter.getInterpretedNumber() == 0)
    }
    
    func testEraseEmpty() {
        interpreter.addInput(.erase)
        XCTAssert(interpreter.getInput() == "0")
        XCTAssert(interpreter.getInterpretedNumber() == 0)
    }
    
    func testAddingInput() {
        interpreter.addInput(.number(1))
        XCTAssert(interpreter.getInput() == "1")
        XCTAssert(interpreter.getInterpretedNumber() == 1)
        
        interpreter.addInput(.number(2))
        XCTAssert(interpreter.getInput() == "12")
        XCTAssert(interpreter.getInterpretedNumber() == 12)
        
        interpreter.addInput(.dot)
        XCTAssert(interpreter.getInput() == "12.")
        XCTAssert(interpreter.getInterpretedNumber() == 12)
        
        interpreter.addInput(.number(4))
        XCTAssert(interpreter.getInput() == "12.4")
        XCTAssert(interpreter.getInterpretedNumber() == 12.4)
        
        interpreter.addInput(.number(5))
        XCTAssert(interpreter.getInput() == "12.45")
        XCTAssert(interpreter.getInterpretedNumber() == 12.45)
        
        interpreter.addInput(.erase)
        XCTAssert(interpreter.getInput() == "12.4")
        XCTAssert(interpreter.getInterpretedNumber() == 12.4)
        
        interpreter.addInput(.erase)
        XCTAssert(interpreter.getInput() == "12.")
        XCTAssert(interpreter.getInterpretedNumber() == 12)
        
        interpreter.addInput(.erase)
        XCTAssert(interpreter.getInput() == "12")
        XCTAssert(interpreter.getInterpretedNumber() == 12)
        
        interpreter.addInput(.erase)
        XCTAssert(interpreter.getInput() == "1")
        XCTAssert(interpreter.getInterpretedNumber() == 1)
        
        interpreter.addInput(.erase)
        XCTAssert(interpreter.getInput() == "0")
        XCTAssert(interpreter.getInterpretedNumber() == 0)
    }
    
    func testDoubleDotEntered() {
        interpreter.addInput(.dot)
        XCTAssert(interpreter.getInput() == "0.")
        XCTAssert(interpreter.getInterpretedNumber() == 0)
        
        interpreter.addInput(.dot)
        XCTAssert(interpreter.getInput() == "0.")
        XCTAssert(interpreter.getInterpretedNumber() == 0)
    }
    
    func testSecondDotEnteredInTheMiddle() {
        interpreter.addInput(.number(1))
        interpreter.addInput(.dot)
        interpreter.addInput(.number(2))
        interpreter.addInput(.dot)
        XCTAssert(interpreter.getInput() == "1.2")
        XCTAssert(interpreter.getInterpretedNumber() == 1.2)
    }
}

