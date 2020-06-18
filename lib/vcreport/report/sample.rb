# frozen_string_literal: true

require 'vcreport/scan'
require 'vcreport/report/vcf'
require 'vcreport/report/render'
require 'vcreport/metrics/vcf'
require 'fileutils'
require 'pathname'

module VCReport
  module Report
    class Sample
      PREFIX = 'report'

      include Render

      # @return [String] sample name
      attr_reader :name

      # @return [Time, nil] workflow end time
      attr_reader :end_time

      # @return [Array<Report::Vcf>]
      attr_reader :vcf_reports

      # @param name        [String]
      # @param end_time    [Time, nil]
      # @param vcf_reports [Array<Report::Vcf>]
      def initialize(name, end_time = nil, vcf_reports = [])
        @name = name
        @end_time = end_time
        @vcf_reports = vcf_reports
      end

      # @param report_dir       [String]
      # @param should_overwrite [Boolean]
      def render(report_dir, should_overwrite = true)
        report_dir = Pathname.new(report_dir)
        out_dir = report_dir / @name
        FileUtils.mkpath out_dir unless File.exist?(out_dir)
        render_markdown(PREFIX, out_dir, should_overwrite)
        render_html(PREFIX, out_dir, should_overwrite)
      end

      class << self
        # @param sample_dir [Pathname]
        def run(sample_dir)
          name = sample_dir.basename.to_s
          warn "Sample: #{name}"
          warn "Directory: #{sample_dir}"
          finish_path = (sample_dir / 'finish')
          return Report::Sample.new(name) unless finish_path.exist?

          end_time = File::Stat.new(finish_path).mtime
          metrics_dir = sample_dir / 'metrics'
          vcf_reports = vcf_paths(sample_dir).map do |vcf_path|
            Report::Vcf.run(vcf_path, chr_region, metrics_dir)
          end.compact
          Report::Sample.new(name, end_time, vcf_reports)
        end

        private

        # @param dir [Pathname]
        def vcf_paths(sample_dir)
          CHR_REGIONS.map do |chr_region|
            sample_name = sample_dir.basename
            # VCF is supposed to be gzipped
            sample_dir / "#{sample_name}.#{chr_region}.g.vcf.gz"
          end
        end
      end
    end
  end
end
