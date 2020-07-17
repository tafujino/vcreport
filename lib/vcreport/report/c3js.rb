# frozen_string_literal: true

require 'json'

module VCReport
  module Report
    module C3js
      class Column
        # @return [Symbol]
        attr_reader :id

        # @return [String]
        attr_reader :label

        # @return [Boolean]
        attr_reader :is_categorical

        # @param id             [Symbol]
        # @param label          [String]
        # @param is_categorical [Boolean]
        def initialize(id, label, is_categorical = false)
          @id = id
          @label = label
          @is_categorical = is_categorical
        end
      end

      class Data
        # @return [Array<Hash>]
        attr_reader :entries

        # @param entries [Array<Hash>]
        def initialize(entries)
          @entries = entries
        end

        # @param key_and_value [Hash{ Symbol => Object }]
        # @return              [Data]
        def select(**key_and_value)
          entries = @entries.filter_map do |e|
            next nil unless key_and_value.all? { |k, v| e[k] == v }

            e
          end
          Data.new(entries)
        end

        # @param cols [Array<Column>]
        # @return     [Array<Array>>]
        def rows(*cols)
          @entries.inject([cols.map(&:label)]) do |a, e|
            a << e.values_at(*cols.map(&:id))
          end
        end

        # @param cols                [Array<Column>]
        # @param x                   [C3js::Column]
        # @param bindto              [String]
        # @param x_axis_label_height [Integer]
        # @return                    [String]
        def bar_chart_json(*cols, x:, bindto:, x_axis_label_height:)
          row_data = rows(*cols)
          chart = {
            bindto: "##{bindto}",
            data: { x: x.label, rows: row_data, type: 'bar' },
            axis: { x: { type: 'category',
                         tick: { rotate: 90, multiline: false },
                         height: x_axis_label_height } },
            zoom: { enabled: true },
            legend: { show: false }
          }
          chart.deep_stringify_keys!
          JSON.generate(chart)
        end

        # @param cols                [Array<Column>]
        # @param x                   [C3js::Column]
        # @param bindto              [String]
        # @param x_axis_label_height [Integer]
        # @return                    [String]
        def bar_chart_html(*cols, x:, bindto:, x_axis_label_height:)
          json = bar_chart_json(
            *cols, x: x, bindto: bindto, x_axis_label_height: x_axis_label_height
          )
          <<~HTML
            <div id = "#{bindto}"></div>
            <script>c3.generate(#{json})</script>
          HTML
        end
      end
    end
  end
end
