require(knitr)
require(markdown)
setwd("./Getting-and-Cleaning-Data-Course-Project")
knit("run_analysis.Rmd", encoding="ISO8859-1")
markdownToHTML("run_analysis.md", "run_analysis.html")
