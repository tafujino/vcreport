# frozen_string_literal: true

require 'vcreport/settings'
require 'concurrent-ruby'
require 'active_support'
require 'active_support/core_ext/string/filters'
require 'pathname'
require 'posix/spawn'
require 'thor'
require 'English'

module VCReport
  class JobManager
    include Thor::Shell

    # @return [Integer]
    attr_reader :num_threads

    # @param num_threads [Integer]
    def initialize(num_threads)
      @num_threads = num_threads
      @pool = Concurrent::FixedThreadPool.new(num_threads)
      @job_status = {} # Hash{ String => Concurrent::Promises::Future }
    end

    # @param result_path [String, Pathname]
    def post(result_path)
      result_path = result_path.to_s
      return unless should_run(result_path)

      @job_status[result_path] = Concurrent::Promises.future_on(@pool) do
        is_success = yield
        if is_success
          say_status 'create', result_path, :green
        else
          say_status 'fail', result_path, :red
        end
        is_success
      end
    end

    def wait
      @pool.shutdown
      @pool.wait_for_termination
    end

    private

    # @param result_path [String]
    # @return            [Boolean]
    def should_run(result_path)
      if File.exist?(result_path)
        say_status 'skip', result_path, :yellow
        return false
      end
      return true unless @job_status.key?(result_path)

      future = @job_status[result_path]
      unless future.resolved?
        say_status 'working', result_path, :yellow
        return false
      end
      if @job_status.value
        warn <<~MESSAGE.squish
          File does not exist but job status is 'success'.
          Something went wrong: #{result_path}
        MESSAGE
        say_status 'start', result_path, :blue
      else
        say_status 'restart', result_path, :blue
      end
      true
    end

    class << self
      # @param command [String]
      # @return        [Boolean] true iff the command succeeded
      def shell(command)
        pid = POSIX::Spawn.spawn(command)
        Process.waitpid(pid)
        $CHILD_STATUS.success?
      end
    end
  end
end
