//
//  Options.swift
//  Fragment
//
//  Created by JINSEN WU on 9/27/23.
//

import Foundation

enum RenderChoice {
    case train, quad
}

class Options: ObservableObject {
    @Published var renderChoice = RenderChoice.train
}
