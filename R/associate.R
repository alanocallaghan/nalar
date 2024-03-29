#' Statistical test of association between arbitrary vector types.
#' @param a,b Vectors of covariates of arbitrary type.
#' See Details for the specific tests used.
#' @param method For numeric vs numeric, the correlation method (passed to
#' \code{\link[stats]{cor.test}})
#' @param ... Passed to specific methods.
#' @details
#' For numeric vs numeric, a correlation test.
#' For factor vs factor, a chisq test.
#' For numeric vs factor/character/logical, ANOVA.
#' @examples
#' a <- rnorm(100)
#' b <- runif(100)
#' c <- sample(letters[1:2], 100, replace = TRUE)
#' d <- sample(letters[3:5], 100, replace = TRUE)
#' associate(a, b)
#' associate(b, a)
#' associate(b, c)
#' associate(b, d)
#' associate(c, d)
#' @return A p-value of an association test.
#' @export
setGeneric("associate", function(a, b, ...) standardGeneric("associate"))

#' @rdname associate
#' @export
setMethod(
    "associate",
    signature(a = "numeric", b = "numeric"),
    function(a, b, method = "spearman") {
        stats::cor.test(a, b, method = method, exact = FALSE)[["p.value"]]
    }
)

.do_anova <- function(a, b) {
    tryCatch(
        suppressWarnings(stats::anova(stats::lm(b ~ a))[["Pr(>F)"]][[1]]),
        error = function(e) NA
    )
}

#' @rdname associate
#' @export
setMethod(
    "associate",
    signature(a = "factor", b = "numeric"),
    .do_anova
)

#' @rdname associate
#' @export
setMethod(
    "associate",
    signature(a = "numeric", b = "factor"),
    function(a, b) {
        .do_anova(b, a)
    }
)

#' @rdname associate
#' @export
setMethod(
    "associate",
    signature(a = "factor", b = "factor"),
    function(a, b) {
        if (length(unique(a)) == 1 || length(unique(b)) == 1) {
            return(NA)
        }
        if (all(colSums(table(a, b) != 0) == 1)) {
            return(NA)
        }
        tryCatch(
            stats::chisq.test(a, b, simulate.p.value = TRUE)[["p.value"]],
            error = function(...) NA
        )
    }
)

#' @rdname associate
#' @export
setMethod(
    "associate",
    signature(a = "character", b = "ANY"),
    function(a, b) {
        associate(factor(a), b)
    }
)
#' @rdname associate
#' @export
setMethod(
    "associate",
    signature(a = "Date", b = "ANY"),
    function(a, b) {
        associate(as.numeric(a), b)
    }
)
#' @rdname associate
#' @export
setMethod(
    "associate",
    signature(a = "ANY", b = "Date"),
    function(a, b) {
        associate(a, as.numeric(b))
    }
)

#' @rdname associate
#' @export
setMethod(
    "associate",
    signature(a = "ANY", b = "POSIXct"),
    function(a, b) {
        associate(a, as.numeric(b))
    }
)
#' @rdname associate
#' @export
setMethod(
    "associate",
    signature(a = "POSIXct", b = "ANY"),
    function(a, b) {
        associate(as.numeric(a), b)
    }
)

#' @rdname associate
#' @export
setMethod(
    "associate",
    signature(a = "ANY", b = "POSIXt"),
    function(a, b) {
        associate(a, as.numeric(b))
    }
)
#' @rdname associate
#' @export
setMethod(
    "associate",
    signature(a = "POSIXt", b = "ANY"),
    function(a, b) {
        associate(as.numeric(a), b)
    }
)


#' @rdname associate
#' @export
setMethod(
    "associate",
    signature(a = "character", b = "character"),
    function(a, b) {
        associate(factor(a), factor(b))
    }
)

#' @rdname associate
#' @export
setMethod(
    "associate",
    signature(a = "ANY", b = "character"),
    function(a, b) {
        associate(factor(b), a)
    }
)

#' @rdname associate
#' @export
setMethod(
    "associate",
    signature(a = "ANY", b = "factor"),
    function(a, b) {
        associate(b, a)
    }
)

#' @rdname associate
#' @export
setMethod(
    "associate",
    signature(a = "logical", b = "ANY"),
    function(a, b) {
        associate(factor(a), b)
    }
)

#' @rdname associate
#' @export
setMethod(
    "associate",
    signature(a = "ANY", b = "logical"),
    function(a, b) {
        associate(a, factor(b))
    }
)
