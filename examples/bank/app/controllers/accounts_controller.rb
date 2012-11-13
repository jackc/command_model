  class AccountsController < ApplicationController
  def index
    @accounts = Account.all
  end

  def deposit_form
    @account = Account.find_by_name params[:id]
    @deposit = Account::DepositCommand.new
  end
  
  def deposit
    @account = Account.find_by_name params[:id]
    @deposit = @account.deposit params[:deposit]
    
    if @deposit.success?
      redirect_to root_path, :notice => "Deposited #{@deposit.amount} to #{@account.name}'s account."
    else
      render "deposit_form"
    end
  end
  
  def withdraw_form
    @account = Account.find_by_name params[:id]
    @withdraw = Account::WithdrawCommand.new
  end  
  
  def withdraw
    @account = Account.find_by_name params[:id]
    @withdraw = @account.withdraw params[:withdraw]
    
    if @withdraw.success?
      redirect_to root_path, :notice => "Withdrew #{@withdraw.amount} from #{@account.name}'s account."
    else
      render "withdraw_form"
    end  
  end

  def transfer_form
    @accounts = Account.all
    @transfer = Account::TransferCommand.new
  end
  
  def transfer
    @transfer = Account::TransferCommand.new(params[:transfer])
    
    if @transfer.call.success?
      redirect_to root_path, :notice => "Transferred #{@transfer.amount} from #{@transfer.from.name}'s account to #{@transfer.to.name}'s account."
    else
      @accounts = Account.all
      render "transfer_form"
    end
  end
end
