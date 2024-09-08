require 'gems'
require 'pry'
require 'figaro'
require 'rest-client'
require 'json'
require 'http'
require 'rubyXL'
require 'roo'
require 'git'

def post(url)
  http_response = HTTP.headers(
    'Accept' => 'application/vnd.github.v3+json'
  ).post(url)
  Response.new(http_response).tap do |response|
    raise(response.error) unless response.successful?
  end
end

def get(url, param = { clone_over: 0, log_history: 0, deep_appraise: 1 })
  http_response = HTTP.headers('Accept' => 'application/vnd.github.v3+json').get(url, params: param)

  Response.new(http_response).tap do |response|
    raise(response.error) unless response.successful?
  end
end

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

# url = 'http://0.0.0.0:9090/api/v1/projects/fxposter/carrierwave-processing'
# post(url)

# 打開 Excel 文件
xlsx = Roo::Excelx.new('/Users/twohorse/Desktop/gems_final_list.xlsx')

# 選擇第一個工作表
xlsx.default_sheet = xlsx.sheets.first

# 使用一个范围来选择第 2 行到第 4 行
# (7..50).each do |index|

# (91..200).each do |index|
(231..240).each do |index|
  row = xlsx.row(index + 1) # 加 1 是因为 row 方法的索引从 1 开始
  owner = row[3]
  project_name = row[4]
  folder_name = "#{owner}_#{project_name}"

  # selected_data = [row[1], row[2]].join('/') # row 数组的索引从 0 开始，所以 1 和 2 分别是第二个和第三个单元格
  puts "----------#{folder_name}----------"
  url = "http://0.0.0.0:9090/api/v1/projects/#{owner}/#{project_name}"

  begin
    p "post: #{folder_name}..."
    post(url)
  rescue Response::NotFound => e
    p "post 時出問題，找不到 #{folder_name}"
    next
  rescue Response::DBError => e
    p "post 時出問題，DB 裡應該有 #{folder_name} 了，直接去 get"
  end

  begin
    p "get: #{folder_name}..."
    if File.exist?("/Users/twohorse/Desktop/repostore_temp/#{folder_name}")
      p "有 clone 過"
      get(url)
    else
      p "沒 clone 過"
      get(url, param = { clone_over: 1 })
    end
  rescue Response::NotFound => e
    p "get 時出問題，找不到 #{folder_name}(可能又是大小寫問題)"
    next
  end
end

#################################

# require 'roo'
# require 'git'
# require 'write_xlsx'

# # 開啟現有的 Excel 文件
# xlsx = Roo::Excelx.new('/Users/twohorse/Desktop/gem_weired.xlsx')
# xlsx.default_sheet = xlsx.sheets.first

# # 創建新的 Excel 文件
# workbook = WriteXLSX.new('/Users/twohorse/Desktop/commit_info_weired.xlsx')
# worksheet = workbook.add_worksheet

# # 寫入標題行
# worksheet.write(0, 0, 'Folder Name')
# worksheet.write(0, 1, 'First Commit Date')
# worksheet.write(0, 2, 'Last Commit Date')

# # 遍歷每一行 1..xlsx.last_row
# (1..xlsx.last_row).each_with_index do |index, row_idx|
#   puts "第#{index}筆"
#   row = xlsx.row(index+1)
#   folder_name = row[0]
#   repo_path = "/Users/twohorse/Desktop/repostore_temp/#{folder_name}"
#   first_commit_temp = `git -C #{repo_path} log --reverse`
#   first_commit_temp.force_encoding('ASCII-8BIT').encode!('UTF-8', invalid: :replace, undef: :replace, replace: '')
#   first_commit = first_commit_temp.split("\n").find{|element| element.include?("Date")}.split(" ").tap(&:shift).join(" ")
#   puts "#{folder_name}第一次 commit 時間：#{first_commit}"
#   last_log_temp = `git -C #{repo_path} log`
#   last_log_temp.force_encoding('ASCII-8BIT').encode!('UTF-8', invalid: :replace, undef: :replace, replace: '')
#   last_commit = last_log_temp.split("\n").find{|element| element.include?("Date")}.split(" ").tap(&:shift).join(" ")
#   puts "#{folder_name}最後一次 commit 時間：#{last_commit}"

#   # g = Git.open(repo_path)
#   # all_commits = g.log
#   # last_commit = all_commits.last.date.to_s
#   # first_commit = all_commits.first.date.to_s

#   # 將數據寫入新的 Excel 文件
#   worksheet.write(row_idx + 1, 0, folder_name)
#   worksheet.write(row_idx + 1, 1, first_commit)
#   worksheet.write(row_idx + 1, 2, last_commit)
# end

# # 關閉並保存文件
# workbook.close
