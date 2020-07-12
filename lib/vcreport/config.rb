# frozen_string_literal: true

require 'vcreport/settings'
require 'vcreport/chr_region'
require 'pathname'
require 'yaml'

module VCReport
  class Config
    # @return [Pathname]
    attr_reader :ref_path

    # @return [Array<ChrRegion>]
    attr_reader :chr_regions

    # @return [Integer]
    attr_reader :num_samples_per_page

    # @param ref_path             [String, Pathname]
    # @param chr_regions          [Array<ChrRegion>]
    # @param num_samples_per_page [Integer]
    def initialize(ref_path, chr_regions, num_samples_per_page)
      @ref_path = ref_path
      @chr_regions = chr_regions
      @num_samples_per_page = num_samples_per_page
    end

    class << self
      # @param dir [String, Pathname]
      # @return    [Config]
      def load(dir)
        config_path = Pathname.new(dir) / CONFIG_FILENAME
        unless File.exist?(config_path)
          warn "config file not found: #{config_path}"
          exit 1
        end
        config = YAML.load_file(config_path)
        ref_path = config['reference']
        chr_regions = config['regions'].map do |id, val|
          desc = val['desc'] || id.to_s
          ChrRegion.new(id.to_sym, desc, val['interval_list'])
        end
        num_samples_per_page = config['num_samples_per_page'] ||
                               Report::DEFAULT_NUM_SAMPLES_PER_PAGE
        num_samples_per_page = num_samples_per_page.to_i
        Config.new(ref_path, chr_regions, num_samples_per_page)
      end
    end
  end
end
