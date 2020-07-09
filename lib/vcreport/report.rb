# frozen_string_literal: true

require 'vcreport/settings'
require 'vcreport/config'
require 'vcreport/report/progress'
require 'vcreport/report/sample'
require 'vcreport/report/sample_reporter'
require 'vcreport/metrics_manager'
require 'pathname'

module VCReport
  module Report
    class << self
      # @param project_dir          [String]
      # @param metrics_manager      [MetricsManager, nil]
      # @param num_samples_per_page [Integer]
      # @param render               [Boolean]
      def run(project_dir,
              config,
              metrics_manager = nil,
              num_samples_per_page: DEFAULT_NUM_SAMPLES_PER_PAGE,
              render: true)
        project_dir = Pathname.new(project_dir)
        report_dir = project_dir / REPORT_DIR
        samples = sample_dirs(project_dir).map do |sample_dir|
          SampleReporter
            .new(sample_dir, config, metrics_manager)
            .run
            .tap { |report| report.render(report_dir) if render }
        end
        return unless render

        Progress
          .new(project_dir, samples)
          .render(report_dir, num_samples_per_page)
      end

      private

      # @param project_dir [Pathname]
      # @return            [Array<Pathname>]
      def sample_dirs(project_dir)
        results_dir = project_dir / RESULTS_DIR
        Dir[results_dir / '*']
          .map { |e| Pathname.new(e) }
          .select(&:directory?)
      end
    end
  end
end
