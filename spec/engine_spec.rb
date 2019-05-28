RSpec.describe TemplateEngine::Engine do

  let(:data) do
      [{ 'node_id' => 0, 'label' => Float::NAN, 'question' => Float::NAN, 'answer' => Float::NAN, 'is_terminal' => false, 'base_size' => 250.0, 'behaviour_change' => 7.244, 'overall_appeal' => 1 },
      { 'node_id' => 1, 'label' => 'gender', 'question' => 'gender', 'answer' => 'Male', 'is_terminal' => true, 'base_size' => 100.0, 'behaviour_change' => 7.34, 'overall_appeal' => 2 },
      { 'node_id' => 2, 'label' => 'gender', 'question' => 'gender', 'answer' => 'Female', 'is_terminal' => false, 'base_size' => 150.0, 'behaviour_change' => 7.18, 'overall_appeal' => 5 },
      { 'node_id' => 3, 'label' => 'region', 'question' => 'regUS', 'answer' => 'North East', 'is_terminal' => true, 'base_size' => 117.0, 'behaviour_change' => 7.265, 'overall_appeal' => 1 },
      { 'node_id' => 3, 'label' => 'region', 'question' => 'regUS', 'answer' => 'Mid West', 'is_terminal' => true, 'base_size' => 117.0, 'behaviour_change' => 7.265, 'overall_appeal' => 1 },
      { 'node_id' => 3, 'label' => 'region', 'question' => 'regUS', 'answer' => 'South', 'is_terminal' => true, 'base_size' => 117.0, 'behaviour_change' => 7.265, 'overall_appeal' => 1 },
      { 'node_id' => 3, 'label' => 'gender', 'question' => 'gender', 'answer' => 'Female', 'is_terminal' => true, 'base_size' => 117.0, 'behaviour_change' => 7.265, 'overall_appeal' => 5 },
      { 'node_id' => 4, 'label' => 'region', 'question' => 'regUS', 'answer' => 'West', 'is_terminal' => true, 'base_size' => 33.0, 'behaviour_change' => 6.879, 'overall_appeal' => 9 },
      { 'node_id' => 4, 'label' => 'gender', 'question' => 'gender', 'answer' => 'Female', 'is_terminal' => true, 'base_size' => 33.0, 'behaviour_change' => 6.879, 'overall_appeal' => 20 }]
  end

  let(:data_engine) do
    described_class.new(data, ['behaviour_change', 'overall_appeal'], {}, nil, :GB_en, {})
  end

  context 'can handle all examples' do

    it 'works' do
      expect(data_engine.data.behaviour_change.labels.keys.to_s).to eq(data_engine.data.overall_appeal.labels.keys.to_s)
      expect(data_engine.data.behaviour_changes.mean.round(2)).to eq(7.18)
    end
  end
end
