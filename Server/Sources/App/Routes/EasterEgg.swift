

import Foundation
import Vapor

struct EasterEgg {
  static let encoder = JSONEncoder()

  static func routes(_ app: Application) throws {
    app.get("easteregg") { req -> Response in
let responseData = """
Ray Wenderlich

Ray's favorite joke (first told to me by to Christine Sweigart!)

- What did sushi A say to sushi B?
- Wassap, B! (Wasabi)

---

Manda Frederick

The best way out is always through. - Robert Frost

---

Marin Todorov

”Why sometimes I’ve believed as many as six impossible things before breakfast.”
— The White Queen, Through the Looking-Glass

---

Richard Turton

In the codebase, the modern codebase
The actor sleeps tonight
In the codebase, the modern codebase
The actor sleeps tonight

async-await async-await async-await async-await
async-await async-await async-await async-await
async-await async-await async-await async-await

eeeeeeeeeeeeEEEEEeeeeasy  async await...

---

Shai Mishali

"February 2nd, 2022 is 2/2/22, which is a Tuesday.
Or really ... a Two's Day?!"

""".data(using: .utf8)!
      return Response(body: .init(data: responseData))
    }
  }
}
