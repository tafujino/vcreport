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
        Config.new(ref_path, chr_regions)
      end
    end
  end
end
