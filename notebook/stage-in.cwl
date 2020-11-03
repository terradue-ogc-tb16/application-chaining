
$graph:
- baseCommand: stage-in
  class: CommandLineTool
  hints:
    DockerRequirement:
      dockerPull: eoepca/stage-in:0.2
  id: stagein
  inputs:
    inp1:
      inputBinding:
        position: 1
        prefix: -t
      type: string
    inp2:
      inputBinding:
        position: 2
      type: string[]
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
- class: Workflow
  label: Instac stage-in
  doc: Stage-in using Instac
  id: main
  inputs:
    input_reference:
      doc: A reference to an opensearch catalog
      label: A reference to an opensearch catalog
      type: string[]
    target_folder:
      label: Folder to stage-in 
      doc: Folder to stage-in 
      type: string
  outputs:
  - id: wf_outputs
    outputSource:
    - node_1/results
    type: Directory
  steps:
    node_1:
      in:
        inp1: target_folder
        inp2: input_reference
      out:
      - results
      run: '#stagein'
cwlVersion: v1.0
