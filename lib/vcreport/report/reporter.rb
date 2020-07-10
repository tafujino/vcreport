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
      # @param metrics_manager [MetricsManager, nil]
      # @param targets         [Array<Pathname>]
      # @param deps            [Array<Pathname>]
      def initialize(metrics_manager, targets: [], deps: [])
        @metrics_manager = metrics_manager
        @target_paths, @dep_paths = [targets, deps].map do |e|
          e.is_a?(Array) ? e : [e]
        end
      end

      def try_parse
        exist_targets, exist_deps = [@target_paths, @dep_paths].map do |paths|
          paths.all? { |path| File.exist?(path) }
        end
        return nil unless IGNORE_DEPS_INEXISTENCE || exist_deps

        ret = exist_targets ? parse : nil
        unless @target_paths.empty?
          @metrics_manager&.post(@target_paths.first) { run_metrics }
        end
        ret
      end

      private

      # @abstract
      def parse; end

      # @abstract
      def run_metrics; end

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
          >& #{out_dir / 'cwl.log'}
        COMMAND
      end
    end
  end
end
