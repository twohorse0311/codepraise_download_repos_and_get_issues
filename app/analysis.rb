# frozen_string_literal: true

require 'gems'
require 'pry'
require 'figaro'
require 'rest-client'
require 'json'
require 'http'
require 'rubyXL'

module CodePraise
  # Web App
  class App
    def self.run
      access_token = Figaro.env.GITHUB_TOKEN

      repo = 'rubygems/rubygems'

      # Example: Fetch the first page of commits
      all_commits = fetch_commits(repo, access_token, per_page = 20)
      all_commits.each do |commit|
        puts "Commit SHA: #{commit['sha']}"
        puts "Author: #{commit['commit']['author']['name']}"
        puts "Date: #{commit['commit']['author']['date']}"
        puts "Message: #{commit['commit']['message']}"
        puts "\n"
      end
    end
  end
end

def fetch_commits(repo, access_token, per_page = 30)
  all_commits = []
  page = 1
  url = "https://api.github.com/repos/#{repo}/commits?page=#{page}&per_page=#{per_page}"
  response = RestClient.get(url, { 'Authorization' => "token #{access_token}" })
  commits = JSON.parse(response.body)
  all_commits.concat(commits)
end

repo = '/rubygems/rubygems'
access_token = 'your_token_here'
commit_sha = 'f04d50cb1ef527ea91484f4e8e440943a7def582'

def fetch_commit_details(repo, access_token, commit_sha)
  url = "https://api.github.com/repos/#{repo}/commits/#{commit_sha}"
  response = RestClient.get(url, { 'Authorization' => "token #{access_token}" })
  JSON.parse(response.body)
end

# test = fetch_commit_details(repo, access_token, commit_sha)
# p test
# binding.pry

def calculate_metric_for_file(file)
  total_line_credits = file['total_line_credits'] # total_line_credits = file.total_line_credits
  if total_line_credits.zero? || total_line_credits.nil?
    return {
      'readability' => 0,
      'code_smell' => 0,
      'cyclomatic_complexity' => 0,
      'abc_metric' => 0,
      'idiomaticity' => 0,
      'code_churn' => 0
    }
  end
  total_line_credits = total_line_credits.to_f

  readability = file['readability'] || 0 # readability = file.readability || 0
  code_smell = file['code_smells'] && file['code_smells']['offense_ratio'] || 0 # code_smell = file.code_smells&.offenses&.count || 0 # 可能會需要改成 ['code_smells']["offenses"].length
  cyclomatic_complexity = file['idiomaticity'] && file['idiomaticity']['cyclomatic_complexity'] || 0 # cyclomatic_complexity = file.idiomaticity&.cyclomatic_complexity || 0
  abc_metric = file['complexity'] && file['complexity']['average'] || 0 # abc_metric = file.complexity&.average || 0
  idiomaticity = file['idiomaticity'] && file['idiomaticity']['offense_count'] || 0 # idiomaticity = file.idiomaticity&.offense_count || 0
  code_churn = calculate_code_churn_for_file(file, total_line_credits)

  {
    'readability' => (readability / total_line_credits * code_churn) || 0,
    'code_smell' => (code_smell / total_line_credits * code_churn) || 0,
    'cyclomatic_complexity' => (cyclomatic_complexity / total_line_credits * code_churn) || 0,
    'abc_metric' => (abc_metric / total_line_credits * code_churn) || 0,
    'idiomaticity' => (idiomaticity / total_line_credits * code_churn) || 0,
    'code_churn' => code_churn
  }
end

def calculate_metric_for_folder(folder)
  total_files = 0
  total_readability = 0
  total_code_smell = 0
  total_cyclomatic_complexity = 0
  total_abc_metric = 0
  total_idiomaticity = 0
  total_code_churn = 0

  if folder['any_base_files?'] # if folder.any_base_files?
    folder['base_files'].each do |file| # folder.base_files.each do |file|
      metrics = calculate_metric_for_file(file)
      total_files += 1
      total_readability += metrics['readability']
      total_code_smell += metrics['code_smell']
      total_cyclomatic_complexity += metrics['cyclomatic_complexity']
      total_abc_metric += metrics['abc_metric']
      total_idiomaticity += metrics['idiomaticity']
      total_code_churn += metrics['code_churn']
    end
  end

  if folder['any_subfolders?'] # if folder.any_subfolders?
    folder['subfolders'].each do |subfolder| # folder.subfolders.each do |subfolder|
      metrics = calculate_metric_for_folder(subfolder)
      total_files += 1
      total_readability += metrics['total_readability']
      total_code_smell += metrics['total_code_smell']
      total_cyclomatic_complexity += metrics['total_cyclomatic_complexity']
      total_abc_metric += metrics['total_abc_metric']
      total_idiomaticity += metrics['total_idiomaticity']
      total_code_churn += metrics['total_code_churn']
    end
  end

  {
    'total_files' => total_files,
    'total_readability' => total_readability,
    'total_code_smell' => total_code_smell,
    'total_cyclomatic_complexity' => total_cyclomatic_complexity,
    'total_abc_metric' => total_abc_metric,
    'total_idiomaticity' => total_idiomaticity,
    'total_code_churn' => total_code_churn,
    'readability' => total_readability / total_files,
    'code_smell' => total_code_smell / total_files,
    'cyclomatic_complexity' => total_cyclomatic_complexity / total_files,
    'abc_metric' => total_abc_metric / total_files,
    'idiomaticity' => total_idiomaticity / total_files,
    'code_churn' => total_code_churn
  }
end

def calculate_code_churn_for_file(file, total_line_credits)
  code_churn = 0
  filename = file['file_path']['filename'] # filename = file.file_path.filename
  commits = @data['commits'] # commits = @data.content.commits
  commits.each do |commit|
    file_changes = commit['file_changes'] # file_changes = commit.file_changes
    file_changes.each do |file_change|
      if file_change['name'].include?(filename) # if file_change.name.include?(filename)
        code_churn += (file_change['addition'] + file_change['deletion']) # code_churn += (file_change.addition + file_change.deletion)
      end
    end
  end

  code_churn /= total_line_credits.to_f

  code_churn
end

# api_host = "http://0.0.0.0:9090/api/v1/projects"
# proj = "/ruby/openssl"
# url = api_host + proj
# response = RestClient.get(url, {'Authorization' => "token #{access_token}"})
# @data = JSON.parse(response.body)
# @data = JSON.parse(File.read('/Users/twohorse/Desktop/repostore_analysis/ruby_openssl_2015.json'))
# commits_count = @data['commits'].count
# folder = @data['folder']
# results = calculate_metric_for_folder(folder)
# binding.pry
# p results

# Specify the path to the local JSON file

# owner = "ruby"
# proj_name = 'openssl'

require 'find'

# 指定要讀取的資料夾路徑
directory_path = '/Users/twohorse/Desktop/repostore_analysis'

json_files = []

# 列出指定資料夾中的所有檔案（僅第一層），並篩選出 .json 檔案
Dir.entries(directory_path).each do |filename|
  next if ['.', '..'].include?(filename) # 排除目錄自己和上級目錄的連結

  if filename.end_with?('.json') # 檢查檔案是否為 .json 檔案
    json_files.push(filename) # 將檔案名稱添加到數組中
  end
end


# file_path = "#{directory_path}/#{json_files[0]}"
# 印出 .json 檔案的名稱
# puts json_files
# p json_files.length


# 創建一個新的工作簿
workbook = RubyXL::Workbook.new
worksheet = workbook[0]

# 設置標題行的基本欄位
base_columns = ['Owner', 'Project Name', 'Year']
results_keys = nil

# 行計數器初始化為 1（第一行為標題）
row_index = 1

json_files.each do |filename|
  owner, proj_name, year = filename.split('_')[0], filename.split('_')[1], filename.split('_')[2].split('.')[0].to_i
  file_path = "#{directory_path}/#{owner}_#{proj_name}_#{year}.json"

  # 嘗試讀取文件，跳過不存在的文件
  next unless File.exist?(file_path)

  begin
    file = File.read(file_path)
    data = JSON.parse(file)

    file_scores = data['folder']
    git_info = data['commits']
    p "------ Get total issues of #{owner}/#{proj_name} in #{year} ------"
    # total_issues = get_issue("#{owner}/#{proj_name}", year)
    # git_info['total_issues'] = total_issues

    # 如果是第一次循環，則設置結果的 keys 並且創建標題行
    if results_keys.nil?
      file_scores_keys = file_scores.keys
      git_info_keys = git_info.keys
      results_keys = file_scores_keys + git_info_keys
      all_columns = base_columns + results_keys
      all_columns.each_with_index { |key, index| worksheet.add_cell(0, index, key) }
    end

    # 添加基本資料到工作表
    worksheet.add_cell(row_index, 0, owner)
    worksheet.add_cell(row_index, 1, proj_name)
    worksheet.add_cell(row_index, 2, year)

    # 添加結果資料到工作表
    results_keys.each_with_index do |key, index|
      value = file_scores[key] || git_info[key]
      worksheet.add_cell(row_index, base_columns.length + index, value)
    end

    # 更新行索引
    row_index += 1
  rescue JSON::ParserError => e
    puts "Error parsing JSON file #{file_path}: #{e.message}"
  end
end

# 儲存工作簿
workbook.write('/Users/twohorse/Desktop/test_result.xlsx')
