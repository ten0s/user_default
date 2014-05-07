<pre>
mkdir -p ~/.ebin
wget https://raw.githubusercontent.com/ten0s/user_default/master/user_default.erl -P ~/.ebin
erlc  -o ~/.ebin ~/.ebin/user_default.erl
echo -e "true = code:add_pathz(\"$HOME/.ebin\").\n{module, user_default} = code:load_abs(\"$HOME/.ebin/user_default\")." >> .erlang
</pre>
