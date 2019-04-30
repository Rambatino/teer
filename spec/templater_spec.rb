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
      expect(templater.finding).to eq('Alan collected 14 apples, higher than anyone else!')
    end

    it 'can handle yaml' do
      templater = Templater::Template.create(apples, 'count', File.join(File.dirname(__FILE__), './apples.yml'))
      expect(templater.finding).to eq('Jeff has the least apples, having only 2')
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
      expect(templater.finding).to eq("Your CHAID performed worst for respondents who selected: \n* `West` for `regUS`\n* `Female` for `gender`\n\nfor `Would you change your response to Apple?`")
    end
  end
end
