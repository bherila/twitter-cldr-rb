require 'twitter_cldr'
require 'pry-byebug'
require 'benchmark'
require 'benchmark/ips'
require 'ruby-prof'

# re = TwitterCldr::Shared::UnicodeRegex.compile('a|[ab]')
# re = TwitterCldr::Shared::UnicodeRegex.compile('L\.P\.|Alt\.|Approx\.|E\.G\.|O\.|Maj\.|Misc\.|P\.O\.|J\.D\.|Jam\.|Card\.|Dec\.|Sept\.|MR\.|Long\.|Hat\.|G\.|Link\.|DC\.|D\.C\.|M\.T\.|Hz\.|Mrs\.|By\.|Act\.|Var\.|N\.V\.|Aug\.|B\.|S\.A\.|Up\.|Job\.|Num\.|M\.I\.T\.|Ok\.|Org\.|Ex\.|Cont\.|U\.|Mart\.|Fn\.|Abs\.|Lt\.|OK\.|Z\.|E\.|Kb\.|Est\.|A\.M\.|L\.A\.|Prof\.|U\.S\.|Nov\.|Ph\.D\.|Mar\.|I\.T\.|exec\.|Jan\.|N\.Y\.|X\.|Md\.|Op\.|vs\.|D\.A\.|A\.D\.|R\.L\.|P\.M\.|Or\.|M\.R\.|Cap\.|PC\.|Feb\.|Exec\.|I\.e\.|Sep\.|Gb\.|K\.|U\.S\.C\.|Mt\.|S\.|A\.S\.|C\.O\.D\.|Capt\.|Col\.|In\.|C\.F\.|Adj\.|AD\.|I\.D\.|Mgr\.|R\.T\.|B\.V\.|M\.|Conn\.|Yr\.|Rev\.|Phys\.|pp\.|Ms\.|To\.|Sgt\.|J\.K\.|Nr\.|Jun\.|Fri\.|S\.A\.R\.|Lev\.|Lt\.Cdr\.|Def\.|F\.|Do\.|Joe\.|Id\.|Mr\.|Dept\.|Is\.|Pvt\.|Diff\.|Hon\.B\.A\.|Q\.|Mb\.|On\.|Min\.|J\.B\.|Ed\.|AB\.|A\.|S\.p\.A\.|I\.|a\.m\.|Comm\.|Go\.|VS\.|L\.|All\.|PP\.|P\.V\.|T\.|K\.R\.|Etc\.|D\.|Adv\.|Lib\.|E\.g\.|Pro\.|U\.S\.A\.|S\.E\.|AA\.|Rep\.|Sq\.|As\.')
re = TwitterCldr::Shared::UnicodeRegex.compile('(ab*|c)')
state_table = TwitterCldr::Resources::Segmentation::RuleVisitor.new(re).start
puts state_table.inspect
exit 0
state = TwitterCldr::Segmentation::State.new(state_table.finalize)
# accepted = 'Approx.'.each_byte.map { |b| state.accept(b) }
binding.pry
exit 0

# rh = TwitterCldr::Utils::RangeHash.from_hash(
#   { 1 => 3, 3 => 4, 4 => 5, 5 => 6, 6 => 8, 7 => 9 }
# )

# binding.pry
# exit 0

# text = File.read('/Users/cameron/Dropbox/JHU/605.421/CompressionAndEncryption/texts/HarryPotter_Ch1.txt')
# text = 'This is cool. And fun.'
text = "\u002E\u0308\u0001"
brkiter = TwitterCldr::Segmentation::BreakIterator.new(:en, use_uli_exceptions: true)
brkiter.each_sentence(text) { |str, start, finish| str }
exit 0

# counts = brkiter.send(:rule_break_engine_for, 'word')
#   .rule_set.rules.flat_map do |rule|
#     [rule.left, rule.right].reject(&:empty?).flat_map do |r|
#       r.state_table.table.map do |k, v|
#         [rule.id, k, v.instance_variable_get(:@int_elements).size]
#       end
#     end
#   end

# binding.pry
# exit 0

# result = RubyProf.profile do
#   5_000.times { brkiter.each_word(text) { |str, _, _| } }
# end

# printer = RubyProf::FlatPrinter.new(result)
# printer.print(STDOUT)

# exit 0

# text = File.read('/Users/cameron/Dropbox/JHU/605.421/CompressionAndEncryption/texts/HarryPotter_Ch1.txt')
# brkiter = TwitterCldr::Segmentation::BreakIterator.new(:en)
# puts brkiter.each_word(text) { |str, _, _| puts str }
# exit 0


Benchmark.ips do |x|
  x.report do
    brkiter.each_sentence(text) { |str, _, _| }
  end
end
