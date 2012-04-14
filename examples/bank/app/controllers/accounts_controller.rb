class AccountsController < ApplicationController
  def index
    @accounts = ACCOUNTS
  end

  def deposit_form
    @account = find_account_by_name params[:id]
    @deposit = Account::DepositCommand.new
  end
  
  def deposit
    @account = find_account_by_name params[:id]
    @deposit = @account.deposit params[:deposit]
    
    if @deposit.success?
      redirect_to root_path, :notice => "Deposited #{@deposit.amount} to #{@account.name}'s account."
    else
      render "deposit_form"
    end
  end
  
  def withdraw_form
    @account = find_account_by_name params[:id]
    @withdraw = Account::WithdrawCommand.new
  end  
  
  def withdraw
    @account = find_account_by_name params[:id]
    @withdraw = @account.withdraw params[:withdraw]
    
    if @withdraw.success?
      redirect_to root_path, :notice => "Withdrew #{@withdraw.amount} from #{@account.name}'s account."
    else
      render "withdraw_form"
    end  
  end

  def transfer_form
    @accounts = ACCOUNTS
    @transfer = Account::TransferCommand.new
  end
  
  def transfer
    @accounts = ACCOUNTS
    @transfer = Account::TransferCommand.new
    @transfer.to = find_account_by_name params[:transfer][:to]
    @transfer.from = find_account_by_name params[:transfer][:from]
    @transfer.amount = params[:transfer][:amount]
    Account.transfer @transfer
    
    if @transfer.success?
      redirect_to root_path, :notice => "Transferred #{@transfer.amount} from #{@transfer.from.name}'s account to #{@transfer.to.name}'s account."
    else
      render "transfer_form"
    end
  end
  
  private
    def find_account_by_name(name)
      ACCOUNTS.find { |a| a.name == name }
    end
end
