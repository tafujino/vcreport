# frozen_string_literal: true

require 'vcreport/settings'
require 'vcreport/chr_regions'
require 'pathname'

module VCReport
  module Scan
    class << self
      # @param dir [Pathname]
      # @return    [Array<Pathname>]
      def sample_dirs(dir)
        results_dir = dir / RESULTS_DIR
        Dir[results_dir / '*']
          .map { |e| Pathname.new(e) }
          .select(&:directory?)
      end

      # @param dir [Pathname]
      def vcf_paths(sample_dir)
        CHR_REGIONS.map do |chr_region|
          # VCF is supposed to be gzipped
          sample_dir / "#{name}.#{chr_region}.g.vcf.gz"
        end
      end
    end
  end
end
