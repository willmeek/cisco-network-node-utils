require 'json'
require 'date'
puts 'creating yaml file'
json = File.read('input.json')
obj = JSON.parse(json)
name = obj['Name']
dir = Dir.pwd
fname = dir + '/../lib/cisco_node_utils/cmd_ref/' + name + '.yaml'
file = File.open(fname, 'w')
file.puts '# ' + name + "\n---\n"
file.puts "_exclude: [ios_xr]\n\n"
file.puts "_template:\n\n"
file.puts "create:\n\n"
file.puts "destroy:\n"
bprops = obj['Bool_Properties']
nbprops = obj['Non_Bool_Properties']
props = []
props << bprops << nbprops
props.flatten!
bprops.each do |prop|
  file.puts "\n" + prop + ':'
  file.puts '  type: boolean'
  file.puts '  default_value: false'
end
nbprops.each do |prop|
  file.puts "\n" + prop + ':'
  file.puts 'default_value:'
end
file.close
puts 'creating ruby file'
fname = dir + '/../lib/cisco_node_utils/' + name + '.rb'
file = File.open(fname, 'w')
month = Date::MONTHNAMES[Date.today.month]
year = Date.today.year.to_s
author = obj['Author']
file.puts '#
# ' + month + ' ' + year + ', ' + author + '
#
# Copyright (c) ' + year + ' Cisco and/or its affiliates.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.'
file.puts "\nrequire_relative 'node_util'"
file.puts "\nmodule Cisco"
file.puts '  # node_utils class for ' + name
cap = name.slice(0, 1).capitalize + name.slice(1..-1)
file.puts '  class ' + cap + ' < NodeUtil'
file.puts "\n    # Helper method to delete @set_args hash keys
    def set_args_keys_default
      @get_args = @set_args
    end

    # rubocop:disable Style/AccessorMethodName
    def set_args_keys(hash={})
      set_args_keys_default
      @set_args = @get_args.merge!(hash) unless hash.empty?
    end\n"
file.puts "    def create
      config_set('" + name + "', 'create', @set_args)
    end

    def destroy
      config_set('" + name + "', 'destroy', @set_args)
    end

    ########################################################
    #                      PROPERTIES                      #
    ########################################################"
props.each do |prop|
  file.puts "\n    def " + prop
  file.puts "      config_get('" + name + "', '" + prop + "', @get_args)\n"
  file.puts '    end'
  file.puts "\n    def " + prop + '=(val)'
  file.puts "      config_set('" + name + "', '" + prop + "', @set_args)\n"
  file.puts '    end'
  file.puts "\n    def default_" + prop
  file.puts "      config_get_default('" + name + "', '" + prop + "')\n"
  file.puts '    end'
end
file.puts "  end # class
end # module"
file.close
puts 'creating test file'
fname = dir + '/../tests/test_' + name + '.rb'
file = File.open(fname, 'w')
year = Date.today.year.to_s
file.puts '# Copyright (c) ' + year + ' Cisco and/or its affiliates.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.'
file.puts "\nrequire_relative 'ciscotest'"
file.puts "require_relative '../lib/cisco_node_utils/" + name + "'"
file.puts "\n# Test" + cap + ' - Minitest for ' + cap
file.puts '# node utility class'
file.puts 'class Test' + cap + ' < CiscoTestCase'
file.puts "\n  def setup
    super
  end

  def teardown
    super
  end"
file.puts "\n  def create_" + name
file.puts "  end\n"
props.each do |prop|
  file.puts "\n  def test_" + prop
  file.puts '    obj = create_' + name
  file.puts '    assert_equal(obj.default_' + prop + ', obj.' + prop + ')'
  file.puts '    obj.' + prop + ' = __put_set_value_here__'
  file.puts '    assert_equal(__put_set_value_here__, obj.' + prop + ')'
  file.puts '    obj.' + prop + ' = obj.default_' + prop
  file.puts '    assert_equal(obj.default_' + prop + ', obj.' + prop + ')'
  file.puts '  end'
end
file.puts 'end'
file.close
