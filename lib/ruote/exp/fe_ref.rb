#--
# Copyright (c) 2005-2011, John Mettraux, jmettraux@gmail.com
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


module Ruote::Exp

  #
  # Sometimes you don't know at 'design time', if you want to trigger a
  # participant or subprocess.
  #
  #   Ruote.process_definition do
  #     sequence do
  #       participant 'alice'
  #       ref '${solver}'
  #       participant 'charlie'
  #     end
  #   end
  #
  # In this process, solver's name could be a participant name or a subprocess
  # name.
  #
  # Subprocesses have the priority over participants.
  #
  # Note : this expression is used by the worker when substituting unknown
  # expression names with participant or subprocess refs.
  #
  class RefExpression < FlowExpression

    names :ref

    def apply

      key = (attribute(:ref) || attribute_text).to_s

      if name != 'ref'
        key = name
        tree[1]['ref'] = key
      end

      key = @context.dollar_sub.s(key, self, h.applied_workitem)
        # see test/functional/ft_62_

      key2, value = iterative_var_lookup(key)

      tree[1]['ref'] = key2 if key2
      tree[1]['original_ref'] = key if key2 != key

      unless value
        #
        # seems like it's a participant

        @h['participant'] =
          @context.plist.lookup_info(tree[1]['ref'], h.applied_workitem)

        value = key2 if ( ! @h['participant']) && (key2 != key)
      end

      new_exp_name, new_exp_class = nil

      if value.is_a?(String)

        if value.index("def consume(") && (Rufus::TreeChecker.parse(value) rescue false)
          #
          # participant code passed

          @h['participant'] = [ 'Ruote::CodeParticipant', { 'code' => value } ]
          tree[1]['ref'] = key

        elsif klass = @context.expmap.expression_class(tree[1]['ref'])
          #
          # aliased expression

          new_exp_name = value
          new_exp_class = klass
        end

      elsif value.is_a?(Hash) && value['on_workitem']
        #
        # participant 'defined' in var

        @h['participant'] = [ 'Ruote::BlockParticipant', value ]

      elsif value.is_a?(Array) && value.size == 2 && value.last.is_a?(Hash)
        #
        # participant 'registered' in var

        @h['participant'] = value
      end

      if value == nil and @h['participant'] == nil
        #
        # unknown participant or subprocess

        @h['state'] = 'failed'
        persist_or_raise

        raise("unknown participant or subprocess '#{tree[1]['ref']}'")
      end

      new_exp_name, new_exp_class = if new_exp_name
        [ new_exp_name, new_exp_class ]
      elsif @h['participant']
        [ 'participant', Ruote::Exp::ParticipantExpression ]
      else
        [ 'subprocess', Ruote::Exp::SubprocessExpression ]
      end

      tree[0] = new_exp_name
      @h['name'] = new_exp_name

      new_exp = new_exp_class.new(@context, @h)

      do_schedule_timeout(attribute(:timeout)) if new_exp_name == 'subprocess'
        #
        # since ref neutralizes consider_timeout because participant expressions
        # handle timeout by themselves, we have to force timeout consideration
        # for subprocess expressions

      #new_exp.initial_persist
        # not necessary

      new_exp.apply
    end

    def consider_timeout

      # neutralized
    end
  end
end

