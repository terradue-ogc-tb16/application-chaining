$graph:
- baseCommand: vegetation-index
  class: CommandLineTool
  hints:
    DockerRequirement:
      dockerPull: terradue/nb-vegetation-index:latest
  id: clt
  inputs:
    inp1:
      inputBinding:
        position: 1
        prefix: --input_reference
      type: Directory
    inp2:
      inputBinding:
        position: 2
        prefix: --aoi
      type: string
  outputs:
    results:
      outputBinding:
        glob: .
      type: Directory
  requirements:
    EnvVarRequirement:
      envDef:
        PATH: /opt/anaconda/envs/env_vegetation_index/bin:/opt/anaconda/envs/env_vegetation_index/bin:/opt/anaconda/envs/env_default/bin:/opt/anaconda/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
        PREFIX: /opt/anaconda/envs/env_vegetation_index
    ResourceRequirement: {}
  stderr: std.err
  stdout: std.out
- class: Workflow
  doc: Vegetation index processor
  id: vegetation-index
  inputs:
    aoi:
      doc: Area of interest in WKT
      label: Area of interest
      type: string
    input_reference:
      doc: EO product for vegetation index
      label: EO product for vegetation index
      type: Directory[]
  label: Vegetation index
  outputs:
  - id: wf_outputs
    outputSource:
    - node_1/results
    type:
      items: Directory
      type: array
  requirements:
  - class: ScatterFeatureRequirement
  steps:
    node_1:
      in:
        inp1: input_reference
        inp2: aoi
      out:
      - results
      run: '#clt'
      scatter: inp1
      scatterMethod: dotproduct
cwlVersion: v1.0
