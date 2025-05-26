require 'test_helper'

class StartlistGeneratorTest < ActiveSupport::TestCase

  def test_reorder_participants
    assert_equal(
      [3, 1, 2, 4],
      Services::StartlistGenerator.reorder_participants([1, 2, 3, 4],nil))
    assert_equal(
      [5, 3, 1, 2, 4],
      Services::StartlistGenerator.reorder_participants([1, 2, 3, 4, 5],nil))
    assert_equal(
      [5, 3, 1, 2, 4, 6],
      Services::StartlistGenerator.reorder_participants([1, 2, 3, 4, 5, 6],nil))

    assert_equal(
      [1, 2, 3, 4, 5, 6],
      Services::StartlistGenerator.reorder_participants([1, 2, 3, 4, 5, 6],'start_at_lane_1'))
    assert_equal(
      [6, 5, 4, 3, 2, 1],
      Services::StartlistGenerator.reorder_participants([1, 2, 3, 4, 5, 6],'end_at_lane_1'))
  end

  def test_number_of_heats
    assert_equal(0, Services::StartlistGenerator.number_of_heats(8, 0))
    assert_equal(1, Services::StartlistGenerator.number_of_heats(8, 1))
    assert_equal(1, Services::StartlistGenerator.number_of_heats(8, 8))
    assert_equal(2, Services::StartlistGenerator.number_of_heats(8, 9))
    assert_equal(2, Services::StartlistGenerator.number_of_heats(8, 16))
    assert_equal(4, Services::StartlistGenerator.number_of_heats(8, 17))
    assert_equal(4, Services::StartlistGenerator.number_of_heats(8, 32))
    assert_equal(8, Services::StartlistGenerator.number_of_heats(8, 33))
    assert_equal(8, Services::StartlistGenerator.number_of_heats(8, 64))
    assert_equal(8, Services::StartlistGenerator.number_of_heats(8, 65)) # ??
  end

  def test_participants_from_equal_distribution
    assert_equal(
      [[1, 2, 3, 4, 5, 6]],
      Services::StartlistGenerator.participants_from_equal_distribution([1, 2, 3, 4, 5, 6], 1))

    assert_equal(
      [[1, 2, 3], [4, 5, 6]],
      Services::StartlistGenerator.participants_from_equal_distribution([1, 2, 3, 4, 5, 6], 2))
    assert_equal(
      [[1, 2, 3, 4], [5, 6, 7]],
      Services::StartlistGenerator.participants_from_equal_distribution([1, 2, 3, 4, 5, 6, 7], 2))
    assert_equal(
      [[1, 2, 3, 4], [5, 6, 7, 8]],
      Services::StartlistGenerator.participants_from_equal_distribution([1, 2, 3, 4, 5, 6, 7, 8], 2))

    assert_equal(
      [[1, 2, 3], [4, 5], [6, 7]],
      Services::StartlistGenerator.participants_from_equal_distribution([1, 2, 3, 4, 5, 6, 7], 3))
    assert_equal(
      [[1, 2, 3], [4, 5, 6], [7, 8]],
      Services::StartlistGenerator.participants_from_equal_distribution([1, 2, 3, 4, 5, 6, 7, 8], 3))
  end

end