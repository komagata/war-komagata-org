#!/usr/bin/env ruby
# encoding: utf-8

require 'csv'
require 'nokogiri'
require 'fileutils'
require 'date'

# HTMLファイルから記事を抽出する
def extract_articles_from_html(file_path)
  begin
    html_content = File.read(file_path, encoding: 'UTF-8')
    puts "ファイル #{File.basename(file_path)} を読み込みました"
  rescue
    begin
      html_content = File.binread(file_path).force_encoding('UTF-8').encode('UTF-8', invalid: :replace, undef: :replace)
      puts "ファイル #{File.basename(file_path)} をバイナリで読み込みました"
    rescue => e
      puts "ファイル #{File.basename(file_path)} の読み込みに失敗しました: #{e.message}"
      return []
    end
  end

  doc = Nokogiri::HTML(html_content)

  # ファイル名から章を抽出
  file_base = File.basename(file_path, '.html')

  # 章番号の抽出（正規表現でファイル名から抽出）
  chapter_match = file_base.match(/第(\d+|[一二三四五六七八九十]+)章/)

  unless chapter_match
    puts "ファイル名から章番号を特定できませんでした: #{file_base}"
    return []
  end

  # 漢数字をアラビア数字に変換
  kanji_to_num = {
    '一' => 1, '二' => 2, '三' => 3, '四' => 4, '五' => 5,
    '六' => 6, '七' => 7, '八' => 8, '九' => 9, '十' => 10,
    '十一' => 11, '十二' => 12, '十三' => 13
  }

  number = chapter_match[1]
  chapter_num = kanji_to_num[number] || number.to_i

  # 章のタイトル抽出
  chapter_title = file_base.match(/第.+章\s+(.+)\s+_/) ? file_base.match(/第.+章\s+(.+)\s+_/)[1].strip : ""

  # 章のベースタイトル
  base_title_map = {
    1 => '初めに',
    2 => '召集下令',
    3 => '入隊',
    4 => '出動',
    5 => 'ジャワ島上陸',
    6 => 'ソロモン群島進駐',
    7 => 'ルソン島転進',
    8 => 'マライからビルマへ',
    9 => '雲南作戦',
    10 => '仏領印度支那駐屯',
    11 => '終戦',
    12 => '帰国葛城丸乗船',
    13 => '終わりに'
  }

  base_title = base_title_map[chapter_num] || chapter_title

  # 記事を収集
  articles = []

  # 各記事を抽出（複数記事対応）
  article_elements = doc.css('article')

  if article_elements.empty?
    # 記事要素が見つからない場合は、エントリーコンテンツを探す
    entry_contents = doc.css('div.entry-content')

    if entry_contents.empty?
      # エントリーコンテンツも見つからない場合、単一コンテンツとして処理
      puts "警告: 記事要素が見つかりませんでした。本文全体を1つの記事として処理します。"

      content_text = doc.text.strip
      content_html = doc.to_html

      # 仮のタイトルと番号
      article_title = "#{base_title}"
      article_num = 1
      date = "2007-10-19"

      articles << {
        'order' => "#{chapter_num}.#{article_num}",
        'chapter' => chapter_num,
        'article_num' => article_num,
        'title' => article_title,
        'date' => date,
        'content_html' => content_html,
        'content_text' => content_text
      }
    else
      # 各エントリーコンテンツを処理
      entry_contents.each_with_index do |entry, index|
        content_html = entry.to_html
        content_text = entry.text.strip

        article_num = index + 1
        # 記事が1つしかない場合は番号を付けない
        article_title = entry_contents.length == 1 ? base_title : "#{base_title}（#{number_to_japanese(article_num)}）"

        # 日付の取得（可能であれば）
        date_element = entry.at_xpath('./following::footer//time[@class="entry-date"]')
        date = date_element && date_element['datetime'] ? date_element['datetime'].split('T').first : "2007-10-19"

        articles << {
          'order' => "#{chapter_num}.#{article_num}",
          'chapter' => chapter_num,
          'article_num' => article_num,
          'title' => article_title,
          'date' => date,
          'content_html' => content_html,
          'content_text' => content_text
        }

        puts "章 #{chapter_num} の記事 #{article_num}: #{article_title} を抽出しました"
      end
    end
  else
    # 各記事要素を処理
    article_elements.each_with_index do |article, index|
      # 記事コンテンツを抽出
      content_element = article.at_css('div.entry-content')

      if content_element
        content_html = content_element.to_html
        content_text = content_element.text.strip
      else
        content_html = article.to_html
        content_text = article.text.strip
      end

      article_num = index + 1
      # 記事が1つしかない場合は番号を付けない
      article_title = article_elements.length == 1 ? base_title : "#{base_title}（#{number_to_japanese(article_num)}）"

      # 日付の取得（可能であれば）
      date_element = article.at_css('time.entry-date')
      date = date_element && date_element['datetime'] ? date_element['datetime'].split('T').first : "2007-10-19"

      articles << {
        'order' => "#{chapter_num}.#{article_num}",
        'chapter' => chapter_num,
        'article_num' => article_num,
        'title' => article_title,
        'date' => date,
        'content_html' => content_html,
        'content_text' => content_text
      }

      puts "章 #{chapter_num} の記事 #{article_num}: #{article_title} を抽出しました"
    end
  end

  # スクレイピングで得られた記事が少ない場合は、追加で作成
  # ただし、第一章と第二章は自動分割しない
  if articles.length < 2 && chapter_num < 13 && chapter_num != 1 && chapter_num != 2  # 第一章、第二章、終わりに以外
    puts "警告: #{base_title} の記事が少ないため、追加の記事を仮定します"

    # 既存の記事から内容を分割
    existing_content = articles.first['content_text']
    paragraphs = existing_content.split(/\n\n+/)

    # 十分な段落がある場合は分割
    if paragraphs.length >= 4
      midpoint = paragraphs.length / 2

      first_half = paragraphs[0...midpoint].join("\n\n")
      second_half = paragraphs[midpoint..-1].join("\n\n")

      # 最初の記事を更新
      articles[0]['content_text'] = first_half
      articles[0]['title'] = "#{base_title}（一）"

      # 2つ目の記事を追加
      articles << {
        'order' => "#{chapter_num}.2",
        'chapter' => chapter_num,
        'article_num' => 2,
        'title' => "#{base_title}（二）",
        'date' => articles[0]['date'],
        'content_html' => "<div class=\"entry-content\"><p>#{second_half.gsub("\n\n", "</p><p>")}</p></div>",
        'content_text' => second_half
      }

      puts "章 #{chapter_num} の記事が分割されました: #{base_title}（一）と#{base_title}（二）"
    end
  end

  return articles
end

# 数字を漢数字に変換（1-10）
def number_to_japanese(num)
  case num
  when 1 then '一'
  when 2 then '二'
  when 3 then '三'
  when 4 then '四'
  when 5 then '五'
  when 6 then '六'
  when 7 then '七'
  when 8 then '八'
  when 9 then '九'
  when 10 then '十'
  else num.to_s
  end
end

# メイン処理
def process_archives(archive_dir, output_file)
  # HTMLファイルのリストを取得
  html_files = Dir.glob(File.join(archive_dir, '*.html'))

  puts "#{html_files.size}個のHTMLファイルを処理します..."

  all_articles = []

  html_files.each_with_index do |file_path, index|
    puts "ファイル #{index + 1}/#{html_files.size} を処理中: #{File.basename(file_path)}"

    articles = extract_articles_from_html(file_path)
    all_articles.concat(articles)
  end

  # CSVファイルに保存
  if !all_articles.empty?
    # 章番号とサブ番号でソート
    all_articles.sort_by! do |article|
      [article['chapter'].to_i, article['article_num'].to_i]
    end

    # 通し番号を付け直す
    all_articles.each_with_index do |article, index|
      article['global_order'] = index + 1
    end

    CSV.open(output_file, 'w', headers: true) do |csv|
      csv << ['order', 'title', 'date', 'content_html', 'content_text']

      all_articles.each do |article|
        csv << [
          article['global_order'],
          article['title'],
          article['date'],
          article['content_html'],
          article['content_text']
        ]
      end
    end

    puts "#{all_articles.size}件の記事を#{output_file}に保存しました。"
  else
    puts "保存する記事がありませんでした。"
  end
end

if __FILE__ == $0
  archive_dir = 'archives'
  output_file = 'posts.csv'

  # コマンドライン引数があれば処理を変更
  if ARGV.length >= 1
    archive_dir = ARGV[0]
  end

  if ARGV.length >= 2
    output_file = ARGV[1]
  end

  process_archives(archive_dir, output_file)
  puts "CSVファイルの生成が完了しました。確認をお願いします。"
end
