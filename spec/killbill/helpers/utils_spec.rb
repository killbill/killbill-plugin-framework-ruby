require 'spec_helper'

describe Killbill::Plugin::ActiveMerchant::Utils do

  include ::Killbill::Plugin::PropertiesHelper

  context 'UUID' do
    it 'should convert back and forth UUIDs' do
      uuid = SecureRandom.uuid
      packed = Killbill::Plugin::ActiveMerchant::Utils.compact_uuid(uuid)
      unpacked = Killbill::Plugin::ActiveMerchant::Utils.unpack_uuid(packed)
      unpacked.should == uuid
    end

    it 'should respect leading 0s' do
      uuid = '0ae18a4c-be57-44c3-84ba-a82962a2de03'
      0.upto(35) do |i|
        # Skip hyphens
        next if [8, 13, 18, 23].include?(i)
        uuid[i] = '0'
        packed = Killbill::Plugin::ActiveMerchant::Utils.compact_uuid(uuid)
        unpacked = Killbill::Plugin::ActiveMerchant::Utils.unpack_uuid(packed)
        unpacked.should == uuid
      end
    end
  end

  context 'normalization' do
    it 'normalizes true values' do
      ::Killbill::Plugin::ActiveMerchant::Utils.normalize(true).should be_true
      ::Killbill::Plugin::ActiveMerchant::Utils.normalize('true').should be_true
      ::Killbill::Plugin::ActiveMerchant::Utils.normalize('  true ').should be_true
      ::Killbill::Plugin::ActiveMerchant::Utils.normalize(:true).should be_true
      ::Killbill::Plugin::ActiveMerchant::Utils.normalize('yes').should be_true
      ::Killbill::Plugin::ActiveMerchant::Utils.normalize('yes  ').should be_true
      ::Killbill::Plugin::ActiveMerchant::Utils.normalize(:yes).should be_true
    end

    it 'normalizes false values' do
      ::Killbill::Plugin::ActiveMerchant::Utils.normalize(false).should be_false
      ::Killbill::Plugin::ActiveMerchant::Utils.normalize('  false ').should be_false
      ::Killbill::Plugin::ActiveMerchant::Utils.normalize(:false).should be_false
      ::Killbill::Plugin::ActiveMerchant::Utils.normalize('no').should be_false
      ::Killbill::Plugin::ActiveMerchant::Utils.normalize('no  ').should be_false
      ::Killbill::Plugin::ActiveMerchant::Utils.normalize(:no).should be_false
    end

    it 'understands snake case and camel case' do
      ::Killbill::Plugin::ActiveMerchant::Utils.normalized({:skip_gw => 'true'}, :skip_gw).should be_true
      ::Killbill::Plugin::ActiveMerchant::Utils.normalized({:skip_gw => 'false'}, :skip_gw).should be_false
      ::Killbill::Plugin::ActiveMerchant::Utils.normalized({:skipGw => 'true'}, :skip_gw).should be_true
      ::Killbill::Plugin::ActiveMerchant::Utils.normalized({:skipGw => 'false'}, :skip_gw).should be_false
    end

    it 'normalizes non-boolean attributes' do
      ::Killbill::Plugin::ActiveMerchant::Utils.normalized({}, :cc_first_name).should be_nil
      ::Killbill::Plugin::ActiveMerchant::Utils.normalized({:cc_first_name => ''}, :cc_first_name).should be_nil
      ::Killbill::Plugin::ActiveMerchant::Utils.normalized({:cc_first_name => 'Paul'}, :cc_first_name).should == 'Paul'
      ::Killbill::Plugin::ActiveMerchant::Utils.normalized({:ccFirstName => 'Paul'}, :cc_first_name).should == 'Paul'
    end

    it 'normalizes properties' do
      properties = []
      properties << build_property('dontTouch', 'true')
      properties << build_property(:dont_touch, false)
      properties << build_property('changeMe', 'false')
      properties << build_property('dont_touch', 'null')

      ::Killbill::Plugin::ActiveMerchant::Utils.normalize_property(properties, 'change_me')

      properties[0].key.should == 'dontTouch'
      properties[0].value.should == 'true'
      properties[1].key.should == :dont_touch
      properties[1].value.should == false
      properties[2].key.should == 'changeMe'
      properties[2].value.should == false
      properties[3].key.should == 'dont_touch'
      properties[3].value.should == 'null'
    end
  end

  context 'KBWiredumpDevice' do
    it 'should implement a wiredump device for the Kill Bill logger' do
      logger = Logger.new(STDOUT)
      logger.level = Logger::INFO

      io = ::Killbill::Plugin::ActiveMerchant::Utils::KBWiredumpDevice.new(logger)
      io.sync = true
      io.sync.should be_true
      io << 'This is an I/O test'

      jlogger = ::Killbill::Plugin::KillbillLogger.new(logger)
      jio = ::Killbill::Plugin::ActiveMerchant::Utils::KBWiredumpDevice.new(jlogger)
      jio.sync = true
      jio.sync.should be_true
      jio << 'This is an I/O test (via Java)'
    end
  end

  context 'LazyEvaluator' do
    it 'defers evaluation until called' do
      argument = {:int => 12}

      double_argument = ::Killbill::Plugin::ActiveMerchant::Utils::LazyEvaluator.new { argument[:int] *= 2 }
      argument[:int].should == 12

      double_argument.to_i.should == 24
      argument[:int].should == 24

      # The block should be invoked exactly once
      double_argument.to_i.should == 24
      argument[:int].should == 24
    end
  end

  context 'BoundedLRUCache' do
    it 'should implement a thread-safe LRU cache' do
      require 'benchmark'

      runs = 2
      cache_size = 50
      nb_threads = (ENV['NB_THREADS'] || 200).to_i
      keys_per_thread = 1000

      cache = nil
      Benchmark.bm do |x|
        runs.times do |n|
          x.report("run ##{n}:") do
            cache = ::Killbill::Plugin::ActiveMerchant::Utils::BoundedLRUCache.new(Proc.new { |value| -1 }, cache_size)

            threads = (0..nb_threads).map do |i|
              Thread.new do
                (0..keys_per_thread).each do |j|
                  key = 1001 * i + j
                  value = rand(2000)
                  cache[key] = value
                  cache[key].should satisfy { |cache_value| cache_value == -1 or cache_value == value }
                end
              end
            end

            threads.each { |thread| thread.join }
          end
        end
      end

      last_keys = cache.keys
      last_values = cache.values
      0.upto(cache_size - 1) do |i|
        # No overlap with test keys or values above
        cache[-1 * i - 1] = -2

        new_keys = cache.keys
        new_values = cache.values

        # Verify the changes we made
        0.upto(i) do |j|
          idx = cache_size - j - 1
          expected_key = -1 * (i - j) - 1
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
end
