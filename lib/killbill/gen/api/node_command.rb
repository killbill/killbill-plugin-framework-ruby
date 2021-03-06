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

      java_package 'org.killbill.billing.util.nodes'
      class NodeCommand

        include org.killbill.billing.util.nodes.NodeCommand

        attr_accessor :is_system_command_type, :node_command_type, :node_command_metadata

        def initialize()
        end

        def to_java()
          # conversion for is_system_command_type [type = boolean]
          @is_system_command_type = @is_system_command_type.nil? ? java.lang.Boolean.new(false) : java.lang.Boolean.new(@is_system_command_type)

          # conversion for node_command_type [type = java.lang.String]
          @node_command_type = @node_command_type.to_s unless @node_command_type.nil?

          # conversion for node_command_metadata [type = org.killbill.billing.util.nodes.NodeCommandMetadata]
          @node_command_metadata = @node_command_metadata.to_java unless @node_command_metadata.nil?
          self
        end

        def to_ruby(j_obj)
          # conversion for is_system_command_type [type = boolean]
          @is_system_command_type = j_obj.is_system_command_type
          if @is_system_command_type.nil?
            @is_system_command_type = false
          else
            tmp_bool = (@is_system_command_type.java_kind_of? java.lang.Boolean) ? @is_system_command_type.boolean_value : @is_system_command_type
            @is_system_command_type = tmp_bool ? true : false
          end

          # conversion for node_command_type [type = java.lang.String]
          @node_command_type = j_obj.node_command_type

          # conversion for node_command_metadata [type = org.killbill.billing.util.nodes.NodeCommandMetadata]
          @node_command_metadata = j_obj.node_command_metadata
          @node_command_metadata = Killbill::Plugin::Model::NodeCommandMetadata.new.to_ruby(@node_command_metadata) unless @node_command_metadata.nil?
          self
        end

      end
    end
  end
end
