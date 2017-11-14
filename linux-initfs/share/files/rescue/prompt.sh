
PS1='[root@rescue: \w] \$ '
export PS1

for f in /etc/profile.d/*.sh
do
	[[ -r $f ]] && . $f
done

