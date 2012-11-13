class TransfersController < ApplicationController
  def new
    @accounts = Account.all
    @transfer = Account::Transfer.new
  end
  
  def create
    @transfer = Account::Transfer.new(params[:transfer])
    
    if @transfer.call.success?
      redirect_to root_path, :notice => "Transferred #{@transfer.amount} from #{@transfer.from.name}'s account to #{@transfer.to.name}'s account."
    else
      @accounts = Account.all
      render :new
    end
  end
end
