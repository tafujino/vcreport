# frozen_string_literal: true

module VCReport
  module Report
    class Paging
      # @return [Integer]
      attr_reader :current_page

      # @return [Integer]
      attr_reader :total_page

      # @return [Integer]
      attr_reader :num_digits

      # @return [String]
      attr_reader :digits

      # @param current_page [Integer]
      # @param total_page   [Integer]
      # @param num_digits   [Integer]
      def initialize(current_page, total_page, num_digits = nil)
        @current_page = current_page
        @total_page = total_page
        @num_digits = num_digits || @total_page.digits.length
        @digits = format("%0#{@num_digits}d", @current_page)
      end

      # @return [Paging]
      def prev
        return nil unless @current_page > 1

        Paging.new(@current_page - 1, @total_page)
      end

      # @return [Paging]
      def next
        return nil unless @current_page < @total_page

        Paging.new(@current_page + 1, @total_page)
      end
    end
  end
end
