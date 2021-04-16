require(tidyverse)
require(httr)
require(jsonlite)
require(data.table)
require(RCurl)
require(rjson)


getLinks <- function(ID, APIpath=NULL) {
  
  if (!is.null(APIpath)) { # API
    request <- GET(url = paste0(APIpath, "project/downloads/", ID))
    response <- httr::content(request, as = "text", encoding = "UTF-8")
    df <- rjson::fromJSON(response, simplify=T)
    df <- setDT(as.data.frame(do.call(cbind, lapply(df, function(x) unlist(x)))), keep.rownames=T)
    colnames(df) <- c("name", "link")
    df$link <- as.character(df$link)
    
  } else { # without API
    prefix <- paste0("https://www.ebi.ac.uk/gxa/sc/experiment/", ID, "/download?fileType=")
    zipPrefix <- paste0("https://www.ebi.ac.uk/gxa/sc/experiment/", ID, "/download/zip?fileType=")
    name <- c("clusteringLink", "experimentDesignLink", "experimentMetadataLink", "filteredTPMLink", "markerGenesLink", "normalisedCountsLink", "project_ID", "rawCountsLink")
    links <- c(paste0(prefix, "cluster&accessKey="), 
                      paste0(prefix, "experiment-design&accessKey="), 
                      paste0(zipPrefix, "experiment-metadata&accessKey="), 
                      paste0(zipPrefix, "quantification-filtered&accessKey="),
                      paste0(zipPrefix, "marker-genes&accessKey="),
                      paste0(zipPrefix, "normalised&accessKey="),
                      ID,
                      paste0(zipPrefix, "quantification-raw&accessKey="))
    
    df <- data.frame(name, links)
    df$links <- as.character(df$links)

  }
  
  return(df)

}
  


readUrl <- function(url) {
  out <- tryCatch(
    {
      temp <- tempfile()
      download.file(url, temp)
      
      unzip(temp, paste0(projectName, prefix, ".mtx"))
      unzip(temp, paste0(projectName, prefix, ".mtx_rows"))
      unzip(temp, paste0(projectName, prefix, ".mtx_cols"))
      
      unlink(temp)
  
    },
    error=function(cond) {
      message(paste("URL does not seem to exist:", url))
      # message("Here's the original error message:")
      # message(cond)
 
      url <- df$link[df$name=="normalisedCountsLink"]
      prefix <- ".aggregated_filtered_normalised_counts"
      
      temp <- tempfile()
      download.file(url, temp)
      
      unzip(temp, paste0(projectName, prefix, ".mtx"))
      unzip(temp, paste0(projectName, prefix, ".mtx_rows"))
      unzip(temp, paste0(projectName, prefix, ".mtx_cols"))
      
      unlink(temp)
    
      return(prefix)
    },
    warning=function(cond) {
      message(paste("URL caused a warning:", url))
      # message("Here's the original warning message:")
      # message(cond)
     
      url <- df$link[df$name=="normalisedCountsLink"]
      prefix <- ".aggregated_filtered_normalised_counts"
      
      temp <- tempfile()
      download.file(url, temp)
      
      unzip(temp, paste0(projectName, prefix, ".mtx"))
      unzip(temp, paste0(projectName, prefix, ".mtx_rows"))
      unzip(temp, paste0(projectName, prefix, ".mtx_cols"))
      
      unlink(temp)
      
      return(prefix)
    },
    finally={
      
      # message(paste("Processed URL:", url))
      # message("Some other message at the end")
    }
  )    
  return(out)
}



getMatrix <- function(ID, workingPath, APIpath=NULL, save=F) {

  require(Matrix)
  
  # Get links
  df <- getLinks(ID, APIpath)
  
  # Get matrix files
  if(!is.null(APIpath)) {
    
    index <- match("filteredTPMLink", df$name)
  
    if (!is.na(index)) { # API
      url <- df$link[df$name=="filteredTPMLink"]
      prefix <- ".expression_tpm"
    } else {
      url <- df$link[df$name=="normalisedCountsLink"]
      prefix <- ".aggregated_filtered_normalised_counts"
    }
    
    projectName <- gsub("https://www.ebi.ac.uk/gxa/sc/experiment/", "", url)
    projectName <- gsub("\\/.*", "", projectName)
    
    temp <- tempfile()
    download.file(url, temp)
    
    unzip(temp, paste0(projectName, prefix, ".mtx"))
    unzip(temp, paste0(projectName, prefix, ".mtx_rows"))
    unzip(temp, paste0(projectName, prefix, ".mtx_cols"))
    
    unlink(temp)
    
  } else { # Without API
    prefix <- readUrl(url)
  }
 
  # Preprocess matrix file
  matrix <- readMM(paste0(workingPath, "/", projectName, prefix, ".mtx"))
  genes <- read.table(paste0(workingPath, "/", projectName, prefix, ".mtx_rows"), sep="\t") 
  stopifnot(identical(genes$V1, genes$V2))
  genes <- as.vector(genes$V1)
  cells <- readLines(paste0(workingPath, "/", projectName, prefix, ".mtx_cols"))
  colnames(matrix) <- cells
  rownames(matrix) <- genes
  
  # projectName <- df$link[df$name=="project_ID"]
  
  if (save==T) {
    saveRDS(matrix, paste0(workingPath, "/", projectName, gsub(".mtxt", "", prefix), ".rds"))  
  } 
  
  files <- list.files(workingPath, pattern=".mtx*", full.names=T)
  file.remove(files)
  
  return(matrix)
  
}


getClustering <- function(ID, workingPath, APIpath) {
  
  require(RCurl)
  
  # Get links
  df <- getLinks(ID, APIpath)
  
  # Get clustering file
  clustering <- getURL(df$link[df$name=="clusteringLink"])
  clustering <- read.csv(textConnection(clustering), sep="\t")
  clustering <- clustering[clustering$sel.K==TRUE, -c(1,2)]
  matrix <- readRDS(list.files(workingPath, pattern="^E-", full.names = T))
  index <- match(colnames(matrix), colnames(clustering)[-c(1,2)]) 
  
  if(sum(is.na(index))==ncol(clustering)) {
    colnames(matrix) <- gsub("\\.", "-", colnames(matrix))
    colnames(clustering) <- gsub("\\.", "-", colnames(clustering))
  }
 
  stopifnot(identical(colnames(matrix), colnames(clustering)))
  
  return(clustering)
  
}



getMetadata <- function(ID, workingPath=NULL, APIpath=NULL, save=F) {
 
  require(RCurl)
  
  # Get links
  df <- getLinks(ID, APIpath)
  
  # Get metadata file
  metadata <- getURL(df$link[df$name=="experimentDesignLink"])
  metadata <- read.csv(textConnection(metadata), sep="\t")
  # matrix <- readRDS(list.files(workingPath, pattern="^E-", full.names = T))
  # metadata <- metadata[match(colnames(matrix), metadata$Assay), ]
  # stopifnot(identical(colnames(matrix), as.character(metadata$Assay)))
  
  # Preprocess metadata file
  ## Remove ontology cols
  index <- grep("Ontology.Term", colnames(metadata))
  metadata <- metadata[, -index]
  
  ## Remove cols with different names but the same information (duplicated cols)
  metadata <- metadata[!duplicated(lapply(metadata, summary))]
  
  ## Simplify colnames 
  colnames(metadata) <- gsub("Sample.Characteristic", "", colnames(metadata))
  colnames(metadata) <- gsub("Factor.Value", "", colnames(metadata))
  colnames(metadata) <- gsub("\\.$", "", colnames(metadata))
  colnames(metadata) <- gsub("^\\.", "", colnames(metadata))
  
  ## Add cluster
  # cluster <- getClustering(df, matrix)
  # stopifnot(identical(names(cluster), as.character(metadata$Assay)))
  # cluster <- as.numeric(as.character(cluster))
  # metadata <- as.data.frame(cbind(metadata, cluster))
  
  ## Transform age col as numeric col
  index <- grep("^age$", colnames(metadata))
  
  if(length(index)>0) {
    metadata[, index] <- as.character(metadata[, index])
    metadata[, index] <- gsub("not applicable", -1, metadata[, index])
    metadata[, index] <- gsub("not available year", -1, metadata[, index])
    metadata[, index] <- gsub("not available", -1, metadata[, index])
    
    age <- parse_number(metadata[, index])
    ageUnit <- gsub('[0-9]+', '', metadata[, index])
    ageUnit <- gsub("\\.", "", ageUnit)
    ageUnit <- ageUnit[ageUnit!="-"]
    ageUnit <- ageUnit[ageUnit!=""]
    
    if(length(unique(ageUnit))==1) {
      metadata[, index] <- age
      metadata[, index] <- as.numeric(metadata[, index])
    } else if (length(grep("to", unique(ageUnit))>0)) {
      metadata[, index] <- age
      metadata[, index] <- as.numeric(metadata[, index])
    } else {
      cat(ID, "\n")
    }
    
  }
  
  ## Transform sex col as numeric col
  index <- grep("^sex$", colnames(metadata))
  
  if(length(index)>0) {
    metadata[, index] <- as.character(metadata[, index])

    metadata[, index] <- gsub("mixed", -1, metadata[, index]) 
    metadata[, index] <- gsub("male", 1, metadata[, index])  
    metadata[, index] <- gsub("mixed sex", -1, metadata[, index])
    metadata[, index] <- gsub("female", 0, metadata[, index]) 
    metadata[, index] <- gsub("mixed sex population", -1, metadata[, index])
    metadata[, index] <- gsub("not applicable", -1, metadata[, index])
    metadata[, index] <- gsub("not available", -1, metadata[, index])
    metadata[, index] <- gsub("male-to-female transsexual", -1, metadata[, index])
    
    }
    
  if (save==T) {
    saveRDS(metadata, paste0(workingPath, "/", "ExpDesign-", projectName, ".rds"))
  }
  return(metadata)
}



getFiles <- function(ID, APIpath, workingPath, save=T) {

  # Create dir if doesn't exist
  projectName <-ID
  workingPath <- paste0(workignPath, "/", projectName)
  
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
    metadata <- getMetadata(ID, workingPath, APIpath, save)
    
  } else if (length(index)==0) {
    cat("Creating matrix file\n")
    matrix <- getMatrix(ID, workingPath, APIpath, save)
    cat("Creating metadata file\n")
    metadata <- getMetadata(ID, workingPath, APIpat, save)
  }
  
}




getMetadataSampling <- function(metadata, samplingCovs) {
  
    # Combinations by sampling covs
    allCombs <- data.frame()
    index <- which(colnames(metadata) %in% samplingCovs)
    
    if(length(index)>0) {
      cols <- list()
      
      for (i in 1:length(index)) {
        cols[[i]] <- metadata[, colnames(metadata)[index[i]]]
      }
      
      mySplit <- split(metadata, cols, drop=TRUE)
      
      ## Show combs details
      combs <- lapply(mySplit, function(x) nrow(x))
      originalNumOfCells <- as.numeric(combs)
      
      for (j in 1:length(names(combs))) {
        names <- unlist(str_split(names(combs)[j], "\\."))
        allCombs <- rbind(allCombs, names)
        allCombs <- apply(allCombs, 2, function(x) as.character(x))
      }
      
      allCombs <- as.data.frame(allCombs)
      colnames(allCombs) <- c(colnames(metadata)[index])
    } else {
      originalNumOfCells <- nrow(metadata)
    }
    
    index_pseudo <- which(originalNumOfCells>200)
    
    if(length(index_pseudo)>0) {
      # Combinations by pseudo-cells iteration
      reps <- c()
      iter <- c()
      numOfCells <- c()
      
      for (k in 1:length(originalNumOfCells)) {
        cells <- originalNumOfCells[k]
        myIter <- 0
        numOfCells <- c(numOfCells, cells)
        iter <- c(iter, myIter)
        
        while(cells>200) {
          cells <- round(cells/2, 0)
          myIter <- myIter + 1
          numOfCells <- c(numOfCells, cells)
          iter <- c(iter, myIter)
        }
        reps <- c(reps, myIter+1)
      }
      
      allCombs <- allCombs[rep(seq_len(nrow(allCombs)), reps), ]
      allCombs <- as.data.frame(cbind(allCombs, numOfCells, iter))
      
    } 
     
    # Combinations if we decide to correct by NULL, sex, age or both
    index_sex <- grep("sex", colnames(metadata))
    index_age <- grep("age", colnames(metadata))
    
    if(length(index_sex)>0 & length(index_age)>0) {
      reps <- 4
      bioCovsToCorrect <- rep(c("NULL", "sex", "age", "both"), nrow(allCombs))
    } else if(length(index_sex)>0 & length(index_age)==0) {
      reps <- 2
      bioCovsToCorrect <- rep(c("NULL", "sex"), nrow(allCombs))
    } else if (length(index_sex)==0 & length(index_age)>0) {
      reps <- 2
      bioCovsToCorrect <- rep(c("NULL", "age"), nrow(allCombs))
    } else {
      reps <- 1
      bioCovsToCorrect <- rep("NULL", nrow(allCombs))
    }
    
    allCombs <- allCombs[rep(seq_len(nrow(allCombs)), each=reps), ]
    allCombs <- as.data.frame(cbind(allCombs, bioCovsToCorrect))
    rownames(allCombs) <- paste0("comb", 1:nrow(allCombs))
    allMetadata <- mySplit
    
    
  return(list(allCombs=allCombs, allMetadata=allMetadata))
}


# E-ENAD-27
# E-GEOD-124263
# E-GEOD-130473
# E-GEOD-75140
# E-GEOD-83139
