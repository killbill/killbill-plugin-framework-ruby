module Killbill
  module Plugin
    module ActiveMerchant
      module ActiveRecordHelper

        def close_connection(logger = nil)
          pool = ::ActiveRecord::Base.connection_pool
          logger.debug { "after_request: pool.active_connection? = #{pool.active_connection?}, pool.connections.size = #{pool.connections.size}, connections = #{pool.connections.inspect}" } if logger
          ::ActiveRecord::Base.connection.close if pool.active_connection? # check-in to pool
        end
      end
    end
  end
end
