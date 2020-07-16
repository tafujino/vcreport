# frozen_string_literal: true

require 'pathname'

module VCReport
  class Reference
    # @return [String]
    attr_reader :desc

    # @return [Pathname]
    attr_reader :path

    # @param desc [String]
    # @param path [String, Pathname]
    def initialize(desc, path)
      desc || raise(ArgumentError, 'reference description is missing')
      @desc = desc
      path || raise(ArgumentError, 'reference path is missing')
      @path = path
    end
  end
end
