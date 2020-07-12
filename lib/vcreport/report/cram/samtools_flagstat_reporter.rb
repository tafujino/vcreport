# frozen_string_literal: true

require 'pathname'
require 'csv'
require 'vcreport/edam'
require 'vcreport/report/reporter'
require 'vcreport/report/cram/samtools_flagstat'
require 'vcreport/job_manager'
require 'vcreport/settings'

module VCReport
  module Report
    class Cram
      class SamtoolsFlagstatReporter < Reporter
        CWL_SCRIPT_PATH = "#{HUMAN_RESEQ_DIR}/Tools/samtools-flagstat.cwl"

        # @param cram_path   [Pathname]
        # @param metrics_dir [Pathname]
        # @param job_manager [JobManager, nil]
        # @return            [SamtoolsFlagstat, nil]
        def initialize(cram_path, metrics_dir, job_manager)
          @cram_path = cram_path
          @out_dir = metrics_dir / 'samtools-flagstat'
          @samtools_flagstat_path = @out_dir / "#{cram_path.basename}.flagstat"
          super(job_manager, targets: @samtools_flagstat_path, deps: @cram_path)
        end

        private

        # @return [SamtoolsFlagstat]
        def parse
          params = {}
          File.foreach(@samtools_flagstat_path, chomp: true) do |line|
            is_valid_line = false
            SamtoolsFlagstat::FIELDS.each do |attr, trailing|
              num_alignments = extract_pass_and_fail(line, trailing)
              next unless num_alignments

              params[attr] = num_alignments
              is_valid_line = true
            end
            unless is_valid_line
              warn "Invalid line: #{line}"
              exit 1
            end
          end
          program_name = CWL.script_docker_path(CWL_SCRIPT_PATH)
          SamtoolsFlagstat.new(@samtools_flagstat_path, program_name, **params)
        end

        # @return [Boolean]
        def run_metrics
          FileUtils.mkpath @out_dir
          job_definition =
            {
              nthreads: 1,
              in_bam: CWL.file_field(@cram_path, edam: Edam::BAM)
            }
          CWL.run(CWL_SCRIPT_PATH, job_definition, @out_dir)
        end

        # @param line     [String]
        # @param trailing [String]
        # @return         [NumReads, nil]
        def extract_pass_and_fail(line, trailing)
          regexp = /^(\d+) \+ (\d+) #{Regexp.escape(trailing)}(\s|$)/
          return nil unless line =~ regexp

          SamtoolsFlagstat::NumReads.new($1.to_i, $2.to_i)
        end
      end
    end
  end
end
