import os
import yaml
import tempfile
import subprocess
import json
import requests

endpoint = 'http://ades-dev.eoepca.terradue.com' 

namespace = 'terradue'

cwltool = '/opt/anaconda/bin/cwltool'

class Workflow():
    
    def __init__(cwl_file):

        with open(cwl_file) as file:

            cwl = yaml.load(file,
                        Loader=yaml.FullLoader)

        self.cwl = cwl
        self.cwl_file = cwl_file
        self.result = None

    def get_workflow_class(self):

        cwl_workflow = None

        for block in self.cwl['$graph']:

            if block['class'] == 'Workflow':

                cwl_workflow = block

                break

        return cwl_workflow

    def get_workflow_id(self):

        return get_workflow_class(self.cwl)['id']

    def get_workflow_inputs():

        wf = get_workflow_class(self.cwl)

        return wf['inputs']

    def process_worflow(self, params):

        temp_file = os.path.join('/tmp', next(tempfile._get_candidate_names()))

        with open(temp_file, 'w') as yaml_file:

            yaml.dump(params,
                      yaml_file, 
                      default_flow_style=False)

        # invoke cwltool
        cmd_args = [cwltool, 
                    '--no-read-only',
                    '--no-match-user',
                    '{}#{}'.format(self.cwl_file , 
                                   self.get_workflow_id()), 
                    temp_file]

        print(' '.join(cmd_args))

        pipes = subprocess.Popen(cmd_args, 
                                 stdout=subprocess.PIPE, 
                                 stderr=subprocess.PIPE)

        std_out, std_err = pipes.communicate()

        os.remove(temp_file)

        self.result = std_out.decode()
        
        return json.loads(self.result), std_err

    def get_catalog(self):

        if type(self.result['wf_outputs']) is list and self.result['wf_outputs'][0] is None:

            raise ValueError('Empty results')

        stac_catalog = None

        staged_stac_catalogs = []


        if type(self.result['wf_outputs']) is dict:

            for index, listing in enumerate(self.result['wf_outputs']['listing']):

                if listing['class'] == 'File':

                    if (listing['basename']) == 'catalog.json':

                        stac_catalog = listing['location']

                    break

        elif type(self.result['wf_outputs']) is list:

            for index, listing in enumerate(self.result['wf_outputs']):

                for sublisting in listing['listing']:

                    if (sublisting['basename']) == 'catalog.json':
                        stac_catalog = sublisting['location']

                        break

        return stac_catalog

class Process:
    
    def __init__(self, token):
        
        self.endpoint = 'http://ades-dev.eoepca.terradue.com' 
        self.namespace = 'terradue'
        
        self.token = token
        self.process_id = process_id
        self.endpoint = endpoint
        
    def _get_deploy_payload(self, url):

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

    def _get_headers(self, token):

        headers = {'Authorization': f'Bearer {self.token}',
                   'Content-Type': 'application/json',
                   'Accept': 'application/json'}

    def get_deploy_headers(self, token):

        deploy_headers = {'Authorization': f'Bearer {self.token}',
                          'Content-Type': 'application/json',
                          'Accept': 'application/json', 
                          'Prefer': 'respond-async'} 

        return deploy_headers

    def deploy_process(self, cwl_url):

        r = requests.post(f'{self.endpoint}/{self.namespace}/wps3/processes',
                          json=self.get_deploy_payload(cwl_url),
                          headers= self._get_deploy_headers(self.token))

        return r

    def get_process(self, process_id=None):

        headers = {'Authorization': f'Bearer {self.token}',
                   'Content-Type': 'application/json',
                   'Accept': 'application/json'}

        r = None
        
        if process_id is None:

            r = requests.get(f'{self.endpoint}/{self.namespace}/wps3/processes',
                                headers=get_headers(self.token))

        else:

            r = requests.get(f'{self.endpoint}/{self.namespace}/wps3/processes/{self.process_id}',
                                headers=self._get_headers(self.token))
        
        return r

class Execution:
    
    def __init__(token, process_id):
        
        self.endpoint = 'http://ades-dev.eoepca.terradue.com' 
        self.namespace = 'terradue'
        
        self.token = token
        self.process_id = process_id
        self.endpoint = endpoint
        self.namespace = namespace
        self.job_location = None
        
    def execute_process(self, execute_inputs):
    
        execution_headers = {'Authorization': f'Bearer {self.token}',
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

        r = requests.post(f'{self.endpoint}/{self.namespace}/wps3/processes/{self.process_id}/jobs',
                             json=execute_request,
                             headers=execution_headers)

        if r.status_code == 200:
            
            self.job_location = r.headers['Location']
 
        return r
        
    def get_job_location(self):
        
        return self.job_location
    
    def get_status(self):

        if self.job_location = None:
            
            return None
        
        r = requests.get(f'{self.endpoint}{self.job_location}',
                         headers=get_headers(self.token))
        
        return r

    def get_result(self):
        
         if self.job_location = None:
            
            return None

        r = requests.get(f'{self.endpoint}/{self.job_location}/result',
                         headers=get_headers(self.token))
        
        return r
