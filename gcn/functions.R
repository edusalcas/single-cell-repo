obtainLinks <- function(ID, APIpath) {
  
  request <- GET(url = paste0(APIpath, "project/downloads/", ID))
  response <- content(request, as = "text", encoding = "UTF-8")
  df <- rjson::fromJSON(response, simplify=T)
  df <- setDT(as.data.frame(do.call(cbind, lapply(df, function(x) unlist(x)))), keep.rownames=T)
  colnames(df) <- c("name", "link")
  df$link <- as.character(df$link)
  
  return(df)

}
  

obtainMatrix <- function(df, workingPath) {
  
  # Obtain matrix files
  index <- match("filteredTPMLink", df$name)
  
  if (!is.na(index)) {
    url <- df$link[df$name=="filteredTPMLink"]
    prefix <- ".expression_tpm"
  } else {
    url <- df$link[df$name=="normalisedCountsLink"]
    prefix <- ".aggregated_filtered_normalised_counts"
  }
  
  
  temp <- tempfile()
  download.file(url, temp)
  
  unzip(temp, paste0(projectName, prefix, ".mtx"))
  unzip(temp, paste0(projectName, prefix, ".mtx_rows"))
  unzip(temp, paste0(projectName, prefix, ".mtx_cols"))
  
  unlink(temp)
  
  # Preprocess matrix file
  matrix <- readMM(paste0(workingPath, "/", projectName, prefix, ".mtx"))
  genes <- read.table(paste0(workingPath, "/", projectName, prefix, ".mtx_rows"), sep="\t") 
  stopifnot(identical(genes$V1, genes$V2))
  genes <- as.vector(genes$V1)
  cells <- readLines(paste0(workingPath, "/", projectName, prefix, ".mtx_cols"))
  colnames(matrix) <- cells
  rownames(matrix) <- genes
  saveRDS(matrix, paste0(workingPath, "/", projectName, gsub(".mtxt", "", prefix), ".rds"))  
  
  files <- list.files(workingPath, pattern=".mtx*", full.names=T)
  file.remove(files)
  
  return(matrix)
  
}


obtainClustering <- function(df, matrix) {
  
  # Obtain clustering file
  clustering <- getURL(df$link[df$name=="clusteringLink"])
  clustering <- read.csv(textConnection(clustering), sep="\t")
  clustering <- clustering[clustering$sel.K==TRUE, -c(1,2)]
  index <- match(colnames(matrix), colnames(clustering)[-c(1,2)])
  
  if(sum(is.na(index))==ncol(clustering)) {
    colnames(matrix) <- gsub("\\.", "-", colnames(matrix))
    colnames(clustering) <- gsub("\\.", "-", colnames(clustering))
  }
 
  stopifnot(identical(colnames(matrix), colnames(clustering)))
  
  return(clustering)
  
}



obtainMetadata <- function(df, matrix, workingPath) {
  
  # Obtain metadata file
  metadata <- getURL(df$link[df$name=="experimentDesignLink"])
  metadata <- read.csv(textConnection(metadata), sep="\t")
  metadata <- metadata[match(colnames(matrix), metadata$Assay), ]
  stopifnot(identical(colnames(matrix), as.character(metadata$Assay)))
  
  # Preprocess metadata file
  ## Remove ontology cols
  index <- grep("Ontology", colnames(metadata))
  metadata <- metadata[, -index]
  
  ## Remove experimental cols
  index <- grep("Factor.Value.", "", colnames(metadata))
  
  if(length(index)>0) {
    metadata <- metadata[, -index]
  }
  
  ## Add cluster
  cluster <- obtainClustering(df, matrix)
  stopifnot(identical(names(cluster), as.character(metadata$Assay)))
  cluster <- as.numeric(as.character(cluster))
  metadata <- as.data.frame(cbind(metadata, cluster))
  
  ## Check if we have cell.type labels for each cell
  index <- grep("cell.type", colnames(metadata))
  
  if(length(index)>0) {
    metadata <- metadata[metadata[, index]!="not applicable", ]
  } 
  # else -> we suppose every cell belongs to the same cell-type
  
  ## Simplify colnames 
  colnames(metadata) <- gsub("Sample.Characteristic.", "", colnames(metadata))
  colnames(metadata) <- gsub("\\.$", "", colnames(metadata))
  
  ## Remove cols with the same value for all cells
  # colsToRemove <- c()
  # 
  # for (i in 1:ncol(metadata)) {
  #   term <- as.character(metadata[, i])
  #   counts <- table(term)
  # 
  #   if (length(counts)==1) {
  #     colsToRemove <- c(colsToRemove, i)
  #   }
  # 
  # }
  # 
  # metadata <- metadata[, -colsToRemove]
   
  ## Remove cols with different names but the same information (duplicated cols)
  metadata <- metadata[!duplicated(lapply(metadata, summary))]
  
  ## Remove single-cell identifier col (we will use Assay as cell ID)
  index <- grep("identifier", colnames(metadata))
  
  if(length(index)>0) {
    metadata <- metadata[, -index]
  }
  
  ## Transform all col into numeric cols except age (different preprocess), assay and individual 
  # index <- match(c("age", "Assay", "individual", "cell.type", "organism.part", "sampling.site", "metastatic.site"), colnames(metadata))
  # index <- index[!is.na(index)]
  # 
  # if (!is.null(dim(metadata[, -index]))) {
  #     metadata[ , -index] <- apply(metadata[, -index], 2, function(x) as.numeric(factor(x)))
  #   } else {
  #     metadata[ , -index] <- as.numeric(factor(metadata[ , -index]))
  #   }
  
  ## Transform age col as numeric col
  index <- grep("^age$", colnames(metadata))
  
  if(length(index)>0) {
    metadata$age <- as.character(metadata$age)
    metadata$age <- gsub("not applicable", "-1", metadata$age)
    metadata$age <- parse_number(metadata$age)
  }
  
  saveRDS(metadata, paste0(workingPath, "/", "ExpDesign-", projectName, ".rds"))

}



obtainFiles <- function(ID, APIpath, myPath) {
  
  # Obtain links
  df <- obtainLinks(ID, APIpath)
  
  # Create dir if doesn't exist
  projectName <- df$link[df$name=="project_ID"]
  workingPath <- paste0(myPath, "/", projectName)
  
  if(!(dir.exists(workingPath))) {
    cat("Creating", workingPath, "directory\n")
    dir.create(workingPath)
  }
  
  setwd(workingPath)
  myFiles <- list.files(workingPath)
  index <- grep(".rds", myFiles)
  
  if (length(index)==1) {
    cat("We already have the matrix created\n")
    matrix <- readRDS(paste0(workingPath, "/", myFiles[index]))
    cat("Creating metadata file\n")
    metadata <- obtainMetadata(df, matrix, workingPath)
    
  } else if (length(index)==0) {
    cat("Creating matrix file\n")
    matrix <- obtainMatrix(df, workingPath)
    cat("Creating metadata file\n")
    metadata <- obtainMetadata(df, matrix, workingPath)
  }
  
}



