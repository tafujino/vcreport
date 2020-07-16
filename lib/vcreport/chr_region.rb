# frozen_string_literal: true

require 'pathname'

module VCReport
  class ChrRegion
    # @return [Symbol]
    attr_reader :id

    # @return [String]
    attr_reader :desc

    # @return [Pathname, nil]
    attr_reader :interval_list_path

    # @param id                 [String, Symbol]
    # @param desc               [String]
    # @param interval_list_path [String, Pathname, nil]
    def initialize(id, desc = nil, interval_list_path = nil)
      @id = id.to_sym
      @desc = desc || @id.to_s
      return unless interval_list_path

      @interval_list_path = Pathname.new(interval_list_path)
    end
  end
end
