require './selector'
require 'test/unit'

class TestVersion < Test::Unit::TestCase
  def test_equal_operator
    @a = '0.1.2'.to_v
    @b = '0.1.2'.to_v

    assert @a == @b
  end

  def test_greater_or_equal_operator
    @a = '0.1.2'.to_v
    @b = '0.1.2'.to_v
    @c = '1.1.2'.to_v
    @d = '0.0.5'.to_v

    assert (@a >= @b), "#{@a} < #{@b}"
    assert !(@a >= @c), "#{@a} < #{@c}"
    assert (@a >= @d), "#{@a} < #{@d}"
  end

  def test_greater_operator
    @a = '0.1.2'.to_v
    @b = '0.1.2'.to_v
    @c = '1.1.2'.to_v
    @d = '0.0.5'.to_v

    assert !(@a > @b), "#{@a} <= #{@b}"
    assert !(@a > @c), "#{@a} <= #{@c}"
    assert (@a > @d), "#{@a} <= #{@d}"
  end

  def test_lower_or_equal_operator
    @a = '0.1.2'.to_v
    @b = '0.1.2'.to_v
    @c = '1.1.2'.to_v
    @d = '0.0.5'.to_v

    assert (@a <= @b), "#{@a} > #{@b}"
    assert (@a <= @c), "#{@a} > #{@c}"
    assert !(@a <= @d), "#{@a} > #{@d}"
  end

  def test_lower_operator
    @a = '0.1.2'.to_v
    @b = '0.1.2'.to_v
    @c = '1.1.2'.to_v
    @d = '0.0.5'.to_v

    assert !(@a < @b), "#{@a} >= #{@b}"
    assert (@a < @c), "#{@a} >= #{@c}"
    assert !(@a < @d), "#{@a} >= #{@d}"
  end

  def test_increment
    @a = '1'.to_v
    @b = '1.1'.to_v
    @c = '1.1.1'.to_v

    assert_equal '2', @a.increment.to_s
    assert_equal '1.2', @b.increment.to_s
    assert_equal '1.1.2', @c.increment.to_s
  end

  def test_decrement
    @a = '1'.to_v
    @b = '1.1'.to_v
    @c = '1.1.1'.to_v

    assert_equal '0', @a.decrement.to_s
    assert_equal '1.0', @b.decrement.to_s
    assert_equal '1.1.0', @c.decrement.to_s
  end

  def test_fill_with_zero
    @a = '1'.to_v
    @b = '1.1'.to_v
    @c = '1.1.1'.to_v

    assert_equal '1.0.0', @a.fill_with_zero.to_s
    assert_equal '1.1.0', @b.fill_with_zero.to_s
    assert_equal '1.1.1', @c.fill_with_zero.to_s
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
      '2.0.0', '2.1.1', '2.2.2',
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

    gt = @version_selector.match '>0.1'
    assert_equal '9999.9999.9999', gt

    gt = @version_selector.match '>0'
    assert_equal '9999.9999.9999', gt

    gt = @version_selector.match '>9999.9999.9999'
    assert_nil gt
  end

  def test_greater_or_equal_version
    gte = @version_selector.match '>=0.1.2'
    assert_equal '9999.9999.9999', gte

    gte = @version_selector.match '>=0.1'
    assert_equal '9999.9999.9999', gte

    gte = @version_selector.match '>=0'
    assert_equal '9999.9999.9999', gte

    gte = @version_selector.match '>=9999.9999.9999'
    assert_equal '9999.9999.9999', gte
  end

  def test_lower_version
    lt = @version_selector.match '<0.1.2'
    assert_equal '0.1.1', lt

    lt = @version_selector.match '<0.1'
    assert_equal '0.0.5', lt

    lt = @version_selector.match '<0'
    assert_nil lt

    lt = @version_selector.match '<0.0.0'
    assert_nil lt
  end

  def test_lower_or_equal
    lte = @version_selector.match '<=0.1.2'
    assert_equal '0.1.2', lte

    lt = @version_selector.match '<=0.1'
    assert_equal '0.1.0', lt

    lt = @version_selector.match '<=0'
    assert_equal '0000.0000.0000', lt
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

    res = @version_selector.match '>9999.9999.9999 || >1.1.1 <1.2.0'
    assert_equal '1.1.2', res
  end

  def test_partial_version
    res = @version_selector.match '1'
    assert_equal '1.2.2', res

    res = @version_selector.match '1.1'
    assert_equal '1.1.2', res

    res = @version_selector.match '1.x'
    assert_equal '1.2.2', res

    res = @version_selector.match '1.1.x'
    assert_equal '1.1.2', res

    res = @version_selector.match '1.x.x'
    assert_equal '1.2.2', res
  end

  def test_tilde_range_version
    res = @version_selector.match '~1'
    assert_equal '1.2.2', res

    res = @version_selector.match '~1.1'
    assert_equal '1.2.2', res

    res = @version_selector.match '~1.0.1'
    assert_equal '1.0.2', res

    res = @version_selector.match '~9999.9999.9999'
    assert_equal '9999.9999.9999', res
  end

end
