
LVMALIAS='lvchange lvcreate lvextend lvmdiskscan lvmsar lvremove lvresize
lvscan lvconvert lvdisplay lvmchange lvmconfig lvmsadc lvreduce lvrename lvs
pvchange pvck pvcreate pvdisplay pvmove pvremove pvresize pvs pvscan
vgcfgbackup vgchange vgconvert vgdisplay vgextend vgmknodes vgremove
vgs vgsplit vgcfgrestore vgck vgcreate vgexport vgimport vgmerge
vgreduce vgrename vgscan'

LVM=$(which lvm)

for lvmalias in $LVMALIAS
do
	ln -s $LVM /sbin/$lvmalias
done

unset lvmalias LVMALIAS LVM

