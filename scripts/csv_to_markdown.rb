#!/usr/bin/env ruby
# encoding: utf-8

require 'csv'
require 'fileutils'
require 'date'

# CSVからマークダウンファイルを生成
def generate_markdown_files(csv_file, output_dir)
  # 出力ディレクトリが存在しなければ作成
  FileUtils.mkdir_p(output_dir) unless Dir.exist?(output_dir)

  # CSVファイルを読み込む
  csv_data = CSV.read(csv_file, headers: true)

  generated_files = 0

  csv_data.each do |row|
    # 必須データの確認
    next unless row['title'] && !row['title'].empty?

    # 値の取得
    order = row['order'].to_i
    title = row['title']
    date = row['date'] || "2007-10-19"
    content = row['content_text']

    # ISO 8601形式に変換
    begin
      parsed_date = Date.parse(date)
      date_iso = parsed_date.strftime('%Y-%m-%dT%H:%M:%S+09:00')
    rescue
      date_iso = Time.now.strftime('%Y-%m-%dT%H:%M:%S+09:00')
    end

    # ファイル名の決定（括弧を除外）
    filename = "#{order}-#{title.gsub(/（.*）/, '')}.md"
    filepath = File.join(output_dir, filename)

    # マークダウンファイルの内容を生成
    markdown_content = <<~MARKDOWN
    +++
    date = '#{date_iso}'
    title = '#{title}'
    order = #{order}
    +++

    #{content}
    MARKDOWN

    # ファイルに書き込み
    File.write(filepath, markdown_content)

    puts "記事を作成しました: #{filepath}"
    generated_files += 1
  end

  puts "#{generated_files}件の記事ファイルを生成しました。"
end

if __FILE__ == $0
  # デフォルト値
  csv_file = 'posts.csv'
  output_dir = 'content/posts'

  # コマンドライン引数があれば上書き
  if ARGV.length >= 1
    csv_file = ARGV[0]
  end

  if ARGV.length >= 2
    output_dir = ARGV[1]
  end

  if !File.exist?(csv_file)
    puts "エラー: CSVファイル #{csv_file} が見つかりません。"
    exit 1
  end

  # 既存のファイルを削除するかどうかを確認（オプション）
  if Dir.exist?(output_dir) && Dir.glob("#{output_dir}/*").any? && !ARGV.include?("--force")
    puts "警告: 出力ディレクトリ #{output_dir} に既存のファイルが存在します。"
    puts "上書きするには --force オプションを追加してください。"
    exit 1
  elsif Dir.exist?(output_dir) && ARGV.include?("--force")
    puts "出力ディレクトリ #{output_dir} の既存ファイルを削除します..."
    FileUtils.rm_rf(Dir.glob("#{output_dir}/*"))
  end

  generate_markdown_files(csv_file, output_dir)
  puts "変換処理が完了しました"
end
