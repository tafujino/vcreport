# frozen_string_literal: true

require 'pathname'
require 'vcreport/report/table'
require 'vcreport/metrics_manager'

module VCReport
  module Report
    class Cram
      class SamtoolsFlagstat
        class NumReads
          # @return [Integer]
          attr_reader :passed

          # @return [Integer]
          attr_reader :failed

          # @param passed [Integer]
          # @param failed [Integer]
          def initialize(passed, failed)
            @passed = passed
            @failed = failed
          end
        end

        FIELDS = {
          total: 'in total',
          secondary: 'secondary',
          supplementary: 'supplementary',
          duplicates: 'duplicates',
          mapped: 'mapped',
          paired_in_sequencing: 'paired in sequencing',
          read1: 'read1',
          read2: 'read2',
          properly_paired: 'properly paired',
          itself_and_mate_mapped: 'with itself and mate mapped',
          singletons: 'singletons',
          mate_mapped_to_different_chr:
            'with mate mapped to a different chr',
          mate_mapped_to_different_chr_mq_ge5:
            'with mate mapped to a different chr (mapQ>=5)'
        }.freeze

        # @return [NumReads]
        attr_accessor(*FIELDS.keys)

        def initialize; end

        # @return [Table]
        def table
          header = ['description', '# of passed reads', '# of failed reads']
          rows = FIELDS.map do |attr, desc|
            num_reads = send(attr)
            [desc, num_reads.passed, num_reads.failed]
          end
          type = %i[string integer integer]
          Table.new(header, rows, type)
        end
      end
    end
  end
end
