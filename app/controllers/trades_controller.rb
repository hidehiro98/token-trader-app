class TradesController < ApplicationController
  require "#{Dir.pwd}/app/models/EthereumAPI.rb"
  require "#{Dir.pwd}/app/models/UpdatePosession.rb"
  before_action :set_trade, only: [:transfer, :destroy]

  def index
    @trades = Trade.all
    @tokens = Token.new
    @trade = Trade.new
    @trade_amount = Trade.new
    @hasheduser = Hasheduser.find_by(username: current_user.username)
  end

  def new
  end

  def create
    # TODO: Trades TableのTokenの名前に関する情報を別テーブルにする
    @trade = Trade.new(trades_params)
    if @trade.from_token_name == @trade.to_token_name
      redirect_to trades_path, notice: "Token types are the same!"
    end
    @trade.from_token_name =  Token.find(@trade.from_token_name.to_i).symbol
    @trade.to_token_name =  Token.find(@trade.to_token_name.to_i).symbol
    @trade.to_token_amount = @trade.price * @trade.from_token_amount
    @hasheduser = Hasheduser.find_by(username: current_user.username)
    @trade.maker_address = @hasheduser.ether_account
    if @trade.save
      redirect_to trades_path, notice: "Success Sale's Info Set!"
    else
      render 'new'
    end
  end

  def transfer
    # TODO: Error check
    @hasheduser = Hasheduser.find_by(username: current_user.username)
    if @trade.from_token_amount < params[:amount].to_i
      puts "It exceeds the amount that can be traded"
      redirect_to trades_path, notice: "It exceeds the amount that can be traded"
    else
      # Tradeするmaker tokenとtaker tokenの量をint型で取得する
      maker_amount = params[:amount].to_i
      taker_amount = (maker_amount * @trade.price).to_i
      # Update Trade Table
      @trade.from_token_amount -= maker_amount
      @trade.to_token_amount -= taker_amount
      @trade.update(from_token_amount: @trade.from_token_amount, to_token_amount: @trade.to_token_amount)

      # Posession Tableをupdateするために必要な情報を取得
      maker_token_id = Token.find_by(symbol: @trade.from_token_name).id
      taker_token_id = Token.find_by(symbol: @trade.to_token_name).id
      maker_id = Hasheduser.find_by(ether_account: @trade.maker_address).id
      taker_id = Hasheduser.find_by(username: current_user.username).id
      # Update Posession Table
      updatePosession = UpdatePosession.new()
      updatePosession.updatePosessionTable(maker_token_id, taker_token_id, maker_id, taker_id, maker_amount, taker_amount)
      # Trade情報のMakerTokenの残高が0になったら行を削除する
      if @trade.from_token_amount == 0
        @trade.destroy
      end
      # Execute smart contract
      # Get token address
      maker_token_address = Token.find_by(symbol: @trade.from_token_name).token_address
      taker_token_address = Token.find_by(symbol: @trade.to_token_name).token_address
      smartContract = EthereumAPI.new()
      smartContract.executeTransfer(maker_token_address, taker_token_address, @trade.maker_address, @hasheduser.ether_account, maker_amount, taker_amount, @hasheduser.ether_account_password)
      redirect_to trades_path, notice: "Success Transfer!"
    end
  end

  def destroy
    @trade.destroy
    redirect_to trades_path, notice: "Success Cancel"
  end

  private
    def trades_params
      params.require(:trade).permit(:price, :from_token_name, :to_token_name, :from_token_amount, :to_token_amount).to_h
    end

    def set_trade
      @trade = Trade.find(params[:id])
    end
end
