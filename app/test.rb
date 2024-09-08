require 'io/console'
require 'pry'

# 克隆仓库到指定路径
def clone_repository(git_url, clone_path)
  clone_command = "git clone #{git_url} #{clone_path}"
  IO.popen(clone_command) do |output|
    binding.pry
    output.each { |line| puts line }
  end
  # 检查进程是否成功结束
  $?.success?
end

# 获取并打印指定仓库的全部 commit 记录
def print_commits(clone_path)
  commits_by_year = {}
  Dir.chdir(clone_path) do
    log_command = "git log --pretty=format:'%H %cd' --date=format:%Y"
    IO.popen(log_command) do |output|
      binding.pry
      output.each do |line|
        sha, year = line.split(' ')
        if year.to_i.between?(2014, 2023)
          # 如果该年份已经有记录，则跳过当前迭代
          next if commits_by_year.key?(year.to_i)
          commits_by_year[year.to_i] = sha
        end
      end
    end
  end
  p commits_by_year
end

git_url = 'https://github.com/soumyaray/YPBT-app.git'
clone_path = './tmp/YPBT-app'

# 克隆仓库
# puts "Cloning repository..."
# if clone_repository(git_url, clone_path)
#   puts "Repository cloned successfully."
# else
#   puts "Failed to clone repository."
#   exit 1
# end

# 打印 commit 记录
puts 'Fetching commits...'
print_commits(clone_path)
