// swift-tools-version:5.2
//
//  Package.swift
//  Bender
//
//  Created by Anton Davydov on 25.05.20.
//  Original work Copyright © 2020 Evgenii Kamyshanov
//
//  The MIT License (MIT)
//
//  Permission is hereby granted, free of charge, to any person obtaining
//  a copy of this software and associated documentation files (the "Software"),
//  to deal in the Software without restriction, including without limitation
//  the rights to use, copy, modify, merge, publish, distribute, sublicense,
//  and/or sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included
//  in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
//  OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import PackageDescription

let package = Package(name: "Bender",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v10)
    ],
    products: [
        .library(name: "Bender", targets: ["Bender"])
    ],
    dependencies: [
        .package(url: "http://github.com/Quick/Nimble.git", .upToNextMajor(from: "8.0.5")),
        .package(url: "http://github.com/Quick/Quick.git", .upToNextMajor(from: "2.2.0"))
    ],
    targets: [
        .target(name: "Bender", path: "Sources"),
        .testTarget(name: "BenderTests",
                    dependencies: ["Bender", "Nimble", "Quick"],
                    path: "Tests"),
    ],
    swiftLanguageVersions: [.v5])
