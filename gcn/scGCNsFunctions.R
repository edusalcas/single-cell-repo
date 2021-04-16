getMetadata <- function(globalMetadata, condition1, condition2=NULL) {
  
  # Check arguments
  if (missing(globalMetadata)) { stop("Please provide a global covs table\n")}
  if (missing(condition1)) { stop("Please provide at least a variable name in order to split globalCovs table\n")}
  
  # Split the global covariate table based on the proposed conditions
  if(!is.null(condition2)) {
    conditions <- list(globalMetadata[, condition1], globalMetadata[, condition2])
  } else {
    conditions <- list(globalMetadata[, condition1])
  }
  
  sp <- split(globalMetadata, conditions, drop=TRUE)
  
  return(sp)
}


#################################################################################################

metadata2Covs <- function(metadata, 
                          cellID, 
                          samplesCovs, 
                          sampleID) {
  
  # Check arguments
  if (missing(metadata)) { stop("Please provide metadata table\n")}
  if (missing(cellID)) { stop("Please provide the name of the column that represents cellID\n")}
  if (missing(samplesCovs)) { stop("Please provide samplesCovs table\n")}
  if (missing(sampleID)) { stop("Please provide a the name of the column that represents sampleID\n")}
  
  # The sample IDs in the individual's covariate table must be in the same order as the sample IDs in the cell metadata table
  samplesNames <- unique(metadata[, sampleID])
  index <- match(samplesNames, samplesCovs[, sampleID])
  newSamplesCovs <- samplesCovs[index, ]
  stopifnot(identical(samplesNames, newSamplesCovs[, sampleID]))
  
  # We write down the number of cells of each individual
  reps <- table(metadata[, sampleID])
  index <- match(samplesNames, names(reps))
  reps <- reps[index]
  stopifnot(identical(samplesNames, names(reps)))
  
  # We repeat the covariates of the individuals as many times as we have cells for each one
  cellsCovs <- newSamplesCovs[rep(seq_len(nrow(newSamplesCovs)), reps), ]
  stopifnot(identical(cellsCovs[, sampleID], metadata[, sampleID]))
  
  # Add cellID and remove sampleID from table
  cellsCovs <- cbind(metadata[, cellID], cellsCovs[, -1])
  colnames(cellsCovs)[1] <- cellID
  
  return(cellsCovs)
}


#################################################################################################


getExprDataAndMetadata <- function(globalExprData=NULL,
                                   globalMetadata,
                                   condition1,
                                   condition2=NULL,
                                   cellID,
                                   outputDir=getwd(),
                                   initialCondition=NULL,
                                   initialExprDataDir=NULL,
                                   samplesCovs=NULL,
                                   sampleID=NULL) {
  
  # Check arguments
  if (missing(globalMetadata)) { stop("Please provide a global covs table\n")}
  if (missing(condition1)) { stop("Please provide at least a variable name in order to split globalMatrix table\n")}
  if (missing(globalExprData) & missing(initialExprDataDir)) { stop("Please provide a global counts matrix or specify the directory of the expression files\n")}
  if (missing(cellID)) { stop("Please provide the name of the column that represents cellID\n")}
  
  # Load libraries
  require(Matrix)
  
  # Check if the directories exists and, if not, create it
  exprDataDir <- paste0(outputDir, "/exprData/")
  metadataDir <- paste0(outputDir, "/metadata/")
  
  if(!(dir.exists(exprDataDir))) {
    cat("Directory for the expression data not found, creating one.\n")
    dir.create(exprDataDir)
  }
  
  if(!(dir.exists(metadataDir))) {
    cat("Directory for the metadata not found, creating one.\n")
    dir.create(metadataDir)
  }
  
  # If we have a global matrix
  
  if (!is.null(globalExprData)) {
    
    # We are going to create a metadata table for each level of condition 1
    spMetadata <- getMetadata(globalMetadata=globalMetadata, condition1=condition1)
    
    # For each level of condition 1
    for (i in 1:length(spMetadata)) {
      metadata <- spMetadata[[i]]
      index <- match(metadata[, cellID], colnames(globalExprData))
      exprData <- globalExprData[, index]
      stopifnot(identical(metadata[, cellID], colnames(exprData)))
      
      name <- gsub(" ", "_", names(spMetadata)[i])
      name <- gsub("-", "_", name)
      
      saveRDS(exprData, paste0(exprDataDir, name, "_", "exprData", ".rds"))
      
      # If the metadata file already contains all the information we want
      if (is.null(samplesCovs)) {
        saveRDS(metadata, paste0(metadataDir, name, "_", "metadata", ".rds"))
        
        # If we want to create a metadata file from the covariates of the individuals
      } else {
        cellsCovs <- metadata2Covs(metadata, cellID, samplesCovs, sampleID)
        saveRDS(cellsCovs, paste0(metadataDir, name, "_", "metadata", ".rds"))
      }
    }
  }
  
  
  # If we do not have a global expression matrix but instead we have this matrix divided into a set of matrices
  
  if (!is.null(initialCondition)) {
    # We are going to create a metadata table for each array using the initial condition 
    spMetadata <- getMetadata(globalMetadata=globalMetadata, condition1=initialCondition)
    
    # We are going to list the expression files
    myFiles <- list.files(path=initialExprDataDir, pattern=".rds")
    
    # Now we have a covariate file and expression file for each cell type
    stopifnot(setequal(names(spMetadata), gsub(".rds", "", myFiles)))
    
    # The covariate tables must be in the same order as the names of the expression arrays
    index <- match(names(spMetadata), gsub(".rds", "", myFiles))
    spMetadata <- spMetadata[index]
    stopifnot(identical(names(spMetadata), gsub(".rds", "", myFiles)))
    
    # For each combination table of covariates-matrix of expression
    for (i in 1:length(spMetadata)) {
      metadata <- spMetadata[[i]]
      
      # We select the normalized expression array
      exprData <- as.matrix(readRDS(paste0(initialExprDataDir, myFiles[i])))
      
      # Take only the expression data of the cells for which we have the metadata
      index <- match(metadata[, cellID], colnames(exprData))
      exprData <- exprData[, index]
      stopifnot(identical(metadata[, cellID], colnames(exprData)))
      
      # Now split this table of covariates according to the desired final condition
      newSpMetadata <- getMetadata(metadata, condition1=condition1)
      
      # For each new partition
      for (j in 1:length(newSpMetadata)) {
        newMetadata <- newSpMetadata[[j]]
        index <- match(newMetadata[, cellID], colnames(exprData))
        newExprData <- exprData[, index]
        stopifnot(identical(newMetadata[, cellID], colnames(newExprData)))
        
        firstName <- gsub(" ", "_", names(spMetadata)[i])
        firstName <- gsub("-", "_", firstName)
        secondName <- names(newSpMetadata)[j]
        
        cat("Creating the files for", firstName, secondName, "\n")
        
        saveRDS(newExprData, paste0(exprDataDir, firstName, "_", secondName, "_", "exprData", ".rds"))
        
        # If the metadata file already contains all the information we want
        if (is.null(samplesCovs)) {
          saveRDS(newMetadata, paste0(metadataDir, firstName, "_", secondName, "_", "metadata", ".rds"))
          
          # If we want to create a metadata file from the covariates of the individuals
        } else {
          cellsCovs <- metadata2Covs(newMetadata, cellID, samplesCovs, sampleID)
          stopifnot(identical(colnames(newExprData), cellsCovs[, cellID]))
          
          saveRDS(cellsCovs, paste0(metadataDir, firstName, "_", secondName, "_", "metadata", ".rds"))
        }
      }
    }
  }
  cat("Expression files are available in the", exprDataDir, "directory\n")
  cat("The metadata files are available in the", metadataDir, "directory\n")
}

#################################################################################################


pair = function(indexes, paired){
  
  set.seed(1234)
  # Check arguments
  if (missing(indexes)) { stop("Please provide indexes\n")}
  if (missing(paired)) { stop("Please provide ids\n")}
  
  # if(is.null(paired)){
  #   indexes = sample(indexes)
  #   iout = do.call(rbind,lapply(seq(1,length(indexes) - 1,2),
  #                               function(x){
  #                                 c(indexes[x],indexes[x + 1])
  #                               }))
  # }else{
  stopifnot(length(indexes) == length(paired))
  
  # Deal with ids with one sample
  iout = NULL
  mytab = table(paired)
  keys = names(mytab)[mytab == 1]
  
  for(key in keys){
    positions = as.character(paired) == key
    lindexes = indexes[positions]
    ids = which(positions)
    pairs = do.call(rbind,lapply(seq(1,length(lindexes),2),
                                 function(x){
                                   c(lindexes[x],lindexes[x])
                                 }))
    
    iout = rbind(iout,cbind(pairs,rep(key,nrow(pairs))))
  }
  
  # Deal with ids with a set of samples
  keys = names(mytab)[mytab > 1]
  for(key in keys){
    positions = as.character(paired) == key
    lindexes = indexes[positions]
    ids = which(positions)
    pairs = do.call(rbind,lapply(seq(1,length(lindexes)-1,2),
                                 function(x){
                                   c(lindexes[x],lindexes[x+1])
                                 }))
    
    iout = rbind(iout,cbind(pairs,rep(key,nrow(pairs))))
    # }
  }
  
  return(iout)
}

#################################################################################################

pseudoCells <- function(exprData, covs, save=F, outputDir=pase0(getwd(), "/pseudoCells/")) {
  
  require(stringr)
  
  # Check arguments
  if (missing(exprData)) { stop("Please provide an expression matrix\n")}
  if (missing(covs)) { stop("Please provide a table of covariates\n")}
  
  cat("Creating pseudo-cells from", ncol(exprData), "cells \n")
  
  # Check the name of the cells to get the indexes correctly
  colnames(exprData) <- str_extract_all(colnames(exprData), "[0-9]+")
  
  # Get the indices using the pair function
  round1 = pair(1:ncol(exprData), colnames(exprData))
  
  # Create pseudo-cells expression matrix from these indices
  r1expr <- apply(round1, 1, function(x) {exprData[, as.numeric(x[1])] + exprData[, as.numeric(x[2])]})
  colnames(r1expr) <- round1[, 3]
  rownames(r1expr) <- rownames(exprData)
  
  # Update the covariate table to match with the new expression array
  r1covs <- covs[as.numeric(round1[,1]), ]
  
  # Save the results
  myResults <- NULL
  myResults[[1]] <- r1expr
  myResults[[2]] <- r1covs
  names(myResults) <- c("pseudoCellsExprData", "pseudoCellsCovs")
  
  cat(ncol(r1expr), "pseudo-cells created\n")
  
  # Save the results as files
  if (save==T) {
    name = deparse(substitute(exprData))
    
    if(!(dir.exists(outputDir))){
      cat("Directory for the pseudo-data not found, creating one.")
      dir.create(outputDir)
    }
    
    saveRDS(myResults, outputDir, paste0(name, "PseudoCells.rds"))
    
    cat("The pseudo-cells file has been stored in the", outputDir, "directory.\n")
  }
  return(myResults)
}


######################################################################################

fromEnsemblIDtoExternalName <- function(genes) {
  
  # Check arguments
  if (missing(genes)) { stop("Please provide a list of genes\n")}
  
  # Load library
  require(biomaRt)
  
  match <- grep("ENSG", genes)
  
  if (length(match)>0) {
    cat("A nomenclature of ensemble_gene_id has been detected, changing to external gene name...\n")
    cat("Number of genes before changing the nomenclature:", length(genes), "\n")
    
    # Get the external gene names
    mart=useMart(biomart="ENSEMBL_MART_ENSEMBL",dataset="hsapiens_gene_ensembl")
    genesNames <- getBM(attributes=c("ensembl_gene_id","external_gene_name"), 
                        filters="ensembl_gene_id", 
                        values=genes, 
                        mart=mart,
                        useCache=FALSE)
    
    # Remove duplicated genes
    duplicatedGenes <- duplicated(genesNames$external_gene_name)
    genesNames <- genesNames[grep("FALSE", duplicatedGenes), ]
    
    # Change the nomenclature of genes in the original matrix
    index <- match(genes, genesNames$ensembl_gene_id)
    genesNames2 <- genesNames[index[!is.na(index)], ]
    genes_HGCN <- genesNames2$external_gene_name
    genes_ensembl <- genesNames2$ensembl_gene_id
    
    cat("Number of genes after changing the nomenclature:", length(genes_HGCN), "\n")
    cat("Showing some examples of gene names with the new nomenclature", genes_HGCN[1:5], "\n")
    
    return(list(genes_HGCN, genes_ensembl))
    
  } else {
    cat("An external gene name nomenclature has been detected, nothing needs to be changed.\n")
    return(genes)
  }
  
}

######################################################################################

prepareData <- function(exprData, covs, batchCov=NULL, idCov, filteringGenes=F, filteringCutoff=NULL, filteringProportion=NULL) {
  
  # Check arguments
  if (missing(exprData)) { stop("Please provide an expression matrix\n")}
  if (missing(covs)) { stop("Please provide a table of covariates\n")}
  if (!is.null(batchCov) && is.null(idCov)) { stop("Please provide the name of the variable that represents the id of the samples\n")}
  
  # Load library
  require(preprocessCore)
  require(stringr)
  require(CoExpNets)
  require(biomaRt)
  
  cat("Preparing data\n")
  
  cat("Checking the name of cells in the expression matrix\n")
  
  # Check the name of the cells (columns)
  colnames(exprData) <- covs[ , idCov]
  
  cat("Checking that all variables are numeric except ID (and batch if there is one)\n")
  # Convert all covariates to numeric type except ID and batch effect 
  covs <- as.data.frame(covs)
  index <- match(idCov, colnames(covs))
  
  if(!is.null(dim(covs[, -index]))) {
    covs[, -index] <- apply(covs[, -index], 2, function(x) {as.numeric(factor(x))})
    covs[, idCov] <- as.character(covs[, idCov])
  } else {
    covs[, -index] <- as.numeric(factor(covs[, -index]))
  }

  
  if (!is.null(batchCov)) {
    
    cat("Check batch effect\n")
    
    colnames(exprData) <- str_extract_all(colnames(exprData), "[0-9]+")
    
    # Check complete cases
    covs[, batchCov] <- as.factor(as.character(covs[, batchCov]))
    covs <- covs[complete.cases(covs[ , batchCov]), ]
    
    # Check batch effect as factor
    covs[, batchCov] <- as.factor(as.character(covs[, batchCov]))
    
    # Check number of samples of each batch effect
    batchDistr <- table(covs[, batchCov])
    batchEffectsToSelect <- names(batchDistr[batchDistr>1])
    covs <- covs[covs[, batchCov] %in% batchEffectsToSelect, ]
    exprData <- exprData[, colnames(exprData) %in% covs[, idCov]]
    
    colnames(exprData) <- covs[ , idCov]
  }
  
  cat("Number of genes before filtering:", dim(exprData)[1], "\n")
  
  if (filteringGenes) {
    
    expressedGenes <- rowSums(exprData > filteringCutoff)  > (filteringProportion * ncol(exprData))
    filteredData <- exprData[expressedGenes,]
    cat("- Number of genes with expression >", filteringCutoff, "in at least", filteringProportion, "of the samples:", nrow(filteredData), "\n")
    
  } else {
    filteredData <- exprData
  }
  
  # Check the name of the genes (rows)
  cat("Checking the name of genes in the expression matrix\n")
  
  match <- grep("ENSG", rownames(filteredData))
  
  if (length(match)>0) {
    
    genesNames <- fromEnsemblIDtoExternalName(rownames(filteredData))
    
    if (length(genesNames[[2]])<nrow(filteredData)) {
      filteredData <- filteredData[match(genesNames[[2]], rownames(filteredData)), ]
      rownames(filteredData) <- genesNames[[1]]
    } else {
      rownames(filteredData) <- genesNames[[1]]
    }
    stopifnot(identical(rownames(filteredData), genesNames[[1]]))
  }
  
  cat("Quantile-normalisation\n")
  genesNames = rownames(filteredData)
  samplesNames = colnames(filteredData)
  exprDataQN = normalize.quantiles(as.matrix(filteredData))
  rownames(exprDataQN) <- genesNames
  colnames(exprDataQN) <- samplesNames
  cat("All done\n")
  
  return(list(normalized_expression=as.matrix(exprDataQN), covariates=covs))
}

######################################################################################


plotMDS_Batch <- function(exprData, covs, batchCov,
                          save=F, outputDir=getwd()) {
  
  # Check arguments
  if (missing(expr.data)) { stop("Please provide an expression matrix\n")}
  if (missing(covs)) { stop("Please provide a table of covariates\n")}
  
  # Load library
  require(limma)
  
  # Represent batch effect using limma::plotMDs function
  name= deparse(substitute(exprData))
  covs[, batchCov] <- as.factor(covs[, batchCov])
  
  # Take a sample to make the representation
  mask = sample(1:ncol(exprData), 100)
  
  # Color each sample according to the batchCov level to which it belongs
  colors = rainbow(length(unique(as.numeric(covs[,batchCov]))))
  finalcolors = colors[as.numeric(covs[, batchCov])][mask]
  
  # If save==TRUE, open a pdf file
  if (save == TRUE){
    cat("Starting MDS plots\n")
    pdf(file = paste0(outputDir,"/", gsub(" ", "_", name),
                      "_MDS_using_", batchCov,".pdf"))
  }
  limma::plotMDS(exprData[, mask], col=finalcolors,
                 main=paste0(name, "_MDS_using_", batchCov))
  legend("topright", fill=colors,
         legend=levels(covs[,batchCov]))
  
  if (save==TRUE) {
    dev.off()
    cat("Done\n")
  }
  
}

##########################################################################################################

combatCorrect <- function(preparedExprData,
                          preparedCovs,
                          batchCov,
                          bioCovsToCorrect,
                          PCA_plots = F,
                          name=deparse(substitute(preparedExprData)),
                          outputDir = paste0(getwd(), "pcaPlots/")) {
  
  # Check arguments
  if (missing(preparedExprData)) { stop("Please provide an expression matrix\n")}
  if (missing(preparedCovs)) { stop("Please provide a table of covariates\n")}
  if (missing(batchCov)) { stop("Please provide the name of the variable that represents the batch effect\n")}
  if (missing(bioCovsToCorrect)) { stop("Please provide the name of the biological variables that you want not to correct\n")}
  
  # Load libraries
  require(sva)
  require(swamp)
  require(CoExpNets)
  
  # Prepare data
  preparedCovs[, bioCovsToCorrect] <- as.numeric(as.character(preparedCovs[, bioCovsToCorrect]))
  
  # Correct data
  cat("Correcting batch effect with combat.\n")
  combatExprData = ComBat(dat=as.matrix(preparedExprData), batch=as.factor(preparedCovs[, batchCov]),
                          mod=model.matrix(~1, data=preparedCovs[, bioCovsToCorrect]))
  combatExprData = combatExprData - min(combatExprData)
  
  cat("Done\n")
  
  if (PCA_plots ==T){
    if(!(dir.exists(outputDir))){
      cat("Directory for the plots not found, creating one.\n")
      dir.create(outputDir)
    }
    cat("PCA uncorrected and plotting in process\n")
    pdf(file = paste0(outputDir, name, "_PCA_uncorrected.pdf"))
    pcres = prince(preparedExprData, preparedCovs[, c(batchCov, bioCovsToCorrect)], top=20)
    CoExpNets::princePlot(prince=pcres,
                          main=paste0("PCA for" ,
                                      name, "\n uncorrected"))
    dev.off()
    cat("PCA uncorrected done.\nPCA corrected and plotting in process\n")
    pdf(file = paste0(outputDir, name, "_PCA_corrected.pdf"))
    pcres = prince(combatExprData, preparedCovs[, c(batchCov, bioCovsToCorrect)],top=20)
    CoExpNets::princePlot(prince=pcres,
                          main=paste0("PCA for" ,
                                      name, "\n corrected"))
    dev.off()
    cat("PCA corrected done\n")
  }
  return(combatExprData)
}


######################################################################################

svaCorrection = function(combatExprData, 
                         preparedCovs,
                         bioCovsToCorrect,
                         idCov,
                         batchCov=NULL, 
                         plots = T,
                         outputDir = paste0(getwd(),"/svas_plots/"),
                         name=deparse(substitute(combatExprData)),
                         save = T,
                         residsOutput=paste0(getwd(), "/residuals/")) {
  
  # Check arguments
  if (missing(combatExprData)) { stop("Please provide an expression matrix\n")}
  if (missing(preparedCovs)) { stop("Please provide a table of covariates\n")}
  if (missing(bioCovsToCorrect)) { stop("Please provide the name of the biological variables that you want not to correct\n")}
  
  # Load libraries
  require(CoExpNets)
  require(swamp)
  require(sva)
  require(dplyr)
  
  # Prepare data
  preparedCovs <- as.data.frame(preparedCovs)
  preparedCovs[, idCov] <- as.character(preparedCovs[, idCov])
  
  if(!is.null(batchCov)) {
    preparedCovs[, batchCov] <- as.factor(as.character(preparedCovs[, batchCov]))
  }
  
  # Creating the models
  myCovs <- paste0(bioCovsToCorrect, collapse=" + ")
  mm = model.matrix(~ eval(parse(text=myCovs)), data=preparedCovs)
  nullmm = model.matrix(~ 1,data=preparedCovs)
  
  cat("Launching svaseq, this will take some time\n")
  svas=sva::svaseq(dat=as.matrix(combatExprData),mod=mm,mod0=nullmm)
  colnames(svas$sv) <- paste0("SV", seq(1:ncol(svas$sv)))
  
  if (svas$n.sv != 0){
    ## LM correction.
    cat("\nStarting linear model correction\n")
    numericCovs = dplyr::select_if(preparedCovs, is.numeric) # In this way, we avoid selecting the ID and batch
    index <- match(bioCovsToCorrect, colnames(numericCovs)) 
    numericCovs = numericCovs[, -index] # We remove bioCovsToCorrect because we want to study the association between the SVs and the covariates of interest
    
    cat("Studying the correlation between svs and the covariates:", paste0(colnames(numericCovs), collapse=", "), "\n")
    
    linp = matrix(ncol=svas$n.sv,nrow=ncol(numericCovs))
    rownames(linp) = colnames(numericCovs)
    colnames(linp) = paste0("SV",1:svas$n.sv)
    linp[] = 0
    
    for(cov in 1:ncol(numericCovs)){
      for(sva in 1:svas$n.sv){ if(svas$n.sv == 1)
        axis = svas$sv else
          axis = svas$sv[,sva]
        linp[cov,sva] = cor.test(as.numeric(unlist(numericCovs[,cov])),axis)$p.value
      }
    }
    smallest = -10
    linp10 <- log10(linp)
    linp10 <- replace(linp10, linp10 <= smallest, smallest)
    tonote <- signif(linp, 1)
    
    # We remove the SVs that are significantly associated with some covariate of interest.
    linp <- as.data.frame(linp)
    mins <- sapply(linp, min)
    svToRemove <- names(mins[which(mins < 0.05)])
    
    if (length(svToRemove>0)) {
      index <- which(colnames(svas$sv) %in% svToRemove)
      svas$sv <- svas$sv[, -index]
    }
  }
  
  if (svas$n.sv != 0) {
    covs.rs = as.data.frame(preparedCovs[,match(bioCovsToCorrect, colnames(preparedCovs))])
    cat("Creating residuals taking into account", paste0(colnames(svas$sv), collapse=", "), "\n")
    resids <- apply(combatExprData, 1, function(y){
      lm( y ~ . , data=cbind(covs.rs,svas$sv))$residuals
    })
    
  } else{
    covs.rs = preparedCovs[,match(bioCovsToCorrect,colnames(preparedCovs))]
    cat("Creating residuals taking into account all svs \n")
    resids <- apply(combatExprData, 1, function(y){
      lm( y ~ . , data=cbind(covs.rs))$residuals
    })
  }
  
  if ((plots == T) & (svas$n.sv != 0) & (ncol(linp10)>=2) & (nrow(linp10)>=2) ){
    cat("Creating plots\n")
    
    if(!(dir.exists(outputDir))){
      cat("Directory for the plots not found, creating one.")
      dir.create(outputDir)
    }
   
    pdf(file = paste0(outputDir, name, "_Corr_of_SVs_and_covs.pdf"))
   
    heatmap.2(linp10, Colv = F, Rowv = F, dendrogram = "none",
              trace = "none", symbreaks = F, symkey = F,
              breaks = seq(-20, 0, length.out = 100),
              key = T, colsep = NULL, rowsep = NULL, sepcolor = "black",
              sepwidth = c(0.05, 0.05), main = "Corr. of SVs and covs.\n Combat-FPKM QN",
              labCol = colnames(linp10),
              labRow = colnames(numericCovs),
              xlab = "Surrogate variables",
              cexRow=0.5,
              margins=c(5, 10))
    dev.off()
    
    # pdf(file = paste0(outputDir, name, "_residuals_corr.pdf"))
    # pcres = prince(as.matrix(CoExpNets::trasposeDataFrame(resids,F)),covs.rs,top=20)
    # CoExpNets::princePlot(prince=pcres, margins=c(5, 10),
    #                       main=paste0(name,": residual cor.\n with ", paste0(bioCovsToCorrect, collapse=", ")))
    # dev.off()
    cat("Plots done\n")
    
  } else if ((plots == T) & (svas$n.sv == 0)){
    
    if(!(dir.exists(outputDir))){
      cat("Directory for the plots not found, creating one.")
      dir.create(outputDir)
    }
    
    pdf(file = paste0(outputDir, name, "_residuals_corr.pdf"))
    pcres = prince(as.matrix(CoExpNets::trasposeDataFrame(resids,F)),covs.rs,top=20)
    CoExpNets::princePlot(prince=pcres, margins=c(5, 10), cexRow=0.5,
                          main=paste0(name,": \n residual cor.\n with ", paste0(bioCovsToCorrect, collapse=", ")))
    
  }
  if(save==T){
    cat("Saving residuals\n")
    
    if(!(dir.exists(residsOutput))){
      cat("Directory for the residuals not found, creating one.")
      dir.create(residsOutput)
    }
    rownames(resids) <- preparedCovs[, idCov]
    saveRDS(resids,paste0(residsOutput, name, "_resids", ".rds"))
    cat(paste0("Residuals saved at: ", residsOutput, "\n"))
  }
  cat("Done\n")
  return(resids)
}

####################################################################################################

myGetGProfilerOnNet <- function(net.file,
                                filter=c("GO","KEGG","REAC"),
                                ensembl=FALSE,
                                exclude.iea=T,
                                organism = "hsapiens",
                                correction.method="gSCS",
                                out.file=NULL) {
  
  require(gprofiler2)
  require(CoExpNets)
  
  if(typeof(net.file) == "character")
    net <- readRDS(net.file)
  else
    net = net.file
  
  modules = unique(net$moduleColors)
  
  background <- names(net$moduleColors)
  if(ensembl)
    background <- CoExpNets::fromEnsembl2GeneName(background)
  
  all.genes <- NULL
  for(module in modules){
    
    genes <- names(net$moduleColors)[net$moduleColors == module]
    if(ensembl)
      genes <- fromEnsembl2GeneName(genes)
    all.genes[[module]] <- genes
  }
  
  go <- gprofiler2::gost(all.genes,
                         correction_method=correction.method,
                         #custom_bg=background,
                         sources=filter,
                         organism=organism,
                         exclude_iea=exclude.iea)
  
  go <- as.data.frame(go$result)
  
  if(nrow(go) == 0)
    return(go)
  #png_fn = paste0(out.file,".png"),
  #no_isects=T)
  go.out = cbind(go,rep(NA,nrow(go)))
  colnames(go.out) = c(colnames(go),"IC")
  
  go.out$parents <- gsub("\\(|\\)", "", go.out$parents)
  go.out$parents <- gsub("c", "", go.out$parents)
  go.out$parents <- gsub("\"", "", go.out$parents)
  go.out$parents <- as.character(go.out$parents)
  
  #	#Now we will add our own column with the information content of each term
  #	#So it is possible to evaluate them
  cat("Generating IC-BP")
  loadICsGOSim("GO:BP")
  mask = go$source == "GO:BP"
  bp.terms.go = go$term_id[mask]
  bp.ic.go = IC[bp.terms.go]
  go.out$IC[mask] = bp.ic.go
  
  cat("Generating IC-MF")
  loadICsGOSim("GO:MF")
  mask = go$source == "GO:MF"
  mf.terms.go = go$term_id[mask]
  mf.ic.go = IC[mf.terms.go]
  go.out$IC[mask] = mf.ic.go
  
  cat("Generating IC-CC")
  loadICsGOSim("GO:CC")
  mask = go$source == "GO:CC"
  cc.terms.go = go$term_id[mask]
  cc.ic.go = IC[cc.terms.go]
  go.out$IC[mask] = cc.ic.go
  #
  #	data("ICsMFhumanall")
  #	data("ICsCChumanall")
  
  if(!is.null(out.file)){
    write.csv(go.out,out.file)
    cat("Obtained",nrow(go),"terms saved at",out.file,"\n")
  }else{
    cat("Obtained",nrow(go),"terms\n")
  }
  return(go.out)
}

loadICsGOSim = function(onto){
  stopifnot(onto %in% c("GO:BP","GO:MF","GO:CC"))
  if(onto == "GO:BP")
    load(system.file("", "ICsBPhumanall.rda", package = "CoExpNets"),.GlobalEnv)
  else if(onto == "GO:MF")
    load(system.file("", "ICsMFhumanall.rda", package = "CoExpNets"),.GlobalEnv)
  else
    load(system.file("", "ICsCChumanall.rda", package = "CoExpNets"),.GlobalEnv)
}

getICReport = function(gprof){
  ontologies = c("GO:BP","GO:CC","GO:MF")
  ics = NULL
  for(onto in ontologies){
    loadICsGOSim(onto)
    terms = gprof$term_id[gprof$source == onto]
    ics[[onto]] = IC[terms]
    names(ics[[onto]]) = terms
  }
  return(ics)
}

################################################################################################

myGenAnnotationCellType = function(tissue="None",
                                   which.one="new",
                                   markerspath=system.file("ctall", "",
                                                           package = "CoExpNets"),
                                   net.in=NULL,
                                   legend=NULL,
                                   doheatmap=T,
                                   notHuman=F,
                                   plot.file=NULL,
                                   threshold=20,
                                   return.processed=F,
                                   getMarkerSize=F,
                                   getOnlyOverlap=F,
                                   getMyOwnTest=F,
                                   applyFDR=F,
                                   display.cats=NULL){ #This last flag FALSE when you want the raw p-values
  
  require(gplots)
  
  cat("Entering genAnnotationCellType with",which.one,"\n")
  
  if(which.one == "new"){
    if(typeof(net.in) == "character")
      net = readRDS(net.in)
    else
      net = net.in
  }else{
    net = getNetworkFromTissue(tissue=tissue,which.one=which.one)
  }
  modules = unique(net$moduleColors)
  if(notHuman)
    names(net$moduleColors) = toupper(names(net$moduleColors))
  #So the 1st heatmap
  #will have a column for each cell.types element and a row for
  #each module and we will show -log10(p-values) in a scale
  
  files = list.files(path=markerspath,full.names = T)
  files = files[grep(pattern=".txt$",files)]
  if(getMarkerSize){
    sizes = lapply(files,function(x){
      nrow(read.delim(x,header=T))
    })
    return(cbind(markerset=files,genes=sizes))
  }
  
  
  markernames = gsub(".txt","",basename(files))
  
  
  ctypes = markernames
  ctypedata = matrix(ncol=length(modules),nrow=length(files))
  ctypedata[,] = 1
  rownames(ctypedata) = ctypes
  colnames(ctypedata) = modules
  
  if(getOnlyOverlap){
    myfunction = Vectorize(function(m,f){
      submarkers = read.delim(f,stringsAsFactors=F,header=T)[,1]
      #cat("Module is",m,"file is",f,"\n")
      #print(names(net$moduleColors)[net$moduleColors == m])
      #print(submarkers)
      return(sum(submarkers %in% names(net$moduleColors)[net$moduleColors == m]))
    })
    
    overlap = outer(modules,files,myfunction)
    colnames(overlap) = gsub(".txt","",basename(files))
    rownames(overlap) = modules
    if(applyFDF){
      overlap = p.adjust(overlap,method="fdr")
    }
    return(overlap)
    
  }
  
  if(getMyOwnTest){
    myfunction = Vectorize(function(m,f){
      submarkers = read.delim(f,stringsAsFactors=F,header=T)[,1]
      ov = sum(submarkers %in% names(net$moduleColors)[net$moduleColors == m])
      nm = sum(net$moduleColors == m)
      
      #cat("Module is",m,"file is",f,"\n")
      #print(names(net$moduleColors)[net$moduleColors == m])
      #print(submarkers)
      return(testGeneSet(n.module=nm,total.specific=length(submarkers),
                         total.net=length(net$moduleColors),n.module.and.specific=ov)$p.value)
    })
    
    overlap = outer(modules,files,myfunction)
    colnames(overlap) = gsub(".txt","",basename(files))
    rownames(overlap) = modules
    return(overlap)
    
  }
  
  
  
  all.gene.names = names(net$moduleColors)
  all.gene.names = CoExpNets::fromAny2GeneName(names(net$moduleColors))
  
  tmp.enr.f = paste0(markerspath,"enrichment_tmp.csv")
  if(file.exists(tmp.enr.f))
    file.remove(tmp.enr.f)
  ukbec.en = WGCNA::userListEnrichment(all.gene.names,net$moduleColors,files,
                                       nameOut=tmp.enr.f)
  if(file.exists(tmp.enr.f)){
    enrichment = read.csv(tmp.enr.f,
                          stringsAsFactors=F)
    
    for(i in 1:nrow(enrichment)){
      module = enrichment$InputCategories[i]
      for(j in 1:length(files)){
        if(grepl(ctypes[j],enrichment$UserDefinedCategories[i]))
          break
      }
      category = ctypes[j]
      ctypedata[category,module] = enrichment$CorrectedPvalues[i]
    }
  }
  rownames(ctypedata) = gsub("cell_type_TableS1.csv.","",rownames(ctypedata))
  uctypedata = ctypedata
  ctypedata = ctypedata[,apply(ctypedata,2,function(x){ any(x < 1)}),drop=FALSE]
  ctypedata = -log10(ctypedata)
  ctypedata[is.infinite(ctypedata)] = max(ctypedata[!is.infinite(ctypedata)])
  
  if(threshold > 0)
    ctypedata[ctypedata > threshold] = threshold
  #Order by cell type
  
  ctypedata = ctypedata[order(rownames(ctypedata)),,drop=FALSE]
  
  ctypedata = ctypedata[apply(ctypedata,1,function(x){ any(x > 2)}),]
  
  
  if(doheatmap){
    ctypedata = as.data.frame(ctypedata)
    if((ncol(ctypedata) >= 2) && nrow(ctypedata) >=2){
      ctypedata = as.matrix(ctypedata)
      if(is.null(legend))
        legend = tissue
      if(!is.null(plot.file))
        pdf(plot.file,width=15,height=8)
      heatmap.2(ctypedata,
                trace="none",
                col=heat.colors(100)[100:1],
                cexCol=1.0,
                cexRow=1.0,
                Rowv=F,
                Colv=T,
                main=paste0("Cell type enrichment for ",legend),
                key=F,srtCol=45,dendrogram="none",
                margins=c(6,20))
      y= ctypedata
      if(!is.null(plot.file))
        dev.off()
    }
  }
  
  if(return.processed)
    return(ctypedata)
  return(uctypedata)
}

############################################################################################


myGetDownstreamNetwork = function(tissue="mytissue",
                                  n.iterations=50,	#Number of iterations for k-means, 50 recommended
                                  min.exchanged.genes=20,
                                  expr.data, 	#We expect a file name pointing to a dataframe (RDS format) with
                                  #genes in columns and samples in rows. Each gene name appears
                                  #in the column name. Better to use gene symbols as names
                                  beta=-1,	#If -1 the algorithm will seek for the best beta
                                  job.path="~/tmp/",	#Where to store all results
                                  min.cluster.size=30,		#Minimum number of genes to form a cluster
                                  net.type="signed",			#Leave it like that (see WGCNA docs)
                                  debug=F,
                                  blockTOM=F,
                                  save.tom=F,
                                  save.plots=F,
                                  excludeGrey=FALSE,
                                  fullAnnotation=T,
                                  silent=T){
  
  final.net=NULL
  distance.type="cor"
  centroid.type="pca"
  cor.type="pearson"
  
  if(debug){
    if(typeof(expr.data) == "character")
      expr.data = readRDS(expr.data)
    expr.data = expr.data[,1:1500]
    n.iterations=5
  }
  
  validgenes = unlist(apply(expr.data,2,function(x){
    return(var(x) != 0)
  }))
  if(sum(validgenes) < ncol(expr.data))
    cat("There are genes with 0 variance:",
        paste0(colnames(expr.data)[!validgenes],collapse=","),"\n")
  discGenes = colnames(expr.data)[!validgenes]
  expr.data = expr.data[,validgenes]
  
  net.and.tom = getAndPlotNetworkLong(expr.data=expr.data,
                                      beta=beta,
                                      tissue.name=tissue,
                                      min.cluster.size=min.cluster.size,
                                      save.plots=save.plots,
                                      excludeGrey=excludeGrey,
                                      additional.prefix=job.path,
                                      return.tom=T,
                                      cor.type=cor.type,
                                      silent=silent)
  
  if(is.null(net.and.tom))
    return(net.and.tom)
  
  if(is.null(final.net) & !is.null(job.path))
    final.net = paste0(job.path,"/","net",tissue,".",
                       net.and.tom$net$beta,".it.",n.iterations,".rds")
  if(is.null(job.path))
    final.net = NULL
  
  outnet = applyKMeans(tissue=tissue,
                       n.iterations=n.iterations,
                       net.file=net.and.tom$net,
                       expr.data=expr.data,
                       excludeGrey=excludeGrey,
                       min.exchanged.genes = min.exchanged.genes,
                       silent=silent)
  
  
  if(save.tom & !is.null(final.net)){
    if(blockTOM)
      saveTOM(tom=net.and.tom$tom,
              clusters=outnet$moduleColors,
              filepref=paste0(final.net,".tom."))
    else
      saveRDS(net.and.tom$tom,paste0(final.net,".tom.rds"))
  }
  
  outnet$beta = net.and.tom$net$beta
  outnet$file = final.net
  outnet$adjacency = net.and.tom$net$adjacency
  names(outnet$moduleColors) = colnames(expr.data)
  outnet$discGenes = discGenes
  
  # names(outnet$moduleColors) = unlist(lapply(str_split(names(outnet$moduleColors),
  #                                                     "\\."),
  #                                           function(x){return(x[[1]])}))
  
  if(!is.null(final.net)){
    saveRDS(outnet,final.net)
    if(save.tom){
      if(blockTOM)
        outnet$tom = paste0(final.net,".tom.")
      else
        outnet$tom = paste0(final.net,".tom.rds")
    }
    if(save.plots){
      cat("Generating mod sizes for",final.net,"\n")
      pdf(paste0(final.net,".mod_size.pdf"))
      plotModSizes(which.one="new",tissue=final.net)
      dev.off()
      pdf(paste0(final.net,".Eigengenes_clustering.pdf"))
      plotEGClustering(which.one="new",tissue=final.net)
      dev.off()
    }
    if(fullAnnotation){
      go = myGetGProfilerOnNet(net.file=final.net,
                               out.file=paste0(final.net,"_gprof.csv"))
      
      # write.csv(myGenAnnotationCellType(net.in=final.net,
      #                                   return.processed = F,
      #                                   doheatmap=save.plots,
      #                                   tissue=tissue,
      #                                   plot.file=paste0(final.net, "_celltype.pdf")),
      #           paste0(final.net,"_celltype.csv"))
      
      write.table(CoExpNets::getMM(final.net,expr.data,genes=NULL),paste0(final.net, "_getMM.csv"),quote=F,row.names=F, sep="\t")
      
      enrichResults <- phenoExam(final.net)
      write.csv(enrichResults, paste0(final.net, "_PEG.csv"))
    }
    
    
    return(final.net)
  }
  outnet
}


######################################################################################

phenoExam <- function(net.file) {
  
  require(devtools)
  require(clusterProfiler)
  require(AnnotationDbi)
  require(PhenoExamWeb)
  
  if(typeof(net.file) == "character")
    net <- readRDS(net.file)
  else
    net = net.file
  
  modules = unique(net$moduleColors)
  
  databases <- getdbnames()
  
  enrichResults <- as.data.frame(matrix(numeric(), nrow = 0, ncol = 9))
  
  for (module in modules) {
    myModuleGenes <- names(net$moduleColors[net$moduleColors==module])
    enrichModule <- PhenoEnrichGenes(genes= myModuleGenes, database=databases, url=F)
    enrichModule <- enrichModule$alldata
    enrichModule <- enrichModule[enrichModule$adjust_pvalue<0.05, ]
    enrichModule <- as.data.frame(cbind(enrichModule, rep(module, nrow(enrichModule))))
    
    enrichResults <- rbind(enrichResults, enrichModule)
  }
  
  colnames(enrichResults)[10] <- "module"
  
  return(enrichResults)
  
}


#########################################################################################

getNet <- function(exprData, 
                   covs, 
                   batchCov=NULL, 
                   idCov, 
                   bioCovsToCorrect="NULL", 
                   name=deparse(substitute(exprData)), 
                   filteringGenes=F,
                   filteringCutoff=NULL,
                   filteringProportion=NULL,
                   plots=F,
                   path=getwd()) {
  
  # Check arguments
  if (missing(exprData)) { stop("Please provide an expression matrix\n")}
  if (missing(covs)) { stop("Please provide a a table of covariates\n")}
  if (missing(idCov)) { stop("Please provide the name of the variable that represents the id of the samples\n")}
  if (missing(bioCovsToCorrect)) { stop("Please provide the name of the biological variables for which you want to correct the expression data\n")}
  
  # Load libraries
  require(stringr)
  require(gplots)
  require(fs)
  require(dplyr)
  require(preprocessCore)
  require(WGCNA)
  require(limma)
  require(biomaRt)
  require(CoExpNets)
  require(sva)
  require(swamp)
  require(gprofiler2)
  require(readr)
  require(devtools)
  require(clusterProfiler)
  require(AnnotationDbi)
  require(PhenoExamWeb)
  
  name = gsub("_exprData", "", name)
  
  # Create directories
  if(!(dir.exists(paste0(path, "/", name)))) {
    cat("Creating", paste0(path, "/", name), "directory\n")
    dir.create(paste0(path, "/", name))
    dir.create(paste0(path, "/", name, "/Net/"))
    dir.create(paste0(path, "/", name, "/Residuals/"))
    
    if (plots==T) {
      dir.create(paste0(path, "/", name, "/Plots/"))
      dir.create(paste0(path, "/", name, "/Plots/Plots_MDS_Batch/"))
      dir.create(paste0(path, "/", name, "/Plots/Plots_PCA_Batch/"))
      dir.create(paste0(path, "/", name, "/Plots/Plots_SVAs/"))
      dir.create(paste0(path, "/", name, "/Plots/Plots_Net/"))
    }
  }
  
  # Save the mean expression of genes in a file
  # mge <- rowMeans(exprData)
  # saveRDS(mge[order(mge, decreasing=T)], paste0(path, "/", name, "/Net/", name, "_MGE", ".rds"))
  
  # Preparing data 
  preparedData <- prepareData(exprData, covs, batchCov, idCov, filteringGenes, filteringCutoff, filteringProportion)
  preparedExprData <- preparedData[[1]]
  preparedCovs <- preparedData[[2]]
  
  # MDS plots
  if (plots==T && !is.null(batchCov)) {
    plotMDS_Batch(preparedExprData, preparedCovs, batchCov,
                  save = T,
                  outputDir = paste0(path, "/", name, "/Plots/Plots_MDS_Batch/"),
                  name=name)
  }
  
  if (!is.null(batchCov)) {
    # Combat correction
    combatExprData = combatCorrect(preparedExprData, 
                                   preparedCovs,
                                   batchCov,
                                   bioCovsToCorrect,
                                   plots,
                                   name,
                                   paste0(path, "/", name, "/Plots/Plots_PCA_Batch/"))
  } else {
    combatExprData = preparedExprData
  }

  
  if (bioCovsToCorrect!="NULL") {
    # SVA correction
    resids = svaCorrection(combatExprData = combatExprData,
                           preparedCovs = preparedCovs,
                           bioCovsToCorrect = bioCovsToCorrect,
                           plots = plots,
                           idCov = idCov,
                           batchCov = batchCov,
                           name = name,
                           save = T,
                           outputDir = paste0(path, "/", name, "/Plots/Plots_SVAs/"),
                           residsOutput = paste0(path, "/", name, "/Residuals/"))
    
  } else {
    # Without SVA
    resids <- t(combatExprData)
    saveRDS(resids, paste0(path, "/", name, "/Residuals/", name, "_resids.rds"))
  }
  
  # Avoid duplicated rownames 
  dup <- duplicated(rownames(resids))
  dup_length <- length(which(dup==TRUE))
  
  if(dup_length>0) {
    rownames(resids) <- paste0(rownames(resids), ".", seq(1:nrow(resids)))
    preparedCovs[, idCov] <- rownames(resids)
  }
  
  # Network creation and full annotation
  net = myGetDownstreamNetwork(tissue=name,
                               n.iterations=50,
                               net.type = "signed",
                               debug=F,
                               expr.data=resids,
                               fullAnnotation=T,
                               save.plots=plots,
                               job.path=paste0(path, "/", name, "/Net"))
  
  cat("Done.\n")
  
  # Correlation between modules and covariates
  path=paste0(path, "/", name, "/")
  
  # if(!is.null(catTraits) | !is.null(numTraits)) {
  #   traitsCorWithModules(catTraits, numTraits, covs, net, name, plots, outputDirPDF, outputDirCSV)
  # }
  
  # Moving files to their corresponding directories
  if (plots==T) {
    
    for (files in list.files(path=path, pattern = ".pdf")) {
      file_move(paste0(path, files), paste0(path, "Plots/Plots_Net/"))
    }
    
    if (!(is.null(net))) {
      for (files in list.files(path=paste0(path, "Net/"), pattern = ".pdf")) {
        file_move(paste0(path, "Net/", files), paste0(path, "Plots/Plots_Net/"))
      }
    }
  }
  
  # Save a summary of the network
  # cat("Creating a summary\n")
  mySum <- summary(name, path)

  cat("All done.\n")

  return(mySum)
}


######################################################################################

mySummary <- function(name, path) {
  
  net <- list.files(path=paste0(path, "Net/"), pattern = ".50.rds$", full.name=T)
  resids <- readRDS(list.files(path=paste0(path, "Residuals/"), full.names=T)) 
    
  if (length(net)>0) {
    net <- readRDS(net)
    GOterms <- as.data.frame(read_csv(list.files(path=paste0(path, "Net/"), pattern = ".gprof.csv", full.name=T)))
    myValues <- c(name, nrow(resids), ncol(resids), length(unique(net$moduleColors)), nrow(GOterms))
    mySummary <- as.data.frame(rbind(myValues))
    colnames(mySummary) <- c("netName", "numOfCells", "numOfGenes", "numOfModules", "numOfGOterms")
    
  } else {
    myValues <- c(name, nrow(resids), ncol(resids), "NULL", "NULL")
    mySummary <- as.data.frame(rbind(myValues))
    colnames(mySummary) <- c("netName", "numOfCells", "numOfGenes", "numOfModules", "numOfGOterms")
    
    cat("There are few modules in the", name, "network. Makes no sense to continue\n")
  }
  
  return(mySummary)
  
}


###########################################################################################


myCorWithCatTraits = function(MEs,name,covlist,covs=NULL,retPVals=F, outputDir=NULL){
  
  require(WGCNA)
  require(CoExpNets)
  
  # if(is.null(covs))
  #   covs = getCovariates(tissue=tissue,which.one=which.one)
  # 
  if(!is.null(covlist))
    covs = covs[,covlist,drop=F]
  
  for(i in 1:ncol(covs)){
    if(typeof(covs[,i]) ==  "character")
      covs[,i] = as.factor(covs[,i])
  }
  factor.mask = unlist(lapply(covs,is.factor))
  cat("We will work with",sum(factor.mask),"factors\n")
  stopifnot(sum(factor.mask) > 0)
  
  # MEs = CoExpNets::getNetworkEigengenes(tissue=tissue,which.one=which.one)
  
  
  fcm = matrix(nrow=ncol(MEs),ncol=sum(factor.mask))
  index = 1
  for(i in which(factor.mask)){
    #cat("Factor",colnames(trait.data)[i],"\n")
    #cat("Levels",levels(trait.data[,i]))
    #print(trait.data[,i])
    for(j in 1:ncol(MEs)){
      #print(paste0(i,j)
      if(length(unique(covs[,i])) > 1){
        form = eg ~ cov
        data.in = data.frame(MEs[,j],covs[,i])
        colnames(data.in) = c("eg","cov")
        fcm[j,index] = anova(aov(form,data.in))$`Pr(>F)`[1]
      }else
        fcm[j,index] = 1
      
    }
    fcm[,index] = p.adjust(fcm[,index],method="BH")
    index = index + 1
  }
  
  if(sum(!factor.mask) > 0){
    moduleTraitCor = cor(MEs,covs[,!factor.mask,drop=FALSE],use="p")
    #Generate the p-values for significance of a given matrix of correlations, for all modules,
    #between traits data and eigengenes, both from samples
    moduleTraitPvalue = corPvalueStudent(moduleTraitCor,nrow(MEs))
    moduleTraitPvalue = cbind(moduleTraitPvalue,fcm)
    colnames(moduleTraitPvalue) = c(colnames(covs)[!factor.mask],
                                    colnames(covs)[factor.mask])
  }else{
    moduleTraitPvalue = fcm
    colnames(moduleTraitPvalue) = colnames(covs)[factor.mask]
  }
  if(retPVals)
    toReturn = moduleTraitPvalue
  else
    toReturn = -log10(moduleTraitPvalue)
  rownames(toReturn) = gsub("ME","",names(MEs))
  moduleTraitPvalue = -log10(moduleTraitPvalue)
  moduleTraitPvalue[moduleTraitPvalue > 10] = 10
  
  if (!is.null(outputDir)) {
    pdf(file = paste0(outputDir, name, "_corCatTraits.pdf"))
  }
  WGCNA::labeledHeatmap(Matrix=moduleTraitPvalue,
                        xLabels=colnames(moduleTraitPvalue),
                        yLabels=gsub("ME","",names(MEs)),
                        ySymbols=names(MEs),
                        colorLabels=FALSE,
                        colors=rev(heat.colors(50)),
                        cex.text=0.7,
                        cex.lab = 0.7,
                        zlim = c(0,10),
                        main="Module-trait relationships")
  if (!is.null(outputDir)) {
    dev.off()
  }
  
  return(toReturn)
}

###########################################################################################

myCorWithNumTraits = function(MEs,name,covlist,covs=NULL,outputDir=NULL, retPVals=F){
  
  require(WGCNA)
  require(CoExpNets)
  
  # MEs = CoExpNets::getNetworkEigengenes(tissue=tissue,which.one=which.one)
  # if(is.null(covs))
  #   covs = getCovariates(tissue=tissue,which.one=which.one)
  covs = covs[,covlist]
  moduleTraitCor = cor(MEs, covs, use = "p")
  moduleTraitPvalue = WGCNA::corPvalueStudent(moduleTraitCor, nrow(MEs))
  textMatrix = paste(signif(moduleTraitCor, 2), "\n(",
                     signif(moduleTraitPvalue, 1), ")", sep = "")
  
  if(length(covlist) == 1){
    textMatrix = cbind(rep("--",length(textMatrix)),textMatrix)
    moduleTraitCor = cbind(rep(0,nrow(moduleTraitCor)),moduleTraitCor)
    covlist = c("Dummy",covlist)
  }else
    dim(textMatrix) = dim(moduleTraitCor)
  par(mar = c(6, 8.5, 3, 3));
  # Display the correlation values within a heatmap plot
  
  if (!is.null(outputDir)) {
    pdf(file = paste0(outputDir, name, "_corNumTraits.pdf"))
  }
  
  if(retPVals) {
    rownames(moduleTraitPvalue) <- gsub("ME", "", rownames(moduleTraitPvalue))
    toReturn = moduleTraitPvalue
  }
  else {
    rownames(moduleTraitCor) <- gsub("ME", "", rownames(moduleTraitCor))
    toReturn = moduleTraitCor  
  }
  
  WGCNA::labeledHeatmap(Matrix = moduleTraitCor,
                        xLabels = covlist,
                        yLabels = names(MEs),
                        ySymbols = names(MEs),
                        colorLabels = FALSE,
                        colors = blueWhiteRed(50),
                        textMatrix = textMatrix,
                        setStdMargins = TRUE,
                        cex.text = 0.000001,
                        cex.lab=0.7, 
                        zlim = c(-1,1),
                        main = paste0("Module-trait relationships"))
  
  if (!is.null(outputDir)) {
    dev.off()
  }
  return(toReturn)
}

##############################################################################################


traitsCorWithModules <- function(catTraits, numTraits, covs, net, name, plots=F, outputDirPDF=NULL, outputDirCSV=getwd()) {
  
  cat("Studying the correlation between modules and covariates\n")
  
  # Load samples covs
  preparedCovs <- covs[, -1] # removing ID column
  
  # Preparing covs table
  indexCatTraits <- match(catTraits, colnames(preparedCovs))
  indexNumTraits <- match(numTraits, colnames(preparedCovs))
  preparedCovs[, indexCatTraits] <- apply(preparedCovs[, indexCatTraits], 2, function(x) as.factor(as.character(x)))
  preparedCovs[, indexNumTraits] <- apply(preparedCovs[, indexNumTraits], 2, function(x) as.numeric(as.character(x)))
  
  # Searching specific traits (we don't have this information for all individuals)
  specificTraits <- apply(preparedCovs, 2, function(x) sum(x==-1))
  specificTraits <- names(specificTraits[specificTraits>0])
  catTraits <- setdiff(catTraits, specificTraits)
  numTraits <- setdiff(numTraits, specificTraits)
  
  # Creating plots  for cat and num traits
  pVals_cat <- myCorWithCatTraits(net$MEs,covs=preparedCovs[, catTraits], covlist = catTraits, retPVals=T, outputDir=outputDirPDF, name=name)
  cor_cat <- myCorWithCatTraits(net$MEs,covs=preparedCovs[, catTraits], covlist = catTraits, retPVals=F, outputDir=NULL, name=name)
  
  pVals_num <- myCorWithNumTraits(net$MEs,covs=preparedCovs[, numTraits], covlist = numTraits, retPVals=T, outputDir=outputDirPDF, name=name)
  cor_num <- myCorWithNumTraits(net$MEs,covs=preparedCovs[, numTraits], covlist = numTraits, retPVals=F, outputDir=NULL, name=name)
  
  # Creating plots for specific traits
  index <- which(preparedCovs[, specificTraits[1]]!=-1)
  MEs <- net$MEs[index, ]
  preparedCovs <- preparedCovs[index, ]
  
  if (isTRUE(is.numeric(preparedCovs[, specificTraits]))) {
    pVals_specific <- myCorWithNumTraits(MEs,covs=preparedCovs[, specificTraits], covlist = specificTraits, retPvals=T, outputDir=outputDirPDF, name=paste0(name, "_specific_"))
    cor_specific <- myCorWithNumTraits(MEs,covs=preparedCovs[, specificTraits], covlist = specificTraits, retPvals=F, outputDir=NULL, name=paste0(name, "_specific_"))
    
  } else {
    pVals_specific <- myCorWithCatTraits(MEs,covs=preparedCovs[, specificTraits], covlist = specificTraits, retPVals=T, outputDir=outputDirPDF, name=paste0(name, "_specific_"))
    cor_specific <- myCorWithCatTraits(MEs,covs=preparedCovs[, specificTraits], covlist = specificTraits, retPVals=F, outputDir=NULL, name=paste0(name, "_specific_"))
  }
  
  stopifnot(identical(rownames(pVals_cat), rownames(pVals_num)))
  stopifnot(identical(rownames(pVals_cat), rownames(pVals_specific)))
  pVals_all <- data.frame(cbind(pVals_cat, pVals_num, pVals_specific))
  write.csv(pVals_all, paste0(outputDirCSV, name, "_corr_pVals.csv"))
  
  stopifnot(identical(rownames(cor_cat), rownames(cor_num)))
  stopifnot(identical(rownames(cor_cat), rownames(cor_specific)))
  cor_all <- data.frame(cbind(cor_cat, cor_num, cor_specific))
  write.csv(cor_all, paste0(outputDirCSV, name, "_corr.csv"))
  
}


###############################################################################################################

myGenCrossTabPlot <- function(colors1,
                              colors2,
                              tissue1="Net 1",
                              tissue2="Net 2",
                              plot.file=NULL){
  
  require(WGCNA)
  
  #We create a simple crosstab
  XTbl <- overlapTable(colors1, colors2)
  XTbl$pTable[] = p.adjust(XTbl$pTable,method="fdr")
  toreturn = XTbl$pTable
  #print(XTbl)
  # Truncate p values smaller than 10^(-50) to 10^(-50)
  XTbl$pTable <- -log10(XTbl$pTable)
  #XTbl$pTable[is.infinite(XTbl$pTable)] = 1.3*max(XTbl$pTable[is.finite(XTbl$pTable)])
  XTbl$pTable[XTbl$pTable>50 ] = 50
  
  # Marginal counts (really module sizes)
  ModTotals.1 = apply(XTbl$countTable, 1, sum)
  ModTotals.2 = apply(XTbl$countTable, 2, sum)
  if(!is.null(plot.file)){
    pdf(plot.file,height=14,width=18)
    print(paste0("Saving new plot ",plot.file))
    
  }
  par(mar=c(15, 12, 2.7, 1)+0.4)
  
  # Use function labeledHeatmap to produce the color-coded table
  #with all the trimmings
  labeledHeatmap(Matrix = XTbl$pTable,
                 yLabels = paste(" ", names(ModTotals.1)),xLabels = paste(" ",
                                                                          names(ModTotals.2)),colorLabels = TRUE,
                 textMatrix =XTbl$countTable,colors = greenWhiteRed(100)[50:100],
                 ySymbols = paste(names(ModTotals.1)," : ", ModTotals.1, sep=""),
                 xSymbols = paste(names(ModTotals.2)," : ", ModTotals.2, sep=""),
                 main = paste0("Correspondence of ", tissue1," (rows) and \n", tissue2, " (columns) modules",sep=""),
                 cex.text = 0.6, cex.lab = 0.6, setStdMargins = FALSE, plotLegend= TRUE)
  if(!is.null(plot.file))
    dev.off()
  return(toreturn)
}

####################################################################################################

