require 'spec_helper'

describe Killbill::Plugin::KillbillLogger do

  it 'should support Logger APIs' do
    logger = Killbill::Plugin::KillbillLogger.new(::Logger.new(STDOUT))
    logger.fatal { "Argument 'foo' not given." }
    logger.error "Argument #{@foo} mismatch."
    logger.info('initialize') { 'Initializing...' }
    logger.add(Logger::FATAL) { 'Fatal error!' }
    logger.close
  end
end
