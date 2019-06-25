-module(customer).
-author("nitin").
-import(lists,[nth/2]).
-import(bank,[bazBank/3]).
-import(lists,[delete/2]).

-export([bazCust/5, demandLoan/1]).

deleteBank(RandomBankTuple, [], Name, Loan, MasterPid, Pid, OriginalLoan) ->
  if Loan > 0 ->
    MasterPid!{customerEnding,{Name, OriginalLoan}};
    true ->
      exit(self(), kill)
  end;
deleteBank(RandomBankTuple, BankPidList, Name, Loan, MasterPid, Pid, OriginalLoan) ->
  BankPidList1 = delete(RandomBankTuple, BankPidList),
  self()!{initiate, Name, Loan, Pid, BankPidList1, MasterPid},
  bazCust(Name, Loan, MasterPid, BankPidList1, OriginalLoan).

demandLoan(Loan)->
  if Loan > 50 ->
    Random = rand:uniform(50),
    Random;
    true ->
      Random = rand:uniform(Loan),
      Random
  end
.

randomTime(RandomTimeValue)->
  if RandomTimeValue > 10 ->
    RandomTimeValue;
    true ->
      randomTime(rand:uniform(100))
  end
.

bazCust(Name, Loan, MasterPid, BankPidList, OriginalLoan) ->
  receive
    {initiate, CustomerName, Loan, Pid, BankPidList, MasterPid} ->
      timer:sleep(100),
      if Loan == 0->
          MasterPid!{customerObReached,{CustomerName, OriginalLoan}};
          true ->
            if length(BankPidList) ==0 ->
              MasterPid!{customerEnding,{Name, OriginalLoan}};
              true ->
                DemandLoan = demandLoan(Loan),
                RandomBankIndex = rand:uniform(length(BankPidList)),
                RandomBankTuple = nth(RandomBankIndex, BankPidList),
                RandomBankName = element(1,RandomBankTuple),
                RandomBankProcessId = element(2,RandomBankTuple),
                RandomTimeValue = randomTime(rand:uniform(100)),
                timer:sleep(RandomTimeValue),

                RandomBankProcessId!{customerCall,{Pid, CustomerName, RandomBankName, DemandLoan}},
                receive
                  {approveLoan,{RandomBankName}}->
                    Loan1 = Loan - DemandLoan,
                    self()!{initiate, Name, Loan1, Pid, BankPidList, MasterPid},
                    bazCust(Name, Loan1, MasterPid, BankPidList, OriginalLoan);
                  {denyLoan,{RandomBankName}}->
                    deleteBank(RandomBankTuple,BankPidList, Name, Loan, MasterPid, Pid, OriginalLoan)
                  after 1500->
                    if Loan > 0 ->
                      MasterPid!{customerEnding,{Name, Loan}};
                      true ->
                        exit(self(), kill)
                    end
                end
            end
      end
  after 1500->
    if Loan > 0 ->
      MasterPid!{customerEnding,{Name, Loan}};
      true ->
        exit(self(), kill)
    end
  end.