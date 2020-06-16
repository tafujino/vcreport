# frozen_string_literal: true

require 'vcreport/settings'
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
    end
  end
end
