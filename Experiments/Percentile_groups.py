
import requests    
import pandas as pd


def read_files(project_ID):
    """Return the metadata of the project with the project_ID
    
    Parameters
    ----------
    project_ID : str
        The ID of a project

    Returns
    -------
    
    metadata: pandas dataframe
        A dataframe of the project with its metadata
    """
    
    # Define the link and the metadata key name
    API_downloads_link = 'http://localhost:5000/project/downloads/'
    metadata_key_name = 'experimentDesignLink'
    filtered_key_name = 'filteredTPMLink'
    normalised_key_name = 'normalisedCountsLink'
    
    # Define variables
    metadata = None
    matrix = None
    gene_names = None
    cell_names = None
    
    # Get the download links of the project
    links = requests.get(API_downloads_link + project_ID).json()
    if not links: # If project doesn't exists
        raise Exception(f'Project with ID {project_ID} not found')
    links = links[0]
    
    # Return the metadata if it exists
    if metadata_key_name in links:
        metadata_link = links[metadata_key_name]
        metadata = pd.read_csv(metadata_link, sep='\t')
    
    if filtered_key_name in links:
        matrix_link = links[filtered_key_name]
        matrix, cell_names, gen_names = download_matrix(matrix_link, project_ID)
    elif normalised_key_name in links:
        matrix_link = links[normalised_key_name]
        matrix, cell_names, gen_names = download_matrix(matrix_link, project_ID)
    
    # If project does not have metadata link, return none
    return metadata, matrix, gene_names, cell_names


from scipy.io import mmread
import zipfile
import os

def download_matrix(matrix_link, project_ID): 
    # download the file contents in binary format
    response = requests.get(matrix_link)
    
    zip_name = project_ID + ".zip"
    
    matrix_path = project_ID + '.aggregated_filtered_normalised_counts.mtx'
    gene_path = project_ID + '.aggregated_filtered_normalised_counts.mtx_rows'
    cell_path = project_ID + '.aggregated_filtered_normalised_counts.mtx_cols'
    
    # open method to open a file on your system and write the contents
    with open(zip_name, "wb") as code:
        code.write(response.content)
        
    with zipfile.ZipFile(zip_name, 'r') as zip_ref:
        zip_ref.extract(matrix_path)
        zip_ref.extract(gene_path)
        zip_ref.extract(cell_path)
    
    matrix = mmread(matrix_path).transpose()
    cell_names = pd.read_csv(cell_path, header=None, names=['Assay'])
    gen_names = pd.read_csv(gene_path, header=None, names=['Gen_Name'])
 
    os.remove(zip_name)
    os.remove(matrix_path)
    os.remove(cell_path)
    os.remove(gene_path)
    
    return matrix, cell_names, gen_names
    

import re

import re

def process_metadata(metadata, cell_names):
    """Return the processed metadata
    
    Parameters
    ----------
    metadata : pandas dataframe
        metadata of a project

    Returns
    -------
    
    metadata: pandas dataframe
        metadata processed
    """
    cols = [c for c in metadata.columns if 'ontology term' not in c.lower()]
    metadata = metadata[cols] # Drop columns with ontology terms
    
    metadata = metadata.rename(columns=lambda x: re.sub(r'.+\[(.+)\]',r'\1',x)) # Rename columns
        
    metadata = metadata.T.drop_duplicates().T # Drop duplicated columns

    # Delete cells that are not in the matrix
    metadata = pd.merge(
        cell_names,
        metadata,
        how="inner",
        on='Assay'
    )
    
    return metadata



def init_subgroups(metadata):
    """Returns a list of one dictionary, containing the metadata
    
    Parameters
    ----------
    
    metadata : pandas dataframe
        The metadata of a project in a dataframe

    Returns
    -------
    
    subgroups: list
        List with the initial group of the metadata
    """
    dictionary = {'dataframe': metadata}
    subgroups = [dictionary]

    return subgroups



def get_subgroups(group, characteristic):
    """Divide the group in subgroups using the characteristic
    
    Parameters
    ----------
    
    group : dict
        The group with the dataframe and the characteristics used

    characteristic: str
        The characteristic used for the division
    
    Returns
    -------
    
    subgroups: list
        List with the subgroups created
    """
    # Get the dataframe and group by the characteristic
    dataframe = group['dataframe']
    groupby = dataframe.groupby(by=characteristic)

    # Create the new subgroups
    subgroups = []
    for value, subgroup in groupby:
        # If the group does not have enough cells skip it
        if len(subgroup) < 25:
            continue

        # Creaete the subgroup from the group
        new_subgroup = group.copy()
        new_subgroup['dataframe'] = subgroup
        new_subgroup[characteristic] = value
        subgroups = subgroups + [new_subgroup]

    return subgroups


def combiation_to_name(combination):
    name = ''
    for item in combination:
        name += str(item) + '-'
    
    return name[:-1]



def create_row(project_ID, subgroups, characteristics_used):
    """Creates a new row with the combinations of the characteristics.

    Parameters
    ----------
    project_ID : str
        The ID of a project
    subgroups: list
        List of subgroups created
    characteristics_used : list
        List of str with the characteristics used to divide the project

    Returns
    -------
    
    row: dict
        An empty row with the combinations
    """
    
    n_subgroups = len(subgroups)
    combination_name = combiation_to_name(characteristics_used)
    row = {
        'project_ID': project_ID,
        'num_subgroups': n_subgroups,
        'characteristics_used': combination_name
    }

    return row


def get_groups_from_project(project_ID, characteristics):
    """Generate the groups for percentile creation using characteristics to divide.

    Parameters
    ----------
    project_ID : str
        The ID of a project
    characteristics : list
        List of str with the characteristics used to divide the project

    Returns
    -------
    
    row: dict
        The row (dictionary) with the number of subgroups created with each combination
    subgroups: list
        A list with dictionaries containing the groups, the characteristics and the values used for the division.
    """    
    # Read the metadata file using the API
    metadata = read_metadata(project_ID)
    
    # If there is not metadata for this project, return empty lists
    if metadata is None:
        return [], []
    
    metadata = process_metadata(metadata)
    
    # Initialitation of parameters
    subgroups = init_subgroups(metadata)
    project_characteristics = metadata.columns
    used_characteristics = []
        
    # Start the subgroup generation using the characteristics
    for characteristic in characteristics:
        # If the characteristic is not in the project, we skip it
        if characteristic not in project_characteristics:
            continue
        
        # For each subgroup created, divide it using the current characteristic
        subgroups_aux = []
        for subgroup in subgroups:
            subgroup_aux = get_subgroups(subgroup, characteristic)
            
            subgroups_aux = subgroups_aux + subgroup_aux
        
        # Update parameters
        used_characteristics = used_characteristics + [characteristic]
        subgroups = subgroups_aux
        
        # If there are no subgroups left, stop
        if not subgroups:
            break
        
    row = create_row(project_ID, subgroups, used_characteristics)
    
    return row, subgroups



