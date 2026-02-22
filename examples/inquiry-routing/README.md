# 問い合わせ種別振り分けフロー

問い合わせの種類（請求・技術サポート・契約変更・その他）に応じて適切なキューに振り分けるフロー。

## フロー概要

1. 着信→挨拶
2. 問い合わせ種別をDTMFで選択（1〜4）
3. 種別に応じた属性設定 + キュー振り分け
4. キューへ転送

## Mermaid 設計図

```mermaid
graph LR
  greeting("お電話ありがとうございます")
  menu{{"お問い合わせ種別\n請求:1 技術:2\n契約:3 その他:4\nTimeout:10\nDTMF:1-4"}}
  attr_billing["inquiry_type=billing"]
  attr_tech["inquiry_type=technical"]
  attr_contract["inquiry_type=contract"]
  attr_other["inquiry_type=other"]
  q_billing["📞 請求キュー"]
  q_tech["📞 技術サポートキュー"]
  q_contract["📞 契約キュー"]
  q_general["📞 総合キュー"]
  transfer[["キューへ転送"]]
  retry("もう一度お選びください")
  end1(("切断"))

  greeting --> menu
  menu -->|"Pressed 1"| attr_billing
  menu -->|"Pressed 2"| attr_tech
  menu -->|"Pressed 3"| attr_contract
  menu -->|"Pressed 4"| attr_other
  menu -->|"Timeout"| retry
  menu -->|"NoMatch"| retry
  attr_billing --> q_billing
  attr_tech --> q_tech
  attr_contract --> q_contract
  attr_other --> q_general
  q_billing --> transfer
  q_tech --> transfer
  q_contract --> transfer
  q_general --> transfer
  retry --> menu
  transfer --> end1
```

## 実装のポイント

- `inquiry_type` 属性を設定することで、エージェントのCCP画面に問い合わせ種別が表示される
- リトライは1回のみ（無限ループ防止のため、実運用ではカウンタ属性で制御）
- 種別ごとにスキルベースルーティングを組み合わせると、より適切なエージェントにつながる
