# Changelog

## [0.3.0] - 2026-02-24

### Fixed
- `SetVoice` → `UpdateContactTextToSpeechVoice` に修正（正しいAWS API ActionType名）
- `SetLoggingBehavior` → `UpdateFlowLoggingBehavior` に修正（正しいAWS API ActionType名）
- `GlobalVoice` → `TextToSpeechVoice` パラメータ名修正
- `LoggingBehavior` → `FlowLoggingBehavior` パラメータ名修正、値を `Enable`/`Disable` → `Enabled`/`Disabled` に修正
- DTMFConfiguration: `FinishOnKey` → `InputTerminationSequence`、`InactivityTimeLimitSeconds` → `InterdigitTimeLimitSeconds` に修正
- 全6サンプルフロー・テンプレートのDTMFConfigurationパラメータ名を修正
- `examples/multilingual/README.md` の `SetVoice` 参照を修正

### Added
- `Loop` ActionType リファレンス追加（自動カウント管理のループ処理）
- `UpdateContactRecordingAndAnalyticsBehavior` ActionType リファレンス追加
- `UpdateContactRecordingBehavior` に AnalyticsBehavior / IVRRecordingBehavior / ScreenRecordedParticipants 設定を追記
- `GetParticipantInput` に `StoreInput` パラメータ・`DisableCancelKey` 設定の説明を追加
- 各ActionTypeに Transitions 仕様（Conditions/Errors の使用可否）を明記
- `references/flow_json_structure.md` に ActionType別 Transitions 仕様表を追加
- `references/mermaid_notation.md` に新しいActionType（Loop, UpdateContactTextToSpeechVoice, UpdateFlowLoggingBehavior, UpdateContactRecordingBehavior, CheckHoursOfOperation, TransferToPhoneNumber）のノード形状を追加
- `references/error_handling_patterns.md` のリトライパターンを `Loop` ActionType 使用に更新（レガシー方式も併記）
- 全6サンプルフローに `UpdateFlowLoggingBehavior` を最初のアクションとして追加
- `scripts/validate.sh` に5項目の新チェックを追加:
  - ActionType ホワイトリストチェック（非推奨名検出）
  - DTMFConfiguration フィールド名検証
  - UpdateFlowLoggingBehavior パラメータ検証
  - UpdateContactTextToSpeechVoice パラメータ検証
  - StartAction が UpdateFlowLoggingBehavior かどうかの警告
- SKILL.md: エラー発生時に aws-mcp で公式ドキュメントを調査する手順を追加
- SKILL.md: 繰り返し処理で Loop ブロックを優先検討するガイドラインを追加
- SKILL.md: Mermaid設計図をファイルとして保存するワークフローを追加
- SKILL.md: フロー最初のアクションに UpdateFlowLoggingBehavior を使用するルールを追加
- SKILL.md: 要件ヒアリング時の録音・分析設定確認項目を追加

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
