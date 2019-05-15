See https://github.com/ten0s/dotfiles/blob/master/tasks/erl.yml for detail

<pre>
mkdir -p ~/.erl_libs/ebin

cd ~/projects
git clone git@github.com:ten0s/user_default.git
cd user_default

erlc user_default.erl

cp user_default.beam ~/.erl_libs/ebin/
</pre>
