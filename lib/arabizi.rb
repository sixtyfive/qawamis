# Arabizi (a.k.a. Arabic chat alphabet, Franco-Arabic, Araby) parsing.
#
# When a user types a word in Latin script (e.g. "kitaab", "3arabi", "sh3r")
# into the search field, we try to recover the Arabic-script *root* they were
# most likely after. Roots are (mostly) sequences of consonantal radicals, so
# the job is essentially: transliterate the Arabizi to Arabic consonants,
# decide which of the vowels are actually weak radicals (ا/و/ي) and which are
# just short vowels that a root omits, and offer the results ranked by how
# plausible their length is (3 radicals most likely, 2 or 4 less so, 5+ least).
#
# See https://en.wikipedia.org/wiki/Arabizi for the conventions used below.
#
# Everything here is written defensively: input is length-capped and reduced to
# a known character set before parsing, tokenisation is a single linear scan
# (no backtracking regexes), and candidate generation is hard-capped so that no
# input can cause combinatorial blow-up.
module Arabizi
  # Longest realistic Arabizi word we bother with. Roots are short; anything
  # past this is almost certainly not a single word and is truncated so a huge
  # paste can never drive the parser.
  MAX_INPUT   = 32
  # Roots longer than this effectively do not exist; such candidates are dropped.
  MAX_ROOT    = 7
  # Absolute ceiling on generated candidates, independent of input.
  MAX_CANDIDATES = 48

  # Multi-character tokens, tried longest-first during the scan. A token maps to
  # either a consonant (:c) — a definite Arabic radical, possibly with less
  # likely alternatives — or a vowel (:v) carrying the weak letter it would
  # become if it turned out to be a radical.
  #
  # Order within this list does not matter; the scanner sorts by length.
  DIGRAPHS = {
    # digit + apostrophe modifiers
    "3'" => {c: %w[غ]},
    "6'" => {c: %w[ظ]},
    "7'" => {c: %w[خ]},
    "9'" => {c: %w[ض]},
    # consonant digraphs
    'sh' => {c: %w[ش]},
    'ch' => {c: %w[ش]},
    'th' => {c: %w[ث ت]},
    'dh' => {c: %w[ذ ض]},
    'kh' => {c: %w[خ]},
    'gh' => {c: %w[غ]},
    # long vowels / diphthongs -> weak radical candidates
    'aa' => {v: 'ا'},
    'ee' => {v: 'ي'},
    'ii' => {v: 'ي'},
    'ei' => {v: 'ي'},
    'ai' => {v: 'ي'},
    'ay' => {v: 'ي'},
    'ey' => {v: 'ي'},
    'oo' => {v: 'و'},
    'uu' => {v: 'و'},
    'ou' => {v: 'و'},
    'aw' => {v: 'و'},
    'au' => {v: 'و'},
  }.freeze

  # Single characters. Consonants are always kept; the first Arabic letter is
  # the canonical reading, the rest are less likely alternatives.
  MONOGRAPHS = {
    '2' => {c: %w[ء]},
    '3' => {c: %w[ع]},
    '5' => {c: %w[خ]},
    '6' => {c: %w[ط]},
    '7' => {c: %w[ح]},
    '8' => {c: %w[ق غ]},
    '9' => {c: %w[ص]},
    'b' => {c: %w[ب]},
    'p' => {c: %w[ب]},
    't' => {c: %w[ت]},
    'j' => {c: %w[ج]},
    'g' => {c: %w[غ ج ق]},
    'd' => {c: %w[د]},
    'r' => {c: %w[ر]},
    'z' => {c: %w[ز]},
    's' => {c: %w[س]},
    'c' => {c: %w[ك س]},
    'f' => {c: %w[ف]},
    'v' => {c: %w[ف]},
    'q' => {c: %w[ق]},
    'k' => {c: %w[ك]},
    'l' => {c: %w[ل]},
    'm' => {c: %w[م]},
    'n' => {c: %w[ن]},
    'h' => {c: %w[ه ح]},
    'x' => {c: %w[خ]},
    # w and y are genuine consonants (و/ي) that double as long vowels; keep them.
    'w' => {c: %w[و]},
    'y' => {c: %w[ي]},
    # short vowels — usually omitted from a root, but a weak radical if kept
    'a' => {v: 'ا'},
    'e' => {v: 'ي'},
    'i' => {v: 'ي'},
    'o' => {v: 'و'},
    'u' => {v: 'و'},
  }.freeze

  DIGRAPH_KEYS = DIGRAPHS.keys.sort_by { |k| -k.length }.freeze

  # Length ranking: 3 radicals is the canonical Semitic root, then 2/4, then 5+,
  # with single-letter results least plausible of all. Lower is better.
  LENGTH_RANK = Hash.new(9).merge(3 => 0, 2 => 1, 4 => 2, 5 => 3, 6 => 4, 7 => 5, 1 => 8).freeze

  module_function

  # True when the string looks like Latin-script input we should transliterate:
  # it contains at least one Latin letter and no Arabic-script characters.
  def latin?(string)
    return false unless string.is_a?(String)
    string.match?(/\p{Latin}/) && !string.match?(/\p{Arabic}/)
  end

  # Returns Arabic-script root candidates for +string+, best guess first.
  # Always returns at least the sanitised transliteration; never raises on
  # hostile input.
  def root_candidates(string)
    tokens = tokenize(sanitize(string))
    return [] if tokens.empty?

    candidates = expand(tokens)
    ranked = candidates
      .select { |cand| cand[:root].length.between?(1, MAX_ROOT) }
      .uniq   { |cand| cand[:root] }
      .sort_by { |cand| [LENGTH_RANK[cand[:root].length], cand[:penalty], cand[:root].length] }

    ranked.map { |cand| cand[:root] }
  end

  # --- internals -------------------------------------------------------------

  # Reduce input to a bounded, known-safe character set: lower-cased ASCII
  # letters, Arabizi digits and the apostrophe modifier. Everything else
  # (spaces, punctuation, control chars, non-Arabizi digits like 0/1/4) is
  # dropped. This is the security boundary — no other input reaches the parser.
  def sanitize(string)
    return '' unless string.is_a?(String)
    string[0, MAX_INPUT].downcase.gsub(/[^a-z2356789']/, '')
  end

  # Linear left-to-right scan into a list of {:c=>[...]} / {:v=>'x'} segments.
  def tokenize(clean)
    segments = []
    i = 0
    len = clean.length
    while i < len
      matched = DIGRAPH_KEYS.find { |key| clean[i, key.length] == key }
      if matched
        segments << DIGRAPHS[matched]
        i += matched.length
      elsif (mono = MONOGRAPHS[clean[i]])
        segments << mono
        i += 1
      else
        # A leftover apostrophe or stray char with no reading: skip it.
        i += 1
      end
    end
    segments
  end

  # Turn the segment list into concrete root strings. Each consonant segment
  # contributes its letter (canonical, or an alternative at a penalty); each
  # vowel segment is either dropped (short-vowel reading) or kept as its weak
  # radical (at a penalty). Generation is capped so no input can explode.
  def expand(segments)
    results = [{root: +'', penalty: 0}]

    segments.each_with_index do |seg, idx|
      choices =
        if seg[:c]
          # consonant: letter is mandatory; first reading free, others penalised
          seg[:c].each_with_index.map { |letter, alt| {add: letter, cost: alt} }
        else
          # vowel: dropping it is the default; keeping the weak radical costs 1.
          # A word-initial vowel is much more likely to be a real alif/hamza,
          # so there we prefer keeping it.
          initial = (idx == 0)
          keep = {add: seg[:v], cost: initial ? 0 : 1}
          drop = {add: '',      cost: initial ? 1 : 0}
          [keep, drop]
        end

      next_results = []
      results.each do |partial|
        choices.each do |choice|
          next_results << {
            root:    partial[:root] + choice[:add],
            penalty: partial[:penalty] + choice[:cost],
          }
          break if next_results.length >= MAX_CANDIDATES * 4
        end
      end
      # Keep the cheapest partials when we would otherwise overflow, so long or
      # highly ambiguous input degrades gracefully instead of blowing up.
      results = next_results.sort_by { |r| r[:penalty] }.first(MAX_CANDIDATES * 4)
    end

    results
  end
end
