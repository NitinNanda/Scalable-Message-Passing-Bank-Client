-module(bank).
-author("nitin").
-import(lists,[nth/2]).
-import(customer,[bazCust/5,demandLoan/4]).

-export([bazBank/3]).


bazBank(BankName, Limit, MasterPid) ->
  receive
    {customerCall,{Pid, CustomerName, RandomBankName, DemandLoan}}->
      timer:sleep(100),
      if Limit == 0 ->
        exit(self(), kill);
        true ->
          if DemandLoan > Limit ->
            MasterPid!{customerRequestDeny,{self(),Pid, CustomerName, RandomBankName, DemandLoan}},
            timer:sleep(60),
            receive
              {deny,{Pid,RandomBankName, DemandLoan, CustomerName}}->
                MasterPid!{customerRequestDenyPrint,{self(), CustomerName, RandomBankName, DemandLoan}},
                Pid!{denyLoan,{RandomBankName}},
                bazBank(BankName, Limit, MasterPid)
            end;

            true ->
              MasterPid!{customerRequestAccept,{self(),Pid,CustomerName, RandomBankName, DemandLoan}},
              timer:sleep(80),
              receive
                {approve,{Pid,RandomBankName, DemandLoan, CustomerName}}->
                  Limit1 = Limit - DemandLoan,
                  MasterPid!{customerRequestAcceptPrint,{self(), CustomerName, RandomBankName, DemandLoan}},
                  Pid!{approveLoan,{RandomBankName}},
                  bazBank(BankName, Limit1, MasterPid)
              end

          end

      end
    after 1000 ->
      if Limit > 0 ->
        MasterPid!{bankEnding,{BankName,Limit}};
        true ->
          ok
      end
  end.