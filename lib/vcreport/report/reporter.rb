# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext/hash/indifferent_access'
require 'vcreport/metrics_manager'
require 'yaml'
require 'pathname'

module VCReport
  module Report
    # @abstract
    class Reporter
      # @param metrics_manager         [MetricsManager]
      # @param metrics_path            [Pathname]
      # @param metrics_secondary_paths [Array<Pathname>]
      def initialize(metrics_manager, metrics_path, *metrics_secondary_paths)
        @metrics_manager = metrics_manager
        @metrics_path = metrics_path
        @metrics_secondary_paths = metrics_secondary_paths
      end

      def run
        deps = [@metrics_path] + @metrics_secondary_paths
        ret = deps.all? { |path| File.exist?(path) } ? parse : nil
        @metrics_manager&.post(@metrics_path) do
          metrics
        end
        ret
      end

      private

      # @abstract
      def parse; end

      # @abstract
      def metrics; end

      def store_job_file(job_path, job_definition)
        File.write(job_path, YAML.dump(job_definition.deep_stringify_keys))
      end

      # @return [Boolean]
      def run_cwl(script_path, job_definition, out_dir)
        job_path = out_dir / 'job.yaml'
        store_job_file(job_path, job_definition)
        MetricsManager.shell <<~COMMAND.squish
          cwltool
          --singularity
          --outdir #{out_dir}
          #{script_path}
          #{job_path}
          2>&1
          > #{out_dir / 'cwl.log'}
        COMMAND
      end
    end
  end
end
