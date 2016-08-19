require 'project_metric_slack'

describe ProjectMetricSlack, :vcr do

  let(:svg) { File.read './spec/data/sample.svg' }
  let(:raw_data) { {'an_ju' => 0,
                    'armandofox' => 0,
                    'francis' => 0,
                    'intfrr' => 0,
                    'mtc2013' => 300,
                    'tansaku' => 174} }
  let(:raw_data_two) { {'armandofox' => 0, 'francis' => 0, 'mtc2013' => 0, 'tansaku' => 10} }
  let(:svg_two) { File.read './spec/data/sample_two.svg' }
  let(:svg_equality) { File.read './spec/data/sample_equality.svg' }

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
      expect(metric.score).to eq (0.2890295358649788)
    end

    it 'fetches raw data if not already cached and computes gini' do
      metric = ProjectMetricSlack.new(channel: 'projectscope', token: ENV["SLACK_API_TOKEN"])
      expect(metric.score).to eq (0.2890295358649788)
    end

    it 'uses cached raw_data if it exists' do
      metric = ProjectMetricSlack.new({channel: 'projectscope', token: ENV["SLACK_API_TOKEN"]}, raw_data_two)
      expect(metric.score).to eq (1-0.75)
    end
  end

  context '#image' do
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
      expect(subject.score).to eq (0.2890295358649788)
      subject.raw_data = raw_data_two
      expect(subject.score).to eq (1-0.75)
    end
  end
end