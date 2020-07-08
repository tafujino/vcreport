# frozen_string_literal: true

require 'pathname'

module VCReport
  class ChrRegion
    # @return [Symbol]
    attr_reader :id

    # @return [String]
    attr_reader :desc

    # @return [Pathname]
    attr_reader :interval_list_path

    # @param id           [String, Symbol]
    # @param desc         [String]
    # @interval_list_path [String, Pathname]
    def initialize(id, desc, interval_list_path)
      @id = id.to_sym
      @desc = desc
      @interval_list_path = Pathname.new(interval_list_path)
    end
  end
end
