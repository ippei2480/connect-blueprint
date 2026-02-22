# Changelog

## [0.2.0] - 2025-02-22

### Added
- サンプルフロー6種追加
  - 営業時間内外振り分けフロー (`examples/business-hours-routing/`)
  - コールバック予約フロー (`examples/callback-reservation/`)
  - 顧客満足度アンケート（NPS）フロー (`examples/nps-survey/`)
  - エスカレーション（VIP顧客対応）フロー (`examples/vip-escalation/`)
  - 多言語対応フロー（日本語/英語）(`examples/multilingual/`)
  - 問い合わせ種別振り分けフロー (`examples/inquiry-routing/`)
- バリデーションスクリプト (`scripts/validate.sh`) — ローカル＋AWS両対応
- `CHANGELOG.md` 追加
- `CONTRIBUTING.md` 追加
- エラーハンドリングパターン集 (`references/error_handling_patterns.md`)
- SKILL.md にトラブルシューティングセクション追加

## [0.1.0] - 2025-02-20

### Added
- 初回リリース
- SKILL.md（モードA/B対応）
- Mermaid記法ガイド
- ActionTypeリファレンス
- フローJSON構造仕様
- AWS CLIコマンドリファレンス
- レイアウトアルゴリズム（`scripts/layout.py`）
