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

        # Relies on the fact that hashes enumerate their values in the order that the corresponding keys were inserted (Ruby 1.9+)
        class BoundedLRUCache

          def initialize(proc, max_size=10000)
            @proc     = proc
            @max_size = max_size

            if defined?(JRUBY_VERSION)
              @is_jruby  = true
              @semaphore = nil

              lru_cache = Class.new(java.util.LinkedHashMap) do
                def initialize(max_size)
                  super(max_size, 1.0, true)
                  @max_size = max_size
                end

                # Note: renaming it to remove_eldest_entry won't work
                def removeEldestEntry(eldest)
                  size > @max_size
                end
              end.new(@max_size)
              @data     = java.util.Collections.synchronizedMap(lru_cache)
            else
              @is_jruby  = false
              @semaphore = Mutex.new
              # TODO Pre-allocate?
              @data      = {}
            end
          end

          def [](key)
            @is_jruby ? jruby_get(key) : ruby_get(key)
          end

          def []=(key, val)
            @is_jruby ? jruby_set(key, val) : ruby_set(key, val)
          end

          # For testing

          def size
            @data.size
          end

          def keys_to_a
            @is_jruby ? @data.key_set.to_a : @data.keys
          end

          def values_to_a
            @is_jruby ? @data.values.to_a : @data.values
          end

          private

          def jruby_get(key)
            value = @data.get(key)
            if value.nil?
              value = @proc.call(key)
              # Somebody may have beaten us to it but the mapping key -> value is constant for our purposes
              jruby_set(key, value)
            end
            value
          end

          def jruby_set(key, val)
            @data.put(key, val)
          end

          def ruby_get(key)
            @semaphore.synchronize do
              found = true
              value = @data.delete(key) { found = false }
              if found
                @data[key] = value
              else
                value      = @proc.call(key)
                @data[key] = value
                value
              end
            end
          end

          def ruby_set(key, val)
            @semaphore.synchronize do
              @data.delete(key)
              @data[key] = val
              if @data.length > @max_size
                @data.delete(@data.first[0])
              end
              val
            end
          end
        end
      end
    end
  end
end

