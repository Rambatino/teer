RSpec.describe Templater do
  it 'has a version number' do
    expect(Templater::VERSION).not_to be nil
  end

  it 'creates an empty finding when no data' do
    expect(Templater::Template.create([], [], '')).to eq(OpenStruct.new(data: nil, finding: nil))
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
      templater = Templater::Template.create(apples, 'count', template)
      binding.pry
      expect(templater.finding).to eq('Alan collected 14 apples, higher than anyone else!')
    end

    it 'can handle yaml' do
      templater = Templater::Template.create(apples, 'count', File.join(File.dirname(__FILE__), './apples.yml'))
      expect(templater.finding).to eq('Jeff has the least apples, having only 2')
    end

    it 'can handle more complex yaml' do
      templater = Templater::Template.create(apples, 'count', File.join(File.dirname(__FILE__), './apples_with_conditionals.yml'))
      expect(templater.finding).to eq("Alan has the most apples. It's a lot more than Bob who came in second place.")
    end

    it 'can pass other parameters through' do
      template = {
        'best_name' => 'names.sort[0].key',
        'best_value' => 'names.sort[0].value',
        'text' => {
          'GB_en' => '{{ cat }} apples!'
        }
      }
      templater = Templater::Template.create(apples, 'count', template, 'cat' => 'meow')
      expect(templater.finding).to eq('meow apples!')
    end

    it 'can handle another language, such as French' do
      templater = Templater::Template.create(apples, 'count', File.join(File.dirname(__FILE__), './apples.yml'), {}, :FR)
      expect(templater.finding).to eq("Jeff a le moins de pommes, n'en ayant que 2")
    end

    it 'allows conditionals' do
      templater = Templater::Template.create(apples, 'count', File.join(File.dirname(__FILE__), './apples_with_conditionals.yml'))
      expect(templater.finding).to eq("Alan has the most apples. It's a lot more than Bob who came in second place.")
    end

    it 'can collect all statements' do
      templater = Templater::Template.create(apples, 'count', File.join(File.dirname(__FILE__), './apples_with_conditionals.yml'))
      expect(templater.findings).to eq(['Alan has the most apples.', "It's a lot more than Bob who came in second place."])
    end

    it 'can slice a specific person' do
      template = {
        'count' => 'names.slice("Bob")[0].value',
        'text' => {
          'GB_en' => 'Bob has {{ count }} apples!'
        }
      }
      templater = Templater::Template.create(apples, 'count', template, 'cat' => 'meow')
      expect(templater.finding).to eq('Bob has 4 apples!')
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
      templater = Templater::Template.create(
        tree_data,
        'behaviour_change',
        File.join(File.dirname(__FILE__), './tree.yml'),
        'NAME' => 'Would you change your response to Apple?'
      )
      expect(templater.finding).to eq("Behaviour change was worst for respondents who selected: \n* `West` for `regUS`\n* `Female` for `gender`\n\nfor `Would you change your response to Apple?`")
    end
  end

  context 'helpers' do
    let(:horrible_floats_and_time) do
      [
        { 'time' => Time.new(1993, 02, 24, 12, 0, 0, "+09:00"), 'name' => 'Bob', 'count' => 4.213432 },
        { 'time' => Time.new(1993, 02, 24, 12, 0, 0, "+09:00"), 'name' => 'Alan', 'count' => 14.35 },
        { 'time' => Time.new(1993, 02, 24, 12, 0, 0, "+09:00"), 'name' => 'Jeff', 'count' => 2.1 }
      ]
    end

    it 'can use default handler :round' do
      template = { 'best_value' => 'names.sort[0].value', 'text' => { 'GB_en' => '{{round best_value }}' } }
      templater = Templater::Template.create(horrible_floats_and_time, 'count', template)
      expect(templater.finding).to eq('14.4')
    end

    it 'can use default handler :month' do
      template = { 'month_key' => 'times.sort[0].key', 'text' => { 'GB_en' => '{{month month_key }}' } }
      templater = Templater::Template.create(horrible_floats_and_time, 'count', template)
      expect(templater.finding).to eq('February')
    end

    it 'raises ledgeable error when helper does not exist' do
      template = { 'month_key' => 'times.sort[0].key', 'text' => { 'GB_en' => '{{year month_key }}' } }
      templater = Templater::Template.create(horrible_floats_and_time, 'count', template)
      expect { templater.finding }.to raise_error(/Missing helper: "year"/)
    end

    it 'can have extra handlers added' do
      Templater::Template.handlebars.register_helper(:year) do |_context, condition, _block|
        Time.at(condition).strftime('%Y')
      end

      template = { 'month_key' => 'times.sort[0].key', 'text' => { 'GB_en' => '{{year month_key }}' } }
      templater = Templater::Template.create(horrible_floats_and_time, 'count', template)
      expect(templater.finding).to eq('1993')
    end
  end
end
