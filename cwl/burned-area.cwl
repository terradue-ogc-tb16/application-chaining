$graph:

- baseCommand: stage-in
  class: CommandLineTool
  hints:
    DockerRequirement:
      dockerPull: eoepca/stage-in:0.2
  id: stagein
  arguments:
      - prefix: -t
        valueFrom: ./
  inputs:
    inp1:
      inputBinding:
        position: 2
      type: string
  outputs:
    results:
      outputBinding:
        glob: .
      type: Directory
  requirements:
    EnvVarRequirement:
      envDef:
        PATH: /opt/anaconda/envs/env_stagein/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
    ResourceRequirement: {}

- baseCommand: vegetation-index
  class: CommandLineTool
  hints:
    DockerRequirement:
      dockerPull: terradue/nb-vegetation-index:latest
  id: vegetation
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
        valueFrom: $(inputs.inp1[0])
      type: Directory[]
    inp2:
      inputBinding:
        position: 2
        prefix: --post_event
        valueFrom: $(inputs.inp2[1])
      type: Directory[]
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
    InlineJavascriptRequirement: {}
    EnvVarRequirement:
      envDef:
        PATH: /opt/anaconda/envs/env_burned_area_delineation/bin:/opt/anaconda/envs/env_burned_area_delineation/bin:/opt/anaconda/envs/env_default/bin:/opt/anaconda/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
        PREFIX: /opt/anaconda/envs/env_burned_area_delineation
    ResourceRequirement: {}
  stderr: std.err
  stdout: std.out
  

- class: Workflow
  label: Burned area
  doc: Burned area
  id: burned-area
  inputs:
    pre_event:
      doc: A Sentinel-2 Level-2 catalog reference for the pre-event acquisition
      label: Pre-event acquisition
      type: string
    post_event:
      doc: A Sentinel-2 Level-2 catalog reference for the post-event acquisition
      label: Post-event acquisition
      type: string
    aoi:
      doc: Area of interest in WKT
      label: Area of interest
      type: string
    ndvi_threshold:
      doc: NDVI difference threshold
      label: NDVI difference threshold
      type: string
    ndwi_threshold:
      doc: NDWI difference threshold
      label: NDWI difference threshold
      type: string
  outputs:
  - id: wf_outputs
    outputSource:
    - delineation/results
    type: Directory
  requirements:
  - class: ScatterFeatureRequirement
  - class: MultipleInputFeatureRequirement
  steps:
  
    stage-in:
      in:
        inp1: [pre_event, post_event]
      out:
      - results
      run: '#stagein'
      scatter: inp1
      scatterMethod: dotproduct
      
    vegetation-index:
      in:
        inp1: stage-in/results
        inp2: aoi
      out:
      - results
      run: '#vegetation'
      scatter: inp1
      scatterMethod: dotproduct
    
    delineation:
      in:
        inp1: vegetation-index/results
        inp2: vegetation-index/results
        inp3: ndvi_threshold
        inp4: ndwi_threshold
      out:
      - results
      run: '#delineation'

cwlVersion: v1.0