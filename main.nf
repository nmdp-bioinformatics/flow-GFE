#!/usr/bin/env nextflow
/*

    nextflow script for running fasta through GFE pipeline 
    Copyright (c) 2014-2015 National Marrow Donor Program (NMDP)

    This library is free software; you can redistribute it and/or modify it
    under the terms of the GNU Lesser General Public License as published
    by the Free Software Foundation; either version 3 of the License, or (at
    your option) any later version.

    This library is distributed in the hope that it will be useful, but WITHOUT
    ANY WARRANTY; with out even the implied warranty of MERCHANTABILITY or
    FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public
    License for more details.

    You should have received a copy of the GNU Lesser General Public License
    along with this library;  if not, write to the Free Software Foundation,
    Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307  USA.

    > http://www.gnu.org/licenses/lgpl.html

    ./nextflow run nmdp-bioinformatics/flow-GFE \
      -with-docker nmdpbioinformatics/service-gfe-submission \
      --input /location/of/hmlfiles --outfile typing_results.txt

*/

params.input = "${baseDir}/tutorial"
params.output = "gfe_results.txt"
params.type = "xml.gz"
fileglob = "${params.input}/*.${params.type}"
outputfile = file("${params.output}")
params.help = ''

inputFiles = Channel.fromPath(fileglob).ifEmpty { error "cannot find any files matching ${fileglob}" }.map { path -> tuple(sample(path), path) }

/*  Help section (option --help in input)  */
if (params.help) {
    log.info ''
    log.info '---------------------------------------------------------------'
    log.info 'NEXTFLOW GFE'
    log.info '---------------------------------------------------------------'
    log.info ''
    log.info 'Usage: '
    log.info '  nextflow run nmdp-bioinformatics/flow-GFE \\'
    log.info '    -with-docker nmdpbioinformatics/service-gfe-submission \\'
    log.info '    --input hmlfiles/ [--outfile gfe_results.txt] '
    log.info ''
    log.info 'Run Tutorial: '
    log.info '  nextflow run nmdp-bioinformatics/flow-GFE \\'
    log.info '    -with-docker nmdpbioinformatics/service-gfe-submission '
    log.info ''
    log.info 'Options:'
    log.info '    --input       FOLDER          Folder containing INPUT FILES'
    log.info '    --outfile     STRING          Name of output file (default : gfe_results.txt)'
    log.info '    --type        STRING          Type of the input files (default : xml.gz)'
    log.info ''
    log.info ''
    exit 1
}

/* Software information */
log.info ''
log.info '---------------------------------------------------------------'
log.info 'NEXTFLOW GFE'
log.info '---------------------------------------------------------------'
log.info "Input file folder   (--input)         : ${params.input}"
log.info "Type of input file  (--type)          : ${params.type}"
log.info "Output file name    (--output)        : ${params.output}"
log.info "Project                               : $workflow.projectDir"
log.info "Git info                              : $workflow.repository - $workflow.revision [$workflow.commitId]"
log.info "\n"

// Breaking up HML file
if(params.type == "hml" || params.type == "xml.gz"){
  process breakupHml{
    errorStrategy 'ignore'

    tag{ "${subid} ${hmlfile}" }

    input:
      set subid, file(hmlfile) from inputFiles
      val typed from params.type

    output:
      stdout fastaFiles

    """
      ngs-extract-consensus-stdout -i ${hmlfile}
    """
  }
}

//Get GFE For each sequence
process getGFE{
  errorStrategy 'ignore'

  input:
    stdin from fastaFiles

  output:
    stdout gfeResults

  """
    fasta2gfe_nextflow -
  """
}

gfeResults
.collectFile() {  gfe ->
       [ "temp_file", gfe ]
   }
.subscribe { file -> copy(file) }


// On completion
workflow.onComplete {
    println "Pipeline completed at : $workflow.complete"
    println "Duration              : ${workflow.duration}"
    println "Execution status      : ${ workflow.success ? 'OK' : 'failed' }"
}


def copy (file) { 
  log.info "Copying ${file.name} into: $outputfile"
  file.copyTo(outputfile)
}

def sample(Path path) {
  def name = path.getFileName().toString()
  int start = Math.max(0, name.lastIndexOf('/'))
  return name.substring(start, name.indexOf("."))
}


