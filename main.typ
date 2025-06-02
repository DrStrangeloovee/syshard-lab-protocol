
#import "@preview/basic-report:0.2.0": *

#show: it => basic-report(
  doc-category: "SYSHARD",
  doc-title: "Lab Protocol Security Exercise",
  author: ("Marco AUENHAMMER", "Waldermar SCHERER").join(", \n"),
  affiliation: "FH Technikum Wien",
  // logo: image("assets/aerospace-engineering.png", width: 2cm),
  // <a href="https://www.flaticon.com/free-icons/aerospace" title="aerospace icons">Aerospace icons created by gravisio - Flaticon</a>
  language: "en",
  compact-mode: false,
  heading-color: rgb("#8bb31d"),
  heading-font: "Noto Sans",
  it,
)

// Style figure captions to fit the rest of the text
#show figure.caption: it => context [
  *#it.supplement~#it.counter.display()#it.separator*#it.body
]

// Style code blocks with a grey background
#show raw.where(block: true): set block(fill: luma(240), inset: 1em, radius: 0.5em, width: 100%)

// Rootpassword: MyRootPassword1!
// Userpassword: MyUserPassword1!
// Encryptpassword: MyEncryptPassword1!
//

// Chapter: Procedure and setup
#include "procedure-and-setup.typ"

// Chapter: Analysis Part
#include "analysis-part.typ"

// Chapter: Conclusions
#include "conclusions.typ"

// Chapter: References
#include "references.typ"

// Chapter: Appendix
#include "appendix.typ"


