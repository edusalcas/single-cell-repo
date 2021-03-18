from Individual import Individual


class Specimen(Individual):

    def __init__(self, specimen_id):
        self.specimen_ID = None
        self.assay = None

        super().__init__(specimen_id)

    def get_dict(self):
        specimen_dict = super().get_dict()

        specimen_dict["AnnotationProperties"]["SR.hasSpecimenID"] = self.specimen_ID
        specimen_dict["AnnotationProperties"]["SR.hasAssayID"] = self.assay

        return specimen_dict

    ####################################################
    #region Sample properties

    @property
    def specimen_ID(self):
        return self.__specimen_ID

    @specimen_ID.setter
    def specimen_ID(self, specimen_ID):
        self.__specimen_ID = specimen_ID

    #endregion
    ####################################################
