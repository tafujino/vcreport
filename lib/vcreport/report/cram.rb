# frozen_string_literal: true

require 'vcreport/report/cram/samtools_idxstats'
require 'vcreport/report/cram/samtools_flagstat'

module VCReport
  module Report
    class Cram
      # @return [SamtoolsIdxstats]
      attr_reader :samtools_idxstats

      # @return [SamtoolsFlagstat]
      attr_reader :samtools_flagstat

      # @param samtools_idxstats_report [SamtoolsIdxstats, nil]
      # @param samtools_flagstat_report [SamtoolsFlagstat, nil]
      def initialize(
            samtools_idxstats,
            samtools_flagstat
          )
        @samtools_idxstats = samtools_idxstats
        @samtools_flagstat = samtools_flagstat
      end
    end
  end
end
