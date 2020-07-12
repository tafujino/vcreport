# frozen_string_literal: true

require 'vcreport/report/table'
require 'vcreport/report/cram/samtools_idxstats'
require 'vcreport/report/cram/samtools_flagstat'
require 'vcreport/report/cram/picard_collect_wgs_metrics_collection'

module VCReport
  module Report
    class Cram
      # @return [SamtoolsIdxstats, nil]
      attr_reader :samtools_idxstats

      # @return [SamtoolsFlagstat, nil]
      attr_reader :samtools_flagstat

      # @return [PicardCollectWgsMetrics]
      attr_reader :picard_collect_wgs_metrics_collection

      # @param cram_path                             [Pathname]
      # @param samtools_idxstats_report              [SamtoolsIdxstats, nil]
      # @param samtools_flagstat_report              [SamtoolsFlagstat, nil]
      # @param picard_collect_wgs_metrics_collection [PicardCollectWgsMetricsCollection]
      def initialize(
            cram_path,
            samtools_idxstats,
            samtools_flagstat,
            picard_collect_wgs_metrics_collection
          )
        @cram_path = cram_path
        @samtools_idxstats = samtools_idxstats
        @samtools_flagstat = samtools_flagstat
        @picard_collect_wgs_metrics_collection = picard_collect_wgs_metrics_collection
      end

      # @return [Table]
      def path_table
        Table.file_table(@cram_path, 'input file')
      end
    end
  end
end
