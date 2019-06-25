-module(money).
-author("nitin").

-export([start/0]).
-import(bank,[bazBank/3]).
-import(customer,[bazCust/5]).
-import(lists,[append/2,split/2,merge/1,nth/2]).

menudisplay(C,B)->
  io:fwrite("** Customers and loan objectives **~n"),
  print(C),
  io:fwrite("** Banks and Financial Resiurces **~n"),
  print(B).
print([])->ok;
print([H|T])->
  io:fwrite("~s: ~w~n",[element(1,H),element(2,H)]),
  print(T).

get_feedback() ->
  receive
    {bankEnding,{BankName, Limit}}->
      io:fwrite("~s has ~w dollar(s) remaining.~n",[BankName, Limit]),
      get_feedback();
    {customerEnding,{CustomerName, Loan}}->
      io:fwrite("~s was only able to borrow ~w dollar(s). Boo Hoo!~n",[CustomerName, Loan]),
      get_feedback();
    {customerObReached,{CustomerName, OriginalLoan}}->
      io:fwrite("~s has reached the objective of ~w dollar(s). Woo Hoo! ~n",[CustomerName, OriginalLoan]),
      get_feedback();
    {customerRequestDeny,{SenderBank,Pid, CustomerName, RandomBankName, DemandLoan}}->
      io:fwrite("Customer ~s requests a loan of ~w dollar(s) from ~s~n",[CustomerName, DemandLoan, RandomBankName]),
      SenderBank!{deny,{Pid,RandomBankName, DemandLoan, CustomerName}},
      get_feedback();
    {customerRequestDenyPrint,{SenderBank,CustomerName, RandomBankName, DemandLoan}}->
      io:fwrite("~s DENIES a loan of ~w dollars from ~s~n",[RandomBankName, DemandLoan, CustomerName]),
      get_feedback();
    {customerRequestAccept,{SenderBank, Pid,CustomerName, RandomBankName, DemandLoan}}->
      io:fwrite("Customer ~s requests a loan of ~w dollar(s) from ~s~n",[CustomerName, DemandLoan, RandomBankName]),
      SenderBank!{approve,{Pid,RandomBankName, DemandLoan, CustomerName}},
      get_feedback();
    {customerRequestAcceptPrint,{SenderBank, CustomerName, RandomBankName, DemandLoan}}->
      io:fwrite("~s approves a loan of ~w dollars from ~s~n",[RandomBankName, DemandLoan, CustomerName]),
      get_feedback()
    after 2000 ->
      ok
  end.

forCust(0, _, _, _) ->
  ok;
forCust(Max, C, BankPidList, MasterPid) when Max > 0 ->
  CustomerName = element(1,nth(Max, C)),
  Loan = element(2,nth(Max, C)),
  OriginalLoan = element(2,nth(Max, C)),
  Pid = spawn(customer, bazCust, [CustomerName, Loan, MasterPid, BankPidList, OriginalLoan]),
  Pid ! {initiate, CustomerName, Loan, Pid, BankPidList, MasterPid},
  forCust(Max -1, C, BankPidList, MasterPid)
  .

elementsBank({C,R}, MasterPid)->
  BankName = C,
  Limit = R,
  Pid = spawn(bank, bazBank, [BankName, Limit, MasterPid]),
  Pid ! {initiate, MasterPid, BankName, Limit},
  T = {BankName, Pid, Limit},
  T.

readBank([],MasterPid)->[0];
readBank([H|T],MasterPid)->
      L1 =elementsBank(H, MasterPid),
      L2 = [L1] ++ readBank(T, MasterPid),
      L2.

createCustomerProcesses(C, BankPidList, MasterPid)->
  forCust(length(C), C, BankPidList, MasterPid).

start() ->
  MasterPid = self(),
  {ok, B} = file:consult("banks.txt"),
  {ok, C} = file:consult("customers.txt"),
  menudisplay(C,B),
  io:fwrite("~n"),
  L = readBank(B,MasterPid),
  {BankPidList, _} = lists:split(length(L) - 1, L),
  io:fwrite("~n"),
  createCustomerProcesses(C, BankPidList, MasterPid),
  get_feedback().