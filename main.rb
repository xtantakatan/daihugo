

class Player
  def initialize(ranking = 0, is_cpu = false)
    @ranking = ranking
    @is_cpu = is_cpu
    @hand_cards = []
  end

  def set_card(cards)
    # 強さ順にソートして格納
    cards
    @hand_cards = cards
  end

  def show_hand_cards
    @hand_cards.map { |card| card.show_label }.join(", ")
  end

  def play_cards(cards_label)
    cards = []
    # 手持ちのカードからcards_labelのカードを排出する
    if cards_label == ["joker"]
      joker = @hand_cards.find do |card|
        card.suit == "joker"
      end
      # 場に出すカードをハンドから削除
      @hand_cards.delete(joker)

      cards << joker
    else
      cards_label.each do |card_label|
        suit_label = card_label.match(/[DCSH]/)[0]
        number = card_label.match(/([\d]|[JQKA])/)[0]
        card = @hand_cards.find do |card|
          card.number == number && card.suit_label == suit_label
        end
        # 場に出すカードをハンドから削除
        @hand_cards.delete(card)

        cards << card
      end
    end

    cards
  end

  def cpu_action(cards)
    puts "CPU、考え中"
    # ひとまず、手元のハンドから出せるものの中から一番弱いカードを提出
    # 提出できるものが無かったらパス（空配列）

    # 例
    # D4がきたから
    case action_type(cards)
    when "NonCard"
      # 場にカードがないので一番弱いカードを出す。
      playable_cards = @hand_cards.group_by { |card| card.number }.first[1]

      if playable_cards.count == 1
        return playable_cards.first.show_label
      else

        return playable_cards.map {|card| card.show_label }.join(", ")
      end
    when "Single"
      # 例：C3を出したら4以上のカードを出す
      card_number_strength = Card::STRENGTH[cards.first.number]
      playable_card = @hand_cards.select do |card|
        card_number_strength < Card::STRENGTH[card.number]
      end

      # 一番弱いカードを出す
      # とりあえずsuitは考慮しない
      if playable_card.nil?
        return "Pass"
      end

      return playable_card.first.show_label
    when "TwoCard"
      # 例：C3, H3を出したら4以上のツーペアを出す
      group_by_number = @hand_cards.group_by { |card| card.number }
      card_number_strength = Card::STRENGTH[cards.first.number]

      playable_cards_set = group_by_number.select do |number, cards|
        cards.count >= 2 &&
            card_number_strength < Card::STRENGTH[number]
      end
      # 一番弱いセットを出す
      # とりあえずsuitは考慮しない
      if playable_cards_set.empty?
        return "Pass"
      end

      return playable_cards_set.first[1][0..1].map {|card| card.show_label }.join(", ")
    when "ThreeCard"
      group_by_number = @hand_cards.group_by { |card| card.number }
      card_number_strength = Card::STRENGTH[cards.first.number]

      playable_cards_set = group_by_number.select do |number, cards|
        cards.count >= 3 &&
            card_number_strength < Card::STRENGTH[number]
      end
      # 一番弱いセットを出す
      # とりあえずsuitは考慮しない
      if playable_cards_set.empty?
        return "Pass"
      end

      return playable_cards_set.first[1][0..2].map {|card| card.show_label }.join(", ")
    when "FourCard"
    when "Sequence"
    end
    puts "error"
  end

  def action_type(cards)
    if cards.count == 0
      # passで流れるなどで場にカードがない
      return "NonCard"
    end


    if cards.count == 1
      return "Single"
    end

    # カード2枚で、同じ数字
    if cards.count == 2 && cards.all? { |card| cards.first.number == card.number }
      return "TwoCard"
    end

    if cards.count == 3 && cards.all? { |card| cards.first.number == card.number }
      return "ThreeCard"
    end

    if cards.count == 4 && cards.all? { |card| cards.first.number == card.number }
      # 革命
      return "FourCard"
    end

    if cards.all? { |card| cards.first.suit == card.suit }
      return "Sequence"
    end

  rescue => e
  end


end

class Card
  STRENGTH = {"3" => 1, "4" => 2, "5" => 3, "6" => 4, "7" => 5,
              "8" => 6, "9" => 7, "10" => 8, "J" => 9, "Q" => 10,
              "K" => 11, "A" => 12, "2" => 13, "joker" => 14}

  def initialize(suit, number)
    @suit = suit
    @number = number
  end

  def number
    @number
  end

  def number_rank
    STRENGTH[@number]
  end

  def suit
    @suit
  end

  def suit_label
    case @suit
    when "Spade"
      "S"
    when "Clover"
      "C"
    when "Diamond"
      "D"
    when "Heart"
      "H"
    end
  end

  def show_label
    case @suit
    when "Spade"
      "S#{@number}"
    when "Clover"
      "C#{@number}"
    when "Diamond"
      "D#{@number}"
    when "Heart"
      "H#{@number}"
    when "joker"
      "joker"
    end
  end
end

class DaiFugoGame
  CARDS = []
  %w(3 4 5 6 7 8 9 10 J Q K A 2).each do |card_number|
    %w(Spade Clover Diamond Heart).each do |card_suit|
      CARDS << Card.new(card_suit, card_number)
    end
  end

  #Joker2枚
  CARDS << Card.new("joker", "joker")
  CARDS << Card.new("joker", "joker")

  def initialize()
    @players = []
    # カード情報のディープコピー、まぁ単体で遊ぶだけだったらやらなくてもいいけど。
    @cards = Marshal.load(Marshal.dump(CARDS))
    @cards.shuffle!
  end

  def game_start(player_count:)
    # プレイヤーの追加設定
    player_count.times do |num|
      if num.zero?
        @players << Player.new(0, false)
      else
        @players << Player.new(0, true)
      end
    end

    # カードの配布
    distribute_card
    cards = [] # スコープをループの外にする
    passes = [] # passがplayer数-1溜まったら場のカードをリセットする

    while true do
      puts "あなたの番です。カードを選んでください。"
      puts "あなたの手札は、"
      # ひとまず@players[0]が人間で固定
      puts @players[0].show_hand_cards
      action_hand = gets.chomp.gsub(" ", "")

      if action_hand != "Pass" && action_hand != "pass"
        passes = []
        cards_label = action_hand.split(",")
        puts "Player_#{0}が#{cards_label.join(", ")}を場に出しました"
        cards = @players[0].play_cards(cards_label)
      else
        # 何もしない
        passes << "Pass"
        puts "Player_#{0}はパスしました"
      end




      action_hand = @players[1].cpu_action(cards)
      if action_hand != "Pass"
        passes = []
        cards_label = action_hand.gsub(" ", "").split(",")
        puts "Player_#{1}が#{cards_label.join(", ")}を場に出しました"
        cards = @players[1].play_cards(cards_label)
      else
        # 何もしない
        passes << "Pass"
        puts "Player_#{1}はパスしました"
      end





      action_hand = @players[2].cpu_action(cards)
      if action_hand != "Pass"
        passes = []
        cards_label = action_hand.gsub(" ", "").split(",")
        puts "Player_#{2}が#{cards_label.join(", ")}を場に出しました"
        cards = @players[2].play_cards(cards_label)
      else
        # 何もしない
        passes << "Pass"
        puts "Player_#{2}はパスしました"
      end

    end








    # while line = gets
    #   p line.chomp
    # end




  end



  def card_reset
    @cards = Marshal.load(Marshal.dump(CARDS))
    @cards.shuffle!
  end



  # プレイヤーにカードを配る
  def distribute_card
    cards_group_by_index = @cards.group_by.with_index {|x, index| index % @players.count}

    @players.each_with_index do |player, index|
      cards = cards_group_by_index[index].sort_by { |card| card.number_rank }
      player.set_card(cards)
    end
  end

end


puts "参加人数を入力してください。"
player_count = gets.to_i

#　イメージ（ゲームの卓）
game_table = DaiFugoGame.new()

game_table.game_start(player_count: player_count)

