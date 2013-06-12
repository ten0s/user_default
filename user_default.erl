-module(user_default).

-export([help/0]).

-export([dbg/0]).
-export([dbg/1]).
-export([dbg/2]).
-export([dbg/3]).
-export([dbg/4]).

-export([etv/0]).
-export([etv/1]).

-export([status/1, status/2]).
-export([state/1, state/2]).
-export([kill/1, kill/2]).
-export([pi/1, pi/2]).
-export([os/1]).
-export([lager/1]).

-compile(inline).

help() ->
    Exports = lists:keysort(1, ?MODULE:module_info(exports)),
    shell_default:help(),
    io:format("** commands in module user_default **\n"),
    [ begin
	  Args = "(" ++ string:join(lists:duplicate(Arity, "_"), ",") ++ ")",
	  Cmd = atom_to_list(Fun) ++ Args,
	  Spaces = lists:duplicate(15 - length(Cmd), 32),
	  io:format("~s~s -- unknown~n", [Cmd, Spaces])
      end || {Fun, Arity} <- Exports, Fun =/= help, Fun =/= module_info ],
    true.

%% ===================================================================
%% DBG
%% ===================================================================

dbg()										-> dbg:tracer().

dbg(c)										-> dbg:stop_clear();
dbg(M)										-> dbgg({M, '_', '_'}, []).

dbg(M, c)									-> dbgc({M, '_', '_'});
dbg(M, r)									-> dbgg({M, '_', '_'}, dbg_rt());
dbg(M, l)									-> dbgl({M, '_', '_'}, []);
dbg(M, lr)									-> dbgl({M, '_', '_'}, dbg_rt());
dbg(M, rl)									-> dbgl({M, '_', '_'}, dbg_rt());
dbg(M, F) when is_atom(F)					-> dbgg({M,   F, '_'}, []);
dbg(M, Fn2Ms) when is_function(Fn2Ms)		-> dbgf({M, '_', '_'}, Fn2Ms);
dbg(M, O)									-> dbgg({M, '_', '_'}, O).

dbg(M, F, c)								-> dbgc({M,   F, '_'});
dbg(M, F, l)								-> dbgl({M,   F, '_'}, dbg_rt());
dbg(M, F, r)								-> dbgg({M,   F, '_'}, dbg_rt());
dbg(M, F, lr)								-> dbgl({M,   F, '_'}, dbg_rt());
dbg(M, F, rl)								-> dbgl({M,   F, '_'}, dbg_rt());
dbg(M, F, A) when is_integer(A)				-> dbgg({M,   F,   A}, []);
dbg(M, F, Fn2Ms) when is_function(Fn2Ms)	-> dbgf({M,   F, '_'}, Fn2Ms);
dbg(M, F, O)								-> dbgg({M,   F, '_'}, O).

dbg(M, F, A, c)								-> dbgc({M,   F,   A});
dbg(M, F, A, r)								-> dbgg({M,   F,   A}, dbg_rt());
dbg(M, F, A, l)								-> dbgl({M,   F,   A}, dbg_rt());
dbg(M, F, A, lr)							-> dbgl({M,   F,   A}, dbg_rt());
dbg(M, F, A, rl)							-> dbgl({M,   F,   A}, dbg_rt());
dbg(M, F, A, Fn2Ms) when is_function(Fn2Ms) -> dbgf({M,   F,   A}, Fn2Ms);
dbg(M, F, A, O)								-> dbgg({M,   F,   A}, O).

%% ===================================================================
%% DBG Internal
%% ===================================================================

dbgc(MFA)    -> dbg:ctp(MFA).
dbgg(MFA, O) -> dbg:tracer(), dbg:p(all, call), dbg:tp(MFA, O).
dbgl(MFA, O) -> dbg:tracer(), dbg:p(all, call), dbg:tpl(MFA, O).
dbgf(MFA, F) -> dbg:tracer(), dbg:p(all, call), dbg:tpl(MFA, dbg:fun2ms(F)).
dbg_rt() -> [{'_', [], [{return_trace}, {exception_trace}]}].

%% ===================================================================
%% Event Viewer
%% ===================================================================

etv() ->
	etv("").

etv(Title) ->
	et_viewer:start([
		{title, Title},
		{trace_global, true},
		{trace_pattern, {et, max}}
	]).

%% ===================================================================
%% Pid generic
%% ===================================================================

-type reg_name() :: atom().
-type process() :: pid() | reg_name() | pos_integer().
-spec pid_do(process(), fun((pid()) -> any())) -> any().
pid_do(Process, Fun) when is_integer(Process) ->
	try c:pid(0, Process, 0) of
		Pid -> pid_do(Pid, Fun)
	catch
		_:_ -> pid_do(bad_pid, Fun)
	end;
pid_do(Process, Fun) when is_pid(Process) ->
	Fun(Process);
pid_do(Process, Fun) when is_atom(Process), Process =/= undefined ->
	Pid = whereis(Process),
	pid_do(Pid, Fun);
pid_do(_, _) ->
	io:format("error: invalid process~n").

%% ===================================================================
%% Process status/state/info
%% ===================================================================

-spec status(process()) -> any().
status(Process) ->
	status(Process, print).

-spec status(process(), fetch | print) -> any().
status(Process, Action) ->
	pid_do(Process,
		fun(Pid) ->
			try sys:get_status(Pid) of
				Status ->
					case Action of
						fetch ->
							Status;
						print ->
							io:format("~p~n", [Status])
					end
			catch
				Exc:Err ->
					io:format("~p: ~p~n", [Exc, Err])
			end
		end
	).

-spec state(process()) -> any().
state(Process) ->
	state(Process, print).

-spec state(process(), fetch | print) -> any().
state(Process, Action) ->
	pid_do(Process,
		fun(Pid) ->
			try sys:get_status(Pid) of
				Status ->
					case fetch_state(Status) of
						{ok, State} ->
							case Action of
								fetch ->
									State;
								print ->
									print_state(State)
							end;
						{error, Error} ->
							io:format("error: ~p~n", [Error])
					end
			catch
				Exc:Err ->
					io:format("~p: ~p~n", [Exc, Err])
			end

		end
	).

print_state({data, State}) ->
	io:format("~p~n", [State]);
print_state({data, StateName, StateData}) ->
	io:format("~p~n~p~n", [StateName, StateData]).

fetch_state({status,_,{module,gen_server},[_,_,_,_,[_,_,{data,Data}]]}) ->
	State = proplists:get_value("State", Data),
	{ok, {data, State}};
fetch_state({status,_,{module,gen_fsm},[_,_,_,_,[_,{data,Data1},{data,Data2}]]}) ->
	StateName = proplists:get_value("StateName", Data1),
	StateData = proplists:get_value("StateData", Data2),
	{ok, {data, StateName, StateData}};
fetch_state(_) ->
	{error, not_implemented}.

-spec pi(process()) -> any().
pi(Process) ->
	pi(Process, print).

-spec pi(process(), fetch | print) -> any().
pi(Process, Action) ->
	pid_do(Process,
		fun(Pid) ->
			try process_info(Pid) of
				Info ->
					case Action of
						fetch ->
							Info;
						print ->
							io:format("~p~n", [Info])
					end
			catch
				Exc:Err ->
					io:format("~p: ~p~n", [Exc, Err])
			end

		end
	).

%% ===================================================================
%% Kill process
%% ===================================================================

-type reason() :: term().
-spec kill(process(), reason()) -> any().
kill(Process, Reason) ->
	pid_do(Process, fun(Pid) -> erlang:exit(Pid, Reason) end).

-spec kill(pid() | reg_name() | pos_integer()) -> any().
kill(Process) ->
	kill(Process, kill).

%% ===================================================================
%% OS command
%% ===================================================================

os(Command) ->
	Res = os:cmd(Command),
	io:format("~s~n", [Res]).

%% ===================================================================
%% Lager
%% ===================================================================

lager(Level) ->
	lager:set_loglevel(lager_console_backend, Level).
