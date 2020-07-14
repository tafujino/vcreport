# frozen_string_literal: true

require 'vcreport/settings'
require 'singleton'
require 'mono_logger'
require 'pathname'
require 'fileutils'

module VCReport
  class System
    include Singleton

    # @return [Boolean]
    attr_accessor :monitor

    # @return [MonoLogger, nil]
    attr_reader :monitor_logger

    # @return [Pathname]
    attr_reader :dir

    # @param dir [String, Pathname]
    def dir=(dir)
      if @dir
        warn "Directoy can be assigned only once: #{dir}"
        exit 1
      end
      @dir = Pathname.new(dir)
      log_path = @dir / MONITOR_LOG_FILENAME
      FileUtils.mkpath(log_path.dirname) unless log_path.dirname.exist?
      @monitor_logger = MonoLogger.new(log_path)
    end

    private

    def initialize
      @monitor = false
      trap(:TERM) do
        @monitor_logger&.info 'End monitoring.'
        exit 0
      end
    end
  end
end
