#! /usr/bin/env Rscript
# FROM: https://lapis.cov-spectrum.org/#plot-the-global-distribution-of-all-sequences

library(jsonlite)
library(ggplot2)

# Query the API
date_from <- format(Sys.Date() - as.difftime(100, unit = "days"), "%Y-%m-%d")
query <- paste0(
  "https://lapis.cov-spectrum.org/open/v1/sample/aggregated?",
  "fields=date",
  "&country=Switzerland",
  "&dateFrom=", date_from,
  "&pangoLineage=B.1.617.2*"
)
response <- fromJSON(query)

# Check for errors
errors <- response$errors
if (length(errors) > 0) {
  stop("Errors")
}

# Check for deprecation
deprecationDate <- response$info$deprecationDate
if (!is.null(deprecationDate)) {
  warning(paste0("This version of the API will be deprecated on ", deprecationDate,
                 ". Message: ", response$info$deprecationInfo))
}

# The data is good to be used!
data <- response$data

# Make a plot
(p <- ggplot(
  data,
  aes(x = as.Date(date), y = count)) + 
  geom_col() + 
  theme_bw() + 
  labs(x = element_blank(), y = "Count") + 
  scale_x_date(date_breaks = "1 month", date_labels = "%B %Y") + 
  ggtitle("Count of delta samples in Switzerland in the past 100 days"))

ggplot2::ggsave(plot = p, filename = "plot.pdf", dpi = 300)