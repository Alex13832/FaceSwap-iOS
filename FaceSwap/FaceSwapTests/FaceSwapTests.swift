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
        XCTAssertEqual(res, SwapStatus.success)
        
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
            XCTAssertEqual(res, SwapStatus.success)
        }
    }
    
    func testSize() throws {
        guard let im_face1_exact_width = UIImage(named: "face1_exact_width") else { return }
        guard let im_face1_width_small = UIImage(named: "face1_width_small") else { return }
        guard let im_face1_height_small = UIImage(named: "face1_height_small") else { return }
        
        guard let im_face2_exact_width = UIImage(named: "face2_exact_width") else { return }
        guard let im_face2_width_small = UIImage(named: "face2_width_small") else { return }
        guard let im_face2_height_small = UIImage(named: "face2_height_small") else { return }
        
        var res = sut.swapFaces(im1: im_face1_width_small, im2: im_face2_exact_width)
        XCTAssertEqual(res, SwapStatus.tooSmallInput)
        
        res = sut.swapFaces(im1: im_face1_height_small, im2: im_face2_exact_width)
        XCTAssertEqual(res, SwapStatus.tooSmallInput)
        
        res = sut.swapFaces(im1: im_face1_exact_width, im2: im_face2_width_small)
        XCTAssertEqual(res, SwapStatus.tooSmallInput)
        
        res = sut.swapFaces(im1: im_face1_exact_width, im2: im_face2_height_small)
        XCTAssertEqual(res, SwapStatus.tooSmallInput)
        
        res = sut.swapFaces(im1: im_face1_exact_width, im2: im_face2_exact_width)
        XCTAssertEqual(res, SwapStatus.success)
    }
    
    func testMissingFace() throws {
        guard let im_face_missing = UIImage(named: "no_face") else { return }
        guard let im_face = UIImage(named: "queen") else { return }
        
        let res = sut.swapFaces(im1: im_face_missing, im2: im_face)
        XCTAssertEqual(res, SwapStatus.faceMissing)
    }
}
