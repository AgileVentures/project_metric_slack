require 'project_metric_slack'

describe ProjectMetricSlack, :vcr do

  let(:svg) { File.read './spec/data/sample.svg' }
  let(:raw_data) { {"tansaku" => 9, "mtc2013" => 8, "jinksy" => 0, "marouen" => 2, "ksteph" => 1, "an_ju" => 2, "armandofox" => 2, "marianmosley" => 0, "nickn" => 0, "arun1595" => 0, "intfrr" => 0, "slackbot" => 0} }
  let(:raw_data_two) { {'armandofox' => 0, 'francis' => 0, 'mtc2013' => 0, 'tansaku' => 10} }
  let(:svg_two) { File.read './spec/data/sample_two.svg' }
  let(:svg_equality) { File.read './spec/data/sample_equality.svg' }

  before { Time.stub_chain(:zone, :now) { Time.new(2016, 9, 7, 1, 12, 39, 0) } }

  context '#raw_data' do
    it 'fetches raw data' do
      metric = ProjectMetricSlack.new(channel: 'projectscope', token: ENV["SLACK_API_TOKEN"])
      metric.refresh
      expect(metric.raw_data).to eq(raw_data)
    end
  end

  context '#score' do
    it 'returns gini coefficient for cached raw_data' do
      metric = ProjectMetricSlack.new({channel: 'projectscope', token: ENV["SLACK_API_TOKEN"]}, raw_data)
      expect(metric.score).to eq (0.29861111111111116)
    end

    it 'fetches raw data if not already cached and computes gini' do
      metric = ProjectMetricSlack.new(channel: 'projectscope', token: ENV["SLACK_API_TOKEN"])
      expect(metric.score).to eq (0.29861111111111116)
    end

    it 'uses cached raw_data if it exists' do
      metric = ProjectMetricSlack.new({channel: 'projectscope', token: ENV["SLACK_API_TOKEN"]}, raw_data_two)
      expect(metric.score).to eq (1-0.75)
    end
  end

  context '#image' do
    let(:svg_many) { File.read './spec/data/many.svg' }
    it 'provides expected image using cached raw_data' do
      metric = ProjectMetricSlack.new({channel: 'projectscope', token: ENV["SLACK_API_TOKEN"]}, raw_data)
      expect(metric.image).to eq svg
    end

    it 'fetches raw data if not already cached and then computes image' do
      metric = ProjectMetricSlack.new channel: 'projectscope', token: ENV["SLACK_API_TOKEN"]
      expect(metric.image).to eq svg
    end

    it 'uses cached raw_data if it exists' do
      metric = ProjectMetricSlack.new({channel: 'projectscope', token: ENV["SLACK_API_TOKEN"]}, raw_data_two)
      expect(metric.image).to eq svg_two
    end

    it 'deals gracefully with max = min' do
      metric = ProjectMetricSlack.new({channel: 'projectscope', token: ENV["SLACK_API_TOKEN"]}, {'armandofox' => 5, 'mtc2013' => 5})
      expect(metric.image).to eq svg_equality
    end

    it 'tries to make the graph at least twice as wide as tall if there are more than 9' do
      metric = ProjectMetricSlack.new({channel: 'projectscope', token: ENV["SLACK_API_TOKEN"]},
                                      {'armandofox' => 5, 'mtc2013' => 5, 'marian' => 5, 'marianscat' => 3,
                                       'randompenguin' => 1, 'ghost' => 4, 'othercat' => 2, 'pikachu' => 1,
                                       'blastoise' => 5, 'hitmonchan' => 4, 'magmar' => 3, 'meowth' => 2,
                                       'pidgy' => 2, 'scyther' => 3, 'abra' => 4, 'wartortle' => 1,
                                       'raticate' => 4, 'hypno' => 5, 'eevee' => 3, 'vaporeon' => 5})
      expect(metric.image).to eq svg_many
    end
  end

  context '#raw_data=' do
    let(:subject) { ProjectMetricSlack.new(channel: 'projectscope', token: ENV["SLACK_API_TOKEN"]) }

    it 'sets raw_data appropriately' do
      subject.raw_data = raw_data
      expect(subject.raw_data).to eq raw_data
    end

    it 'sets image as uncached' do
      expect(subject.image).to eq svg
      subject.raw_data = raw_data_two
      expect(subject.image).to eq svg_two
    end

    it 'sets score as uncached' do
      expect(subject.score).to eq (0.29861111111111116)
      subject.raw_data = raw_data_two
      expect(subject.score).to eq (1-0.75)
    end
  end
end
