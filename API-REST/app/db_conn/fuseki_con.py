import requests
import pandas as pd
import whoosh.index as index
import os

from whoosh.qparser import QueryParser

server_name = 'http://localhost:3030'
service_name = 'ds'
request_url = server_name + '/' + service_name
URI_prefix = 'http://www.semanticweb.org/alicia/ontologies/2020/8/singleCellRepositories#'


def __intersection(list1, list2):
    if not list1:
        return list2
    if not list2:
        return list1

    return list(set(list1) & set(list2))


def conn_alive():
    ans = requests.get(request_url, data={'query': '{}'})

    return ans.status_code == 200


def __fuseki_to_dict(response, dict_type='list'):
    headers = response.json()["head"]["vars"]
    results = response.json()["results"]['bindings']

    if not results:
        return []

    rows = []

    for result in results:
        result_dict = {}
        for header in headers:
            if header not in result:
                result_dict[header] = None
            else:
                value = result[header]['value']

                if URI_prefix in value:
                    value = value.split('#')[-1]
                result_dict[header] = value

        rows.append(result_dict)

    df = pd.DataFrame(rows)

    if 'project_ID' not in df.columns:
        df_dict = df.to_dict(dict_type)

        if dict_type == 'list':
            for key in df_dict:
                l = list(set(df_dict[key]))
                df_dict[key] = l[0] if len(l) == 1 else l
        elif dict_type == 'records':
            aux = {}

            for item in df_dict:

                term = item['term']
                URI = item['URI']

                if term not in aux:
                    aux[term] = []

                aux[term].append(URI)

            df_dict = []

            for term, URIs in aux.items():
                df_dict.append({
                    'term': term,
                    'URI': URIs
                })

        return df_dict

    projects = []
    for project_ID, data in df.groupby('project_ID'):
        project = {
            'project_ID': project_ID,
        }

        for column in [x for x in data if x != 'project_ID']:
            column_data = data[column].unique().tolist()
            if len(column_data) == 1:
                column_data = column_data[0]

            if column_data is not None:
                project[column] = column_data

        projects.append(project)

    return projects


def __fuseki_to_list(response):
    items = []
    header = response.json()["head"]["vars"][0]
    results = response.json()["results"]['bindings']
    for result in results:
        item = result[header]['value']
        if URI_prefix in item:
            item = item.split('#')[-1]
        items.append(item)

    return items


def get_projects(params={}):
    where_content = "?project rdf:type a:Project . ?project a:PR.hasProjectID ?project_ID ."

    for key, value in params.items():
        if key == 'disease':
            where_content += " { ?project a:SPR.hasDisease ?disease . ?subClasses rdfs:subClassOf* a:" + value + ". ?disease rdf:type ?subClasses . } UNION { ?project a:SPR.hasDisease a:" + value + " . }"
        elif key == 'cell_type':
            where_content += " { ?project a:SPR.hasCellType ?cellType . ?subClasses rdfs:subClassOf* a:" + value + ". ?cellType rdf:type ?subClasses . } UNION { ?project a:SPR.hasCellType a:" + value + " . }"
        elif key == 'organism_part':
            where_content += " { ?project a:SPR.hasOrganismPart ?organismPart . ?subClasses rdfs:subClassOf* a:" + value + ". ?organismPart rdf:type ?subClasses . } UNION { ?project a:SPR.hasOrganismPart a:" + value + " . }"
        elif key == 'sex':
            where_content += " ?project a:SPR.hasSex \"" + value + "\" ."
        else:
            return {'msg': 'Param key not valid'}

    where_content += '''
        OPTIONAL { ?project a:SPR.hasProjectTitle ?projectTitle . }
        OPTIONAL { ?project a:PR.hasDescription ?description . }
        OPTIONAL { ?project a:SPR.hasAnalysisProtocol ?analysisProtocol . }
        OPTIONAL { ?project a:SPR.hasLibrary ?library . }
        OPTIONAL { ?project a:SPR.hasCellType ?cellType . }
        OPTIONAL { ?project a:SPR.hasSex ?sex . }
        OPTIONAL { ?project a:SPR.hasDisease ?disease . }
        OPTIONAL { ?project a:SPR.hasMinAge ?minAge . }
        OPTIONAL { ?project a:SPR.hasMinAge ?maxAge . }
        OPTIONAL { ?project a:SPR.hasAgeUnit ?ageUnit . }
        OPTIONAL { ?project a:SPR.hasOrganismPart ?organismPart . }
        OPTIONAL { ?project a:SPR.hasBiopsySite ?biopsySite . }
        OPTIONAL { ?project a:SPR.hasLaboratory ?laboratory . }
        OPTIONAL { ?project a:PR.hasInstitution ?institution . }
        OPTIONAL { ?project a:SPR.isPartOfRepository ?repository . }
        OPTIONAL { ?project a:SPR.isPartOfCollection ?collection . }
        OPTIONAL { ?project a:PR.hasDonorCount ?donorCount . }
        OPTIONAL { ?project a:PR.hasSpecimenCount ?specimenCount . }
    '''

    query = '''
        PREFIX a: <http://www.semanticweb.org/alicia/ontologies/2020/8/singleCellRepositories#>
        PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
        PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
        SELECT DISTINCT
            ?project_ID
            ?projectTitle
            ?description
            ?analysisProtocol
            ?cellType
            ?sex
            ?minAge
            ?maxAge
            ?ageUnit
            ?disease
            ?organismPart
            ?biopsySite
            ?laboratory
            ?institution
            ?repository
            ?collection
            ?donorCount
            ?specimenCount
        WHERE { ''' + where_content + '}'

    print(query)

    response = requests.post(request_url, data={'query': query})

    projects = __fuseki_to_dict(response)

    return projects


def get_project_metadata(metadata_param):
    metadata_param_with_URI = ['disease', 'cell_type', 'organism_part', 'biopsy_site']
    metadata_param_without_URI = ['sex', 'repository', 'library', 'specie', 'analysis_protocol', 'instrument']

    if metadata_param in metadata_param_with_URI:
        return __get_project_metadata_with_URI(metadata_param)
    elif metadata_param in metadata_param_without_URI:
        return __get_project_metadata_without_URI(metadata_param)

    return {'msg': 'Param key not valid'}


def __get_project_metadata_with_URI(metadata_param):
    where_content = ""

    if metadata_param == 'disease':
        where_content += "{ ?term rdfs:subClassOf* a:Disease . } UNION { ?y rdfs:subClassOf* a:Disease . ?term rdf:type ?y } ."
    elif metadata_param == 'cell_type':
        where_content += "{ ?term rdfs:subClassOf* a:CellType . } UNION { ?y rdfs:subClassOf* a:CellType . ?term rdf:type ?y } ."
    elif metadata_param == 'organism_part' or metadata_param == "biopsy_site":
        where_content += "{ ?term rdfs:subClassOf* a:OrganismPart . } UNION { ?y rdfs:subClassOf* a:OrganismPart . ?term rdf:type ?y } ."

    query = '''
        PREFIX a: <http://www.semanticweb.org/alicia/ontologies/2020/8/singleCellRepositories#>
        PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
        PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
        SELECT DISTINCT
            ?term
            ?URI
        WHERE { ''' + where_content + '\n OPTIONAL { ?term a:OR.hasURI ?URI } .\n }' + "\nORDER BY ?term"

    print(query)

    response = requests.post(request_url, data={'query': query})

    metadata_list = __fuseki_to_dict(response, dict_type="records")

    return metadata_list


def __get_project_metadata_without_URI(metadata_param):
    where_content = ""

    if metadata_param == 'sex':
        where_content += " ?project a:SPR.hasSex ?x ."
    elif metadata_param == 'repository':
        where_content += " ?project a:SPR.isPartOfRepository ?x ."
    elif metadata_param == 'library':
        where_content += "{ ?x rdfs:subClassOf* a:Library . } UNION { ?y rdfs:subClassOf* a:Library . ?x rdf:type ?y }"
    elif metadata_param == 'specie':
        where_content += "{ ?x rdfs:subClassOf* a:Specie . } UNION { ?y rdfs:subClassOf* a:Specie . ?x rdf:type ?y }"
    elif metadata_param == 'analysis_protocol':
        where_content += "{ ?x rdfs:subClassOf* a:AnalysisProtocol . } UNION { ?y rdfs:subClassOf* a:AnalysisProtocol . ?x rdf:type ?y }"
    elif metadata_param == 'instrument':
        where_content += "{ ?x rdfs:subClassOf* a:InstrumentModel . } UNION { ?y rdfs:subClassOf* a:InstrumentModel . ?x rdf:type ?y }"

    query = '''
                PREFIX a: <http://www.semanticweb.org/alicia/ontologies/2020/8/singleCellRepositories#>
                PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
                PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
                SELECT DISTINCT
                    ?x
                WHERE { ''' + where_content + '}' + "ORDER BY ?x"

    print(query)

    response = requests.post(request_url, data={'query': query})

    metadata_list = __fuseki_to_list(response)

    return metadata_list


def get_project_downloads(project_ID):
    where_content = f"?project rdf:type a:Project . ?project a:PR.hasProjectID \"{project_ID}\" ."

    where_content += '''
            OPTIONAL { ?project a:PR.hasProjectID ?project_ID . }
            OPTIONAL { ?project a:SPR.hasClusteringLink ?clusteringLink . }
            OPTIONAL { ?project a:SPR.hasExperimentDesignLink ?experimentDesignLink . }
            OPTIONAL { ?project a:SPR.hasExperimentMetadataLink ?experimentMetadataLink . }
            OPTIONAL { ?project a:SPR.hasFilteredTPMLink ?filteredTPMLink . }
            OPTIONAL { ?project a:SPR.hasMarkerGenesLink ?markerGenesLink . }
            OPTIONAL { ?project a:SPR.hasMatrixLink ?matrixLink . }
            OPTIONAL { ?project a:SPR.hasNormalisedCountsLink ?normalisedCountsLink . }
            OPTIONAL { ?project a:SPR.hasRawCountsLink ?rawCountsLink . }
            OPTIONAL { ?project a:SPR.hasResultsLink ?resultsLink . }
        '''

    query = '''
            PREFIX a: <http://www.semanticweb.org/alicia/ontologies/2020/8/singleCellRepositories#>
            PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
            SELECT
                ?project_ID
                ?clusteringLink
                ?experimentDesignLink
                ?experimentMetadataLink
                ?filteredTPMLink
                ?markerGenesLink
                ?matrixLink
                ?normalisedCountsLink
                ?rawCountsLink
                ?resultsLink
            WHERE { ''' + where_content + '}'

    print(query)

    response = requests.post(request_url, data={'query': query})
    downloads = __fuseki_to_dict(response)

    return downloads


def get_percentile(gen_names=[], cell_types=[], project_IDs=[]):
    ix = index.open_dir("../SingleCell-Files/index")
    qp = QueryParser("content", ix.schema)
    genes_project_IDs = []
    cell_types_project_IDs = []

    # Search for projects with that meet the filter conditions (gen_names and cell_types)
    for gen_name in gen_names:

        q = qp.parse(gen_name)

        with ix.searcher() as s:
            results = s.search(q, limit=None)
            for result in results:
                genes_project_IDs.append(result['title'])

    for cell_type in cell_types:

        q = qp.parse(cell_type)

        with ix.searcher() as s:
            results = s.search(q, limit=None)
            for result in results:
                cell_types_project_IDs.append(result['title'])

    percentile_project_IDs = __intersection(genes_project_IDs, cell_types_project_IDs)

    percentile_projects = []
    key_items = ['project_ID', 'gen_name'] + cell_types

    if not percentile_project_IDs:
        percentile_project_IDs = project_IDs

    print(percentile_project_IDs)

    # For each project parse the response
    for percentile_project_ID in percentile_project_IDs:
        # Filter with project ID
        if project_IDs and percentile_project_ID not in project_IDs:
            continue

        # If project is not in the index
        filename = f'../SingleCell-Files/percentiles/{percentile_project_ID}.percentiles.csv'
        if not os.path.isfile(filename):
            continue

        # Read percentile file
        df = pd.read_csv(filename)

        # Filter gene names
        if gen_names:
            df = df[df['gen_name'].isin(gen_names)]
        print("project_info")
        project_info = requests.get('http://localhost:5001/project/info/' + percentile_project_ID).json()
        print(project_info)

        # Loop over gen-project
        for df_dict in df.to_dict('records'):
            df_dict.update({'project_ID': percentile_project_ID})

            if cell_types:
                df_dict = {k: v for k, v in df_dict.items() if k in key_items}

            df_dict.update(project_info)
            percentile_projects.append(df_dict)

    return percentile_projects


def get_project_info(project_ID):
    query = '''
        PREFIX a: <http://www.semanticweb.org/alicia/ontologies/2020/8/singleCellRepositories#>
        PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
        SELECT DISTINCT
          ?disease
          ?organismPart
          ?projectLink
        WHERE { 
          ?project rdf:type a:Project . ''' + \
            f'?project a:PR.hasProjectID "{project_ID}" .' + \
            '''
          ?project a:PR.hasProjectRepositoryLink ?projectLink
          OPTIONAL { ?project a:SPR.hasOrganismPart ?organismPart . }
          OPTIONAL { ?project a:SPR.hasDisease ?disease . }
        }
    '''

    print(query)

    response = requests.post(request_url, data={'query': query})
    project_info = __fuseki_to_dict(response)

    return project_info
