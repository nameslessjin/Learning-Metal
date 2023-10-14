//
//  ContentView.swift
//  Textures
//
//  Created by JINSEN WU on 9/29/23.
//

import SwiftUI

struct ContentView: View {
    @State var options = Options()
    var body: some View {
        VStack(alignment: .leading) {
            ZStack {
                MetalView(options: options)
                    .border(Color.black, width: 2)
//                    .frame(width: 800, height: 400)
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
