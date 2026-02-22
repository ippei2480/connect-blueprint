# エスカレーション（VIP顧客対応）フロー

発信者番号をLambdaで顧客DBと照合し、VIP顧客は優先キューへ、一般顧客は通常キューへ振り分けるフロー。

## フロー概要

1. 着信→挨拶
2. Lambda で顧客情報を照合（発信者番号ベース）
3. **VIP**: 優先キューへ転送（優先メッセージ付き）
4. **一般**: 通常のIVRメニューへ

## Mermaid 設計図

```mermaid
graph LR
  greeting("お電話ありがとうございます")
  lookup[/"lambda:lookupCustomer"/]
  check_vip{"VIP判定"}
  vip_msg("いつもご利用ありがとうございます\n優先対応いたします")
  vip_queue["📞 VIPキュー"]
  normal_menu{{"メインメニュー\nTimeout:8\nDTMF:1-2"}}
  q_sales["📞 営業キュー"]
  q_support["📞 サポートキュー"]
  transfer[["キューへ転送"]]
  end1(("切断"))

  greeting --> lookup
  lookup --> check_vip
  check_vip -->|"= vip"| vip_msg
  check_vip -->|"= normal"| normal_menu
  vip_msg --> vip_queue
  vip_queue --> transfer
  normal_menu -->|"Pressed 1"| q_sales
  normal_menu -->|"Pressed 2"| q_support
  normal_menu -->|"Timeout"| end1
  q_sales --> transfer
  q_support --> transfer
  transfer --> end1
```

## 実装のポイント

- `lookupCustomer` Lambda: 発信者番号（`$.CustomerEndpoint.Address`）でDynamoDBを検索し、`customerLevel` を `vip` or `normal` で返す
- VIPキューにはConnect管理画面で高い優先度を設定
- 顧客名が取得できた場合は `vip_msg` に名前を含めることも可能（`UpdateContactAttributes` で属性セット後にテキスト内で参照）
