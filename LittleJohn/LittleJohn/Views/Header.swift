

import SwiftUI

struct Header: View {
  var body: some View {
    Label(" LittleJohn", systemImage: "chart.bar.xaxis")
      .foregroundColor(.green)
      .font(.custom("FantasqueSansMono-Regular", size: 34))
      .padding(.bottom, 20)
  }
}
