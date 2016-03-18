<pre>
mkdir -p ~/.erl_libs/ebin

cd ~/projects
git clone git@github.com:ten0s/user_default.git
cd user_default

erlc user_default.erl

cp user_default.beam ~/.erl_libs/ebin/
cp dot_erlang ~/.erlang
</pre>

<pre>
cd ~/.erl_libs
git clone https://github.com/rustyio/sync.git
cd sync
make
</pre>
