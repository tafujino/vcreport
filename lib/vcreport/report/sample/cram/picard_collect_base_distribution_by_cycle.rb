# frozen_string_literal: true

require 'pathname'

module VCReport
  module Report
    class Sample
      class Cram
        class PicardCollectBaseDistributionByCycle
          # @return [Pathname]
          attr_reader :path

          # @return [Pathname]
          attr_reader :chart_pdf_path

          # @return [Pathname]
          attr_reader :chart_png_path

          # @param path           [Pathname]
          # @param chart_pdf_path [Pathname]
          # @param chart_png_path [Pathname]
          def initialize(path, chart_pdf_path, chart_png_path)
            @path = path
            @chart_pdf_path = chart_pdf_path
            @chart_png_path = chart_png_path
          end
        end
      end
    end
  end
end
