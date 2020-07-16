# frozen_string_literal: true

require 'vcreport/settings'
require 'vcreport/config'
require 'vcreport/report/index'
require 'vcreport/report/progress'
require 'vcreport/report/sample'
require 'vcreport/report/sample_reporter'
require 'vcreport/report/dashboard'
require 'vcreport/job_manager'
require 'pathname'

module VCReport
  module Report
    class << self
      # @param project_dir [String]
      # @param config      [Config]
      # @param job_manager [JobManager, nil]
      # @param render      [Boolean]
      def run(project_dir,
              config,
              job_manager = nil,
              render: true)
        project_dir = Pathname.new(project_dir)
        report_dir = project_dir / REPORT_DIR
        samples = sample_dirs(project_dir).filter_map do |sample_dir|
          SampleReporter
            .new(sample_dir, config, job_manager)
            .try_parse
            .tap { |report| report.render(report_dir) if render }
        end
        return unless render

        progress_html_paths =
          Progress.new(project_dir, samples, config.report.num_samples_per_page)
            .render(report_dir)
        dashboard_html_path = Dashboard.new(samples, config.vcf.chr_regions)
                                .render(report_dir)
        Index.new(project_dir, progress_html_paths.first, dashboard_html_path)
             .render(report_dir)
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
