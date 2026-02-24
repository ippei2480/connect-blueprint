# Connect Blueprint — エラーハンドリングパターン集

## 基本原則

1. **すべてのActionにエラー遷移を設定する** — エラー未設定のActionがあるとフローが停止する
2. **最終的に必ず DisconnectParticipant に到達させる** — 無限ループやデッドエンドを防ぐ
3. **NoMatchingError は最後の砦** — 想定外エラーのキャッチオール

## ErrorType 一覧

| ErrorType | 発生するAction | 説明 |
|-----------|---------------|------|
| `NoMatchingError` | 全ActionType | 想定外のエラー（キャッチオール） |
| `NoMatchingCondition` | GetParticipantInput, Compare | どの条件にも一致しない入力 |
| `InputTimeLimitExceeded` | GetParticipantInput | 入力タイムアウト |
| `QueueAtCapacity` | TransferContactToQueue | キューが満杯 |
| `NoMatchingError` | InvokeLambdaFunction | Lambda実行エラー |

## パターン1: リトライ付きIVRメニュー

入力エラー時に最大N回リトライし、超過したら切断する。

### 推奨: Loop ActionType 使用（自動カウント管理）

```mermaid
graph LR
  loop{"🔁 ループ:3回"}
  menu{{"メニュー\nTimeout:8\nDTMF:1-2"}}
  sorry("おつなぎできません")
  end1(("切断"))

  loop -->|"ContinueLooping"| menu
  loop -->|"DoneLooping"| sorry
  menu -->|"Timeout"| loop
  menu -->|"NoMatch"| loop
  sorry --> end1
```

**実装方法**: `Loop` ActionType で `LoopCount` を指定。`ContinueLooping` 条件でメニューに遷移し、`DoneLooping` 条件でエラーメッセージに遷移する。カウンタの手動管理が不要。

### レガシー: UpdateContactAttributes + Compare（手動カウンタ）

```mermaid
graph LR
  menu{{"メニュー\nTimeout:8\nDTMF:1-2"}}
  retry_msg("もう一度お選びください")
  retry_check{"リトライ回数判定"}
  sorry("おつなぎできません")
  end1(("切断"))

  menu -->|"Timeout"| retry_msg
  menu -->|"NoMatch"| retry_msg
  retry_msg --> retry_check
  retry_check -->|"< 3"| menu
  retry_check -->|">= 3"| sorry
  sorry --> end1
```

**実装方法**: `UpdateContactAttributes` でカウンタ属性をインクリメントし、`Compare` で判定する。Loop ActionType が使えない場合の代替手段。

## パターン2: Lambda エラー時のフォールバック

Lambda失敗時は直接キューに転送する（機能を縮退させて継続）。

```mermaid
graph LR
  lambda[/"lambda:getCustomerInfo"/]
  personalized("お客様情報あり")
  generic("お電話ありがとうございます")
  transfer[["キューへ転送"]]

  lambda --> personalized
  lambda -->|"Error"| generic
  personalized --> transfer
  generic --> transfer
```

## パターン3: キュー満杯時のフォールバック

主キューが満杯の場合、代替キューまたはコールバックへ誘導する。

```mermaid
graph LR
  transfer1[["主キューへ転送"]]
  fallback_msg("ただいま大変混み合っております")
  transfer2[["代替キューへ転送"]]
  end1(("切断"))

  transfer1 --> end1
  transfer1 -->|"QueueAtCapacity"| fallback_msg
  fallback_msg --> transfer2
  transfer2 --> end1
  transfer2 -->|"QueueAtCapacity"| end1
```

## パターン4: 営業時間チェックエラー時のデフォルト動作

CheckHoursOfOperation のエラー時は営業時間内として扱う（サービス優先）。

```mermaid
graph LR
  hours{"営業時間判定"}
  menu{{"メインメニュー"}}
  after_hours("営業時間外です")

  hours -->|"= True"| menu
  hours -->|"= False"| after_hours
  hours -->|"Error"| menu
```

## アンチパターン

### エラー遷移なし
```json
{
  "Transitions": {
    "NextAction": "next-uuid"
  }
}
```
→ エラー発生時にフローが停止する。必ず `Errors` 配列を含める。

### 無限ループのリトライ
カウンタなしでエラー → 同じメニューに戻すと無限ループになる。
→ 必ず `Loop` ActionType またはカウンタで回数を制限する。

### DisconnectParticipant への遷移忘れ
全パスが最終的に DisconnectParticipant に到達することを確認する。
→ `scripts/validate.sh` でチェック可能。
