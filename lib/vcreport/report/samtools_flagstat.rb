# frozen_string_literal: true

require_relative 'table'

module VCReport
  module Report
    class SamtoolsFlagstat
      class NumAlignments
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

      # @return [NumAlignment]
      attr_accessor(*FIELDS.keys)

      def initialize; end

      # @return [Table]
      def to_table
        header = ['description', '# of passed reads', '# of failed reads']
        rows = FIELDS.map do |message, name|
          num_alignments = send(message)
          [name, num_alignments.passed, num_alignments.failed]
        end
        type = %i[string integer integer]
        Table.new(header, rows, type)
      end

      class << self
        def run(cram_path, metrics_dir, metrics_manager)
          out_dir = metrics_dir / 'samtools-flagstat'
          samtools_flagstat_path = out_dir / "#{cram_path.basename}.flagstat"
          if samtools_flagstat_path.exist?
            load_samtools_flagstat(samtools_flagstat_path)
          else
            metrics_manager&.post(samtools_flagstat_path) do
              run_samtools_flagstat(cram_path, out_dir)
            end
            nil
          end
        end

        # @param samtools_flagstats_path [Pathname]
        # @return                        [Report::SamtoolsFlagstat]
        def load_samtools_flagstat(samtools_flagstat_path)
          flagstat = SamtoolsFlagstat.new
          File.foreach(samtools_flagstat_path, chomp: true) do |line|
            is_valid_line = false
            FIELDS.each do |attr, trailing|
              num_alignments = extract_pass_and_fail(line, trailing)
              next unless num_alignments

              flagstat.send("#{attr}=", num_alignments)
              is_valid_line = true
            end
            unless is_valid_line
              warn "Invalid line: #{line}"
              exit 1
            end
          end
          flagstat
        end

        # @param line     [String]
        # @param trailing [String]
        # @return         [NumAlignments, nil]
        def extract_pass_and_fail(line, trailing)
          return nil unless line =~ /^(\d+) \+ (\d+) #{Regexp.escape(trailing)}(\s|$)/

          NumAlignments.new($1.to_i, $2.to_i)
        end
      end
    end
  end
end

#nthreads: 4
#in_bam:
#  class: File
#  format: http://edamontology.org/format_3462
#  path: <cram path>
#
