# frozen_string_literal: true

require 'concurrent-ruby'
require 'active_support'
require 'active_support/core_ext/string/filters'
require 'pathname'
require 'open3'

module VCReport
  class MetricsManager
    # @return [Integer]
    attr_reader :num_threads

    # @param num_threads [Integer]
    def initialize(num_threads)
      @num_threads = num_threads
      @pool = Concurrent::FixedThreadPool.new(num_threads)
      # Hash{ String => Symbol }
      # The value may be :success, :fail, :unfinished
      @job_status = {}
    end

    # @param result_path [String, Pathname]
    def post(result_path)
      result_path = result_path.to_s
      case @job_status[result_path]
      when :success
        return if File.exist?(result_path)

        warn <<~MESSAGE.squish
          File does not exist but job status is 'success'.
          Something went wrong: #{result_path}
        MESSAGE
        return
      when :unfinished
        # the job is already in queue
        return
      when :fail
        warn "Restart metrics calculation: #{result_path}"
      end
      # when staus is :fail or nil
      @job_status[result_path] = :unfinished
      @job_status[result_path] = @pool.post do
        status = yield
        status ? :success : :fail
      end
    end

    class << self
      # @param command [String]
      # @return        [Boolean] true iff the command succeeded
      def shell(command)
        warn command
        value = nil
        Open3.popen3(command) do |_, o, e, w|
          o.each { |s| puts s }
          e.each { |s| warn s }
          value = w.value
        end
        value.success?
      end
    end
  end
end
