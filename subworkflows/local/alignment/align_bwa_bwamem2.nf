//
// Map to reference, fetch stats for each demultiplexed read pair, merge, mark duplicates, and index.
//

include { BWA_MEM                                  } from '../../../modules/nf-core/bwa/mem/main'
include { BWAMEM2_MEM                              } from '../../../modules/nf-core/bwamem2/mem/main'
include { SAMTOOLS_INDEX as SAMTOOLS_INDEX_ALIGN   } from '../../../modules/nf-core/samtools/index/main'

workflow ALIGN_BWA_BWAMEM2 {
    take:
        ch_reads_input   // channel: [mandatory] [ val(meta), path(reads_input) ]
        ch_bwa_index     // channel: [mandatory] [ val(meta), path(bwamem2_index) ]
        ch_bwamem2_index // channel: [mandatory] [ val(meta), path(bwamem2_index) ]
        ch_genome_fasta  // channel: [mandatory] [ val(meta), path(fasta) ]
        ch_genome_fai    // channel: [mandatory] [ val(meta), path(fai) ]
        val_platform     // string:  [mandatory] default: illumina

    main:
        ch_versions = Channel.empty()

        // Map, sort, and index
        if (params.aligner.equals("bwa")) {
            BWA_MEM ( ch_reads_input, ch_bwa_index, true )
            ch_align = BWA_MEM.out.bam
            ch_versions = ch_versions.mix(BWA_MEM.out.versions.first())
        } else {
            BWAMEM2_MEM ( ch_reads_input, ch_bwamem2_index, true )
            ch_align = BWAMEM2_MEM.out.bam
            ch_versions = ch_versions.mix(BWAMEM2_MEM.out.versions.first())
        }

        SAMTOOLS_INDEX_ALIGN ( ch_align )

        ch_versions = ch_versions.mix(BWAMEM2_MEM.out.versions.first())
        ch_versions = ch_versions.mix(SAMTOOLS_INDEX_ALIGN.out.versions.first())

    emit:
        marked_bam  = ch_align        // channel: [ val(meta), path(bam) ]
        marked_bai  = SAMTOOLS_INDEX_ALIGN.out.bai // channel: [ val(meta), path(bai) ]
        versions    = ch_versions                    // channel: [ path(versions.yml) ]
}