# frozen_string_literal: true

require 'vcreport/job_manager'
require 'yaml'
require 'pathname'

module VCReport
  module Report
    # @abstract
    class Reporter
      EDAM_DOMAIN = 'http://edamontology.org'

      # @param job_manager [JobManager, nil]
      # @param targets     [Array<Pathname>]
      # @param deps        [Array<Pathname>]
      def initialize(job_manager, targets: [], deps: [])
        @job_manager = job_manager
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
          @job_manager&.post(@target_paths.first) { run_metrics }
        end
        ret
      end

      private

      # @abstract
      def parse; end

      # @abstract
      def run_metrics; end
    end
  end
end
