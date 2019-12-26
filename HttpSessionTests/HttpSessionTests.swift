//
//  HttpSessionTests.swift
//  HttpSessionTests
//
//  Created by Shichimitoucarashi on 12/1/18.
//  Copyright © 2018 keisuke yamagishi. All rights reserved.
//

import XCTest
import HttpSession

class HttpSessionTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testHttpSession() {
        let exp = expectation(description: "Single Exception")
        Http.request(url: "https://httpsession.work/getApi.json", method: .get)
            .session { (data, _, _) in
                XCTAssertNotNil(data)
                exp.fulfill()
        }
        wait(for: [exp], timeout: 60.0)
    }

    func testHttpPost() {
        let exp = expectation(description: "Single Exception")
        let param = ["http_post": "Http Request POST 😄"]
        Http.request(url: "https://httpsession.work/postApi.json", method: .post, params: param)
            .session(completion: { (data, _, _) in
                XCTAssertNotNil(data)
                exp.fulfill()
            })
        wait(for: [exp], timeout: 60.0)
    }

    func testHttpCookieSignIn() {
        let exp = expectation(description: "Single Exception")
        let param1 = ["http_sign_in": "Http Request SignIn",
                      "userId": "keisukeYamagishi",
                      "password": "password_jisjdhsnjfbns"]
        let url = "https://httpsession.work/signIn.json"

        Http.request(url: url, method: .post, params: param1)
            .session { (data, _, _) in
            XCTAssertNotNil(data)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 60.0)
    }

    func testHttpCookieSignIned() {
        let exp = expectation(description: "Single Exception")
        Http.request(url: "https://httpsession.work/signIned.json", method: .get, cookie: true )
            .session(completion: { (data, _, _) in
                XCTAssertNotNil(data)
                exp.fulfill()
            })
        wait(for: [exp], timeout: 60.0)
    }

    func testHttpMultipart() {
        let exp = expectation(description: "Single Exception")
        var dto: Multipart.data = Multipart.data()
        let image: String? = Bundle.main.path(forResource: "re", ofType: "txt")
        var img: Data = Data()
        do {
            img = try Data(contentsOf: URL(fileURLWithPath: image!))
        } catch {

        }

        dto.fileName = "Hello.txt"
        dto.mimeType = "text/plain"
        dto.data = img

        Http.request(url: "https://httpsession.work/imageUp.json", method: .post)
            .upload(param: ["img": dto], completionHandler: { (data, _, _) in
                XCTAssertNotNil(data)
                exp.fulfill()
            })
        wait(for: [exp], timeout: 60.0)
    }

    func testHttpBasicAuth() {
        let exp = expectation(description: "Single Exception")
        let basicAuth: [String: String] = [Auth.user: "httpSession",
                                           Auth.password: "githubHttpsession"]
        Http.request(url: "https://httpsession.work/basicauth.json",
             method: .get,
             basic: basicAuth).session(completion: { (data, _, _) in
                XCTAssertNotNil(data)
                exp.fulfill()
             })
        wait(for: [exp], timeout: 60.0)
    }

    func testHttpTwitterOAuth() {
        let exp = expectation(description: "Single Exception")
        Twitter.oAuth(urlType: "httpRequest-NNKAREvWGCn7Riw02gcOYXSVP://", success: {
            exp.fulfill()
        }, failuer: { (_, _) in
            XCTFail()
            exp.fulfill()
        })
        wait(for: [exp], timeout: 60.0)
    }
}
