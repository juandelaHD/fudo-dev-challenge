# frozen_string_literal: true

require_relative '../test_helper'

class ProductValidatorTest < Minitest::Test
  def test_validates_valid_product
    result = ProductValidator.validate_create(name: 'Test Product', description: 'A description')
    
    assert result[:success]
    assert_equal 'Test Product', result[:data][:name]
  end

  def test_rejects_missing_name
    result = ProductValidator.validate_create(description: 'Only description')
    
    refute result[:success]
    assert_includes result[:errors], :name
  end

  def test_rejects_empty_name
    result = ProductValidator.validate_create(name: '', description: 'Test')
    
    refute result[:success]
    assert_includes result[:errors], :name
  end

  def test_rejects_name_too_long
    long_name = 'a' * 256
    result = ProductValidator.validate_create(name: long_name)
    
    refute result[:success]
    assert_includes result[:errors], :name
  end

  def test_accepts_name_at_max_length
    max_name = 'a' * 255
    result = ProductValidator.validate_create(name: max_name)
    
    assert result[:success]
  end

  def test_accepts_missing_description
    result = ProductValidator.validate_create(name: 'Product')
    
    assert result[:success]
  end

  def test_rejects_description_too_long
    long_desc = 'a' * 1001
    result = ProductValidator.validate_create(name: 'Product', description: long_desc)
    
    refute result[:success]
    assert_includes result[:errors], :description
  end
end
