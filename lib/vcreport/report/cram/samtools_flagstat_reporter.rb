# frozen_string_literal: true

require 'pathname'
require 'csv'
require 'vcreport/report/reporter'
require 'vcreport/report/cram/samtools_flagstat'
require 'vcreport/metrics_manager'
require 'vcreport/settings'

module VCReport
  module Report
    class Cram
      class SamtoolsFlagstatReporter < Reporter
        # @param cram_path       [Pathname]
        # @param metrics_dir     [Pathname]
        # @param metrics_manager [MetricsManager, nil]
        # @return                [SamtoolsFlagstat, nil]
        def initialize(cram_path, metrics_dir, metrics_manager)
          @cram_path = cram_path
          @out_dir = metrics_dir / 'samtools-flagstat'
          @samtools_flagstat_path = @out_dir / "#{cram_path.basename}.flagstat"
          super(metrics_manager, @samtools_flagstat_path)
        end

        private

        # @return [SamtoolsFlagstat]
        def parse
          flagstat = SamtoolsFlagstat.new
          File.foreach(@samtools_flagstat_path, chomp: true) do |line|
            is_valid_line = false
            SamtoolsFlagstat::FIELDS.each do |attr, trailing|
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

        # @return [Boolean]
        def metrics
          FileUtils.mkpath @out_dir
          job_definition =
            {
              nthreads: 1,
              in_bam:
                {
                  class: 'File',
                  format: 'http://edamontology.org/format_2572', # actuall BAM
                  path: @cram_path.expand_path.to_s
                }
            }
          script_path = "#{HUMAN_RESEQ_DIR}/Tools/samtools-flagstat.cwl"
          run_cwl(script_path, job_definition, @out_dir)
        end

        # @param line     [String]
        # @param trailing [String]
        # @return         [NumReads, nil]
        def extract_pass_and_fail(line, trailing)
          return nil unless line =~ /^(\d+) \+ (\d+) #{Regexp.escape(trailing)}(\s|$)/

          SamtoolsFlagstat::NumReads.new($1.to_i, $2.to_i)
        end
      end
    end
  end
end
