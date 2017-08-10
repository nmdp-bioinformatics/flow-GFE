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
      -with-docker nmdpbioinformatics/flow-gfe \
      --fastafiles /location/of/fastafiles --outfile typing_results.txt

*/

params.input = "${baseDir}/tutorial"
params.output = "gfe_results.txt"
params.type = "fa"
fileglob = "${params.input}/*.${params.type}"
outputfile = file("${params.output}")
params.help = ''

catType = "cat"
inputFiles = Channel.create()
if(params.type == "hml" || params.type == "xml.gz"){
  inputFiles = Channel.fromPath(fileglob).ifEmpty { error "cannot find any files matching ${fileglob}" }.map { path -> tuple(sample(path), path) }
  catType = "zcat"
}else{
  if(params.type =~ "gz"){
    catType = "zcat"
  }
}

/*  Help section (option --help in input)  */
if (params.help) {
    log.info ''
    log.info '---------------------------------------------------------------'
    log.info 'NEXTFLOW GFE'
    log.info '---------------------------------------------------------------'
    log.info ''
    log.info 'Usage: '
    log.info 'nextflow run main.nf -with-docker nmdpbioinformatics/flow-gfe --fasta fastafiles/ [--outfile gfe_results.txt]'
    log.info ''
    log.info 'Mandatory arguments:'
    log.info '    --input       FOLDER          Folder containing INPUT FILES'
    log.info 'Options:'
    log.info '    --outfile     STRING          Name of output file (default : gfe_results.txt)'
    log.info '    --type        STRING          Type of the input files (default : fa)'
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
      file('*.fa.gz') into outputFasta mode flatten

    """
      ngs-extract-consensus -i ${hmlfile}
    """
  }
}

inputData = Channel.create()
if(params.type == "hml" || params.type == "xml.gz"){
  inputData = outputFasta.map { path -> tuple(sample(path), path) }
}else{
  inputData = Channel.fromPath(fileglob).ifEmpty { error "cannot find any files matching ${fileglob}" }.map { path -> tuple(sample(path), path) }
}

// Breaking up the fasta files
process breakupFasta{
  errorStrategy 'ignore'

  tag{ "${subid} ${fasta}" }

  input:
    set subid, file(fasta) from inputData

  output:
    set subid, file('*.txt') into fastaFiles mode flatten

  """
    ${catType} ${fasta} | breakup-fasta
  """
}

//Get GFE For each sequence
process getGFE{
  errorStrategy 'ignore'

  tag{ fastafile }

  input:
    set subid, file(fastafile) from fastaFiles

  output:
    file {"*.txt"}  into gfeResults mode flatten

  """
    cat ${fastafile} | fasta2gfe -s ${subid}
  """
}

gfeResults
.collectFile() {  gfe ->
       [ "temp_file", gfe.text ]
   }
.subscribe { file -> copy(file) }

def copy (file) { 
  log.info "Copying ${file.name} into: $outputfile"
  file.copyTo(outputfile)
}

def sample(Path path) {
  def name = path.getFileName().toString()
  int start = Math.max(0, name.lastIndexOf('/'))
  return name.substring(start, name.indexOf("."))
}


