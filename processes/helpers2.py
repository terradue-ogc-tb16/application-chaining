import os
import yaml
import tempfile
import subprocess
import json
import requests

endpoint = 'http://ades-dev.eoepca.terradue.com' 

namespace = 'terradue'

cwltool = '/opt/anaconda/bin/cwltool'

def read_cwl(cwl_file):
    
    with open(cwl_file) as file:
    
        cwl = yaml.load(file,
                    Loader=yaml.FullLoader)
    
    return cwl

def get_workflow_class(cwl):
    
    cwl_workflow = None
    
    for block in cwl['$graph']:

        if block['class'] == 'Workflow':

            cwl_workflow = block

            break
            
    return cwl_workflow

def get_workflow_id(cwl_file):
    
    cwl = read_cwl(cwl_file)
        
    return get_workflow_class(cwl)['id']

def get_workflow_inputs(cwl_file):
    
    cwl = read_cwl(cwl_file)

    wf = get_workflow_class(cwl)
    
    return wf['inputs']

def process_worflow(cwl_file, params):
    
    temp_file = os.path.join('/tmp', next(tempfile._get_candidate_names()))
    
    with open(temp_file, 'w') as yaml_file:

        yaml.dump(params,
                  yaml_file, 
                  default_flow_style=False)
    
    # invoke cwltool
    cmd_args = [cwltool, 
                '--no-read-only',
                '--no-match-user',
                '{}#{}'.format(cwl_file, 
                               get_workflow_id(cwl_file)), 
                temp_file]
        
    print(' '.join(cmd_args))

    pipes = subprocess.Popen(cmd_args, 
                             stdout=subprocess.PIPE, 
                             stderr=subprocess.PIPE)
    
    std_out, std_err = pipes.communicate()
    
    os.remove(temp_file)
    
    return json.loads(std_out.decode()), std_err

def get_catalog(result):

    if type(result['wf_outputs']) is list and result['wf_outputs'][0] is None:
        
        raise ValueError('Empty results')
    
    stac_catalog = None

    staged_stac_catalogs = []


    if type(result['wf_outputs']) is dict:

        for index, listing in enumerate(result['wf_outputs']['listing']):

            if listing['class'] == 'File':

                if (listing['basename']) == 'catalog.json':

                    stac_catalog = listing['location']

                break

    elif type(result['wf_outputs']) is list:

        for index, listing in enumerate(result['wf_outputs']):

            for sublisting in listing['listing']:

                if (sublisting['basename']) == 'catalog.json':
                    stac_catalog = sublisting['location']

                    break

    return stac_catalog
                             
                             
def get_deploy_payload(url):
    
    deploy_payload = {'inputs': [{'id': 'applicationPackage',
                              'input': {'format': {'mimeType': 'application/cwl'},
                                        'value': {'href': '{}'.format(url)}}}],
                  'outputs': [{'format': {'mimeType': 'string',
                                          'schema': 'string',
                                          'encoding': 'string'},
                               'id': 'deployResult',
                               'transmissionMode': 'value'}],
                  'mode': 'auto',
                  'response': 'raw'}
    
    return deploy_payload

def get_headers(token):
    
    headers = {'Authorization': f'Bearer {token}',
               'Content-Type': 'application/json',
               'Accept': 'application/json'}

def get_deploy_headers(token):
    
    deploy_headers = {'Authorization': f'Bearer {token}',
                      'Content-Type': 'application/json',
                      'Accept': 'application/json', 
                      'Prefer': 'respond-async'} 
    
    return deploy_headers

def deploy_process(cwl_url, token):
    
    r = requests.post(f'{endpoint}/{namespace}/wps3/processes',
                      json=get_deploy_payload(cwl_url),
                      headers=get_deploy_headers(token))
    
    return r

def get_process(token, process_id=None):
    
    headers = {'Authorization': f'Bearer {token}',
               'Content-Type': 'application/json',
               'Accept': 'application/json'}
    
    if process_id is None:
    
        return requests.get(f'{endpoint}/{namespace}/wps3/processes',
                            headers=get_headers(token))
    
    else:
        
        return requests.get(f'{endpoint}/{namespace}/wps3/processes/{process_id}',
                            headers=get_headers(token))
    
    
def execute_process(token, process_id, execute_inputs):
    
    execution_headers = {'Authorization': f'Bearer {token}',
                       'Content-Type': 'application/json',
                       'Accept': 'application/json', 
                       'Prefer': 'respond-async'}
    
    execute_request = {'inputs': execute_inputs,
                       'outputs': [{'format': {'mimeType': 'string',
                                               'schema': 'string',
                                               'encoding': 'string'},
                                    'id': 'wf_output',
                                    'transmissionMode': 'value'}],
                       'mode': 'async',
                       'response': 'raw'}

    return requests.post(f'{endpoint}/{namespace}/wps3/processes/{process_id}/jobs',
                         json=execute_request,
                         headers=execution_headers)


    
def get_status(token, job_location):

    return requests.get(f'{endpoint}{job_location}',
                        headers=get_headers(token))

def get_result(token, job_location):
    
    return requests.get(f'{endpoint}/{job_location}/result',
                          headers=get_headers(token))
