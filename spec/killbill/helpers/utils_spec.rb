require 'spec_helper'

describe Killbill::Plugin::ActiveMerchant::Utils do
  it 'should convert back and forth UUIDs' do
    uuid     = SecureRandom.uuid
    packed   = Killbill::Plugin::ActiveMerchant::Utils.compact_uuid(uuid)
    unpacked = Killbill::Plugin::ActiveMerchant::Utils.unpack_uuid(packed)
    unpacked.should == uuid
  end

  it 'should respect leading 0s' do
    uuid = '0ae18a4c-be57-44c3-84ba-a82962a2de03'
    0.upto(35) do |i|
      # Skip hyphens
      next if [8, 13, 18, 23].include?(i)
      uuid[i]  = '0'
      packed   = Killbill::Plugin::ActiveMerchant::Utils.compact_uuid(uuid)
      unpacked = Killbill::Plugin::ActiveMerchant::Utils.unpack_uuid(packed)
      unpacked.should == uuid
    end
  end

  it 'should implement a wiredump device for the Kill Bill logger' do
    logger       = Logger.new(STDOUT)
    logger.level = Logger::INFO

    io      = ::Killbill::Plugin::ActiveMerchant::Utils::KBWiredumpDevice.new(logger)
    io.sync = true
    io.sync.should be_true
    io << 'This is an I/O test'

    jlogger  = ::Killbill::Plugin::KillbillLogger.new(logger)
    jio      = ::Killbill::Plugin::ActiveMerchant::Utils::KBWiredumpDevice.new(jlogger)
    jio.sync = true
    jio.sync.should be_true
    jio << 'This is an I/O test (via Java)'
  end

  it 'should implement a thread-safe LRU cache' do
    require 'benchmark'

    runs            = 2
    cache_size      = 50
    nb_threads      = 200
    keys_per_thread = 1000

    cache = nil
    Benchmark.bm do |x|
      runs.times do |n|
        x.report("run ##{n}:") do
          cache = ::Killbill::Plugin::ActiveMerchant::Utils::BoundedLRUCache.new(Proc.new { |value| -1 }, cache_size)

          threads = (0..nb_threads).map do |i|
            Thread.new do
              (0..keys_per_thread).each do |j|
                key        = 1001 * i + j
                value      = rand(2000)
                cache[key] = value
                cache[key].should satisfy { |cache_value| cache_value == -1 or cache_value == value }
              end
            end
          end

          threads.each { |thread| thread.join }
        end
      end
    end

    last_keys   = cache.keys
    last_values = cache.values
    0.upto(cache_size - 1) do |i|
      # No overlap with test keys or values above
      cache[-1 * i - 1] = -2

      new_keys   = cache.keys
      new_values = cache.values

      # Verify the changes we made
      0.upto(i) do |j|
        idx            = cache_size - j - 1
        expected_key   = -1 * (i - j) - 1
        expected_value = -2

        new_keys[idx].should eq(expected_key), "i=#{i}, j=#{j}, idx=#{idx}, expected_key=#{expected_key}, new_keys=#{new_keys.inspect}, last_keys=#{last_keys}"
        new_values[idx].should eq(expected_value), "i=#{i}, j=#{j}, idx=#{idx}, expected_value=#{expected_value}, new_values=#{new_values.inspect}, last_values=#{last_values.inspect}"
      end

      # Check we didn't override older entries
      new_keys.slice(0, cache_size - i - 1).should eq(last_keys.slice(i + 1, cache_size)), "i=#{i}, new_keys=#{new_keys.inspect}, last_keys=#{last_keys.inspect}"
      new_values.slice(0, cache_size - i - 1).should eq(last_values.slice(i + 1, cache_size)), "i=#{i}, new_values=#{new_values.inspect}, last_values=#{last_values.inspect}"

      # Check there is no change in cache size
      cache.size.should == cache_size
    end
  end
end
