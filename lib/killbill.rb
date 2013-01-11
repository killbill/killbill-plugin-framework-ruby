begin
  require 'java'
rescue LoadError
  warn "Except maybe for testing, you need JRuby to run Killbill plugins"
end

require 'killbill/notification'
require 'killbill/payment'
