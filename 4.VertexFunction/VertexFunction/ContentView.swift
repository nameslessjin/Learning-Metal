//
//  ContentView.swift
//  VertexFunction
//
//  Created by JINSEN WU on 9/25/23.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            MetalView()
                .border(Color.black, width: 2)
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider
{
    static var previews: some View {
        ContentView()
            .preferredColorScheme(/*@START_MENU_TOKEN@*/.dark/*@END_MENU_TOKEN@*/)
            .environment(\.sizeCategory, .accessibilityLarge)
    }
}
