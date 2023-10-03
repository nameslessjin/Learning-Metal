import SwiftUI

let originalColor = Color(red: 0.8, green: 0.8, blue: 0.8)
let size: CGFloat = 400
struct ContentView: View {
    @State private var showGrid = true
    
    var body: some View {
        VStack(alignment: .leading) {
            ZStack {
                MetalView()
                    .border(Color.black, width: 2)
                if showGrid {
                    Grid()
                }
            }
            .frame(width: size, height: size)
            ZStack(alignment: .top) {
                Key()
                Toggle("Show Grid", isOn: $showGrid)
                    .padding(.leading, 250)
            }
        }
        .padding()
    }
}

struct Key: View {
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Rectangle()
                    .foregroundColor(originalColor)
                    .frame(width: 20, height: 20)
                Text("Original triangle")
            }
            HStack {
                Rectangle()
                    .foregroundColor(.red)
                    .frame(width: 20, height: 20)
                Text("Transformed triangle")
            }
        }
        .padding(0)
    }
}

struct Grid: View {
  var cellSize: CGFloat = size / 20
  var body: some View {
    ZStack {
      HStack {
        ForEach(0..<Int(cellSize)) { _ in
          Spacer()
          Divider()
        }
      }
      VStack {
        ForEach(0..<Int(cellSize)) { _ in
          Spacer()
          Divider()
        }
      }
      HStack {
        ZStack {
          Divider()
          Divider()
          Divider()
        }
      }
      VStack {
        ZStack {
          Divider()
          Divider()
          Divider()
        }
      }
    }
  }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
        }
    }
}
