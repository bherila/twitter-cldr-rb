# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Segmentation
    autoload :AlternationState,      'twitter_cldr/segmentation/alternation_state'
    autoload :BrahmicBreakEngine,    'twitter_cldr/segmentation/brahmic_break_engine'
    autoload :BreakIterator,         'twitter_cldr/segmentation/break_iterator'
    autoload :BreakRule,             'twitter_cldr/segmentation/rule'
    autoload :BurmeseBreakEngine,    'twitter_cldr/segmentation/burmese_break_engine'
    autoload :Cursor,                'twitter_cldr/segmentation/cursor'
    autoload :CjBreakEngine,         'twitter_cldr/segmentation/cj_break_engine'
    autoload :Dictionary,            'twitter_cldr/segmentation/dictionary'
    autoload :DictionaryBreakEngine, 'twitter_cldr/segmentation/dictionary_break_engine'
    autoload :KhmerBreakEngine,      'twitter_cldr/segmentation/khmer_break_engine'
    autoload :LaoBreakEngine,        'twitter_cldr/segmentation/lao_break_engine'
    autoload :NoBreakRule,           'twitter_cldr/segmentation/rule'
    autoload :Parser,                'twitter_cldr/segmentation/parser'
    autoload :PossibleWord,          'twitter_cldr/segmentation/possible_word'
    autoload :PossibleWordList,      'twitter_cldr/segmentation/possible_word_list'
    autoload :Rule,                  'twitter_cldr/segmentation/rule'
    autoload :RuleBasedBreakEngine,  'twitter_cldr/segmentation/rule_based_break_engine'
    autoload :RuleSet,               'twitter_cldr/segmentation/rule_set'
    autoload :RuleSetLoader,         'twitter_cldr/segmentation/rule_set_loader'
    autoload :State,                 'twitter_cldr/segmentation/state'
    autoload :ThaiBreakEngine,       'twitter_cldr/segmentation/thai_break_engine'
    autoload :UnhandledBreakEngine,  'twitter_cldr/segmentation/unhandled_break_engine'
  end
end
