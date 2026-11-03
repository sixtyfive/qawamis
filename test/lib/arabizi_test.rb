require 'test_helper'

class ArabiziTest < ActiveSupport::TestCase
  # --- detection -------------------------------------------------------------

  def test_latin_detects_ascii_words
    assert Arabizi.latin?('kitaab')
    assert Arabizi.latin?('3arabi'), 'digits mixed with Latin letters are Arabizi'
  end

  def test_latin_rejects_arabic_script
    refute Arabizi.latin?('كتب')
    refute Arabizi.latin?('كتاب abc'), 'presence of any Arabic script disqualifies it'
  end

  def test_latin_rejects_pure_numbers_and_junk
    refute Arabizi.latin?('123')
    refute Arabizi.latin?('!!!')
    refute Arabizi.latin?('')
    refute Arabizi.latin?(nil)
  end

  # --- transliteration to a root --------------------------------------------

  def test_common_words_yield_the_expected_three_letter_root_first
    {
      'kitaab' => 'كتب', # book       -> k-t-b
      'salaam' => 'سلم', # peace      -> s-l-m
      'shams'  => 'شمس', # sun        -> sh-m-s
      '3arabi' => 'عرب', # Arabic     -> 3-r-b
      '3ilm'   => 'علم', # knowledge  -> 3-l-m
      'darasa' => 'درس', # to study   -> d-r-s
    }.each do |arabizi, expected_root|
      assert_equal expected_root, Arabizi.root_candidates(arabizi).first,
        "expected #{arabizi.inspect} to transliterate to #{expected_root}"
    end
  end

  def test_digit_glyphs_map_to_their_letters
    assert_equal 'حمد', Arabizi.root_candidates('7amd').first  # 7 -> ح
    assert_equal 'طلب', Arabizi.root_candidates('6alab').first # 6 -> ط
    assert_equal 'صبر', Arabizi.root_candidates('9abr').first  # 9 -> ص
    assert_equal 'غرب', Arabizi.root_candidates("3'arb").first # 3' -> غ
  end

  def test_candidates_are_ranked_by_plausible_length
    candidates = Arabizi.root_candidates('kitaab')
    lengths = candidates.map(&:length)
    assert_equal 3, lengths.first, 'a 3-letter root should be the top guess'
    # the weak-radical reading (كتاب, 4 letters) should also be offered...
    assert_includes candidates, 'كتاب'
    # ...but ranked after the 3-letter root.
    assert_operator candidates.index('كتب'), :<, candidates.index('كتاب')
  end

  def test_result_is_always_arabic_script
    Arabizi.root_candidates('kitaab').each do |root|
      assert_match(/\A\p{Arabic}+\z/, root)
    end
  end

  # --- security / robustness -------------------------------------------------

  def test_hostile_or_empty_input_never_raises_and_stays_bounded
    ['', '   ', '!@#$%^&*()', '../../etc/passwd', "'; DROP TABLE pages;--"].each do |input|
      assert_nothing_raised { Arabizi.root_candidates(input) }
    end
  end

  def test_pathological_length_input_is_capped
    result = nil
    assert_nothing_raised { result = Arabizi.root_candidates('a' * 5000) }
    assert result.length <= Arabizi::MAX_CANDIDATES
    result.each { |root| assert_operator root.length, :<=, Arabizi::MAX_ROOT }
  end

  def test_highly_ambiguous_input_does_not_explode
    # every character is an ambiguous letter/vowel; generation must stay capped
    assert_nothing_raised { Arabizi.root_candidates('ghghghghghaiaiai') }
    assert_operator Arabizi.root_candidates('ghghghghghaiaiai').length, :<=, Arabizi::MAX_CANDIDATES
  end

  def test_non_string_input_is_handled
    assert_equal [], Arabizi.root_candidates(nil)
    assert_equal [], Arabizi.root_candidates(12345)
    refute Arabizi.latin?(:symbol)
  end
end
