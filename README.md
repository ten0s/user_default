<pre>
mkdir -p ~/.ebin ~/.erlang_libs

cd ~/projects
git clone git@github.com:ten0s/user_default.git
cd user_default

erlc user_default.erl

cp user_default.beam ~/.ebin/
cp dot_erlang ~/.erlang
</pre>

<pre>
cd ~/.erlang_libs
git clone https://github.com/rustyio/sync.git
cd sync
make
</pre>