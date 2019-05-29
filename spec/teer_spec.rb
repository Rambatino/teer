# frozen_string_literal: true

RSpec.describe Teer do
  it 'has a version number' do
    expect(Teer::VERSION).not_to be nil
  end

  it 'creates an empty finding when no data' do
    expect(Teer::Template.create([], [], '')).to eq(OpenStruct.new(data: nil, finding: nil))
  end

  context 'when looking at apples data' do
    let(:apples) { [{ 'name' => 'Bob', 'count' => 4 }, { 'name' => 'Alan', 'count' => 14 }, { 'name' => 'Jeff', 'count' => 2 }] }
    it 'can handle simple data with a simple template' do
      template = {
        'best_name' => 'names.sort[0].key',
        'best_value' => 'names.sort[0].value',
        'text' => {
          'GB_en' => '{{ best_name }} collected {{ best_value }} apples, higher than anyone else!'
        }
      }
      teer = Teer::Template.create(apples, 'count', template)
      expect(teer.finding).to eq('Alan collected 14 apples, higher than anyone else!')
    end

    it 'can handle yaml' do
      teer = Teer::Template.create(apples, 'count', File.join(File.dirname(__FILE__), './apples.yml'))
      expect(teer.finding).to eq('Jeff has the least apples, having only 2')
    end

    it 'can handle more complex yaml' do
      teer = Teer::Template.create(apples, 'count', File.join(File.dirname(__FILE__), './apples_with_conditionals.yml'))
      expect(teer.finding).to eq("Alan has the most apples. It's a lot more than Bob who came in second place.")
    end

    it 'can pass other parameters through' do
      template = {
        'best_name' => 'names.sort[0].key',
        'best_value' => 'names.sort[0].value',
        'text' => {
          'GB_en' => '{{ cat }} apples!'
        }
      }
      teer = Teer::Template.create(apples, 'count', template, 'cat' => 'meow')
      expect(teer.finding).to eq('meow apples!')
    end

    it 'can handle another language, such as French' do
      teer = Teer::Template.create(apples, 'count', File.join(File.dirname(__FILE__), './apples.yml'), {}, :FR)
      expect(teer.finding).to eq("Jeff a le moins de pommes, n'en ayant que 2")
    end

    it 'allows conditionals' do
      teer = Teer::Template.create(apples, 'count', File.join(File.dirname(__FILE__), './apples_with_conditionals.yml'))
      expect(teer.finding).to eq("Alan has the most apples. It's a lot more than Bob who came in second place.")
    end

    it 'can collect all statements' do
      teer = Teer::Template.create(apples, 'count', File.join(File.dirname(__FILE__), './apples_with_conditionals.yml'))
      expect(teer.findings).to eq(['Alan has the most apples.', "It's a lot more than Bob who came in second place."])
    end

    it 'can slice a specific person' do
      template = {
        'count' => 'names.slice("Bob")[0].value',
        'text' => {
          'GB_en' => 'Bob has {{ count }} apples!'
        }
      }
      teer = Teer::Template.create(apples, 'count', template, 'cat' => 'meow')
      expect(teer.finding).to eq('Bob has 4 apples!')
    end
  end

  context 'when passing spreadsheet of rules' do
    let(:apples) do
      [
        { 'name' => 'Bob', 'green_apple_count' => 4, 'red_apple_count' => 6 },
        { 'name' => 'Alan', 'green_apple_count' => 14, 'red_apple_count' => 10 },
        { 'name' => 'Jeff', 'green_apple_count' => 2, 'red_apple_count' => 15 }
      ]
    end

    it 'can parse 2d array templates of condition:text' do
      template = [
        ['green_apple_counts.mean < 5', 'Few green apples have been found'],
        ['green_apple_counts.mean > 4 && green_apple_counts.mean < 10', 'A decent amount of green apples have been found'],
        ['green_apple_counts.mean > 10', 'Lots of green apples have been found'],
        ['red_apple_counts.mean < 5', 'Few red apples have been found'],
        ['red_apple_counts.mean > 4 && red_apple_counts.mean < 10', 'A decent amount of red apples have been found'],
        ['red_apple_counts.mean > 9', 'Lots of red apples have been found'],
        ['red_apple_count.names.slice("Bob").value > 5', 'Bob has made his quota']
      ]
      teer = Teer::Template.create(apples, %w[green_apple_count red_apple_count], template)
      expect(teer.findings).to eq(['A decent amount of green apples have been found', 'Lots of red apples have been found', 'Bob has made his quota'])
    end

    let(:apples_bad_name) do
      [
        { 'name' => 'Bob', 'green_apples' => 4, 'red_apples' => 6 },
        { 'name' => 'Alan', 'green_apples' => 14, 'red_apples' => 10 },
        { 'name' => 'Jeff', 'green_apples' => 2, 'red_apples' => 15 }
      ]
    end

    it 'raises error if column name is plural' do
      expect { Teer::Template.create(apples, %w[green_apples red_apples], [[]]) }.to raise_error
    end

    it 'columns do not exist' do
      expect { Teer::Template.create(apples, %w[green_apple red_apple_count], [[]]) }.to raise_error
    end
  end

  context 'it can handle more complex examples' do
    it 'can output bullet points and link between indexes' do
      tree_data = [
        { 'node_id' => 0, 'label' => Float::NAN, 'question' => Float::NAN, 'answer' => Float::NAN, 'is_terminal' => false, 'base_size' => 250.0, 'behaviour_change' => 7.244 },
        { 'node_id' => 1, 'label' => 'gender', 'question' => 'gender', 'answer' => 'Male', 'is_terminal' => true, 'base_size' => 100.0, 'behaviour_change' => 7.34 },
        { 'node_id' => 2, 'label' => 'gender', 'question' => 'gender', 'answer' => 'Female', 'is_terminal' => false, 'base_size' => 150.0, 'behaviour_change' => 7.18 },
        { 'node_id' => 3, 'label' => 'region', 'question' => 'regUS', 'answer' => 'North East', 'is_terminal' => true, 'base_size' => 117.0, 'behaviour_change' => 7.265 },
        { 'node_id' => 3, 'label' => 'region', 'question' => 'regUS', 'answer' => 'Mid West', 'is_terminal' => true, 'base_size' => 117.0, 'behaviour_change' => 7.265 },
        { 'node_id' => 3, 'label' => 'region', 'question' => 'regUS', 'answer' => 'South', 'is_terminal' => true, 'base_size' => 117.0, 'behaviour_change' => 7.265 },
        { 'node_id' => 3, 'label' => 'gender', 'question' => 'gender', 'answer' => 'Female', 'is_terminal' => true, 'base_size' => 117.0, 'behaviour_change' => 7.265 },
        { 'node_id' => 4, 'label' => 'region', 'question' => 'regUS', 'answer' => 'West', 'is_terminal' => true, 'base_size' => 33.0, 'behaviour_change' => 6.879 },
        { 'node_id' => 4, 'label' => 'gender', 'question' => 'gender', 'answer' => 'Female', 'is_terminal' => true, 'base_size' => 33.0, 'behaviour_change' => 6.879 }
      ]
      teer = Teer::Template.create(
        tree_data,
        'behaviour_change',
        File.join(File.dirname(__FILE__), './tree.yml'),
        'NAME' => 'Would you change your response to Apple?'
      )
      expect(teer.finding).to eq("Behaviour change was worst for respondents who selected: \n* `West` for `regUS`\n* `Female` for `gender`\n\nfor `Would you change your response to Apple?`")
    end
  end

  context 'helpers' do
    let(:horrible_floats_and_time) do
      [
        { 'time' => Time.new(1993, 0o2, 24, 12, 0, 0, '+09:00'), 'name' => 'Bob', 'count' => 4.213432 },
        { 'time' => Time.new(1993, 0o2, 24, 12, 0, 0, '+09:00'), 'name' => 'Alan', 'count' => 14.35 },
        { 'time' => Time.new(1993, 0o2, 24, 12, 0, 0, '+09:00'), 'name' => 'Jeff', 'count' => 2.1 }
      ]
    end

    it 'can use default handler :round' do
      template = { 'best_value' => 'names.sort[0].value', 'text' => { 'GB_en' => '{{round best_value }}' } }
      teer = Teer::Template.create(horrible_floats_and_time, 'count', template)
      expect(teer.finding).to eq('14.4')
    end

    it 'can use default handler :month' do
      template = { 'month_key' => 'times.sort[0].key', 'text' => { 'GB_en' => '{{month month_key }}' } }
      teer = Teer::Template.create(horrible_floats_and_time, 'count', template)
      expect(teer.finding).to eq('February')
    end

    it 'raises ledgeable error when helper does not exist' do
      template = { 'month_key' => 'times.sort[0].key', 'text' => { 'GB_en' => '{{year month_key }}' } }
      teer = Teer::Template.create(horrible_floats_and_time, 'count', template)
      expect { teer.finding }.to raise_error(/Missing helper: 'year'/)
    end

    it 'can have extra handlers added' do
      Teer::Template.parser.register_helper(:year) do |ctx, value|
        Time.at(value).strftime('%Y')
      end

      template = { 'month_key' => 'times.sort[0].key', 'text' => { 'GB_en' => '{{year month_key }}' } }
      teer = Teer::Template.create(horrible_floats_and_time, 'count', template)
      expect(teer.finding).to eq('1993')
    end
  end

  context '#bug_fixes' do
    let(:apples) do
      [
        { 'name' => 'Bob', 'green_apple_count' => 4, 'red_apple_count' => 6 },
        { 'name' => 'Alan', 'green_apple_count' => 14, 'red_apple_count' => 10 },
        { 'name' => 'Jeff', 'green_apple_count' => 2, 'red_apple_count' => 15 }
      ]
    end

    it 'returns error if variable inside handlebars unrecognized' do
      template = [
        ['green_apple_counts.mean > 4 && green_apple_counts.mean < 10', 'A decent amount of green apples have been found equal to {{round green_apple_count.mean }}'],
      ]
      teer = Teer::Template.create(apples, %w[green_apple_count red_apple_count], template)
      expect { teer.finding }.to raise_error(ArgumentError, "Could not parse variable: 'green_apple_count.mean'")
    end

    it 'returns error if variable in condition unrecognized' do
      template = [
        ['green_apple_c.mean > 4 && green_apple_counts.mean < 10', 'A decent amount of green apples have been found equal to {{round green_apple_count.mean }}'],
      ]
      teer = Teer::Template.create(apples, %w[green_apple_count red_apple_count], template)
      expect { teer.finding }.to raise_error(ArgumentError, "Could not parse variables in condition: 'green_apple_c.mean > 4 && green_apple_counts.mean < 10'")
    end

    it 'returns error if hash passed as data' do
      template = [
        ['green_apple_counts.mean > 4 && green_apple_counts.mean < 10', 'A decent amount of green apples have been found equal to {{round green_apple_count.mean }}'],
      ]
      teer = Teer::Template.create(apples, %w[green_apple_count red_apple_count], template)
      expect { teer.finding }.to raise_error(ArgumentError, "Could not parse variable: 'green_apple_count.mean'")
    end
  end
end
