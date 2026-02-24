# Contributing to connect-blueprint

## 貢献の方法

### バグ報告
- GitHub Issues で報告してください
- フローJSONのサンプルとエラーメッセージを添付してください

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
./scripts/validate.sh <flow.json>

# レイアウト適用
python3 scripts/layout.py <flow.json>
```

## ライセンス

MIT License に基づきます。貢献するコードも同ライセンスが適用されます。
