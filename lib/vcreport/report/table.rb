# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext/numeric/conversions'
require 'stringio'

module VCReport
  module Report
    class Table
      class FloatFormatter
        # @param fmt [String]
        def initialize(fmt)
          @fmt = fmt
        end

        # @param num [Float]
        # @return    [String]
        def run(num)
          format("%#{@fmt}f", num)
        end
      end

      # type is either :string, :varbatim, :integer, :float (FloatFormatter) or :numeric

      # @param header [Array<String>]
      # @param rows   [Array<Array>>]
      # @param type   [Array<Symbol>]
      def initialize(header, rows = [], type = [])
        @header = header
        @rows = rows
        @type = type
      end

      # @param row [Array]
      def push(*row)
        @rows << row
      end

      # @return [String, nil]
      def markdown_text
        return nil if @rows.empty?

        sio = StringIO.new
        sio.puts markdown_row_text(@header, is_header: true)
        sio.puts markdown_separator_text(@type)
        @rows.each do |row|
          sio.puts markdown_row_text(row, type: @type)
        end
        sio.string
      end

      class << self
        # @param paths   [String, Pathname, Array<String, Pathname>]
        # @param caption [String]
        # @return [Table]
        def file_table(paths, caption = 'file')
          header = [caption]
          type = %i[verbatim]
          paths = paths.is_a?(Array) ? paths : [paths]
          rows = paths.map { |path| [File.expand_path(path)] }
          Table.new(header, rows, type)
        end

        # @param  [String]
        # @return [Table]
        def program_table(program)
          header = %w[program]
          type = %i[verbatim]
          rows = [[program]]
          Table.new(header, rows, type)
        end
      end

      private

      # @param type [Array<Symbol>]
      # @return     [String]
      def markdown_separator_text(type)
        type.map do |t|
          case t
          when :string, :verbatim, nil
            ':---'
          when :integer, :float, FloatFormatter, :numeric
            '---:'
          else
            warn "Unknown type: #{t}"
            exit 1
          end
        end.then { |fields| markdown_render_fields(fields) }
      end

      # @param row       [Array]
      # @param type      [Array<Symbol>]
      # @param is_header [Boolean]
      # @return          [String]
      def markdown_row_text(row, type: [], is_header: false)
        fields = row.zip(type).map do |e, t|
          next e.to_s if is_header

          case t
          when :string, :float, :numeric, nil
            e.to_s
          when FloatFormatter
            t.run(e)
          when :verbatim
            # this does not work perfectly when the string contains backtick
            "`#{e}`"
          when :integer
            e.to_s(:delimited)
          else
            warn "Unknown type: #{t}"
            exit 1
          end
        end
        markdown_render_fields(fields)
      end

      # @param fields [Array<String>]
      # @return       [String]
      def markdown_render_fields(fields)
        ['| ', fields.join(' | '), ' |'].join
      end
    end
  end
end
