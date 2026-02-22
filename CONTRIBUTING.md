# Contributing to connect-blueprint

## 貢献の方法

### バグ報告
- GitHub Issues で報告してください
- フローJSONのサンプルとエラーメッセージを添付してください

### サンプルフローの追加
1. `examples/<flow-name>/` ディレクトリを作成
2. `README.md` — フロー概要、Mermaid図、実装のポイント
3. `flow.json` — デプロイ可能なフローJSON（プレースホルダーARN使用可）
4. バリデーション通過を確認: `./scripts/validate.sh examples/<flow-name>/flow.json`

### リファレンスの追加・修正
- `references/` 配下にMarkdownファイルとして追加
- Amazon Connect の公式ドキュメントに基づく正確な情報のみ記載

### コーディング規約
- フローJSON内のIdentifierはUUID v4形式
- プレースホルダーARNは `<YOUR_XXX_ARN>` 形式
- Mermaid図は `references/mermaid_notation.md` の記法に従う
- コミットメッセージは日本語・英語どちらでもOK

## 開発環境

```bash
# リポジトリのクローン
git clone https://github.com/ippei2480/connect-blueprint.git
cd connect-blueprint

# バリデーション実行
./scripts/validate.sh examples/business-hours-routing/flow.json

# レイアウト適用
python3 scripts/layout.py examples/business-hours-routing/flow.json
```

## ライセンス

MIT License に基づきます。貢献するコードも同ライセンスが適用されます。
