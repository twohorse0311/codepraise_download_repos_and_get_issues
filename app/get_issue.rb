require 'gems'
require 'pry'
require 'figaro'
require 'rest-client'
require 'json'
require 'http'
require 'rubyXL'
require 'roo'

class Response < SimpleDelegator
  Unauthorized = Class.new(StandardError)
  NotFound = Class.new(StandardError)
  DBError = Class.new(StandardError)

  HTTP_ERROR = {
    401 => Unauthorized,
    404 => NotFound,
    500 => DBError
  }.freeze

  def successful?
    HTTP_ERROR.key?(code) ? false : true
  end

  def error
    HTTP_ERROR[code]
  end
end

def get(url)
  Figaro.application = Figaro::Application.new(
      environment: ENV['RACK_ENV'] || 'development',
      path: File.expand_path('config/secrets.yml')
    )
  Figaro.load
  access_token = Figaro.env.GITHUB_TOKEN
  http_response = HTTP.headers(
    'Accept' => 'application/vnd.github.v3+json',
    'Authorization' => "Bearer #{access_token}"
  ).get(url)

  Response.new(http_response).tap do |response|
    raise(response.error) unless response.successful?
  end
  http_response
end

def get_issue(repo, year)
  start_date = "#{year}-01-01T00:00:00Z"
  url = "https://api.github.com/repos/#{repo}/issues?state=closed&since=#{start_date}"
  total_issues = []
  page = 1
  loop do
    response = get(url + "&per_page=100&page=#{page}")
    break if response.body.nil? || response.body.empty?

    issues = JSON.parse(response.body)
    break if issues.empty?

    page += 1
    total_issues.concat(issues)
  end
  total_issues.map { |issue| Time.parse(issue['created_at']).year }
              .group_by { |year| year }
              .tap { |grouped| grouped.transform_values!(&:size) }
end

# repo = 'brianmario/mysql2'
# total_issues = get_issue(repo, 2015)
# p "total issues: #{total_issues}"

def get_full_name_years(file_path)
  # 讀取 Excel 文件
  xlsx = Roo::Excelx.new(file_path)

  # 讀取標題行，找到所需欄位的索引
  headers = xlsx.row(1)
  full_name_index = headers.index('full_name') + 1
  year_index = headers.index('Year') + 1

  # 初始化哈希來儲存結果
  full_name_years = {}

  # 迭代每一行數據
  xlsx.each_row_streaming(offset: 1) do |row|
    full_name = row[full_name_index - 1].cell_value
    year = row[year_index - 1].cell_value.to_i

    # 如果哈希中還沒有這個 full_name，則添加它
    if !full_name_years.key?(full_name)
      full_name_years[full_name] = [year]
    else
      full_name_years[full_name] << year unless full_name_years[full_name].include?(year)
    end
  end

  full_name_years
end

file_path = '/Users/twohorse/Desktop/test_result.xlsx'
result = get_full_name_years(file_path)
result.each_with_index do |(full_name, years), index|

  # next if index < 5
  puts "第 #{index} 筆"
  puts "----- 取得 #{full_name} 的 issue 中 -----"
  all_issues = get_issue(full_name, years.first) # 得到一個 {年份： issues 數量} 的 hash
  puts "----- 順利取得 #{full_name} issues -----"
  years.each do |year|
    puts "***** 處理 #{full_name} #{year} 的資料...... *****"
    file_path = "/Users/twohorse/Desktop/repostore_analysis/#{full_name.split("/")[0]}_#{full_name.split("/")[1]}_#{year}.json"
    analysis_result_josn = File.read(file_path)
    analysis_result = JSON.parse(analysis_result_josn)
    analysis_result["commits"]["issues"] = all_issues[year] || 0
    analysis_result_add_issue = JSON.pretty_generate(analysis_result)
    File.open(file_path, 'w') do |file|
      file.write(analysis_result_add_issue)
    end
    puts "***** 處理完成 #{full_name} #{year} 的資料！ *****"
  end
end

