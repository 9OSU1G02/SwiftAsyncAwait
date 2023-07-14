

import App
import Vapor

print("""

  ★*ﾟ*☆*ﾟ*★*ﾟ*☆*ﾟ*★★*ﾟ*☆*ﾟ*★*ﾟ*☆*ﾟ*★★*ﾟ*☆*ﾟ*★*ﾟ*☆*ﾟ*★
  This is the "Modern Concurrency in Swift" book server.
  The projects in the book are server-driven
  so keep this app running while you work
  through the book excercises.

  Have a great day!
  ★*ﾟ*☆*ﾟ*★*ﾟ*☆*ﾟ*★★*ﾟ*☆*ﾟ*★*ﾟ*☆*ﾟ*★★*ﾟ*☆*ﾟ*★*ﾟ*☆*ﾟ*★

""")

var env = try Environment.detect()
try LoggingSystem.bootstrap(from: &env)
let app = Application(env)
defer { app.shutdown() }
try configure(app)
try app.run()
