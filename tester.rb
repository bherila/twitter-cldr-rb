require 'twitter_cldr'
require 'pry-byebug'

class BaseVisitor
  include TwitterCldr::Shared
  include TwitterCldr::Parsers

  attr_reader :root

  def initialize(root)
    @root = root
  end

  def start
    visit(root)
  end

  def visit_children(node)
    return [] unless node.respond_to?(:elements)
    node.elements.map { |child| visit(child) }
  end

  def visit(node)
    case node
      when UnicodeRegex
        visit_regex(node)
      when UnicodeRegexParser::Alternation
        visit_alternation(node)
      when UnicodeRegexParser::CharacterClass
        visit_character_class(node)
      when UnicodeRegexParser::CharacterRange
        visit_character_range(node)
      when UnicodeRegexParser::CharacterSet
        visit_character_set(node)
      when UnicodeRegexParser::Group
        visit_group(node)
      when UnicodeRegexParser::UnicodeString
        visit_unicode_string(node)
    end
  end

  alias_method :visit_regex, :visit_children
  alias_method :visit_alternation, :visit_children
  alias_method :visit_character_class, :visit_children
  alias_method :visit_character_range, :visit_children
  alias_method :visit_character_set, :visit_children
  alias_method :visit_group, :visit_children
  alias_method :visit_unicode_string, :visit_children
end

class Table
  attr_reader :table, :exit_state

  def initialize(table, exit_state)
    @table = table
    @exit_state = exit_state
  end

  def inspect
    table.inspect
  end

  def [](state)
    table[state]
  end

  def each_transition
    return to_enum(__method__) unless block_given?

    table.each_pair do |state, transitions|
      transitions.each_pair do |cp, next_state|
        yield state, cp, next_state
      end
    end
  end

  def shift_by(offset)
    new_exit_state = 0

    result = each_transition.with_object(blank_table) do |(state, cp, next_state), ret|
      new_state = state + offset
      ret[new_state][cp] = next_state + offset
      new_exit_state = ret[new_state][cp] if ret[new_state][cp] > new_exit_state
    end

    self.class.new(result, new_exit_state)
  end

  def merge(other)
    result = other.shift_by(exit_state)
    Table.new(table.merge(result.table), result.exit_state)
  end

  def rewrite_next_states
    new_exit_state = 0

    result = each_transition.with_object(blank_table) do |(state, cp, next_state), ret|
      ret[state][cp] = yield next_state
      new_exit_state = ret[state][cp] if ret[state][cp] > new_exit_state
    end

    self.class.new(result, new_exit_state)
  end

  private

  def blank_table
    Hash.new { |h, k| h[k] = {} }
  end
end

class Visitor < BaseVisitor
  def visit_regex(node)
    collapse(visit_children(node))
  end

  def visit_character_class(node)
    visit_set(node)
  end

  def visit_character_range(node)
    visit_set(node)
  end

  def visit_character_set(node)
    visit_set(node)
  end

  def visit_set(node)
    # enter the next state when character is recognized
    table = node.to_set.each_with_object(blank_table) do |cp, table|
      table[0][cp] = 1
    end

    # if node.quantifier.min == 0
    #   # if we don't enter, skip to next state
    #   table[current_state][:else] = next_state
    # else
    #   # min must be 1; if we don't enter, return to start
    #   table[current_state][:else] = :start
    # end

    # if node.quantifier.max == Float::INFINITY
    #   # make sure we can stay in this state indefinitely
    #   node.to_set.each do |cp|
    #     table[next_state][cp] = next_state
    #   end

    #   # make sure any non-matching char breaks us out
    #   table[next_state][:else] = next_next_state

    #   # skip over the "inner" state entirely if min is zero (overrides first if statement)
    #   table[current_state][:else] = next_next_state if node.quantifier.min == 0
    #   exit_state = next_next_state
    # # else
    #   # max must be 1, which is handled by entering the
    #   # next state, i.e. the loop statement at the beginning
    #   # of the method
    # end

    quantify(Table.new(table, 1), node.quantifier)
  end

  def quantify(table, quantifier)
    if quantifier.min == 0
      # if we don't enter, skip to next state
      table[0][:else] = table.exit_state
    end

    if quantifier.max == Float::INFINITY
      table[0].each do |cp, _|
        table[table.exit_state][cp] = table.exit_state
      end

      new_exit_state = table.exit_state + 1
      table[table.exit_state][:else] = new_exit_state
      table[0][:else] = new_exit_state if quantifier.min == 0
    end

    table
  end

  def visit_alternation(node)
    alternates = node.elements.map do |alt_group|
      collapse(alt_group.map { |alt_elem| visit(alt_elem) })
    end

    exit_states = Set.new

    alternates = collapse(alternates) do |first, second|
      new_second = second.shift_by(first.exit_state)
      exit_states << first.exit_state
      exit_states << new_second.exit_state
      result = { 0 => first.table[0].merge(new_second.table[first.exit_state]) }
      (first.table.keys - [0]).each { |k| result[k] = first.table[k] }
      new_second.table.delete(first.exit_state)
      result.merge!(new_second.table)
      Table.new(result, new_second.exit_state)
    end

    max_exit_state = exit_states.max

    alternates = alternates.rewrite_next_states do |next_state|
      next max_exit_state if exit_states.include?(next_state)
      next_state
    end

    Table.new(alternates.table, max_exit_state)
  end

  def visit_group(node)
    quantify(super.first, node.quantifier)
  end

  def visit_unicode_string(node)
    codepoints = node.to_set.to_full_a
    table = blank_table
    exit_state = 0

    node.to_set.each_with_index do |cp, idx|
      table[idx][cp] = idx + 1
      exit_state = idx + 1
    end

    quantify(Table.new(table, exit_state), node.quantifier)
  end

  private

  def collapse(tables)
    return tables.first if tables.size <= 1

    tables[1..-1].inject(tables.first) do |ret, table|
      if block_given?
        yield ret, table
      else
        ret.merge(table)
      end
    end
  end

  # def flatten(tables, &block)
  #   return tables if tables.is_a?(Table)
  #   flat = tables.is_a?(Array) ? tables.map { |tb| flatten(tb, &block) } : tables
  #   return flat.first if flat.size <= 1
  #   result = yield(flat[0], flat[1])
  #   2.upto(flat.size - 1) { |i| result = yield(result, flat[i]) }
  #   result
  # end

  def blank_table
    Hash.new { |h, k| h[k] = {} }
  end
end

def to_state_table(re)
  regex = TwitterCldr::Shared::UnicodeRegex.compile(re)
  v = Visitor.new(regex)
  v.start
end

# p to_state_table('a|b+')
# p to_state_table('a|bc|def')
# p to_state_table('[abc]+')
# p to_state_table('(a|[bcd])+')
# p to_state_table('[a-c]')

class State
  attr_reader :state_table, :current_state

  EMPTY_TRANSITION = {}.freeze

  def initialize(state_table)
    @state_table = state_table
    state_table.table.default = nil
    reset
  end

  def accept(cp)
    @current_state = current[cp] || current[:else] || 0
  end

  def can_accept?(cp)
    current.include?(cp)
  end

  def terminal?
    current_state == state_table.exit_state
  end

  def reset
    @current_state = 0
  end

  private

  def current
    state_table[current_state] || EMPTY_TRANSITION
  end
end

re = Re.new(to_state_table('(a|b|c)d'))
'dd'.each_char { |c| re.accept(c.ord); puts re.current_state }
puts re.terminal?
# binding.pry

# ['[abc]', '[abc]?', '[abc]+', '[abc]*'].each do |re|
#   puts "#{re} => #{to_state_table(re).inspect}"
# end

# binding.pry
exit 0
