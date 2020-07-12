//
//  FaceSwapTests.swift
//  FaceSwapTests
//
//  Created by Alexander Karlsson on 2020-07-05.
//  Copyright © 2020 Alexander Karlsson. All rights reserved.
//

import XCTest

@testable import FaceSwap

class FaceSwapTests: XCTestCase {
    
    var sut = FaceSwapLogic()
    
    override class func setUp() {
        super.setUp()
    }
    
    // Ideal test case, two input images with one face each.
    func testSwapFaces() throws {
        guard let im1 = UIImage(named: "arnold") else { return }
        guard let im2 = UIImage(named: "queen") else { return }
        
        let res = sut.swapFaces(im1: im1, im2: im2)
        XCTAssertTrue(res)
        
        let im_res1 = sut.getResultImage1()
        XCTAssertGreaterThan(im_res1.size.width, 0)
        XCTAssertGreaterThan(im_res1.size.height, 0)
        let im_res2 = sut.getResultImage2()
        XCTAssertGreaterThan(im_res2.size.width, 0)
        XCTAssertGreaterThan(im_res2.size.height, 0)
    }

    // Tests the time it takes to swap faces in two images.
    func testPerformanceExample() throws {
        measure {
            guard let im1 = UIImage(named: "arnold") else { return }
            guard let im2 = UIImage(named: "queen") else { return }
            let res = sut.swapFaces(im1: im1, im2: im2)
            XCTAssertTrue(res)
        }
    }
    
    func testTooSmallInput() throws {
        
        
        
        
    }
    
    
    // Test height too small
    // Test width too small
    // Test height and width too small
    // Acceptance test that images with size equal ~ minSize can be swapped.
}
