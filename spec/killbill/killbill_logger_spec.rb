require 'spec_helper'

describe Killbill::Plugin::KillbillLogger do

  it 'should support Logger APIs' do
    logger = Killbill::Plugin::KillbillLogger.new(::Logger.new(STDOUT))
    logger.fatal { "Argument 'foo' not given." }
    logger.error "Argument #{@foo} mismatch."
    logger.info('initialize') { 'Initializing...' }
    logger.add(Logger::FATAL) { 'Fatal error!' }
    logger.level = ::Logger::DEBUG
    logger.log_level.should == ::Logger::DEBUG
    logger.close
  end

  it 'only executes block when at given level' do
    logger = Killbill::Plugin::KillbillLogger.new(::Logger.new(STDOUT))
    logger.log_level = ::Logger::INFO
    logger.info { 'logging at INFO level' }
    logger.debug { raise 'logging at DEBUG level' } # should not raise
    logger.add(Logger::WARN) { 'logging at WARN level' }
    logger.add(Logger::DEBUG) { raise 'logging at DEBUG level' } # should not raise
    logger.close
  end

end
