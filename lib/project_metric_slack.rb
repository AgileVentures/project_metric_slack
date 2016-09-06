require 'slack'
require 'color_functions'

class ProjectMetricSlack

  attr_reader :raw_data

  def initialize credentials, raw_data=nil
    @raw_data = raw_data
    @channel = credentials[:channel]
    @client = Slack::Web::Client.new(token: credentials[:token])
  end

  def score
    return @score if @score
    refresh unless @raw_data
    @score = (1-gini_coefficient(@raw_data.values))
  end

  def image
    return @image if @image
    refresh unless @raw_data
    normalized_member_scores = normalize_member_scores(@raw_data)
    @member_colors = compute_member_hex_colors_for_heatmap(normalized_member_scores)
    file_path = File.join(File.dirname(__FILE__), 'svg.erb')
    @image_width = 3
    @image_width = Math.sqrt(@member_colors.length * 0.5).ceil*2 if @member_colors.length > 9
    @image = ERB.new(File.read(file_path), nil, '-').result(self.send(:binding))
    # File.open(File.join(File.dirname(__FILE__), 'many.svg'), 'w') { |f| f.write @image}
  end

  def refresh
    @raw_data = get_slack_message_totals
    true
  end

  def raw_data=(new)
    @raw_data = new
    @score = @image = nil
  end

  private

  def gini_coefficient(array)
    sorted = array.sort
    n = sorted.length
    temp = (0..(n-1)).inject(0.0) { |memo, i| memo += (n-i)*sorted[i] }
    return (n+1).to_f / n - 2.0 * temp / ((array.sum)*n)
  end

  def compute_member_hex_colors_for_heatmap normalized_member_scores
    normalized_member_scores.inject({}) do |member_colors, (name, norm_score)|
      member_colors.merge name => Color::rgb_to_hex(Color::score_to_rgb(norm_score))
    end
  end

  def get_slack_message_totals
    start_date = (Time.now - (7+Time.now.wday+1).days).to_date
    end_date = (Time.now - (Time.now.wday).days).to_date
    member_names_by_id = get_member_names_by_id
    id = @client.channels_list['channels'].detect { |c| c['name'] == @channel }.id
    history = @client.channels_history(channel: id)
    history.messages.inject(Hash.new(0)) do |slack_message_totals, message|
      add_to_total = 0
      add_to_total = 1 if start_date < Time.at(message.ts.to_i).to_date && Time.at(message.ts.to_i).to_date < end_date
      slack_message_totals.merge member_names_by_id[message.user] => slack_message_totals[message.user] + add_to_total
    end
  end

  def get_member_names_by_id
    members = @client.users_list.members
    members.inject({}) do |collection, member|
      collection.merge member.id => member.name
    end
  end

  def normalize_member_scores member_scores
    min = member_scores.values.min
    max = member_scores.values.max
    diff = [(max - min), 1].max.to_f
    member_scores.inject({}) do |normalized_member_scores, (name, num_messages)|
      normalized_member_scores.merge name => (num_messages - min)/diff
    end
  end
end
