#!/usr/bin/env cwl-runner

cwlVersion: v1.0

class: Workflow

requirements:
  - class: InlineJavascriptRequirement
  - class: MultipleInputFeatureRequirement
  - class: ScatterFeatureRequirement
  - class: StepInputExpressionRequirement

inputs:
  - id: bam_path
    type: File

outputs:
  - id: merged_bam
    type: File
    outputSource: merge_all/MERGED_OUTPUT

steps:
  - id: bamtoreadgroup
    run: unix_bamreadgroup_cmd.cwl
    in:
      - id: bam_path
        source: bam_path
    out:
      - id: output_readgroup

  - id: bamtofastq
    run: unix_bamtofastq_cmd.cwl
    in:
      - id: bam_path
        source: bam_path
    out:
      - id: output_fastq1
      - id: output_fastq2
      - id: output_fastq_o1

  - id: decider_align_pe
    run: decider_align_expression.cwl
    in:
      - id: fastq_path
        source: bamtofastq/output_fastq1
      - id: readgroup_path
        source: bamtoreadgroup/output_readgroup
    out:
      - id: output_readgroup_paths

  - id: decider_align_o1
    run: decider_align_expression.cwl
    in:
      - id: fastq_path
        source: bamtofastq/output_fastq_o1
      - id: readgroup_path
        source: bamtoreadgroup/output_readgroup
    out:
      - id: output_readgroup_paths

  - id: align_pe
    run: unix_align_pe.cwl
    scatter: [fastq1_path, fastq2_path, readgroup_path]
    scatterMethod: "dotproduct"
    in:
      - id: fastq1_path
        source: bamtofastq/output_fastq1
      - id: fastq2_path
        source: bamtofastq/output_fastq2
      - id: readgroup_path
        source: decider_align_pe/output_readgroup_paths
    out:
      - id: output_bam

  - id: align_o1
    run: unix_align_pe.cwl
    scatter: [fastq_path, readgroup_path]
    scatterMethod: "dotproduct"
    in:
      - id: fastq_path
        source: bamtofastq/output_fastq_o1
      - id: readgroup_path
        source: decider_align_o1/output_readgroup_paths
    out:
      - id: output_bam

  - id: merge_pe
    run: unix_merge_cmd.cwl
    in:
      - id: INPUT
        source: align_pe/output_bam
      - id: OUTPUT
        source: bam_path
        valueFrom: $(self.basename)
    out:
      - id: MERGED_OUTPUT

  - id: merge_o1
    run: unix_merge_cmd.cwl
    in:
      - id: INPUT
        source: align_o1/output_bam
      - id: OUTPUT
        source: bam_path
        valueFrom: $(self.basename)
    out:
      - id: MERGED_OUTPUT

  - id: merge_all
    run: unix_merge_cmd.cwl
    in:
      - id: INPUT
        source: [
        merge_pe/MERGED_OUTPUT,
        merge_o1/MERGED_OUTPUT
        ]
      - id: OUTPUT
        source: bam_path
        valueFrom: $(self.basename)
    out:
      - id: MERGED_OUTPUT
