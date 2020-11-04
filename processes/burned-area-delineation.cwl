$graph:
- baseCommand: burned-area-delineation
  class: CommandLineTool
  hints:
    DockerRequirement:
      dockerPull: terradue/nb-burned-area-delineation:latest
  id: delineation
  inputs:
    inp1:
      inputBinding:
        position: 1
        prefix: --pre_event
      type: Directory
    inp2:
      inputBinding:
        position: 2
        prefix: --post_event
      type: Directory
    inp3:
      inputBinding:
        position: 3
        prefix: --ndvi_threshold
      type: string
    inp4:
      inputBinding:
        position: 4
        prefix: --ndwi_threshold
      type: string
    inp5:
       inputBinding:
         position: 5
         prefix: --store_username
       type: string
    inp6:
       inputBinding:
         position: 6
         prefix: --store_apikey
       type: string
  outputs:
    results:
      outputBinding:
        glob: .
      type: Directory
  requirements:
    EnvVarRequirement:
      envDef:
        PATH: /opt/anaconda/envs/env_burned_area_delineation/bin:/opt/anaconda/envs/env_burned_area_delineation/bin:/opt/anaconda/envs/env_default/bin:/opt/anaconda/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
        PREFIX: /opt/anaconda/envs/env_burned_area_delineation
    ResourceRequirement: {}
#  stderr: std.err
#  stdout: std.out
  
- class: Workflow
  label: Burned area
  doc: Burned area
  id: burned-area
  inputs:
    pre_event:
      doc: A Sentinel-2 Level-2 catalog reference for the pre-event acquisition
      label: Pre-event acquisition
      type: Directory
    post_event:
      doc: A Sentinel-2 Level-2 catalog reference for the post-event acquisition
      label: Post-event acquisition
      type: Directory
    ndvi_threshold:
      doc: NDVI difference threshold
      label: NDVI difference threshold
      type: string
    ndwi_threshold:
      doc: NDWI difference threshold
      label: NDWI difference threshold
      type: string
    store_apikey:
       doc: ''
       id: store_apikey
       label: ''
       type: string
    store_username:
       doc: ''
       id: store_username
       label: ''
       type: string
  outputs:
  - id: wf_outputs
    outputSource:
    - delineation/results
    type: Directory
 
  steps:
    delineation:
      in:
        inp1: pre_event
        inp2: post_event
        inp3: ndvi_threshold
        inp4: ndwi_threshold
        inp5: store_username
        inp6: store_apikey
      out:
      - results
      run: '#delineation'

cwlVersion: v1.0