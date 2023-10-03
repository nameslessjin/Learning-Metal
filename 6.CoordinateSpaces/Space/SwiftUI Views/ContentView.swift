import SwiftUI

let size: CGFloat = 400
struct ContentView: View {
    var body: some View {
        VStack(alignment: .leading) {
            ZStack {
                MetalView().border(Color.black, width: 2)
            }
            .frame(height: size)
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
