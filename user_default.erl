-module(user_default).

-export([help/0]).

-export([dbg/0]).
-export([dbg/1]).
-export([dbg/2]).
-export([dbg/3]).
-export([dbg/4]).
-export([ii/1]).

-export([etv/0]).
-export([etv/1]).

-export([kill/1, kill/2]).
-export([pi/1, pi/2]).
-export([mql/0]).
-export([os/1]).
-export([lager/1]).

-export([rw/2]).

-include_lib("docsh/include/docsh_user_default.hrl").

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
%% Process info
%% ===================================================================

-spec pi(process()) -> any().
pi(Process) ->
	pi(Process, print).

-spec pi(process(), return | print) -> any().
pi(Process, Action) when Action =:= return; Action =:= print ->
	pid_do(Process,
		fun(Pid) ->
			try process_info(Pid) of
				Info ->
					case Action of
						return ->
							Info;
						print ->
							io:format("~p~n", [Info])
					end
			catch
				Exc:Err ->
					io:format("~p: ~p~n", [Exc, Err])
			end

		end).

-spec mql() -> any().
mql() ->
	lists:reverse(lists:sort([
		{process_info(P, message_queue_len), P} || P <- processes()
	])).

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

%% ===================================================================
%% Interpreter overrides
%% ===================================================================

ii(Module) when is_atom(Module) ->
	ModInfo = Module:module_info(),
	ModSrc = proplists:get_value(source,
		proplists:get_value(compile, ModInfo)),
	i:ii(ModSrc);
ii(Module) ->
	i:ii(Module).

%% ===================================================================
%% shell_default additions
%% ===================================================================

%% from /opt/r19.3/lib/stdlib-3.3/src/shell.erl
-define(CHAR_MAX, 60).
-define(RECORDS, shell_records).

pp(V, I, D, RT) ->
    Strings =
        case application:get_env(stdlib, shell_strings) of
            {ok, false} ->
                false;
            _ ->
                true
        end,
    io_lib_pretty:print(V, ([{column, I}, {line_length, columns()},
                             {depth, D}, {max_chars, ?CHAR_MAX},
                             {strings, Strings},
                             {record_print_fun, record_print_fun(RT)}]
                            ++ enc())).

columns() ->
    case io:columns() of
        {ok,N} -> N;
        _ -> 80
    end.

enc() ->
    case lists:keyfind(encoding, 1, io:getopts()) of
	false -> [{encoding,latin1}]; % should never happen
	Enc -> [Enc]
    end.

record_print_fun(RT) ->
    fun(Tag, NoFields) ->
            case ets:lookup(RT, Tag) of
                [{_,{attribute,_,record,{Tag,Fields}}}]
                                  when length(Fields) =:= NoFields ->
                    record_fields(Fields);
                _ ->
                    no
            end
    end.

record_fields([{record_field,_,{atom,_,Field}} | Fs]) ->
    [Field | record_fields(Fs)];
record_fields([{record_field,_,{atom,_,Field},_} | Fs]) ->
    [Field | record_fields(Fs)];
record_fields([{typed_record_field,Field,_Type} | Fs]) ->
    record_fields([Field | Fs]);
record_fields([]) ->
    [].
%% from /opt/r19.3/lib/stdlib-3.3/src/shell.erl

records_table() ->
    catch lists:foldl(fun (T, Acc) ->
        case proplists:get_value(name, ets:info(T)) of
        ?RECORDS -> throw({ok, T});
        _ -> Acc end
    end, error, ets:all()).

rw(File, Term) ->
    {ok, RT} = records_table(),
    Cs = pp(Term, _Column=1, _Depth=-1, RT),
    file:write_file(File, Cs).
