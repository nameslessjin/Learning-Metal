//
//  ContentView.swift
//  Particles
//
//  Created by JINSEN WU on 10/11/23.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var options = Options()
    var body: some View {
        return VStack(alignment: .leading) {
            
            ZStack {
                VStack {
                    MetalView(options: options).border(Color.black, width: 2)
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
