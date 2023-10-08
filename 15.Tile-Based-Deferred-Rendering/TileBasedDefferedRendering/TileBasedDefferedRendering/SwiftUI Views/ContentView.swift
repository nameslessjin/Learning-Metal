//
//  ContentView.swift
//  Textures
//
//  Created by JINSEN WU on 9/29/23.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var options = Options()
    @State var chcked: Int = 1
    var body: some View {
        let tiledSupported = options.tiledSupported ? "Tiled Deferred" : "Tiled Deferred not Supported!"
        return VStack(alignment: .leading) {
            ZStack {
                VStack {
                    MetalView(options: options)
                        .border(Color.black, width: 2)
                    RadioButton(label: "Rendering", options: [tiledSupported, "Deferred", "Forward"]) {
                        checked in
                        options.renderChoice = RenderChoice(rawValue: checked) ?? .forward
                        if !options.tiledSupported && options.renderChoice == .tiledDeferred {
                            print("WARNING: TBDR features not supported")
                            options.renderChoice = .forward
                        }
                    }
                }
            }
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
        }
    }
}
