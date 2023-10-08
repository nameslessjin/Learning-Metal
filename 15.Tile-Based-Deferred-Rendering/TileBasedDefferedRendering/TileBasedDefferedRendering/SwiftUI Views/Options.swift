//
//  Options.swift
//  Fragment
//
//  Created by JINSEN WU on 9/27/23.
//

import Foundation

enum RenderChoice: Int {
    case tiledDeferred = 0, deferred, forward
}

class Options: ObservableObject {
    @Published var renderChoice = RenderChoice.tiledDeferred
    @Published var tiledSupported = false
}
