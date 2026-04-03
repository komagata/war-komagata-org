# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

祖父の大東亜戦争従軍手記をWeb公開するJekyllサイト（https://war.komagata.org/）。
GitHub Pages組み込みのJekyllでビルド・デプロイされる。

## コマンド

```bash
# 依存インストール
bundle install

# 開発サーバー起動
bundle exec jekyll serve

# ビルド（_site/に出力）
bundle exec jekyll build
```

## アーキテクチャ

- **Jekyll静的サイト** — GitHub Pages（`github-pages` gem）でビルド
- **コンテンツ**: `_pages/` コレクションに章ごとのMarkdownファイル（YAML frontmatterの `order` フィールドで表示順を制御）
- **レイアウト**: `_layouts/`（`default.html`, `page.html`）
- **CSS**: `assets/css/main.css`
- **画像**: `images/`
- **データ変換スクリプト**: `scripts/` にRuby/Bashスクリプト（元データからの変換用、参考資料）

## コンテンツ構造

各Markdownファイルのフロントマター形式:
```yaml
---
title: "初めに"
date: 2007-09-09
order: 1
---
```

章名と番号（漢数字）でファイル名が構成される（例: `雲南作戦-一.md`）。
トップページでは `order` フィールドの昇順で全記事を一覧表示。
