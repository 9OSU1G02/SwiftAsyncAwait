

import SwiftUI

/// A view that displays a preset text animation.
struct TitleView: View {
  @State private var title = "s|2 |2k|0 |1y|3"

  var body: some View {
    Text(title)
      .font(.custom("Datalegreya-Gradient", size: 36, relativeTo: .largeTitle))
  }
}
