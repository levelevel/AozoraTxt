# AozoraTxt
[青空文庫](https://www.aozora.gr.jp/)で公開されている文書の全テキストファイルのリポジトリです。ただし著作権が存在するファイルは除いてあります。

https://github.com/aozorabunko/aozorabunko で公開されているものをベースにしています。

テキストファイルだけを欲しい人は[Google Drive](https://drive.google.com/drive/folders/1rgjtxZqPQbOrpM8soGj_wFe_WNk5CStP?usp=sharing)からzipファイルを取得できます（不定期更新）。

## ディレクトリ構成
- person/<作者ID>/<作品ID>\_\<type>_<オリジナルファイル名>.txt  
  zipファイルに格納されているファイルそのままで、管理しやすいようにファイル名のみ変更しています。文字コードはSJIS、改行コードはCRLF（Windows形式）です。
- person_utf8/<作者ID>/<作品ID>\_utf8\_\<type>\_<オリジナルファイル名>.txt  
  上記ファイルの文字コードをUTF8に変換し、外字は可能な限りUTF8に置き換えています。改行コードはLF（Unix形式）です。

  - <作者ID> : 6桁の数値（先頭0埋め）
  - <作品ID> : 1~5桁の数値
  - \<type> : ruby（ルビ入り）またはtxt（ルビ無し）。かつては一つの作品に対してルビ入り・ルビ無しの両方が作成されることがありましたが、現在では底本にルビがあればルビ入り、無ければルビ無しとなります。
  - <オリジナルファイル名> : zipファイル内のtxtファイル名。

https://www.aozora.gr.jp/cards/<作者ID>/card<作品ID>.html  
で該当作品の図書カードにアクセスできます。（IDを二つ入れないといけないのがちょっと難点ですね）

## テキストファイルの更新履歴
青空文庫のリポジトリは2011年5月から現在までほぼ毎日更新されていますが、この間に変更されたテキストファイルの差分（ファイル名の変更含む）はすべて本リポジトリに反映してあります（バグがなければ）。

よって、任意のテキストファイルの差分を見れば、2011年以降の更新履歴を確認することができます。とはいえ、多くのファイルは公開後一度も更新されておらず、一番更新が多いファイルでも7世代となります。

なお、2019年2月までに登録・更新された作品に関しては、最初に登録されたものをRev1、次に更新されたものをRev2、、、Rev9という形で全世代を登録しています（著作権無しの作品に関してはRev7が最大）。それ以降に登録・更新されたものはその都度（ほぼ毎日）登録しています。

## 本リポジトリの更新頻度
本リポジトリの更新作業は手動で行っており、不定期です。

## UTF8版における外字のUnicode変換
例の右側に示すような[青空文庫記法](https://www.aozora.gr.jp/annotation/external_character.html)による外字のうち、JIS句点コードまたはUnicodeが記載されている場合は対応する文字（左側）に変換してあります。
- 𣘹　：　※［＃「木＋寅」、第4水準2-15-31］
- 怰　：　※［＃「りっしんべん＋玄」、U+6030、ページ数-行数］
- ‼　：　※［＃感嘆符二つ、1-8-75］

以下のような青空文庫記法における特殊文字はUnicode変換の対象外となっています。
- 《　：　※［＃始め二重山括弧、1-1-52］　（[ルビ](https://www.aozora.gr.jp/annotation/etc.html#ruby)）
- 》　：　※［＃終わり二重山括弧、1-1-53］（ルビ）
- ［　：　※［＃始め角括弧、1-1-46］   （[注記](https://www.aozora.gr.jp/annotation/)）
- ］　：　※［＃終わり角括弧、1-1-47］ （注記）
- 〔　：　※［＃始めきっこう（亀甲）括弧、1-1-44］　（[アクセント分解](https://www.aozora.gr.jp/annotation/external_character.html#accent)）
- 〕　：　※［＃終わりきっこう（亀甲）括弧、1-1-45］（アクセント分解）
- ｜　：　※［＃縦線、1-1-35］　（ルビ）
- ※　：　※［＃米印、1-2-8］　（[外字](https://www.aozora.gr.jp/annotation/external_character.html)）

「／＼」や「／″＼」のような青空文庫記法の踊り字（[くの字点](https://ja.wikipedia.org/wiki/%E8%B8%8A%E3%82%8A%E5%AD%97#%E3%80%B1%EF%BC%88%E3%81%8F%E3%81%AE%E5%AD%97%E7%82%B9%EF%BC%89)）もUnicodeへ変換は可能ですがそのまま残してあります。
