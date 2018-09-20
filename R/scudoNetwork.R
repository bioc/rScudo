#' @include class.R scudo.R accessors.R
NULL

#' scudoNetwork
#'
#' A function to convert a ScudoResult in an igraph object
#'
#' Details about the function
#'
#' @param object A scudoResults object
#' @param N A numeric value.
#' @param colors A character vector
#'
#' @rdname scudoNetwork-methods
#' @export
setGeneric("scudoNetwork", function(object, N, colors = character())
    standardGeneric("scudoNetwork"))

#' @rdname scudoNetwork-methods
#' @aliases scudoNetwork,scudoResults-method
#' @usage NULL
setMethod("scudoNetwork", signature = "scudoResults", definition =
    function(object, N, colors) {

        # input checks
        stopifnot(
            is.numeric(N),
            is.vector(N),
            length(N) == 1,
            N > 0,
            N <= 1.0,
            is.character(colors),
            is.vector(colors)
        )

        if (length(colors) != 0) {
            if (any(is.na(colors))) stop("colors contains NAs")
            if (length(colors) != dim(distMatrix(object))[1]) {
                stop(paste("length of colors differs from number of samples",
                           "in object"))
            }
            if (any(is.na(stringr::str_match(colors, "^#[0-9a-fA-F]{6,8}$")))) {
                stop(paste("colors contains invalid hexadecimal colors (see",
                "documentation for correct format)"))
            }
        }

        # get distance matrix and generate adjacency matrix according to N
        adjMatrix <- matrix(0, nrow = dim(distMatrix(object))[1],
            ncol = dim(distMatrix(object))[1])
        NQuantile <- stats::quantile(distMatrix(object)[
            distMatrix(object) > sqrt(.Machine$double.eps)], probs = N)
        adjMatrix[distMatrix(object) <= NQuantile] <- 1
        colnames(adjMatrix) <- colnames(distMatrix(object))

        # generate graph using graph_from_adjacency_matrix
        result <- igraph::graph_from_adjacency_matrix(adjMatrix,
            mode = "undirected", diag = FALSE)

        # add weights
        igraph::E(result)$weight <- distMatrix(object)[as.logical(adjMatrix) &
            lower.tri(distMatrix(object))]

        # add group and color annotation
        igraph::V(result)$group <- groups(object)
        if (length(colors) == 0) {
            pal <- grDevices::rainbow(length(levels(groups(object))))
            pal <- stringr::str_extract(pal, "^#[0-9a-fA-F]{6}")
            igraph::V(result)$color <- pal[as.integer(groups(object))]
        } else {
            igraph::V(result)$color <- stringr::str_extract(colors,
            "^#[0-9a-fA-F]{6}")
        }

        result
    }
)