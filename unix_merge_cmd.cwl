#!/usr/bin/env cwl-runner

cwlVersion: v1.0

class: CommandLineTool

requirements:
  - class: DockerRequirement
    dockerPull: ubuntu
  - class: InlineJavascriptRequirement
  - class: ShellCommandRequirement

inputs:
  - id: INPUT
    type:
      type: array
      items: File

  - id: OUTPUT
    type: string

outputs:
  - id: MERGED_OUTPUT
    type: File
    outputBinding:
      glob: $(inputs.OUTPUT)

arguments:
    - valueFrom: |
        ${
          if (inputs.INPUT.length == 0) {
            var cmd = ['/usr/bin/touch ' + inputs.OUTPUT];
            return cmd;
          }
          else {
            var cmd = "";
            var have_input = false;
            for (var i = 0; i < inputs.INPUT.length; i++) {
              if (inputs.INPUT[i].size > 0) {
                if (have_input) {
                  cmd += "&& cat " + inputs.INPUT[i].path + " >> " + inputs.OUTPUT;
                }
                else {
                  cmd += "cat " + inputs.INPUT[i].path + " >> " + inputs.OUTPUT;
                  have_input = true;
                }
              }
            }
            return cmd
          }
        }
        
baseCommand: [bash, -c]
