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
        VStack(alignment: .leading) {
            ZStack {
                VStack {
                    MetalView(options: options)
                        .border(Color.black, width: 2)
                    RadioButton(label: "Rendering", options: ["Deferred", "Forward"]) {
                        checked in
                        options.renderChoice = checked == 0 ? .deferred : .forward
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
