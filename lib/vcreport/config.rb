# frozen_string_literal: true

require 'vcreport/settings'
require 'vcreport/chr_region'
require 'vcreport/reference'
require 'pathname'
require 'yaml'

module VCReport
  class Config
    class VcfConfig
      # @return [Array<ChrRegion>]
      attr_reader :chr_regions

      # @param chr_regions [Array<ChrRegion>]
      def initialize(chr_regions)
        @chr_regions = chr_regions
      end
    end

    class ReportConfig
      # @return [Integer]
      attr_reader :num_samples_per_page

      # @param num_samples_per_page [Integer, nil]
      def initialize(num_samples_per_page)
        @num_samples_per_page =
          num_samples_per_page || Report::DEFAULT_NUM_SAMPLES_PER_PAGE
      end
    end

    class MetricsConfig
      class PicardCollectWgsMetricsConfig
        # @return [Array<ChrRegion>]
        attr_reader :intervals

        def initialize(intervals)
          @intervals = intervals || []
        end
      end

      # @return [PicardCollectWgsMetricsConfig, nil]
      attr_reader :picard_collect_wgs_metrics

      def initialize(picard_collect_wgs_metrics)
        @picard_collect_wgs_metrics = picard_collect_wgs_metrics
      end
    end

    # @return [Reference, nil]
    attr_reader :reference

    # @return [VcfConfig, nil]
    attr_reader :vcf

    # @return [ReportConfig, nil]
    attr_reader :report

    # @return [MetricsConfig, nil]
    attr_reader :metrics

    def initialize(reference, vcf, report, metrics)
      @reference = reference
      @vcf = vcf
      @report = report
      @metrics = metrics
    end

    class << self
      # @param dir [String, Pathname]
      def load(dir)
        Parse.new(dir).run
      end
    end

    class Parse
      # @param dir [String, Pathname]
      def initialize(dir)
        @config_path = Pathname.new(dir) / CONFIG_FILENAME
      end

      # @return [Config]
      def run
        params = load_params
        reference = parse_reference_config(params)
        vcf = parse_vcf_config(params)
        report = parse_report_config(params)
        metrics = parse_metrics_config(params)
        Config.new(reference, vcf, report, metrics)
      end

      private

      # @return [Hash]
      def load_params
        unless File.exist?(@config_path)
          warn "config file not found: #{@config_path}"
          exit 1
        end
        YAML.load_file(@config_path)
      end

      # @param params [Hash, nil]
      # @return       [Reference, nil]
      def parse_reference_config(params)
        return nil unless params.key?('reference')

        h = params['reference']
        Reference.new(h['desc'], h['path'])
      end

      # @param params [Hash, nil]
      # @return       [VcfConfig]
      def parse_vcf_config(params)
        unless params['vcf']
          warn "'vcf' field is missing: #{@config_path}"
          exit 1
        end

        h = params['vcf']
        if !h['regions'] || h['regions'].empty?
          warn "'vcf/regions' field is missing: #{@config_path}"
          exit 1
        end
        chr_regions = h['regions'].map do |id, val|
          desc = val ? val['desc'] : nil
          ChrRegion.new(id, desc)
        end
        VcfConfig.new(chr_regions)
      end

      # @param params [Hash, nil]
      # @return       [ReportConfig, nil]
      def parse_report_config(params)
        num_samples_per_page = params['report']&.then do |h|
          h['samples_per_page']&.to_i
        end
        ReportConfig.new(num_samples_per_page)
      end

      # @param params [Hash, nil]
      # @return       [MetricsConfig, nil]
      def parse_metrics_config(params)
        unless params.key?('metrics')
          warn "'metrics' field is missing: #{@config_path}"
          exit 1
        end

        picard_collect_wgs_metrics_config =
          parse_picard_collect_wgs_metrics_config(params['metrics'])
        MetricsConfig.new(picard_collect_wgs_metrics_config)
      end

      # @param params [Hash, nil]
      # @return       [MetricsConfig::PicardCollectWgsMetricsConfig, nil]
      def parse_picard_collect_wgs_metrics_config(params)
        key = 'picard-CollectWgsMetrics'
        if !params[key] || params[key].empty?
          warn "'metrics/#{key}' field is missing: #{@config_path}"
          exit 1
        end

        h = params[key]['interval-list']
        if !h || h.empty?
          warn "'metrics/#{key}/interval-list' field is missing: #{@config_path}"
          exit 1
        end

        chr_regions = h.map do |id, val|
          unless val && val['path']
            warn "'metrics/#{key}/#{id}/path' is missing: #{@config_path}"
            exit 1
          end
          ChrRegion.new(id, val['desc'], val['path'])
        end
        MetricsConfig::PicardCollectWgsMetricsConfig.new(chr_regions)
      end
    end
  end
end
