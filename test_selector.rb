require './selector'
require 'test/unit'

class TestVersion < Test::Unit::TestCase
  def test_equal_operator
    @a = Version.new '0.1.2'
    @b = Version.new '0.1.2'

    assert @a == @b
  end

  def test_greater_or_equal_operator
    @a = Version.new '0.1.2'
    @b = Version.new '0.1.2'
    @c = Version.new '1.1.2'
    @d = Version.new '0.0.5'

    assert (@a >= @b), "#{@a} < #{@b}"
    assert !(@a >= @c), "#{@a} < #{@c}"
    assert (@a >= @d), "#{@a} < #{@d}"
  end

  def test_greater_operator
    @a = Version.new '0.1.2'
    @b = Version.new '0.1.2'
    @c = Version.new '1.1.2'
    @d = Version.new '0.0.5'

    assert !(@a > @b), "#{@a} <= #{@b}"
    assert !(@a > @c), "#{@a} <= #{@c}"
    assert (@a > @d), "#{@a} <= #{@d}"
  end

  def test_lower_or_equal_operator
    @a = Version.new '0.1.2'
    @b = Version.new '0.1.2'
    @c = Version.new '1.1.2'
    @d = Version.new '0.0.5'

    assert (@a <= @b), "#{@a} > #{@b}"
    assert (@a <= @c), "#{@a} > #{@c}"
    assert !(@a <= @d), "#{@a} > #{@d}"
  end

  def test_lower_operator
    @a = Version.new '0.1.2'
    @b = Version.new '0.1.2'
    @c = Version.new '1.1.2'
    @d = Version.new '0.0.5'

    assert !(@a < @b), "#{@a} >= #{@b}"
    assert (@a < @c), "#{@a} >= #{@c}"
    assert !(@a < @d), "#{@a} >= #{@d}"
  end


end

class TestVersionSelector < Test::Unit::TestCase

  def setup
    @version_selector = VersionSelector.new([
      '0000.0000.0000',
      '9999.9999.9999',
      '0.0.1', '0.0.2', '0.0.3', '0.0.4', '0.0.5',
      '0.1.0', '0.1.1', '0.1.2', '0.1.3',
      '0.2.0', '0.2.1', '0.2.2', '0.2.3',
      '1.0.0', '1.0.1', '1.0.2',
      '1.1.0', '1.1.1', '1.1.2',
      '1.2.0', '1.2.1', '1.2.2',
    ])
  end

  def test_version_only
    res = @version_selector.match '0.1.2'
    assert_equal '0.1.2', res, 'selector didn\'t found the exact version'
  end

  def test_equal_version
    res = @version_selector.match '=0.1.2'
    assert_equal '0.1.2', res, 'selector didn\'t found the exact version'
  end

  def test_greater_version
    gt = @version_selector.match '>0.1.2'
    assert_equal '9999.9999.9999', gt

    gt = @version_selector.match '>9999.9999.9999'
    assert_nil gt
  end

  def test_greater_or_equal_version
    gte = @version_selector.match '>=0.1.2'
    assert_equal '9999.9999.9999', gte
  end

  def test_lower_version
    lt = @version_selector.match '<0.1.2'
    assert_equal '0.1.1', lt

    lt = @version_selector.match '<0.0.0'
    assert_nil lt
  end

  def test_lower_or_equal
    lte = @version_selector.match '<=0.1.2'
    assert_equal '0.1.2', lte
  end

  def test_any_version
    res = @version_selector.match '*'
    assert_equal '9999.9999.9999', res
  end

  def test_empty_version
    res = @version_selector.match ''
    assert_equal '9999.9999.9999', res
  end

  def test_version_range_by_substraction
    res = @version_selector.match '1.0.0 - 1.1.1'
    assert_equal '1.1.1', res
  end

  def test_version_range
    res = @version_selector.match '>1.0.0 <1.1.1'
    assert_equal '1.1.0', res
  end

  def test_or_version_range
    res = @version_selector.match '<1.0.0 || >1.1.1'
    assert_equal '0.2.3', res
  end


end
