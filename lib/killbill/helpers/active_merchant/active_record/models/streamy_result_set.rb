module Killbill
  module Plugin
    module ActiveMerchant
      module ActiveRecord
        require 'active_record'

        # Closest from a streaming API as we can get with ActiveRecord
        class StreamyResultSet
          include Enumerable

          def initialize(limit, batch_size = 100, &delegate)
            @limit = limit
            @batch = [batch_size, limit].min
            @delegate = delegate
          end

          def each(&block)
            (0..(@limit - @batch)).step(@batch) do |i|
              result = @delegate.call(i, @batch)
              block.call(result)
              # Optimization: bail out if no more results
              break if result.nil? || result.empty?
            end if @batch > 0
          ensure
            # Make sure to return DB connections to the Pool
            close_connection
          end

          def to_a
            super.to_a.flatten
          end

          private

          def close_connection
            pool = ::ActiveRecord::Base.connection_pool
            return unless pool.active_connection?

            ::ActiveRecord::Base.connection.close # check-in to pool
          end
        end
      end
    end
  end
end
