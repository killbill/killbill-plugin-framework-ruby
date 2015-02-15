require 'thread_safe'

module Killbill
  module Plugin
    module ActiveMerchant
      class Utils
        # Use base 62 to be safe
        BASE62 = ('0'..'9').to_a + ('A'..'Z').to_a + ('a'..'z').to_a

        def self.compact_uuid(uuid)
          uuid = uuid.gsub(/-/, '')
          uuid.hex.base(62).map { |i| BASE62[i].chr } * ''
        end

        def self.unpack_uuid(base62_uuid)
          as_hex     = base62_uuid.split(//).inject(0) { |i, e| i*62 + BASE62.index(e[0]) }
          no_hyphens = "%x" % as_hex
          no_hyphens = '0' * (32 - no_hyphens.size) + no_hyphens
          no_hyphens.insert(8, "-").insert(13, "-").insert(18, "-").insert(23, "-")
        end

        def self.ip
          first_public_ipv4 ? first_public_ipv4.ip_address : first_private_ipv4.ip_address
        end

        def self.first_private_ipv4
          Socket.ip_address_list.detect { |intf| intf.ipv4_private? }
        end

        def self.first_public_ipv4
          Socket.ip_address_list.detect { |intf| intf.ipv4? and !intf.ipv4_loopback? and !intf.ipv4_multicast? and !intf.ipv4_private? }
        end

        class KBWiredumpDevice < IO

          # Required for compatibility, but unused
          attr_accessor :sync

          def initialize(logger, method = :info)
            @logger = logger
            @method = method
          end

          # We mostly care about the << method
          def write(string)
            sanitized_string = string.to_s.chomp("\n")
            @logger.send(@method, sanitized_string) if sanitized_string.size > 0
          end
        end

        class BoundedLRUCache
          include ThreadSafe::Util::CheapLockable

          def initialize(proc, max_size = 10000)
            @max_size = max_size
            @data = ThreadSafe::Cache.new do |hash, key|
              # mapping key -> value is constant for our purposes
              set_value = hash.fetch_or_store key, value = proc.call(key)
              store_key(key) if value.equal?(set_value) # very same object
              set_value
            end
            @keys = []
          end

          def [](key); @data[key] end

          def []=(key, val)
            prev_val = @data.get_and_set(key, val)
            prev_val.nil? ? store_key(key) : update_key(key)
            val
          end

          # @private for testing
          def size; @data.size end

          # @private for testing
          def keys
            cheap_synchronize { @keys.dup }
          end

          # @private for testing
          def values
            cheap_synchronize { @keys.map { |key| self[key] } }
          end

          protected

          def store_key(key)
            cheap_synchronize do
              @keys << key
              remove_eldest_key_if_full
            end
          end

          def update_key(key)
            cheap_synchronize do
              @keys.delete(key); @keys << key
              remove_eldest_key_if_full
            end
          end

          private

          def remove_eldest_key_if_full
            @data.delete @keys.shift if @data.size > @max_size
          end

        end

      end
    end
  end
end

