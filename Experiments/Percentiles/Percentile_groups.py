import requests
import pandas as pd
from scipy.io import mmread
import zipfile
import os
import re


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
    if not links:  # If project doesn't exists
        raise Exception(f'Project with ID {project_ID} not found')
    links = links[0]

    # Return the metadata if it exists
    if metadata_key_name in links:
        metadata_link = links[metadata_key_name]
        metadata = pd.read_csv(metadata_link, sep='\t', low_memory=False)

    if filtered_key_name in links:
        matrix_link = links[filtered_key_name]
        matrix, cell_names, gene_names = download_matrix(matrix_link, matrix_type='filtered')
    elif normalised_key_name in links:
        matrix_link = links[normalised_key_name]
        matrix, cell_names, gene_names = download_matrix(matrix_link, matrix_type='normalised')

    # If project does not have metadata link, return none
    return metadata, matrix, gene_names, cell_names


def download_matrix(matrix_link, matrix_type='normalised'):
    # download the file contents in binary format
    response = requests.get(matrix_link)

    project_ID = re.sub(r'.*/experiment/(.+)/download/.*', r'\1', matrix_link)

    zip_name = project_ID + ".zip"
    if matrix_type == 'normalised':
        matrix_path = project_ID + '.aggregated_filtered_normalised_counts.mtx'
        gene_path = project_ID + '.aggregated_filtered_normalised_counts.mtx_rows'
        cell_path = project_ID + '.aggregated_filtered_normalised_counts.mtx_cols'
    elif matrix_type == 'filtered':
        matrix_path = project_ID + '.expression_tpm.mtx'
        gene_path = project_ID + '.expression_tpm.mtx_rows'
        cell_path = project_ID + '.expression_tpm.mtx_cols'

    # open method to open a file on your system and write the contents
    with open(zip_name, "wb") as code:
        code.write(response.content)

    with zipfile.ZipFile(zip_name, 'r') as zip_ref:
        zip_ref.extract(matrix_path)
        zip_ref.extract(gene_path)
        zip_ref.extract(cell_path)

    matrix = mmread(matrix_path).transpose()
    cell_names = pd.read_csv(cell_path, header=None, names=['Assay'])
    gene_names = pd.read_csv(gene_path, header=None, names=['Gen_Name'])

    os.remove(zip_name)
    os.remove(matrix_path)
    os.remove(cell_path)
    os.remove(gene_path)

    return matrix, cell_names, gene_names


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
    metadata = metadata[cols]  # Drop columns with ontology terms

    metadata = metadata.rename(columns=lambda x: re.sub(r'.+\[(.+)\]', r'\1', x))  # Rename columns

    metadata = metadata.loc[:, ~metadata.columns.duplicated()]  # Drop duplicated columns

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
        name += str(item) + '/'

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

    cells = 0
    for subgroup in subgroups:
        cells += len(subgroup['dataframe'])

    n_subgroups = len(subgroups)
    combination_name = combiation_to_name(characteristics_used)
    row = {
        'project_ID': project_ID,
        'num_subgroups': n_subgroups,
        'num_cells': cells,
        'characteristics_used': combination_name
    }

    return row


def print_subgroups(subgroups):
    for n, subgroup in enumerate(subgroups):
        print(f'Subgroup {n}:')
        for key, value in subgroup.items():
            print('\t', end='')
            if key == 'dataframe':
                print(f'Number of cells: {len(value)}')
            else:
                print(f'{key}: {value}')


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
    metadata, _, _, cell_names = read_files(project_ID)

    # If there is not metadata for this project, return empty lists
    if metadata is None:
        return [], []

    metadata = process_metadata(metadata, cell_names)

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


def compare_combination(combination0, combination1):
    if combination0 is None:
        return 1
    if combination1 is None:
        return -1

    combination0_characteristics = len(combination0['characteristics_used'].split('/'))
    combination1_characteristics = len(combination1['characteristics_used'].split('/'))
    # Compare characteristics
    if combination0_characteristics > combination1_characteristics:
        return -1
    if combination0_characteristics < combination1_characteristics:
        return 1

    return 0


def best_subgroup_combination(subgroups_combinations):
    best_combination = None
    best_combination_index = 0

    for n, combination in enumerate(subgroups_combinations):
        if compare_combination(best_combination, combination) == 1:
            best_combination = combination
            best_combination_index = n

    return best_combination, best_combination_index


def get_groups_from_project_multiple(project_ID, characteristics_groups):
    """Generate the groups for percentile creation using characteristics to divide.

    Parameters
    ----------
    project_ID : str
        The ID of a project
    characteristics_groups : list
        Lists of lists of str with the characteristics used to divide the project

    Returns
    -------

    row: dict
        The row (dictionary) with the number of subgroups created with each combination
    subgroups: list
        A list with dictionaries containing the groups, the characteristics and the values used for the division.
    """
    # Read the metadata file using the API
    metadata, _, _, cell_names = read_files(project_ID)

    # If there is not metadata for this project, return empty lists
    if metadata is None:
        return [], []

    metadata = process_metadata(metadata, cell_names)

    rows = []
    subgroups_list = []
    for characteristics in characteristics_groups:
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

        rows.append(row)
        subgroups_list.append(subgroups)

    row, index = best_subgroup_combination(rows)
    subgroups = subgroups_list[index]

    return row, subgroups