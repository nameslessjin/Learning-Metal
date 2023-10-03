import SwiftUI
let size: CGFloat = 400
struct ContentView: View {
    @State var options = Options()
    
    var body: some View {
        VStack(alignment: .leading) {
            ZStack {
                MetalView(options: options)
                    .border(Color.black, width: 2)
                    .frame(width: size, height: size)
            }
            Picker(
                selection: $options.renderChoice,
                label: Text("Render Options")) {
                    Text("Train").tag(RenderChoice.train)
                    Text("Quad").tag(RenderChoice.quad)
            }
                .pickerStyle(SegmentedPickerStyle())
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
