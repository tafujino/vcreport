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

    # @param ref_path    [String, Pathname]
    # @param chr_regions [Array<ChrRegion>]
    def initialize(ref_path, chr_regions)
      @ref_path = ref_path
      @chr_regions = chr_regions
    end

    class << self
      # @param dir [String, Pathname]
      # @return    [Config]
      def load(dir)
        config_path = dir / CONFIG_PATH
        config = YAML.load_file(config_path)
        ref_path = config['reference']
        chr_regions = config['regions'].map do |id, val|
          ChrRegion.new(id.to_sym, val['desc'], val['interval_list'])
        end
        Config.new(ref_path, chr_regions)
      end
    end
  end
end
