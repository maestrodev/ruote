#--
# Copyright (c) 2005-2009, John Mettraux, jmettraux@gmail.com
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# Made in Japan.
#++

require 'ruote/exp/flowexpression'


module Ruote::Exp

  #
  # Setting a workitem field or a process variable.
  #
  #   sequence do
  #     set :field => 'subject', :value => 'food and beverage'
  #     set :field => 'date', :val => 'tomorrow'
  #     participant :ref => 'attendees'
  #   end
  #
  # :field can be abbreviated to :f or :fld. :variable can be abbreviated to
  # :v or :var. Likewise, :val and :value are interchangeable.
  #
  # == field_value, variable_value
  #
  # Usually, grabbing a value from a field or a value will look like
  #
  #   set :f => 'my_field', :value => '${v:my_variable}'
  #
  # But doing those ${} substitutions always result in a string result. What
  # if the variable or the field holds a non-string value ?
  #
  #   set :f => 'my_field', :var_value => 'my_variable'
  #
  # Is the way to go then. 'set' understands v_value, var_value, variable_value
  # and f_value, fld_value and field_value.
  #
  # == :escape
  #
  # If the value to insert contains ${} stuff but this has to be preserved,
  # setting the attribute :escape to true will do the trick.
  #
  #   set :f => 'my_field', :value => 'oh and ${whatever}', :escape => true
  #
  class SetExpression < FlowExpression

    names :set, :unset

    def apply

      opts = { :escape => attribute(:escape) }

      value = if name == 'unset'
        nil
      else
        v = lookup_val(opts)
        raise(ArgumentError.new("'set' is missing a value")) if v == nil
        v
      end

      if var_key = has_attribute(:v, :var, :variable)

        var = attribute(var_key, @applied_workitem)

        if name == 'unset'
          unset_variable(var)
        else
          set_variable(var, value)
        end

      elsif field_key = has_attribute(:f, :fld, :field)

        field = attribute(field_key, @applied_workitem)

        if name == 'unset'
          @applied_workitem.fields.delete(field)
        else
          @applied_workitem.set_field(field, value)
        end

      else

        raise ArgumentError.new(
          "missing a variable or field target in #{tree.inspect}")
      end

      reply_to_parent(@applied_workitem)
    end

    def reply (workitem)

      # never called
    end
  end
end

