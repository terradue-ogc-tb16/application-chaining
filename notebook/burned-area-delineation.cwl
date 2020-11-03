$graph:
- baseCommand: burned-area-delineation
  class: CommandLineTool
  hints:
    DockerRequirement:
      dockerPull: terradue/nb-burned-area-delineation:latest
  id: clt
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
  stderr: std.err
  stdout: std.out
- class: Workflow
  doc: Burned area delineation using two techniques
  id: burned-area-delineation
  inputs:
    ndvi_threshold:
      doc: NDVI difference threshold
      label: NDVI difference threshold
      type: string
    ndwi_threshold:
      doc: NDWI difference threshold
      label: NDWI difference threshold
      type: string
    post_event:
      doc: Post-event product for burned area delineation
      label: Post-event product for burned area delineation
      type: Directory
    pre_event:
      doc: Pre-event product for burned area delineation
      label: Pre-event product for burned area delineation
      type: Directory
  label: Burned area delineation
  outputs:
  - id: wf_outputs
    outputSource:
    - node_1/results
    type: Directory
  steps:
    node_1:
      in:
        inp1: pre_event
        inp2: post_event
        inp3: ndvi_threshold
        inp4: ndwi_threshold
      out:
      - results
      run: '#clt'
cwlVersion: v1.0
