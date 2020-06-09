# frozen_string_literal: true

require 'vcreport/vcf_report'
require 'vcreport/chr_regions'
require 'vcreport/render'
require 'fileutils'
require 'pathname'

module VCReport
  class SampleReport
    PREFIX = 'report'

    include Render

    # @return [String] sample name
    attr_reader :name

    # @return [Time, nil] workflow end time
    attr_reader :end_time

    # @return [Array<VCFReport>]
    attr_reader :vcf_reports

    # @param name        [String]
    # @param end_time    [Time, nil]
    # @param vcf_reports [Array<VCFReport>]
    def initialize(name, end_time = nil, vcf_reports = [])
      @name = name
      @end_time = end_time
      @vcf_reports = vcf_reports
    end

    # @param report_dir       [String]
    # @param should_overwrite [Boolean]
    def render(report_dir, should_overwrite = false)
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
        warn "sample: #{name}"
        warn "directory: #{sample_dir}"
        finish_path = (sample_dir / 'finish')
        return SampleReport.new(name) unless finish_path.exist?

        end_time = File::Stat.new(finish_path).mtime
        metrics_dir = sample_dir / 'metrics'
        vcf_reports = CHR_REGIONS.map do |chr_region|
          # VCF is supposed to be gzipped
          vcf_path = sample_dir / "#{name}.#{chr_region}.g.vcf.gz"
          VcfReport.run(vcf_path, metrics_dir)
        end.compact
        SampleReport.new(name, end_time, vcf_reports)
      end
    end
  end
end
