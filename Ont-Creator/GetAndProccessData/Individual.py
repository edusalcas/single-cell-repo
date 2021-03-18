

class Individual:

    def __init__(self, ID):
        self.ID = ID

        self.analysis_protocol = None
        self.biopsy_site = None
        self.cell_line_type = None
        self.disease = None
        self.instrument = None
        self.library = None
        self.model_organ = None
        self.organism_part = None
        self.preservation = None
        self.sample_type = None
        self.cell_type = None
        self.specie = None
        self.sample_status = None
        self.downloads_type = None
        self.metastatic_site = None
        self.nucleic_acid = None

        self.age_unit = None
        self.biological_sex = None
        self.laboratory = None
        self.max_age = -1
        self.min_age = -1
        self.phenotype = None
        self.project_short_name = None
        self.project_title = None
        self.total_cell_counts = -1
        self.total_size_of_files = -1.0
        self.paired_end = None
        self.part_of_collection = None
        self.part_of_repository = None
        self.growth_condition = None

        self.clustering_link = None
        self.experiment_design_link = None
        self.experiment_metadata_link = None
        self.filtered_TPM_link = None
        self.marker_genes_link = None
        self.matrix_link = None
        self.normalised_counts_link = None
        self.raw_counts_link = None
        self.result_link = None

        super().__init__()

    def get_dict(self):
        individual_dict = {
            "ID": self.ID,
            "ObjectProperties": {
                "SPR.hasAnalysisProtocol": self.analysis_protocol,
                "SPR.hasBiopsySite": self.biopsy_site,
                "SPR.hasCellLineType": self.cell_line_type,
                "SPR.hasDisease": self.disease,
                "SPR.hasInstrument": self.instrument,
                "SPR.hasLibrary": self.library,
                "SPR.hasModel": self.model_organ,
                "SPR.hasOrganismPart": self.organism_part,
                "SPR.hasPreservation": self.preservation,
                "SPR.hasCellType": self.cell_type,
                "SPR.hasSpecie": self.specie,
                "SPR.hasSampleStatus": self.sample_status,
                "SPR.hasDownloads": self.downloads_type,
                "SPR.hasMetastaticSite": self.metastatic_site,
            },
            "DataProperties": {
                "SPR.hasAgeUnit": self.age_unit,
                "SPR.hasSex": self.biological_sex,
                "SPR.hasMaxAge": self.max_age,
                "SPR.hasMinAge": self.min_age,
                "SPR.hasPhenotype": self.phenotype,
                "SPR.hasTotalCellCount": self.total_cell_counts,
                "SPR.isPairedEnd": self.paired_end,
                "SPR.hasGrowthCondition": self.growth_condition,
                "SPR.hasSampleType": self.sample_type,
                "SPR.hasNucleicAcidSource": self.nucleic_acid,
            },
            "AnnotationProperties": {
                "SPR.hasLaboratory": self.laboratory,
                "SPR.hasProjectShortName": self.project_short_name,
                "SPR.hasProjectTitle": self.project_title,
                "SPR.isPartOfCollection": self.part_of_collection,
                "SPR.isPartOfRepository": self.part_of_repository,
                "SPR.hasTotalSizeOfFilesInMB": self.total_size_of_files,
                "SPR.hasClusteringLink": self.clustering_link,
                "SPR.hasExperimentDesignLink": self.experiment_design_link,
                "SPR.hasExperimentMetadataLink": self.experiment_metadata_link,
                "SPR.hasFilteredTPMLink": self.filtered_TPM_link,
                "SPR.hasMarkerGenesLink": self.marker_genes_link,
                "SPR.hasMatrixLink": self.matrix_link,
                "SPR.hasNormalisedCountsLink": self.normalised_counts_link,
                "SPR.hasRawCountsLink": self.raw_counts_link,
                "SPR.hasResultsLink": self.result_link
            }
        }

        return individual_dict

    ####################################################
    #region Properties

    @property
    def ID(self):
        return self.__ID

    @ID.setter
    def ID(self, ID):
        self.__ID = ID

    @property
    def analysis_protocol(self):
        return self.__analysis_protocol

    @analysis_protocol.setter
    def analysis_protocol(self, analysis_protocol):
        self.__analysis_protocol = analysis_protocol

    @property
    def cell_line_type(self):
        return self.__cell_line_type

    @cell_line_type.setter
    def cell_line_type(self, cell_line_type):
        self.__cell_line_type = cell_line_type

    @property
    def disease(self):
        return self.__disease

    @disease.setter
    def disease(self, disease):
        self.__disease = disease

    @property
    def instrument(self):
        return self.__instrument

    @instrument.setter
    def instrument(self, instrument):
        self.__instrument = instrument

    @property
    def library(self):
        return self.__library

    @library.setter
    def library(self, library):
        self.__library = library

    @property
    def model_organ(self):
        return self.__model_organ

    @model_organ.setter
    def model_organ(self, model_organ):
        self.__model_organ = model_organ

    @property
    def object_of_study(self):
        return self.__object_of_study

    @object_of_study.setter
    def object_of_study(self, object_of_study):
        self.__object_of_study = object_of_study

    @property
    def preservation(self):
        return self.__preservation

    @preservation.setter
    def preservation(self, preservation):
        self.__preservation = preservation

    @property
    def sample_type(self):
        return self.__sample_type

    @sample_type.setter
    def sample_type(self, sample_type):
        self.__sample_type = sample_type

    @property
    def cell_type(self):
        return self.__cell_type

    @cell_type.setter
    def cell_type(self, cell_type):
        self.__cell_type = cell_type

    @property
    def age_unit(self):
        return self.__age_unit

    @age_unit.setter
    def age_unit(self, age_unit):
        self.__age_unit = age_unit

    @property
    def downloads_format(self):
        return self.__downloads_format

    @downloads_format.setter
    def downloads_format(self, downloads_format):
        self.__downloads_format = downloads_format

    @property
    def downloads_type(self):
        return self.__downloads_type

    @downloads_type.setter
    def downloads_type(self, downloads_type):
        self.__downloads_type = downloads_type

    @property
    def biological_sex(self):
        return self.__biological_sex

    @biological_sex.setter
    def biological_sex(self, biological_sex):
        self.__biological_sex = biological_sex

    @property
    def laboratory(self):
        return self.__laboratory

    @laboratory.setter
    def laboratory(self, laboratory):
        self.__laboratory = laboratory

    @property
    def max_age(self):
        return self.__max_age

    @max_age.setter
    def max_age(self, max_age):
        self.__max_age = max_age

    @property
    def min_age(self):
        return self.__min_age

    @min_age.setter
    def min_age(self, min_age):
        self.__min_age = min_age

    @property
    def project_short_name(self):
        return self.__project_short_name

    @project_short_name.setter
    def project_short_name(self, project_short_name):
        self.__project_short_name = project_short_name

    @property
    def project_title(self):
        return self.__project_title

    @project_title.setter
    def project_title(self, project_title):
        self.__project_title = project_title

    @property
    def total_cell_counts(self):
        return self.__total_cell_counts

    @total_cell_counts.setter
    def total_cell_counts(self, total_cell_counts):
        self.__total_cell_counts = total_cell_counts

    @property
    def total_size_of_files(self):
        return self.__total_size_of_files

    @total_size_of_files.setter
    def total_size_of_files(self, total_size_of_files):
        self.__total_size_of_files = total_size_of_files

    @property
    def paired_end(self):
        return self.__paired_end

    @paired_end.setter
    def paired_end(self, paired_end):
        self.__paired_end = paired_end

    @property
    def part_of_collection(self):
        return self.__part_of_collection

    @part_of_collection.setter
    def part_of_collection(self, part_of_collection):
        self.__part_of_collection = part_of_collection

    @property
    def part_of_repository(self):
        return self.__part_of_repository

    @part_of_repository.setter
    def part_of_repository(self, part_of_repository):
        self.__part_of_repository = part_of_repository

    #endregion
    ####################################################
