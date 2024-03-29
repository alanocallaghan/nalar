% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/maximise-trace.R
\name{maximise_trace}
\alias{maximise_trace}
\title{Maximise the trace of a matrix.}
\usage{
maximise_trace(mat)
}
\arguments{
\item{mat}{Input matrix}
}
\value{
A matrix with rows permuted such that tr(mat) is maximised.
}
\description{
Maximising the trace of a matrix amounts to maximising the diagonal elements.
This is useful when comparing clustering methods, or comparing clustering
results with known ground truth labels.
}
\examples{
# say we have the output of a clustering algorithm on 100 samples
a <- sample(letters[1:5], 100, replace = TRUE)
# now imagine we repeat it and get different labels for the same clusters
releveler <- setNames(letters[1:5], sample(letters[1:5]))
b <- releveler[a]
# comparing the results, it can be hard to spot which cluster is which
table(a, b)
# if we permute the rows to maximise the trace it's pretty obvious
maximise_trace(table(a, b))
}
