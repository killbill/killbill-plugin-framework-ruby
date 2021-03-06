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

      java_package 'org.killbill.billing.catalog.api'
      class PriceList

        include org.killbill.billing.catalog.api.PriceList

        attr_accessor :name, :pretty_name, :plans

        def initialize()
        end

        def to_java()
          # conversion for name [type = java.lang.String]
          @name = @name.to_s unless @name.nil?

          # conversion for pretty_name [type = java.lang.String]
          @pretty_name = @pretty_name.to_s unless @pretty_name.nil?

          # conversion for plans [type = java.util.Collection]
          tmp = java.util.ArrayList.new
          (@plans || []).each do |m|
            # conversion for m [type = org.killbill.billing.catalog.api.Plan]
            m = m.to_java unless m.nil?
            tmp.add(m)
          end
          @plans = tmp
          self
        end

        def to_ruby(j_obj)
          # conversion for name [type = java.lang.String]
          @name = j_obj.name

          # conversion for pretty_name [type = java.lang.String]
          @pretty_name = j_obj.pretty_name

          # conversion for plans [type = java.util.Collection]
          @plans = j_obj.plans
          tmp = []
          (@plans || []).each do |m|
            # conversion for m [type = org.killbill.billing.catalog.api.Plan]
            m = Killbill::Plugin::Model::Plan.new.to_ruby(m) unless m.nil?
            tmp << m
          end
          @plans = tmp
          self
        end

      end
    end
  end
end
