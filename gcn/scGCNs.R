# Load library
library(dplyr)

# Load functions
myPath <- "/home/aligo/API/"
source(paste0(myPath, "scGCNsFunctions.R"))
source(paste0(myPath, "functions.R"))

# Specify API path if necessary 
APIpath <- NULL
# APIpath <- "http://194.4.102.168:5000/"

# Select one project ID
ID <- "E-CURD-12"

# Create dir if necessary 
if(!(dir.exists(paste0(myPath, "/", ID)))) {
  cat("Creating", paste0(myPath, "/", ID), "directory\n")
}

workingPath <- NULL

# Download data (with or without API)
metadata <- getMetadata(ID, workingPath, APIpath, save=F)
matrix <- getMatrix(ID, workingPath, APIpath, save=F)

# Match metadata rows and matrix columns in order to select QC+ cells
metadata <- metadata[match(colnames(matrix), metadata$Assay), ]
stopifnot(identical(colnames(matrix), as.character(metadata$Assay)))

# Metadata preprocess
## Remove cols where we only have one possible value
metadata <- metadata %>% select(where(~length(unique(.)) > 1))

## Remove rows without sex
sexCov <- grep("sex", colnames(metadata))

if(length(sexCov)>0) {
  cellsToRemove <- which(metadata[, sexCov]==-1)
  if(length(cellsToRemove)>0) {
    metadata <- metadata[-cellsToRemove, ]
  }
}

## Remove rows without age
ageCov <- grep("^age$", colnames(metadata))

if(length(ageCov)>0) {
  cellsToRemove <- which(metadata[, ageCov]==-1)
  if(length(cellsToRemove)>0) {
    metadata <- metadata[-cellsToRemove, ]
  }
}

# Detecting batch cov
possibleBatchCovs <- c("block", "microwell.plate", "passage", "plate", "well", "well.information")
batchCov <- intersect(colnames(metadata), possibleBatchCovs)
if(length(batchCov)==0) {
  batchCov <- NULL
}

# Specify bioCovsToCorrect
if (length(sexCov)>0 & length(ageCov)>0) {
  allBioCovsToCorrect <- list("NULL", "sex", "age", c("sex", "age"))
  
} else if (length(sexCov)>0 & length(ageCov)==0) {
  allBioCovsToCorrect <- list("NULL", "sex")
  
} else if (length(sexCov)==0 & length(ageCov)>0) {
  allBioCovsToCorrect <- list("NULL", "age")
  
} else if (length(sexCov)==0 & length(ageCov)==0) {
  allBioCovsToCorrect <- "NULL"
}


# Split matrix (if necessary) based on sampling covs

## Define which cell.type criteria we are going to use 
index_ct <- grep("cell.type", colnames(metadata))

if(length(index_ct)!=0) {
  ct <- "cell.type"
} else {
  index_ct <- grep("inferred.cell.type...ontology.labels", colnames(metadata))

  if(length(index_ct)!=0) {
    ct <- "inferred.cell.type...ontology.labels"
  } else {
    index_ct <- grep("inferred.cell.type...authors.labels", colnames(metadata))
    
    if(length(index_ct)!=0){
      ct <- "inferred.cell.type...authors.labels"
    } else {
      ct <- NULL
    }
  }
}

## Define sampling covs + selected cell-type 
samplingCovs <- c("organism", "organism.part", "sampling.site", "biopsy.site", "metastatic.site", "developmental.stage", "cell.line", ct)
cellTypes <- c("cell.type", "inferred.cell.type...ontology.labels", "inferred.cell.type...authors.labels")
mainCovs <- c("Assay", "sex", "age")

## Create a list of metadata based on sampling covs
mySplit <- getMetadataSampling(metadata, samplingCovs) 

## Define parameters
idCov <- "Assay"
plots <- F

if(is.null(dim(mySplit))) { # That means we have more than one combination
  
  for (i in 1:length(mySplit))
    # Metadata preprocess
    ## Remove sampling covs cols, the rest of cell-types criteria and individual col
    myMetadata <- mySplit[[i]]
    myMetadata <- myMetadata[, -which(colnames(metadata) %in% c(samplingCovs, "individual", setdiff(samplingCovs, cellTypes)))]
    
    ## Transform all col into numeric cols except age, sex, assay and individual (necessary to estimate modules-covariates correlations)
    diff <- setdiff(colnames(metadata), c(samplingCovs, mainCovs))

    if(length(diff)>0) {
      if (!is.null(dim(myMetadata[, diff]))) {
        metadata[ , diff] <- apply(metadata[, diff], 2, function(x) as.numeric(factor(x)))
      } else {
        metadata[ , diff] <- as.numeric(factor(metadata[ , diff]))
      }
    }
      
    # Matrix preprocess
    myMatrix <- exprData[, match(myMetadata$Assay, colnames(matrix))]
    stopifnot(identical(as.character(myMetadata$Assay), colnames(myMatrix)))
    
    # Create a new fold for this split (organism part, sampling site, cell type)
    foldName <- paste0(ID, "_", "comb", i)
    
    if(!(dir.exists(paste0(myPath, ID, "/", foldName)))) {
      cat("Creating", paste0(myPath, ID, "/", foldName), "directory\n")
      dir.create(paste0(myPath, projectName, "/", foldName))
    }
    
    # Create a new fold for each combination in allBioCovsToCorrect
    for (bioCovsToCorrect in allBioCovsToCorrect) {
      
      foldNameCond <- paste0(foldName, "_", bioCovsToCorrect)
      
      # Initial scGCN
      mySum <- getNet(myExprData,
                      myMetadata,
                      name=foldNameCond,
                      batchCov=batchCov,
                      idCov=idCov,
                      bioCovsToCorrect=unlist(bioCovsToCorrect),
                      filteringGenes=F,
                      filteringCutoff=NULL,
                      filteringProportion=NULL,
                      plots=plots,
                      path=paste0(myPath, projectName, "/", foldName))
        
      iter <- 0
      
      # pseudo-cells scGCNs
      while(ncol(myExprData) > 200) {
        iter <- iter + 1
        newName <- paste0(foldNameCond, "_iter", iter)
        myPseudoCells <- pseudoCells(myExprData, myMetadata)
        newExprData <- myPseudoCells[[1]]
        newMetaData <- myPseudoCells[[2]]
        
        if(!(dir.exists(paste0(myPath, projectName, "/", foldName, "/", foldNameCond, "/", newName)))) {
          
          mySum <- getNet(newExprData,
                          newMetaData,
                          name=newName,
                          batchCov=batchCov,
                          idCov=idCov,
                          bioCovsToCorrect=unlist(bioCovsToCorrect),
                          filteringGenes=F,
                          filteringCutoff=NULL,
                          filteringProportion=NULL,
                          plots=plots,
                          path=paste0(myPath, projectName, "/", foldName, "/", foldNameCond))
        }
        myExprData <- newExprData
        myMetadata <- newMetaData
      }
      
    }
  
} else { # There is only one combination
  
    myMetadata <- metadata
    myExprData <- exprData
    stopifnot(identical(as.character(myMetadata$Assay), colnames(myExprData)))
    
    ## Transform all col into numeric cols except age, sex, assay and individual (necessary to estimate modules-covariates correlations)
    diff <- setdiff(colnames(metadata), c(samplingCovs, mainCovs))
    
    if(length(diff)>0) {
      if (!is.null(dim(myMetadata[, diff]))) {
        metadata[ , diff] <- apply(metadata[, diff], 2, function(x) as.numeric(factor(x)))
      } else {
        metadata[ , diff] <- as.numeric(factor(metadata[ , diff]))
      }
    }
    
    # Matrix preprocess
    myMatrix <- exprData[, match(myMetadata$Assay, colnames(matrix))]
    stopifnot(identical(as.character(myMetadata$Assay), colnames(myMatrix)))
    
    # Create a new fold for this split (organism part, sampling site, cell type)
    foldName <- paste0(ID, "_", "comb1")
    
    if(!(dir.exists(paste0(myPath, ID, "/", foldName)))) {
      cat("Creating", paste0(myPath, ID, "/", foldName), "directory\n")
      dir.create(paste0(myPath, projectName, "/", foldName))
    }
    
    for (bioCovsToCorrect in allBioCovsToCorrect) {
      cat("Correcting by", bioCovsToCorrect, "\n")
      
      # Preprocess projectName
      if(nchar(projectName)>15) {
        foldName <- paste0(gsub("\\-.*", "", projectName), "_", paste0(unlist(bioCovsToCorrect), collapse=""))
      
        } else {
        foldName <- paste0(projectName, "_", paste0(unlist(bioCovsToCorrect), collapse=""))
      }
      
      if(!(dir.exists(paste0(myPath, projectName, "/", foldName)))) {
        cat("Creating", paste0(myPath, projectName, "/", foldName), "directory\n")
        dir.create(paste0(myPath, projectName, "/", foldName))
      }
      
      iter <- 0
      
      if(!(dir.exists(paste0(myPath, projectName, "/", foldName, "/", foldName, "_iter", iter)))) {
        
        # Initial scGCN
        mySum <- getNet(exprData=myExprData,
                        covs=myMetadata,
                        name=paste0(foldName, "_iter", iter),
                        batchCov=batchCov,
                        idCov=idCov,
                        bioCovsToCorrect=unlist(bioCovsToCorrect),
                        filteringGenes=F,
                        filteringCutoff=NULL,
                        filteringProportion=NULL,
                        plots=plots,
                        path=paste0(myPath, projectName, "/", foldName, "/"))
       
      }
      
      
      # pseudo-cells scGCNs
      while(ncol(myExprData) > 200) {
        iter <- iter + 1
        myPseudoCells <- pseudoCells(myExprData, myMetadata)
        newExprData <- myPseudoCells[[1]]
        newMetaData <- myPseudoCells[[2]]
        
        if(!(dir.exists(paste0(myPath, projectName, "/", foldName, "/", foldName, "_iter", iter)))) {
          
          mySum <- getNet(newExprData,
                          newMetaData,
                          name=paste0(foldName, "_iter", iter),
                          batchCov=batchCov,
                          idCov=idCov,
                          bioCovsToCorrect=unlist(bioCovsToCorrect),
                          filteringGenes=F,
                          filteringCutoff=NULL,
                          filteringProportion=NULL,
                          plots=plots,
                          path=paste0(myPath, projectName, "/", foldName, "/"))
        }
        myExprData <- newExprData
        myMetadata <- newMetaData
      
      }
    }
  }



