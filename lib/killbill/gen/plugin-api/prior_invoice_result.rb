#############################################################################################
#                                                                                           #
#                   Copyright 2010-2013 Ning, Inc.                                          #
#                   Copyright 2014 Groupon, Inc.                                            #
#                   Copyright 2014 The Billing Project, LLC                                 #
#                                                                                           #
#      The Billing Project licenses this file to you under the Apache License, version 2.0  #
#      (the "License"); you may not use this file except in compliance with the             #
#      License.  You may obtain a copy of the License at:                                   #
#                                                                                           #
#          http://www.apache.org/licenses/LICENSE-2.0                                       #
#                                                                                           #
#      Unless required by applicable law or agreed to in writing, software                  #
#      distributed under the License is distributed on an "AS IS" BASIS, WITHOUT            #
#      WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the            #
#      License for the specific language governing permissions and limitations              #
#      under the License.                                                                   #
#                                                                                           #
#############################################################################################


#
#                       DO NOT EDIT!!!
#    File automatically generated by killbill-java-parser (git@github.com:killbill/killbill-java-parser.git)
#


module Killbill
  module Plugin
    module Model

      java_package 'org.killbill.billing.invoice.plugin.api'
      class PriorInvoiceResult

        include org.killbill.billing.invoice.plugin.api.PriorInvoiceResult

        attr_accessor :is_aborted, :reschedule_date

        def initialize()
        end

        def to_java()
          # conversion for is_aborted [type = boolean]
          @is_aborted = @is_aborted.nil? ? java.lang.Boolean.new(false) : java.lang.Boolean.new(@is_aborted)

          # conversion for reschedule_date [type = org.joda.time.DateTime]
          if !@reschedule_date.nil?
            @reschedule_date =  (@reschedule_date.kind_of? Time) ? DateTime.parse(@reschedule_date.to_s) : @reschedule_date
            @reschedule_date = Java::org.joda.time.DateTime.new(@reschedule_date.to_s, Java::org.joda.time.DateTimeZone::UTC)
          end
          self
        end

        def to_ruby(j_obj)
          # conversion for is_aborted [type = boolean]
          @is_aborted = j_obj.is_aborted
          if @is_aborted.nil?
            @is_aborted = false
          else
            tmp_bool = (@is_aborted.java_kind_of? java.lang.Boolean) ? @is_aborted.boolean_value : @is_aborted
            @is_aborted = tmp_bool ? true : false
          end

          # conversion for reschedule_date [type = org.joda.time.DateTime]
          @reschedule_date = j_obj.reschedule_date
          if !@reschedule_date.nil?
            fmt = Java::org.joda.time.format.ISODateTimeFormat.date_time_no_millis # See https://github.com/killbill/killbill-java-parser/issues/3
            str = fmt.print(@reschedule_date)
            @reschedule_date = DateTime.iso8601(str)
          end
          self
        end

      end
    end
  end
end
