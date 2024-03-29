#' Graphical test between principal components and a table of covariates.
#'
#' @param a A matrix or data.frame-alike of covariates.
#' @param b A matrix, or the output of \code{\link[stats]{prcomp}}.
#' @param method The method used to calculate PCs. Can be \code{"irlba"}
#' for \code{\link[irlba]{prcomp_irlba}} for truncated PCA or
#' \code{\link[stats]{prcomp}} for standard PCA.
#' @param center,scale Passed to PCA methods. Should the data be scaled and
#' centered before performing PCA?
#' @param n The maximum number of variables to be shown in the PCA plot
#' (the top n are taken based on the minimum association p-value).
#' @param npcs The number of PCs to truncate the results to. For large datasets
#' visualising >50 PCs is unwieldy so setting this to (e.g.) 20 can be very
#' useful.
#' @param max_iterations Passed to \code{\link[irlba]{prcomp_irlba}}.
#' @param vars_keep,vars_ignore Vectors of variables to keep or remove from the
#' plot, regardless of p-value filtering.
#' @param progress_bar Show a progress bar when testing associations? Useful
#' for very large datasets.
#' @param ... Passed to specific methods.
#' @examples
#' mat <- matrix(rnorm(1000), ncol = 10)
#' pc <- prcomp(mat)
#' pca_association_plot(mat, pc)
#' ## only the top 5 associations
#' pca_association_plot(mat, pc, n = 5)
#' @return The output of plot_grid, a set of plots showing variance explained
#' and associations between the columns of \code{a} and the principal components
#' of \code{b}.
#' @export
setGeneric("pca_association_plot", function(a, b, ...) {
    standardGeneric("pca_association_plot")
})

#' @rdname pca_association_plot
#' @export
setMethod(
    "pca_association_plot",
    signature(a = "data.frame", b = "matrix"),
    function(a, b,
             method = c("irlba", "prcomp"),
             n = 20,
             npcs = min(ncol(a) - 1, nrow(a) - 1, 50),
             center = TRUE,
             scale = TRUE,
             max_iterations = 100000,
             vars_keep = NULL,
             vars_ignore = NULL,
             ...) {
        method <- match.arg(method)
        ## -1 because irlba has to be truncated
        pcs <- switch(method,
            "irlba" = {
                prcomp_irlba(b,
                    n = npcs,
                    center = center,
                    scale. = scale,
                    maxit = max_iterations
                )
            },
            "prcomp" = {
                prcomp(b,
                    center. = center,
                    scale. = scale
                )
                pca_association_plot(a, pcs, n = n, npcs = npcs, vars_keep = vars_keep, vars_ignore = vars_ignore, ...)
            }
        )
    }
)

#' @rdname pca_association_plot
#' @export
setMethod(
    "pca_association_plot",
    signature(a = "ANY", b = "ANY"),
    function(a, b, ...) {
        pca_association_plot(as.data.frame(a), b, ...)
    }
)

#' @rdname pca_association_plot
#' @export
setMethod(
    "pca_association_plot",
    signature(a = "data.frame", b = "missing"),
    function(a, b, ...) {
        pca_association_plot(a, a, ...)
    }
)

#' @rdname pca_association_plot
#' @export
setMethod(
    "pca_association_plot",
    signature(a = "ANY", b = "data.frame"),
    function(a, b, ...) {
        pca_association_plot(a, as.matrix(b), ...)
    }
)

.pc_plot_df_prcomp <- function(
        a, b,
        npcs = ncol(b$x),
        ncovariates = 20,
        vars_keep = NULL,
        vars_ignore = NULL,
        progress_bar = FALSE,
        ...
    ) {
    pcs <- b$x[, seq_len(npcs), drop = FALSE]
    a <- a[, setdiff(colnames(a), vars_ignore)]
    pvals <- .associate_dfs(a, pcs, progress_bar = progress_bar)

    ## drop cols that are all NA    
    ind_all_na <- apply(pvals, 2, function(x) all(!is.finite(x)))
    pvals <- pvals[, !ind_all_na]

    ## keep only the top ncovariates based on min pvals
    min_pval <- apply(pvals, 2, min)
    ind_drop <- rank(min_pval) <= ncovariates
    name_drop <- setdiff(colnames(pvals)[ind_drop], vars_keep)
    pvals <- pvals[, name_drop, drop = FALSE]

    # calculate variance explained
    eigs <- (b$sdev^2)
    varexp <- eigs / sum(eigs)
    varexp <- varexp[seq_len(npcs)]

    # convert PC1 to PC01, accounting for if we only have PC1 to PC9 or
    # even have PC1 to PC101
    # this is so lexicographical sort works
    nzeros <- nchar(as.character(ncol(pvals)))
    rownames(pvals) <- gsub("PC(\\d+)", "\\1", rownames(pvals))
    sprintf_string <- paste0("PC %0", nzeros, "d")
    rownames(pvals) <- sprintf(sprintf_string, as.numeric(rownames(pvals)))

    hm <- .pvalue_heatmap(t(pvals), ...)
    .add_varexp(hm, varexp)
}

#' @rdname pca_association_plot
#' @export
setMethod(
    "pca_association_plot",
    signature(a = "data.frame", b = "irlba_prcomp"),
    .pc_plot_df_prcomp
)

#' @rdname pca_association_plot
#' @export
setMethod(
    "pca_association_plot",
    signature(a = "data.frame", b = "prcomp"),
    .pc_plot_df_prcomp
)

.add_varexp <- function(heatmap, varexp) {
    barplot <- ggplot() +
        aes(
            factor(
                paste0(seq_along(varexp)),
                levels = paste0(seq_along(varexp))
            ),
            varexp
        ) +
        geom_col() +
        scale_x_discrete(
            name = NULL
        ) +
        scale_y_continuous(
            name = "% of variance",
            labels = scales::percent,
            expand = c(0.0, 0, 0.05, 0)
        ) +
        theme_bw() +
        theme(
            panel.border = element_blank(),
            axis.text.x = element_blank(),
            axis.ticks.x = element_blank(),
            panel.grid.major.x = element_blank(),
            panel.grid.minor.x = element_blank()
        )
    plot_grid(barplot, heatmap, align = "v", ncol = 1, axis = "tblr", rel_heights = c(0.2, 0.8))
}

.pvalue_heatmap <- function(pvalues, varexp, min_pvalue = NULL, ...) {
    stopifnot(inherits(pvalues, "matrix"))
    if (!is.null(min_pvalue)) {
        stopifnot(min_pvalue > 0 && min_pvalue < 1)
        pvalues[pvalues < min_pvalue] <- min_pvalue
    }
    if (is.null(colnames(pvalues))) {
        colnames(pvalues) <- paste0("Col", seq_len(ncol(pvalues)))
    }
    if (is.null(rownames(pvalues))) {
        rownames(pvalues) <- paste0("Row", seq_len(nrow(pvalues)))
    }

    mdf <- reshape2::melt(pvalues)
    # reshape2 melt seems to coerce Var1 to numeric sometimes
    mdf$Var1 <- factor(mdf$Var1, levels = sort(unique(as.character(mdf$Var1))))
    mdf$Var2 <- factor(mdf$Var2, levels = sort(unique(as.character(mdf$Var2))))

    ggplot(mdf, aes(x = .data$Var2, y = .data$Var1, fill = .data$value)) +
        geom_tile(colour = "grey80") +
        scale_fill_distiller(
            palette = "YlGnBu",
            name = "p-value",
            trans = "log10",
            limits = c(min(pvalues), 1)
        ) +
        theme_bw() +
        theme(
            panel.border = element_blank(),
            axis.text.x = element_text(hjust = 1, angle = 45),
            axis.title.x = element_blank(),
            axis.title.y = element_blank()
        )
}
