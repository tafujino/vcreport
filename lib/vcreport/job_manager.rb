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

    # @param result_paths [Array<String, Pathname>]
    def post(*result_paths)
      result_paths = result_paths.map(&:to_s)
      return unless should_run(result_paths)

      main_result_path = result_paths.first
      @job_status[main_result_path] =
        Concurrent::Promises.future_on(@pool, main_result_path) do |path|
        say_status 'start', path, :blue
        is_success = yield
        if is_success
          say_status 'create', path, :green
        else
          say_status 'fail', path, :red
        end
        is_success
      end
    end

    def wait
      @pool.shutdown
      @pool.wait_for_termination
    end

    private

    # @param result_paths [Array<String>]
    # @return             [Boolean]
    def should_run(result_paths)
      main_result_path = result_paths.first
      if result_paths.all? { |path| File.exist?(path) }
        say_status 'skip', main_result_path, :yellow
        return false
      end
      unless @job_status.key?(main_result_path)
        say_status 'enqueue', main_result_path, :blue
        return true
      end
      future = @job_status[main_result_path]
      unless future.resolved?
        say_status 'working', main_result_path, :yellow
        return false
      end
      if @job_status.value
        warn <<~MESSAGE.squish
          File does not exist but job status is 'success'.
          Something went wrong: #{result_path}
        MESSAGE
        say_status 'enqueue', main_result_path, :blue
      else
        say_status 'requeue', main_result_path, :yellow
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
