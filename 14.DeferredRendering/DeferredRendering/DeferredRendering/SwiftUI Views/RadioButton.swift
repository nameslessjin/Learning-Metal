//
//  RadioButton.swift
//  Metal-Rendering
//
//  Created by JINSEN WU on 10/6/23.
//

import SwiftUI

struct RadioButton: View {
    let label: String
    let options: [String]
    let action: (_ checked: Int) -> Void
    
    @State var checked: Int = 0
    var body: some View {
        VStack(alignment: .trailing) {
            ForEach(0..<options.count, id: \.self) {
                index in
                HStack {
                    Text(options[index])
                    index == checked ? 
                    Image(systemName: "smallcircle.filled.circle")
                        .font(Font.system(.title).bold())
                        .onTapGesture {
                            checked = index
                            action(index)
                        }
                    :
                    Image(systemName: "circle")
                        .font(Font.system(.title).bold())
                        .onTapGesture {
                            checked = index
                            action(index)
                        }
                }
            }
        }
    }
}

struct RadioButton_Previews: PreviewProvider {
    static var previews: some View {
        RadioButton(label: "Options:", options: ["on", "off"]) { _ in }
    }
}
